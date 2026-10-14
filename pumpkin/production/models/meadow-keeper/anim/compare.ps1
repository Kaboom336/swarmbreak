param([string]$AnimRoot = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$p = Join-Path $AnimRoot 'preview'
$canvas = New-Object Drawing.Bitmap(1840,1030)
$g = [Drawing.Graphics]::FromImage($canvas)
$g.Clear([Drawing.Color]::FromArgb(236,239,241))
$font = New-Object Drawing.Font('Segoe UI',19)
$small = New-Object Drawing.Font('Segoe UI',13)
function Label($text,$x,$y) { $g.DrawString($text,$font,[Drawing.Brushes]::Black,$x,$y) }
function Frame($path,$x,$y) {
    $im=[Drawing.Image]::FromFile($path)
    $g.DrawImage($im,$x,$y,360,360)
    $im.Dispose()
}
Label 'THROW / CHASE: previous reviewed pass vs exaggerated revision' 15 8
$ref=[Drawing.Image]::FromFile((Join-Path $AnimRoot '../blender/compare.jpg'))
Label 'Supplied v2 meadow throw' 15 60
$g.DrawImage($ref,(New-Object Drawing.Rectangle(15,100,360,345)),(New-Object Drawing.Rectangle(84,720,272,260)),[Drawing.GraphicsUnit]::Pixel)
Label 'Supplied title card lunge' 15 485
$g.DrawImage($ref,(New-Object Drawing.Rectangle(15,525,360,360)),(New-Object Drawing.Rectangle(1350,154,445,444)),[Drawing.GraphicsUnit]::Pixel)
$ref.Dispose()
Label 'OLD load / 0.480s' 390 60
Label 'NEW load / 0.480s' 750 60
Label 'OLD release / 0.620s' 1110 60
Label 'NEW release / 0.620s' 1470 60
Frame (Join-Path $p 'previous/throw-03.png') 380 100
Frame (Join-Path $p 'throw-03.png') 740 100
Frame (Join-Path $p 'previous/throw-04.png') 1100 100
Frame (Join-Path $p 'throw-04.png') 1460 100
Label 'OLD chase / 0.160s' 390 485
Label 'NEW chase / 0.160s' 750 485
Label 'OLD chase / 0.480s' 1110 485
Label 'NEW chase / 0.480s' 1470 485
Frame (Join-Path $p 'previous/chase-02.png') 380 525
Frame (Join-Path $p 'chase-02.png') 740 525
Frame (Join-Path $p 'previous/chase-05.png') 1100 525
Frame (Join-Path $p 'chase-05.png') 1460 525
$g.DrawString('Actual approved mesh / identical camera and scale. Reference images retain their own camera.',$small,[Drawing.Brushes]::Black,15,925)
$g.DrawString('Release remains 0.620s. GIFs show sampled continuous motion; Studio / device feel remains untested.',$small,[Drawing.Brushes]::Black,15,960)
$g.Dispose();$font.Dispose();$small.Dispose()
$canvas.Save((Join-Path $p '_throw-compare.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$canvas.Dispose()
