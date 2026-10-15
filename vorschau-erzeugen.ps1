# Erzeugt die Vorschaubilder fuer die Dossiers (Seite 1 = Cover, Seiten 2-4 = Vorschau).
#
# Alle Dossiers:        powershell -ExecutionPolicy Bypass -File vorschau-erzeugen.ps1
# Nur eines:            powershell -ExecutionPolicy Bypass -File vorschau-erzeugen.ps1 kurvendiskussion-1
#
# Liest  dossiers\<name>.pdf  und schreibt  dossiers\vorschau\<name>-1.png ... <name>-4.png
# Benoetigt pdftoppm (ist in TeX Live und MiKTeX enthalten).
param([string]$Name = "*", [int]$Seiten = 4)

$ordner = Join-Path $PSScriptRoot "dossiers"
$ziel   = Join-Path $ordner "vorschau"
New-Item -ItemType Directory -Force $ziel | Out-Null

$pdfs = Get-ChildItem (Join-Path $ordner "$Name.pdf")
if (-not $pdfs) { Write-Host "Keine PDF gefunden: dossiers\$Name.pdf"; exit 1 }

foreach ($pdf in $pdfs) {
  $basis = $pdf.BaseName
  # alte Bilder dieses Dossiers loeschen
  Get-ChildItem $ziel -Filter "$basis-*.png" | Where-Object { $_.BaseName -match "^$([regex]::Escape($basis))-\d+$" } | Remove-Item
  # Seiten rendern (pdftoppm haengt -01, -02 ... an)
  & pdftoppm -png -r 180 -f 1 -l $Seiten $pdf.FullName (Join-Path $ziel "$basis-tmp")
  Get-ChildItem $ziel -Filter "$basis-tmp-*.png" | ForEach-Object {
    $nr = [int]($_.BaseName -replace '^.*-tmp-', '')
    Move-Item $_.FullName (Join-Path $ziel "$basis-$nr.png") -Force
  }
  Write-Host "Vorschau erzeugt: $basis"
}
