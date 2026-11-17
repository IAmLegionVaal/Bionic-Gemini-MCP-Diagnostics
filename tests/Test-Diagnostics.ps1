$ErrorActionPreference='Stop'
$scriptFile=Join-Path $PSScriptRoot '../scripts/Test-BionicMcpPreflight.ps1'
$tokens=$null; $errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($scriptFile,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw 'Syntax errors' }
function Assert-Throws([scriptblock]$Action,[string]$Expected) {
    $caught=$false
    try { & $Action } catch { $caught=$true; if ($_.Exception.Message -notlike "*$Expected*") { throw } }
    if (-not $caught) { throw "Expected failure: $Expected" }
}
# Synthetic fixtures remain under tests; no production files or network access.
$good=Join-Path $PSScriptRoot 'valid.mjs'
$empty=Join-Path $PSScriptRoot 'empty.mjs'
$bad=Join-Path $PSScriptRoot 'invalid.mjs'
Set-Content -LiteralPath $good -Value 'export const synthetic = true;'
Set-Content -LiteralPath $empty -Value '' -NoNewline
Set-Content -LiteralPath $bad -Value 'export const = ;'
$testState=@{calls=0;failHttp=$false}
function Invoke-WebRequest {
    param($Uri,$Method,$TimeoutSec,$MaximumRedirection,[switch]$UseBasicParsing,$ErrorAction)
    $testState.calls++
    if ($MaximumRedirection -ne 0 -or $Method -ne 'Get' -or $TimeoutSec -gt 30) { throw 'Unsafe request options' }
    if ($testState.failHttp) { throw 'synthetic private response' }
    @{StatusCode=200}
}
Assert-Throws { & $scriptFile -ServerScript $empty } 'zero bytes'
Assert-Throws { & $scriptFile -ServerScript $bad } 'Node preflight failed'
Assert-Throws { & $scriptFile -ServerScript $good -LocalApiUrl 'https://example.com/v1/models' } 'LocalApiUrl'
Assert-Throws { & $scriptFile -ServerScript $good -LocalApiUrl 'http://localhost:1235/v1/models?token=synthetic' } 'LocalApiUrl'
if ($testState.calls -ne 0) { throw 'Invalid input reached HTTP' }
& $scriptFile -ServerScript $good
if ($testState.calls -ne 1) { throw 'Expected one local request' }
$testState.failHttp=$true
Assert-Throws { & $scriptFile -ServerScript $good } 'Details suppressed'
Write-Host '6 behavioral checks and PowerShell syntax passed; no network requests made.'
