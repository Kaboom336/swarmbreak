"""Emit complete per-type handoff ledger from the checked native inventories."""
import json,re
from pathlib import Path
data=json.loads(Path("prototype/KITS-OFFLINE.json").read_text())
def assignment(island,name):
 n=name.lower()
 if island=="meadow":
  if re.search(r"(lookhill|tunnelhill|r5oak).*tree|r5oak",n):return "kenney_nature-kit__tree_oak","whole tree assembly"
  if "bush" in n:return "kenney_nature-kit__plant_bush","whole bush assembly"
  if "flower" in n:return "kenney_nature-kit__flower_yellowA","whole flower assembly"
  if "mushroom" in n:return "quaternius-nature__Mushroom_Common","whole mushroom; retain glow"
  if "boulder" in n or n=="lookrockfragment":return "kenney_nature-kit__rock_largeA","decorative assembly; retain collider"
  if n.startswith("r5fence"):return "kenney_nature-kit__fence_simple","whole bay; fit endpoints"
  if n in ("bridgeguardbeam","bridgetimberplank") or n=="r5bridgeguardbeam":return "kenney_nature-kit__bridge_wood","candidate dressing; keep playable carrier"
  if n in ("lookskylightoutcrop","looklightrocktop","round4palerocktop","round4shelflightfacet"):return "quaternius-nature__Rock_Medium_1","skin only; protect opening/clearance"
 else:
  if n.startswith("connect"):return "KEEP custom","fitted CONNECT joint/contact profile"
  if "crate" in n:return "kenney_survival-kit__box-large","whole crate including bands"
  if n in ("floatingrock",):return "quaternius-nature__Rock_Medium_1","decorative skin"
  if n in ("cavearchstone","cavearchvoussoir","tunnelarchpier","tunnelarchvoussoir"):return "kenney_mini-dungeon__wall-opening","whole arch; preserve opening"
  if n in ("cavemouthtimber","cavemouthlintel","campshelterbeam","campsheltertimber","cliffscaffoldbrace","cliffscaffoldpost","cliffscaffoldshelf","cartstationtimber"):return "kenney_mini-dungeon__wood-support","whole timber assembly"
  if n in ("campshelterroof","stationroof"):return "kenney_survival-kit__tent","whole shelter candidate; retain roof collider"
  if n=="tinymoss":return "kenney_nature-kit__plant_bush","low decorative accent"
 return "KEEP custom","gameplay, fitted terrain/route, focal art or no matching kit"
lines=["","## Complete saved prop-type ledger","","Every saved BasePart name is assigned below. Route segment digits and CONNECT facet suffixes are collapsed into types; exact saved names remain in KITS-OFFLINE.json. KEEP covers protected custom geometry and types with no suitable exported kit. Candidate mappings are not automatic authorization to replace a collider.","","| Island | Saved type/name family | Kit | Replacement unit / protection |","|---|---|---|---|"]
for place in data["places"]:
 if "guardian" in place["file"]:continue
 island="meadow" if "meadow" in place["file"] else "cave"
 families={}
 for name in place["propNames"]:
  typ=re.sub(r":.*$","*",name) if name.startswith("ConnectSurface_") else re.sub(r"\d+$","*",name)
  families.setdefault(typ,assignment(island,name))
 for typ,(model,rule) in sorted(families.items()):lines.append(f"| {island} | {typ} | {model} | {rule} |")
print(json.dumps("\n".join(lines)+"\n"))
