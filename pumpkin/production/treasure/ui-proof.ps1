Add-Type -AssemblyName System.Drawing
$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$ink=[Drawing.Color]::FromArgb(31,27,47)
$cream=[Drawing.Color]::FromArgb(255,245,218)
$gold=[Drawing.Color]::FromArgb(255,207,65)
$cyan=[Drawing.Color]::FromArgb(63,215,235)
$panel=[Drawing.Color]::FromArgb(49,60,84)
$family=New-Object Drawing.FontFamily 'Comic Sans MS'
$small=New-Object Drawing.Font 'Arial',17
$tiny=New-Object Drawing.Font 'Arial',13
$title=New-Object Drawing.Font 'Arial',27,([Drawing.FontStyle]::Bold)
function Label($g,$s,$x,$y,$color=$cream,$font=$small){
 $brush=New-Object Drawing.SolidBrush $color
 $g.DrawString($s,$font,$brush,[single]$x,[single]$y);$brush.Dispose()
}
function DrawType($g,$s,$x,$y,$size,$color=$cream){
 $path=New-Object Drawing.Drawing2D.GraphicsPath
 $path.AddString($s,$family,([int][Drawing.FontStyle]::Bold),[single]$size,(New-Object Drawing.PointF $x,$y),[Drawing.StringFormat]::GenericTypographic)
 $pen=New-Object Drawing.Pen $ink,([single]([math]::Max(2,$size/14)))
 $pen.LineJoin=[Drawing.Drawing2D.LineJoin]::Round
 $brush=New-Object Drawing.SolidBrush $color
 $g.DrawPath($pen,$path);$g.FillPath($brush,$path);$pen.Dispose();$brush.Dispose();$path.Dispose()
}
function Round($x,$y,$w,$h,$r){
 $p=New-Object Drawing.Drawing2D.GraphicsPath
 $d=$r*2
 $p.AddArc($x,$y,$d,$d,180,90);$p.AddArc(($x+$w-$d),$y,$d,$d,270,90)
 $p.AddArc(($x+$w-$d),($y+$h-$d),$d,$d,0,90);$p.AddArc($x,($y+$h-$d),$d,$d,90,90);$p.CloseFigure();return $p
}
function Panel($g,$x,$y,$w,$h,$color){
 $p=Round $x $y $w $h 14
 $rect=New-Object Drawing.Rectangle $x,$y,$w,$h
 $bottom=[Drawing.Color]::FromArgb([int]($color.R*.75),[int]($color.G*.78),[int]($color.B*.84))
 $fill=New-Object Drawing.Drawing2D.LinearGradientBrush $rect,$color,$bottom,90
 $shadow=New-Object Drawing.Pen ([Drawing.Color]::FromArgb(110,0,0,0)),9
 $edge=New-Object Drawing.Pen $ink,4
 $g.DrawPath($shadow,$p);$g.FillPath($fill,$p);$g.DrawPath($edge,$p)
 $shadow.Dispose();$edge.Dispose();$fill.Dispose();$p.Dispose()
}
function ImageCrop($g,$file,$src,$dst){
 $im=[Drawing.Image]::FromFile((Join-Path $root $file))
 $g.DrawImage($im,$dst,$src,[Drawing.GraphicsUnit]::Pixel);$im.Dispose()
}
function Coin($g,$x,$y){
 $brush=New-Object Drawing.SolidBrush $gold;$pen=New-Object Drawing.Pen $ink,3
 $g.FillEllipse($brush,$x,$y,36,36);$g.DrawEllipse($pen,$x,$y,36,36)
 DrawType $g '$' ($x+8) ($y+3) 26 $ink
 $pen.Dispose();$brush.Dispose()
}
$b=New-Object Drawing.Bitmap 2100,1570
$g=[Drawing.Graphics]::FromImage($b)
$g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([Drawing.Color]::FromArgb(20,25,36))
Label $g 'STEAL A TREASURE / UI REVIEW' 26 18 $cream $title
Label $g 'BEFORE: inspected Studio crops + labelled code reconstruction | AFTER: offline mockup, not a Studio capture' 28 66
Label $g 'Local Comic Sans Bold type proxy. Runtime uses FredokaOne. Reference images are promotional crops.' 28 95 ([Drawing.Color]::LightGray) $tiny
Label $g 'BEFORE / CURRENT EVIDENCE' 28 143 $gold
Label $g 'AFTER / IMPLEMENTED STYLE SPEC' 720 143 $gold
Label $g 'NAMED REFERENCE / OBSERVED' 1435 143 $gold
$shot='prototype/studio-pass-1/mcp-Roblox_Studio-blob-1792011318200-fq7kuh.jpg'
ImageCrop $g $shot (New-Object Drawing.Rectangle 0,145,245,132) (New-Object Drawing.Rectangle 30,195,490,264)
Label $g 'HUD / equal-weight lines; debug competes with reward' 30 475
Panel $g 735 215 320 100 $gold
Coin $g 750 245
DrawType $g 'Coins 0' 802 230 31
DrawType $g '0 Coins/s' 803 273 21
Panel $g 1135 216 205 62 $cyan
DrawType $g '<>  Index' 1150 230 26
Label $g 'Coin symbol + warm reward / cyan collection action' 735 348
Label $g 'Studio save status hidden unless Studio + ShowDebug' 735 379 ([Drawing.Color]::LightGray) $tiny
ImageCrop $g 'treasure/refs-topgames/_Adopt_Me_3.png' (New-Object Drawing.Rectangle 0,295,450,137) (New-Object Drawing.Rectangle 1445,215,610,186)
Label $g 'Adopt Me / broad, friendly letter silhouettes' 1445 423

