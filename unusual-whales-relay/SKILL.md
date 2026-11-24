---
name: unusual-whales-relay
description: Query the Unusual Whales relay at ai-tool.indevs.in - the API key YG actually owns. GEX levels, dealer greek exposure, options flow alerts, dark pool prints, market tide, plus a 238-endpoint catalog and a live WebSocket. Use for any request about unusual options activity, GEX/gamma walls, dealer positioning, dark pool, options sentiment, or when building features on this data.
---

# Unusual Whales Relay

YG 拥有的真实凭据。上游是 Unusual Whales API **Advanced**（官方 $375/月），本站中转按 5.9% 转售。Key 到期 **2026-12-24 20:35:53**。

```
base      https://ai-tool.indevs.in
prefix    /unusualwhales
auth      X-API-Key: <KEY>        (也接受 Authorization: Bearer <KEY> 和 ?api_key=)
key file  C:\Users\dingzhaoyi\.config\uw-relay\key.txt   (或 env RELAY_API_KEY)
```

路径规则：`{base}/unusualwhales` + 上游路径。上游 `/api/stock/SPY/gex-levels` → 中转 `/unusualwhales/api/stock/SPY/gex-levels`。

## 五条铁律（违反即出错）

1. **不猜路径。** 238 条权威目录在 `assets/catalog.json`（也可 GET `/unusualwhales/catalog`）。人类可读版 `references/endpoints.md`。目录里没有的路径不存在。
2. **403 不重试。** 403 = 上游套餐/add-on 没有权限，永久失败，重试无意义。响应体带 `advanced_tier_required` / `politics_scope_required` / `volatility_scope_required` / `Missing access for ...`。清单见下文"拿不到的"。
3. **expiry 必须是真实到期日 `YYYY-MM-DD`。** 传周六、不存在或已过期的日期，端点返回 `{"data": []}` **而不报错** —— 这是最容易误判成"没数据"的坑。到期日从 `flow-alerts` 的 `expiry` 字段或 `option-contracts` 的 `option_symbol`（OSI，如 `SPY261123C00725000` → 2026-11-23）取。
4. **判断有没有数据看 `data` 数组长度，不看 HTTP 200。** 实测 24 个端点稳定返回 200 + 空数组。
5. **GEX/greek 是"assumed dealer exposure"。** 上游按固定符号约定（做市商买 call、卖 put）从 OI/volume 推算，**不是**观测到的做市商持仓。汇报时照实说，别写成"机构在买/卖"。

6. **自己写 HTTP 客户端时必须设 User-Agent。** Cloudflare 会以 `Error 1010: Access denied` 拦掉裸 `Python-urllib/x.y`、`Go-http-client` 之类的默认 UA，表现为**所有请求 403** —— 看起来像 Key 失效，其实是 UA 被拦。`uw.py` 已内置伪装 UA，`uw.ps1` 靠 Invoke-WebRequest 的默认 UA 就够。

## 先跑这个

```powershell
# 本机 python.exe 是 Store 占位符，py launcher 指向已删除的 3.12 —— 用 PowerShell 版
$S = "C:\Users\dingzhaoyi\.agents\skills\unusual-whales-relay\scripts\uw.ps1"
& $S selftest                      # 4 项健康检查
& $S gex SPY                       # GEX 关键位
& $S exposure SPY 5                # 最近 5 分钟 dealer greeks
& $S flow 10                       # 最新 flow alerts
& $S tide                          # market tide 末根
& $S matrix                        # 打印可用性统计
& $S raw /api/stock/SPY/greek-exposure/strike 'min_strike=700&max_strike=740'
```

Python 版 `scripts/uw.py`（stdlib only，同一套子命令）。本机 `python.exe` / `py.exe` 都是坏的（Store 占位符 + 指向已删除的 3.12），但 `uv` 可用 —— `uv run --python 3.12 --no-project uw.py selftest` 已实测 6/6 通过。两版都内置了 Cloudflare 需要的 User-Agent。

`scripts/probe.ps1 -Out matrix.csv` 重跑全量可用性探测（238 端点，约 40 秒，走 HttpClient 并发）。

## 能拿到什么（按开发用途）

