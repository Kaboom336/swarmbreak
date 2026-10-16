"""Unchanged exact N8 route coverage/total/failure gates from S2."""
from pathlib import Path
H=Path(__file__).resolve().parent
source=H.parent/'S2/r4-merge-drops.py'
exec(compile(source.read_text().replace('r4-','final-'),str(source),'exec'),{'__file__':str(H/'merge-drops.py')})
