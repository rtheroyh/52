# 字段级 schema（全部为实测，2026-11-24 抓取）

价格/IV 类字段常为字符串。`time` / `created_at` 为 UTC ISO8601。`*_oi` 用持仓推算，`*_vol` 用成交量，`*_dir` 用方向性成交。

## /api/stock/{ticker}/gex-levels

单对象，日更（美股开盘后更新，抓取时 time=前一日 21:15Z）。

```json
{"data":{
  "call_wall":"350", "put_wall":"330",
  "gamma_flip":"347.6", "gamma_magnet":"350",
  "nearby_flips":["347.6","352.2","345.8","354.94","355.75"],
  "date":"2026-11-23", "time":"2026-11-23T21:15:00.000000Z", "source":"vol"
}}
```

`source` 取值 `vol`（用成交量算）或 oi。全部为字符串，需自行转 float。

## /api/stock/{ticker}/spot-exposures

每分钟一行，约 517 行/交易日。

```
ticker, ticker_id, price, time, start_time,
gamma_per_one_percent_move_oi,  gamma_per_one_percent_move_vol,  gamma_per_one_percent_move_dir,
charm_per_one_percent_move_oi,  charm_per_one_percent_move_vol,  charm_per_one_percent_move_dir,
vanna_per_one_percent_move_oi,  vanna_per_one_percent_move_vol,  vanna_per_one_percent_move_dir
```

样例：`price=723.51 gamma_..oi=-6458200965.02 gamma_..dir=2343554957.76 charm_..oi=-9216371104224.81 vanna_..oi=852850338.76`

`start_time` 是整分钟，`time` 是落库时刻（带微秒）。

## /api/stock/{ticker}/spot-exposures/strike

快照，551 行（全 strike 范围，默认升序 —— 从 strike=50 开始，取 ATM 附近要传 `min_strike`/`max_strike`）。

36 字段 = `{call,put} × {delta,gamma,vanna,charm} × {oi,vol,bid,ask}` + `strike, price, ticker, time, date`。

```
call_gamma_oi, call_gamma_vol, call_gamma_bid, call_gamma_ask,
put_gamma_oi,  put_gamma_vol,  put_gamma_bid,  put_gamma_ask,
... 同样四套 × delta / vanna / charm
```

注意 `strike` 是数字（50），不似 gex-levels 的字符串。`price` 是当时标的价。

## /api/stock/{ticker}/spot-exposures/expiry-strike

参数 `expirations[]`（必填，真实到期日）。32 字段同上但不含 expiry 列 —— 到期日靠参数区分。不传 `expirations[]` 返回空。

## /api/stock/{ticker}/spot-exposures/{EXPIRY}/strike

每日更，190 行/到期。同上结构，路径里的 EXPIRY 必须是真实到期日。

## /api/stock/{ticker}/greek-exposure

日频历史序列，250 行（跨年）。

```
date, call_delta, call_gamma, call_vanna, call_charm,
      put_delta,  put_gamma,  put_vanna,  put_charm
```

样例：`date=2025-11-25 call_charm=-237704368.6132 call_delta=170236703.8884 put_vanna=-415054400.0685`

## /api/stock/{ticker}/greek-exposure/strike

日频按 strike，551 行。

```
date, strike, call_charm, call_delta, call_gex, call_vanna,
              put_charm,  put_delta,  put_gex,  put_vanna
```

注意这里字段名是 `call_gex` / `put_gex`（不是 `*_gamma`）。`/greek-exposure` 用 `*_gamma`，两者命名不一致。

## /api/stock/{ticker}/greek-flow

5 分钟桶，约 521 行/交易日。

```
timestamp, ticker, transactions, volume,
dir_delta_flow,        dir_vega_flow,
otm_dir_delta_flow,    otm_dir_vega_flow,
otm_total_delta_flow,  otm_total_vega_flow,
total_delta_flow,      total_vega_flow
```

高精度小数字符串（`-26667.532921366020100300`），解析用 decimal 或直接 float 均可。

## /api/stock/{ticker}/greek-flow/{EXPIRY}

同上，按单个到期日，520 行。

## /api/option-trades/flow-alerts

实时聚合异动，50 行/批，秒级更新（实测 `created_at` 与请求时刻同秒）。

```
id (uuid), rule_id (uuid), ticker, option_chain (OSI), type (call|put),
strike, expiry, price, bid, ask, theo, delta, gamma, theta, vega, rho, iv,
iv_start, iv_end, volume, open_interest, total_size, trade_count,
total_premium, total_bid_side_prem, total_ask_side_prem,
volume_oi_ratio, alert_rule, underlying_price, marketcap,
sector, issue_type, next_earnings_date, er_time,
has_singleleg, has_multileg, has_sweep, has_floor, all_opening_trades,
start_time, end_time (epoch ms), created_at (ISO8601)
```

