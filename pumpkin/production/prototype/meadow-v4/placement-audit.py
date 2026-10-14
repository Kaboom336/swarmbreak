"""Independent placement audit of rendered/shipped OBBs, including cosmetics.
Assembly interiors are intentional joins, never cross-prop exemptions.
Terrain, attached cliff moss, portal/acorn/character, distant island masses and
the deliberately floating underside debris are construction, not ground props.
"""
import json, math, hashlib, sys
from pathlib import Path
H=Path(__file__).parent; O=H.parents[1]/'treasure/map-v4'
SUPPORT_CATEGORIES={'terrace','lane','bridge','jump_access','court','portal','protected','jump','ground','base','ravine_ground','bridge_structure'}
CONSTRUCTION_CATEGORIES=SUPPORT_CATEGORIES|{'cliff','path_rock','rock_cap','terrain_cap','terrain_grass','ravine_rock','background','grass','edging','paving','tell','jump_read','root','underside'}

def bounds(p):
    r=p['rotation']; s=p['size']; c=p['position']
    e=[sum(abs(r[i*3+j])*s[j]/2 for j in range(3)) for i in range(3)]
    return tuple(c[i]-e[i] for i in range(3))+tuple(c[i]+e[i] for i in range(3))

def vertical(p,x,z):
    r=p['rotation'];o=p['position'];s=p['size'];lo=-1000;hi=1000
    for j in range(3):
        origin=r[j]*(x-o[0])+r[3+j]*(-o[1])+r[6+j]*(z-o[2]);d=r[3+j]
        if abs(d)<1e-9:
            if abs(origin)>s[j]/2+.001:return None
        else:
            a=(-s[j]/2-origin)/d;b=(s[j]/2-origin)/d
            lo=max(lo,min(a,b));hi=min(hi,max(a,b))
            if hi<lo:return None
    return lo,hi

class Terrain:
    def __init__(self,parts):
        self.grid={}
        for p in parts:
            if not p['collidable'] or p['category'] not in SUPPORT_CATEGORIES:continue
            b=bounds(p)
            for x in range(math.floor(b[0]/8),math.floor(b[3]/8)+1):
                for z in range(math.floor(b[2]/8),math.floor(b[5]/8)+1):self.grid.setdefault((x,z),[]).append(p)
    def top(self,x,z,ceiling=100):
        hits=[vertical(p,x,z) for p in self.grid.get((math.floor(x/8),math.floor(z/8)),[])]
        return max((h[1] for h in hits if h and h[1]<=ceiling),default=None)

