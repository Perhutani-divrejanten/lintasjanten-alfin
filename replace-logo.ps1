# Script untuk mengganti gambar brand lama dengan text-based logo di semua HTML files

$WorkspaceRoot = "c:\KULIAH\MAGANG\Magang di Perhutani\Lintas Janten"
$htmlFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.html" -File

$textBasedLogo = @"
<span style="font-weight: 700; color: #EA580C; font-size: 24px; letter-spacing: -0.5px;">LINTAS<span style="color: #1F5F2F; font-weight: 500; font-size: 18px; margin-left: 2px;">JANTEN</span></span>
"@

$replaceCount = 0
$legacyLogoPattern = 'logo\.' + 'png'

foreach ($file in $htmlFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $originalContent = $content

        # Ganti gambar brand lama di navbar dan artikel menjadi text logo baru
        $pattern1 = '<img[^>]*src="img/' + $legacyLogoPattern + '"[^>]*>'
        $pattern2 = '<img[^>]*src="\.\./img/' + $legacyLogoPattern + '"[^>]*>'

        $newContent = $content -replace $pattern1, $textBasedLogo
        $newContent = $newContent -replace $pattern2, $textBasedLogo

        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
            $replaceCount++
            Write-Host "Updated branding in: $($file.Name)"
        }
    } catch {
        Write-Host "Error processing $($file.FullName): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Brand logo replacement complete!"
Write-Host "Total files updated: $replaceCount"