`alert_rule` 实测值：`RepeatedHits`、`RepeatedHitsDescendingFill`。
参数：`limit`、`ticker_symbol`、`min_premium`、`is_call`、`is_put`、`is_otm`、`size_greater_oi`。

## /api/screener/option-contracts

热门链筛选，50+ 字段。

```
ticker_symbol, option_symbol (OSI), option_type, strike, expiry,
stock_price, premium, volume, open_interest, prev_oi, avg_price, close, open, high, low,
ask_side_volume, bid_side_volume, no_side_volume, mid_volume, multileg_volume,
sweep_volume, floor_volume, cross_volume, stock_multi_leg_volume, trades,
delta, gamma, theta, vega, iv_change, prev_iv, roc, last_fill,
ask_side_perc_7_day, bid_side_perc_7_day, total_ask_changes, total_bid_changes,
days_of_oi_increases, days_of_vol_greater_than_oi, vol_pctile_15d,
sector, issue_type, next_earnings_date, er_time, is_new
```

参数：`limit`、`type`（Calls/Puts）、`is_otm`、`min_premium`、`min_volume`、`min_volume_oi_ratio`、`min_ask_perc`、`max_dte`、`issue_types[]`。

## /api/stock/{ticker}/option-contracts

链上每合约的希腊值与当日量。恒定 201 行，**忽略 limit**。

```
option_symbol (OSI), delta, gamma, theta, vega, rho, implied_volatility,
open_interest, prev_oi, volume, last_price, nbbo_bid, nbbo_ask, avg_price,
ask_volume, bid_volume, mid_volume, sweep_volume, multi_leg_volume,
stock_multi_leg_volume, no_side_volume, floor_volume, high_price, low_price,
total_premium, last_tape_time
```

无 `expiry` / `strike` 列 —— 从 OSI 解析：`SPY261123C00725000` = SPY / 2026-11-23 / C / 725.000。

## /api/market/market-tide

105 行 5 分钟，顶层另有 `date`。

```
timestamp (带 -05:00 偏移), date,
net_call_premium, net_put_premium, net_volume
```

`net_volume` 为负表示 put 占优。premium 是字符串化定点小数（`"654703102.0000"`）。

## /api/darkpool/recent 与 /api/darkpool/{ticker}

100 行，字段一致：

```
ticker, price, size, volume, premium, executed_at, trf_executed_at,
canceled, sale_cond_codes, trade_code, trade_settlement,
market_center, ext_hour_sold_codes,
nbbo_bid, nbbo_ask, nbbo_bid_quantity, nbbo_ask_quantity, tracking_id
```

## /api/stock/{ticker}/volatility/character 等）

`/volatility/anomaly`、`/character`、`/context`、`/option-sentiment`、`/variance-risk-premium` 均为 `{"data": {...}}` 或小数组，字段随端点变化；先取一次看键名再用。
`/volatility/anomaly/top`、`/character/top`、`/option-sentiment/top` 需 `direction`：

- anomaly：`direction=short_vol|long_vol`
- 其余 top 端点取对应 direction 值，缺参会 422。

## /api/stock/{ticker}/greeks

单合约希腊值全链，恒定 201 行，忽略 limit。字段以 `*_per_*` 形式存在，取一次确认。

## /api/market/correlations

必填 `tickers=A,B,C`（逗号分隔，不要用 `tickers[]`）。返回 6 行相关矩阵。缺参 400。

## /api/insider/transactions

500 行。`/api/congress/recent-trades` 100 行。`/api/news/headlines` 50 行。`/api/lit-flow/recent` 100 行。`/api/futures/contracts` 200 行。

## 通用错误体

```json
{"code":"advanced_tier_required","message":"This endpoint requires the Advanced API tier or higher..."}
{"code":"politics_scope_required","message":"This endpoint requires the Politics data add-on..."}
{"code":"volatility_scope_required","message":"..."}
{"path":"...","msg":"Missing access for private markets. This is a paid add-on..."}
{"path":"...","msg":"Invalid path input: 0dte (0dte is not a valid input...)"}
{"error":"Invalid UUID format"}   // flow-alerts/{id} 传了非 uuid
```

`422` = 参数/路径值不合法或未购买；`400` = 必填参数缺失；两者都不该重试同一请求。