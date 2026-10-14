"""Contact sheet from existing pixels, using bundled Blender, no new dependency."""
import bpy,sys,array
from pathlib import Path
out=Path(__file__).resolve().parents[2]/'treasure/map-v4'
r=sys.argv[sys.argv.index('--')+1]
w,h=1152,768
sheet=bpy.data.images.new('Concept left; exported native geometry right',width=2*w,height=h,alpha=False)
sheet.colorspace_settings.name='Non-Color'
pixels=array.array('f',[.95,.96,.97,1])*(w*h*2)
for name,col,row in [('concept.png',0,0),(f'build-r{r}-concept.png',1,0)]:
    im=bpy.data.images.load(str(out/name));im.colorspace_settings.name='Non-Color'
    scale=min(w/im.size[0],h/im.size[1]);sw=round(im.size[0]*scale);sh=round(im.size[1]*scale)
    im.scale(sw,sh);data=array.array('f',[0])*(sw*sh*4);im.pixels.foreach_get(data)
    ox=col*w+(w-sw)//2;oy=row*h+(h-sh)//2
    for y in range(sh):
        start=((oy+y)*w*2+ox)*4
        pixels[start:start+sw*4]=data[y*sw*4:(y+1)*sw*4]
sheet.pixels.foreach_set(pixels)
sheet.file_format='JPEG'
for name in [f'build-r{r}-sbs.jpg','build-sbs.jpg']:
    sheet.filepath_raw=str(out/name);sheet.save()
print('Saved',out/'build-sbs.jpg')
if r.startswith(('rr3','rr4')):
    top=bpy.data.images.load(str(out/f'build-r{r}-top-routes.png'))
    top.colorspace_settings.name='Non-Color'
    top_pixels=array.array('f',[0])*(top.size[0]*top.size[1]*4);top.pixels.foreach_get(top_pixels)
    exported=bpy.data.images.new('Final route plan',width=top.size[0],height=top.size[1],alpha=False)
    exported.colorspace_settings.name='Non-Color';exported.pixels.foreach_set(top_pixels)
    exported.file_format='JPEG';exported.filepath_raw=str(out/'build-top.jpg');exported.save()
    print('Saved',out/'build-top.jpg')
