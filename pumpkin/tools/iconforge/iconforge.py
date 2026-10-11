"""Offline Pillow renderer: original code, reusing SECTION-LOOK 2.5 grids.
Run with Python 3; no external assets or dependencies beyond Pillow.
"""
from __future__ import annotations
import argparse
import json
import math
from pathlib import Path
from PIL import Image, ImageColor, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
IDS = ('shop','index','pets','quests','daily','settings','candy','scythe','king','timer','carry','sprint')
BASE_KEYS = {'O':'o','Y':'o','h':'y','G':'g','P':'p','q':'p','R':'r','S':'s','B':'b','C':'c','N':'n'}


def load_data(path):
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    if tuple(i['id'] for i in data['icons']) != IDS:
        raise ValueError('Expected all 12 specified IDs in source order')
    for icon in data['icons']:
        grid = icon['grid']
        if len(grid) != 12 or any(len(r) != 12 for r in grid):
            raise ValueError(f"{icon['id']}: expected a 12x12 grid")
        unknown = set(''.join(grid)) - set(data['palette']) - {'.'}
        if unknown:
            raise ValueError(f"{icon['id']}: unknown keys {unknown}")
    return data


def mix(a,b,t):
    return tuple(round(x*(1-t)+y*t) for x,y in zip(a,b))


def render(icon,palette,config):
    size,ss = config['size'],config['supersample']
    n = size*ss
    yaw,pitch,tilt = (math.radians(config[k]) for k in ('yaw_degrees','pitch_degrees','tilt_degrees'))
    sy,cy,sp,cp = math.sin(yaw),math.cos(yaw),math.sin(pitch),math.cos(pitch)
    st,ct = math.sin(tilt),math.cos(tilt)
    depth,grid,faces = config['depth'],icon['grid'],[]

    def occupied(x,y):
        return 0 <= x < 12 and 0 <= y < 12 and grid[y][x] != '.'

    def project(p):
        x,y,z = p
        u,v = x*cy+z*sy,y*cp+x*sy*sp-z*cy*sp
        return u*ct-v*st,u*st+v*ct

    def add(kind,key,points):
        c = tuple(sum(p[i] for p in points)/4 for i in range(3))
        distance = c[0]*sy*cp-c[1]*sp-c[2]*cy*cp
        base = palette[BASE_KEYS.get(key,key)]
        colour = (mix(base,(255,255,255),.25) if kind == 'top' else
                  mix(base,(42,16,68),.34) if kind == 'right' else palette[key])
        faces.append((distance,kind,[project(p) for p in points],colour))

    for y,row in enumerate(grid):
        for x,key in enumerate(row):
            if key == '.':
                continue
            add('front',key,[(x,y,0),(x+1,y,0),(x+1,y+1,0),(x,y+1,0)])
            if not occupied(x,y-1):
                add('top',key,[(x,y,depth),(x+1,y,depth),(x+1,y,0),(x,y,0)])
            if not occupied(x+1,y):
                add('right',key,[(x+1,y,0),(x+1,y,depth),(x+1,y+1,depth),(x+1,y+1,0)])
    points = [p for f in faces for p in f[2]]
    xmin,ymin = (min(p[i] for p in points) for i in (0,1))
    xmax,ymax = (max(p[i] for p in points) for i in (0,1))
    span = max(xmax-xmin,ymax-ymin)
    # Fit includes circular dilation; eight percent margins leave room for shadow.
    scale = n*(1-2*config['padding'])/(span*(1+2*config['outline_fraction']))
    radius = span*scale*config['outline_fraction']
    mx,my = (xmin+xmax)/2,(ymin+ymax)/2
    def pixels(points):
        return [((x-mx)*scale+n/2,(y-my)*scale+n/2) for x,y in points]

    art = Image.new('RGBA',(n,n))
    draw = ImageDraw.Draw(art)
    contour = Image.new('L',art.size)
    edge = ImageDraw.Draw(contour)
    visible_tops = Image.new('L',art.size)
    top_draw = ImageDraw.Draw(visible_tops)
    for _,kind,points,colour in sorted(faces,key=lambda f:f[0]):
        p = pixels(points)
        draw.polygon(p,fill=(*colour,255))
        top_draw.polygon(p,fill=255 if kind == 'top' else 0)
        edge.polygon(p,fill=255)
        # Union of circular polygon dilations: rounded outer contour, no cell strokes.
        edge.line(p+[p[0]],fill=255,width=round(2*radius),joint='curve')
        for x,y in p:
            edge.ellipse((x-radius,y-radius,x+radius,y+radius),fill=255)
    # Find contiguous top runs so the gloss reads as one toy shine, not voxel noise.
    runs = []
    for y,row in enumerate(grid):
        x = 0
        while x < 12:
            if not occupied(x,y) or occupied(x,y-1):
                x += 1
                continue
            start,key = x,BASE_KEYS.get(row[x],row[x])
            x += 1
            while x < 12 and occupied(x,y) and not occupied(x,y-1) and BASE_KEYS.get(row[x],row[x]) == key:
                x += 1
            runs.append(pixels([project(p) for p in
                        [(start,y,depth),(x,y,depth),(x,y,0),(start,y,0)]]))
    top = min(runs,key=lambda p:sum(y+.20*x for x,y in p)/4)
    def uv(u,v):
        a,b,_,d = top
        return (a[0]+u*(b[0]-a[0])+v*(d[0]-a[0]),a[1]+u*(b[1]-a[1])+v*(d[1]-a[1]))
    gloss = Image.new('RGBA',art.size)
    shine = ImageDraw.Draw(gloss)
    shine.polygon([uv(.12,.25),uv(.65,.25),uv(.65,.49),uv(.12,.49)],fill=(255,255,255,235))
    shine.polygon([uv(.82+.065*math.cos(t),.36+.14*math.sin(t))
                   for t in [i*math.tau/24 for i in range(24)]],fill='white')
    from PIL import ImageChops
    gloss.putalpha(ImageChops.multiply(gloss.getchannel('A'),visible_tops))
    art.alpha_composite(gloss)
    blurred = contour.filter(ImageFilter.GaussianBlur(n*.009))
    shifted = Image.new('L',art.size)
    shifted.paste(blurred,(round(n*.012),round(n*.018)))
    result = Image.new('RGBA',art.size,(12,7,24,0))
    result.putalpha(shifted.point(lambda a:round(a*.32)))
    outline = Image.new('RGBA',art.size,(*ImageColor.getrgb(config['outline_colour']),0))
    outline.putalpha(contour)
    result.alpha_composite(outline)
    result.alpha_composite(art)
    return result.resize((size,size),Image.Resampling.LANCZOS)


