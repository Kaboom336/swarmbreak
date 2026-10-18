Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$groups = @{
 'evidence-live' = @(Get-ChildItem "$root/sections" -Recurse -File | Where-Object {$_.Name -like 'studio-*.jpg'})
 'evidence-offline' = @((Get-ChildItem "$root/visual-simplify" -File | Where-Object {$_.Name -like 'after-*.png' -or $_.Name -like 'deliver-*.png'})) + @(Get-ChildItem "$root/sections" -Recurse -File | Where-Object {$_.Name -like 'after*.png' -and $_.Name -notlike '*mask*'})
 'evidence-official' = @(Get-ChildItem "$root/refs-topgames" -File -Filter '*.png')
}
foreach($key in $groups.Keys) {
 $files = @($groups[$key]); $cols=4; $w=400; $h=248; $rows=[Math]::Ceiling($files.Count/$cols)
 $bmp = New-Object Drawing.Bitmap ($cols*$w),($rows*$h)
 $g=[Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::FromArgb(25,30,35)); $font=New-Object Drawing.Font 'Arial',10
 for($i=0;$i -lt $files.Count;$i++){
  $im=[Drawing.Image]::FromFile($files[$i].FullName); $x=($i%$cols)*$w; $y=[Math]::Floor($i/$cols)*$h
  $g.DrawImage($im,[int]$x,[int]$y,$w,225); $g.DrawString(($files[$i].Directory.Name+'/'+$files[$i].Name),$font,[Drawing.Brushes]::White,$x,($y+226)); $im.Dispose()
 }
 $bmp.Save("$PSScriptRoot/$key.jpg",[Drawing.Imaging.ImageFormat]::Jpeg); $g.Dispose(); $bmp.Dispose(); $font.Dispose()
 Write-Output "$key : $($files.Count) images"
}
