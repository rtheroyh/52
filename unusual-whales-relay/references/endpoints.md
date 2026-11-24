# Unusual Whales Relay - 238 endpoints

Base: https://ai-tool.indevs.in   Auth: X-API-Key (or Authorization: Bearer)

## alerts  (5)  - 异动告警
- `GET /unusualwhales/api/alerts`  - Alerts
- `GET /unusualwhales/api/alerts/configuration`  - Alert configurations
- `GET /unusualwhales/api/alerts/filters`  - Alert filters
- `GET /unusualwhales/api/alerts/query/grammar`  - Query grammar
- `POST /unusualwhales/api/alerts/configuration`  - Create or update own alert configuration

## commodities  (1)  - 大宗商品数据
- `GET /unusualwhales/api/commodities/{name}`  - Commodity Series

## companies  (5)  - 公司信息与基本面
- `GET /unusualwhales/api/companies/{ticker}/dividends`  - Company Dividends
- `GET /unusualwhales/api/companies/{ticker}/earnings-estimates`  - Forward Earnings Estimates
- `GET /unusualwhales/api/companies/{ticker}/profile`  - Company Profile
- `GET /unusualwhales/api/companies/{ticker}/splits`  - Company Stock Splits
- `GET /unusualwhales/api/companies/{ticker}/transcripts/{quarter}`  - Earnings Call Transcript

## congress  (4)  - 国会议员交易
- `GET /unusualwhales/api/congress/congress-trader`  - Recent Reports By Trader
- `GET /unusualwhales/api/congress/late-reports`  - Recent Late Reports
- `GET /unusualwhales/api/congress/politicians`  - List of Politicians with Trade Data
- `GET /unusualwhales/api/congress/recent-trades`  - Recent Congress Trades

## crypto  (13)  - 加密资产数据
- `GET /unusualwhales/api/crypto/candles/{interval}`  - Get Crypto API OHLC Candles.
- `GET /unusualwhales/api/crypto/list_tokens`  - Get a list of tokens.
- `GET /unusualwhales/api/crypto/options/chain`  - Crypto Options Chain
- `GET /unusualwhales/api/crypto/options/instruments`  - Crypto Options Instruments
- `GET /unusualwhales/api/crypto/options/volatility/latest`  - Crypto Volatility Indexes
- `GET /unusualwhales/api/crypto/options/volatility/surface`  - Crypto Options Volatility Surface
- `GET /unusualwhales/api/crypto/options/volatility/term-structure`  - Crypto Options Term Structure
- `GET /unusualwhales/api/crypto/token/{token}`  - Get token metadata.
- `GET /unusualwhales/api/crypto/trades`  - Get a list of trades.
- `GET /unusualwhales/api/crypto/whale-transactions`  - Crypto Whale Transactions
- `GET /unusualwhales/api/crypto/whales/recent`  - Recent Crypto Whale Trades
- `GET /unusualwhales/api/crypto/{pair}/ohlc/{candle_size}`  - Crypto OHLC Candles
- `GET /unusualwhales/api/crypto/{pair}/state`  - Crypto Pair State

## darkpool  (3)  - 暗池成交
- `GET /unusualwhales/api/darkpool/recent`  - Recent Darkpool Trades
- `GET /unusualwhales/api/darkpool/{ticker}`  - Ticker Darkpool Trades
- `GET /unusualwhales/api/darkpool/{ticker}/price-levels`  - Darkpool Price Levels

## digital_currencies  (2)  - 数字货币数据
- `GET /unusualwhales/api/digital-currencies/history`  - Digital Currency Historical Series
- `GET /unusualwhales/api/digital-currencies/intraday`  - Digital Currency Intraday Series

## earnings  (3)  - 财报与业绩日历
- `GET /unusualwhales/api/earnings/afterhours`  - Afterhours
- `GET /unusualwhales/api/earnings/premarket`  - Premarket
- `GET /unusualwhales/api/earnings/{ticker}`  - Historical Ticker Earnings

## economy  (1)  - 宏观经济数据
- `GET /unusualwhales/api/economy/{indicator}`  - Economic Indicator

