Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$order = @('hub-topdown','hub-perspective','zone1-perspective','zone1-topdown','zones-strip','hud-desktop','hud-phone','panels-shop-index','panels-upgrades-daily','hatch-reveal','scythes','pets','guards-and-king','collectibles','first-5-min')
$current = @(Get-ChildItem -LiteralPath $root -File -Filter '*.png' | Where-Object { !$_.Name.StartsWith('_refs') -and !$_.Name.EndsWith('.v1.png') } | ForEach-Object { $_.BaseName })
$names = @($order | Where-Object { $_ -in $current }) + @($current | Where-Object { $_ -notin $order } | Sort-Object)
$height = 80 + [int][Math]::Ceiling($names.Count / 3.0) * 345
$sheet = New-Object System.Drawing.Bitmap(1680,$height)
$graphics = [System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#241a38'))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$font = New-Object System.Drawing.Font('Arial',24,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$titleFont = New-Object System.Drawing.Font('Arial',34,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#fff8ec'))
$titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#ffc83d'))
$graphics.DrawString(('STEAL A PUMPKIN | ' + $names.Count + ' CURRENT CONCEPT SHEETS'),$titleFont,$titleBrush,22,20)
for ($i=0; $i -lt $names.Count; $i++) {
    $path = Join-Path $root ($names[$i]+'.png')
    $im = [System.Drawing.Image]::FromFile($path)
    try {
        $scale = [Math]::Min(540.0/$im.Width,303.0/$im.Height)
        $width = [int][Math]::Round($im.Width*$scale)
        $thumbHeight = [int][Math]::Round($im.Height*$scale)
        $x = ($i % 3)*560
        $y = 80 + [int][Math]::Floor($i/3.0)*345
        $graphics.DrawImage($im,[int]($x+(560-$width)/2),$y,$width,$thumbHeight)
        $graphics.DrawString(($names[$i]+'.png'),$font,$labelBrush,($x+10),($y+310))
        Write-Output ($names[$i] + ' ' + $im.Width + 'x' + $im.Height)
    } finally { $im.Dispose() }
}
try {
    $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $parameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality,[long]92)
    $sheet.Save((Join-Path $root '_sheet.jpg'),$encoder,$parameters)
    $parameters.Dispose()
} finally {
    $graphics.Dispose()
    $sheet.Dispose()
    $font.Dispose()
    $titleFont.Dispose()
    $labelBrush.Dispose()
    $titleBrush.Dispose()
}

