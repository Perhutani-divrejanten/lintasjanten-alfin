# Rebrand portal ke Lintas Janten
# Menjaga encoding UTF-8, backup data penting, dan merapikan branding di file aktif.

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$ErrorActionPreference = 'Stop'

$WorkspaceRoot = $PSScriptRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$stats = @{
    main_pages    = New-Object 'System.Collections.Generic.HashSet[string]'
    article_pages = New-Object 'System.Collections.Generic.HashSet[string]'
    css_files     = New-Object 'System.Collections.Generic.HashSet[string]'
    package_files = New-Object 'System.Collections.Generic.HashSet[string]'
    docs          = New-Object 'System.Collections.Generic.HashSet[string]'
}

function Save-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Register-Change {
    param(
        [string]$Category,
        [string]$Path
    )

    if ($stats.ContainsKey($Category)) {
        $null = $stats[$Category].Add($Path)
    }
}

function Get-TextLogoMarkup {
    param(
        [string]$Href,
        [string]$ClassName = 'navbar-brand mr-5'
    )

    return @"
<a href="$Href" class="$ClassName">
            <span style="font-weight: 700; color: #EA580C; font-size: 24px; letter-spacing: -0.5px;">LINTAS<span style="color: #1F5F2F; font-weight: 500; font-size: 18px; margin-left: 2px;">JANTEN</span></span>
        </a>
"@
}

function Normalize-Content {
    param(
        [string]$Content,
        [switch]$IsHtml
    )

    # Perbaikan encoding/typography
    $Content = $Content.Replace([char]0x201C, '"')
    $Content = $Content.Replace([char]0x201D, '"')
    $Content = $Content.Replace([char]0x2018, "'")
    $Content = $Content.Replace([char]0x2019, "'")
    $Content = $Content.Replace([char]0x2013, '-')
    $Content = $Content.Replace([char]0x2014, '-')
    $Content = $Content.Replace([char]0x00A0, ' ')
    $Content = $Content.Replace([char]0xFFFD, ' ')
    $Content = $Content -replace [string][char]0x00AD, ''

    # Branding umum
    $Content = $Content -replace 'Lintas Janten', 'Lintas Janten'
    $Content = $Content -replace 'LintasJanten', 'LintasJanten'
    $Content = $Content -replace 'LintasJanten', 'lintasjanten'
    $Content = $Content -replace 'Lintas Janten', 'Lintas Janten'
    $Content = $Content -replace 'LintasJanten', 'LintasJanten'
    $Content = $Content -replace 'LintasJanten', 'lintasjanten'
    $Content = $Content -replace 'lintas-janten', 'lintas-janten'

    # Email & sosial
    $Content = $Content -replace 'LintasJanten33@gmail\.com', 'lintasjanten@gmail.com'
    $Content = $Content -replace 'LintasJanten@gmail\.com', 'lintasjanten@gmail.com'
    $Content = $Content -replace 'LintasJanten@gmail\.com', 'lintasjanten@gmail.com'
    $Content = $Content -replace '(?i)https://twitter\.com/[^"''\s<]+', 'https://twitter.com/lintasjanten'
    $Content = $Content -replace '(?i)https://facebook\.com/[^"''\s<]+', 'https://facebook.com/lintasjanten'
    $Content = $Content -replace '(?i)https://instagram\.com/[^"''\s<]+', 'https://instagram.com/lintasjanten'
    $Content = $Content -replace '(?i)https://youtube\.com/@?[^"''\s<]+', 'https://youtube.com/@lintasjanten'
    $Content = $Content -replace '(?i)https://linkedin\.com/company/[^"''\s<]+', 'https://linkedin.com/company/lintasjanten'

    # Warna tema global
    $Content = $Content -replace '(?i)#EA580C', '#EA580C'
    $Content = $Content -replace '(?i)#7C2D12', '#7C2D12'
    $Content = $Content -replace '(?i)#1F5F2F', '#1F5F2F'
    $Content = $Content -replace '(?i)#EA580C', '#EA580C'
    $Content = $Content -replace '(?i)#7C2D12', '#7C2D12'
    $Content = $Content -replace '(?i)#1F5F2F', '#1F5F2F'
    $Content = $Content -replace '(?i)#C2410C', '#C2410C'
    $Content = $Content -replace '(?i)rgb\(6,\s*95,\s*70\)', 'rgb(234, 88, 12)'

    if ($IsHtml) {
        # Normalisasi text logo yang sudah ada
        $Content = $Content -replace '>\s*WARTA\s*<span', '>LINTAS<span'

        # Ganti image logo lama jadi text-based logo di navbar
        $Content = [regex]::Replace(
            $Content,
            '(?is)<a\s+href="([^"]+)"\s+class="(navbar-brand[^"]*)">\s*(?:<img[^>]*?logo\.png[^>]*>|<span[^>]*?>.*?JANTEN.*?</span>)\s*</a>',
            {
                param($match)
                return (Get-TextLogoMarkup -Href $match.Groups[1].Value -ClassName $match.Groups[2].Value).TrimEnd()
            }
        )

        # Jika masih ada gambar brand lama di konten aktif, ubah ke text logo sederhana
        $Content = [regex]::Replace(
            $Content,
            '(?is)<img[^>]*src="(?:\.\./|)img/logo\.png"[^>]*>',
            '<span class="brand-text-logo" aria-label="LintasJanten" style="font-weight: 700; color: #EA580C; letter-spacing: -0.3px;">LINTAS<span style="color: #1F5F2F; font-weight: 500; font-size: 0.92em;">JANTEN</span></span>'
        )

        $Content = $Content -replace 'alt="(?:LintasJanten|LintasJanten)"', 'alt="LintasJanten"'
        $Content = $Content -replace ' - Lintas Janten - Lintas Janten', ' - Lintas Janten'
        $Content = $Content -replace 'Lintas Janten - Berita Terkini Indonesia', 'Lintas Janten - Portal Berita Terkini'
    }

    return $Content
}

