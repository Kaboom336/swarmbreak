"""Reuse repository native renderer, with fixed summit player-height cameras."""
from pathlib import Path
source=Path(__file__).resolve().parent.parent/'S6/render.py'
code=source.read_text()
start=code.index('views=[');end=code.index("(H/'CAMERAS.json')",start)
code=code[:start]+'''views=[
 dict(name='arrival',eye=[28,53,-108],target=[-1,53,-97],lens=24),
 dict(name='acorn',eye=[5,53,-89],target=[-1,53,-97],lens=24),
 dict(name='escape-spiral',eye=[30,53,-116],target=[21,43,-137],lens=24),
 dict(name='escape-shelf',eye=[29,53,-108],target=[65,44,-108],lens=24),
 dict(name='overview',eye=[-66,107,-52],target=[0,48,-105],lens=30)]
'''+code[end:]
exec(compile(code,__file__,'exec'))
