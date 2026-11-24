# Reachability matrix for all catalog endpoints. PowerShell 5.1 compatible.
param([string]$Out = "")
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Net.Http | Out-Null
$here = Split-Path -Parent $PSCommandPath
$key = (Get-Content (Join-Path $here "key.txt") -Raw).Trim()
$catalog = [IO.File]::ReadAllText((Join-Path $here "catalog.json"), [Text.Encoding]::UTF8) | ConvertFrom-Json

$sub = @{
  '{ticker}'='SPY'; '{date}'='2026-11-23'; '{expiry}'='2026-11-28'; '{contract}'='ESZ6';
  '{name}'='CL'; '{pair}'='BTC'; '{interval}'='1m'; '{candle_size}'='1m'; '{token}'='BTC';
  '{sector}'='technology'; '{flow_group}'='0dte'; '{chain}'='SPY'; '{security_id}'='1';
  '{id}'='1'; '{function}'='RSI'; '{currency_pair}'='EURUSD'
}

$jobs = @()
foreach ($e in $catalog.endpoints) {
  $p = $e.upstream_path
  foreach ($k in $sub.Keys) { $p = $p.Replace($k, $sub[$k]) }
  $jobs += [pscustomobject]@{ category=$e.category; template=$e.upstream_path; path="/unusualwhales$p" }
}

[Net.ServicePointManager]::DefaultConnectionLimit = 96
$client = New-Object Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(40)
$client.DefaultRequestHeaders.Add("X-API-Key", $key)

$tasks = @{}
foreach ($j in $jobs) {
  try { $tasks[$j.path] = $client.GetAsync("https://ai-tool.indevs.in" + $j.path) } catch { $tasks[$j.path] = $null }
}
$all = @($tasks.Values | Where-Object { $_ -ne $null })
try { [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]$all) | Out-Null } catch {}

$res = @()
foreach ($j in $jobs) {
  $row = [pscustomobject]@{ category=$j.category; template=$j.template; path=$j.path; status=0; rows=-1; bytes=0; note="" }
  $t = $tasks[$j.path]
  if ($null -eq $t) { $row.status = -2; $row.note = "task-create-failed"; $res += $row; continue }
  if ($t.IsFaulted) { $row.status = -1; $row.note = ($t.Exception.InnerException.Message); $res += $row; continue }
  if (-not $t.IsCompleted) { $row.status = -3; $row.note = "timeout"; $res += $row; continue }
  $resp = $t.Result
  $row.status = [int]$resp.StatusCode
  try {
    $txt = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $row.bytes = $txt.Length
    try {
      $o = $txt | ConvertFrom-Json
      if ($o.data -is [array]) { $row.rows = $o.data.Count }
      elseif ($null -eq $o.data) { $row.rows = -2; $row.note = "data=null" }
      elseif ($o.data -is [pscustomobject]) { $row.rows = 1 }
      else { $row.rows = -3 }
      if ($row.rows -eq 0) { $row.note = "empty" }
    } catch { $row.rows = -4; $row.note = "not-json: " + ($txt -replace '\s+',' ').Substring(0,[Math]::Min(80,$txt.Length)) }
    if ($row.status -ge 400) { $row.note = ($txt -replace '\s+',' ').Substring(0,[Math]::Min(120,$txt.Length)) }
  } catch { $row.note = "read-failed" }
  $res += $row
}
$client.Dispose()
$res = $res | Sort-Object category, template
if ($Out) { $res | Export-Csv -Path $Out -NoTypeInformation -Encoding UTF8 }
$res