# Requires: ffmpeg in PATH
param(
  [string]$Source = "G:\Apps\napolill\assets\audio",
  [string]$Duration = "00:30:00"
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  Write-Error "ffmpeg wurde nicht gefunden. Bitte PATH prüfen."
  exit 1
}

if (-not (Test-Path $Source)) {
  Write-Error "Quellordner '$Source' existiert nicht."
  exit 1
}

Get-ChildItem $Source -Filter *.mp3 | ForEach-Object {
  $tempPath = Join-Path $_.DirectoryName ("{0}_trim.mp3" -f $_.BaseName)
  Write-Host "Trimme $($_.Name) auf $Duration ..."
  ffmpeg -y -i $_.FullName -c copy -t $Duration $tempPath | Out-Null
  Move-Item -Force $tempPath $_.FullName
}

Write-Host "Trimmen abgeschlossen."

