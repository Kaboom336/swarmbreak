param([switch]$Blind,[string]$Lob='R',[string]$Fan='M')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=$PSScriptRoot
$dir=Join-Path $root $(if($Blind){'preview/throw-blind'}else{'preview/fx'})
$ff=Join-Path $root '../../../concepts/refs3/_tools/ffmpeg.exe'
$ids=if($Blind){@('K','M','R','T')}else{@('lob','fan')}
$font=New-Object Drawing.Font('Segoe UI',16)
$small=New-Object Drawing.Font('Segoe UI',12)
$labels=@('Rear load','Opposite-foot stride','Elbow leads','Release 0.620s','Across / rear drag','Recover')
foreach($id in $ids){
    & $ff -y -loglevel error -framerate 30 -i (Join-Path $dir ($id+'-%03d.png')) -vf 'split[a][b];[a]palettegen[p];[b][p]paletteuse' -loop 0 (Join-Path $dir ($id+'.gif'))
    if($LASTEXITCODE -ne 0){throw "GIF failed $id"}
    $strip=New-Object Drawing.Bitmap(2520,355);$g=[Drawing.Graphics]::FromImage($strip);$g.Clear([Drawing.Color]::White)
    $g.DrawString(('Candidate '+$id+' / exact chronological poses / offline'),$font,[Drawing.Brushes]::Black,5,4)
    for($i=0;$i -lt 6;$i++){
        $im=[Drawing.Image]::FromFile((Join-Path $dir ('{0}-pose-{1:d2}.png' -f $id,$i)))
        $g.DrawImage($im,$i*420,30,420,300);$im.Dispose()
        $g.DrawString($labels[$i],$small,[Drawing.Brushes]::Black,($i*420+5),333)
    }
    $g.Dispose();$strip.Save((Join-Path $dir ($id+'-strip.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$strip.Dispose()
    # Chronological contact sheet exposes the continuous GIF's actual 30 fps samples.
    $sheet=New-Object Drawing.Bitmap(1920,780);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::White)
    $g.DrawString(('Candidate '+$id+' / regular motion samples; temporal order left to right, then down'),$font,[Drawing.Brushes]::Black,5,5)
    for($i=0;$i -lt 16;$i++){
        $idx=[int][Math]::Round($i*33/15)
        $im=[Drawing.Image]::FromFile((Join-Path $dir ('{0}-{1:d3}.png' -f $id,$idx)))
        $x=($i%8)*240;$y=35+[Math]::Floor($i/8)*370
        $g.DrawImage($im,$x,$y,240,340);$im.Dispose()
        $g.DrawString(('{0:F3}s' -f ($idx/30)),$small,[Drawing.Brushes]::Black,($x+5),($y+340))
    }
    $g.Dispose();$sheet.Save((Join-Path $dir ($id+'-motion.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
}
if(-not $Blind){
    $canvas=New-Object Drawing.Bitmap(2520,1210);$g=[Drawing.Graphics]::FromImage($canvas);$g.Clear([Drawing.Color]::FromArgb(244,243,232))
    $pen=New-Object Drawing.Pen([Drawing.Color]::FromArgb(35,54,53),5)
    $red=New-Object Drawing.Pen([Drawing.Color]::FromArgb(210,93,45),5)
    $g.DrawString('THROW MECHANICS / original real-motion knowledge sketches vs articulated Keeper',$font,[Drawing.Brushes]::Black,8,7)
    $g.DrawString('Reference sketches are schematic, not traced video. Target points right. Orange: throwing arm. Runtime / owner acceptance UNKNOWN.',$small,[Drawing.Brushes]::Black,8,35)
    for($row=0;$row -lt 2;$row++){
        $baseY=65+$row*560
        $g.DrawString($(if($row -eq 0){'HEAVY TWO-HAND OVERHEAD / baseball weight-transfer principle adapted to a heavy heave'}else{'QUICK ONE-HAND SIDEARM / hips then chest, elbow then hand'}),$font,[Drawing.Brushes]::Black,8,$baseY)
        for($i=0;$i -lt 6;$i++){
            $x=$i*420+80;$y=$baseY+48
            # Six deliberately different silhouettes: rear load -> planted lead -> release -> fold.
            $hipX=@(80,100,110,135,150,100)[$i];$hipY=@(125,122,110,100,115,112)[$i]
            $chestX=@(66,88,105,144,174,102)[$i];$chestY=@(65,62,58,48,66,55)[$i]
            $g.DrawLine($pen,($x+$hipX),($y+$hipY),($x+$chestX),($y+$chestY))
            $g.DrawEllipse($pen,($x+$chestX-12),($y+$chestY-29),25,25)
            $g.DrawLine($pen,($x+$chestX+14),($y+$chestY-14),($x+$chestX+24),($y+$chestY-14))
            $lead=@(112,175,188,198,203,142)[$i];$rear=@(47,55,68,95,140,63)[$i]
            $g.DrawLine($pen,($x+$hipX),($y+$hipY),($x+$lead-15),($y+155));$g.DrawLine($pen,($x+$lead-15),($y+155),($x+$lead),($y+190))
            $g.DrawLine($pen,($x+$hipX),($y+$hipY),($x+$rear+15),($y+156));$g.DrawLine($pen,($x+$rear+15),($y+156),($x+$rear),($y+$(if($i -in @(3,4)){171}else{190})))
            $g.DrawLine($pen,$x,($y+195),($x+255),($y+195))
            if($row -eq 0){$elbowX=@(35,47,145,191,184,60)[$i];$elbowY=@(108,42,12,9,87,103)[$i];$handX=@(82,100,139,219,206,103)[$i];$handY=@(93,17,-8,-5,115,110)[$i]}
            else{$elbowX=@(35,34,158,190,145,65)[$i];$elbowY=@(85,70,67,58,97,107)[$i];$handX=@(31,15,75,233,111,74)[$i];$handY=@(115,92,83,61,139,123)[$i]}
            $g.DrawLine($red,($x+$chestX),($y+$chestY),($x+$elbowX),($y+$elbowY));$g.DrawLine($red,($x+$elbowX),($y+$elbowY),($x+$handX),($y+$handY))
            $supportX=if($i -lt 2){200}else{($chestX+12)};$supportY=if($i -lt 2){64}else{($chestY+45)}
            if(-not ($row -eq 0 -and $i -in @(1,2,3))){
                $g.DrawLine($pen,($x+$chestX),($y+$chestY),($x+$supportX),($y+$supportY))
            }
            if($row -eq 0 -and $i -in @(1,2,3)){
                $g.DrawLine($pen,($x+$chestX+8),($y+$chestY+3),($x+$elbowX+8),($y+$elbowY+6))
                $g.DrawLine($pen,($x+$elbowX+8),($y+$elbowY+6),($x+$handX+6),($y+$handY+3))
            }
            $g.DrawString($labels[$i],$small,[Drawing.Brushes]::Black,($i*420+8),($baseY+249))
        }
        $im=[Drawing.Image]::FromFile((Join-Path $dir ($(if($row -eq 0){'lob'}else{'fan'})+'-strip.jpg')))
        $g.DrawImage($im,0,($baseY+272),2520,280);$im.Dispose()
    }
    $g.Dispose();$canvas.Save((Join-Path $root 'preview/THROW-compare.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg);$canvas.Dispose();$pen.Dispose();$red.Dispose()
}
$font.Dispose();$small.Dispose()
Write-Output 'Generated throw GIFs, chronological strips, motion sheets and reference comparison.'
