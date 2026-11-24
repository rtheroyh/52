<#
  Unusual Whales relay client. PowerShell 5.1 compatible.
  uw.ps1 selftest
  uw.ps1 gex SPY
  uw.ps1 exposure SPY [n]
  uw.ps1 strikes SPY [minStrike] [maxStrike]
  uw.ps1 gflow SPY [expiry]
  uw.ps1 flow [n] [ticker]
  uw.ps1 tide
  uw.ps1 darkpool [ticker]
  uw.ps1 raw <path> [queryString]
  uw.ps1 catalog [keyword]
  uw.ps1 matrix
  uw.ps1 ws <channel[,channel]> [seconds]
#>
param(
  [Parameter(Position=0)][string]$Cmd = "selftest",
  [Parameter(Position=1)][string]$A1,
  [Parameter(Position=2)][string]$A2,
  [Parameter(Position=3)][string]$A3
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$BASE = "https://ai-tool.indevs.in"
$HERE = Split-Path -Parent $PSCommandPath

function Get-Key {
  if ($env:RELAY_API_KEY) { return $env:RELAY_API_KEY.Trim() }
  foreach ($p in @((Join-Path $HERE "key.txt"), (Join-Path $HOME ".config\uw-relay\key.txt"))) {
    if (Test-Path $p) { return (Get-Content $p -Raw).Trim() }
  }
  throw "no key: set RELAY_API_KEY or put key.txt next to this script"
}

function Invoke-Relay {
  param([string]$Path, [string]$Query, [int]$Timeout = 45)
  $key = Get-Key
  $u = $BASE + $Path
  if ($Query) { if ($Query.StartsWith("?")) { $u += $Query } else { $u += "?" + $Query } }
  $r = Invoke-WebRequest -Uri $u -Headers @{ "X-API-Key" = $key } -UseBasicParsing -TimeoutSec $Timeout
  $txt = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  return $txt | ConvertFrom-Json
}

function Show-Json($o) { $o | ConvertTo-Json -Depth 8 }

switch ($Cmd.ToLower()) {

  "selftest" {
    $ok = 0
    try { $g = (Invoke-Relay "/unusualwhales/api/stock/SPY/gex-levels").data
          "gex-levels      OK  call_wall=$($g.call_wall) flip=$($g.gamma_flip) put_wall=$($g.put_wall)  asof=$($g.time)"; $ok++ }
    catch { "gex-levels      FAIL  $($_.Exception.Message)" }
    try { $e = (Invoke-Relay "/unusualwhales/api/stock/SPY/spot-exposures").data
          $last = @($e)[-1]
          "spot-exposures  OK  rows=$(@($e).Count) price=$($last.price) at=$($last.time)"; $ok++ }
    catch { "spot-exposures  FAIL  $($_.Exception.Message)" }
    try { $f = (Invoke-Relay "/unusualwhales/api/option-trades/flow-alerts?limit=1").data
          $x = @($f)[0]
          "flow-alerts     OK  $($x.ticker) $($x.type) $($x.strike) $($x.expiry) prem=$($x.total_premium) created=$($x.created_at)"; $ok++ }
    catch { "flow-alerts     FAIL  $($_.Exception.Message)" }
    try { $t = (Invoke-Relay "/unusualwhales/api/market/market-tide")
          "market-tide     OK  date=$($t.date) rows=$(@($t.data).Count)"; $ok++ }
    catch { "market-tide     FAIL  $($_.Exception.Message)" }
    try { $st = (Invoke-WebRequest -Uri "$BASE/unusualwhales/socket-ticket" -Method POST `
                    -Headers @{ "X-API-Key" = (Get-Key) } -UseBasicParsing -TimeoutSec 20).Content
          $s = $st | ConvertFrom-Json
          "socket-ticket   OK  expires_in=$($s.expires_in)"; $ok++ }
    catch { "socket-ticket   FAIL  $($_.Exception.Message)" }
    try { $h = Invoke-Relay "/unusualwhales"
          "relay-health    OK  status=$($h.operational_health.status) issues=$(@($h.operational_health.issues).Count) plan=$($h.upstream_plan)"; $ok++ }
    catch { "relay-health    FAIL  $($_.Exception.Message)" }
    ""
    "$ok/6 checks passed"
  }

  "gex" {
    $t = if ($A1) { $A1.ToUpper() } else { "SPY" }
    $g = (Invoke-Relay "/unusualwhales/api/stock/$t/gex-levels").data
    if (-not $g) { "$t : no gex-levels data"; return }
    [pscustomobject]@{
      ticker = $t; date = $g.date; asof = $g.time; source = $g.source
      price_proxy = $null
      call_wall = [double]$g.call_wall; put_wall = [double]$g.put_wall
      gamma_flip = [double]$g.gamma_flip; gamma_magnet = [double]$g.gamma_magnet
      nearby_flips = ($g.nearby_flips -join " ")
    } | Format-List
  }

  "exposure" {
    $t = if ($A1) { $A1.ToUpper() } else { "SPY" }
    $n = if ($A2) { [int]$A2 } else { 3 }
    $rows = @((Invoke-Relay "/unusualwhales/api/stock/$t/spot-exposures").data)
    "ticker=$t  total=$($rows.Count)  showing last $n"
    $rows | Select-Object -Last $n |
      Select-Object time, price,
        @{n="gamma_oi";e={[double]$_.gamma_per_one_percent_move_oi}},
        @{n="gamma_dir";e={[double]$_.gamma_per_one_percent_move_dir}},
        @{n="charm_oi";e={[double]$_.charm_per_one_percent_move_oi}},
        @{n="vanna_oi";e={[double]$_.vanna_per_one_percent_move_oi}} |
      Format-Table -AutoSize
  }

  "strikes" {
    $t = if ($A1) { $A1.ToUpper() } else { "SPY" }
    $lo = if ($A2) { $A2 } else { "0" }
    $hi = if ($A3) { $A3 } else { "99999" }
    $q = "min_strike=$lo&max_strike=$hi"
    $rows = @((Invoke-Relay "/unusualwhales/api/stock/$t/spot-exposures/strike" $q).data)
    "ticker=$t  strikes=$lo..$hi  rows=$($rows.Count)"
    $rows | Select-Object strike, price,
      @{n="call_gamma_oi";e={[double]$_.call_gamma_oi}},
      @{n="put_gamma_oi";e={[double]$_.put_gamma_oi}},
      @{n="net_gamma";e={[double]$_.call_gamma_oi + [double]$_.put_gamma_oi}} |
      Sort-Object { [double]$_.strike } | Format-Table -AutoSize
  }

  "gflow" {
    $t = if ($A1) { $A1.ToUpper() } else { "SPY" }
    if ($A2) { $rows = @((Invoke-Relay "/unusualwhales/api/stock/$t/greek-flow/$A2").data) }
    else { $rows = @((Invoke-Relay "/unusualwhales/api/stock/$t/greek-flow").data) }
    "ticker=$t expiry=$(if($A2){$A2}else{'all'}) rows=$($rows.Count)"
    $rows | Select-Object -Last 12 |
      Select-Object timestamp, volume, transactions,
        @{n="dir_delta";e={[math]::Round([double]$_.dir_delta_flow,0)}},
        @{n="total_delta";e={[math]::Round([double]$_.total_delta_flow,0)}},
        @{n="otm_dir_delta";e={[math]::Round([double]$_.otm_dir_delta_flow,0)}} |
      Format-Table -AutoSize
  }

  "flow" {
    $n = if ($A1) { [int]$A1 } else { 15 }
    $q = "limit=$n"
    if ($A2) { $q += "&ticker_symbol=" + $A2.ToUpper() }
    $rows = @((Invoke-Relay "/unusualwhales/api/option-trades/flow-alerts" $q).data)
    "alerts=$($rows.Count)"
    $rows | Select-Object created_at, ticker, type, strike, expiry, price,
      total_premium, volume, open_interest, total_size, volume_oi_ratio, alert_rule, has_sweep |
      Format-Table -AutoSize
  }

  "tide" {
    $o = Invoke-Relay "/unusualwhales/api/market/market-tide"
    $rows = @($o.data)
    "date=$($o.date)  bars=$($rows.Count)"
    $rows | Select-Object -Last 8 |
      Select-Object timestamp,
        @{n="call_prem";e={[math]::Round([double]$_.net_call_premium,0)}},
        @{n="put_prem";e={[math]::Round([double]$_.net_put_premium,0)}},
        net_volume | Format-Table -AutoSize
    $tot = ($rows | ForEach-Object { [double]$_.net_volume } | Measure-Object -Sum).Sum
    "cumulative net_volume = $tot  (negative = put-heavy)"
  }

  "darkpool" {
    if ($A1) { $rows = @((Invoke-Relay "/unusualwhales/api/darkpool/$($A1.ToUpper())").data) }
    else { $rows = @((Invoke-Relay "/unusualwhales/api/darkpool/recent").data) }
    "prints=$($rows.Count)"
    $rows | Select-Object -First 20 executed_at, ticker, price, size, volume, premium, market_center, ext_hour_sold_codes |
      Format-Table -AutoSize
  }

  "raw" {
    if (-not $A1) { throw "usage: uw.ps1 raw <path> [query]  e.g. raw /api/stock/SPY/gex-levels" }
    $p = $A1
    if (-not $p.StartsWith("/unusualwhales")) { $p = "/unusualwhales" + $p }
    $o = Invoke-Relay $p $A2
    $c = if ($o.data -is [array]) { $o.data.Count } else { "obj" }
    "# rows=$c"
    Show-Json $o
  }

  "catalog" {
    $cat = Get-Content (Join-Path $HERE "..\assets\catalog.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $items = if ($A1) { $cat.endpoints | Where-Object { $_.upstream_path -like "*$A1*" -or $_.description -like "*$A1*" -or $_.category -like "*$A1*" } } else { $cat.endpoints }
    "$($items.Count) of $($cat.count) endpoints"
    $items | Select-Object category, method, upstream_path, description | Format-Table -AutoSize
  }

  "matrix" {
    $m = Import-Csv (Join-Path $HERE "..\assets\availability-matrix.csv")
    "probed $($m.Count)"
    $m | Group-Object status | Sort-Object Count -Descending | ForEach-Object { "  HTTP {0,-4} {1,4}" -f $_.Name, $_.Count }
    "  with data (rows>0): $(($m | Where-Object { [int]$_.rows -gt 0 }).Count)"
    ""
    "blocked / empty:"
    $m | Where-Object { $_.status -ne "200" -or [int]$_.rows -le 0 } |
      Select-Object status, template, rows, note | Format-Table -AutoSize -Wrap
  }

  "ws" {
    if (-not $A1) { throw "usage: uw.ps1 ws <channel[,channel]> [seconds]" }
    $secs = if ($A2) { [int]$A2 } else { 20 }
    $key = Get-Key
    $tk = (Invoke-WebRequest -Uri "$BASE/unusualwhales/socket-ticket" -Method POST `
            -Headers @{ "X-API-Key" = $key } -UseBasicParsing -TimeoutSec 20).Content | ConvertFrom-Json
    "ticket ok, expires_in=$($tk.expires_in)"
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $cts = New-Object Threading.CancellationTokenSource
    $cts.CancelAfter([TimeSpan]::FromSeconds($secs + 15))
    $ws.ConnectAsync([Uri]$tk.websocket_url, $cts.Token).Wait(15000) | Out-Null
    if ($ws.State -ne "Open") { "connect failed: $($ws.State)"; return }
    "connected"
    foreach ($ch in ($A1 -split ",")) {
      $ch = $ch.Trim(); if (-not $ch) { continue }
      $b = [Text.Encoding]::UTF8.GetBytes("{`"channel`":`"$ch`",`"msg_type`":`"join`"}")
      $ws.SendAsync([ArraySegment[byte]]::new($b), "Text", $true, $cts.Token).Wait(5000) | Out-Null
      "join -> $ch"
    }
    $buf = New-Object byte[] 262144
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $n = 0
    while ($sw.Elapsed.TotalSeconds -lt $secs -and $ws.State -eq "Open") {
      $seg = [ArraySegment[byte]]::new($buf)
      $t = $ws.ReceiveAsync($seg, $cts.Token)
      if (-not $t.Wait(2000)) { continue }
      if ($t.Result.MessageType -eq "Close") { "closed: $($t.Result.CloseStatusDescription)"; break }
      $s = [Text.Encoding]::UTF8.GetString($buf, 0, $t.Result.Count)
      $n++
      "[" + $sw.Elapsed.TotalSeconds.ToString("0.0") + "s] " + $s.Substring(0, [Math]::Min(400, $s.Length))
    }
    "messages=$n in $($sw.Elapsed.TotalSeconds.ToString('0.0'))s"
    try { $ws.CloseAsync("NormalClosure", "done", [Threading.CancellationToken]::None).Wait(3000) | Out-Null } catch {}
  }

  default {
    "commands: selftest | gex TICKER | exposure TICKER [n] | strikes TICKER [min] [max] | gflow TICKER [expiry] | flow [n] [ticker] | tide | darkpool [ticker] | raw PATH [query] | catalog [kw] | matrix | ws CH[,CH] [secs]"
  }
}