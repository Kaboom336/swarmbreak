Add-Type -AssemblyName System.Drawing
$outDir = $PSScriptRoot
$sheet = New-Object System.Drawing.Bitmap 1920,1230
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(17,24,32))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font 'Arial',20
$small = New-Object System.Drawing.Font 'Arial',15
$g.DrawString('MEADOW POLISH | matched offline production native geometry',$font,[System.Drawing.Brushes]::White,22,12)
$tags = @('before','after')
$shots = @('portal','camp')
for ($col=0; $col -lt 2; $col++) {
    $g.DrawString($tags[$col].ToUpper(),$font,[System.Drawing.Brushes]::Gold,(22+960*$col),55)
    for ($row=0; $row -lt 2; $row++) {
        $img = [System.Drawing.Image]::FromFile((Join-Path $outDir ('polish-'+$tags[$col]+'-'+$shots[$row]+'.png')))
        $g.DrawImage($img,(960*$col),(95+555*$row),960,540)
        $img.Dispose()
        $g.FillRectangle([System.Drawing.Brushes]::Black,(960*$col),(95+555*$row),110,28)
        $g.DrawString($shots[$row].ToUpper(),$small,[System.Drawing.Brushes]::White,(10+960*$col),(96+555*$row))
    }
}
$g.DrawString('Native proxy: original BEFORE; matched cameras. Brighter sky/beam approximated; kits, Roblox effects and UI need Studio.',$small,[System.Drawing.Brushes]::LightGray,22,1185)
$sheet.Save((Join-Path $outDir 'POLISH-SBS.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $sheet.Dispose(); $font.Dispose(); $small.Dispose()
