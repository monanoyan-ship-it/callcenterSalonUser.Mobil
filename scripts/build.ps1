#requires -Version 5.1
<#
  Salon Staff mobile release build sarmalayicisi.

  Ornek:
    .\scripts\build.ps1 -Target apk -Env prod
    .\scripts\build.ps1 -Target appbundle -Env prod
    .\scripts\build.ps1 -Target web -Env staging
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('web', 'apk', 'appbundle', 'ios', 'macos', 'windows')]
    [string] $Target,

    [ValidateSet('dev', 'staging', 'prod')]
    [string] $Env = 'dev',

    [string] $ApiUrl,
    [bool]   $AllowBadSsl,
    [string] $SentryDsn
)

$ErrorActionPreference = 'Stop'

$defaults = @{
    dev = @{
        ApiUrl      = 'http://localhost:5041'
        AllowBadSsl = $true
    }
    staging = @{
        ApiUrl      = 'https://staging-api.corplynk.com'
        AllowBadSsl = $false
    }
    prod = @{
        ApiUrl      = 'https://api.corplynk.com'
        AllowBadSsl = $false
    }
}

$cfg = $defaults[$Env]
if ($ApiUrl) { $cfg.ApiUrl = $ApiUrl }
if ($PSBoundParameters.ContainsKey('AllowBadSsl')) { $cfg.AllowBadSsl = $AllowBadSsl }

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    $sdkPath = "C:\Users\Ahmet\flutter_sdk_stable\bin\flutter.bat"
    if (Test-Path $sdkPath) { $flutter = $sdkPath }
    else { throw "flutter PATH'te yok ve $sdkPath bulunamadi." }
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location -LiteralPath $RepoRoot

$defines = @(
    "--dart-define=API_BASE_URL=$($cfg.ApiUrl)",
    "--dart-define=ALLOW_BAD_SSL=$($cfg.AllowBadSsl.ToString().ToLower())"
)
if ($SentryDsn) { $defines += "--dart-define=SENTRY_DSN=$SentryDsn" }

Write-Host "[build] target=$Target env=$Env"
foreach ($d in $defines) { Write-Host "         $d" }

$cmd = @('build', $Target) + $defines
if ($Target -in @('apk', 'appbundle', 'ios')) {
    $cmd += '--release'
}
& $flutter @cmd
