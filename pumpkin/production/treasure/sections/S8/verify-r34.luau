-- Final artifact/source parity and exact two-source scope; no remount.
local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local H='treasure/sections/S8/'
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-s8r3.rbxl'
local old=rb.deserializePlace(fs.readFile(backup));local p=rb.deserializePlace(fs.readFile(main))
assert(fs.readFile(main)==fs.readFile(H..'R4-review.rbxl'))
assert(p.ReplicatedStorage.MeadowV4.Section8.Source==fs.readFile('prototype/meadow-v4/Section8.luau'))
assert(p.ReplicatedStorage.MeadowV4.Section8.Source==fs.readFile(H..'r4-Section8.luau'))
assert(p.ReplicatedStorage.GreyboxScene.Source==fs.readFile('slice-v2/prototype/Scene.luau'))
assert(p.StarterPlayer.StarterPlayerScripts.HomeArt.Source==fs.readFile('slice-v2/prototype/HomeArt.client.luau'))
local home=p.StarterPlayer.StarterPlayerScripts.HomeArt.Source
local first=assert(home:find('\t\t\t-- S8:',1,true))
local last=assert(home:find('\t\t\tlocal material',first,true))
assert(home:sub(1,first-1)..home:sub(last)==old.StarterPlayer.StarterPlayerScripts.HomeArt.Source,'HomeArt change exceeds Lava cosmetic finish')
local restored=p.ReplicatedStorage.GreyboxScene.Source:gsub('Vector3.new%(3, 24, 0.4%)','Vector3.new(8, 66, 3)'):gsub('Color3.fromRGB%(176, 112, 62%)','Color3.fromRGB(255, 110, 25)')
assert(restored:gsub('%s+','')==old.ReplicatedStorage.GreyboxScene.Source:gsub('%s+',''),'unexpected Scene change')
local count=0
for _,n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then for opt=0,2 do luau.compile(n.Source,{optimizationLevel=opt}) end;count+=1 end end
p.ReplicatedStorage.MeadowV4.Section8.Source=old.ReplicatedStorage.MeadowV4.Section8.Source
p.ReplicatedStorage.GreyboxScene.Source=old.ReplicatedStorage.GreyboxScene.Source
p.StarterPlayer.StarterPlayerScripts.HomeArt.Source=old.StarterPlayer.StarterPlayerScripts.HomeArt.Source
assert(rb.serializePlace(p)==rb.serializePlace(old),'unrelated place changed')
local out={state='PASS',compiled_O0_O1_O2=count,unrelated_sources_preserved=count-3,serialized_place_exact_after_restoring_three_sources=true,Scene_only_lava_cosmetic_size_and_color=true,HomeArt_only_Lava_finish=true,canonical_sha256=serde.hash('sha256',fs.readFile(main)),backup_sha256=serde.hash('sha256',fs.readFile(backup)),source_sha256=serde.hash('sha256',fs.readFile('prototype/meadow-v4/Section8.luau')),live_Studio='UNKNOWN'}
fs.writeFile(H..'PARITY-R34.json',serde.encode('json',out,true));print('PASS final mounted source parity; only Section8 and two scenery Lava finishes; '..count..' compile O0/O1/O2')
