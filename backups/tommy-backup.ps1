# ============================================================
# ISA LC OS — kunlik backup (Free plan, Supabase db dump)
# Ishlaydi: Windows Task Scheduler har kuni chaqiradi.
# DB conn string LOKAL faylda (.dbconn.txt) — OneDrive'da/gitda EMAS.
# Dumplar OneDrive papkaga tushadi -> bulutga off-site sync.
# ============================================================
$ErrorActionPreference = 'Stop'

$connFile = 'D:\Git\tommy-lc\backups\.dbconn.txt'      # LOKAL sir — siz yaratasiz
$keepDays = 14

$outDir = if ($env:OneDrive) { Join-Path $env:OneDrive 'tommy-backups' } else { 'C:\Users\user\OneDrive\tommy-backups' }
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

if (-not (Test-Path $connFile)) { throw "Conn string fayli yo'q: $connFile — avval yarating." }
$conn = (Get-Content $connFile -Raw).Trim()
if (-not $conn) { throw "Conn string bo'sh: $connFile" }

$stamp  = Get-Date -Format 'yyyy-MM-dd_HHmm'
$schema = Join-Path $outDir "tommy_${stamp}_schema.sql"
$data   = Join-Path $outDir "tommy_${stamp}_data.sql"

# schema (struktura + policy + funksiyalar) va data (qatorlar) alohida
npx -y supabase@latest db dump --db-url $conn -f $schema
npx -y supabase@latest db dump --db-url $conn --data-only -f $data

# eski backuplarni tozalash
Get-ChildItem $outDir -Filter 'tommy_*.sql' -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$keepDays) } |
  Remove-Item -Force

Write-Output "BACKUP OK -> $schema"
Write-Output "BACKUP OK -> $data"