## etfs  (5)  - ETF 持仓与资金流
- `GET /unusualwhales/api/etfs/{ticker}/exposure`  - Exposure
- `GET /unusualwhales/api/etfs/{ticker}/holdings`  - Holdings
- `GET /unusualwhales/api/etfs/{ticker}/in-outflow`  - Inflow & Outflow
- `GET /unusualwhales/api/etfs/{ticker}/info`  - Information
- `GET /unusualwhales/api/etfs/{ticker}/weights`  - Sector & Country weights

## flex-options  (4)  - flex-options
- `GET /unusualwhales/api/flex-options`  - FLEX option contracts
- `GET /unusualwhales/api/flex-options/chain/{chain}`  - FLEX option contract history
- `GET /unusualwhales/api/flex-options/market`  - FLEX market overview
- `GET /unusualwhales/api/flex-options/{ticker}`  - FLEX ticker history

## forex  (3)  - 外汇数据
- `GET /unusualwhales/api/forex/history`  - FX Historical Series
- `GET /unusualwhales/api/forex/intraday`  - FX Intraday Series
- `GET /unusualwhales/api/forex/rate`  - FX Spot Rate

## Futures  (8)  - Futures
- `GET /unusualwhales/api/futures/contracts`  - Futures Contracts
- `GET /unusualwhales/api/futures/display_factors`  - Futures Display Factors
- `GET /unusualwhales/api/futures/display_factors/{security_id}`  - Futures Display Factor
- `GET /unusualwhales/api/futures/display_factors/{security_id}/history`  - Futures Display Factor History
- `GET /unusualwhales/api/futures/flow`  - Futures Flow
- `GET /unusualwhales/api/futures/{contract}/candles`  - Futures Candles (OHLCV)
- `GET /unusualwhales/api/futures/{contract}/stats`  - Futures Session Stats
- `GET /unusualwhales/api/futures/{contract}/trades`  - Futures Trades (Time & Sales)

## Gex/Greeks  (11)  - GEX 与希腊值暴露
- `GET /unusualwhales/api/stock/{ticker}/gex-levels`  - GEX Levels
- `GET /unusualwhales/api/stock/{ticker}/greek-exposure`  - Greek Exposure
- `GET /unusualwhales/api/stock/{ticker}/greek-exposure/expiry`  - Greek Exposure By Expiry
- `GET /unusualwhales/api/stock/{ticker}/greek-exposure/strike`  - Greek Exposure By Strike
- `GET /unusualwhales/api/stock/{ticker}/greek-exposure/strike-expiry`  - Greek Exposure By Strike And Expiry
- `GET /unusualwhales/api/stock/{ticker}/greek-flow`  - Greek flow
- `GET /unusualwhales/api/stock/{ticker}/greek-flow/{expiry}`  - Greek flow by expiry
- `GET /unusualwhales/api/stock/{ticker}/spot-exposures`  - GEX exposures per 1min
- `GET /unusualwhales/api/stock/{ticker}/spot-exposures/expiry-strike`  - GEX exposures by strike & expiry
- `GET /unusualwhales/api/stock/{ticker}/spot-exposures/strike`  - GEX exposures by strike
- `GET /unusualwhales/api/stock/{ticker}/spot-exposures/{expiry}/strike`  - GEX exposures by strike & expiry (Deprecated)

## group_flow  (2)  - 分组期权流
- `GET /unusualwhales/api/group-flow/{flow_group}/greek-flow`  - Greek flow
- `GET /unusualwhales/api/group-flow/{flow_group}/greek-flow/{expiry}`  - Greek flow by expiry

## insiders  (4)  - 内部人交易
- `GET /unusualwhales/api/insider/transactions`  - Transactions
- `GET /unusualwhales/api/insider/{sector}/sector-flow`  - Sector Flow
- `GET /unusualwhales/api/insider/{ticker}`  - Insiders
- `GET /unusualwhales/api/insider/{ticker}/ticker-flow`  - Ticker Flow

