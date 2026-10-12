param([switch]$Sheet)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference='Stop'
$rows=Get-Content -Raw (Join-Path $PSScriptRoot 'MANIFEST.json') | ConvertFrom-Json
$font=New-Object System.Drawing.Font('Arial',24,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$bg=[System.Drawing.ColorTranslator]::FromHtml('#17141f')
$encoder=[System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$params=New-Object System.Drawing.Imaging.EncoderParameters(1)
$params.Param[0]=New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality,[long]94)
foreach($row in $rows){
 $ours=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($row.sheet+'.png')))
 $ref=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ('../refs3/'+$row.ref)))
 $bmp=New-Object System.Drawing.Bitmap(2572,790); $g=[System.Drawing.Graphics]::FromImage($bmp); $g.Clear($bg)
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
 foreach($pair in @(@($ours,0),@($ref,1292))){
  $im=$pair[0];$x=[int]$pair[1];$s=[Math]::Min(1280.0/$im.Width,720.0/$im.Height)
  $w=[int]($im.Width*$s);$h=[int]($im.Height*$s)
  $g.DrawImage($im,[int]($x+(1280-$w)/2),[int](70+(720-$h)/2),$w,$h)
 }
 $g.DrawString(('OURS v4 | '+$row.sheet+' | pre-check '+$row.score+'/10'),$font,[System.Drawing.Brushes]::Gold,12,20)
 $g.DrawString(('REF | '+$row.game+' | uploaded '+$row.uploadDate),$font,[System.Drawing.Brushes]::LightSkyBlue,1304,20)
 $bmp.Save((Join-Path $PSScriptRoot ($row.sheet+'-sbs.jpg')),$encoder,$params)
 $g.Dispose();$bmp.Dispose();$ours.Dispose();$ref.Dispose()
}
if($Sheet){
 $bmp=New-Object System.Drawing.Bitmap(1680,(90+[int][Math]::Ceiling($rows.Count/3.0)*370));$g=[System.Drawing.Graphics]::FromImage($bmp);$g.Clear($bg)
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.DrawString(('STEAL A PUMPKIN | v4 | '+$rows.Count+' screens | self pre-checks'),$font,[System.Drawing.Brushes]::Gold,20,24)
 for($i=0;$i -lt $rows.Count;$i++){
  $row=$rows[$i];$im=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($row.sheet+'.png')))
  $s=[Math]::Min(540.0/$im.Width,310.0/$im.Height);$w=[int]($im.Width*$s);$h=[int]($im.Height*$s)
  $x=($i%3)*560;$y=90+[int][Math]::Floor($i/3.0)*370
  $g.DrawImage($im,[int]($x+(560-$w)/2),[int]($y+(310-$h)/2),$w,$h)
  $g.DrawString(($row.sheet+' | '+$row.score+'/10'),$font,[System.Drawing.Brushes]::White,($x+10),($y+320));$im.Dispose()
 }
 $bmp.Save((Join-Path $PSScriptRoot '_sheet.jpg'),$encoder,$params);$g.Dispose();$bmp.Dispose()
}
$font.Dispose();$params.Dispose()
