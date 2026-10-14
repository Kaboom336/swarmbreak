param([string]$AnimRoot=$PSScriptRoot)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$dir=Join-Path $AnimRoot 'preview/fx'
$ff=Join-Path $AnimRoot '../../../concepts/refs3/_tools/ffmpeg.exe'
$names=@('lob','fan','slam','dash','warn')
$ids=@('C','E','A','D','B')
$times=@(@(5,8,17,24,29),@(5,8,15,20,24),@(3,6,10,13,24),@(3,6,10,14,22),@(3,6,10,17,23))
$sheet=New-Object Drawing.Bitmap(1920,1540)
$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(239,239,227))
$font=New-Object Drawing.Font('Segoe UI',16)
$small=New-Object Drawing.Font('Segoe UI',11)
$g.DrawString('MEADOW KEEPER / ATTACK STORYBOARD v2',$font,[Drawing.Brushes]::Black,12,8)
$g.DrawString('Left: prior poses. Right: FX tell / release / impact. Offline approximation; audio + Studio UNKNOWN.',$small,[Drawing.Brushes]::Black,12,38)
for($row=0;$row -lt $names.Count;$row++) {
    $name=$names[$row];$y=66+$row*292
    & $ff -y -loglevel error -framerate 16 -i (Join-Path $dir ($name+'-%03d.png')) -vf 'split[a][b];[a]palettegen[p];[b][p]paletteuse' -loop 0 (Join-Path $dir ($name+'.gif'))
    if($LASTEXITCODE -ne 0){throw "GIF failed: $name"}
    $strip=New-Object Drawing.Bitmap(2400,396);$sg=[Drawing.Graphics]::FromImage($strip);$sg.Clear([Drawing.Color]::White)
    $sg.DrawString(('CLIP '+$ids[$row]+' / chronological samples / offline FX approximation'),$font,[Drawing.Brushes]::Black,5,3)
    for($i=0;$i -lt 5;$i++) {
        $im=[Drawing.Image]::FromFile((Join-Path $dir ('{0}-{1:d3}.png' -f $name,$times[$row][$i])))
        $sg.DrawImage($im,($i*480),36,480,360);$im.Dispose()
    }
    $sg.Dispose();$strip.Save((Join-Path $dir ('blind-'+$ids[$row]+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$strip.Dispose()
    $g.DrawString(($name.ToUpper()+' / before -> tell -> release -> impact'),$font,[Drawing.Brushes]::Black,12,$y)
    $prior=Join-Path $AnimRoot ('preview/'+$(if($name -eq 'dash'){'chase'}else{$name})+'-02.png')
    $im=[Drawing.Image]::FromFile($prior);$g.DrawImage($im,12,($y+32),270,250);$im.Dispose()
    for($col=0;$col -lt 3;$col++) {
        $idx=$times[$row][@(1,2,4)[$col]]
        $im=[Drawing.Image]::FromFile((Join-Path $dir ('{0}-{1:d3}.png' -f $name,$idx)))
        $g.DrawImage($im,(310+$col*530),($y+32),510,250);$im.Dispose()
    }
}
$g.Dispose();$sheet.Save((Join-Path $AnimRoot 'preview/ATTACK-storyboard-v2.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$sheet.Dispose();$font.Dispose();$small.Dispose()
Write-Output 'Generated five effect GIFs, five blind strips and before/after storyboard.'
