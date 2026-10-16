local fs,rb=require('@lune/fs'),require('@lune/roblox')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s2.rbxl'))
local cf=rb.CFrame.lookAt(rb.Vector3.zero,rb.Vector3.new(0,1,0),rb.Vector3.new(1,0,0));print('CF',cf,cf.RightVector,cf.UpVector,cf.LookVector,cf:VectorToWorldSpace(rb.Vector3.new(0,0,-1)))
for _,q in p:GetDescendants() do if q:IsA('TextLabel') or q:IsA('TextButton') then local ok,t=pcall(function() return q.Text end);if ok and (t:upper():find('RECOVERY') or t:upper():find('CYAN')) then print('LABEL',q:GetFullName(),t) end end end
for _,s in p:GetDescendants() do if s:IsA('LuaSourceContainer') then
 local src=s.Source;local at=src:upper():find('RECOVERY')
 if at and src:upper():find('CYAN') then
  for line in src:gmatch('[^\n]+') do if line:upper():find('CYAN') then print(s:GetFullName(),line:sub(1,250)) end end
 end
end end