| 要什么 | 端点 | 形态 |
|---|---|---|
| GEX 关键位（call/put wall、gamma flip、magnet） | `/api/stock/{t}/gex-levels` | 单对象，日更 |
| Dealer greeks 每分钟序列（gamma/charm/vanna） | `/api/stock/{t}/spot-exposures` | 约 517 行/日，1min |
| Dealer greeks 按 strike（含 bid/ask/vol/oi 四套） | `/api/stock/{t}/spot-exposures/strike` | 551 行，快照 |
| 按 strike+expiry | `/api/stock/{t}/spot-exposures/expiry-strike?expirations[]=DATE` | 需 `expirations[]` |
| 按 expiry 的 GEX | `/api/stock/{t}/spot-exposures/{EXPIRY}/strike` | 190 行/到期 |
| 日频 greeks 序列（历史） | `/api/stock/{t}/greek-exposure` | 250 行（跨年日频） |
| 按 strike 的日频 greeks + GEX | `/api/stock/{t}/greek-exposure/strike` | 551 行 |
| 按 expiry / strike+expiry 的日频 | `/api/stock/{t}/greek-exposure/expiry`, `/strike-expiry` | |
| 每分钟 delta/vega 流量（dir vs total, otm） | `/api/stock/{t}/greek-flow` | 521 行，5min |
| 指定到期的 greek flow | `/api/stock/{t}/greek-flow/{EXPIRY}` | 520 行 |
| Flow alerts（异动聚合，实时） | `/api/option-trades/flow-alerts` | 50 行，秒级更新 |
| 单条 alert 详情 | `/api/option-trades/flow-alerts/{uuid}` | |
| 期权逐笔 | `/api/option-trades` | 最新交易日 |
| 历史逐笔全量 | `/api/option-trades/full-tape/{DATE}` | |
| 期权筛选器 / 热门链 | `/api/screener/option-contracts` | 50+ 字段 |
| 个股近期 flow | `/api/stock/{t}/flow-recent` | |
| 暗池（全市场 / 单票） | `/api/darkpool/recent`, `/api/darkpool/{t}` | 100 行 |
| 暗池价位 | `/api/darkpool/{t}/price-levels` | |
| Market Tide（全市场情绪） | `/api/market/market-tide` | 105 根 5min |
| 板块 / ETF tide | `/api/market/{sector}/sector-tide`, `/api/market/{t}/etf-tide` | |
| OI 变化、Top net impact、总期权量 | `/api/market/oi-change`, `/top-net-impact`, `/total-options-volume` | |
| 波动率异常 / 特征 / 定位 | `/api/volatility/anomaly/top?direction=short_vol`, `/character/top`, `/option-sentiment/top` | 需 direction |
| 个股波动率族 | `/api/stock/{t}/volatility/{anomaly,character,context,option-sentiment}` | |
| IV 插值分布 / 期限结构 | `/api/stock/{t}/interpolated-iv/distribution`, `/volatility/term-structure/distribution` | |
| 合约链 + 单合约 greeks | `/api/stock/{t}/option-contracts`, `/api/stock/{t}/greeks` | 固定 201 行，忽略 limit |
| 单合约盘中/历史/flow/量价 | `/api/option-contract/{OSI}/{intraday,historic,flow,volume-profile}` | OSI 合约符号 |
| 内部人 / 国会 | `/api/insider/transactions`, `/api/congress/recent-trades` | 500 / 100 行 |
| 新闻 | `/api/news/headlines` | 50 行 |
| 暗池外 lit flow | `/api/lit-flow/recent`, `/api/lit-flow/{t}` | 100 行 |
| 期货合约表 | `/api/futures/contracts` | 200 行 |
| 相关性 | `/api/market/correlations?tickers=AAPL,SPY,JPM` | 需 tickers |
| 企业事件 | `/api/earnings/{t}`, `/api/calendar/*`, `/api/market/economic-calendar` | |

完整 238 条见 `references/endpoints.md`；字段级 schema 见 `references/schemas.md`；WebSocket 见 `references/websocket.md`。

## 拿不到的（别浪费时间）

