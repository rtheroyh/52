# 0DTE 期权功能规划

> 说明：本文将用户所说的 `ODTE` 按行业通常含义理解为 **0DTE（zero days to expiration，当日到期）**。本文基于仓库中的 `unusual-whales-relay` skill、238 条 endpoint catalog 以及 2026-11-24 的字段实测整理；目标是先做数据与盘中决策工具，不直接下单。

## 1. 结论：最适合做什么

这套 relay 最适合做一个“0DTE 盘中驾驶舱”，核心不是预测涨跌，而是把以下四类信息在**同一真实到期日**上对齐：

1. **标的与关键价位**：现价、call wall、put wall、gamma flip、gamma magnet，以及按 strike 的 gamma/charm/vanna。
2. **0DTE 链与合约状态**：ATM 附近的 call/put、价差、成交量、OI、IV、Greeks、成交时间。
3. **实时异常流**：大额权利金、volume/OI、sweep、重复击打、bid/ask 方向和 IV 变化。
4. **市场背景与风险**：Market Tide、经济/财报事件、数据新鲜度、WebSocket 断线和上游降级状态。

最终呈现为：**现在价格在哪里 → 0DTE 的流量和 dealer 假设敞口在哪里 → 关键风险位在哪里 → 数据是否足够可靠**。

## 2. 产品边界

### 可以做

- 0DTE 链筛选、ATM 附近合约对比和单合约详情。
- 0DTE 按 strike 的成交量、权利金、OI、volume/OI、IV、delta/gamma/theta/vega 图表。
- 当日到期的 flow scanner、重复成交与大单提醒。
- GEX wall / gamma flip / magnet 和 0DTE strike-level heatmap。
- dealer greek flow 的 5 分钟序列、call/put 与 OTM 过滤。
- WebSocket 实时流、断线重连、REST 回补、数据质量标识。
- 历史 tape/snapshot 采集、盘后 replay 和信号回测。
- 纸上交易/交易日志/风险计算器（输入由用户提供，不连接券商下单）。

### 不应宣称可以做

- **不能把 `gex` / `spot-exposures` 写成真实做市商持仓**：它们是按固定假设从 OI、成交量或方向性成交推算的 dealer exposure。
- 不能仅凭 bid/ask、`all_opening_trades` 或 sweep 就断言“机构开仓/平仓”；这些只能作为信号特征。
- relay 本身没有可靠的券商执行、账户保证金和真实持仓接口；第一版不做自动下单。
- 不调用不存在的 `/0dte` 路径。0DTE 必须先解析当天实际到期日；周六、假日、不存在或已过期日期会返回空数组而不是报错。
- 不把空数组当成“没有机会”，必须同时显示请求日期、数据时间和 endpoint 状态。

## 3. 关键设计原则

### 3.1 0DTE 的定义必须是“真实日期”，不是字符串标签

建立 `expiry_resolver`，以美东交易日为准：

1. 从 `/api/stock/{ticker}/option-contracts` 取当日链；它返回 OSI `option_symbol`，从 OSI 解析 expiry、类型和 strike。
2. 只保留 `expiry == session_date_et` 的合约；不能用本地 UTC 日期直接代替美东日期。
3. 如果链不可用，用 `/api/option-trades/flow-alerts` 中的 `expiry` 或 OSI 作为交叉确认。
4. 将解析结果缓存为 `{ticker, session_date_et, expiry, resolved_at}`，所有后续 endpoint 都复用这个 expiry。
5. 当天无 0DTE 时明确显示“本交易日没有可用的当日到期链”，不要静默切换到次日。

### 3.2 所有数字先规范化再计算

relay 返回的价格、IV、premium、greeks 和 GEX 很多是字符串；统一使用 Decimal/安全 float 转换。统一字段：

- `timestamp_utc`：原始时间保留；展示时转换为 ET/HKT。
- `session_date_et`、`expiry`：`YYYY-MM-DD`。
- `strike`、`underlying_price`、`bid`、`ask`、`last_price`：数值。
- `premium`、`gex`、`delta_flow` 等：可保留 Decimal 精度。
- `as_of`、`source`、`stale_after`、`gap_possible`：所有图表必带数据质量元信息。

### 3.3 “信号”与“事实”分栏

