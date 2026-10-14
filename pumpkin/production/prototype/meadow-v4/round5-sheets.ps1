param([string]$Round='before')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path 'treasure/map-v4').Path
$font=New-Object System.Drawing.Font 'Arial',18
function Sheet($name,$tiles,$cols=2,$tw=768,$th=550) {
 $rows=[int][Math]::Ceiling($tiles.Count/$cols)
 $bmp=New-Object System.Drawing.Bitmap ($cols*$tw),($rows*$th)
 $graphics=[System.Drawing.Graphics]::FromImage($bmp)
 $graphics.Clear([System.Drawing.Color]::FromArgb(239,243,246))
 $graphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 for($i=0;$i -lt $tiles.Count;$i++) {
  $x=($i%$cols)*$tw;$y=[int][Math]::Floor($i/$cols)*$th
  $graphics.DrawString($tiles[$i][1],$font,[System.Drawing.Brushes]::Black,$x+12,$y+8)
  $im=[System.Drawing.Image]::FromFile("$root/$($tiles[$i][0])")
  $graphics.DrawImage($im,$x,$y+38,$tw,($th-38));$im.Dispose()
 }
 $bmp.Save("$root/$name",[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $graphics.Dispose();$bmp.Dispose()
}
if($Round -eq 'before') {
 $crops=@(
  @('under-south',210,290,1120,490),@('under',240,100,1080,830),
  @('concept',260,240,1060,700),@('top',270,175,1030,760),
  @('eye-portal-west',0,130,1300,750),@('eye-west',100,80,1300,850),
  @('eye-bridge',100,70,1300,850),@('eye-east',100,70,1300,850),
  @('eye-summit',100,70,1300,850),@('eye-shelf',100,70,1300,850),
  @('eye-recovery',100,70,1300,850))
 foreach($c in $crops) {
  $im=[System.Drawing.Bitmap]::FromFile("$root/build-rr5before-$($c[0]).png")
  $rect=New-Object System.Drawing.Rectangle $c[1],$c[2],$c[3],$c[4]
  $crop=$im.Clone($rect,$im.PixelFormat)
  $crop.Save("$root/r5-crop-$($c[0]).jpg",[System.Drawing.Imaging.ImageFormat]::Jpeg)
  $crop.Dispose();$im.Dispose()
 }
} else {
 Sheet 'build-sbs.jpg' @(@('concept.png','REFERENCE: approved concept'),@("build-rr5$Round-concept.png",'R5 actual manifest / offline'),@('../v2/home-island.png','REFERENCE: v2 Home'),@('../v2/meadow-island.png','REFERENCE: v2 Meadow'))
 Sheet 'build-under.jpg' @(@('build-rr5before-under-south.png','BEFORE / south'),@("build-rr5$Round-under-south.png",'AFTER / south'),@('build-rr5before-under.png','BEFORE / underneath'),@("build-rr5$Round-under.png",'AFTER / underneath'),@("build-rr5$Round-under-west.png",'AFTER / west'),@("build-rr5$Round-under-east.png",'AFTER / east'),@('build-rr5before-under-north.png','BEFORE / north'),@("build-rr5$Round-under-north.png",'AFTER / north'))
 $tiles=@();foreach($n in @('portal-west','portal-bridge','portal-east','west','bridge','east','summit','shelf','recovery')) {
  $tiles+=,@("build-rr5before-eye-$n.png","BEFORE / $n / eye 5.5")
  $tiles+=,@("build-rr5$Round-eye-$n.png","AFTER / $n / eye 5.5")
 }
 Sheet 'build-ground.jpg' $tiles
 $routeTiles=@();$routeNames=(Get-Content prototype/meadow-v4/scene.json -Raw | ConvertFrom-Json).routes.PSObject.Properties.Name
 foreach($n in $routeNames) {
  $routeTiles+=,@("build-rr5before-eye-route-$n.png","BEFORE / $n / eye 5.5")
  $routeTiles+=,@("build-rr5$Round-eye-route-$n.png","AFTER / $n / eye 5.5")
 }
 Sheet 'build-route-ground.jpg' $routeTiles 2 768 550
 Sheet 'build-top.jpg' @(@('build-rr5before-top.png','BEFORE / north up'),@("build-rr5$Round-top.png",'AFTER / north up'))
}
$font.Dispose()
