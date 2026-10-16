"""Reuse inspected local section renderer/audits; no external dependency."""
from pathlib import Path
H=Path(__file__).resolve().parent
s=(H.parent/'S4/render.py').read_text().replace('S4','S5').replace('s4_geometry','s5_geometry')
a=s.index('views=[');b=s.index("(H/'CAMERAS.json')",a)
s=s[:a]+'''views=[
 dict(name='base',eye=[110,7,-18],target=[110,19,51],lens=24),
 dict(name='mid-bypass',eye=[128.8,27,29],target=[148,25,0],lens=24),
 dict(name='jump',eye=[148,27,10],target=[148,28,54],lens=24),
 dict(name='overview',eye=[244,150,192],target=[112,17,22],lens=34)]
'''+s[b:]
(H/'render.py').write_text(s)
s=(H.parent/'S2/contact.py').read_text().replace("!='S2'","!='S5'").replace("=='S2'","=='S5'").replace('S2 metadata','S5 metadata')
s=s.replace("data=json.loads((H/(tag+'.json')).read_text())","data=json.loads((H/(tag+'.json')).read_text());data['kits']=[]")
(H/'contact.py').write_text(s)
s=(H.parent/'S4/drop.luau').read_text().replace('S4','S5');(H/'drop.luau').write_text(s)
s=(H.parent/'S4/contracts.luau').read_text().replace('S4','S5').replace('Section4','Section5');(H/'contracts.luau').write_text(s)
s=(H.parent/'S4/merge-drops.py').read_text();(H/'merge-drops.py').write_text(s)
