from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFont
root=Path(__file__).resolve().parent
names=['hub-topdown','hub-perspective','zone1-perspective','zone1-topdown','zones-strip','hud-desktop','hud-phone','panels','hatch-reveal','scythes','pets','guards-and-king','collectibles','first-5-min']
sheet=Image.new('RGB',(1680,1805),'#241a38')
draw=ImageDraw.Draw(sheet)
font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',24)
title=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',34)
draw.text((22,20),'STEAL A PUMPKIN | 14 CONCEPT SHEETS',font=title,fill='#ffc83d')
for i,name in enumerate(names):
    path=root/(name+'.png')
    with Image.open(path) as im: im.verify()
    with Image.open(path) as im:
        thumb=ImageOps.contain(im.convert('RGB'),(540,303))
        x=(i%3)*560; y=80+(i//3)*345
        sheet.paste(thumb,(x+(560-thumb.width)//2,y))
        draw.text((x+10,y+310),name+'.png',font=font,fill='#fff8ec')
        print(name,im.size,round(im.width/im.height,4))
sheet.save(root/'_sheet.jpg',quality=92)

