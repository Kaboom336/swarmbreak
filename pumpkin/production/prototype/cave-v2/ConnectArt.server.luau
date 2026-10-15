-- Cosmetic span rails follow the existing breakable collision span.
-- No gameplay state, route, timing, hook or original script is changed.
local map=workspace:WaitForChild('CaveV2')
local span=map:WaitForChild('BreakableSpan')
local bearing=map:WaitForChild('SpanBearingBeam')
local pieces={}
for _,p in map:GetChildren() do
 if p:IsA('BasePart') and p:GetAttribute('ConnectDynamicSpan') then table.insert(pieces,p) end
end
local function update()
 local alpha=span.CanCollide and 0 or 1
 for _,p in pieces do p.Transparency=alpha end
 -- The old broad floor/beam remain collision carriers beneath the fitted kit.
 if span.Transparency~=1 then span.Transparency=1 end
 if bearing.Transparency~=1 then bearing.Transparency=1 end
end
span:GetPropertyChangedSignal('CanCollide'):Connect(update)
span:GetPropertyChangedSignal('Transparency'):Connect(update)
bearing:GetPropertyChangedSignal('Transparency'):Connect(update)
update()
