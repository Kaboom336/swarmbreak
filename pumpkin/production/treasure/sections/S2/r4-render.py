"""Reuse identical locked cameras and materials, plus an actual background-depth mask."""
from pathlib import Path
H=Path(__file__).resolve().parent
src=(H/'render.py').read_text().replace("tag.startswith('r3-')","tag.startswith(('r3-','r4-'))")
src=src.replace("('TunnelHillEarth','TunnelRockCourse','TunnelInnerRockFacet','SolidMountainStone','R5BoulderFoot')", "('TunnelHillEarth','TunnelRockCourse','TunnelInnerRockFacet','SolidMountainStone','R5BoulderFoot','S2_ShoulderSlopeShell')")
src=src.replace("scene.view_layers[0].use_pass_object_index=True","scene.view_layers[0].use_pass_object_index=True\nscene.view_layers[0].use_pass_z=True")
src=src.replace("coverage_path=H/(tag+'-coverage.json')", """sky_mask=tree.nodes.new('CompositorNodeMath');sky_mask.operation='GREATER_THAN';sky_mask.inputs[1].default_value=2000
tree.links.new(layers.outputs['Depth'],sky_mask.inputs[0])
sky_out=tree.nodes.new('CompositorNodeOutputFile');sky_out.base_path=str(H);sky_out.format.file_format='PNG'
tree.links.new(sky_mask.outputs[0],sky_out.inputs[0])
coverage_path=H/(tag+'-coverage.json')""")
src=src.replace("out.file_slots[0].path=tag+'-'+name+'-mask-'", "out.file_slots[0].path=tag+'-'+name+'-mask-'\n    sky_out.file_slots[0].path=tag+'-'+name+'-sky-'")
exec(compile(src,str(H/'render.py'),'exec'))