- 事实：成交了多少、在哪个 strike、价格相对 bid/ask、OI/volume、IV 变化、服务器时间。
- 推断：可能的主动买卖、异常分数、gamma regime、关键价位反应。
- 界面用“观察到的成交”“按模型推算的敞口”“启发式信号”三个标签，避免将推断写成确定性结论。

## 4. MVP 功能范围

### MVP-1：0DTE 盘前/盘中总览

**目标**：输入一个 ticker，在一个页面看懂当日到期链和风险地图。

| 模块 | 展示内容 | 主要数据源 | 建议刷新 |
|---|---|---|---|
| 标的卡片 | 现价、日内涨跌、交易时段、数据时间 | `/api/stock/{ticker}/quote`、`/ohlc/{candle_size}` | 15–30 秒 |
| 到期日卡片 | ET 交易日、真实 expiry、合约数量、是否 0DTE | `/api/stock/{ticker}/option-contracts` + OSI 解析 | 30–60 秒 |
| 关键位 | call wall、put wall、gamma flip、magnet、nearby flips | `/api/stock/{ticker}/gex-levels` | 60 秒 |
| 0DTE 热力图 | strike × call/put 的 gamma、charm、vanna、delta | `/spot-exposures/expiry-strike?expirations[]=YYYY-MM-DD` | 30–60 秒 |
| 0DTE 链 | ATM ± N 个 strike 的 bid/ask、last、IV、Greeks、OI、volume | `/stock/{ticker}/option-contracts`，解析 OSI 后过滤 | 15–30 秒 |
| 市场背景 | net call premium、net put premium、net volume | `/api/market/market-tide` | 5 分钟 |
| 风险横幅 | 数据时间、stale、403/422、上游 degraded、WebSocket gap | relay 响应和本地质量检查 | 每次请求 |

第一版建议支持 `SPY / QQQ / IWM / SPX / NDX` 等高流动性标的，但 ticker 应配置化，不能在代码中写死。

### MVP-2：0DTE Flow Scanner

**目标**：在全市场或指定 ticker 中找出值得人工复核的当日到期异常成交。

数据源：

- `/api/option-trades/flow-alerts`
- `/api/option-trades`（最新逐笔）
- `/api/screener/option-contracts`
- `/api/stock/{ticker}/flow-alerts`、`flow-recent`

筛选条件：

- 精确 expiry 为当日真实到期日。
- ticker、call/put、ITM/OTM、delta 区间、距离 ATM 百分比。
- 最低总权利金、volume/OI、volume 大于 OI、trade_count。
- sweep/floor/multi-leg、bid/ask side、IV start/end 变化。
- `RepeatedHits` / `RepeatedHitsDescendingFill` 等规则。

每一条结果显示：

```text
ticker · expiry · C/P · strike · OSI
underlying_price · delta/gamma/theta/vega · IV
last/avg/bid/ask · total_size · volume/OI · total_premium
bid-side premium · ask-side premium · trade_count
alert_rule · created_at · start_time/end_time · 数据来源
```

重要实现细节：flow-alerts 的实测参数没有“0DTE”快捷值，应取回结果后再次按 `expiry` 严格过滤；`start_time/end_time` 是 epoch 毫秒，`created_at` 是 UTC ISO8601。

### MVP-3：0DTE Flow + Greek Flow 联动

**目标**：把“单笔异常”与“整个到期日的流量”分开，避免只看一笔大单。

- `/api/stock/{ticker}/greek-flow/{expiry}`：5 分钟桶，展示 `dir_delta_flow`、`dir_vega_flow`、OTM 和 total 版本。
- 用 0DTE expiry 过滤 flow-alerts，再与最近 5 分钟 greek flow 对齐。
- 计算并标注：call/put 权利金差、主动方向代理、OTM flow、delta/vega flow 的变化率。
- 允许用户切换 `dir` 与 `total`：`dir` 带方向假设，`total` 不带方向；两者差异本身是信息。
- 不把正负 greek flow 直接翻译成“必涨/必跌”，页面显示原始指标和说明。

### MVP-4：可解释的 GEX / Dealer Map

**目标**：回答“价格接近哪些 0DTE strike，穿越之后可能发生什么”，而不是给出无依据的交易指令。

