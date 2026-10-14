"""Read the approved external animation data; never execute vendor code."""
import bpy, json
from pathlib import Path
R=Path(__file__).resolve().parent
P=Path('C:/dev/codex-lab/vendor/quaternius-ual/Universal Animation Library[Standard]')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(P/'Unreal-Godot/UAL1_Standard.glb'))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
data={'bones':[{'name':b.name,'parent':b.parent.name if b.parent else None,'head':list(b.head_local),'tail':list(b.tail_local)} for b in rig.data.bones], 'actions':[{'name':a.name,'range':list(a.frame_range)} for a in bpy.data.actions], 'fps':bpy.context.scene.render.fps}
(R/'inventory.json').write_text(json.dumps(data,indent=2))
print(json.dumps(data),flush=True)