## institution  (8)  - 机构持仓与机构交易
- `GET /unusualwhales/api/institution/{name}/activity`  - Institutional Activity (Deprecated)
- `GET /unusualwhales/api/institution/{name}/activity/v2`  - Institutional Activity
- `GET /unusualwhales/api/institution/{name}/holdings`  - Institutional Holdings
- `GET /unusualwhales/api/institution/{name}/sectors`  - Sector Exposure
- `GET /unusualwhales/api/institution/{ticker}/option-holders`  - Institutional Option Holders
- `GET /unusualwhales/api/institution/{ticker}/ownership`  - Institutional Ownership
- `GET /unusualwhales/api/institutions`  - List of Institutions
- `GET /unusualwhales/api/institutions/latest_filings`  - Latest Filings

## intel  (5)  - 事件情报与日历
- `GET /unusualwhales/api/analytics/sliding`  - Sliding-Window Analytics
- `GET /unusualwhales/api/analytics/window`  - Fixed-Window Analytics
- `GET /unusualwhales/api/calendar/ipo`  - IPO Calendar
- `GET /unusualwhales/api/companies/listings`  - Active or Delisted Securities
- `GET /unusualwhales/api/market/movers`  - Top Movers

## lit-flow  (2)  - 明池成交流
- `GET /unusualwhales/api/lit-flow/recent`  - Recent Lit Flow Trades
- `GET /unusualwhales/api/lit-flow/{ticker}`  - Ticker Lit Flow Trades

## market  (13)  - 市场广度与 Market Tide
- `GET /unusualwhales/api/market/correlations`  - Correlations
- `GET /unusualwhales/api/market/daily-report`  - Daily Market Report
- `GET /unusualwhales/api/market/economic-calendar`  - Economic calendar
- `GET /unusualwhales/api/market/fda-calendar`  - FDA Calendar
- `GET /unusualwhales/api/market/insider-buy-sells`  - Total Insider Buy & Sells
- `GET /unusualwhales/api/market/market-tide`  - Market Tide
- `GET /unusualwhales/api/market/oi-change`  - OI Change
- `GET /unusualwhales/api/market/sector-etfs`  - Sector Etfs
- `GET /unusualwhales/api/market/top-net-impact`  - Top Net Impact
- `GET /unusualwhales/api/market/total-options-volume`  - Total Options Volume
- `GET /unusualwhales/api/market/{sector}/sector-tide`  - Sector Tide
- `GET /unusualwhales/api/market/{ticker}/etf-tide`  - ETF Tide
- `GET /unusualwhales/api/net-flow/expiry`  - Net Flow Expiry

## news  (1)  - 新闻事件
- `GET /unusualwhales/api/news/headlines`  - News Headlines

## option-contract  (7)  - 期权合约明细
- `GET /unusualwhales/api/option-contract/{id}/flow`  - Flow Data
- `GET /unusualwhales/api/option-contract/{id}/historic`  - Historic Data
- `GET /unusualwhales/api/option-contract/{id}/intraday`  - Intraday Data
- `GET /unusualwhales/api/option-contract/{id}/volume-profile`  - Volume Profile
- `GET /unusualwhales/api/stock/{ticker}/expiry-breakdown`  - Expiry Breakdown
- `GET /unusualwhales/api/stock/{ticker}/option-contracts`  - Option contracts
- `GET /unusualwhales/api/stock/{ticker}/option-stance`  - Option Trade-Stance Ranking

## options-pulse  (4)  - 期权 Pulse 与市场脉冲
- `GET /unusualwhales/api/options-pulse/sectors`  - Options Pulse by Sector/Industry
- `GET /unusualwhales/api/options-pulse/top`  - Options Pulse Scanner
- `GET /unusualwhales/api/options-pulse/total`  - Market-wide Options Pulse
- `GET /unusualwhales/api/stock/{ticker}/options-pulse`  - Options Pulse for a ticker

## option-trade  (8)  - 期权成交与异动流
- `GET /unusualwhales/api/option-trades`  - Option Trades
- `GET /unusualwhales/api/option-trades/exchange-breakdown/{date}`  - Exchange & Trade Code Breakdown
- `GET /unusualwhales/api/option-trades/flow-alerts`  - Flow Alerts
- `GET /unusualwhales/api/option-trades/flow-alerts/{id}`  - Flow Alert by ID
- `GET /unusualwhales/api/option-trades/full-tape/{date}`  - Full Tape
- `GET /unusualwhales/api/option-trades/multi-leg`  - Multi-Leg Option Trades
- `GET /unusualwhales/api/option-trades/multi-leg/{id}/legs`  - Multi-Leg Trade Legs
- `GET /unusualwhales/api/option-trades/optionable-tickers`  - Optionable Tickers