- 全市场/标的关键位：`gex-levels`。
- 0DTE 按 expiry/strike：`spot-exposures/expiry-strike`。
- 盘中序列：`spot-exposures`，关注 gamma、charm、vanna 每分钟变化。
- 每个 strike 显示 call/put、OI/volume/bid/ask 版本，说明使用的计算口径。
- 叠加现价、日内高低、VWAP（若本地自行计算）和 flow 发生的位置。
- 给出“可能的支撑/阻力/放大波动区”标签，但必须显示“assumed dealer exposure”免责声明。

### MVP-5：单合约详情与 0DTE 复盘

用户从 flow scanner 或 heatmap 点击一个 OSI 合约，展示：

- `/api/option-contract/{OSI}/intraday`：盘中价格/成交量序列。
- `/api/option-contract/{OSI}/volume-profile`：成交量分布。
- `/api/option-contract/{OSI}/flow`：合约 flow。
- `/api/option-contract/{OSI}/historic`：历史数据（若该合约有数据）。
- 从 `/stock/{ticker}/option-contracts` 取得最新 NBBO、Greeks、OI、成交量。

OSI 必须来自实时链或 alert，不允许用户手写后直接猜测合约根；页面要显示合约是否仍在当前有效链中。

## 5. 实时架构与降级策略

### 5.1 推荐数据流

```text
expiry resolver
      ↓
REST snapshot ──→ normalized store ──→ 0DTE dashboard
      ↑                    ↑
REST fallback ← WebSocket collector ← ticket + channel join
      ↓
raw event/snapshot archive ──→ replay / backtest / data-quality report
```

### 5.2 WebSocket 订阅建议

一个 ticker 的第一版最多订阅：

- `flow-alerts:{TICKER}`：指定标的异常流。
- `option_trades:{TICKER}`：逐笔流。
- `option_minutes:{OSI}`：用户当前选中的 1 个或少量合约。
- 可选 `gex:{TICKER}` / `gex_strike:{TICKER}`（支持且数据稳定时启用）。

硬限制是单连接最多 12 个频道。票据有效期 60 秒，票据只用于获取 WebSocket URL，不把长期 key 放在 URL 中。

### 5.3 必须做的容错

1. WebSocket 断线后重连并显示 `gap_possible`。
2. 断线区间用 `/api/option-trades/full-tape/{DATE}` 回补；无法回补时不要伪造 K 线。
3. WebSocket 无数据或 QuantData 重连时，退回 `/flow-alerts` REST 轮询。
4. 403 视为套餐/add-on 权限不足，不重试；422/400 先修正日期或参数，不重试同一请求。
5. 使用已提供的 User-Agent；裸默认 Python/Go User-Agent 可能被 Cloudflare 以 1010 拦截。
6. 对 1–2.5 秒的 relay 延迟做缓存、去重和请求合并；大响应 `spot-exposures` 不要每秒重复拉取。

## 6. 建议的本地 API / 数据模型

建议不要让前端直接拼 relay URL，而由后端提供稳定的产品 API：

```text
GET /api/0dte/{ticker}/context
GET /api/0dte/{ticker}/chain?around=atm&width=10
GET /api/0dte/{ticker}/flow?min_premium=...
GET /api/0dte/{ticker}/levels
GET /api/0dte/{ticker}/quality
GET /api/0dte/{ticker}/contracts/{osi}
WS  /api/0dte/stream?ticker=...
```

统一返回结构建议：

```json
{
  "ticker": "SPY",
  "session_date_et": "YYYY-MM-DD",
  "expiry": "YYYY-MM-DD",
  "is_0dte": true,
  "as_of": "UTC ISO8601",
  "data_quality": {
    "source": "rest|websocket|mixed",
    "stale": false,
    "gap_possible": false,
    "warnings": []
  },
  "data": {}
}
```

缓存 key 至少包含 `ticker + expiry + endpoint + query`，避免把前一交易日或下一到期日的数据误显示成 0DTE。

## 7. 信号评分：只做可解释的排序，不做方向性承诺

可以做一个 0–100 的 `attention_score`，用于排序而不是买卖建议。示例特征：

- 30%：total premium 的相对排名。
- 20%：volume/OI 与 size > OI。
- 15%：sweep/repeated hits 等结构特征。
- 15%：相对 bid/ask 的成交位置与 bid/ask premium 差。
- 10%：IV start/end 变化。
- 10%：距现价、gamma wall/flip 的距离。

