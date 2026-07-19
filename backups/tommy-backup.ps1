# ============================================================
# ISA LC OS - kunlik DATA backup (o'rnatishsiz, REST orqali)
# Docker/pg_dump KERAK EMAS. service_role kalit bilan barcha
# jadval ma'lumotini JSON'ga eksport qiladi (RLS bypass).
# STRUKTURA git migratsiya fayllarida (sql/migrations/001-020).
# Tiklash = migratsiyalar + shu JSON data.
# service_role kalit LOKAL faylda (.svckey.txt) - OneDrive/git da EMAS.
# ASCII-only (PowerShell 5.1 encoding uchun).
# ============================================================
$ErrorActionPreference = 'Stop'

$keyFile  = 'D:\Git\tommy-lc\backups\.svckey.txt'
$apiUrl   = 'https://ftnmiaswdiynbutschad.supabase.co/rest/v1'
$keepDays = 14
$tables = @(
  'centers','platform_admins','center_branding','center_settings','feature_flags',
  'plans','subscriptions','center_domains','platform_settings','center_secrets',
  'audit_log','events','admins','groups','profiles','students','daily_checks',
  'assignments','assignment_grades','homework','homework_done','notifications',
  'messages','payments','materials','parent_links','login_history','lesson_confirms'
)

$outRoot = if ($env:OneDrive) { Join-Path $env:OneDrive 'tommy-backups' } else { 'C:\Users\user\OneDrive\tommy-backups' }
if (-not (Test-Path $keyFile)) { throw "service_role kalit fayli topilmadi: $keyFile" }
$key = (Get-Content $keyFile -Raw).Trim()
if (-not $key -or $key -like '*SHU_YERGA*') { throw "service_role kalit qoyilmagan: $keyFile" }

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$dir = Join-Path $outRoot "backup_$stamp"
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$h = @{ apikey = $key; Authorization = "Bearer $key" }

$total = 0
foreach ($t in $tables) {
  $rows = @()
  $offset = 0
  while ($true) {
    $uri = $apiUrl + '/' + $t + '?select=*&limit=1000&offset=' + $offset
    $page = $null
    try { $page = Invoke-RestMethod -Uri $uri -Headers $h -Method Get } catch { $page = $null }
    if (-not $page) { break }
    $rows += $page
    if (@($page).Count -lt 1000) { break }
    $offset += 1000
  }
  ($rows | ConvertTo-Json -Depth 12) | Set-Content -Path (Join-Path $dir ($t + '.json')) -Encoding utf8
  $total += @($rows).Count
}

Get-ChildItem $outRoot -Directory -Filter 'backup_*' -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$keepDays) } |
  Remove-Item -Recurse -Force

Write-Output ("BACKUP OK: " + $dir)
Write-Output ("Jadval: " + $tables.Count + " | Jami qator: " + $total)
