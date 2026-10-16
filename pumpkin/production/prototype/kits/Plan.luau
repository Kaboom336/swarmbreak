-- Explicit families only; lane-encroaching dressing is dropped by Swap.
local Plan = {}
local Q, N, D, S = "quaternius-nature__", "kenney_nature-kit__", "kenney_mini-dungeon__", "kenney_survival-kit__"
local rules = {
 meadow = {
  {anchor="R5OakTrunk", members={"R5OakTrunk","R5OakCrown"}, names={Q.."CommonTree_1",Q.."Pine_1",Q.."TwistedTree_1"}, radius=22, tree=true},
  {anchor="LookHillTreeTrunk", members={"LookHillTreeTrunk","LookHillTreeCrown"}, names={Q.."CommonTree_1",Q.."Pine_1"}, radius=22, tree=true},
  {anchor="TunnelHillTreeTrunk", members={"TunnelHillTreeTrunk","TunnelHillTreeCrown"}, names={Q.."CommonTree_1",Q.."TwistedTree_1"}, radius=22, tree=true},
  {anchor="R5BushFoot",members={"R5BushFoot","R5BushCrown","R5BushSide"},names={Q.."Bush_Common",Q.."Bush_Common_Flowers"},radius=8},
  {anchor="LookHillBush",members={"LookHillBush"},names={Q.."Bush_Common_Flowers"},radius=8},
  {anchor="TunnelHillBush",members={"TunnelHillBush"},names={Q.."Bush_Common"},radius=8},
  {anchor="R5BoulderFoot",members={"R5BoulderFoot","R5BoulderFacet","R5BoulderShoulder","R5BoulderMoss"},names={Q.."Rock_Medium_1",N.."rock_tallA",N.."rock_largeA"},radius=12},
  {anchor="LookHillBoulder",members={"LookHillBoulder"},names={N.."rock_tallA"},radius=10},
  {anchor="R5FlowerStem",members={"R5FlowerStem","R5FlowerPetals","R5FlowerCentre","R5FlowerLeaves"},names={N.."flower_yellowA",Q.."Flower_3_Group"},radius=3},
  {anchor="LookHillFlowerStem",members={"LookHillFlowerStem","LookHillFlowerPetal"},names={N.."flower_yellowA"},radius=3},
  {anchor="TunnelMushroomStem",members={"TunnelMushroomStem","TunnelMushroomGlow","Fix1MushroomCap","Fix1MushroomSpot"},names={Q.."Mushroom_Common"},radius=3},
 },
 cave = {
  {anchor="MineCrate",members={"MineCrate","CrateIronBand"},names={S.."box"},radius=5},
  {anchor="DressedCrate",members={"DressedCrate","CrateBinding","CrateDiagonal"},names={S.."box-large"},radius=5},
  {anchor="R3SupplyCrate",members={"R3SupplyCrate","R3CrateBinding"},names={S.."box"},radius=5},
  {anchor="R3YardCrate",members={"R3YardCrate","R3YardCrateBand"},names={S.."box-large"},radius=5},
  {anchor="FramingCrate",members={"FramingCrate"},names={S.."box"},radius=5},
  {anchor="FloatingRock",members={"FloatingRock"},names={Q.."Rock_Medium_1",D.."rocks",N.."rock_tallA"},radius=1},
  {anchor="CliffScaffoldPost",members={"CliffScaffoldPost"},names={D.."column"},radius=1,fitted=true},
  {anchor="CliffScaffoldBrace",members={"CliffScaffoldBrace"},names={D.."wood-support"},radius=1,fitted=true},
  {anchor="CliffScaffoldShelf",members={"CliffScaffoldShelf"},names={D.."wood-structure",D.."wall"},radius=1,fitted=true},
 }
}
local function match(name, stem) return name == stem or name:match("^"..stem.."Voxel[123]$") ~= nil end
function Plan.bounds(parts)
 local lo, hi = Vector3.new(math.huge,math.huge,math.huge), Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,p in parts do
  for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
   local v=p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x,y,z)/2)
   lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
   hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
  end end end
 end
 return CFrame.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2),hi-lo
