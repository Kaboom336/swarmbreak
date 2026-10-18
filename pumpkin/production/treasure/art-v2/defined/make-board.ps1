param([switch]$CopyImages)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$dir=$PSScriptRoot
$generated='C:/Users/zerha/.codex/generated_images/01a15061-e670-7392-aa39-1055799a98af'
$names=@('01-hub-hideout','02-guardian-states','03-roll-up-vault-buildable','04-baron-turnaround')
$initial=@('exec-5766b734-b70f-4be0-98f2-accc84e9b81d.png','exec-4134ea53-7968-4118-bfe1-e05c2429ab37.png','exec-7623b15e-e2f1-48bb-813d-5e93b44c21fc.png','exec-f809c649-2078-491e-bab1-7f8d7dde6d31.png')
$redraw=@('exec-6625c266-28be-4502-81f3-c446f44467e3.png','exec-07a67a5b-594b-40ce-b258-5097ebfa7d98.png','exec-99ea14b6-0ef3-4eec-b7ee-8adfff943a6c.png','exec-591babcf-5426-47c4-addc-3c86580217bb.png')
$selected=@('exec-0a4fb9a3-3bec-4b4d-ba83-434b557d69bf.png','exec-2cd2384d-45dd-4eda-b328-5fe678869d78.png','exec-01d0b237-8640-440b-8d1f-4509aee3625b.png','exec-83cfb47b-cd14-4f1c-b4c3-44197c2c57f5.png')
if($CopyImages){
 $attempt=Join-Path $dir 'attempt-1'
 New-Item -ItemType Directory -Path $attempt -Force | Out-Null
 $second=Join-Path $dir 'attempt-2'
 New-Item -ItemType Directory -Path $second -Force | Out-Null
 for($i=0;$i -lt 4;$i++){
  Copy-Item -LiteralPath (Join-Path $generated $initial[$i]) -Destination (Join-Path $attempt ($names[$i]+'.png'))
  Copy-Item -LiteralPath (Join-Path $generated $redraw[$i]) -Destination (Join-Path $second ($names[$i]+'.png'))
  Copy-Item -LiteralPath (Join-Path $generated $selected[$i]) -Destination (Join-Path $dir ($names[$i]+'.png'))
 }
}
function Draw-Contained($g,$path,$x,$y,$w,$h){
 $im=[System.Drawing.Image]::FromFile($path)
 try{
  $s=[Math]::Min($w/$im.Width,$h/$im.Height)
  $dw=[int]($im.Width*$s);$dh=[int]($im.Height*$s)
  $g.DrawImage($im,[int]($x+($w-$dw)/2),[int]($y+($h-$dh)/2),$dw,$dh)
 }finally{$im.Dispose()}
}
$font=New-Object System.Drawing.Font('Arial',22,[System.Drawing.FontStyle]::Bold)
$small=New-Object System.Drawing.Font('Arial',16)
$ink=[System.Drawing.Brushes]::White
$labels=@('HIDEOUT / BREAK-IN STATION','BARON / POSE + GAMEPLAY STATES','ROLL UP THE VAULT / KIT VIEW','BARON / PROPORTION TARGETS')
$refs=@('Pet Simulator 99','Steal an Egg','Steal an Egg','Steal an Egg / guardian scale')
$board=New-Object System.Drawing.Bitmap(2000,1400)
$g=[System.Drawing.Graphics]::FromImage($board)
try{
 $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#182B49'))
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.DrawString('STEAL A TREASURE / ART V2 DEFINED',$font,$ink,30,20)
 $g.DrawString('2D build targets | 3 sheets BELOW 8 target | written dimensions control the build | CRITIC.md',$small,$ink,30,62)
 for($i=0;$i -lt 4;$i++){
  $x=30+($i%2)*985;$y=110+[Math]::Floor($i/2)*570
  $g.DrawString($labels[$i],$font,$ink,$x,$y)
  $g.DrawString(('Reference: '+$refs[$i]),$small,$ink,$x,($y+33))
  $scoreLabels=@('7.7 BELOW TARGET','8.1','7.8 BELOW TARGET','7.8 BELOW TARGET')
  $g.DrawString(('AI '+$scoreLabels[$i]),$small,$ink,($x+665),($y+33))
  Draw-Contained $g (Join-Path $dir ($names[$i]+'.png')) $x ($y+65) 955 490
 }
 $swatches=@('#FFF1D1','#167D9A','#182B49','#FFD34E','#FF665E','#48DFFF','#FFC58F')
 for($i=0;$i -lt $swatches.Count;$i++){
  $x=35+$i*240
  $b=New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($swatches[$i]))
  $g.FillRectangle($b,$x,1265,200,45);$b.Dispose()
  $g.DrawString($swatches[$i],$small,$ink,$x,1315)
 }
 $g.DrawString('No 3D/place edits or Studio Play. Runtime, device performance and fun: UNKNOWN.',$small,$ink,30,1360)
 $board.Save((Join-Path $dir 'BOARD.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
}finally{$g.Dispose();$board.Dispose()}
$refRoot='C:/dev/codex-lab/refs/videos'
$refPaths=@('pet-sim-99-frames/f_012s.png','sae-new-frames/h_1034.jpg','sae-new-frames/h_1034.jpg','sae-new-frames/h_1034.jpg')
$comparison=New-Object System.Drawing.Bitmap(2000,2160)
$g=[System.Drawing.Graphics]::FromImage($comparison)
try{
 $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#182B49'))
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.DrawString('LOCAL GAMEPLAY EVIDENCE / GENERATED CONSTRUCTION TARGET',$font,$ink,25,20)
 for($i=0;$i -lt 4;$i++){
  $y=75+$i*500
  $g.DrawString(($refs[$i]+' / '+$labels[$i]),$font,$ink,25,$y)
  Draw-Contained $g (Join-Path $refRoot $refPaths[$i]) 25 ($y+45) 875 435
  Draw-Contained $g (Join-Path $dir ($names[$i]+'.png')) 935 ($y+45) 1040 435
 }
 $g.DrawString('Named local benchmarks; not current chart rankings. Images do not verify physics or model dimensions.',$small,$ink,25,2110)
 $comparison.Save((Join-Path $dir 'REFERENCE-COMPARE.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
}finally{$g.Dispose();$comparison.Dispose();$font.Dispose();$small.Dispose()}
$manifest=foreach($name in $names){
 $path=Join-Path $dir ($name+'.png')
 $im=[System.Drawing.Image]::FromFile($path)
 try{[pscustomobject]@{name=$name+'.png';width=$im.Width;height=$im.Height;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}}finally{$im.Dispose()}
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dir 'FILES.json') -Encoding UTF8
$summaryPath=Join-Path (Split-Path (Split-Path $dir)) 'ART-V2-BUILD-SUMMARY.md'
if(Test-Path -LiteralPath $summaryPath){
 $lines=(Get-Content -LiteralPath $summaryPath).Count
 if($lines -gt 15){throw 'Phone summary exceeds 15 lines'}
}
Get-ChildItem -LiteralPath $dir -File | Select-Object Name,Length

