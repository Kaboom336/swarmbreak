from pathlib import Path
R=Path(__file__).resolve().parent
source=(R/'render-fx.py').read_text().split("selection=['lob'")[0]
exec(compile(source,str(R/'render-fx.py'),'exec'),globals())
for t in [.2,.495,.575,.62]:
    w=apply(sample(DATA['clips']['lob'],t));print('POSE',t,'hands',tuple(hand(w,'R')),tuple(hand(w,'L')),'socket',tuple(socket(w,'lob')))
print('LOG REST',[[list(v) for v in m] for m in logRest[:2]])
