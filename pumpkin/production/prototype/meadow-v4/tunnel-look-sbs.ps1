Add-Type -AssemblyName System.Drawing
$lookOut=Join-Path (Get-Location) 'treasure/map-v4'
$lookNames=@('entrance','inside','near-exit','south-exit','from-summit','overview')
$lookSheet=[System.Drawing.Bitmap]::new(1800,3888)
$lookGraphics=[System.Drawing.Graphics]::FromImage($lookSheet)
$lookGraphics.Clear([System.Drawing.Color]::FromArgb(17,24,30))
$lookFont=[System.Drawing.Font]::new('Segoe UI',20)
for($row=0;$row -lt 6;$row++){
 $lookName=$lookNames[$row]
 for($col=0;$col -lt 2;$col++){
  $lookFile=if($lookName -eq 'overview'){'build-rtunnel-tunnel-overview.png'}else{"build-rtunnel-eye-tunnel-$lookName.png"}
  $lookPath=if($col -eq 0){Join-Path $lookOut "tunnel-round2-before/$lookFile"}else{Join-Path $lookOut $lookFile}
  $lookImg=[System.Drawing.Bitmap]::new($lookPath)
  $lookGraphics.DrawImage($lookImg,$col*900,$row*648+37,900,611)
  $lookLabel=if($col -eq 0){"BEFORE | $lookName"}else{"AFTER | $lookName"}
  $lookGraphics.DrawString($lookLabel,$lookFont,[System.Drawing.Brushes]::White,$col*900+12,$row*648+3)
  $lookImg.Dispose()
 }
}
$lookSheet.Save((Join-Path $lookOut 'build-tunnel-sbs.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$lookGraphics.Dispose();$lookSheet.Dispose();$lookFont.Dispose()
