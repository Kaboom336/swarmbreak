param([string]$AnimRoot = $PSScriptRoot, [switch]$Before)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$previewDir = Join-Path $AnimRoot 'preview'
if ($Before) { $previewDir = Join-Path $previewDir 'before' }
$clipNames = @('idle','patrol','warn','chase','throw','stun','celebrate','return')
$times = Get-Content (Join-Path $previewDir 'times.json') -Raw | ConvertFrom-Json
$font = New-Object Drawing.Font('Segoe UI',18)
$small = New-Object Drawing.Font('Segoe UI',12)
$sheet = New-Object Drawing.Bitmap(2520,3240)
$sg = [Drawing.Graphics]::FromImage($sheet)
$sg.Clear([Drawing.Color]::FromArgb(236,239,241))
for ($row=0; $row -lt 8; $row++) {
    $name = $clipNames[$row]
    $strip = New-Object Drawing.Bitmap(2520,405)
    $g = [Drawing.Graphics]::FromImage($strip)
    $g.Clear([Drawing.Color]::FromArgb(236,239,241))
    $g.DrawString($name.ToUpper(),$font,[Drawing.Brushes]::Black,8,2)
    for ($i=0; $i -lt 7; $i++) {
        $path = Join-Path $previewDir ('{0}-{1:d2}.png' -f $name,$i)
        $image = [Drawing.Image]::FromFile($path)
        $g.DrawImage($image,$i*360,29,360,360)
        $image.Dispose()
        $label = '{0:0.000}s' -f $times.$name[$i]
        if ($name -eq 'throw' -and $i -eq 4) { $label += ' RELEASE' }
        $g.DrawString($label,$small,[Drawing.Brushes]::Black,$i*360+8,384)
    }
    $g.Dispose()
    $strip.Save((Join-Path $previewDir ($name+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg)
    $sg.DrawImage($strip,0,$row*405)
    # Blind sheets omit the clip name and use neutral IDs.
    $blind = $strip.Clone((New-Object Drawing.Rectangle(0,29,2520,376)),$strip.PixelFormat)
    $blind.Save((Join-Path $previewDir ('blind-'+[char](65+$row)+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg)
    $blind.Dispose();$strip.Dispose()
}
$sg.Dispose()
$sheet.Save((Join-Path $previewDir '_sheet.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$sheet.Dispose();$font.Dispose();$small.Dispose()
Write-Output ('Frame strips: '+$previewDir)

if (-not $Before) {
    $compare = New-Object Drawing.Bitmap(1440,820)
    $cg = [Drawing.Graphics]::FromImage($compare)
    $cg.Clear([Drawing.Color]::FromArgb(236,239,241))
    $cf = New-Object Drawing.Font('Segoe UI',16)
    $cg.DrawString('SUPPLIED POSE REFERENCES vs FINAL AUTHORED POSES',$cf,[Drawing.Brushes]::Black,12,8)
    $reference = [Drawing.Image]::FromFile((Join-Path $AnimRoot '../blender/compare.jpg'))
    $cg.DrawImage($reference,(New-Object Drawing.Rectangle(0,70,360,310)),(New-Object Drawing.Rectangle(946,720,315,260)),[Drawing.GraphicsUnit]::Pixel)
    $cg.DrawImage($reference,(New-Object Drawing.Rectangle(0,470,360,310)),(New-Object Drawing.Rectangle(48,720,308,260)),[Drawing.GraphicsUnit]::Pixel)
    $reference.Dispose()
    $cg.DrawString('Warn reference / snap / high fist',$cf,[Drawing.Brushes]::Black,12,42)
    $cg.DrawString('Throw reference / loaded wind-up / release',$cf,[Drawing.Brushes]::Black,12,442)
    $pairs = @(@('warn-02.png','warn-04.png'),@('throw-02.png','throw-04.png'))
    for ($row=0;$row -lt 2;$row++) {
        for ($col=0;$col -lt 2;$col++) {
            $im=[Drawing.Image]::FromFile((Join-Path $previewDir $pairs[$row][$col]))
            $cg.DrawImage($im,400+$col*400,60+$row*400,360,360)
            $im.Dispose()
        }
    }
    $cg.Dispose();$cf.Dispose()
    $compare.Save((Join-Path $previewDir '_reference-compare.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
    $compare.Dispose()
}
