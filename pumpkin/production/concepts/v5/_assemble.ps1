param([switch]$Refs)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$names=Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../v4') -Filter '*.png' | Sort-Object Name | ForEach-Object BaseName
$bg=[System.Drawing.ColorTranslator]::FromHtml('#17141f')
$font=New-Object System.Drawing.Font('Arial',24,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$small=New-Object System.Drawing.Font('Arial',20,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$encoder=[System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$params=New-Object System.Drawing.Imaging.EncoderParameters(1)
$params.Param[0]=New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality,[long]94)
function Draw-Fitted($graphics,$im,[int]$x,[int]$y,[int]$boxw,[int]$boxh){
 $scale=[Math]::Min($boxw/[double]$im.Width,$boxh/[double]$im.Height)
 $w=[int]($im.Width*$scale);$h=[int]($im.Height*$scale)
 $graphics.DrawImage($im,[int]($x+($boxw-$w)/2),[int]($y+($boxh-$h)/2),$w,$h)
}
foreach($name in $names){
 $before=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ('../v4/'+$name+'.png')))
 $after=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($name+'.png')))
 $bmp=New-Object System.Drawing.Bitmap(2572,802);$g=[System.Drawing.Graphics]::FromImage($bmp);$g.Clear($bg)
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
 $g.DrawString(('v4 | '+$name),$font,[System.Drawing.Brushes]::Gold,12,15)
 $g.DrawString(('v5 | '+$name+' | AI concept, not Studio capture'),$font,[System.Drawing.Brushes]::LightSkyBlue,1304,15)
 Draw-Fitted $g $before 0 62 1280 720
 Draw-Fitted $g $after 1292 62 1280 720
 $bmp.Save((Join-Path $PSScriptRoot ($name+'-v4v5.jpg')),$encoder,$params)
 $g.Dispose();$bmp.Dispose();$before.Dispose();$after.Dispose()
}
$bmp=New-Object System.Drawing.Bitmap(1680,1940);$g=[System.Drawing.Graphics]::FromImage($bmp);$g.Clear($bg)
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.DrawString('STEAL A PUMPKIN | v5 | 15 Roblox-buildable screenshot concepts',$font,[System.Drawing.Brushes]::Gold,20,20)
$g.DrawString('Built-in imagegen + actual refs3 frames | NOT Studio captures | feasibility pre-check only',$small,[System.Drawing.Brushes]::LightSkyBlue,20,53)
for($i=0;$i -lt $names.Count;$i++){
 $im=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($names[$i]+'.png')))
 $x=($i%3)*560;$y=90+[int][Math]::Floor($i/3.0)*370
 Draw-Fitted $g $im $x $y 540 310
 $g.DrawString($names[$i],$font,[System.Drawing.Brushes]::White,($x+10),($y+320))
 $im.Dispose()
}
$bmp.Save((Join-Path $PSScriptRoot '_sheet.jpg'),$encoder,$params);$g.Dispose();$bmp.Dispose()
if($Refs){
 $rows=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'MANIFEST.json') | ConvertFrom-Json
 foreach($row in $rows){
  $bmp=New-Object System.Drawing.Bitmap(2572,802);$g=[System.Drawing.Graphics]::FromImage($bmp);$g.Clear($bg)
  $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $ours=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($row.screen+'.png')))
  $ref=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ('../refs3/'+$row.refs[0])))
  $g.DrawString(('v5 concept | '+$row.screen),$font,[System.Drawing.Brushes]::Gold,12,15)
  $g.DrawString(('REAL Roblox reference | '+$row.refs[0]),$font,[System.Drawing.Brushes]::LightSkyBlue,1304,15)
  Draw-Fitted $g $ours 0 62 1280 720
  Draw-Fitted $g $ref 1292 62 1280 720
  $bmp.Save((Join-Path $PSScriptRoot ($row.screen+'-refs3.jpg')),$encoder,$params)
  $ours.Dispose();$ref.Dispose();$g.Dispose();$bmp.Dispose()
 }
}
$font.Dispose();$small.Dispose();$params.Dispose()
Write-Output ('Verified assembly: '+$names.Count+' v4-left/v5-right comparisons plus contact sheet.')
