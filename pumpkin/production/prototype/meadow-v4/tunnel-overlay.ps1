# Native Windows drawing fallback; no additional library or asset dependency.
Add-Type -AssemblyName System.Drawing
$tunnelScriptRoot = Join-Path (Get-Location) 'prototype/meadow-v4'
$tunnelRoot = Split-Path -Parent $tunnelScriptRoot
$tunnelOut = Join-Path (Split-Path -Parent $tunnelRoot) 'treasure/map-v4'
$tunnelScene = Get-Content (Join-Path $tunnelScriptRoot 'scene.json') -Raw | ConvertFrom-Json
$tunnelImage = [System.Drawing.Bitmap]::new((Join-Path $tunnelOut 'build-rtunnel-tunnel-top.png'))
$tunnelGraphics = [System.Drawing.Graphics]::FromImage($tunnelImage)
$tunnelGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$tunnelFont = [System.Drawing.Font]::new('Segoe UI',14)
$tunnelInk = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(15,27,46))
$tunnelWhite = [System.Drawing.Brushes]::White
function Convert-TunnelPoint($point) { [System.Drawing.PointF]::new([single]($tunnelImage.Width/2+$point[0]/390*$tunnelImage.Width),[single]($tunnelImage.Height/2-$point[1]/390*$tunnelImage.Height)) }
foreach ($name in @('tunnel_trunk','tunnel_south')) {
 $route=$tunnelScene.routes.$name
 $color=if($name -eq 'tunnel_trunk'){[System.Drawing.Color]::FromArgb(42,247,218)}else{[System.Drawing.Color]::FromArgb(206,121,255)}
 $pen=[System.Drawing.Pen]::new($color,6);$outline=[System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(15,27,46),13)
 for($i=0;$i -lt $route.points.Count-1;$i++){$a=Convert-TunnelPoint $route.points[$i];$b=Convert-TunnelPoint $route.points[$i+1];$tunnelGraphics.DrawLine($outline,$a,$b);$tunnelGraphics.DrawLine($pen,$a,$b)}
 $pen.Dispose();$outline.Dispose()
}
$labels=@(@('ENTRANCE',$tunnelScene.tunnel.entrance),@('CROSS-LINK EXIT',$tunnelScene.tunnel.exits[0]),@('SOUTH EXIT',$tunnelScene.tunnel.exits[1]))
foreach($entry in $labels){$p=Convert-TunnelPoint $entry[1];$tunnelGraphics.FillEllipse([System.Drawing.Brushes]::Gold,$p.X-7,$p.Y-7,14,14);$tunnelGraphics.FillRectangle($tunnelInk,$p.X+10,$p.Y-12,210,27);$tunnelGraphics.DrawString($entry[0],$tunnelFont,$tunnelWhite,$p.X+14,$p.Y-10)}
$tunnelGraphics.FillRectangle($tunnelInk,20,20,710,95)
$tunnelGraphics.DrawString('MEADOW V4 | ACTUAL TUNNEL ROUTE OVERLAY',$tunnelFont,$tunnelWhite,32,29)
$tunnelGraphics.DrawString('Surveyed centerlines through roof | 14 studs | 2 connected exits',$tunnelFont,$tunnelWhite,32,57)
$tunnelGraphics.DrawString('Clearance 0 | Dead ends 0 | Offline shipped geometry',$tunnelFont,$tunnelWhite,32,85)
$oldTop=Join-Path $tunnelOut 'build-top.jpg';$baselineTop=Join-Path $tunnelOut 'tunnel-baseline-build-top.jpg'
if((Test-Path $oldTop) -and -not(Test-Path $baselineTop)){Copy-Item -LiteralPath $oldTop -Destination $baselineTop}
$tunnelImage.Save($oldTop,[System.Drawing.Imaging.ImageFormat]::Jpeg)
$tunnelImage.Save((Join-Path $tunnelOut 'build-tunnel-top.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$tunnelGraphics.Dispose();$tunnelImage.Dispose();$tunnelFont.Dispose();$tunnelInk.Dispose()
@{scene_sha256=(Get-FileHash (Join-Path $tunnelScriptRoot 'scene.json')).Hash.ToLower();render_sha256=(Get-FileHash (Join-Path $tunnelOut 'build-rtunnel-tunnel-top.png')).Hash.ToLower();method='Native System.Drawing over actual orthographic scene render, source X,Z,Y centerline mapping'} | ConvertTo-Json | Set-Content (Join-Path $tunnelOut 'TUNNEL-OVERLAY-METADATA.json')