## politician_portfolios  (5)  - 政治人物持仓组合
- `GET /unusualwhales/api/politician-portfolios/disclosures`  - Annual Disclosures List
- `GET /unusualwhales/api/politician-portfolios/holders/{ticker}`  - Politician Portfolio Holders by Ticker
- `GET /unusualwhales/api/politician-portfolios/people`  - Politicians List
- `GET /unusualwhales/api/politician-portfolios/recent_trades`  - Politician Trades
- `GET /unusualwhales/api/politician-portfolios/{politician_id}`  - Politician Portfolios

## politics  (6)  - politics
- `GET /unusualwhales/api/politics/fec/candidates`  - Candidates with company-linked contributions
- `GET /unusualwhales/api/politics/fec/companies`  - Companies with political activity
- `GET /unusualwhales/api/politics/fec/company/{ticker}/lobbying`  - Company lobbying totals and issues
- `GET /unusualwhales/api/politics/fec/company/{ticker}/people`  - People associated with a company
- `GET /unusualwhales/api/politics/fec/contributions`  - Company political contributions
- `GET /unusualwhales/api/politics/politician/trades`  - Politician's trades

## portfolio  (8)  - portfolio
- `GET /unusualwhales/api/portfolio/accounts`  - Portfolio accounts
- `GET /unusualwhales/api/portfolio/catalysts`  - Portfolio catalysts
- `GET /unusualwhales/api/portfolio/edge`  - Portfolio edge
- `GET /unusualwhales/api/portfolio/holdings`  - Portfolio holdings
- `GET /unusualwhales/api/portfolio/performance`  - Portfolio performance
- `GET /unusualwhales/api/portfolio/rank`  - Portfolio Trade Rank
- `GET /unusualwhales/api/portfolio/ticker/{ticker}`  - Portfolio ticker
- `GET /unusualwhales/api/portfolio/trades`  - Portfolio trades

## potus  (2)  - potus
- `GET /unusualwhales/api/potus/posts`  - President's Posts
- `GET /unusualwhales/api/potus/schedule`  - President's Schedule

## predictions  (10)  - 预测市场与事件概率
- `GET /unusualwhales/api/predictions/insiders`  - Prediction Market Insiders
- `GET /unusualwhales/api/predictions/market/{asset_id}`  - Prediction Market Details
- `GET /unusualwhales/api/predictions/market/{asset_id}/liquidity`  - Prediction Market Liquidity
- `GET /unusualwhales/api/predictions/market/{asset_id}/positions`  - Prediction Market Positions
- `GET /unusualwhales/api/predictions/search-users`  - Search Prediction Market Users
- `GET /unusualwhales/api/predictions/smart-money`  - Prediction Smart Money
- `GET /unusualwhales/api/predictions/ticker/{ticker}`  - Prediction Markets for a Ticker
- `GET /unusualwhales/api/predictions/unusual`  - Unusual Prediction Markets
- `GET /unusualwhales/api/predictions/user/{user_id}`  - Prediction Market User
- `GET /unusualwhales/api/predictions/whales`  - Prediction Market Whales

## private_markets  (9)  - 私募市场与非公开公司
- `GET /unusualwhales/api/private-markets/companies`  - List Private Markets Companies
- `GET /unusualwhales/api/private-markets/companies/{npm_ticker}`  - Private Markets Company Profile
- `GET /unusualwhales/api/private-markets/companies/{npm_ticker}/funding`  - Private Markets Funding Rounds
- `GET /unusualwhales/api/private-markets/companies/{npm_ticker}/investors`  - Private Markets Investors for Company
- `GET /unusualwhales/api/private-markets/companies/{npm_ticker}/management`  - Private Markets Management
- `GET /unusualwhales/api/private-markets/companies/{npm_ticker}/pricing`  - Private Markets Pricing History
- `GET /unusualwhales/api/private-markets/investors`  - Top Private Markets Investors
- `GET /unusualwhales/api/private-markets/investors/{name}`  - Private Markets Investor Profile
- `GET /unusualwhales/api/private-markets/search`  - Search Private Markets

