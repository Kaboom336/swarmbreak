"""Emit source patches only; selected.json is a review/build data artifact."""
import json,sys,copy
from pathlib import Path
R=Path(__file__).resolve().parent;A=R.parent
old=json.loads((R/'hand-keyed.json').read_text());new=json.loads((R/'candidates.json').read_text())
# Winner choices passed explicitly after blind review. Other library clips remain
# candidates until owner review; retain proven warning/dash gameplay tells.
choices=dict(x.split('=') for x in sys.argv[1:] if '=' in x)
selected=copy.deepcopy(old)
for name in ['idle','patrol','return','stun','celebrate']:
    selected['clips'][name]=new['clips'][name]
for name,recipe in choices.items():
    if recipe=='library':selected['clips'][name]=new['clips'][name]
selected['clips']['throw']=copy.deepcopy(selected['clips']['fan'])
(R/'selected.json').write_text(json.dumps(selected,separators=(',',':')))
if '--file' in sys.argv:
    name=sys.argv[sys.argv.index('--file')+1];path=A/name
    text=json.dumps(selected,separators=(',',':'))
    if name=='Clips.luau':
        previous=path.read_text();text=previous[:previous.index('[==[')+4]+text+previous[previous.index(']==]'):]
    print('*** Begin Patch\n*** Update File: '+str(path).replace('\\','/')+'\n@@')
    print('\n'.join('-'+l for l in path.read_text().splitlines()))
    print('\n'.join('+'+l for l in text.splitlines()))
    print('*** End Patch')
