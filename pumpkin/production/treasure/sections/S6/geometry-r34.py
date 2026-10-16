"""SAT against the actual native box/wedge convex vertices, same .035 tolerance."""
import numpy as np
def convex(p):
 r=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2;c=np.array(p['position'])
 corners=[(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)] if p.get('shape')=='Wedge' else [(x,y,z) for x in (-1,1) for y in (-1,1) for z in (-1,1)]
 v=np.array([c+r@(np.array(q)*h) for q in corners]);axes=list(r.T);edges=list(r.T)
 if p.get('shape')=='Wedge':axes.append(r@np.array([0,1,-h[1]/h[2]]));edges.append(r@np.array([0,h[1],h[2]]))
 return v,axes,edges
def overlaps(a,b,tol=.035):
 av,an,ae=a;bv,bn,be=b
 for axis in an+bn+[np.cross(x,y) for x in ae for y in be]:
  length=np.linalg.norm(axis)
  if length<1e-6:continue
  axis=axis/length;x=av@axis;y=bv@axis
  if min(x.max(),y.max())-max(x.min(),y.min())<=tol:return False
 return True
