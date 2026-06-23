# ============================================================
#  Boter 訂單管理系統 — 預覽發布腳本
#  將 dev 分支同步到 orders.boter.com.tw/dev/ 供測試
#  確認無誤後再執行 deploy.ps1 更新正式版
# ============================================================

$RepoRoot = $PSScriptRoot
Set-Location $RepoRoot

Write-Host ""
Write-Host "====================================================" -ForegroundColor DarkCyan
Write-Host "  Boter 訂單管理系統 — 發布測試版" -ForegroundColor DarkCyan
Write-Host "====================================================" -ForegroundColor DarkCyan
Write-Host ""

# 確認目前 dev 狀態乾淨
$branch = (& git rev-parse --abbrev-ref HEAD 2>&1).Trim()
if ($branch -ne 'dev') {
    Write-Host "✗ 請先切換到 dev 分支（目前：$branch）" -ForegroundColor Red
    exit 1
}
$status = (& git status --porcelain 2>&1).Trim()
if ($status) {
    Write-Host "✗ 有未提交的變更，請先讓 auto-push 完成：" -ForegroundColor Red
    Write-Host $status -ForegroundColor Gray
    exit 1
}

# 讀取 dev 的 index.html，將 redirectUri 改為 /dev/ 版本
Write-Host "[1/4] 讀取 dev 版本 index.html…" -ForegroundColor Cyan
$content = Get-Content "$RepoRoot\index.html" -Raw -Encoding UTF8
$devContent = $content -replace "redirectUri: 'https://orders.boter.com.tw'", "redirectUri: 'https://orders.boter.com.tw/dev/'"
if ($devContent -eq $content) {
    Write-Host "  ✗ 找不到 redirectUri 設定，請確認 index.html 內容" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ redirectUri 已調整為 /dev/" -ForegroundColor Green

# 切到 main
Write-Host "[2/4] 切換到 main…" -ForegroundColor Cyan
& git checkout main 2>&1 | Out-Null
& git pull origin main 2>&1 | Out-Null
Write-Host "  ✓ main 已更新" -ForegroundColor Green

# 寫入 dev/index.html
Write-Host "[3/4] 寫入 dev/index.html…" -ForegroundColor Cyan
if (-not (Test-Path "$RepoRoot\dev")) {
    New-Item -ItemType Directory "$RepoRoot\dev" | Out-Null
}
[System.IO.File]::WriteAllText("$RepoRoot\dev\index.html", $devContent, [System.Text.Encoding]::UTF8)
Write-Host "  ✓ 已寫入" -ForegroundColor Green

# Commit & push
Write-Host "[4/4] 推送到 GitHub Pages…" -ForegroundColor Cyan
& git add "dev\index.html" 2>&1 | Out-Null
$st = (& git status --porcelain 2>&1).Trim()
if (-not $st) {
    Write-Host "  → 測試版無新變更，略過推送" -ForegroundColor Gray
} else {
    $msg = "preview: sync dev to /dev/ $(Get-Date -Format 'MM/dd HH:mm')"
    & git commit -m $msg 2>&1 | Out-Null
    $pushOut = & git push origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 推送成功" -ForegroundColor Green
        Write-Host ""
        Write-Host "  測試網址：https://orders.boter.com.tw/dev/" -ForegroundColor DarkCyan
    } else {
        Write-Host "  ✗ push 失敗：$pushOut" -ForegroundColor Red
        & git checkout dev 2>&1 | Out-Null
        exit 1
    }
}

# 切回 dev
& git checkout dev 2>&1 | Out-Null
Write-Host "  → 已切回 dev 分支" -ForegroundColor Gray

Write-Host ""
Write-Host "====================================================" -ForegroundColor DarkCyan
Write-Host "  測試版已上線！" -ForegroundColor DarkCyan
Write-Host "  https://orders.boter.com.tw/dev/" -ForegroundColor White
Write-Host "  確認沒問題後，執行 deploy.ps1 更新正式版" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor DarkCyan
Write-Host ""