def sheet(images,output):
    """Large previews plus native 64px and silhouette checks on both backgrounds."""
    cw,ch,cols,rows = 248,310,6,2
    result = Image.new('RGB',(cw*cols,(ch*rows+38)*2))
    draw = ImageDraw.Draw(result)
    font,small = ImageFont.load_default(size=17),ImageFont.load_default(size=12)
    for band,bg in enumerate(('#85858B','#24202F')):
        y0 = band*(rows*ch+38)
        draw.rectangle((0,y0,result.width,y0+rows*ch+38),fill=bg)
        draw.text((18,y0+10),f'{bg} | 192px preview / native 64px / 64px silhouette',fill='white',font=font)
        for i,(name,icon) in enumerate(images.items()):
            x,y = (i%cols)*cw,y0+38+(i//cols)*ch
            draw.text((x+14,y+8),name,fill='white',font=font)
            big = icon.resize((192,192),Image.Resampling.LANCZOS)
            result.paste(big,(x+28,y+28),big)
            tiny = icon.resize((64,64),Image.Resampling.LANCZOS)
            result.paste(tiny,(x+43,y+228),tiny)
            solid = Image.new('RGBA',icon.size,(10,6,16,255))
            solid.putalpha(icon.getchannel('A').point(lambda a:255 if a>160 else 0))
            solid = solid.resize((64,64),Image.Resampling.LANCZOS)
            result.paste(solid,(x+140,y+228),solid)
            draw.text((x+44,y+295),'64 px',font=small,fill='white')
            draw.text((x+137,y+295),'silhouette',font=small,fill='white')
    result.save(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data',type=Path,default=ROOT/'icons.json')
    args = parser.parse_args()
    data = load_data(args.data)
    palette = {k:ImageColor.getrgb(v) for k,v in data['palette'].items()}
    output = ROOT/'out'
    output.mkdir(exist_ok=True)
    images = {}
    for icon in data['icons']:
        image = render(icon,palette,data['render'])
        image.save(output/f"{icon['id']}.png")
        images[icon['id']] = image
        print(f"{icon['id']}: {image.width}x{image.height} RGBA")
    sheet(images,output/'_sheet.png')
    print(f'Wrote {len(images)} icons and _sheet.png to {output}')


if __name__ == '__main__':
    main()
