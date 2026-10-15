Add-Type -AssemblyName System.Drawing
$outDir = Join-Path (Get-Location) 'assets/kits2'
$manifest = Get-Content (Join-Path $outDir 'manifest.json') -Raw | ConvertFrom-Json
$font = New-Object System.Drawing.Font('Segoe UI', 11)
$small = New-Object System.Drawing.Font('Segoe UI', 9)
$title = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$white = [System.Drawing.Brushes]::White
$muted = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(188,198,215))
function Make-Sheet($items, $path, $label) {
    $cols = 6; $cellW = 256; $cellH = 330; $header = 76
    $bmp = New-Object System.Drawing.Bitmap(($cols*$cellW), ([int][Math]::Ceiling($items.Count/$cols)*$cellH+$header))
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(23,27,36))
    $g.DrawString("KITS2 / $label / source materials kept separate", $title, $white, 16, 10)
    $g.DrawString('Original island palettes; each part also carries an embedded 8 x 8 PNG albedo. Studio import pending.', $font, $muted, 16, 43)
    $i = 0
    foreach ($e in $items) {
        $x = ($i%$cols)*$cellW; $y = [int][Math]::Floor($i/$cols)*$cellH+$header
        $thumb = [System.Drawing.Image]::FromFile((Join-Path $outDir ('_thumbs/'+$e.island+'__'+$e.pack+'__'+$e.name+'.png')))
        $g.DrawImage($thumb,$x+10,$y,236,236); $thumb.Dispose()
        $g.DrawString(($e.island+' / '+$e.name),$font,$white,$x+10,$y+238)
        $g.DrawString(($e.pack+' / '+$e.meshParts+' meshes'),$small,$muted,$x+10,$y+260)
        $j = 0
        foreach ($m in $e.meshes) {
            $sw = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb([int]$m.colour[0],[int]$m.colour[1],[int]$m.colour[2]))
            $sy = $y+281+$j*14
            $g.FillRectangle($sw,$x+10,$sy,14,10)
            $text = $m.sourceMaterial+' > '+($m.material -replace '^\w+_','')
            $g.DrawString($text,$small,$muted,$x+29,$sy-3)
            $sw.Dispose(); $j++
        }
        $i++
    }
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}
Make-Sheet @($manifest.exports) (Join-Path $outDir '_sheet.png') 'Meadow + Cave'
foreach ($island in @('meadow','cave')) {
    Make-Sheet @($manifest.exports | Where-Object island -eq $island) (Join-Path $outDir ('_sheet-'+$island+'.png')) $island
}
$font.Dispose(); $small.Dispose(); $title.Dispose(); $muted.Dispose()
Write-Output 'PASS kits2 thumbnail sheets'
