"""Same conservative SAT and tolerance as contact.py, vectorized broad phase only."""
from pathlib import Path
scope={'__file__':__file__}
source=Path(__file__).with_name('contact.py').read_text()
exec(compile(source.split('errors=[dict')[0],str(Path(__file__).with_name('contact.py')),'exec'),scope)
np=scope['np'];old=scope['old'];new=scope['new']
centers=np.array([p['position'] for p in old],float)
extents=np.array([np.abs(scope['obb'](p)[2])@scope['obb'](p)[1] for p in old])
errors=[]
for a in new:
    c,h,r=scope['obb'](a)
    candidates=np.flatnonzero(np.all(np.abs(centers-c)<=extents+np.abs(r)@h-.035,axis=1))
    for index in candidates:
        b=old[index]
        if scope['penetration'](a,b):errors.append(dict(new=a['name'],old=b['name'],at=b['position']))
report=dict(state='PASS' if not errors else 'FAIL',tolerance=.035,cosmetic_envelopes=len(new),protected_solids=len(old),contact=len(errors),errors=errors,method='Original contact.py OBB SAT; vectorized identical AABB broad phase')
(scope['H']/('CONTACT-'+scope['tag']+'.json')).write_text(scope['json'].dumps(report,indent=2))
print(report)
assert not errors


