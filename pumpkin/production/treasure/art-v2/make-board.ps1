Add-Type -AssemblyName System.Drawing
$dir=$PSScriptRoot
function Draw-Contained($g,$path,$x,$y,$w,$h) {
 $im=[System.Drawing.Image]::FromFile($path)
 try {$s=[Math]::Min($w/$im.Width,$h/$im.Height);$dw=[int]($im.Width*$s);$dh=[int]($im.Height*$s);$g.DrawImage($im,[int]($x+($w-$dw)/2),[int]($y+($h-$dh)/2),$dw,$dh)} finally {$im.Dispose()}
}
$names=@('01-hub-hideout','02-heist-board','03-roll-up-vault','04-kings-bed','05-guardian-turnaround','06-treasure-toys','07-hud')
$labels=@('HUB / HIDEOUT','HEIST BOARD','ROLL UP THE VAULT',"KING'S BED",'GUARDIAN: FRONT / SIDE / BACK','TREASURE TOYS','HUD: HAUL / TIMER / HEIST')
$refs=@('Pet Simulator 99','Pet Simulator 99','Steal an Egg','Steal an Egg','Steal an Egg','Grow a Garden','Pet Simulator 99')
$scores=@('7.8 BELOW BAR','8.2','8.0','8.2','7.6 BELOW BAR','8.0','8.2')
$font=New-Object System.Drawing.Font('Arial',18,[System.Drawing.FontStyle]::Bold)
$small=New-Object System.Drawing.Font('Arial',14)
$ink=[System.Drawing.Brushes]::White
$board=New-Object System.Drawing.Bitmap(1800,2250)
$g=[System.Drawing.Graphics]::FromImage($board)
$g.Clear([System.Drawing.ColorTranslator]::FromHtml('#182B49'))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawString('STEAL A TREASURE / ART V2 / 2D CONCEPTS',$font,$ink,30,18)
for($i=0;$i -lt 7;$i++){
 $x=30+($i%2)*885;$y=70+[Math]::Floor($i/2)*530
 $g.DrawString($labels[$i],$font,$ink,$x,$y)
 $g.DrawString(('Reference: '+$refs[$i]+' | AI score '+$scores[$i]),$small,$ink,$x,($y+29))
 Draw-Contained $g (Join-Path $dir ($names[$i]+'.png')) $x ($y+60) 855 455
}
$g.DrawString('CUTE CHUNKY TOY HEISTS',$font,$ink,915,1680)
$g.DrawString('Gold treasure / cream routes / teal walls',$small,$ink,915,1720)
$g.DrawString('Daytime. Oversized joke. Clear player view.',$small,$ink,915,1750)
$g.DrawString('Concept art only. Zion owns all testing.',$small,$ink,915,1780)
$swatches=@('#FFF1D1','#167D9A','#182B49','#FF665E','#FFD34E','#33BEF7','#62B04E','#48DFFF')
for($i=0;$i -lt $swatches.Count;$i++){
 $b=New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($swatches[$i]))
 $x=920+($i%4)*200;$y=1830+[Math]::Floor($i/4)*95
 $g.FillRectangle($b,$x,$y,160,52);$b.Dispose();$g.DrawString($swatches[$i],$small,$ink,$x,($y+57))
}
$g.DrawString('Reference charts / runtime / phone performance: UNVERIFIED',$small,$ink,30,2220)
$board.Save((Join-Path $dir 'BOARD.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$board.Dispose()
$root='C:\dev\codex-lab\refs\videos'
$refPaths=@('pet-sim-99-frames\f_012s.png','pet-sim-99-frames\farm_tile.png','sae-new-frames\h_1034.jpg','sae-new-frames\h_1034.jpg','sae-new-frames\h_1034.jpg','grow-a-garden-frames\g_820s.png','pet-sim-99-frames\crop_lefthud.png')
$comparison=New-Object System.Drawing.Bitmap(1600,3480)
$g=[System.Drawing.Graphics]::FromImage($comparison)
$g.Clear([System.Drawing.ColorTranslator]::FromHtml('#182B49'))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawString('LOCAL GAMEPLAY REFERENCE / OUR GENERATED CONCEPT',$font,$ink,25,16)
for($i=0;$i -lt 7;$i++){
 $y=60+$i*485;$g.DrawString(($refs[$i]+' | '+$labels[$i]),$font,$ink,25,$y)
 Draw-Contained $g (Join-Path $root $refPaths[$i]) 25 ($y+40) 650 420
 Draw-Contained $g (Join-Path $dir ($names[$i]+'.png')) 700 ($y+40) 875 420
}
$comparison.Save((Join-Path $dir 'REFERENCE-COMPARE.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$comparison.Dispose();$font.Dispose();$small.Dispose()
Get-ChildItem $dir -File | Where-Object Extension -In '.png','.jpg' | Select-Object Name,Length

