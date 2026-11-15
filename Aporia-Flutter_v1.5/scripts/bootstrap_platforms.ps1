$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "Flutter was not found. Install the Flutter SDK and add it to PATH."
  exit 1
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Error "Python 3 is required to set generated Android/Web display names."
  exit 1
}

$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $Root
$Backup = Join-Path $env:TEMP ("entrelinhas-backup-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $Backup | Out-Null
try {
  $files = @('pubspec.yaml', 'analysis_options.yaml', '.gitignore', 'README.md', 'lib/main.dart', 'test/widget_test.dart')
  foreach ($file in $files) {
    $dest = Join-Path $Backup ($file -replace '/', '_')
    Copy-Item -LiteralPath $file -Destination $dest
  }

  flutter create --platforms=android,web --org com.entrelinhas --project-name entrelinhas .
  if ($LASTEXITCODE -ne 0) { throw "flutter create failed with exit code $LASTEXITCODE" }

  foreach ($file in $files) {
    $source = Join-Path $Backup ($file -replace '/', '_')
    Copy-Item -LiteralPath $source -Destination $file -Force
  }

  python scripts/set_app_display_name.py
  if ($LASTEXITCODE -ne 0) { throw "Could not set app display names" }
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed with exit code $LASTEXITCODE" }
  Write-Host "Aporia Android and Web platform folders generated. Run flutter analyze and flutter test next."
} finally {
  Remove-Item -LiteralPath $Backup -Recurse -Force -ErrorAction SilentlyContinue
}
