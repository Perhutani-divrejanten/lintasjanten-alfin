# Final verification script - memastikan rebrand Lintas Janten bersih dan konsisten

$WorkspaceRoot = "c:\KULIAH\MAGANG\Magang di Perhutani\Lintas Janten"
$legacyLogoPattern = 'logo\.' + 'png'

Write-Host "========== FINAL VERIFICATION - LINTAS JANTEN ==========" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$stats = @{
    "Files checked" = 0
    "Old branding found" = 0
    "Legacy logo refs" = 0
    "New colors found" = 0
}

$filesToCheck = Get-ChildItem -Path $WorkspaceRoot -Recurse -File |
    Where-Object {
        $_.FullName -notlike "*\node_modules\*" -and
        $_.FullName -notlike "*\.bak*" -and
        $_.Extension -in ".html", ".css", ".json", ".md", ".toml", ".txt", ".ps1"
    }

$stats["Files checked"] = $filesToCheck.Count

# 1. Check for old branding strings
Write-Host "1. Checking for old branding strings..." -ForegroundColor Yellow
$oldBrandingPatterns = @(
    ('Indonesia' + ' Daily'),
    ('indonesia' + 'daily'),
    ('Indonesia' + 'Daily'),
    ('Warta' + ' Janten'),
    ('Warta' + 'Janten'),
    ('warta' + 'janten')
)

foreach ($pattern in $oldBrandingPatterns) {
    $found = $filesToCheck | Select-String -Pattern $pattern -ErrorAction SilentlyContinue
    if ($found) {
        foreach ($result in $found) {
            $issues += @{
                Type = "Old Branding"
                File = ($result.Path | Split-Path -Leaf)
                Line = $result.LineNumber
                Pattern = $pattern
            }
            $stats["Old branding found"]++
        }
    }
}

if ($stats["Old branding found"] -eq 0) {
    Write-Host "   ✅ No old branding references found!" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Found old branding in $($stats['Old branding found']) places" -ForegroundColor Yellow
}

# 2. Check for leftover legacy logo image references
Write-Host "2. Checking for legacy logo image references..." -ForegroundColor Yellow
$logoFound = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.html" -File |
    Select-String -Pattern ('img.*' + $legacyLogoPattern + '|' + $legacyLogoPattern + '.*img') -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -notlike "*\.bak*" }

if ($logoFound) {
    $stats["Legacy logo refs"] = $logoFound.Count
    Write-Host "   ⚠️  Found $($logoFound.Count) legacy image references" -ForegroundColor Yellow
    foreach ($ref in $logoFound | Select-Object -First 5) {
        Write-Host "      - $($ref.Path | Split-Path -Leaf)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ No legacy image references found!" -ForegroundColor Green
}

# 3. Check for new colors in CSS
Write-Host "3. Checking for new color scheme in CSS files..." -ForegroundColor Yellow
$cssFiles = Get-ChildItem -Path (Join-Path $WorkspaceRoot "css") -Recurse -Include "*.css" -File -ErrorAction SilentlyContinue

$newColors = @("#EA580C", "#7C2D12", "#1F5F2F")
$colorsFound = 0

foreach ($color in $newColors) {
    $found = $cssFiles | Select-String -Pattern $color -ErrorAction SilentlyContinue
    if ($found) {
        $colorsFound++
        Write-Host "   ✅ Found $color in CSS" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Not found: $color" -ForegroundColor Yellow
    }
}

# 4. Check for new branding
Write-Host "4. Checking for new Lintas Janten branding..." -ForegroundColor Yellow
$newBrandingFound = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.html" -File |
    Select-String -Pattern "Lintas Janten|LintasJanten|lintasjanten" -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -notlike "*\.bak*" } |
    Measure-Object

if ($newBrandingFound.Count -gt 0) {
    Write-Host "   ✅ Found Lintas Janten branding in $($newBrandingFound.Count) places" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  No Lintas Janten branding found!" -ForegroundColor Yellow
    $issues += @{ Type = "Missing"; File = "All"; Pattern = "Lintas Janten" }
}

# 5. Check package metadata updates
Write-Host "5. Checking package metadata..." -ForegroundColor Yellow
$pkgFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "package.json" -File |
    Where-Object { $_.FullName -notlike "*\node_modules\*" }

$pkgOK = 0
foreach ($pkg in $pkgFiles) {
    $content = Get-Content $pkg.FullName -Raw -Encoding UTF8
    if ($content -match '"name"\s*:\s*"lintasjanten') {
        $pkgOK++
        Write-Host "   ✅ $($pkg.Name) has proper branding" -ForegroundColor Green
    }
}

# Summary
Write-Host ""
Write-Host "========== SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Files checked: $($stats['Files checked'])" -ForegroundColor White
Write-Host "Old branding issues: $($stats['Old branding found'])" -ForegroundColor $(if ($stats["Old branding found"] -eq 0) { "Green" } else { "Yellow" })
Write-Host "Legacy logo refs: $($stats['Legacy logo refs'])" -ForegroundColor $(if ($stats["Legacy logo refs"] -eq 0) { "Green" } else { "Yellow" })
Write-Host "New color scheme found: $colorsFound/3" -ForegroundColor $(if ($colorsFound -eq 3) { "Green" } else { "Yellow" })
Write-Host "Package files OK: $pkgOK" -ForegroundColor Green
Write-Host ""

if ($issues.Count -gt 0) {
    Write-Host "[!] Issues found:" -ForegroundColor Yellow
    $issues | Select-Object -First 5 | ForEach-Object {
        Write-Host "   - $($_.File): $($_.Type) - $($_.Pattern)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[OK] No critical issues found!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Rebrand Lintas Janten selesai ✅" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Cyan