def groups(parts):
    result=[]; current=None
    cats={'tree','bush','cover','boulder','flower','lantern','light','fence','ground_detail','west_landmark','east_landmark','bridge_landmark','jump_landmark','banner'}
    for i,p in enumerate(parts):
        if p.get('assembly'):
            continue
        if p['category']=='fence':current=None;continue
        if p['category'] not in cats and p['name'] not in {'GrassTuft','NativeGrassTuft','MossTuft'}:current=None;continue
        n=p['name']; attach=False
        if current:
            attach=(p['category']=='tree' and n=='VoxelOakCrown' and current['kind']=='tree') or (n in {'WarmWildflower','FlowerPatchGold','FlowerPatchCentre','Round4BushTop'} and current['kind']==p['category']) or (p['category'] in {'lantern','light'} and n not in {'Round4LanternFooting','LanternPost'} and current['kind']=='lantern') or (n=='LanternPost' and current['parts'][-1]['name']=='Round4LanternFooting') or (p['category']=='banner' and n!='CampBannerPole' and current['kind']=='banner')
        if not attach:
            current={'id':f'legacy-{i}','kind':'lantern' if p['category']=='light' else p['category'],'parts':[]}
            result.append(current)
        current['parts'].append(p)
    authored={}
    for p in parts:
        if p.get('assembly'):
            a=authored.setdefault(p['assembly'],{'id':p['assembly'],'kind':p.get('prop_kind',p['category']),'parts':[]})
            a['parts'].append(p)
    # Reconstruct old fence assemblies from their rail geometry, including
    # deliberate post/rail joints so these do not inflate the defect count.
    posts=[p for p in parts if p['name']=='FencePost' and not p.get('assembly')]
    rails=[p for p in parts if p['name']=='FenceRail' and not p.get('assembly')]
    assigned=set()
    for i,p in enumerate(rails):
        if id(p) in assigned:continue
        r=p['rotation'];s=p['size'];c=p['position']
        a={'id':f'legacy-fence-{i}','kind':'fence','parts':[p]};assigned.add(id(p))
        for q in rails:
            if id(q) not in assigned and abs(q['position'][0]-c[0])<.01 and abs(q['position'][2]-c[2])<.01 and q['rotation']==r:a['parts'].append(q);assigned.add(id(q))
        for q in posts:
            d=[q['position'][j]-c[j] for j in range(3)]
            along=abs(r[2]*d[0]+r[8]*d[2]);across=abs(r[0]*d[0]+r[6]*d[2])
            if across<1 and along<s[2]/2+1 and id(q) not in assigned:
                a['parts'].append(q);assigned.add(id(q))
        result.append(a)
    for p in posts:
        if id(p) not in assigned:result.append({'id':f'legacy-post-{len(result)}','kind':'fence','parts':[p]})
    return result+list(authored.values())

def boxes_overlap(a,b,tol=.025):
    # Exact separating-axis test for the 15 OBB axes; touching is not overlap.
    ba=bounds(a);bb=bounds(b)
    if any(min(ba[i+3],bb[i+3])-max(ba[i],bb[i])<=tol for i in range(3)):return False
    ar=a['rotation'];br=b['rotation']
    axes_a=[[ar[j],ar[3+j],ar[6+j]] for j in range(3)]
    axes_b=[[br[j],br[3+j],br[6+j]] for j in range(3)]
    axes=axes_a+axes_b
    for u in axes_a:
        for v in axes_b:axes.append([u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]])
    d=[b['position'][i]-a['position'][i] for i in range(3)]
    for axis in axes:
        norm=math.sqrt(sum(v*v for v in axis))
        if norm<1e-8:continue
        ax=[v/norm for v in axis]
        reach=sum(a['size'][j]/2*abs(sum(ax[i]*axes_a[j][i] for i in range(3)))+b['size'][j]/2*abs(sum(ax[i]*axes_b[j][i] for i in range(3))) for j in range(3))
        if abs(sum(ax[i]*d[i] for i in range(3)))>=reach-tol:return False
    return True

def footprint(p):
    # Flatten the actual projected footprint, never expand a pitched OBB by
    # making its local Y dimension tall (that spuriously widens the footprint).
    r=p['rotation'];s=p['size'];length=math.hypot(r[2],r[8])
    q=dict(p);q['position']=[p['position'][0],0,p['position'][2]]
    if length<1e-8:
        b=bounds(p);q['rotation']=[1,0,0,0,1,0,0,0,1];q['size']=[b[3]-b[0],200,b[5]-b[2]]
    else:
        zx,zz=r[2]/length,r[8]/length
        q['rotation']=[zz,0,zx,0,1,0,-zx,0,zz]
        q['size']=[s[0]*math.hypot(r[0],r[6]),200,s[2]*length+s[1]*math.hypot(r[1],r[7])]
    return q

class Construction:
    def __init__(self,parts):
        self.grid={}
        for p in parts:
            if p.get('assembly') or p['category'] not in CONSTRUCTION_CATEGORIES:continue
            if p['name'].startswith('Boulder') or p['name'] in {'MossTuft','Round4BoulderFacet','SummitRockMoss'}:continue
            b=bounds(p)
            for x in range(math.floor(b[0]/16),math.floor(b[3]/16)+1):
                for z in range(math.floor(b[2]/16),math.floor(b[5]/16)+1):self.grid.setdefault((x,z),[]).append(p)
    def clips(self,p):
        b=bounds(p)
        candidates={id(q):q for x in range(math.floor(b[0]/16),math.floor(b[3]/16)+1) for z in range(math.floor(b[2]/16),math.floor(b[5]/16)+1) for q in self.grid.get((x,z),[])}
        return [q['name'] for q in candidates.values() if boxes_overlap(p,q,.20)]

