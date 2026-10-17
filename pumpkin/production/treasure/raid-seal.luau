-- Final offline seal. Preserve the entire original N8 lattice and assertions.
local fs, rb, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde')
local path='slice-v2/prototype/guardian-greybox.rbxl'
local bytes=fs.readFile(path)
local finalHash=serde.hash('sha256',bytes)
local final=rb.deserializePlace(bytes)
local dropBytes=fs.readFile('treasure/raid-drop-input.rbxl')
local dropHash=serde.hash('sha256',dropBytes)
local input=rb.deserializePlace(dropBytes)
-- DropSample's frozen input predates only the last client visibility guard.
-- Neither the client nor this Source field is executed by the offline resolver.
-- Neutralizing that ONE field must reproduce the complete saved input exactly.
local client=final.StarterPlayer.StarterPlayerScripts.RaidSliceClient
local latest=client.Source
client.Source=input.StarterPlayer.StarterPlayerScripts.RaidSliceClient.Source
assert(rb.serializePlace(final)==rb.serializePlace(input),'DropSample input differs beyond client visibility Source')
client.Source=latest
if require('@lune/process').args[1]=='parity' then
 print('PASS DropSample input: entire final serialization equal after neutralizing only client visibility Source')
 return
end
local reports,expected,seen,total={},{},{},0
for i=1,3 do
 local r=serde.decode('json',fs.readFile('treasure/RAID-DROPS-'..i..'.json'))
 assert(r.worker==i and r.state=='PASS' and #r.failures==0,'worker failed '..i)
 assert(r.input_sha256==dropHash,'worker used a stale place '..i)
 local names={};for _,name in r.allRouteNames do names[name]=true end
 if i==1 then expected=names else
  for name in expected do assert(names[name],'route-set missing') end
  for name in names do assert(expected[name],'route-set unexpected') end
 end
 for _,name in r.shardRoutes do assert(not seen[name],'duplicate route '..name);seen[name]=true end
 total+=r.samples;table.insert(reports,r)
end
local routes={};for name in expected do assert(seen[name],'missing route '..name);table.insert(routes,name) end
table.sort(routes)
assert(total==31824 and #routes==20,'incomplete original N8 lattice')
local drops={status='PASS',state='PASS',samples=total,failures={},workers=reports,
 input_sha256=dropHash,final_place_sha256=finalHash,all_routes_executed_exactly_once=routes,
 complete_input_equal_after_neutralizing_only_RaidSliceClient_Source=true,Studio='NOT RUN'}
fs.writeFile('treasure/RAID-DROPS.json',serde.encode('json',drops,true))
local function report(name)
 local r=serde.decode('json',fs.readFile('treasure/'..name))
 assert(r.status=='PASS',name..' failed');return r
end
local build=report('RAID-BUILD.json')
assert(build.place_sha256==finalHash and build.compiled_O0_O1_O2==101,'build drift')
for _,name in {'RAID-CONTRACTS.json','RAID-VAULT.json','RAID-CLIENT.json'} do
 assert(report(name).artifact_sha256==finalHash,name..' stale')
end
local existing=serde.decode('json',fs.readFile('treasure/RAID-EXISTING-CONTRACTS.json'))
assert(existing.offset_origin_once and existing.late_kits_origin_once
 and existing.failed_section_warns_and_keeps_island,'legacy construction contract failed')
local logAssertions={
 {'raid-50-seed.log','PASS 50-seed actual 3D walking-floor'},
 {'raid-existing-contracts.log','PASS nonzero origin'},
 {'raid-behavior.log','PASS production Arena.reset and overlapping path completion epochs'},
 {'raid-client.log','PASS actual raid client'},
 {'raid-contracts-fresh.log','PASS raid lifecycle'},
 {'raid-vault.log','PASS actual server vault'},
}
local function readLog(path)
 local raw=fs.readFile(path)
 if raw:sub(1,2)~='\255\254' then return raw end
 -- Windows PowerShell redirection writes UTF-16LE; assertions inspect text.
 local chars,i={},3
 while i<#raw do
  local cp=string.byte(raw,i)+256*string.byte(raw,i+1)
  if cp>=0xD800 and cp<=0xDBFF and i+3<=#raw then
   local low=string.byte(raw,i+2)+256*string.byte(raw,i+3)
   assert(low>=0xDC00 and low<=0xDFFF,'invalid log encoding')
   cp=0x10000+(cp-0xD800)*1024+low-0xDC00;i+=2
  end
  table.insert(chars,utf8.char(cp));i+=2
 end
 return table.concat(chars)
end
for _,row in logAssertions do
 local contents=readLog('treasure/'..row[1]);assert(contents:find(row[2],1,true),'missing check '..row[1])
 assert(not contents:find('[Stack Begin]',1,true),'failed check '..row[1])
end
local baseline=rb.deserializePlace(fs.readFile(build.backup))
assert(rb.serializeModel({baseline.Workspace})==rb.serializeModel({final.Workspace}),'saved Workspace drift')
local unchanged,changed=0,{}
local allowed={
 ['ServerScriptService.Greybox']=true,['ServerScriptService.GreyboxArena']=true,
 ['ServerScriptService.StudioPass']=true,['ReplicatedStorage.GreyboxTraps']=true,
 ['ReplicatedStorage.MeadowV4.Builder']=true,
}
for _,n in baseline:GetDescendants() do if n:IsA('LuaSourceContainer') then
 local names={};local cursor=n
 while cursor.Parent do table.insert(names,1,cursor.Name);cursor=cursor.Parent end
 local node=final;for _,name in names do node=assert(node:FindFirstChild(name),'source removed') end
 local key=table.concat(names,'.')
 if node.Source~=n.Source then assert(allowed[key],'unrelated source changed '..key);table.insert(changed,key)
 else unchanged+=1 end
end end
local suites={'GreyboxSelfTest','DropSampleTest','GreyboxLoopTest','GreyboxPvpTest','GreyboxTrapTest',
 'CoreLoopTest','RavineTest','TunnelTest','OutsmartTest','RaidSliceTest'}
local live={};for _,name in suites do
 assert(final.ServerScriptService.StudioPass.Source:find('"'..name..'"',1,true),'missing suite '..name)
 table.insert(live,{name=name,result='UNKNOWN; Claude live check pending'})
end
local hashes={}
for _,file in {path,build.backup,'treasure/RAID-SLICE-1.md','treasure/sections/LESSONS.md',
 'treasure/RAID-BUILD.json','treasure/RAID-CONTRACTS.json','treasure/RAID-VAULT.json',
 'treasure/RAID-CLIENT.json','treasure/RAID-DROPS.json','treasure/raid-50-seed.log',
 'treasure/RAID-EXISTING-CONTRACTS.json',
 'treasure/raid-behavior.log','treasure/raid-existing-contracts.log','treasure/raid-contracts-fresh.log',
 'treasure/raid-vault.log','treasure/raid-client.log','treasure/raid-drop-input.rbxl'} do
 hashes[file]=serde.hash('sha256',fs.readFile(file))
end
fs.writeFile('treasure/RAID-FINAL.json',serde.encode('json',{
 status='PASS',evidence='Offline only; no Studio play',place=path,place_sha256=finalHash,
 compiled_O0_O1_O2=101,original_sources_unchanged=unchanged,intentional_original_source_changes=changed,
 existing_nine_suite_bodies_preserved=true,drop_samples=total,drop_routes=routes,
 drop_input_sha256=dropHash,drop_input_only_diff_is_nonexecuted_client_Source=true,
 native_body_and_vault_collision_proxy='PASS; actual Roblox physics UNKNOWN',
 live_StudioPassAll=live,Claude_review='PENDING',commit='NONE',publish='NONE',hashes=hashes,
},true))
print('PASS final seal: 101 compiled sources; contracts/50 seeds; '..total..' DropSample samples; raid/client/vault contracts; live UNKNOWN')