## screener  (5)  - 筛选器
- `GET /unusualwhales/api/option-activity/unusual`  - Unusual Options Activity
- `GET /unusualwhales/api/screener/analysts`  - Analyst Rating
- `GET /unusualwhales/api/screener/option-contracts`  - Hottest Chains
- `GET /unusualwhales/api/screener/stocks`  - Stock Screener
- `GET /unusualwhales/api/screener/stocks/dsl`  - Stock screener query language

## seasonality  (4)  - 季节性统计
- `GET /unusualwhales/api/seasonality/market`  - Market Seasonality
- `GET /unusualwhales/api/seasonality/{month}/performers`  - Month Performers
- `GET /unusualwhales/api/seasonality/{ticker}/monthly`  - Average return per month
- `GET /unusualwhales/api/seasonality/{ticker}/year-month`  - Price change per month per year

## sec-filings  (1)  - sec-filings
- `GET /unusualwhales/api/sec-filings`  - SEC Filings

## short  (7)  - 做空数据
- `GET /unusualwhales/api/short_screener`  - Short Screener
- `GET /unusualwhales/api/shorts/{ticker}/data`  - Short Data
- `GET /unusualwhales/api/shorts/{ticker}/ftds`  - Failures to Deliver
- `GET /unusualwhales/api/shorts/{ticker}/interest-float`  - V1 Short Interest and Float (Deprecated)
- `GET /unusualwhales/api/shorts/{ticker}/interest-float/v2`  - V2 Short Interest and Float
- `GET /unusualwhales/api/shorts/{ticker}/volume-and-ratio`  - Short Volume and Ratio
- `GET /unusualwhales/api/shorts/{ticker}/volumes-by-exchange`  - Short Volume By Exchange

## stock  (39)  - 股票行情与基本信息
- `GET /unusualwhales/api/stock/{sector}/tickers`  - Companies in Sector
- `GET /unusualwhales/api/stock/{ticker}/atm-chains`  - ATM Chains
- `GET /unusualwhales/api/stock/{ticker}/balance-sheets`  - Balance Sheets
- `GET /unusualwhales/api/stock/{ticker}/cash-flows`  - Cash Flow Statements
- `GET /unusualwhales/api/stock/{ticker}/earnings`  - Earnings History
- `GET /unusualwhales/api/stock/{ticker}/financials`  - Full Financials
- `GET /unusualwhales/api/stock/{ticker}/flow-alerts`  - Flow Alerts
- `GET /unusualwhales/api/stock/{ticker}/flow-per-expiry`  - Flow per expiry
- `GET /unusualwhales/api/stock/{ticker}/flow-per-strike`  - Flow per strike
- `GET /unusualwhales/api/stock/{ticker}/flow-per-strike-intraday`  - Flow per strike intraday
- `GET /unusualwhales/api/stock/{ticker}/flow-recent`  - Recent flows
- `GET /unusualwhales/api/stock/{ticker}/fundamental-breakdown`  - Fundamental Breakdown
- `GET /unusualwhales/api/stock/{ticker}/greeks`  - Greeks
- `GET /unusualwhales/api/stock/{ticker}/historical-risk-reversal-skew`  - Historical Risk Reversal Skew
- `GET /unusualwhales/api/stock/{ticker}/income-statements`  - Income Statements
- `GET /unusualwhales/api/stock/{ticker}/info`  - Information
- `GET /unusualwhales/api/stock/{ticker}/insider-buy-sells`  - Insider buy & sells
- `GET /unusualwhales/api/stock/{ticker}/interpolated-iv`  - Interpolated IV
- `GET /unusualwhales/api/stock/{ticker}/iv-rank`  - IV Rank
- `GET /unusualwhales/api/stock/{ticker}/max-pain`  - Max Pain
- `GET /unusualwhales/api/stock/{ticker}/net-prem-ticks`  - Call/Put Net/Vol Ticks
- `GET /unusualwhales/api/stock/{ticker}/nope`  - Nope
- `GET /unusualwhales/api/stock/{ticker}/ohlc/{candle_size}`  - OHLC
- `GET /unusualwhales/api/stock/{ticker}/oi-change`  - OI Change
- `GET /unusualwhales/api/stock/{ticker}/oi-per-expiry`  - OI per Expiry
- `GET /unusualwhales/api/stock/{ticker}/oi-per-strike`  - OI per Strike
- `GET /unusualwhales/api/stock/{ticker}/option-chains`  - Option Chains
- `GET /unusualwhales/api/stock/{ticker}/option/stock-price-levels`  - Option Price Levels
- `GET /unusualwhales/api/stock/{ticker}/option/volume-oi-expiry`  - Volume & OI per Expiry
- `GET /unusualwhales/api/stock/{ticker}/options-volume`  - Options Volume
- `GET /unusualwhales/api/stock/{ticker}/ownership`  - Ownership
- `GET /unusualwhales/api/stock/{ticker}/quote`  - Stock Quote
- `GET /unusualwhales/api/stock/{ticker}/stock-state`  - Stock State
- `GET /unusualwhales/api/stock/{ticker}/stock-volume-price-levels`  - Off/Lit Price Levels
- `GET /unusualwhales/api/stock/{ticker}/technical-indicator/{function}`  - Technical Indicator
- `GET /unusualwhales/api/stock/{ticker}/unusualness`  - Volume Unusualness
- `GET /unusualwhales/api/stock/{ticker}/volatility/realized`  - Realized Volatility
- `GET /unusualwhales/api/stock/{ticker}/volatility/stats`  - Volatility Statistics
- `GET /unusualwhales/api/stock/{ticker}/volatility/term-structure`  - Implied Volatility Term Structure

