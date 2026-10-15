-- Show whether historical snapshot checks already fail on this task's baseline.
local fs,luau=require('@lune/fs'),require('@lune/luau')
for _,test in {'prototype/meadow-v4/tunnel-test.luau','prototype/cave-v2/connect-check.luau','prototype/core-check.luau'} do
 local source=fs.readFile(test)
 local path=if test:find('tunnel') then 'prototype/meadow-v4.rbxl' elseif test:find('core-check',1,true) then 'prototype/guardian-greybox.rbxl' else 'prototype/cave-v2.rbxl'
 local baseline=path:gsub('%.rbxl$','.kit-runtime-baseline.rbxl')
 local wrapped=table.clone(fs)
 wrapped.readFile=function(p) return fs.readFile(if p==path then baseline else p) end
 local actualRequire=require
 local function loadModule(p)
  if p=='@lune/fs' then return wrapped end
  if test:find('core-check',1,true) then
   if p:sub(1,2)=='./' then return actualRequire('../'..p:sub(3)) end
   if p:sub(1,3)=='../' then return actualRequire('../'..p) end
  end
  if p:sub(1,2)=='./' then return actualRequire('../meadow-v4/'..p:sub(3)) end
  return actualRequire(p)
 end
 local ok,err=pcall(luau.load(source,{environment={require=loadModule}}))
 assert(not ok,'historical baseline unexpectedly passes; investigate new failure')
 print('BASELINE FAIL '..test..': '..tostring(err):match('[^\n]+'))
end
