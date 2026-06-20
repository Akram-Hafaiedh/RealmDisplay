Add-Type -AssemblyName System.Drawing

$mediaDir = "c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\RealmDisplay\Media\Icons"
if (!(Test-Path $mediaDir)) {
    New-Item -ItemType Directory -Force -Path $mediaDir
}

function Create-Icon($name, $drawAction) {
    $outputPath = Join-Path $mediaDir "$name.png"
    
    if (-not $Force -and (Test-Path $outputPath)) {
        Write-Host "Skipped (already exists): $outputPath"
        return
    }
    $bmp = New-Object System.Drawing.Bitmap(32, 32)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $whitePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White)

    $drawAction.Invoke($g, $whiteBrush, $whitePen)

    $whiteBrush.Dispose()
    $whitePen.Dispose()
    $g.Dispose()

    $outputPath = Join-Path $mediaDir "$name.png"
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Generated: $outputPath"
}

# 1. Chevron
Create-Icon "chevron" {
    param($g, $brush, $pen)
    $pen.Width = 4
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    
    $points = @(
        (New-Object System.Drawing.PointF(8, 12)),
        (New-Object System.Drawing.PointF(16, 20)),
        (New-Object System.Drawing.PointF(24, 12))
    )
    $g.DrawLines($pen, $points)
}

# 2. Settings (Gear)
Create-Icon "settings" {
    param($g, $brush, $pen)
    $pen.Width = 4
    $g.DrawEllipse($pen, 10, 10, 12, 12) # outer ring
    
    # 8 teeth
    for ($i = 0; $i -lt 8; $i++) {
        $angle = $i * [Math]::PI / 4
        $cos = [Math]::Cos($angle)
        $sin = [Math]::Sin($angle)
        
        $x1 = 16 + 6 * $cos
        $y1 = 16 + 6 * $sin
        $x2 = 16 + 12 * $cos
        $y2 = 16 + 12 * $sin
        
        $g.DrawLine($pen, $x1, $y1, $x2, $y2)
    }
    
    # center hole
    $g.FillEllipse($brush, 13, 13, 6, 6)
    
    $clearBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Transparent)
    # Using DestinationOut to clear the center hole (making it hollow)
    $oldMode = $g.CompositingMode
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.FillEllipse($clearBrush, 14, 14, 4, 4)
    $g.CompositingMode = $oldMode
    $clearBrush.Dispose()
}

# 3. Lock
Create-Icon "lock" {
    param($g, $brush, $pen)
    # Shackle
    $pen.Width = 3
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    
    # Draw shackle arc
    $g.DrawArc($pen, 10, 6, 12, 12, 180, 180)
    # Shackle legs
    $g.DrawLine($pen, 10, 12, 10, 16)
    $g.DrawLine($pen, 22, 12, 22, 16)
    
    # Body
    # Draw rounded rect body
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rect = New-Object System.Drawing.RectangleF(7, 14, 18, 12)
    $r = 3
    $path.AddArc(($rect.X), ($rect.Y), (2*$r), (2*$r), 180, 90)
    $path.AddArc(($rect.Right - 2*$r), ($rect.Y), (2*$r), (2*$r), 270, 90)
    $path.AddArc(($rect.Right - 2*$r), ($rect.Bottom - 2*$r), (2*$r), (2*$r), 0, 90)
    $path.AddArc(($rect.X), ($rect.Bottom - 2*$r), (2*$r), (2*$r), 90, 90)
    $path.CloseFigure()
    
    $g.FillPath($brush, $path)
    $path.Dispose()
}

# 4. Unlock
Create-Icon "unlock" {
    param($g, $brush, $pen)
    # Shackle
    $pen.Width = 3
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    
    # Draw shackle arc (shifted up to show unlocked state)
    $g.DrawArc($pen, 10, 3, 12, 12, 180, 180)
    # Shackle legs (unconnected/open)
    $g.DrawLine($pen, 10, 9, 10, 16)
    $g.DrawLine($pen, 22, 9, 22, 12) # left hanging
    
    # Body
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rect = New-Object System.Drawing.RectangleF(7, 14, 18, 12)
    $r = 3
    $path.AddArc(($rect.X), ($rect.Y), (2*$r), (2*$r), 180, 90)
    $path.AddArc(($rect.Right - 2*$r), ($rect.Y), (2*$r), (2*$r), 270, 90)
    $path.AddArc(($rect.Right - 2*$r), ($rect.Bottom - 2*$r), (2*$r), (2*$r), 0, 90)
    $path.AddArc(($rect.X), ($rect.Bottom - 2*$r), (2*$r), (2*$r), 90, 90)
    $path.CloseFigure()
    
    $g.FillPath($brush, $path)
    $path.Dispose()
}

# 5. Refresh
Create-Icon "refresh" {
    param($g, $brush, $pen)
    $pen.Width = 3
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    
    # Draw 270 degree arc
    $g.DrawArc($pen, 8, 8, 16, 16, 45, 270)
    
    # Arrow head at the end of the arc (45 degrees is approx x=21.6, y=10.3)
    # We will draw a small triangle/head pointing down/left
    $headPoints = @(
        (New-Object System.Drawing.PointF(22, 6)),
        (New-Object System.Drawing.PointF(22, 14)),
        (New-Object System.Drawing.PointF(14, 14))
    )
    $g.DrawLines($pen, $headPoints)
}

# 6. Sun (Theme Light toggle)
Create-Icon "theme_light" {
    param($g, $brush, $pen)
    $g.FillEllipse($brush, 11, 11, 10, 10)
    
    $pen.Width = 2
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    
    # 8 rays
    for ($i = 0; $i -lt 8; $i++) {
        $angle = $i * [Math]::PI / 4
        $cos = [Math]::Cos($angle)
        $sin = [Math]::Sin($angle)
        
        $x1 = 16 + 7 * $cos
        $y1 = 16 + 7 * $sin
        $x2 = 16 + 12 * $cos
        $y2 = 16 + 12 * $sin
        
        $g.DrawLine($pen, $x1, $y1, $x2, $y2)
    }
}

# 7. Moon (Theme Dark toggle)
Create-Icon "theme_dark" {
    param($g, $brush, $pen)
    # Outer circle
    $g.FillEllipse($brush, 6, 6, 20, 20)
    
    # Subtract inner offset circle to form crescent
    $clearBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Transparent)
    $oldMode = $g.CompositingMode
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.FillEllipse($clearBrush, 12, 4, 20, 20)
    $g.CompositingMode = $oldMode
    $clearBrush.Dispose()
}

# 8. Close (X)
Create-Icon "close" {
    param($g, $brush, $pen)
    $pen.Width = 4
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round

    # Draw two crossing lines for an 'X'
    $g.DrawLine($pen, 8, 8, 24, 24)
    $g.DrawLine($pen, 24, 8, 8, 24)
}

# 9. Share (Nodes connected by lines)
Create-Icon "share" {
    param($g, $brush, $pen)
    $pen.Width = 3
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Draw connecting lines
    $g.DrawLine($pen, 10, 9, 22, 16)
    $g.DrawLine($pen, 10, 23, 22, 16)

    # Draw three node circles
    $g.FillEllipse($brush, 6, 5, 8, 8)     # Top-left node
    $g.FillEllipse($brush, 6, 19, 8, 8)    # Bottom-left node
    $g.FillEllipse($brush, 18, 12, 8, 8)   # Right node
}