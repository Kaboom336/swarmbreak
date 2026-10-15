"""Document the future Studio ID manifest while preserving the live kits ID array."""
import json, hashlib
from pathlib import Path
root = Path.cwd()
folder = root/'assets/kits2'
exports = json.loads((folder/'manifest.json').read_text())['exports']
notes = {
    'kits2Manifest': 'assets/kits2/ROBLOX-ASSETS.json is an ID-null staging array; Claude fills new MODEL asset IDs after Studio import. Never copy old IDs into it.',
    'format': 'Keep the runtime manifest a JSON array of {id, name, island, meshParts, size, triangles}; optional _formatNotes is metadata on an entry, never an extra array row.',
    'name': 'name stays <kit>__<model>; strip the __<island> filename suffix. island remains meadow or cave.',
    'id': 'Use the grouped Model asset ID containing every material MeshPart, not an individual mesh/image ID.',
    'meshParts': 'Use the actual imported MeshPart count, matching kits2/manifest.json meshParts; source-material meshes must not be merged. Pine_1 now has two.',
    'materials': 'Mesh names are <kit>__<model>__<island>_<material>; trunk_wood ends in wood. Each source material is separate, with one palette material and embedded 8x8 PNG per palette role.',
    'palette': 'Original assets/kits exporter palettes retained. TextureID preserves exact albedo; KitLibrary still supplies interim fallback colours if textures are absent.',
    'geometry': 'Same 1/0.28 conversion, Y-up FBX, shared bounding-box base pivot and original size extents; size order X,Y,Z in studs.',
    'integration': 'After filling IDs, update the runtime and Rojo manifests together and make the build helper read kits2/manifest.json for triangle provenance. Current kits IDs remain active.',
    'status': 'Offline FBX reimport PASS. Studio bulk import, TextureID and grouped Model IDs UNKNOWN until Claude/Zion checks.'
}
path = root/'assets/kits/ROBLOX-ASSETS.json'
text = path.read_text()
live = json.loads(text)
if '_formatNotes' not in live[0]:
    # Preserve all original IDs and row bytes; add optional metadata only.
    text = text.replace('[{', '[{"_formatNotes":'+json.dumps(notes,ensure_ascii=True)+',', 1)
    path.write_text(text)
updated = json.loads(path.read_text())
assert [{k:v for k,v in e.items() if k!='_formatNotes'} for e in updated]==[{k:v for k,v in e.items() if k!='_formatNotes'} for e in live]
pending = [dict(id=None,name=e['pack']+'__'+e['name'],island=e['island'],
    meshParts=e['meshParts'],size=e['sizeStuds'],triangles=e['triangles']) for e in exports]
pending[0]['_formatNotes'] = notes
(folder/'ROBLOX-ASSETS.json').write_text(json.dumps(pending,indent=2)+'\n')
(folder/'NOTES.md').write_text('''# Kits2 material export

Checked the existing converter, CC0 licence notices, original manifests, source FBX/OBJ material slots and every generated FBX through Blender reimport. Best reference for this correction: the original Quaternius source material assignments (bark versus leaves), compared against the old Pine_1 export (one leaf mesh) and kits2 (trunk_wood plus leaf). Both use identical bounds and base pivot.

All 74 existing island variants are present. Original source materials stay separate; source palette atlases in Kenney can be split further by palette role. Original Meadow/Cave export colours are unchanged. Flat 8x8 PNGs embedded in each FBX preserve those colours even when Studio discards diffuse material colour. External copies live in _palette; import only the FBXs in the two island folders.

KitLibrary has only a suffix-parser compatibility addition for trunk_wood and other source-role suffixes. TextureID prevents the interim palette from overriding imported textures. Runtime IDs and mesh counts are deliberately unchanged until the second import; the kits2 ID staging array uses null IDs.

Evidence: CHECKS.json, manifest.json, _sheet.png and the per-island sheets. Studio bulk import, resulting TextureID and asset IDs remain UNKNOWN. No commit, publish or account operation.

Lesson: When a source material references an unavailable texture, use its semantic material slot to distinguish bark from leaves, because grey fallback RGB erases that distinction. When exact palette colour must survive an FBX importer, embed a flat albedo swatch because diffuse colour alone can be discarded.
''')
print('PASS live ID rows preserved; kits2 ID staging and format notes written')
