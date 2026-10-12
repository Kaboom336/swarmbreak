# Windows fallback for comparison/contact assembly when Pillow cannot run.
# Artwork is copied unchanged; only comparison JPGs receive labels/resizing.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$rows = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'MANIFEST.json') | ConvertFrom-Json
$font = New-Object System.Drawing.Font('Arial',26,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$titleFont = New-Object System.Drawing.Font('Arial',36,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$gold = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#ffc83d'))
$cyan = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#72dbff'))
$white = [System.Drawing.Brushes]::White
$background = [System.Drawing.ColorTranslator]::FromHtml('#17141f')
$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$parameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
$parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality,[long]92)

foreach ($row in $rows) {
    $ours = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($row.sheet+'.png')))
    $refSheet = $row.sheet
    if ($row.refSheet) { $refSheet = $row.refSheet }
    $ref = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ('../refs2/'+$refSheet+'-ref-'+$row.ref+'.jpg')))
    $h=900
    $ow=[int][Math]::Round($ours.Width*$h/$ours.Height)
    $rw=[int][Math]::Round($ref.Width*$h/$ref.Height)
    $bmp=New-Object System.Drawing.Bitmap(($ow+$rw+12),($h+64))
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($background)
    $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.DrawImage($ours,0,64,$ow,$h)
    $g.DrawImage($ref,($ow+12),64,$rw,$h)
    $g.DrawString(('OURS v3 | '+$row.score+'/10'),$font,$gold,14,17)
    $g.DrawString(('BEST REF | '+$row.game+' | ref-'+$row.ref),$font,$cyan,($ow+26),17)
    $bmp.Save((Join-Path $PSScriptRoot ($row.sheet+'-sbs.jpg')),$encoder,$parameters)
    $g.Dispose(); $bmp.Dispose(); $ours.Dispose(); $ref.Dispose()
}
$height=90+[int][Math]::Ceiling($rows.Count/3.0)*400
$sheet=New-Object System.Drawing.Bitmap(1680,$height)
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear($background)
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.DrawString('STEAL A PUMPKIN | v3 | 14 gameplay concepts',$titleFont,$gold,22,24)
for ($i=0; $i -lt $rows.Count; $i++) {
    $row=$rows[$i]
    $im=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($row.sheet+'.png')))
    $scale=[Math]::Min(540.0/$im.Width,340.0/$im.Height)
    $w=[int][Math]::Round($im.Width*$scale)
    $h=[int][Math]::Round($im.Height*$scale)
    $x=($i%3)*560
    $y=90+[int][Math]::Floor($i/3.0)*400
    $g.DrawImage($im,[int]($x+(560-$w)/2),[int]($y+(340-$h)/2),$w,$h)
    $g.DrawString(($row.sheet+' | '+$row.score+'/10'),$font,$white,($x+12),($y+352))
    $im.Dispose()
}
$sheet.Save((Join-Path $PSScriptRoot '_sheet.jpg'),$encoder,$parameters)
$g.Dispose(); $sheet.Dispose(); $font.Dispose(); $titleFont.Dispose(); $gold.Dispose(); $cyan.Dispose(); $parameters.Dispose()