end
function Plan.groups(root,island)
 local parts={}
 for _,p in root:GetDescendants() do if p:IsA("BasePart") and not p:GetAttribute("KitAssetId") and not p:GetAttribute("MeadowPolishCleared") then table.insert(parts,p) end end
 local result, claimed = {}, {}
 for _,rule in rules[island] do
  local anchors={}
  for _,p in parts do if match(p.Name,rule.anchor) and not p.Name:find("Voxel[23]$") then table.insert(anchors,p) end end
  local groups={}
  for i,a in anchors do groups[i]={anchor=a,parts={},name=rule.names[1+(i-1)%#rule.names],tree=rule.tree,fitted=rule.fitted} end
  for _,p in parts do
   if claimed[p] then continue end
   local member=false
   for _,stem in rule.members do if match(p.Name,stem) then member=true;break end end
   if not member then continue end
   local nearest, distance=nil,math.huge
   for i,a in anchors do
    local delta=p.CFrame.Position-a.CFrame.Position
    local d=math.sqrt(delta.X^2+delta.Z^2) -- crowns/stems share a vertical axis
    if d<distance and math.abs(delta.Y)<60 then nearest,distance=i,d end
   end
   if nearest and distance<=rule.radius then table.insert(groups[nearest].parts,p);claimed[p]=true end
  end
  for _,g in groups do
   if #g.parts>0 then
    g.base,g.size=Plan.bounds(g.parts)
    if g.fitted then g.base=g.anchor.CFrame*CFrame.new(0,-g.anchor.Size.Y/2,0);g.size=g.anchor.Size end
    table.insert(result,g)
   end
  end
 end
 -- Fence bays are grouped by their shared plan-view midpoint (two rail levels).
 -- Profiles are fitted only after loading the actual imported bounding box.
 if island=="meadow" then
  local bays={}
  for _,p in parts do if p.Name=="R5FenceRail" then
   local v=p.CFrame.Position;local id=string.format("%.3f:%.3f",v.X,v.Z)
   bays[id]=bays[id] or {};table.insert(bays[id],p)
  end end
  local keys={};for k in bays do table.insert(keys,k) end;table.sort(keys)
  for _,id in keys do
   local rails=bays[id];local a=rails[1]
   local g={anchor=a,parts=rails,name=N.."fence_simple",fence=true}
   g.base,g.size=Plan.bounds(rails)
   -- Rails run along local Z in the saved native fence recipe.
   local posts={}
   for _,p in parts do if p.Name=="R5FencePost" then table.insert(posts,p) end end
   table.sort(posts,function(p,q) return (p.CFrame.Position-a.CFrame.Position).Magnitude<(q.CFrame.Position-a.CFrame.Position).Magnitude end)
   assert(#posts>=2,"fence bay has no posts")
   local pa,pb=posts[1],posts[2]
   local va=pa.CFrame.Position-Vector3.new(0,pa.Size.Y/2,0)
   local vb=pb.CFrame.Position-Vector3.new(0,pb.Size.Y/2,0)
   local right=(vb-va).Unit
   local back=right:Cross(Vector3.yAxis).Unit;local up=back:Cross(right).Unit
   local mid=(va+vb)/2
   g.base=CFrame.new(mid.X,mid.Y,mid.Z,right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z)
   -- Imported end-post faces meet the retained post faces, never overlap them.
   g.size=Vector3.new((vb-va).Magnitude-pa.Size.X,4.5,pa.Size.Z)
   g.posts={pa,pb};g.ends={va,vb};g.fitted=true
   if math.abs(va.Y-vb.Y)>0.001 then g.keepReason="rigid kit end posts cannot match vertical posts on a sloped bay" end
   table.insert(result,g)
  end
 else
  -- Complete arch assemblies, clustered by plan position; labels/lights stay put.
  for _,family in {{"CaveArchStone","CaveArchVoussoir"},{"TunnelArchPier","TunnelArchVoussoir"}} do
   local remaining={}
   for _,p in parts do if p.Name==family[1] or p.Name==family[2] then remaining[p]=true end end
   for _,seed in parts do if remaining[seed] then
    local group={seed};remaining[seed]=nil;local i=1
    while i<=#group do
     local a=group[i]
     for p in remaining do
      local delta=p.CFrame.Position-a.CFrame.Position
      if math.sqrt(delta.X^2+delta.Z^2)<13 and math.abs(delta.Y)<30 then table.insert(group,p);remaining[p]=nil end
     end
     i+=1
    end
    local base,size=Plan.bounds(group)
    table.insert(result,{anchor=seed,parts=group,name=D.."wall-opening",base=base,size=size,fitted=true,arch=true})
   end end
  end
  for _,p in parts do
   if p.Name=="CaveMouthTimber" or p.Name=="CampShelterTimber" or p.Name=="CartStationTimber" or p.Name=="MainGatewayTimber" then
    local base,size=Plan.bounds({p})
    table.insert(result,{anchor=p,parts={p},name=D.."wood-support",base=p.CFrame*CFrame.new(0,-p.Size.Y/2,0),size=p.Size,fitted=true})
   end
  end
 end
 if island=="cave" then
  local station=root:FindFirstChild("CartStationTimber",true)
  if station then
   local crates={}
   for _,g in result do if g.anchor.Name:find("Crate") then table.insert(crates,g) end end
   table.sort(crates,function(a,b) return (a.base.Position-station.CFrame.Position).Magnitude<(b.base.Position-station.CFrame.Position).Magnitude end)
   if crates[1] then crates[1].name=D.."barrel" end
   if crates[2] then crates[2].name=D.."chest" end
  end
 end
 return result
end
-- Conservative footprint test: every component, every deck, including stacked
-- routes. Project into each deck's local frame and reserve a full stud outside
-- its edges. Dropping a placement is preferable to obscuring a walking lane.
function Plan.laneClear(parts, lanes)
 for _,p in parts do
  if not p:IsA("BasePart") then continue end
  for _,lane in lanes do
   local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
   for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
    local v=lane.CFrame:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2))
    lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
    hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
   end end end
   if hi.X >= -lane.Size.X/2-1 and lo.X <= lane.Size.X/2+1
    and hi.Z >= -lane.Size.Z/2-1 and lo.Z <= lane.Size.Z/2+1 then return false,lane.Name end
  end
 end
 return true
end
function Plan.lanes(root)
 local lanes={}
 for _,p in root:GetDescendants() do
  if p:IsA("BasePart") and p:HasTag("AuthoredLaneFloor") and p:GetAttribute("WalkableLaneFloor")==true then table.insert(lanes,p) end
 end
 return lanes
end
function Plan.bridgeCandidate(root)
 local deck={}
 for _,p in root:GetDescendants() do if p:IsA("BasePart") and p.Name=="BridgeTimberPlank" then table.insert(deck,p) end end
 if #deck==0 then return nil end
 local base,size=Plan.bounds(deck)
 return {base=base,size=size,parts=deck,name=N.."bridge_wood"}
end
return Plan
