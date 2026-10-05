<#
.SYNOPSIS
  Baut aus sources/*.txt eine einfügbare FRITZ!Box-Blacklist (max. 500 Einträge).
.EXAMPLE
  pwsh ./scripts/build.ps1
  pwsh ./scripts/build.ps1 -Strict   # Abbruch statt Kürzung bei >500
#>
param(
  [int]$MaxEntries = 500,
  [switch]$Strict
)
$ErrorActionPreference = 'Stop'
$root    = Split-Path $PSScriptRoot -Parent
$src     = Join-Path $root 'sources'
$dist    = Join-Path $root 'dist'
$domainRx = '^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$'

function Read-List([string]$path) {
  Get-Content $path -Encoding UTF8 | ForEach-Object {
    $l = ($_ -replace '#.*$', '').Trim().ToLowerInvariant()
    $l = $l -replace '^(0\.0\.0\.0|127\.0\.0\.1)\s+', ''   # hosts-Format akzeptieren
    $l = $l -replace '^https?://', '' -replace '/.*$', '' -replace '^www\.', ''
    $l = $l -replace '^\|\|', '' -replace '\^$', ''        # AdBlock-Syntax akzeptieren
    if ($l) { $l }
  }
}

$allow = @(Read-List (Join-Path $src 'allowlist.txt'))
$all = [System.Collections.Generic.List[string]]::new()
$invalid = @()

Get-ChildItem $src -Filter *.txt | Where-Object Name -ne 'allowlist.txt' | Sort-Object Name | ForEach-Object {
  foreach ($d in Read-List $_.FullName) {
    if ($d -match $domainRx) { $all.Add($d) } else { $invalid += "$($_.Name): $d" }
  }
}

if ($invalid) {
  Write-Host "Ungültige Einträge:" -ForegroundColor Red
  $invalid | ForEach-Object { Write-Host "  $_" }
  exit 1
}

# Deduplizieren, Allowlist anwenden, Subdomains entfernen, deren Parent schon gelistet ist
$set = $all | Sort-Object -Unique | Where-Object { $allow -notcontains $_ }
$hash = [System.Collections.Generic.HashSet[string]]::new([string[]]$set)
$final = $set | Where-Object {
  $parts = $_.Split('.')
  $covered = $false
  for ($i = 1; $i -lt $parts.Count - 1; $i++) {
    if ($hash.Contains(($parts[$i..($parts.Count-1)] -join '.'))) { $covered = $true; break }
  }
  -not $covered
}

$count = @($final).Count
if ($count -gt $MaxEntries) {
  $msg = "$count Einträge – FRITZ!Box erlaubt max. $MaxEntries."
  if ($Strict) { Write-Error $msg }
  Write-Warning "$msg Liste wird alphabetisch gekürzt."
  $final = $final | Select-Object -First $MaxEntries
}

New-Item -ItemType Directory -Force $dist | Out-Null
$utf8 = [System.Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $dist 'fritzbox-blocklist.txt'), (($final -join "`n") + "`n"), $utf8)
[IO.File]::WriteAllText((Join-Path $dist 'hosts.txt'), ((($final | ForEach-Object { "0.0.0.0 $_" }) -join "`n") + "`n"), $utf8)

Write-Host "OK: $(@($final).Count) / $MaxEntries Einträge -> dist/fritzbox-blocklist.txt" -ForegroundColor Green
