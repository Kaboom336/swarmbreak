"""Publish local evidence only after a passing final contact audit."""
import json, hashlib
from pathlib import Path
H=Path(__file__).parent;ROOT=H.parents[2]
read=lambda name:json.loads((H/name).read_text())
contact=read('r3-physical-contact.json')
assert not any(contact[key] for key in ['physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies'])
coverage=read('r3-coverage.json');audit=read('AUDIT.json')
out={'round':'S1 R3','acceptance':'FAIL: coverage and full camera-distance goals unmet','renders':3,'coverage':coverage,
     'contact':contact,'build':audit,'offscreen_trim':read('r3-offscreen-trim.json'),
     'artifact':'slice-v2/prototype/guardian-greybox.rbxl','backup':'slice-v2/prototype/guardian-greybox.pre-s1r3.rbxl',
     'sha256':hashlib.sha256((ROOT/'slice-v2/prototype/guardian-greybox.rbxl').read_bytes()).hexdigest(),
     'StudioPassAll':'UNKNOWN after R3','commit':False,'published':False,
     'lessons':'../LESSONS.md; R3 visible masks, frustum placement, actual wall spans'}
(H/'FINAL-EVIDENCE.json').write_text(json.dumps(out,indent=2))
print('Lower-left: %.2f%% (goal 25%%)'%coverage['lower_left_pct'])
print('Lower-right: %.2f%% (goal 25%%)'%coverage['lower_right_pct'])
print('Portal: %.2f%% of frame; contact audit: 0'%coverage['portal_frame_pct'])