**上游套餐缺权限（403，永久）：** `/api/analytics/{sliding,window}`、`/api/calendar/ipo`、`/api/market/movers`、`/api/companies/*`（profile、dividends、splits、earnings-estimates、transcripts）、`/api/companies/listings`、`/api/commodities/{name}`、`/api/forex/*`、`/api/digital-currencies/*`。

**需要另买 add-on（403）：** politics/FEC 全套、`/api/volatility/vix-term-structure`。

**"Missing access"（422，同样是没买）：** `/api/private-markets/*`、`/api/politician-portfolios/*`、`/api/congress/unusual-trades/*`、`/api/stock/{t}/ownership`、`/api/option-trades/optionable-tickers`、`/api/predictions/*`。

**上游暂时坏（503）：** `/api/futures/{contract}/{candles,stats,trades}`（QuantData 源不可用）、`/api/futures/display_factors*`（404 not supported）。

**crypto 基本空：** `/api/crypto/{pair}/state` 返回 `data:null`，`/ohlc/{size}` 返回 `[]`；只有 `/api/crypto/whales/recent`（500 行）和 `/api/crypto/list_tokens` 可用。

## 中转站健康状况

`GET /unusualwhales` 返回服务自述 + 健康报告。抓取时的实测：

- `upstream_plan: Advanced`，`relay_price_ratio: 5.9%`，`mode: live_proxy`
- `operational_health.status: degraded`，17–21 项 issue（数量随时间浮动），集中在商品/期货投递、期权盘中、QuantData 会话、predictions 延迟
- 限流：`x-ratelimit-limit: 1000000` / 60s（等于不限）；实际瓶颈是上游延迟
- 延迟实测：REST 1–2.5 s/请求，大响应（spot-exposures 290KB、spot-exposures/strike 480KB）偏慢
- 响应头有 `x-api-relay-cache: MISS|HIT` 和 `x-unusual-whales-upstream-key-index`

## 参数与返回约定

- 列表参数用方括号重复：`?expirations[]=2026-11-27&expirations[]=2026-12-19`、`?tags[]=ask_side`。
- 常用参数实测有效：`limit`、`ticker_symbol`、`min_premium`、`type`、`is_otm`、`min_strike`、`max_strike`、`date`、`direction`。
- 有端点**忽略** `limit`（`/greeks` 恒 201 行、`/greek-flow` 恒约 521 行）—— 返回固定形状，别当成 bug。
- 顶层恒为 `{"data": ...}`；`market-tide` 额外有顶层 `date`。
- 数值型价格常是**字符串**（`"347.9309"`、`"0.05"`），转化时别直接当 float 用。
- `flow-alerts.start_time` / `end_time` 是 epoch **毫秒**；`created_at` 是 ISO8601 UTC。
- 分页：`page` + `limit`（部分端点），或时间游标 `newer_than` / `older_than`。

## 数据语义速查

- `gex-levels.call_wall`：call gamma 堆积的价位，做市商在此上方对冲卖出会压制价格。
- `gamma_flip`：总 gamma 变号价位，之上做市商追涨杀跌（放大波动），之下反向（抑制波动）。`nearby_flips` 是邻近次要点位。
- `gamma_magnet`：gamma 最密集价位，价格倾向被吸附。
- `spot-exposures.*_per_one_percent_move_{oi,vol,dir}`：标的每动 1% 的 dealer greek 敞口；`oi` 用持仓算、`vol` 用成交量算、`dir` 用方向性成交算。三者分歧大 = 当日成交与历史持仓态度不一致。
- `greek-flow.dir_*` vs `total_*`：`dir` 含方向（买/卖），`total` 不分方向。`otm_*` 只看虚值。
- `flow-alerts.alert_rule`：`RepeatedHits`（同合约反复成交）、`RepeatedHitsDescendingFill`（递降成交价反复打）等，是上游聚合规则。
- `darkpool` 行 `market_center` 是交易所代码，`ext_hour_sold_codes: extended_hours_trade` 表示盘外成交。

## 汇报口径

- 明确数据时点（`time` / `created_at` / `trade_date`），美股数据以 ET 交易日为准，接口时间是 UTC。
- 区分「观测到的成交」与「按模型推算的敞口」。
- 期权数据是美股，别和 A 股/加密混谈。