## stock-directory  (1)  - 股票目录与标的检索
- `GET /unusualwhales/api/stock-directory/ticker-exchanges`  - Ticker Exchange Mapping

## unusual_trades  (4)  - 异常交易与异动成交
- `GET /unusualwhales/api/congress/unusual-trades`  - Unusual Congressional Trades
- `GET /unusualwhales/api/congress/unusual-trades/by-tickers`  - Unusual Trades by Ticker
- `GET /unusualwhales/api/congress/unusual-trades/chart-data`  - Unusual Trades Chart Data
- `GET /unusualwhales/api/congress/unusual-trades/stats`  - Unusual Trades Aggregate Stats

## volatility  (13)  - 波动率与风险指标
- `GET /unusualwhales/api/stock/{ticker}/interpolated-iv/distribution`  - Interpolated IV Distribution
- `GET /unusualwhales/api/stock/{ticker}/volatility/anomaly`  - Volatility Anomaly Score
- `GET /unusualwhales/api/stock/{ticker}/volatility/character`  - Volatility Character
- `GET /unusualwhales/api/stock/{ticker}/volatility/context`  - Volatility Context
- `GET /unusualwhales/api/stock/{ticker}/volatility/option-sentiment`  - Options Positioning Sentiment
- `GET /unusualwhales/api/stock/{ticker}/volatility/realized/windows`  - Realized Volatility Windows
- `GET /unusualwhales/api/stock/{ticker}/volatility/term-structure/distribution`  - Implied Volatility Term Structure Distribution
- `GET /unusualwhales/api/stock/{ticker}/volatility/variance-risk-premium`  - Variance Risk Premium
- `GET /unusualwhales/api/stock/{ticker}/volatility/variance-risk-premium/windows`  - Variance Risk Premium Windows
- `GET /unusualwhales/api/volatility/anomaly/top`  - Top Volatility Anomalies
- `GET /unusualwhales/api/volatility/character/top`  - Top Volatility Character
- `GET /unusualwhales/api/volatility/option-sentiment/top`  - Top Options Positioning Sentiment
- `GET /unusualwhales/api/volatility/vix-term-structure`  - VIX Term Structure

## watchlists  (2)  - watchlists
- `GET /unusualwhales/api/watchlists/options`  - Option watchlists
- `GET /unusualwhales/api/watchlists/stocks`  - Stock watchlists