每个分数旁边提供特征贡献和原始字段；缺字段时降低置信度而不是填 0 后假装有数据。评分需要用历史采集数据校准，不能在没有样本时宣称有 alpha。

## 8. 第二阶段可扩展功能

1. **盘中 replay/backtest**：按 ET 交易日回放 flow、greek flow、GEX snapshot，比较信号出现后 1/5/15 分钟的标的和合约变化。
2. **多标的 watchlist**：只为用户关注的 ticker 分配 WS 频道，超过 12 个频道时拆连接或只用 REST。
3. **事件风险层**：合并 earnings、economic calendar、news headline，并在 0DTE 页面上显示事件时间与数据来源。
4. **策略模板**：如 gamma pin、breakout after flip、premium/IV expansion、repeated-hit review；每个模板输出触发条件、反例和失效时间。
5. **纸上交易与日志**：记录进入理由、expiry、OSI、预期风险、退出原因、滑点和复盘结果；不模拟真实成交保证。
6. **通知**：将筛选器结果通过站内通知/邮件/Telegram 等外层渠道发送，通知内容必须包含 as-of、expiry 和数据质量。
7. **风险计算器**：根据用户输入的账户净值、最大亏损、合约乘数和止损价计算纸上仓位；不读取或推断券商保证金。

## 9. 里程碑与验收标准

### 第 0 步：数据基础（1 个短迭代）

- [ ] `X-API-Key` 只从环境变量或本机配置读取，不进前端、不写日志、不提交仓库。
- [ ] REST client 带 User-Agent、超时、JSON 错误解析和无重试的 403/422 分类。
- [ ] OSI 解析器有真实 expiry、strike、call/put 的单元测试。
- [ ] ET session date 与 UTC 转换有跨午夜/周末/假日测试。
- [ ] 所有金额/价格/IV/Greeks 的字符串转换有测试。

### 第 1 步：MVP 看板

- [ ] 输入 SPY，在有当日链时能显示正确 `expiry == session_date_et`。
- [ ] 明确区分 0DTE、次日到期和无 0DTE，不会因空数组误判。
- [ ] 关键位、链、flow、greek flow 的 as-of 时间可见。
- [ ] 任意一个 0DTE flow 点击后能打开对应 OSI 合约详情。
- [ ] GEX/greek exposure 旁有 assumed dealer exposure 说明。

### 第 2 步：实时与质量

- [ ] WebSocket 断线、重连、gap_possible、REST fallback 均可在 UI 观察。
- [ ] 用 full tape 回补后不会重复计数；无法回补时标记缺口。
- [ ] 上游返回 403、422、空数组、503 时有不同提示。
- [ ] 记录请求耗时、HTTP 状态、数据行数和最后更新时间。

### 第 3 步：验证后才做评分/回测

- [ ] 至少收集多个交易日的原始快照/tape 后再冻结评分权重。
- [ ] 训练/评估按交易日切分，避免把同一盘中的未来数据泄漏到信号。
- [ ] 报告命中率时同时报告样本量、滑点、bid/ask、手续费、缺失数据和最大回撤。
- [ ] UI 文案不使用“稳赚”“机构必然开仓”等不可验证表述。

## 10. 建议的实现顺序

```text
1. relay client + secret hygiene + error/quality model
2. ET expiry resolver + OSI parser
3. /0dte/{ticker}/context（chain + levels + market tide）
4. chain table + strike heatmap
5. flow scanner + exact expiry filter
6. greek-flow alignment
7. single-contract detail
8. WebSocket + REST fallback + gap repair
9. raw archive + replay
10. explainable score + paper journal
```

第一版做到第 6 步就已经是可用的 0DTE 期权工具；实时 WebSocket、回放和评分属于增强项，不应在数据质量尚未稳定时先做自动交易。

## 参考资料

- `unusual-whales-relay/SKILL.md`：relay 认证、数据语义、权限和硬限制。
- `unusual-whales-relay/references/endpoints.md`：权威 endpoint 目录。
- `unusual-whales-relay/references/schemas.md`：已实测字段与参数。
- `unusual-whales-relay/references/websocket.md`：票据、频道、断线和回补规则。
