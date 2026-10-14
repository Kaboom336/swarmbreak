local fs=require('@lune/fs')
local source='prototype/guardian-greybox.rbxl'
local target='slice-v2/prototype/guardian-greybox.rbxl'
local bytes=fs.readFile(source)
fs.writeFile(target,bytes)
assert(fs.readFile(target)==bytes,'Canonical/delivery mismatch')
print('PASS canonical/delivery binary byte parity')
