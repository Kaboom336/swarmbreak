"""Read-only reuse of inspected Meadow manifest renderer; outputs only cave files.
Generated concept has no camera metadata. This 3/4 reconstruction is approximate.
"""
from pathlib import Path
source=Path(__file__).parents[1]/'meadow-v4/render.py'
text=source.read_text(encoding='utf8')
text=text.replace("HERE=Path(__file__).resolve().parent", "HERE=Path(__file__).resolve().parent")
text=text.replace("OUT=HERE.parents[1]/'treasure/map-v4'",'OUT=HERE')
text=text.replace('CONCEPT_EYE=(0,-460,220);CONCEPT_TARGET=(0,10,-30)','CONCEPT_EYE=(-620,-750,350);CONCEPT_TARGET=(0,0,-35)')
text=text.replace("render('side',(-390,-245,72),(0,35,-14),490)","render('side',(0,-800,-20),(0,0,-20),620)")
text=text.replace("'side_camera':{'eye':[-390,-245,72],'target':[0,35,-14],'projection':'orthographic','scale':490}","'side_camera':{'eye':[0,-800,-20],'target':[0,0,-20],'projection':'orthographic','scale':620}")
text=text.replace("render('top',(0,0,600),(0,0,0),555)","render('top',(0,0,600),(0,0,0),690)")
text=text.replace("'top_camera':{'eye':[0,0,600],'target':[0,0,0],'projection':'orthographic','scale':555}","'top_camera':{'eye':[0,0,600],'target':[0,0,0],'projection':'orthographic','scale':690}")
text=text.replace("'meadow-v4-proof.blend'","'cave-v2-proof.blend'")
text=text.replace("ambient.inputs[0].default_value=(.55,.68,.88,1)","ambient.inputs[0].default_value=(.34,.39,.62,1)")
text=text.replace("sky.inputs[0].default_value=(.17,.57,.95,1)","sky.inputs[0].default_value=(.20,.23,.36,1)")
text=text.replace("light.data.color=(1,.91,.72)","light.data.color=(.76,.82,1)")
text=text.replace("bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam",'''if data.get('stage',0)>=4:
    ambient.inputs[0].default_value=(.32,.38,.60,1)
    ambient.inputs[1].default_value=.55
    sky.inputs[0].default_value=(.017,.041,.12,1)
    for ob in bpy.data.objects:
        if ob.type=='LIGHT':
            if ob.data.type=='SUN':ob.data.energy=1.65
            else:ob.data.energy=85000;ob.data.color=(.58,.67,1)
    for item in data.get('lights',[]):
        pos=item['position']
        bpy.ops.object.light_add(type='POINT',location=(pos[0],-pos[2],pos[1]))
        ob=bpy.context.object;ob.name='NativePointLight'
        warm=item['color'][0]>240 and item['color'][2]<100
        ob.data.energy=item['brightness']*item['range']**2*(24 if warm else 10)
        ob.data.color=tuple(v/255 for v in item['color']);ob.data.shadow_soft_size=2
    scene.use_nodes=True
    nt=scene.node_tree;nt.nodes.clear()
    layers=nt.nodes.new('CompositorNodeRLayers')
    glare=nt.nodes.new('CompositorNodeGlare');glare.glare_type='FOG_GLOW';glare.quality='HIGH';glare.threshold=.6;glare.size=7;glare.mix=-.35
    output=nt.nodes.new('CompositorNodeComposite')
    nt.links.new(layers.outputs['Image'],glare.inputs['Image']);nt.links.new(glare.outputs['Image'],output.inputs['Image'])
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam''')
exec(compile(text,str(source),'exec'))
