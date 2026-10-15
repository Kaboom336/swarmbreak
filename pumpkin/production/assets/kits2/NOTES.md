# Kits2 material export

Checked the existing converter, CC0 licence notices, original manifests, source FBX/OBJ material slots and every generated FBX through Blender reimport. Best reference for this correction: the original Quaternius source material assignments (bark versus leaves), compared against the old Pine_1 export (one leaf mesh) and kits2 (trunk_wood plus leaf). Both use identical bounds and base pivot.

All 74 existing island variants are present. Original source materials stay separate; source palette atlases in Kenney can be split further by palette role. Original Meadow/Cave export colours are unchanged. Flat 8x8 PNGs embedded in each FBX preserve those colours even when Studio discards diffuse material colour. External copies live in _palette; import only the FBXs in the two island folders.

KitLibrary has only a suffix-parser compatibility addition for trunk_wood and other source-role suffixes. TextureID prevents the interim palette from overriding imported textures. Runtime IDs and mesh counts are deliberately unchanged until the second import; the kits2 ID staging array uses null IDs.

Evidence: CHECKS.json, manifest.json, _sheet.png and the per-island sheets. Studio bulk import, resulting TextureID and asset IDs remain UNKNOWN. No commit, publish or account operation.

Lesson: When a source material references an unavailable texture, use its semantic material slot to distinguish bark from leaves, because grey fallback RGB erases that distinction. When exact palette colour must survive an FBX importer, embed a flat albedo swatch because diffuse colour alone can be discarded.
