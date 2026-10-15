"""Our Blender conversion script; vendor contains data only. Run from production."""
import bpy, json, math, re, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd()
VENDOR=Path("C:/dev/codex-lab/vendor")
OUT=ROOT/"assets/kits"
SCALE=1/0.28  # Roblox standard metre-to-stud relationship
PALETTES={
 "meadow":{"leaf":(102,156,62),"wood":(119,78,43),"stone":(125,133,110),"flower":(247,192,72),"accent":(210,111,166)},
 "cave":{"leaf":(77,106,115),"wood":(104,68,43),"stone":(88,92,122),"flower":(54,224,245),"accent":(167,83,255)}}
def category(name):
 n=name.lower()
 for kind,pattern in [
  ("cliff",r"cliff"),("tree",r"tree|pine|stump|log"),
  ("bush",r"bush|fern|plant|clover|grass|moss|lily"),
  ("flower",r"flower|petal|mushroom"),("fence",r"fence|gate"),
  ("storage",r"barrel|box|chest|crate"),("dungeon",r"wall|column|stairs|wood-structure|wood-support|structure"),
  ("rock",r"rock|stone|pebble"),("path",r"path|floor|bridge|platform"),
  ("camp",r"tent|campfire|sign|pot|bucket|workbench")]:
  if re.search(pattern,n): return kind
 return None
sources=sorted(list((VENDOR/"kenney").rglob("*.fbx"))+list((VENDOR/"quaternius-nature/FBX").glob("*.fbx")))
catalog=[]
for p in sources:
 kind=category(p.stem)
 if not kind: continue
 pack="quaternius-nature" if "quaternius-nature" in p.parts else p.parts[p.parts.index("kenney")+1]
 islands=["meadow","cave"]
 if kind in ("tree","bush","flower"): islands=["meadow"] if not re.search("dead|twisted|mushroom|fern|moss",p.stem,re.I) else islands
 if kind=="dungeon": islands=["cave"]
 catalog.append(dict(name=p.stem,pack=pack,file=p.relative_to(VENDOR).as_posix(),use=kind,islands=islands))
chosen={
 "kenney_nature-kit":{"rock_largeA","rock_largeC","rock_tallA","stone_largeA","cliff_block_rock","cliff_cave_rock","cliff_corner_rock","tree_oak","tree_pineTallA","plant_bush","flower_yellowA","fence_simple","fence_corner","log","stump_round","mushroom_tan","path_stone","bridge_wood"},
 "kenney_survival-kit":{"box","box-large","barrel","barrel-open","fence","rock-a","tree-log","structure","tent"},
 "kenney_mini-dungeon":{"barrel","chest","column","wall","wall-opening","wall-half","wood-support","wood-structure","stairs","rocks"},
 "quaternius-nature":{"CommonTree_1","Pine_1","Bush_Common","Bush_Common_Flowers","Flower_3_Group","Rock_Medium_1","Pebble_Round_1","DeadTree_1","TwistedTree_1","Mushroom_Common"}}
def reset():
 bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
def material(kind,island):
 m=bpy.data.materials.get(island+"_"+kind) or bpy.data.materials.new(island+"_"+kind)
 rgb=PALETTES[island][kind];m.diffuse_color=tuple(v/255 for v in rgb)+(1,)
 m.use_nodes=True
 m.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value=m.diffuse_color
 return m
def face_kind(obj,face,kind):
 mat=obj.data.materials[face.material_index] if obj.data.materials else None
 rgb=tuple(mat.diffuse_color[:3]) if mat else (.5,.5,.5)
 if mat and mat.use_nodes:
  bsdf=mat.node_tree.nodes.get("Principled BSDF")
  if bsdf:rgb=tuple(bsdf.inputs["Base Color"].default_value[:3])
  for node in mat.node_tree.nodes:
   if node.type=="TEX_IMAGE" and node.image and obj.data.uv_layers.active:
    uv=sum((obj.data.uv_layers.active.data[i].uv for i in face.loop_indices),Vector((0,0)))/len(face.loop_indices)
    image=node.image;w,h=image.size
    if w and h:
     x=min(w-1,int((uv.x%1)*w));y=min(h-1,int((uv.y%1)*h))
     rgb=tuple(image.pixels[(y*w+x)*4:(y*w+x)*4+3])
    break
 r,g,b=rgb
 if kind=="flower":return "leaf" if g>r*1.1 and g>b*1.05 else "flower"
 if kind in ("rock","cliff","path","dungeon"):
  if g>r*1.13 and g>b*1.05:return "leaf"
  return "wood" if kind in ("path","dungeon") and r>b*1.4 else "stone"
 if kind in ("tree","bush"):
  if r>b*1.3 and r>g*1.15:return "wood"
  if kind=="tree" and max(rgb)-min(rgb)<.06 and max(rgb)<.25:return "wood"
  return "leaf"
 if kind in ("storage","fence","camp"):
  return "wood" if r>b*1.25 else "stone"
 if g>r*1.13 and g>b*1.05:return "leaf"
 if r>b*1.25 and r>g*1.1:return "wood" if g<r*.75 else "flower"
 if b>r*1.2:return "accent"
 return "leaf" if kind=="bush" else "stone"