Write-Host "Memulai rebrand Lintas Janten..."

# Backup penting
$articlesJson = Join-Path $WorkspaceRoot 'articles.json'
$articlesBackup = Join-Path $WorkspaceRoot 'articles.json.bak'
if (Test-Path $articlesJson) {
    Copy-Item -Path $articlesJson -Destination $articlesBackup -Force
    Write-Host "Backup dibuat: articles.json.bak"
}

# HTML utama dan artikel
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.html -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\|\\archive\\' -and $_.Name -notmatch '\.bak(\.|$)' } |
    ForEach-Object {
        $path = $_.FullName
        $original = Get-Content -Path $path -Raw -Encoding utf8
        $updated = Normalize-Content -Content $original -IsHtml

        if ($updated -ne $original) {
            Save-Utf8File -Path $path -Content $updated
            if ($path -match '\\article\\') {
                Register-Change -Category 'article_pages' -Path $path
            } else {
                Register-Change -Category 'main_pages' -Path $path
            }
        }
    }

# CSS utama
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.css -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.Name -notmatch '\.bak(\.|$)' } |
    ForEach-Object {
        $path = $_.FullName
        $original = Get-Content -Path $path -Raw -Encoding utf8
        $updated = Normalize-Content -Content $original
        if ($updated -ne $original) {
            Save-Utf8File -Path $path -Content $updated
            Register-Change -Category 'css_files' -Path $path
        }
    }

# Package metadata
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include package.json,package-lock.json -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
    ForEach-Object {
        $path = $_.FullName
        $original = Get-Content -Path $path -Raw -Encoding utf8
        $updated = Normalize-Content -Content $original
        $updated = $updated -replace '"name"\s*:\s*"lintasjanten-article-generator"', '"name": "lintasjanten-article-generator"'
        $updated = $updated -replace '"name"\s*:\s*"lintasjanten"', '"name": "lintasjanten"'
        if ($path -match '\\tools\\package\.json$') {
            $updated = $updated -replace '"author"\s*:\s*"[^"]+"', '"author": "Lintas Janten Team"'
        }
        if ($updated -ne $original) {
            Save-Utf8File -Path $path -Content $updated
            Register-Change -Category 'package_files' -Path $path
        }
    }

# Dokumentasi & config
$docPatterns = @('*.md', '*.toml', '*.txt', '*.ps1')
Get-ChildItem -Path $WorkspaceRoot -Recurse -File |
    Where-Object {
        $_.Name -notmatch '\.bak(\.|$)' -and
        $_.FullName -notmatch '\\node_modules\\|\\archive\\' -and
        ($docPatterns | ForEach-Object { $_ }) -contains ('*' + $_.Extension)
    } |
    ForEach-Object {
        $path = $_.FullName
        $original = Get-Content -Path $path -Raw -Encoding utf8
        $updated = Normalize-Content -Content $original
        if ($updated -ne $original) {
            Save-Utf8File -Path $path -Content $updated
            Register-Change -Category 'docs' -Path $path
        }
    }

# Verifikasi akhir (abaikan file backup)
$verifyFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '\\node_modules\\|\\archive\\' -and
        $_.Name -notmatch '\.bak(\.|$)' -and
        $_.Extension -in '.html', '.css', '.json', '.md', '.toml', '.txt', '.ps1'
    }

$oldBrandCount = (Select-String -Path $verifyFiles.FullName -Pattern 'Lintas Janten|LintasJanten|LintasJanten|Lintas Janten|LintasJanten|LintasJanten' -AllMatches | Measure-Object).Count
$logoCount = (Select-String -Path $verifyFiles.FullName -Pattern 'logo\.png' -AllMatches | Measure-Object).Count
$primaryCount = (Select-String -Path $verifyFiles.FullName -Pattern '#EA580C' -AllMatches | Measure-Object).Count
$darkCount = (Select-String -Path $verifyFiles.FullName -Pattern '#7C2D12' -AllMatches | Measure-Object).Count
$secondaryCount = (Select-String -Path $verifyFiles.FullName -Pattern '#1F5F2F' -AllMatches | Measure-Object).Count

Write-Host ''
Write-Host ('Main pages updated: ' + $stats.main_pages.Count)
Write-Host ('Article pages updated: ' + $stats.article_pages.Count)
Write-Host ('CSS files updated: ' + $stats.css_files.Count)
Write-Host ('Package files updated: ' + $stats.package_files.Count)
Write-Host ('Documentation updated: ' + $stats.docs.Count)
Write-Host ''
Write-Host ('Old branding refs remaining: ' + $oldBrandCount)
Write-Host ('Legacy logo refs remaining: ' + $logoCount)
Write-Host ('#EA580C occurrences: ' + $primaryCount)
Write-Host ('#7C2D12 occurrences: ' + $darkCount)
Write-Host ('#1F5F2F occurrences: ' + $secondaryCount)
Write-Host ''
Write-Host 'Rebrand Lintas Janten selesai ✅'
