# WebSocket

REST 与 WS 走**不同域名**：REST 在 `ai-tool.indevs.in`，WS 在 `tushare.indevs.in`。长期 Key 不进 URL，改用 60 秒票据。

## 三步

```
1) POST https://ai-tool.indevs.in/unusualwhales/socket-ticket
   header: X-API-Key: <KEY>
   → {"ok":true,"websocket_url":"wss://tushare.indevs.in/unusualwhales/socket?ticket=...",
      "expires_in":60,"protocol":{"subscribe":{...},"unsubscribe":{...}}}

2) 连 websocket_url（票据 60 秒内有效，过期就重新申请）

3) 发订阅帧 {"channel":"<ch>","msg_type":"join"}   退订 {"channel":"<ch>","msg_type":"leave"}
```

每条消息是一个二元数组：`["<channel>", {payload}]`。

## 频道

**QuantData 原生（逐笔/flow，实时）**

| 频道 | 内容 |
|---|---|
| `flow-alerts` | 全市场 `isUnusual=true` 的聚合成交 |
| `flow-alerts:SPX` | 指定标的 |
| `option_trades` | 全市场逐笔（别名 `option-trades`） |
| `option_trades:SPX` | 指定标的逐笔 |
| `option_minutes:<OSI>` | 单合约 1 分钟 OHLCV，如 `option_minutes:SPX261029P07640000` |

QuantData 消息带 `source: "quantdata-native-websocket"` 和 `schema`（`quantdata-options-consolidated.v1` / `quantdata-options-unconsolidated.v1`）。`price` / `premium` / `strike` 是美元字符串，`timestamp_ms` 是 UTC 毫秒，`impliedVolatility` 是百分数。

1 分钟线消息：`{"type":"bar","source":"quantdata-contract-minute","contract":"...","data":{start,end,o,h,l,c,v,is_final}}`，`is_final:false` 表示形成中。同一合约同一分钟覆盖更新。

**UW 原生（走原上游，受原套餐限制）**

`gex:SPY`、`gex_strike:SPY`、`gex_strike_expiry:SPY`、`net_flow:SPY`、`price:SPY`，以及 maker board `periscope` / `periscope:{TICKER}`（仅 SPX/VIX/XSP/NANOS 等指数，行形状 `{strike,expiry,gamma,charm,vanna}`，约每分钟快照一份，最多 1024 行/帧，`has_more:false` 的帧收尾）。

## 硬限制

- **单连接最多 12 个频道。**
- **只推新成交，断线不补历史。** 重连状态消息带 `gap_possible: true`，缺口需自己用 REST `/api/option-trades/full-tape/{DATE}` 补。
- 慢客户端会被**主动断开**并明确提示，可能产生缺口。
- `flow-alerts` 的口径是 QuantData 的 `isUnusual=true`，**不等于** UW 自己在网页上的专有预警，也不读 UW 自定义预警配置。
- `option_minutes` 必须用**精确的 OCC/OSI 合约代码**，且必须是当前有效合约 —— 用 REST 的 `/api/stock/{t}/option-contracts` 或 `/api/option-trades/flow-alerts` 的 `expiry` 现取，不要猜合约根。
- 源端缺数据的分钟**不补造** K 线。

## 实测状态（2026-11-24 20:47 +08:00，美股盘前）

- 票据：200，`websocket_url` 正常返回
- 连接：`ClientWebSocket.State = Open`
- `join` 三个频道（`flow-alerts`、`gex:SPY`、`option_trades:SPY`）全部回 `status:ok`
- 随后 `flow-alerts` / `option_trades:SPY` 推 `{"status":"reconnecting","generation":0,"messages":0,"rows":0,"last_trade_time":null,"gap_possible":true}` —— QuantData 上游会话在重连，对应 HTTP 健康报告里的 `qd_session_failed` / `qd_native_tape_failed`
- `gex:SPY` 在盘前无任何帧

**结论：** 盘前无逐笔是正常的（期权未开盘），但 `reconnecting` + `rows:0` 在盘中若持续，就是上游 QuantData 挂了 —— 此时退回 REST `/api/option-trades/flow-alerts`（实测秒级更新，可靠）。

## PowerShell 最小客户端

```powershell
$key = (Get-Content "$env:USERPROFILE\.config\uw-relay\key.txt" -Raw).Trim()
$tk = (Invoke-WebRequest -Uri 'https://ai-tool.indevs.in/unusualwhales/socket-ticket' `
        -Method POST -Headers @{ 'X-API-Key' = $key } -UseBasicParsing).Content | ConvertFrom-Json
$ws = [System.Net.WebSockets.ClientWebSocket]::new()
$cts = [Threading.CancellationTokenSource]::new(3600000)
$ws.ConnectAsync([Uri]$tk.websocket_url, $cts.Token).Wait(15000) | Out-Null
foreach ($ch in 'flow-alerts','option_trades:SPY') {
  $b = [Text.Encoding]::UTF8.GetBytes("{`"channel`":`"$ch`",`"msg_type`":`"join`"}")
  $ws.SendAsync([ArraySegment[byte]]::new($b), 'Text', $true, $cts.Token).Wait(5000) | Out-Null
}
$buf = [byte[]]::new(262144)
while ($ws.State -eq 'Open') {
  $seg = [ArraySegment[byte]]::new($buf)
  $t = $ws.ReceiveAsync($seg, $cts.Token)
  if (-not $t.Wait(30000)) { continue }
  if ($t.Result.MessageType -eq 'Close') { break }
  [Text.Encoding]::UTF8.GetString($buf, 0, $t.Result.Count)
}
```

`scripts/uw.ps1 ws <channel>[,<channel>] [seconds]` 是可直接跑的版本。

## Python（官方示例，注意本机无可用 python，需 uv）

```python
import asyncio, json, os
import requests, websockets

r = requests.post("https://ai-tool.indevs.in/unusualwhales/socket-ticket",
                  headers={"X-API-Key": os.environ["RELAY_API_KEY"]}, timeout=15)
r.raise_for_status()
url = r.json()["websocket_url"]

async def main():
    async with websockets.connect(url, max_size=16_000_000) as ws:
        for ch in ["flow-alerts", "option_trades:SPX"]:
            await ws.send(json.dumps({"channel": ch, "msg_type": "join"}))
        async for raw in ws:
            channel, payload = json.loads(raw)
            print(channel, payload)

asyncio.run(main())
```