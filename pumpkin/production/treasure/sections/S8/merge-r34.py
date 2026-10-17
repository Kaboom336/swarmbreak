from pathlib import Path
source=Path(__file__).resolve().parent.parent/'S6/merge-drops.py'
exec(compile(source.read_text().replace('final','r34'),__file__,'exec'))
