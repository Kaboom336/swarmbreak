"""Reused saved-place renderer, with repeating world-scale material approximations."""
from pathlib import Path
source=Path(__file__).with_name('balance-render.py').read_text()
inject=r'''
text=text.replace('def material(rgb,neon,alpha=1):','def material(rgb,neon,alpha=1,kind="Slate"):')
text=text.replace('key=tuple(rgb)+(neon,alpha)','key=tuple(rgb)+(neon,alpha,kind)')
text=text.replace("key=tuple(color)+(neon,1-p.get('transparency',0))","key=tuple(color)+(neon,1-p.get('transparency',0),p['material'])")
text=text.replace('material(key[:3],key[3],key[4])','material(key[:3],key[3],key[4],key[5])')
text=text.replace('[(0,2,3,1),(2,4,5,3),(0,1,5,4),(0,4,2),(1,3,5)]','[(1,3,2,0),(3,5,4,2),(4,5,1,0),(2,4,0),(5,3,1)]')
text=text.replace('mats[key]=m',r"""
        nt=m.node_tree;nodes=nt.nodes;links=nt.links
        coord=nodes.new('ShaderNodeTexCoord')
        if kind=='Cobblestone':
            tex=nodes.new('ShaderNodeTexBrick');tex.inputs['Scale'].default_value=.45
            tex.inputs['Brick Width'].default_value=1.35;tex.inputs['Row Height'].default_value=.7
            tex.inputs['Mortar Size'].default_value=.035;tex.inputs['Mortar Smooth'].default_value=.02
            tex.inputs['Color1'].default_value=(*c,1);tex.inputs['Color2'].default_value=(*(x*.76 for x in c),1)
            tex.inputs['Mortar'].default_value=(*(x*.43 for x in c),1)
            links.new(coord.outputs['Object'],tex.inputs['Vector']);links.new(tex.outputs['Color'],n.inputs['Base Color'])
            bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.32;bump.inputs['Distance'].default_value=.11
            links.new(tex.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],n.inputs['Normal'])
        elif kind in ('Slate','Basalt','Rock','WoodPlanks','Wood'):
            tex=nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=2.2 if kind=='WoodPlanks' else 1.4
            tex.inputs['Detail'].default_value=3
            links.new(coord.outputs['Object'],tex.inputs['Vector'])
            mix=nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=(*(x*.72 for x in c),1);mix.inputs[2].default_value=(*c,1)
            links.new(tex.outputs['Fac'],mix.inputs[0]);links.new(mix.outputs[0],n.inputs['Base Color'])
            bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.24;bump.inputs['Distance'].default_value=.065
            links.new(tex.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],n.inputs['Normal'])
            if kind in ('WoodPlanks','Wood'):
                wave=nodes.new('ShaderNodeTexWave');wave.bands_direction='X';wave.inputs['Scale'].default_value=1.8;wave.inputs['Distortion'].default_value=3
                links.new(coord.outputs['Object'],wave.inputs['Vector']);links.new(wave.outputs['Color'],bump.inputs['Height'])
        elif kind=='Metal':
            n.inputs['Metallic'].default_value=.8;n.inputs['Roughness'].default_value=.32
        elif kind=='Glass':
            n.inputs['Transmission Weight'].default_value=.32;n.inputs['Roughness'].default_value=.2
        mats[key]=m
""")
'''
source=source.replace("exec(compile(text,str(source),'exec'))",inject+"\nexec(compile(text,str(source),'exec'))")
# Use the actual geometric top view here; navigation overlays would hide seams.
source=source.replace("if not requested_views or 'top-routes' in requested_views:","if False:")
source=source.replace("render('top',(0,0,800)","render('top-routes',(0,0,800)")
source=source.replace('top-routes lines review-only','top view shows actual geometry without route overlays')
# Six close-up proof cameras, identical for the frozen before and final manifests.
source += '''
joint_views=[('joint-1',(-157,-62,20),(-150,-70,1)),
 ('joint-2',(-58,100,42),(-50,110,24)),
 ('joint-3',(29,10,40),(45,20,24)),
 ('joint-4',(-3,-41,41),(0,-25,24)),
 ('joint-5',(-82,-83,26),(-70,-65,8)),
 ('joint-6',(210,81,65),(214,98,48))]
for name,eye,target in joint_views:render(name,eye,target,ortho=32)
'''
exec(compile(source,str(Path(__file__)), 'exec'))