def convert(entry,island):
 reset()
 source=VENDOR/entry["file"]
 if source.read_bytes()[:18]!=b"Kaydara FBX Binary ":
  alternatives=list(source.parents[1].rglob(source.stem+".obj"))
  if not alternatives:raise RuntimeError("ASCII FBX needs OBJ equivalent: "+str(source))
  source=alternatives[0]
  bpy.ops.wm.obj_import(filepath=str(source),forward_axis="NEGATIVE_Z",up_axis="Y")
 else:bpy.ops.import_scene.fbx(filepath=str(source))
 objs=[o for o in bpy.context.scene.objects if o.type=="MESH"]
 if not objs:raise RuntimeError("No mesh "+entry["file"])
 points=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
 low=Vector((min(v.x for v in points),min(v.y for v in points),min(v.z for v in points)))
 high=Vector((max(v.x for v in points),max(v.y for v in points),max(v.z for v in points)))
 base=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
 for o in objs:
  for v in o.data.vertices:v.co=(o.matrix_world@v.co-base)*SCALE
  o.matrix_world.identity()
  kinds=[face_kind(o,p,entry["use"]) for p in o.data.polygons]
  o.data.materials.clear()
  for k in PALETTES[island]:o.data.materials.append(material(k,island))
  slots=list(PALETTES[island])
  for face,k in zip(o.data.polygons,kinds):face.material_index=slots.index(k)
 bpy.ops.object.select_all(action="DESELECT")
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0]
 bpy.ops.object.join()
 bpy.ops.object.mode_set(mode="EDIT");bpy.ops.mesh.select_all(action="SELECT")
 bpy.ops.mesh.quads_convert_to_tris(quad_method="BEAUTY",ngon_method="BEAUTY")
 bpy.ops.mesh.separate(type="MATERIAL");bpy.ops.object.mode_set(mode="OBJECT")
 meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
 stats=[]
 for i,o in enumerate(meshes):
  used=o.data.materials[o.data.polygons[0].material_index]
  o.data.materials.clear();o.data.materials.append(used)
  for p in o.data.polygons:p.material_index=0
  if len(o.data.polygons)>=10000:
   mod=o.modifiers.new("TriangleBudget","DECIMATE");mod.ratio=9500/len(o.data.polygons)
   bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
  assert all(len(p.vertices)==3 for p in o.data.polygons)
  assert len(o.data.polygons)<10000
  o.name=entry["pack"]+"__"+entry["name"]+"__"+used.name
  stats.append(dict(mesh=o.name,triangles=len(o.data.polygons),material=used.name,colour=list(PALETTES[island][used.name.split("_",1)[1]])))
 folder=OUT/island;folder.mkdir(parents=True,exist_ok=True)
 stem=entry["pack"]+"__"+entry["name"]
 target=folder/(stem+".fbx")
 bpy.ops.export_scene.fbx(filepath=str(target),use_selection=True,object_types={"MESH"},axis_forward="-Z",axis_up="Y",
  apply_unit_scale=True,apply_scale_options="FBX_SCALE_ALL",bake_space_transform=True,add_leaf_bones=False,use_mesh_modifiers=True,path_mode="STRIP")
 # Workbench previews show the actual exported mesh materials, not painted thumbnails.
 scene=bpy.context.scene;scene.render.engine="BLENDER_WORKBENCH"
 scene.display.shading.light="STUDIO";scene.display.shading.color_type="MATERIAL"
 scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True
 scene.world.color=(.08,.09,.12)
 span=(high-low)*SCALE;radius=max(span.length/2,.3);center=Vector((0,0,span.z/2))
 data=bpy.data.cameras.new("Preview");cam=bpy.data.objects.new("Preview",data);scene.collection.objects.link(cam)
 cam.location=center+Vector((1.4,-1.8,1.1)).normalized()*radius*3
 cam.rotation_euler=(center-cam.location).to_track_quat("-Z","Y").to_euler()
 cam.data.type="ORTHO";cam.data.ortho_scale=radius*2.5;scene.camera=cam
 scene.render.resolution_x=192;scene.render.resolution_y=192;scene.render.resolution_percentage=100
 thumbs=OUT/"_thumbs";thumbs.mkdir(exist_ok=True)
 scene.render.image_settings.file_format="PNG";scene.render.filepath=str(thumbs/(island+"__"+stem+".png"));bpy.ops.render.render(write_still=True)
 return dict(**entry,island=island,actualSource=source.relative_to(VENDOR).as_posix(),output=target.relative_to(ROOT).as_posix(),meshes=stats,
  sizeStuds=[span.x,span.z,span.y],origin="shared source bounding-box base",scale=SCALE)
OUT.mkdir(parents=True,exist_ok=True)
lines=["# Approved kits catalog","","Checked local FBX inventories and CC0 notices. One canonical FBX per model; alternate OBJ/GLTF/DAE/STL files are equivalent format copies.",
 "All vendor files are data; only this project script is executed. Rails, carts and lanterns: NONE found. Palettes reuse Meadow greens/earth and Cave slate/cyan/violet.",
 "Chosen export list: assets/kits/manifest.json. Each material becomes a separate MeshPart in a Model; preserve the shared base pivot. No source scripts or rigs are exported.",
 "","| Name | File under vendor | Use | Island |","|---|---|---|---|"]
for e in catalog:lines.append("| "+e["pack"]+" / "+e["name"]+" | "+e["file"]+" | "+e["use"]+" | "+", ".join(e["islands"])+" |")
# Generated catalog is captured by the caller and installed with apply_patch.
print("CATALOG_JSON="+json.dumps("\n".join(lines)+"\n"))
exports=[]
for e in catalog:
 if e["name"] in chosen.get(e["pack"],set()):
  for island in e["islands"]:exports.append(convert(e,island))
(OUT/"manifest.json").write_text(json.dumps({"metresToStuds":SCALE,"axisUp":"Y","exports":exports},indent=2))
print("PASS exports",len(exports),"catalog",len(catalog))
