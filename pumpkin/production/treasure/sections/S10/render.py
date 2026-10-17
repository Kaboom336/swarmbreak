from pathlib import Path
import sys
H=Path(__file__).resolve().parent
source=(H.parent/'S9/render.py').read_text()
source=source.replace("views=[dict(name='spawn'", "views=[dict(name='spawn'")
start=source.index('views=[');end=source.index("\n(H/'CAMERAS.json')",start)
source=source[:start]+"views=[dict(name='walk',eye=[0,6,-80],target=[0,21,-145],lens=19),dict(name='open',eye=[0,9,39],target=[0,17,0],lens=23),dict(name='locked',eye=[-66,16.7,-117],target=[-66,22,-145],lens=19),dict(name='overview',eye=[155,160,60],target=[0,8,-92],lens=23),dict(name='pen',eye=[-25,9,46],target=[-61,5,32],lens=24)]"+source[end:]
# Proxy exports carry exact strings, with no invented arrow prefix.
source=source.replace("o.data.body='>  '+p['label']", "o.data.body=p['label']")
source=source.replace("o.data.size=64/48", "o.data.size=p.get('labelSize',64/48)")
source=source.replace("v=Vector(p['position'])+r@Vector((0,0,", "v=Vector(p['position'])+r@Vector((0,p.get('attributes',{}).get('S10LabelLift',0),")
exec(compile(source,str(H/'render.py'),'exec'))
