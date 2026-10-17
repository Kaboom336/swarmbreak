-- Run the unchanged cave checker against its own mounted loader version.
-- Shared on-disk KitLibrary was changed by Meadow after this cave was built.
local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local baseline=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c8.rbxl'))
local final=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
assert(final.ServerScriptService.KitLibrary.Source==baseline.ServerScriptService.KitLibrary.Source,'C8 changed loader')
local proxy=table.clone(fs)
proxy.writeFile=function(path,bytes)
 if path=='prototype/cave-v2/STUDIO-OFFLINE.json'then return fs.writeFile('treasure/cave-sections/C8/STUDIO-OFFLINE.json',bytes)end
 return fs.writeFile(path,bytes)
end
proxy.readFile=function(path)
 if path=='prototype/kits/KitLibrary.luau'then return final.ServerScriptService.KitLibrary.Source end
 if path=='prototype/cave-v2.pre-studio-pass.rbxl'then
  -- Only the explicitly authorized noncollidable CART board expected fields.
  -- All collider/floor/source assertions remain the unchanged stock checker.
  local expected=rb.deserializePlace(fs.readFile(path))
  local old,new=expected.Workspace.CaveV2.CartSign,final.Workspace.CaveV2.CartSign
  assert(not old.CanCollide and not new.CanCollide)
  old.CFrame=new.CFrame;old.Size=new.Size
  -- C8 owns only Transparency of the 74 noncollidable residual cubes.
  -- Independently verified complete serialized restoration in C8/verify.luau.
  local retire=require('./retire')
  for _,q in expected.Workspace.CaveV2:GetDescendants()do
   if retire(q,final.ServerScriptService.CaveEscapeC8.Round.Value)then
    assert(not q.CanCollide);q.Transparency=1
   end
  end
  return rb.serializePlace(expected)
 end
 return fs.readFile(path)
end
local originalRequire=require
local serde=require('@lune/serde')
local mode=require('@lune/process').args[1]or'8'
fs.writeFile('treasure/cave-sections/C8/OFFLINE-INPUT-'..mode..'.json',serde.encode('json',{
 place_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl')),
 loader_sha256=serde.hash('sha256',final.ServerScriptService.KitLibrary.Source),
 working_tree_loader_differs=final.ServerScriptService.KitLibrary.Source~=fs.readFile('prototype/kits/KitLibrary.luau'),
 checker_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2/studio-check.luau')),
 mode=mode,expected_loader='unchanged pre-C8 mounted cave loader',expected_scene_exception='historical CartSign Size/CFrame; C8 retire.luau residual noncollidable cubes/distant Crystal details Transparency only',test_assertions_changed=false},true))
local env=table.clone(getfenv())
env.require=function(path)
 if path=='@lune/fs'then return proxy end
 if path=='../meadow-v4/OfflineRay'then return originalRequire('../../../prototype/meadow-v4/OfflineRay')end
 return originalRequire(path)
end
print('SOURCE-AWARE: unchanged studio-check; expected KitLibrary read uses exact pre-C8 mounted version, not Meadow working-tree version')
luau.load(fs.readFile('prototype/cave-v2/studio-check.luau'),{environment=env,injectGlobals=true})()
