# ============================================================
#  Boter 訂單管理系統 — 發布腳本
#  將 dev 分支合併到 main，更新線上工具
#  用法：在確認開發版測試無誤後執行此腳本
# ============================================================

$RepoRoot = $PSScriptRoot
Set-Location $RepoRoot

Write-Host ""
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "  Boter 訂單管理系統 — 發布到線上" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host ""

# 確認目前狀態乾淨
$status = (& git status --porcelain 2>&1).Trim()
if ($status) {
    Write-Host "✗ 有未提交的變更，請先儲存並讓 auto-push 完成：" -ForegroundColor Red
    Write-Host $status -ForegroundColor Gray
    exit 1
}

# 取得目前分支
$branch = (& git rev-parse --abbrev-ref HEAD 2>&1).Trim()
Write-Host "目前分支：$branch" -ForegroundColor Gray

# 先確保 dev 是最新的
Write-Host "`n[1/4] 切換到 dev 並更新…" -ForegroundColor Cyan
& git checkout dev 2>&1 | Out-Null
& git pull origin dev 2>&1 | Out-Null
Write-Host "  ✓ dev 已是最新" -ForegroundColor Green

# 切到 main，合併 dev
Write-Host "[2/4] 切換到 main…" -ForegroundColor Cyan
& git checkout main 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "  ✗ 切換失敗" -ForegroundColor Red; exit 1 }
Write-Host "  ✓ 已切換到 main" -ForegroundColor Green

Write-Host "[3/4] 合併 dev → main…" -ForegroundColor Cyan
$mergeOut = & git merge dev --no-edit 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 合併失敗：$mergeOut" -ForegroundColor Red
    & git merge --abort 2>&1 | Out-Null
    & git checkout dev 2>&1 | Out-Null
    exit 1
}
Write-Host "  ✓ 合併成功" -ForegroundColor Green

# Push main → 更新線上
Write-Host "[4/4] 推送到 GitHub Pages…" -ForegroundColor Cyan
$pushOut = & git push origin main 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ 發布成功！線上工具已更新" -ForegroundColor Green
    Write-Host "  → https://orders.boter.com.tw" -ForegroundColor DarkCyan
} else {
    Write-Host "  ✗ push 失敗：$pushOut" -ForegroundColor Red
    exit 1
}

# 切回 dev，繼續開發
Write-Host "`n切回 dev 分支，繼續開發…" -ForegroundColor Gray
& git checkout dev 2>&1 | Out-Null
Write-Host "  ✓ 現在在 dev 分支" -ForegroundColor Green

Write-Host ""
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "  發布完成！" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host ""
