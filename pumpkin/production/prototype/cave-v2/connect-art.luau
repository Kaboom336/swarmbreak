-- Fitted visual infrastructure over the accepted collision floors.
local rb,fs,serde=require('@lune/roblox'),require('@lune/fs'),require('@lune/serde')
return function(e)
 local native=e.model:GetChildren();local remove={}
 local kit=serde.decode('json',fs.readFile('prototype/cave-v2/CONNECT-KIT.json'))
 for i,p in e.parts do
  local replace=p.name=='CobbleRoutePaving' or p.name=='ChunkyPathEdge' or p.name=='SteelRail' or p.name=='RailSleeper' or p.name:match('^ReadableRail')
  if replace and not p.collidable then remove[i]=true end
  if p.category=='lane' or p.name=='BreakableSpan' or p.name=='SpanBearingBeam' then p.transparency=1;native[i].Transparency=1 end
  if p.name=='RouteRockButtress' then
   for _,old in kit.hidden_supports do
    if p.position[1]==old.position[1] and p.position[2]==old.position[2] and p.position[3]==old.position[3] and p.size[2]==old.size[2] then
     p.transparency=1;native[i].Transparency=1;break
    end
   end
  end
  local material=p.material
  if p.category=='lane' then material='Cobblestone'
  elseif p.category=='mass' then material='Slate'
  elseif p.category=='underside' then material='Basalt'
  elseif p.category=='rock-detail' or p.category=='wall' or p.category=='roof' then material='Rock'
  elseif material=='Wood' then material='WoodPlanks'
  elseif p.category=='crystal' and (p.name=='CrystalDarkFace' or p.name=='CrystalPrismFace' or p.name=='CrystalInsetFacet') then material='Glass' end
  if p.category~='hook' then p.material=material;native[i].Material=rb.Enum.Material[material] end
 end
 for i=#e.parts,1,-1 do if remove[i] then native[i]:Destroy();table.remove(e.parts,i) end end
 local start=#e.parts
 local clamps,maxDelta=0,0
 for i,p in kit.parts do
  local changed=false
  for axis=1,3 do
   if p.size[axis]<.001 then maxDelta=math.max(maxDelta,.001-p.size[axis]);p.size[axis]=.001;changed=true end
  end
  if changed then clamps+=1 end
  local r=p.rotation;local q=p.position
  local cf=e.C.new(q[1],q[2],q[3],unpack(r))
  local node=e.part(p.name,p.category,cf,e.V.new(unpack(p.size)),p.color,false,p.material,p.shape)
  node:SetAttribute('ConnectKitIndex',i-1)
  if p.bridge then node:SetAttribute('ConnectDynamicSpan',true) end
 end
 kit.native_start=start;kit.minimum_size_clamps=clamps;kit.maximum_dimension_change=maxDelta
 fs.writeFile('prototype/cave-v2/CONNECT-PLACED.json',serde.encode('json',kit,true))
end
