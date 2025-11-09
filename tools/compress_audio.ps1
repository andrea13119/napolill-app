# Requires: ffmpeg in PATH
param(
  [string]$Source = "G:\Apps\napolill\assets\audio",
  [string]$TargetExtension = ".m4a",
  [int]$BitrateKbps = 128,
  [switch]$Mono
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  Write-Error "ffmpeg wurde nicht gefunden. Bitte stelle sicher, dass ffmpeg im PATH liegt."
  exit 1
}

if (-not (Test-Path $Source)) {
  Write-Error "Quellverzeichnis '$Source' wurde nicht gefunden."
  exit 1
}

$bitrate = "$BitrateKbps`k"
$channelArgs = @()
if ($Mono) { $channelArgs = @('-ac', '1') }

Get-ChildItem $Source -Filter *.mp3 | ForEach-Object {
  $outputPath = [System.IO.Path]::ChangeExtension($_.FullName, $TargetExtension)
  Write-Host "Konvertiere $($_.Name) -> $(Split-Path $outputPath -Leaf)"
  ffmpeg -y -i $_.FullName -c:a aac -b:a $bitrate @channelArgs $outputPath | Out-Null
}

Write-Host "Konvertierung abgeschlossen."

