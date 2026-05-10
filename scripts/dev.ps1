#requires -Version 5.1
<#
  Tek oturum: bu projeye ait dart süreçleri + web-port dinleyicisi kapatılır,
  sonra flutter run.
  Kullanım (proje kökünden):
    .\scripts\dev.ps1
    .\scripts\dev.ps1 -Mode android -ApiUrl "http://10.0.2.2:5041"
    .\scripts\dev.ps1 -Mode web -WebPort 53860 -ApiUrl "http://localhost:5041"
#>
param(
    [ValidateSet('web', 'android')]
    [string] $Mode = 'web',
    [int] $WebPort = 53860,
    [string] $ApiUrl = 'http://localhost:5041'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$PathMarker = 'callcenterSalonUser.Mobil'

function Stop-TcpListenersOnPort([int] $Port) {
    $listeners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    foreach ($l in $listeners) {
        $procId = $l.OwningProcess
        if ($procId -lt 1) { continue }
        try {
            $p = Get-Process -Id $procId -ErrorAction Stop
            Write-Host "[dev] Port $Port dinleyen kapatiliyor: $($p.ProcessName) (PID $procId)"
            Stop-Process -Id $procId -Force -ErrorAction Stop
        } catch {
            Write-Host "[dev] Port $Port PID $procId kapatilamadi: $_"
        }
    }
    Start-Sleep -Milliseconds 500
}

function Stop-ProjectDartProcesses {
    try {
        Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -eq 'dart.exe' -and
                $_.CommandLine -and
                ($_.CommandLine -like "*$PathMarker*")
            } |
            ForEach-Object {
                Write-Host "[dev] Eski dart oturumu kapatiliyor: PID $($_.ProcessId)"
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
    } catch {
        Write-Host "[dev] dart temizligi atlandi: $_"
    }
    Start-Sleep -Milliseconds 400
}

Set-Location -LiteralPath $RepoRoot

Stop-ProjectDartProcesses
if ($Mode -eq 'web') {
    Stop-TcpListenersOnPort $WebPort
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    $sdkPath = "C:\Users\Ahmet\flutter_sdk_stable\bin\flutter.bat"
    if (Test-Path $sdkPath) {
        $flutter = $sdkPath
    } else {
        throw "flutter PATH'te yok ve $sdkPath bulunamadi."
    }
}

Write-Host "[dev] flutter run ($Mode) API_BASE_URL=$ApiUrl"
Write-Host "[dev] Calisma dizini: $RepoRoot"

if ($Mode -eq 'web') {
    & $flutter run -d chrome "--web-port=$WebPort" "--dart-define=API_BASE_URL=$ApiUrl"
} else {
    & $flutter run -d android "--dart-define=API_BASE_URL=$ApiUrl"
}
