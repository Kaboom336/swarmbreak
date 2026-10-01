"""Builds the 3D gallery page from the exported GLB models and renders.

Output: <out>.html plus a folder next to it with the GLB files (models/<group>/<name>.glb) and the big images
(img/*.jpg). The page loads them by relative path, so it stays small; publish the folder as the artifact's files.
Viewer: three.js r128 + GLTFLoader + OrbitControls from cdnjs.

Run: python3 export_gallery.py [out.html]   -> writes out.html and <dir>/files.json (published path -> source path)
"""
import base64
import io
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ASSETS = os.path.join(ROOT, "assets")
TEMPLATE = os.path.join(HERE, "gallery_template.html")

GROUPS = [("enemies", "Enemies"), ("weapons", "Weapons"), ("arena", "Arena kit")]


def thumb(path, size=256, quality=80):
    try:
        from PIL import Image
    except ImportError:
        return None
    im = Image.open(path).convert("RGB")
    im.thumbnail((size, size))
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=quality)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def jpeg_file(src, dst, width=1400, quality=80):
    from PIL import Image
    im = Image.open(src).convert("RGB")
    if im.width > width:
        im = im.resize((width, int(im.height * width / im.width)))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    im.save(dst, "JPEG", quality=quality)
    return dst


def main(out):
    out_dir = os.path.dirname(os.path.abspath(out))
    files = {}   # published path -> source path
    with open(os.path.join(ASSETS, "models", "manifest.json")) as f:
        manifest = json.load(f)
    data = {"groups": [], "sheets": {}, "before_after": []}
    for key, title in GROUPS:
        mdir = os.path.join(ASSETS, "models", key)
        rdir = os.path.join(ASSETS, "renders", key)
        if not os.path.isdir(mdir):
            continue
        items = []
        for fn in sorted(os.listdir(mdir)):
            if not fn.endswith(".glb"):
                continue
            name = fn[:-4]
            entry = manifest.get("%s/%s" % (key, name), {})
            png = os.path.join(rdir, name + ".png")
            rel = "models/%s/%s" % (key, fn)
            dst = os.path.join(out_dir, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(os.path.join(mdir, fn), dst)
            files[rel] = dst
            items.append({
                "id": name,
                "name": entry.get("display", name),
                "tris": entry.get("tris"),
                "size": entry.get("size_studs"),
                "rarity": entry.get("rarity"),
                "recipe": entry.get("recipe", "v1"),
                "parts": [p["name"] for p in entry.get("parts", [])],
                "glb_url": rel,
                "thumb": thumb(png) if os.path.exists(png) else None,
            })
            old = os.path.join(ASSETS, "renders", "v1", key, name + ".png")
            if entry.get("recipe") == "v2" and os.path.exists(old) and os.path.exists(png):
                data["before_after"].append({"name": entry.get("display", name), "group": title, "before": thumb(old, 320), "after": thumb(png, 320)})
        data["groups"].append({"key": key, "title": title, "items": items})
        sp = os.path.join(ASSETS, "renders", key + "-sheet.png")
        if os.path.exists(sp):
            rel = "img/%s-sheet.jpg" % key
            files[rel] = jpeg_file(sp, os.path.join(out_dir, rel))
            data["sheets"][key] = rel
    for k, src, width in (("lineup", os.path.join(ASSETS, "renders", "arena", "Lineup.png"), 1200),
                          ("hero", os.path.join(ASSETS, "renders", "hero.png"), 1400),
                          ("refs", os.path.join(ASSETS, "renders", "refs-sheet.png"), 1400)):
        if os.path.exists(src):
            rel = "img/%s.jpg" % k
            files[rel] = jpeg_file(src, os.path.join(out_dir, rel), width)
            data["sheets"][k] = rel
    old_lineup = os.path.join(ASSETS, "renders", "v1", "arena", "Lineup.png")
    new_lineup = os.path.join(ASSETS, "renders", "arena", "Lineup.png")
    if os.path.exists(old_lineup) and os.path.exists(new_lineup) and manifest.get("arena/FloorTile", {}).get("recipe") == "v2":
        data["before_after"].append({"name": "Arena corner", "group": "Arena kit", "before": thumb(old_lineup, 420), "after": thumb(new_lineup, 420)})
    with open(TEMPLATE) as f:
        html = f.read()
    payload = json.dumps(data).replace("</", "<\\/")
    html = html.replace("__DATA__", payload)
    os.makedirs(out_dir, exist_ok=True)
    with open(out, "w") as f:
        f.write(html)
    with open(os.path.join(out_dir, "files.json"), "w") as f:
        json.dump(files, f, indent=1)
    total = sum(os.path.getsize(p) for p in files.values())
    print("wrote", out, "%.2f MB page" % (len(html) / 1e6), sum(len(g["items"]) for g in data["groups"]), "models,", len(files), "files (%.1f MB)" % (total / 1e6), len(data["before_after"]), "before/after pairs")


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "preview", "gallery.html")
    main(out)