def audit(scene,legacy_tunnel_lights=False):
    parts=scene['parts'];assemblies=groups(parts); terrain=Terrain(parts);construction=Construction(parts)
    # These existing meshes belong to tunnel construction/lighting: caps attach
    # to tunnel_detail stems; ceiling emitters are intentionally suspended.
    # Keep legacy mode to expose and compare the old misclassification counts.
    fixture_names={'TunnelMushroomGlow','TunnelSkylightGlow'}
    fixtures=[p for p in parts if p['name'] in fixture_names]
    fixture_errors=[p for p in fixtures if p['name']=='TunnelMushroomGlow' and not any(q['name']=='TunnelMushroomStem' and boxes_overlap(p,q,-.035) for q in parts)]
    if not legacy_tunnel_lights:assemblies=[a for a in assemblies if not all(p['name'] in fixture_names for p in a['parts'])]
    overlaps=[]; floating=[];sunk=[]; unsupported=[];paths=[];offedge=[]
    clipping=[];disconnected=[];fence_gaps=[]
    for a in assemblies:
        ps=a['parts'];links={i:set() for i in range(len(ps))}
        for i,p in enumerate(ps):
            hits=construction.clips(p)
            if hits:clipping.append({'id':a['id'],'part':p['name'],'construction':hits[:5]})
            for j in range(i):
                if boxes_overlap(p,ps[j],-.035):links[i].add(j);links[j].add(i)
        seen={0};pending=[0]
        while pending:
            for j in links[pending.pop()]-seen:seen.add(j);pending.append(j)
        if len(seen)!=len(ps):disconnected.append(a['id'])
        if a['kind']=='fence':
            posts=[p for p in ps if 'Post' in p['name']];rails=[p for p in ps if 'Rail' in p['name']]
            if len(posts)<2 or len(rails)<2:fence_gaps.append(a['id']);continue
            incidence={id(p):0 for p in posts}
            for p in rails:
                for sign in [-1,1]:
                    end=[p['position'][i]+sign*p['rotation'][i*3+2]*p['size'][2]/2 for i in range(3)]
                    near=[q for q in posts if math.hypot(end[0]-q['position'][0],end[2]-q['position'][2])<.65]
                    if not near:fence_gaps.append(a['id'])
                    else:incidence[id(near[0])]+=1
            # Old fences use uninterrupted long rails through intermediate
            # posts; those posts need not be endpoints of separate segments.
            if sum(n==2 for n in incidence.values())!=2 or any(n not in {0,2,4} for n in incidence.values()):fence_gaps.append(a['id'])
            if any(not any(boxes_overlap(post,rail,-.035) for rail in rails) for post in posts):fence_gaps.append(a['id'])
    # Local hash bounds avoid quadratic all-scene comparisons.
    cells={}; pairs=set()
    for i,a in enumerate(assemblies):
        bs=[bounds(p) for p in a['parts']]
        for x in range(math.floor(min(b[0] for b in bs)/16),math.floor(max(b[3] for b in bs)/16)+1):
            for z in range(math.floor(min(b[2] for b in bs)/16),math.floor(max(b[5] for b in bs)/16)+1):
                for j in cells.get((x,z),[]):pairs.add((j,i))
                cells.setdefault((x,z),[]).append(i)
    for i,j in sorted(pairs):
        a,b=assemblies[i],assemblies[j]
        if any(boxes_overlap(p,q) for p in a['parts'] for q in b['parts']):overlaps.append([a['id'],b['id']])
    lanes=[p for p in parts if p['category'] in {'lane','bridge','jump_access'}]
    lanegrid={}
    for p in lanes:
        b=bounds(p)
        for x in range(math.floor(b[0]/16),math.floor(b[3]/16)+1):
            for z in range(math.floor(b[2]/16),math.floor(b[5]/16)+1):lanegrid.setdefault((x,z),[]).append(p)
    for a in assemblies:
        if any(p.get('root') for p in a['parts']):roots=[p for p in a['parts'] if p.get('root')]
        elif a['kind']=='tree':roots=[p for p in a['parts'] if p['name']=='OakTrunk']
        elif a['kind']=='fence':roots=[p for p in a['parts'] if p['name']=='FencePost']
        elif a['kind']=='banner':roots=a['parts'][:1]
        elif a['kind']=='lantern':roots=a['parts'][:1]
        else:roots=[min(a['parts'],key=lambda p:bounds(p)[1])]
        gaps=[]
        for p in roots:
            r=p['rotation'];s=p['size'];c=p['position']
            for u,v in [(0,0),(-.98,-.98),(-.98,.98),(.98,-.98),(.98,.98)]:
                x=c[0]+r[0]*s[0]*u/2+r[2]*s[2]*v/2
                z=c[2]+r[6]*s[0]*u/2+r[8]*s[2]*v/2
                bottom=vertical(p,x,z)
                top=terrain.top(x,z,100)
                if top is None:unsupported.append(a['id']);continue
                if bottom:gaps.append(bottom[0]-top)
        if gaps and max(gaps)>.20:floating.append({'id':a['id'],'max_gap':round(max(gaps),3)})
        if gaps and min(gaps)<-.20:sunk.append({'id':a['id'],'penetration':round(-min(gaps),3)})
        # Footprints reserve the whole lane even for noncollidable cosmetics.
        hit=False
        for p in a['parts']:
            b=bounds(p)
            candidates={id(q):q for x in range(math.floor(b[0]/16),math.floor(b[3]/16)+1) for z in range(math.floor(b[2]/16),math.floor(b[5]/16)+1) for q in lanegrid.get((x,z),[])}
            probe=footprint(p)
            for q in candidates.values():
                qb=bounds(q)
                if b[1]>qb[4]+20 or b[4]<qb[1]-.20:continue
                qprobe=footprint(q)
                if boxes_overlap(probe,qprobe):hit=True;break
            if hit:break
        if hit:paths.append(a['id'])
        if a['kind']=='flower':
            import geometry as g
            p=roots[0];x,z=p['position'][0],-p['position'][2]
            dist=min(g.dist_segment(x,z,u,v)-route['width']/2 for route in scene['routes'].values() for u,v in zip(route['points'],route['points'][1:]))
            # R6 deliberately includes interior mixed groves. An interior bloom
            # must belong to a nearby actual mixed planting, not an exemption
            # from any support, overlap, clipping or clearance test above.
            grove_ids=next((ids for ids in scene.get('r6',{}).get('clusters',{}).values() if a['id'] in ids),[])
            neighbours=[q for q in assemblies if q['id'] in grove_ids and q['kind'] in {'tree','bush','boulder','cover'}]
            mixed={'tree','bush'}<=set(q['kind'] for q in neighbours) and any(q['kind'] in {'boulder','cover'} for q in neighbours)
            nearby=any(math.hypot(p['position'][0]-q['parts'][0]['position'][0],p['position'][2]-q['parts'][0]['position'][2])<=22 for q in neighbours)
            if not .3<=dist<=6 and not (mixed and nearby):offedge.append(a['id'])
    audited={id(p) for a in assemblies for p in a['parts']}
    expected=[p for p in parts if (legacy_tunnel_lights or p['name'] not in fixture_names) and (p.get('assembly') or p['category'] in {'tree','bush','cover','boulder','flower','lantern','light','fence','ground_detail','banner','west_landmark','east_landmark','bridge_landmark','jump_landmark'} or p['name']=='MossTuft')]
    widths=sum(rr['width']<(14 if not legacy_tunnel_lights and name in {'tunnel_trunk','tunnel_south'} else 18) for name,rr in scene['routes'].items())
    pads=[p for p in parts if p['category']=='jump'];pad_errors=sum(p['size'][0]<12 or p['size'][2]<12 or not p['collidable'] for p in pads)+abs(3-len(pads))
    for p in pads:
        b=bounds(p)
        for ix in range(13):
            for iz in range(13):
                x=b[0]+(b[3]-b[0])*ix/12;z=b[2]+(b[5]-b[2])*iz/12;h=terrain.top(x,z)
                if h is None or abs(h-b[4])>.75:pad_errors+=1
    result={'assemblies':len(assemblies),'parts_in_prop_audit':sum(len(a['parts']) for a in assemblies),'unclassified_prop_parts':sum(id(p) not in audited for p in expected),'overlap_pairs':len(overlaps),'floating':len(floating),'sunk':len(sunk),'unsupported':len(set(unsupported)),'path_intrusions':len(paths),'flowers_off_path_edge':len(offedge),'construction_clipping_parts':len(clipping),'disconnected_assemblies':len(disconnected),'fence_gaps_or_stubs':len(set(fence_gaps)),'main_width_errors':widths,'jump_pad_errors':pad_errors,'overlap_details':overlaps,'floating_details':floating,'sunk_details':sunk,'unsupported_details':sorted(set(unsupported)),'path_details':paths,'flower_details':offedge,'construction_details':clipping,'disconnected_details':disconnected,'fence_details':sorted(set(fence_gaps))}
    result['method']='15-axis OBB cross-assembly overlaps; whole-prop construction OBB checks (0.20-stud contact tolerance); 5 support rays/root with explicit support-category whitelist; assembly connectivity and fence endpoint/incidence checks; projected lane footprints within20-stud headroom; flowers0.3..6 studs outside lanes OR explicit mixed tree+bush+boulder grove membership within22 studs of a member; route widths>=18 and three actual collidable12x12 pads with13x13 support rays and0.75-stud nominal surface tolerance matching lane audit. Retained access/pad surface lips reach0.441 stud: Studio must confirm jump feel. Wedges use conservative bounding envelopes, not exact triangle solids. Internal connected art joins are deliberate, not independent props. Terrain/cliff vegetation, character/objective/portal, roots and intentionally floating geography/debris are construction. Studio physics/throw arcs UNKNOWN.'
    result['preserved_tunnel_lighting_parts']=len(fixtures)
    result['method']=result['method'].replace('route widths>=18','legacy widths>=18 including tunnels' if legacy_tunnel_lights else 'surface route widths>=18; retained tunnel widths>=14')
    result['tunnel_mushroom_attachment_errors']=len(fixture_errors)
    result['scope']='Surface ground props, full physical lane audit separate. Preserved tunnel mushroom caps and ceiling-light emitters are attached construction lighting, not free ground props. Legacy mode retains the original raw classifications. Surface widths18; authored tunnel widths14. Cave decorative stem-ground contact is outside this surface planting audit.'
    if legacy_tunnel_lights:result['scope']='Raw legacy surface-only rules: attached cave-light meshes classified as free ground props; 18-stud width threshold applied to original14-stud tunnels. Kept for honest before/after comparison, not a claim of correct cave fixture classification.'
    return result

if __name__=='__main__':
    tag=sys.argv[1] if len(sys.argv)>1 else 'after'
    src=H/('round5-baseline-scene.json' if tag=='before' else 'scene.json')
    raw=src.read_bytes();report=audit(json.loads(raw));report['scene_sha256']=hashlib.sha256(raw).hexdigest()
    (O/f'ROUND5-PLACEMENT-{tag.upper()}.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({k:v for k,v in report.items() if not k.endswith('details')},indent=2))
