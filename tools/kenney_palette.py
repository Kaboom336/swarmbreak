import os, json
from PIL import Image
KEN = 'kenney/Models/OBJ format'
names = [n for n in json.load(open('json/_index.json')) if not os.path.exists(os.path.join('kaykit/KayKit-Space-Base-Bits-1.0-main/addons/kaykit_space_base_bits/Assets/obj', n + '.obj'))]
cols = {}
for n in names:
    for l in open(os.path.join(KEN, n + '.mtl')):
        q = l.split()
        if q and q[0] == 'newmtl': cur = q[1]
        if q and q[0] == 'Kd': cols[cur] = tuple(float(x) for x in q[1:4])
keys = sorted(cols); cell = 16; W = cell * 4; H = cell * ((len(keys) + 3) // 4)
img = Image.new('RGB', (W, H))
uv = {}
for i, k in enumerate(keys):
    x, y = (i % 4) * cell, (i // 4) * cell
    c = tuple(int(round(v * 255)) for v in cols[k])
    for a in range(cell):
        for b in range(cell): img.putpixel((x + a, y + b), c)
    uv[k] = ((x + cell / 2) / W, 1 - (y + cell / 2) / H)
os.makedirs('merged2', exist_ok=True)
img.save('merged2/kenney_palette.png')
V, T, L = [], [], []
vo = 0; ti = 0; tidx = {}
for k in keys:
    T.append(f'vt {uv[k][0]:.5f} {uv[k][1]:.5f}'); ti += 1; tidx[k] = ti
for i, n in enumerate(names):
    ox, oz = (i % 5) * 4.0, (i // 5) * 4.0 + 40
    L += [f'o {n}', f'g {n}', 'usemtl kenney_palette']
    v = 0; cur = None
    for line in open(os.path.join(KEN, n + '.obj')):
        p = line.split()
        if not p: continue
        if p[0] == 'v':
            x, y, z = map(float, p[1:4]); V.append(f'v {x+ox:.5f} {y:.5f} {z+oz:.5f}'); v += 1
        elif p[0] == 'usemtl': cur = p[1]
        elif p[0] == 'f':
            t = tidx[cur]
            L.append('f ' + ' '.join(f'{int(c.split("/")[0]) + vo}/{t}' for c in p[1:]))
    vo += v
open('merged2/swarmbreak_kenney.obj', 'w').write('mtllib swarmbreak_kenney.mtl\n' + '\n'.join(V + T + L) + '\n')
open('merged2/swarmbreak_kenney.mtl', 'w').write('newmtl kenney_palette\nKd 1 1 1\nmap_Kd kenney_palette.png\n')
print(len(names), keys)
