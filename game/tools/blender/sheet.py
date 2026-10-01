"""Contact sheets: one PNG per group (enemies / weapons / arena) with captions, for quick review.
Run: python3 sheet.py   -> assets/renders/<group>-sheet.png"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ASSETS = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets"))
RENDERS = os.path.join(ASSETS, "renders")
manifest = {}
mp = os.path.join(ASSETS, "models", "manifest.json")
if os.path.exists(mp):
    with open(mp) as f:
        manifest = json.load(f)

try:
    FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
except Exception:
    FONT = ImageFont.load_default()


def sheet(group, cols=4, cell=320):
    d = os.path.join(RENDERS, group)
    if not os.path.isdir(d):
        return
    files = sorted(f for f in os.listdir(d) if f.endswith(".png") and f != "Lineup.png")
    if not files:
        return
    rows = (len(files) + cols - 1) // cols
    out = Image.new("RGB", (cols * cell, rows * (cell + 34)), (10, 11, 16))
    draw = ImageDraw.Draw(out)
    for i, f in enumerate(files):
        im = Image.open(os.path.join(d, f)).convert("RGB")
        im.thumbnail((cell, cell))
        x = (i % cols) * cell
        y = (i // cols) * (cell + 34)
        out.paste(im, (x + (cell - im.width) // 2, y))
        name = f[:-4]
        entry = manifest.get("%s/%s" % (group, name), {})
        label = entry.get("display", name)
        sub = "%s tris" % entry.get("tris", "?")
        if entry.get("size_studs"):
            s = entry["size_studs"]
            sub += "  %.1fx%.1fx%.1f studs" % (s[0], s[1], s[2])
        draw.text((x + 8, y + cell + 4), label, fill=(240, 240, 250), font=FONT)
        draw.text((x + 8 + 150, y + cell + 6), sub, fill=(150, 150, 170), font=ImageFont.load_default())
    path = os.path.join(RENDERS, "%s-sheet.png" % group)
    out.save(path)
    print("wrote", path, len(files), "renders")


if __name__ == "__main__":
    for g in (sys.argv[1:] or ["enemies", "weapons", "arena"]):
        sheet(g)
