"""Blender reimport audit: generated FBX geometry, units, material count and pivot."""
import bpy,json,re
from pathlib import Path
from mathutils import Vector
root=Path.cwd()
manifest=json.loads((root/"assets/kits/manifest.json").read_text())
results=[]
for e in manifest["exports"]:
 bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=str(root/e["output"]))
 meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
 assert len(meshes)==len(e["meshes"]),(e["output"],"mesh count")
 points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 lo=[min(v[i] for v in points) for i in range(3)]
 hi=[max(v[i] for v in points) for i in range(3)]
 span=[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]]
 assert abs(lo[2])<.002,(e["output"],"base",lo)
 for got,want in zip(span,e["sizeStuds"]):assert abs(got-want)<.002,(e["output"],"scale",span,e["sizeStuds"])
 for o in meshes:
  assert len(o.data.materials)==1,(o.name,"materials")
  assert all(len(p.vertices)==3 for p in o.data.polygons),(o.name,"non triangles")
  assert len(o.data.polygons)<10000,(o.name,"tri budget")
  assert o.location.length<.002,(o.name,"shared origin")
  assert all(abs(v-1)<.00001 for v in o.scale),(o.name,"unapplied scale",list(o.scale))
  materialName=re.sub(r"\.\d+$","",o.data.materials[0].name)
  expected=next(s for s in e["meshes"] if s["material"]==materialName)["colour"]
  actual=o.data.materials[0].diffuse_color[:3]
  assert all(abs(v-w/255)<.003 for v,w in zip(actual,expected)),(o.name,"palette")
 results.append({"file":e["output"],"meshes":len(meshes),"triangles":sum(len(o.data.polygons) for o in meshes)})
(root/"assets/kits/CHECKS.json").write_text(json.dumps({"status":"PASS","exports":len(results),
 "checks":["FBX reimport","scale extents","base pivot","triangulated","under 10k triangles per mesh","single material","palette","applied scale"],"models":results},indent=2))
print("PASS reimport",len(results),"FBX models")
