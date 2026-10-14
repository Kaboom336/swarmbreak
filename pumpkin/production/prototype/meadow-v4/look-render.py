"""Matched offline native geometry comparisons, not Roblox lighting simulation."""
import os, sys, runpy, json, hashlib
from pathlib import Path
H=Path(__file__).parent
tag=sys.argv[sys.argv.index('--')+1]
os.environ['LOOK_MANIFEST']='look-baseline-scene.json' if tag=='before' else 'scene.json'
sys.argv=[str(H/'render.py'),'--','look-'+tag,'SKIP']
R=runpy.run_path(str(H/'render.py'))
R['requested_views'].clear();R['requested_views'].update(['look-three-quarter','look-hill'])
scene=R['scene'];scene.render.resolution_x=1200;scene.render.resolution_y=800;scene.cycles.samples=12
R['render']('look-three-quarter',(-340,-360,285),(0,0,8),560)
R['render']('look-hill',(-205,112,158),(-76,-30,23),210)
(R['OUT']/('LOOK-RENDER-'+tag.upper()+'.json')).write_text(json.dumps({'source':'Actual shared native manifest; matched Cycles proxy lighting in both views; Roblox Atmosphere and post effects require Studio A/B','manifest_sha256':hashlib.sha256(R['manifest_bytes']).hexdigest(),'parts':len(R['data']['parts']),'tag':tag},indent=2))
