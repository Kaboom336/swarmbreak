from pathlib import Path
source=Path('treasure/sections/S2/r4-merge-drops.py')
exec(compile(source.read_text().replace('r4-', 'close-'),str(source),'exec'))
