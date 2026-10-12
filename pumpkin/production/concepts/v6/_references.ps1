$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$font=New-Object System.Drawing.Font('Arial',24,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
foreach($f in Get-ChildItem $PSScriptRoot -Filter '*.png'){
 $ours=[System.Drawing.Image]::FromFile($f.FullName)
 $old=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ('../v5/'+$f.BaseName+'-cmp.jpg')))
 $b=New-Object System.Drawing.Bitmap($old.Width,$old.Height);$g=[System.Drawing.Graphics]::FromImage($b)
 $g.DrawImage($old,0,0,$old.Width,$old.Height)
 $g.FillRectangle([System.Drawing.Brushes]::Black,0,0,$old.Width,768)
 $g.DrawString(('v6 | '+$f.BaseName+' | supplied JUDGE5 references below'),$font,[System.Drawing.Brushes]::White,650,8)
 $scale=[Math]::Min(1280/[double]$ours.Width,720/[double]$ours.Height)
 $w=[int]($ours.Width*$scale);$h=[int]($ours.Height*$scale)
 $g.DrawImage($ours,[int](($old.Width-$w)/2),[int](48+(720-$h)/2),$w,$h)
 $b.Save((Join-Path $PSScriptRoot ($f.BaseName+'-refs-review.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $g.Dispose();$b.Dispose();$ours.Dispose();$old.Dispose()
}
$font.Dispose()
