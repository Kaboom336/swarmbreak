import os, json, shutil
KAY = 'kaykit/KayKit-Space-Base-Bits-1.0-main/addons/kaykit_space_base_bits/Assets/obj'
KEN = 'kenney/Models/OBJ format'
names = json.load(open('json/_index.json'))
out_v, out_vt, out_vn, lines, mtl = [], [], [], [], {}
vo = to = no = 0
i = 0
for n in names:
    src = os.path.join(KAY if os.path.exists(os.path.join(KAY, n + '.obj')) else KEN, n + '.obj')
    base = os.path.dirname(src)
    ox, oz = (i % 7) * 4.0, (i // 7) * 4.0; i += 1
    v = vt = vn = 0
    lines.append(f'o {n}'); lines.append(f'g {n}')
    for line in open(src):
        p = line.split()
        if not p: continue
        if p[0] == 'mtllib':
            cur = None
            for l in open(os.path.join(base, ' '.join(p[1:]))):
                q = l.strip()
                if q.startswith('newmtl'): cur = q.split()[1]; mtl.setdefault(cur, [])
                elif cur and q and not q.startswith('#'): 
                    if cur in mtl and q not in mtl[cur]: mtl[cur].append(q)
        elif p[0] == 'v':
            x, y, z = map(float, p[1:4]); out_v.append(f'v {x+ox:.5f} {y:.5f} {z+oz:.5f}'); v += 1
        elif p[0] == 'vt': out_vt.append(line.strip()); vt += 1
        elif p[0] == 'vn': out_vn.append(line.strip()); vn += 1
        elif p[0] == 'usemtl': lines.append(line.strip())
        elif p[0] == 'f':
            fs = []
            for c in p[1:]:
                a = c.split('/') + ['', '']
                s = str(int(a[0]) + vo)
                s += '/' + (str(int(a[1]) + to) if a[1] else '')
                if a[2]: s += '/' + str(int(a[2]) + no)
                fs.append(s)
            lines.append('f ' + ' '.join(fs))
    vo += v; to += vt; no += vn
with open('merged/swarmbreak_kit.obj', 'w') as f:
    f.write('mtllib swarmbreak_kit.mtl\n' + '\n'.join(out_v + out_vt + out_vn + lines) + '\n')
with open('merged/swarmbreak_kit.mtl', 'w') as f:
    for k, props in mtl.items(): f.write(f'newmtl {k}\n' + '\n'.join(props) + '\n\n')
shutil.copy('spacebits_texture.png', 'merged/spacebits_texture.png')
print(len(names), 'objects', vo, 'verts', len(mtl), 'materials')
