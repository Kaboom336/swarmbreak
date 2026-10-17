from pathlib import Path
source=(Path(__file__).resolve().parent.parent/'S6/merge-drops.py').read_text()
source=source.replace('final-DROPS','r34-DROPS').replace('final-drop','r34-drop')
exec(compile(source,__file__,'exec'))
