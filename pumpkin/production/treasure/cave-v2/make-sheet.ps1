Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$taskRoot = $PSScriptRoot
if (-not $taskRoot) { $taskRoot = Join-Path (Get-Location) 'treasure/cave-v2' }
$white = [System.Drawing.Brushes]::White
$muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(186,203,221))
$gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,202,87))
$font = New-Object System.Drawing.Font 'Arial',17
$head = New-Object System.Drawing.Font 'Arial',27,([System.Drawing.FontStyle]::Bold)
$plan = New-Object System.Drawing.Bitmap 1100,940
$pg = [System.Drawing.Graphics]::FromImage($plan)
$pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$pg.Clear([System.Drawing.Color]::FromArgb(16,29,48))
$pg.DrawString('SWITCHYARD MESA V2 / TRUE OVERHEAD',$head,$white,28,20)
$pg.DrawString('Proposed coordinates / north +Z / PLAN and ROUTES govern construction',$font,$muted,28,61)
$gridPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(34,53,78)),1
for($x=126;$x -lt 880;$x+=28){$pg.DrawLine($gridPen,$x,100,$x,700)}
for($y=100;$y -lt 700;$y+=28){$pg.DrawLine($gridPen,110,$y,880,$y)}
$poly = [System.Drawing.Point[]]@((New-Object System.Drawing.Point 160,180),(New-Object System.Drawing.Point 340,115),(New-Object System.Drawing.Point 760,130),(New-Object System.Drawing.Point 835,235),(New-Object System.Drawing.Point 820,590),(New-Object System.Drawing.Point 610,680),(New-Object System.Drawing.Point 210,670),(New-Object System.Drawing.Point 125,430))
$land = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(67,73,82))
$pg.FillPolygon($land,$poly)
$edge = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(158,136,176)),5
$pg.DrawPolygon($edge,$poly)
$rock = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(108,88,122))
$pg.FillRectangle($rock,657,174,170,115)
$pg.FillRectangle($rock,280,208,205,96)
$pg.FillEllipse([System.Drawing.Brushes]::MidnightBlue,425,370,130,130)
$routes = Get-Content -LiteralPath (Join-Path $taskRoot 'ROUTES.json') -Raw | ConvertFrom-Json
$colors = @{main='#87ef72';cave='#69cafa';cartApproach='#ffbe58';cartRail='#ffbe58';crosslinkNorth='#ced8e5';crosslinkSouth='#ced8e5';pitRecovery='#f5a3e7';railWalkBypass='#b99667'}
foreach($taskRouteName in @('railWalkBypass','crosslinkNorth','crosslinkSouth','main','cave','cartApproach','cartRail','pitRecovery')){
 $route = $routes.routeCenterlines.PSObject.Properties[$taskRouteName]
 $pts = @($route.Value | ForEach-Object { New-Object System.Drawing.PointF ([single](490+$_[0]*1.4)),([single](400-$_[1]*1.4)) })
 $width=12; if($route.Name.StartsWith('cross')){$width=6}
 $pen=New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($colors[$route.Name])),$width
 if($route.Name -eq 'cave'){$pen.DashStyle=[System.Drawing.Drawing2D.DashStyle]::Dash}
 $pg.DrawLines($pen,[System.Drawing.PointF[]]$pts);$pen.Dispose()
}
$gap=New-Object System.Drawing.Pen ([System.Drawing.Color]::Crimson),16
$pg.DrawLine($gap,498,427,482,443)
$pg.FillRectangle([System.Drawing.Brushes]::Turquoise,246,540,68,56)
function PlanText($x,$z,$text,$brush=$white,$dy=0){$pg.DrawString($text,$font,$brush,[single](490+$x*1.4),[single](400-$z*1.4+$dy))}
PlanText 115 153 'GEODE CAMP +48'
PlanText -147 141 'MAIN 29.5s EST.'
PlanText 108 -10 'CAVE 33.0s EST.'
PlanText -72 86 'CART 19.5-23.5s EST.' $gold
PlanText -27 -8 '16-STUD GAP'
PlanText -25 -65 'PIT -16'
PlanText -120 -45 'CLIMB OUT'
PlanText -171 -162 'CYAN SAFETY Y0'
$numfont=New-Object System.Drawing.Font 'Arial',18,([System.Drawing.FontStyle]::Bold)
foreach($b in @(@(74,54,'1'),@(0,-25,'2'),@(-100,65,'3'),@(80,-35,'4'),@(-70,-65,'5'))){
 $bx=490+$b[0]*1.4;$by=400-$b[1]*1.4
 $pg.FillEllipse([System.Drawing.Brushes]::Tomato,[single]($bx-15),[single]($by-15),30,30)
 $pg.DrawString($b[2],$numfont,$white,[single]($bx-8),[single]($by-14))
}
$pg.DrawString('N ^',$head,$white,925,110)
$legend=@('1 TNT | 2 support / jump | 3 guardian throw | 4 shatter cavern | 5 switch / bumper','Green main | amber rail | cyan cave | white links | pink recovery | brown bypass','Rail has a permanent 18-wide walking bypass. Only marked gap breaks.','Camp vista SW: MAIN / CART / CAVE entrances plus raised cyan exit beacon.','520 x 400 | lanes >=18 | turns >=28 | cave headroom >=24 | ramps <=25 degrees','4-8 players | same-item 60s deadline | no hide spots | separate safety entries')
for($i=0;$i -lt $legend.Count;$i++){$pg.DrawString($legend[$i],$font,$muted,28,(742+$i*29))}
$pg.Dispose();$plan.Save((Join-Path $taskRoot 'PLAN.png'),[System.Drawing.Imaging.ImageFormat]::Png);$plan.Dispose()
$sheet = New-Object System.Drawing.Bitmap 3400,4020
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(15,23,35))
$big = New-Object System.Drawing.Font 'Arial',49,([System.Drawing.FontStyle]::Bold)
$body = New-Object System.Drawing.Font 'Arial',29
$bold = New-Object System.Drawing.Font 'Arial',31,([System.Drawing.FontStyle]::Bold)
$g.DrawString('CRYSTAL CAVE V2 / SWITCHYARD MESA',$big,$white,40,24)
$g.DrawString('ONE REDESIGN | Main 29.5s ESTIMATED | 4-8 players | 60s deadline | no hide spots',$body,$gold,43,98)
function Fit($file,$x,$y,$w,$h){
 $img=[System.Drawing.Image]::FromFile((Join-Path $taskRoot $file))
 $scale=[Math]::Min($w/$img.Width,$h/$img.Height)
 $dw=[int]($img.Width*$scale);$dh=[int]($img.Height*$scale)
 $g.DrawImage($img,[int]($x+($w-$dw)/2),[int]($y+($h-$dh)/2),$dw,$dh);$img.Dispose()
}
$g.DrawString('GENERATED BLUEPRINT / illustrative',$bold,$white,40,164)
$g.DrawString('3/4 IN-GAME CONCEPT / generated art',$bold,$white,1490,164)
Fit 'blueprint.png' 40 218 1400 1060
Fit 'concept.png' 1480 218 1880 1060
$g.DrawString('PRECISE PLAN / proposed coordinates',$bold,$white,40,1300)
$g.DrawString('TWO HERO CLIPS / 3 panels each / portrait',$bold,$white,1860,1300)
Fit 'PLAN.png' 40 1360 1760 1250
Fit 'storyboard-final.png' 1850 1370 1510 2420
function Block($text,$x,$y,$w,$h,$brush=$muted){$g.DrawString($text,$body,$brush,(New-Object System.Drawing.RectangleF $x,$y,$w,$h))}
$g.DrawString('FIVE CLIP FEATURES / tell -> choice -> payoff',$bold,$gold,45,2630)
Block '1 TNT: 1s spark + ring -> sidestep / bail -> loose geode, debris, visual crater. 15s cooldown.' 45 2700 1740 90
Block '2 BIG AIR: 1s spark + 2s cracks, JUMP READY -> jump or bypass -> broad landing; fail has pit climb-out. 20s reset.' 45 2800 1740 100
Block '3 DYNAMITE: 1.5s arm tell + 1s fuse, fixed ring -> dodge / rock cover -> narrow miss. 7s cooldown.' 45 2910 1740 90
Block '4 SHATTER: next-only white cracks -> untouched center lane -> chain burst / visible geode drop. 20s reset.' 45 3010 1740 90
Block '5 SWITCH: 2s amber arrow -> override / dismount -> soft bumper bonk, 3-4s added EST. 12s cooldown.' 45 3110 1740 100
$g.DrawString('BLIND CRITIC / ONE CORRECTION PASS',$bold,$gold,45,3240)
Block 'Fixed hidden jump threshold, chained drops, recovery camping, camera staging and crystal cause. Shared 3s mercy; visible 1s pickup priority. No runtime acceptance claimed.' 45 3300 1740 150
$g.DrawString('REFERENCE ARENA / existing project bars',$bold,$gold,45,3480)
Block 'Steal an Egg: C diagonal docks -> V2 elevated route fan + exit beacon. Catastrophic Horse Racing: C shuttle -> V2 warned big air + recoverable shatter. V2 art: stronger rock height, broad ramps.' 45 3540 1740 160
Block 'LESSONS: show jump readiness; share hazard mercy; frame tells ahead of normal camera.' 45 3730 1740 110 $white
Block 'ART QA: blueprint rail/marker drift; PLAN + ROUTES + CAVE-V2.md govern. Generated images are concepts, not screenshots. Real travel, phone framing and jump physics UNKNOWN.' 1860 3790 1500 180
$g.Dispose();$sheet.Save((Join-Path $taskRoot '_sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
foreach($obj in @($font,$head,$numfont,$gridPen,$land,$edge,$rock,$gap,$big,$body,$bold,$muted,$gold)){$obj.Dispose()}