ImageCrop $g $shot (New-Object Drawing.Rectangle 60,615,1390,205) (New-Object Drawing.Rectangle 30,625,650,96)
Label $g 'ACTION + OBJECTIVE / screen-wide flat rectangles' 30 825
Panel $g 810 590 450 67 $gold
DrawType $g '>  Enter [E / X]' 840 607 28
Panel $g 740 697 600 64 $panel
DrawType $g '>  Enter the central portal' 760 716 25
Label $g 'One action; compact objective; outlines + rounded edges' 735 790
Label $g 'Phone: 56 px action, 48 px objective; capped widths' 735 822 ([Drawing.Color]::LightGray) $tiny
ImageCrop $g 'treasure/refs-topgames/_Grow_a_Garden__4.png' (New-Object Drawing.Rectangle 0,0,768,120) (New-Object Drawing.Rectangle 1445,595,610,130)
Label $g 'Grow a Garden / outline survives bright scenery' 1445 755

Panel $g 30 927 650 355 ([Drawing.Color]::FromArgb(54,79,68))
Label $g 'TAG: source reconstruction (not a supplied pet shot)' 48 944 $cream $tiny
Label $g 'Pup' 290 1015 ([Drawing.Color]::White) $small
Label $g 'Common' 270 1046 ([Drawing.Color]::FromArgb(165,255,103)) $small
Label $g '+1 Coins/s' 259 1077 ([Drawing.Color]::White) $small
Label $g 'Fixed 200 x 84 box / tier branch never parents text' 45 1196
Label $g 'Route sign: unoutlined GothamBold on one face' 45 1233 ([Drawing.Color]::LightGray) $tiny
Panel $g 735 927 640 355 ([Drawing.Color]::FromArgb(54,79,68))
DrawType $g 'Pup' 956 964 37
DrawType $g '* Common' 916 1010 28 ([Drawing.Color]::FromArgb(165,255,103))
DrawType $g '$ +1 /s' 935 1047 27 $gold
Panel $g 866 1122 355 68 ([Drawing.Color]::FromArgb(133,82,43))
DrawType $g '>  CAMP' 929 1139 31
Label $g 'World-size label + pixel floor; range 90; pets occluded' 752 1211 $cream $tiny
Label $g 'Physical wooden signs / two-sided / route arrow' 752 1243 $cream $tiny
ImageCrop $g 'treasure/refs-topgames/_Steal_a_Brainrot_2.png' (New-Object Drawing.Rectangle 576,0,192,126) (New-Object Drawing.Rectangle 1470,950,560,367)
Label $g 'Steal a Brainrot / name, tier, income stack' 1445 1332
Label $g 'Font ID + exact game settings: UNKNOWN' 1445 1363 ([Drawing.Color]::LightGray) $tiny

Label $g 'CHECKED: post-S1 backup; 69 scripts compile O0/O1/O2; 63 unrelated sources and Workspace preserved.' 30 1420
Label $g 'STILL UNKNOWN: Roblox font rendering, phone/gamepad focus, hold feedback, occlusion and all 8 live suites after UI.' 30 1456 ([Drawing.Color]::LightGray)
Label $g 'No quality score or top-game parity claimed. Compare in Studio at 390x844 + 844x390 before visual acceptance.' 30 1492 ([Drawing.Color]::LightGray) $tiny
$b.Save((Join-Path $root 'treasure/UI-SBS.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$b.Dispose();$family.Dispose()
