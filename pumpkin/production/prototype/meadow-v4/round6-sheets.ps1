param([switch]$Routes,[string]$Round='r6b')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path 'treasure/map-v4').Path
$font=New-Object System.Drawing.Font 'Arial',18
function Sheet($name,$tiles,$cols=3,$tw=768,$th=550) {
 $rows=[int][Math]::Ceiling($tiles.Count/$cols)
 $bmp=New-Object System.Drawing.Bitmap ($cols*$tw),($rows*$th)
 $graphics=[System.Drawing.Graphics]::FromImage($bmp)
 $graphics.Clear([System.Drawing.Color]::FromArgb(239,243,246))
 $graphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 for($i=0;$i -lt $tiles.Count;$i++) {
  $x=($i%$cols)*$tw;$y=[int][Math]::Floor($i/$cols)*$th
  $graphics.DrawString($tiles[$i][1],$font,[System.Drawing.Brushes]::Black,$x+12,$y+8)
  $im=[System.Drawing.Image]::FromFile("$root/$($tiles[$i][0])")
  $scale=[Math]::Min($tw/$im.Width,($th-40)/$im.Height)
  $iw=[int]($im.Width*$scale);$ih=[int]($im.Height*$scale)
  $graphics.DrawImage($im,[int]($x+($tw-$iw)/2),[int]($y+40+($th-40-$ih)/2),$iw,$ih);$im.Dispose()
 }
 $bmp.Save("$root/$name",[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $graphics.Dispose();$bmp.Dispose()
}
if($Routes) {
 $tiles=@();$names=(Get-Content prototype/meadow-v4/scene.json -Raw | ConvertFrom-Json).routes.PSObject.Properties.Name
 foreach($n in $names) { $tiles+=,@("build-rr6route-eye-route-$n.png","R6 / $n / offline") }
 Sheet 'build-route-ground.jpg' $tiles
} else {
 Sheet 'build-sbs.jpg' @(@('build-rrr4b-concept.png','ROUND 4 / lush'),@("build-r$Round-concept.png",'ROUND 6 / actual / offline'),@('concept.png','REFERENCE / approved concept'),@('build-rrr4b-top.png','ROUND 4 / north up'),@("build-r$Round-top.png",'ROUND 6 / north up'),@('../v2/meadow-island.png','REFERENCE / supplied v2 Meadow'))
 $tiles=@();foreach($n in @('portal-west','portal-bridge','portal-east','west','bridge','east','summit','shelf','recovery')) { $tiles+=,@("build-r$Round-eye-$n.png","R6 / $n / eye 5.5 / offline") }
 Sheet 'build-ground.jpg' $tiles
}
$font.Dispose()
