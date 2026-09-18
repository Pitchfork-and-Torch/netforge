# Pure logic check for MaxLogLines trim (run with pwsh when available).
$ErrorActionPreference = 'Stop'
$max = 5
$lines = 1..12 | ForEach-Object { "[t] line $_" }
if ($lines.Count -le $max) { throw 'fixture too short' }
$kept = $lines[-$max..-1]
if ($kept.Count -ne $max) { throw "expected $max kept, got $($kept.Count)" }
if ($kept[0] -notmatch 'line 8') { throw "expected oldest kept to be line 8, got $($kept[0])" }
if ($kept[-1] -notmatch 'line 12') { throw "expected newest kept to be line 12, got $($kept[-1])" }
Write-Output 'ROTATE LOG LOGIC OK'
