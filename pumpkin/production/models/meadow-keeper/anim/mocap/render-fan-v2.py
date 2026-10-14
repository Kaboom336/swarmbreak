"""Anonymous matched fan proofs, actual three-acorn release at .620s."""
import bpy,json,math,sys,subprocess
from pathlib import Path
R=Path(__file__).resolve().parent;A=R.parent
scope={'__file__':str(R/'render.py'),'__name__':'preview'}
exec((R/'render.py').read_text().split('old=json.loads')[0],scope)
globals().update({k:v for k,v in scope.items() if k not in ('__file__','__name__')})
scene.render.resolution_x=320;scene.render.resolution_y=320
camera.data.ortho_scale=22
for obj in trailpieces:obj.hide_render=True
log.hide_render=True
acorns=[acorn];pieces=[acornpieces]
for i in range(2):
    parent=acorn.copy();scene.collection.objects.link(parent);acorns.append(parent);children=[]
    for child in acornpieces:
        obj=child.copy();scene.collection.objects.link(obj);obj.parent=parent;children.append(obj)
    pieces.append(children)
D=json.loads((R/'fan-v2-candidates.json').read_text());FF=A.parents[2]/'concepts/refs3/_tools/ffmpeg.exe'
def showfan(t,w,release):
    for i,o in enumerate(acorns):
        visible=(i==1 if t<.62 else t<1.3)
        for child in pieces[i]:child.hide_render=not visible
        if t<.62:p=hand(w,'R')
        else:
            u=min(1,(t-.62)/.7);dest=release+Matrix.Rotation(math.radians((-16,0,16)[i]),3,'Y')@(Vector((0,2,24))-release)
            p=release.lerp(dest,u)+Vector((0,3*u*(1-u),0))
        o.location=BI@p;o.rotation_euler.x=max(0,t-.62)*18
    bpy.context.view_layer.update()
for id in ['M','Q','T']:
    if '--only' in sys.argv and id!=sys.argv[sys.argv.index('--only')+1]:continue
    clip=D[id];duration=clip['duration'];release=hand(apply(sample(clip,.62)),'R')
    times=[0,.2,.42,.52,.62,.72,.84,1.02,duration]
    for i,t in enumerate(times):
        w=apply(sample(clip,t));showfan(t,w,release)
        scene.render.filepath=str(OUT/f'fan-v2-{id}-pose-{i:02d}.png');bpy.ops.render.render(write_still=True)
    count=math.ceil(duration*24)+1
    for i in range(count):
        t=min(duration,i/24);w=apply(sample(clip,t));showfan(t,w,release)
        scene.render.filepath=str(OUT/f'fan-v2-{id}-{i:03d}.png');bpy.ops.render.render(write_still=True)
    subprocess.run([str(FF),'-y','-loglevel','error','-framerate','24','-i',str(OUT/f'fan-v2-{id}-%03d.png'),'-vf','split[a][b];[a]palettegen[p];[b][p]paletteuse','-loop','0',str(OUT/f'fan-v2-{id}.gif')],check=True)
    subprocess.run([str(FF),'-y','-loglevel','error','-i',str(OUT/f'fan-v2-{id}-pose-%02d.png'),'-vf','scale=180:180,tile=9x1','-frames:v','1',str(OUT/f'fan-v2-{id}-strip.jpg')],check=True)
    subprocess.run([str(FF),'-y','-loglevel','error','-i',str(OUT/f'fan-v2-{id}-%03d.png'),'-vf','scale=160:160,tile=8x5','-frames:v','1',str(OUT/f'fan-v2-{id}-motion.jpg')],check=True)
    print('PROOF',id,flush=True)
args=[str(FF),'-y','-loglevel','error']
for id in ['Q','T','M']:args+=['-i',str(OUT/f'fan-v2-{id}-strip.jpg')]
subprocess.run(args+['-filter_complex','vstack=inputs=3','-frames:v','1',str(OUT/'fan-v2-blind.jpg')],check=True)
