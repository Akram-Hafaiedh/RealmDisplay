# ==============================================================================
#  generate_icons.ps1
#  Regenerates all custom PNG icons used by RealmDisplay.
#  Run from an elevated PowerShell session (or one with write access to the
#  AddOns folder).
# ==============================================================================

Add-Type -AssemblyName System.Drawing

$mediaDir = "c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\RealmDisplay\Media\Icons"
if (!(Test-Path $mediaDir)) {
    New-Item -ItemType Directory -Force -Path $mediaDir | Out-Null
}

function Create-Icon($name, $drawAction) {
    $outputPath = Join-Path $mediaDir "$name.png"

    if (-not $Force -and (Test-Path $outputPath)) {
        Write-Host "Skipped (already exists): $outputPath" -ForegroundColor DarkGray
        return
    }

    $bmp = New-Object System.Drawing.Bitmap(32, 32)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $whitePen   = New-Object System.Drawing.Pen([System.Drawing.Color]::White)

    $drawAction.Invoke($g, $whiteBrush, $whitePen)

    $whiteBrush.Dispose()
    $whitePen.Dispose()
    $g.Dispose()

    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Generated: $outputPath" -ForegroundColor Green
}

# ----------------------------------------------------------------
# chevron.png — down arrow for the realm dropdown
# ----------------------------------------------------------------
Create-Icon "chevron" {
    param($g, $brush, $pen)
    $pen.Width    = 4
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    $points = @(
        (New-Object System.Drawing.PointF(8, 12)),
        (New-Object System.Drawing.PointF(16, 20)),
        (New-Object System.Drawing.PointF(24, 12))
    )
    $g.DrawLines($pen, $points)
}

# ----------------------------------------------------------------
# close.png — clean X for the panel close button
# ----------------------------------------------------------------
Create-Icon "close" {
    param($g, $brush, $pen)
    $pen.Width    = 3
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round

    $g.DrawLine($pen, 9, 9, 23, 23)
    $g.DrawLine($pen, 23, 9, 9, 23)
}

Write-Host "`nDone." -ForegroundColor Cyan