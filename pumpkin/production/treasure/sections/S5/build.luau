-- Canonical Lune source-only mount; preserve serialized Workspace and kit state.
local fs,luau=require('@lune/fs'),require('@lune/luau')
-- Restart guard: use only the freshly byte-verified canonical backup.
local serde=require('@lune/serde')
local proof=serde.decode('json',fs.readFile('treasure/sections/S5/BACKUP.json'))
assert(serde.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.pre-s5.rbxl'))==string.lower(proof.backup),'stale S5 backup')
local src=fs.readFile('treasure/sections/S4/build.luau')
src=src:gsub('S4','S5'):gsub('Section4','Section5'):gsub('pre%-s4','pre-s5')
-- No tagged-cosmetic exception applies to S5.
src=src:gsub(' and not oldWarning','')
src=src:gsub('kind=p.ClassName,position',"kind=p.ClassName,shadows=p.Shadows,position")
-- JSON round-trip both sides before comparing: native empty tables and decoded
-- JSON empty arrays otherwise have different encodings despite equal contents.
src=src:gsub("table.insert%(physical,serde.encode%('json',q%)%)", "table.insert(physical,serde.encode('json',serde.decode('json',serde.encode('json',q))))")
src=src:gsub("if mode=='deliver' then", "if mode=='r1' or mode=='r2' then")
local first=assert(src:find(' local rojo=',1,true))
local last=assert(src:find(' fs.writeFile(main,bytes)',first,true))
src=src:sub(1,first-1)..src:sub(last)
-- Full-place equality after removing the only new module.
src=src:gsub('local bytes=rb.serializePlace%(place%)',[[
local neutral=rb.deserializePlace(rb.serializePlace(place))
local added=neutral.ReplicatedStorage.MeadowV4:FindFirstChild('Section5')
if added then added:Destroy() end
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized state changed')
local bytes=rb.serializePlace(place)
]])
src=src:gsub(' fs.writeFile%(main,bytes%)'," fs.writeFile(H..string.upper(mode)..'-review.rbxl',bytes);fs.writeFile(main,bytes)")
-- Reuse the freshly exported backup manifest rather than rebuilding it per round.
src=src:gsub("export%(old,'before'%)",[[
if mode=='before' then export(old,'before') else
 local baseline=serde.decode('json',fs.readFile(H..'before.json'));local sig={}
 for _,q in baseline.parts do
  if q.collidable or q.query or q.touch or q.lane or #q.tags>0 then table.insert(sig,serde.encode('json',q)) end
 end
 table.sort(sig);signatures.before=table.concat(sig,'\n')
end
]])
luau.load(src,{environment=getfenv(),injectGlobals=true})()
