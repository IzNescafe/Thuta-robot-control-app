$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterCandidates = @(
    (Join-Path (Split-Path -Parent $projectRoot) 'flutter\bin\flutter.bat'),
    'C:\Users\user\Downloads\flutter_windows_3.47.1-stable\flutter\bin\flutter.bat',
    'C:\src\flutter\bin\flutter.bat',
    'C:\flutter\bin\flutter.bat'
)

if ($flutterCommand) {
    $flutter = $flutterCommand.Source
} else {
    $flutter = $flutterCandidates |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
}

if (-not $flutter) {
    throw 'Flutter SDK was not found. Install Flutter, add it to PATH, or place it beside robot_dog_app in the flutter folder.'
}

Set-Location -LiteralPath $projectRoot
Write-Host "Using Flutter: $flutter"
Write-Host 'Building the Thuta AI laptop preview...'
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $flutter build web --release --no-pub
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$server = Start-Process py `
    -ArgumentList @('-m', 'http.server', '8181', '--bind', '127.0.0.1') `
    -WorkingDirectory (Join-Path $projectRoot 'build\web') `
    -WindowStyle Hidden `
    -PassThru

try {
    Start-Sleep -Milliseconds 900
    Start-Process 'http://127.0.0.1:8181'
    Write-Host ''
    Write-Host 'Thuta AI is running at http://127.0.0.1:8181'
    Write-Host 'Keep this window open while using the app.'
    Read-Host 'Press ENTER to stop the laptop preview'
} finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
}
