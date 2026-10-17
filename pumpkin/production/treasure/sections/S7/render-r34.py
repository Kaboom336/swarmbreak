from pathlib import Path
p=Path(__file__).resolve().parent
code=(p/'render.py').read_text()
code=code.replace("exec(compile(code,__file__,'exec'))", "code=code.replace(\"H/(tag+'.json')\",\"H/(tag+'-visual.json')\")\nexec(compile(code,__file__,'exec'))")
exec(compile(code,__file__,'exec'))
