param([switch]$Variants, [string]$AnimRoot=$PSScriptRoot)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$dir=Join-Path $AnimRoot 'preview'
if ($Variants) { $dir=Join-Path $dir 'variants-v3' }
$data=Get-Content (Join-Path $AnimRoot $(if($Variants){'variants-v3.json'}else{'clips.json'})) -Raw | ConvertFrom-Json
$names=@($data.clips.PSObject.Properties.Name)
$font=New-Object Drawing.Font('Segoe UI',14)
$sheet=New-Object Drawing.Bitmap(1792,($names.Count*290))
$sg=[Drawing.Graphics]::FromImage($sheet)
$sg.Clear([Drawing.Color]::White)
foreach($name in $names) {
    $row=[array]::IndexOf($names,$name)
    $strip=New-Object Drawing.Bitmap(1792,290)
    $g=[Drawing.Graphics]::FromImage($strip);$g.Clear([Drawing.Color]::White)
    $g.DrawString($name,$font,[Drawing.Brushes]::Black,5,3)
    for($i=0;$i -lt 7;$i++) {
        $im=[Drawing.Image]::FromFile((Join-Path $dir ('{0}-{1:d2}.png' -f $name,$i)))
        $g.DrawImage($im,$i*256,30,256,256);$im.Dispose()
    }
    $g.Dispose();$strip.Save((Join-Path $dir ($name+'-strip.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg)
    $sg.DrawImage($strip,0,$row*290);$strip.Dispose()
    if(-not $Variants) {
        $ff=Join-Path $AnimRoot '../../../concepts/refs3/_tools/ffmpeg.exe'
        $count=[Math]::Max(16,[Math]::Round($data.clips.$name.duration*16))
        & $ff -y -loglevel error -framerate 16 -i (Join-Path $dir ($name+'-motion-%02d.png')) -vf 'split[a][b];[a]palettegen[p];[b][p]paletteuse' -frames:v $count -loop 0 (Join-Path $dir ($name+'.gif'))
        if($LASTEXITCODE -ne 0){throw "GIF generation failed: $name"}
    }
}
$sg.Dispose();$sheet.Save((Join-Path $dir $(if($Variants){'_pairs.jpg'}else{'_sheet-v3.jpg'})),[Drawing.Imaging.ImageFormat]::Jpeg)
$sheet.Dispose();$font.Dispose()
if(-not $Variants) {
    $motionNames=@('idle','chase','lob','fan','slam')
    $timeline=New-Object Drawing.Bitmap(2048,870)
    $tg=[Drawing.Graphics]::FromImage($timeline);$tg.Clear([Drawing.Color]::White)
    $tf=New-Object Drawing.Font('Segoe UI',12)
    foreach($name in $motionNames) {
        $row=[array]::IndexOf($motionNames,$name);$clip=$data.clips.$name
        $count=[Math]::Max(16,[Math]::Round($clip.duration*16))
        $tg.DrawString(($name+' / ordered motion samples'),$tf,[Drawing.Brushes]::Black,4,($row*174))
        for($i=0;$i -lt 16;$i++) {
            $idx=[int][Math]::Round(($count-1)*$i/15)
            $im=[Drawing.Image]::FromFile((Join-Path $dir ('{0}-motion-{1:d2}.png' -f $name,$idx)))
            $tg.DrawImage($im,($i*128),($row*174+22),128,128);$im.Dispose()
            $denom=if($clip.loop){$count}else{$count-1}
            $tg.DrawString(('{0:0.00}s' -f ($clip.duration*$idx/$denom)),$tf,[Drawing.Brushes]::Black,($i*128+3),($row*174+152))
        }
    }
    $tg.Dispose();$timeline.Save((Join-Path $dir '_motion-v3.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
    $timeline.Dispose();$tf.Dispose()
    # Schematic top-down tells paired with real approved-mesh windup renders.
    $story=New-Object Drawing.Bitmap(1200,960)
    $g=[Drawing.Graphics]::FromImage($story);$g.Clear([Drawing.Color]::FromArgb(242,244,239))
    $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $title=New-Object Drawing.Font('Segoe UI',22)
    $font=New-Object Drawing.Font('Segoe UI',15)
    $small=New-Object Drawing.Font('Segoe UI',12)
    $red=New-Object Drawing.Pen([Drawing.Color]::FromArgb(234,45,50),5)
    $amber=New-Object Drawing.Pen([Drawing.Color]::FromArgb(213,136,0),5)
    $blue=New-Object Drawing.Pen([Drawing.Color]::FromArgb(20,117,171),5)
    $blue.EndCap=[Drawing.Drawing2D.LineCap]::ArrowAnchor
    $g.DrawString('MEADOW KEEPER / ATTACK STORYBOARD',$title,[Drawing.Brushes]::Black,20,12)
    $g.DrawString('Authored mesh + schematic tells. Studio rendering and balance UNTESTED.',$small,[Drawing.Brushes]::Black,22,51)
    $kinds=@('lob','fan','slam')
    for($row=0;$row -lt 3;$row++) {
        $y=82+$row*290;$kind=$kinds[$row]
        $g.DrawString($kind.ToUpper(),$font,[Drawing.Brushes]::Black,22,$y)
        $idx=if($kind -eq 'slam'){3}else{2}
        $im=[Drawing.Image]::FromFile((Join-Path $dir ('{0}-{1:d2}.png' -f $kind,$idx)))
        $g.DrawImage($im,22,($y+28),244,244);$im.Dispose()
        $cx=455;$cy=$y+145
        if($kind -eq 'lob') {
            $g.DrawEllipse($red,($cx-80),($cy-80),160,160)
            $g.FillEllipse([Drawing.Brushes]::Black,($cx-6),($cy-6),12,12)
            $g.DrawLine($blue,($cx+15),$cy,($cx+126),($cy-35))
            $text="BIG LOB / 8-stud red landing ring`nAim fixed at tell start; release 0.62s`nImpact 1.52s / 4-stud boulder`nLeave ring; cover stops flight/splash`nGroups knock-drop together"
        } elseif($kind -eq 'fan') {
            foreach($dx in @(-70,0,70)) { $g.DrawLine($red,$cx,($cy+85),($cx+$dx),($cy-85)) }
            $g.FillEllipse([Drawing.Brushes]::Black,($cx-6),($cy-70),12,12)
            $g.DrawLine($blue,($cx+5),($cy-55),($cx+85),($cy-15))
            $text="3 ACORNS / three red flight lanes`nVelocity lead locked; fan +/-16 degrees`nRelease 0.62s / flight 0.70s`nReverse or weave between lanes`nCover stops each acorn independently"
        } else {
            $g.DrawEllipse($amber,($cx-100),($cy-100),200,200)
            $g.DrawEllipse($amber,($cx-50),($cy-50),100,100)
            $g.FillEllipse([Drawing.Brushes]::Black,($cx-6),($cy-6),12,12)
            $g.DrawLine($blue,($cx+105),($cy+20),($cx+105),($cy-70))
            $text="GROUND SLAM / amber expanding rim`nCrouch -> jump -> land at 0.80s`nWave grows at 24 studs/s to 22 studs`nJump above rim as it reaches you`nOnly rim hits; not the filled circle"
        }
        $g.DrawString($text,$font,[Drawing.Brushes]::Black,640,($y+40))
        $g.DrawLine([Drawing.Pens]::Gray,20,($y+277),1180,($y+277))
    }
    $g.Dispose();$story.Save((Join-Path $dir 'ATTACK-storyboard.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
    $story.Dispose();$title.Dispose();$font.Dispose();$small.Dispose();$red.Dispose();$amber.Dispose();$blue.Dispose()
}
