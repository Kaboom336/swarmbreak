"""Reuse the CC0 kit converter, retaining source material boundaries and palette textures."""
import struct, zlib
from collections import defaultdict
from pathlib import Path
exec(Path(__file__).with_name('export-kits.py').read_text().split('OUT.mkdir(parents=True,exist_ok=True)')[0])
OUT = ROOT / 'assets/kits2'
OUT.mkdir(parents=True, exist_ok=True)

def swatch(kind, island):
    """Embedded flat albedo also preserves exact palette when Studio ignores diffuse colour."""
    folder = OUT / '_palette'
    folder.mkdir(exist_ok=True)
    path = folder / (island + '_' + kind + '.png')
    rgb = bytes(PALETTES[island][kind])
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 8, 8, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress((b'\0' + rgb * 8) * 8)) + chunk(b'IEND', b''))
    m = material(kind, island)
    node = m.node_tree.nodes.get('Palette') or m.node_tree.nodes.new('ShaderNodeTexImage')
    node.name = 'Palette'
    node.image = bpy.data.images.load(str(path), check_existing=True)
    m.node_tree.links.new(node.outputs['Color'], m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    return m

def convert2(entry):
    reset()
    island = entry['island']
    source = VENDOR / entry['actualSource']
    if source.suffix == '.obj':
        bpy.ops.wm.obj_import(filepath=str(source), forward_axis='NEGATIVE_Z', up_axis='Y')
    else:
        bpy.ops.import_scene.fbx(filepath=str(source))
    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    points = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    low = Vector(tuple(min(v[i] for v in points) for i in range(3)))
    high = Vector(tuple(max(v[i] for v in points) for i in range(3)))
    base = Vector(((low.x + high.x)/2, (low.y + high.y)/2, low.z))
    groups = defaultdict(lambda: {'verts': [], 'faces': []})
    for o in objs:
        for face in o.data.polygons:
            mat = o.data.materials[face.material_index] if o.data.materials else None
            source_name = re.sub(r'\.\d+$', '', mat.name) if mat else 'unassigned'
            # Quaternius albedo references are missing from FBX folders; semantic source
            # materials are authoritative. Never infer bark/leaf from grey fallback RGB.
            if entry['pack'] == 'quaternius-nature':
                n = source_name.lower()
                if 'bark' in n: role = 'wood'
                elif 'lea' in n or 'grass' in n: role = 'leaf'
                elif 'flower' in n or 'mushroom' in n: role = 'flower'
                elif 'rock' in n or 'stone' in n: role = 'stone'
                else: raise ValueError(('Unknown source material', entry['name'], source_name))
            else:
                n = source_name.lower()
                if 'wood' in n: role = 'wood'
                elif 'leaf' in n or 'leaves' in n or 'grass' in n: role = 'leaf'
                elif 'stone' in n or 'dirt' in n: role = 'stone'
                else: role = face_kind(o, face, entry['use'])
            g = groups[(source_name, role)]
            offset = len(g['verts'])
            g['verts'].extend(tuple((o.matrix_world @ o.data.vertices[i].co - base)*SCALE) for i in face.vertices)
            g['faces'].append(tuple(range(offset, offset + len(face.vertices))))
    for o in objs: bpy.data.objects.remove(o, do_unlink=True)
    stem = entry['pack'] + '__' + entry['name']
    stats = []
    for (source_name, role), g in sorted(groups.items()):
        token = 'trunk_wood' if 'bark' in source_name.lower() else role
        # Keep distinct source materials separate even when their palette role agrees.
        if sum(r == role for _, r in groups) > 1:
            token = re.sub(r'[^a-z0-9]+', '_', source_name.lower()).strip('_') + '_' + role
        name = stem + '__' + island + '_' + token
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(g['verts'], [], g['faces'])
        mesh.update()
        o = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(o)
        mesh.materials.append(swatch(role, island))
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.remove_doubles(threshold=0.000001)
        bpy.ops.mesh.quads_convert_to_tris(quad_method='BEAUTY', ngon_method='BEAUTY')
        bpy.ops.object.mode_set(mode='OBJECT')
        assert len(mesh.polygons) < 10000, (name, 'triangle budget')
        uv = mesh.uv_layers.new(name='PaletteUV')
        for loop in uv.data: loop.uv = (.5, .5)
        stats.append(dict(mesh=name, sourceMaterial=source_name, material=island+'_'+role,
                          colour=list(PALETTES[island][role]), triangles=len(mesh.polygons),
                          texture='_palette/'+island+'_'+role+'.png'))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes: o.select_set(True)
    folder = OUT / island
    folder.mkdir(exist_ok=True)
    # Island in filename prevents same-name assets colliding during the second import.
    target = folder / (stem + '__' + island + '.fbx')
    bpy.ops.export_scene.fbx(filepath=str(target), use_selection=True, object_types={'MESH'},
        axis_forward='-Z', axis_up='Y', apply_unit_scale=True, apply_scale_options='FBX_SCALE_ALL',
        bake_space_transform=True, add_leaf_bones=False, use_mesh_modifiers=True,
        path_mode='COPY', embed_textures=True)
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'MATERIAL'
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.world.color = (.08,.09,.12)
    span = (high-low)*SCALE
    radius = max(span.length/2, .3)
    center = Vector((0,0,span.z/2))
    data = bpy.data.cameras.new('Preview')
    cam = bpy.data.objects.new('Preview', data)
    scene.collection.objects.link(cam)
    cam.location = center+Vector((1.4,-1.8,1.1)).normalized()*radius*3
    cam.rotation_euler = (center-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = radius*2.5
    scene.camera = cam
    scene.render.resolution_x = scene.render.resolution_y = 256
    scene.render.resolution_percentage = 100
    thumbs = OUT/'_thumbs'
    thumbs.mkdir(exist_ok=True)
    scene.render.image_settings.file_format = 'PNG'
    scene.render.filepath = str(thumbs/(island+'__'+stem+'.png'))
    bpy.ops.render.render(write_still=True)
    result = {k:v for k,v in entry.items() if k not in ('meshes','output')}
    result.update(output=target.relative_to(ROOT).as_posix(), meshes=stats,
                  meshParts=len(stats), triangles=sum(s['triangles'] for s in stats))
    return result

original = json.loads((ROOT/'assets/kits/manifest.json').read_text())
exports = [convert2(e) for e in original['exports']]
(OUT/'manifest.json').write_text(json.dumps(dict(formatVersion=2, metresToStuds=SCALE,
    axisUp='Y', palettes=PALETTES, exports=exports), indent=2)+'\n')
(OUT/'IMPORT.md').write_text('Drag assets/kits2/meadow/ and assets/kits2/cave/ into Studio > Asset Manager > Bulk Import.\n')
for p in (ROOT/'assets/kits').glob('LICENSE-*.txt'):
    (OUT/p.name).write_bytes(p.read_bytes())
print('PASS kits2 exports',len(exports),'material meshes',sum(e['meshParts'] for e in exports))
