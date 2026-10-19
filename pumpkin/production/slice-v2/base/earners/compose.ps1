param([string]$Tag='final')
Add-Type -AssemblyName System.Drawing
$root=$PSScriptRoot
$source=[Drawing.Image]::FromFile('C:/dev/codex-lab/refs/videos/steal-a-brainrot-frames/f_008s.png')
$crop=New-Object Drawing.Bitmap 300,330
$g=[Drawing.Graphics]::FromImage($crop)
$g.InterpolationMode='NearestNeighbor'
$g.DrawImage($source,[Drawing.Rectangle]::new(0,0,300,330),[Drawing.Rectangle]::new(135,130,115,126),[Drawing.GraphicsUnit]::Pixel)
$crop.Save((Join-Path $root 'reference-crop.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $source.Dispose()
$canvas=New-Object Drawing.Bitmap 1600,720
$g=[Drawing.Graphics]::FromImage($canvas); $g.Clear([Drawing.Color]::FromArgb(23,27,34))
$font=[Drawing.Font]::new('Arial',19,[Drawing.FontStyle]::Bold)
$small=[Drawing.Font]::new('Arial',12)
$g.DrawString('STEAL A BRAINROT  |  COPPER COMPASS: ONE-EARNER CHECK',$font,[Drawing.Brushes]::White,24,18)
$g.DrawString('REFERENCE: Ta Ta Ta Sahur',$small,[Drawing.Brushes]::White,25,78)
$g.DrawImage($crop,25,125,300,330)
$g.DrawString('Pedestal, supplied 00:08 frame',$small,[Drawing.Brushes]::LightGray,25,475)
$g.DrawString('Camera match estimated from image',$small,[Drawing.Brushes]::LightGray,25,500)
$names=@('normal','gold','diamond')
for($i=0;$i -lt 3;$i++) {
  $x=370+$i*405
  $img=[Drawing.Image]::FromFile((Join-Path $root "$Tag-$($names[$i]).png"))
  $g.DrawString($names[$i].ToUpper(),$font,[Drawing.Brushes]::White,$x,78)
  $g.DrawImage($img,[Drawing.Rectangle]::new($x,120,390,390),[Drawing.Rectangle]::new(170,190,390,390),[Drawing.GraphicsUnit]::Pixel); $img.Dispose()
}
$g.DrawString('Same voxel grid | 0.5-stud cells | anchored parts | offline Blender proof',$small,[Drawing.Brushes]::LightGray,370,550)
$g.DrawString('Diamond: cyan neon needle. Studs approximated offline. Engine appearance and walk: NOT RUN.',$small,[Drawing.Brushes]::LightGray,370,580)
$g.DrawString('Reference is supplied gameplay evidence; renders are not Roblox screenshots.',$small,[Drawing.Brushes]::LightGray,370,610)
$file=if($Tag -eq 'final'){'SBS-copper-compass.jpg'}else{"SBS-$Tag.jpg"}
$canvas.Save((Join-Path $root $file),[Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $canvas.Dispose(); $crop.Dispose(); $font.Dispose(); $small.Dispose()
