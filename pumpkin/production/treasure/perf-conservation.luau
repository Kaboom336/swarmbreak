-- Execute the exact production visual/conservation functions with native Instances.
local fs, rb, luau = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau')
local source=fs.readFile('slice-v2/prototype/Greybox.server.luau')
local start=assert(source:find('local function visual(item)',1,true))
local finish=assert(source:find('local portal = Scene.home',start,true))
local workspace=rb.Instance.new('Workspace')
local world=rb.Instance.new('Folder');world.Parent=workspace
local storage=rb.Instance.new('Folder')
local rules={items={}}
local registry={}
local collection={GetTagged=function(_,tag)
 local out={}
 -- Lune destroyed userdata throws; Roblox CollectionService unregisters it.
 for _,p in registry do
  local ok,tagged=pcall(function() return p:HasTag(tag) end)
  if ok and tagged then table.insert(out,p) end
 end
 return out
end}
local env={workspace=workspace,world=world,CollectionService=collection,rules=rules,
 Rules={audit=function() end},Config={ItemName='Loot',MeadowV4=false},
 Vector3=rb.Vector3,CFrame=rb.CFrame,Enum=rb.Enum,states={},
 part=function(parent,name,size,position)
  local p=rb.Instance.new('Part');p.Name=name;p.Size=size;p.Position=position;p.Parent=parent
  table.insert(registry,p);return p
 end,
 label=function(p)
  local gui=rb.Instance.new('BillboardGui');gui.Parent=p
  local label=rb.Instance.new('TextLabel');label.Parent=gui;return label
 end}
local f=luau.load(source:sub(start,finish-1)..'\nreturn {visual=visual,audit=conservation}',{environment=env,injectGlobals=true})()
local item={id='test',state='Nest',position=rb.Vector3.zero};rules.items[item.id]=item
f.visual(item);assert(item.visual:HasTag('GreyboxLoot'));assert(f.audit())
local function oldAudit()
 local n=0
 for _,p in workspace:GetDescendants() do if p:IsA('BasePart') and p:GetAttribute('LootId')==item.id then n+=1 end end
 return n==(item.state=='Retired' and 0 or 1)
end
local cases=0
local function check(expected)
 local ok,err=pcall(f.audit)
 assert(ok==expected and oldAudit()==expected,'old/new assertion mismatch case '..(cases+1)..': '..tostring(err))
 if not expected then assert(tostring(err):find('physical LOOT duplication/loss',1,true)) end
 cases+=1
end
check(true)
local clone=item.visual:Clone();table.insert(registry,clone)
assert(clone:HasTag('GreyboxLoot') and clone:GetAttribute('LootId')==item.id,'Clone tag/attribute inheritance')
clone.Parent=world;check(false)
clone.Parent=storage;check(true)
clone.Parent=workspace;check(false)
clone:Destroy();check(true)
item.visual.Parent=storage;check(false)
item.visual.Parent=world;check(true)
local character=rb.Instance.new('Model');character.Parent=workspace
item.visual.Parent=character;check(true)
local unknown=rb.Instance.new('Part');unknown:SetAttribute('LootId','unknown');unknown:AddTag('GreyboxLoot');unknown.Parent=world;table.insert(registry,unknown);check(true)
item.state='Placed';item.position=rb.Vector3.new(1,2,3);f.visual(item);check(true)
item.state='Retired';f.visual(item);check(true)
clone=unknown:Clone();clone:SetAttribute('LootId',item.id);clone.Parent=world;table.insert(registry,clone);check(false)
print('PASS exact production conservation/visual:',cases,'old/new equivalence cases; native Clone tags; duplicates, loss, reparent, placed, retired')
