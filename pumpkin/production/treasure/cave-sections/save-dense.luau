local fs,serde=require('@lune/fs'),require('@lune/serde')
local id=require('@lune/process').args[1];local H='treasure/cave-sections/'..id..'/'
local tag=fs.isFile(H..'r4-review.rbxl')and'r4'or(fs.isFile(H..'r3-review.rbxl')and'r3'or'r2')
local hash=serde.hash('sha256',fs.readFile(H..tag..'-review.rbxl'))
local input=serde.decode('json',fs.readFile(H..'OFFLINE-INPUT-8.json'));assert(input.place_sha256==hash)
local log=fs.readFile(H..'offline-dense.log')
assert(log:gsub('%z',''):find('PASS scene preservation, O0/O1/O2, manifest, kit clearance/query, stacked floor, policy, reachable drops',1,true),'dense incomplete')
local report=fs.isFile(H..'STUDIO-OFFLINE.json')and H..'STUDIO-OFFLINE.json'or'prototype/cave-v2/STUDIO-OFFLINE.json'
local d=serde.decode('json',fs.readFile(report))
assert(d.N==8 and d.samples==3024 and next(d.failures)==nil and next(d.reasons)==nil)
fs.writeFile(H..'DENSE-FINAL.json',serde.encode('json',{state='PASS',place_sha256=hash,report=d,input=input,log_sha256=serde.hash('sha256',log)},true))
print('PASS fresh final-artifact 3024 samples, zero failures')
