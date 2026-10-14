-- Binary generated-artifact backup; all authored edits use apply_patch.
local fs = require('@lune/fs')
local rb = require('@lune/roblox')
local source = 'slice-v2/prototype/guardian-greybox.rbxl'
local target = 'prototype/guardian-greybox.pre-v4.rbxl'
assert(not fs.isFile(target), 'Refusing to overwrite pre-v4 backup')
local bytes = fs.readFile(source)
rb.deserializePlace(bytes) -- Reject a corrupt source before preserving it.
fs.writeFile(target, bytes)
assert(fs.readFile(target) == bytes, 'Backup byte verification failed')
rb.deserializePlace(fs.readFile(target))
print('PASS backup: byte-identical, deserialize OK, ' .. #bytes .. ' bytes')
