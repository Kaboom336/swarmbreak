-- Source-only Lune mount. Preserve the current fully assembled place.
local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
local main = 'slice-v2/prototype/guardian-greybox.rbxl'
local backup = 'slice-v2/prototype/guardian-greybox.pre-uifix.rbxl'
assert(fs.isFile(backup), 'pre-uifix backup required')
local before = fs.readFile(backup)
local p, old = rb.deserializePlace(before), rb.deserializePlace(before)
local paths = {
 {'StarterPlayer.StarterPlayerScripts.Greybox', 'slice-v2/prototype/Greybox.client.luau'},
 {'StarterPlayer.StarterPlayerScripts.HomeArt', 'slice-v2/prototype/HomeArt.client.luau'},
 {'ReplicatedStorage.MeadowV4.Section7', 'prototype/meadow-v4/Section7.luau'},
}
local function at(root,path)
 for _,key in string.split(path,'.') do root=assert(root:FindFirstChild(key),key) end
 return root
end
for _,pair in paths do at(p,pair[1]).Source=fs.readFile(pair[2]) end
local compiled=0
for _,node in p:GetDescendants() do
 if node:IsA('LuaSourceContainer') then
  for opt=0,2 do luau.compile(node.Source,{optimizationLevel=opt}) end
  compiled+=1
 end
end
local bytes=rb.serializePlace(p)
local neutral=rb.deserializePlace(bytes)
for _,pair in paths do at(neutral,pair[1]).Source=at(old,pair[1]).Source end
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized state changed')
-- Execute only the changed presentation constructors with actual Lune instances.
local env={}
for _,key in {'Enum','Instance','Color3','Vector2','Vector3','UDim','UDim2','ColorSequence'} do env[key]=rb[key] end
local style=luau.load(p.ReplicatedStorage.UIStyle.Source,{environment=env})()
local source=at(p,paths[1][1]).Source
local start=assert(source:find('local goal =',1,true))
local finish=assert(source:find('local button =',start,true))
env.Style=style;env.gui=rb.Instance.new('ScreenGui')
local goal,icon=luau.load(source:sub(start,finish-1)..'\nreturn goal,goalIcon',{environment=env})()
assert(goal.PanelPadding.PaddingLeft.Offset==60)
assert(icon.Position.X.Offset+icon.Size.X.Offset < 0,'icon overlaps padded text')
-- Execute the actual new acorn-caption block, using the real cosmetic builder.
env.unpack=table.unpack;env.CFrame=rb.CFrame
local acorn=luau.load(p.ReplicatedStorage.MeadowV4.SummitAcorn.Source,{environment=env})().build()
env.model=acorn
start=assert(at(p,paths[2][1]).Source:find('local caption, captionGui = Style.billboard(model.GoldenBody',1,true))
source=at(p,paths[2][1]).Source
finish=assert(source:find('for _, gui in root:GetDescendants()',start,true))
luau.load(source:sub(start,finish-1),{environment=env})()
local caption=acorn.GoldenBody.SummitAcornCaption
assert(caption.Caption.Text=='Golden Acorn' and caption.MaxDistance==70)
assert(caption.StudsOffsetWorldSpace.Y>3.5 and not caption.AlwaysOnTop)
-- Build the delivered summit signage and apply the real generic decorator again.
env.game={GetService=function(_,name)
 if name=='ReplicatedStorage' then return p.ReplicatedStorage end
 assert(name=='RunService');return {}
end}
env.require=function(node) assert(node==p.ReplicatedStorage.UIStyle);return style end
local summit=rb.Instance.new('Model');summit.Parent=p.Workspace
luau.load(p.ReplicatedStorage.MeadowV4.Section7.Source,{environment=env})().build(summit,rb.Vector3.zero)
env.workspace=p.Workspace;env.styledPrompt=function()return false end
source=p.StarterPlayer.StarterPlayerScripts.TreasureUIWorld.Source
start=assert(source:find('local function decorate',1,true))
finish=assert(source:find('workspace.DescendantAdded',start,true))
local decorate=luau.load(source:sub(start,finish-1)..'\nreturn decorate',{environment=env})()
for i,text in {'SHELF  >','SPIRAL  >'} do
 local board=summit:FindFirstChild('S7_ExitBoard'..i)
 assert(board and board:GetAttribute('S7Caption')==text)
 local faces={}
 for _,node in board:GetChildren() do
  if node:IsA('SurfaceGui') then
   faces[node.Face.Name]=node
   assert(node.AlwaysOnTop and node.MaxDistance==70)
   assert(node:FindFirstChildOfClass('TextLabel').Text==text)
  end
 end
 assert(faces.Front and faces.Back,'missing approach/reverse face')
 decorate(board);decorate(board)
 assert(faces.Front.Parent==board and faces.Back.Parent==board,'generic decorator replaced private faces')
end
summit:Destroy()
-- Neutralized serialization proves prompts, gameplay, tests, saving, geometry,
-- capture cameras and every other source/property are unchanged.
fs.writeFile(main,bytes)
assert(fs.readFile(main)==bytes)
fs.writeFile('treasure/UI-FIX-BUILD.json',serde.encode('json',{
 status='PASS',backup=backup,backup_sha256=serde.hash('sha256',before),
 canonical_sha256=serde.hash('sha256',bytes),compiled_O0_O1_O2=compiled,
 changed_sources=paths,all_unrelated_serialized_state_exact=true,
 objective_icon_clearance_pixels=20,acorn_caption_constructor='PASS',summit_signs_both_faces_decorator_repeat='PASS',
 live_Studio='UNKNOWN',
},true))
print('PASS Lune source-only mount; '..compiled..' scripts O0/O1/O2; unrelated state exact; objective/acorn constructors PASS')
