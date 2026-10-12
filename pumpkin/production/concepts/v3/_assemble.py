"""Reproduce comparisons and contact sheet using Pillow. No image generation."""
from pathlib import Path
import json
from PIL import Image, ImageOps, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
rows = json.loads((root / 'MANIFEST.json').read_text(encoding='utf-8'))
font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 26)
title_font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 36)
background = '#17141f'
for row in rows:
    ours = Image.open(root / (row['sheet'] + '.png')).convert('RGB')
    reference = Image.open(root.parent / 'refs2' / (row.get('refSheet', row['sheet']) + '-ref-' + str(row['ref']) + '.jpg')).convert('RGB')
    height = 900
    ours = ours.resize((round(ours.width * height / ours.height), height), Image.Resampling.LANCZOS)
    reference = reference.resize((round(reference.width * height / reference.height), height), Image.Resampling.LANCZOS)
    canvas = Image.new('RGB', (ours.width + reference.width + 12, height + 64), background)
    canvas.paste(ours, (0, 64))
    canvas.paste(reference, (ours.width + 12, 64))
    draw = ImageDraw.Draw(canvas)
    draw.text((14, 17), f"OURS v3 | {row['score']}/10", font=font, fill='#ffc83d')
    draw.text((ours.width + 26, 17), f"BEST REF | {row['game']} | ref-{row['ref']}", font=font, fill='#72dbff')
    canvas.save(root / (row['sheet'] + '-sbs.jpg'), quality=92)

sheet = Image.new('RGB', (1680, 90 + ((len(rows) + 2) // 3) * 400), background)
draw = ImageDraw.Draw(sheet)
draw.text((22, 24), 'STEAL A PUMPKIN | v3 | 14 gameplay concepts', font=title_font, fill='#ffc83d')
for index, row in enumerate(rows):
    im = Image.open(root / (row['sheet'] + '.png')).convert('RGB')
    thumb = ImageOps.contain(im, (540, 340), Image.Resampling.LANCZOS)
    x, y = (index % 3) * 560, 90 + (index // 3) * 400
    sheet.paste(thumb, (x + (560 - thumb.width) // 2, y + (340 - thumb.height) // 2))
    draw.text((x + 12, y + 352), f"{row['sheet']} | {row['score']}/10", font=font, fill='white')
sheet.save(root / '_sheet.jpg', quality=92)

