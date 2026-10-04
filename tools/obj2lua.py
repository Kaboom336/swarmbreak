import sys, os, json
def fmt(x): 
    s = f"{x:.4f}".rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'
def conv(path, name, kind):
    vs, ts, faces, mats, cur = [], [], [], {}, None
    mtl = {}
    base = os.path.dirname(path)
    for line in open(path):
        p = line.split()
        if not p: continue
        if p[0] == 'mtllib':
            m = None
            for l in open(os.path.join(base, ' '.join(p[1:]))):
                q = l.split()
                if not q: continue
                if q[0] == 'newmtl': m = q[1]
                elif q[0] == 'Kd' and m: mtl[m] = [float(x) for x in q[1:4]]
        elif p[0] == 'v': vs.append([float(x) for x in p[1:4]])
        elif p[0] == 'vt': ts.append([float(x) for x in p[1:3]])
        elif p[0] == 'usemtl': cur = p[1]
        elif p[0] == 'f':
            idx = []
            for c in p[1:]:
                a = c.split('/')
                vi = int(a[0]); ti = int(a[1]) if len(a) > 1 and a[1] else 0
                idx.append((vi, ti))
            for i in range(1, len(idx) - 1):
                faces.append((idx[0], idx[i], idx[i+1], cur))
    names = sorted({f[3] for f in faces if f[3]})
    cols = [mtl.get(n, [1, 1, 1]) for n in names]
    out = ["{p={" + ",".join(fmt(c) for v in vs for c in v) + "}"]
    if kind == 'tex':
        out.append("t={" + ",".join(fmt(c) for t in ts for c in t) + "}")
        out.append("f={" + ",".join(f"{a[0]},{a[1]},{b[0]},{b[1]},{c[0]},{c[1]}" for a, b, c, _ in faces) + "}")
    else:
        out.append("c={" + ",".join(fmt(x) for c in cols for x in c) + "}")
        out.append("f={" + ",".join(f"{a[0]},{b[0]},{c[0]},{names.index(m)+1 if m in names else 1}" for a, b, c, m in faces) + "}")
    return f'_G.__kit["{name}"]=' + ",".join(out) + "}"
kind, src, outdir = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(outdir, exist_ok=True)
for n in sys.argv[4:]:
    s = conv(os.path.join(src, n + '.obj'), n, kind)
    open(os.path.join(outdir, n + '.lua'), 'w').write(s)
    print(n, len(s))
