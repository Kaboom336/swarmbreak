Add-Type -AssemblyName System.Drawing
$taskRoot = $PSScriptRoot
if (-not $taskRoot) { $taskRoot = Join-Path (Get-Location) 'treasure/cave-v1' }
$ErrorActionPreference = 'Stop'
$sheet = New-Object System.Drawing.Bitmap 2700,2140
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::FromArgb(15,23,35))
$white = [System.Drawing.Brushes]::White
$gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,202,87))
$muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(186,203,221))
$head = New-Object System.Drawing.Font 'Arial',36,([System.Drawing.FontStyle]::Bold)
$body = New-Object System.Drawing.Font 'Arial',24
$g.DrawString('CRYSTAL CAVE / THREE LAYOUTS / ONE NEW MECHANIC EACH',$head,$white,40,20)
$g.DrawString('Generated concepts / 4-8 players / 60s deadline / 16 studs per second / no hide spots',$body,$muted,42,85)
$labels = @('A  LANTERN CRESCENT','B  FRACTURE CATHEDRAL / PICK','C  SWITCHYARD MESA')
$subs = @('Light pulse / main 34.0s EST.','Shattering bridge / main 32.9s EST.','Minecart / main 34.8s EST.')
function Fit($file,$x,$y,$w,$h) {
 $img = [System.Drawing.Image]::FromFile((Join-Path $taskRoot $file))
 $scale = [Math]::Min($w/$img.Width,$h/$img.Height)
 $dw = [int]($img.Width*$scale); $dh = [int]($img.Height*$scale)
 $g.DrawImage($img,[int]($x+($w-$dw)/2),[int]($y+($h-$dh)/2),$dw,$dh)
 $img.Dispose()
}
for($i=0;$i -lt 3;$i++) {
 $x=40+$i*880
 $brush=$white
 if($i -eq 1){$brush=$gold}
 $g.DrawString($labels[$i],$body,$brush,$x,150)
 $g.DrawString($subs[$i],$body,$muted,$x,192)
 $letter=[char](65+$i)
 Fit "$letter-blueprint-overhead.png" $x 245 850 850
 Fit "$letter-concept.png" $x 1120 850 850
}
$g.DrawString('JUDGE: B. Strongest rock mass + visible bridge risk + permanent walking flanks.',$body,$gold,42,2010)
$g.DrawString('Route arithmetic, not playtests. CAVE-V1.md / ROUTES.json govern construction; images are illustrative.',$body,$muted,42,2060)
$g.Dispose()
$sheet.Save((Join-Path $taskRoot '_sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$sheet.Dispose(); $head.Dispose(); $body.Dispose(); $gold.Dispose(); $muted.Dispose()
