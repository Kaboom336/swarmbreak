local fs=require("@lune/fs")
local rb=require("@lune/roblox")
local serde=require("@lune/serde")
local V=rb.Vector3
local results={}
for _,letter in {"A","B","C"} do
    local game=rb.deserializePlace(fs.readFile("prototype/meadow-"..letter..".rbxl"))
    local root=game:GetService("Workspace"):FindFirstChild("Meadow"..letter)
    local colliders={}; local routes={}; local meshes={}
    for _,p in root:GetDescendants() do
        if p:IsA("BasePart") then
            if p.CanCollide then table.insert(colliders,p) end
            if p:GetAttribute("Start") then table.insert(routes,p) end
            local cf={p.CFrame:GetComponents()}
            table.insert(meshes,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf=cf,color={p.Color.R,p.Color.G,p.Color.B},
                material=tostring(p.Material),shape=tostring(p.Shape),collide=p.CanCollide,transparency=p.Transparency})
        end
    end
    local conflicts={}
    for _,lane in routes do
        local a,b=lane:GetAttribute("Start"),lane:GetAttribute("Finish")
        local direction=V.new(b.X-a.X,0,b.Z-a.Z).Unit
        local right=direction:Cross(V.yAxis)
        local count=math.ceil((b-a).Magnitude/2)
        local seen={}
        for j=0,count do
            local pos=a+(b-a)*j/count
            -- Keeper's eleven-wide hat, standing twelve high, sampled across every nominal lane.
            for _,offset in {-5.5,-2,0,2,5.5} do
                for _,height in {1,3,6,11.5} do
                    if math.abs(offset)>2 and height~=11.5 then continue end
                    local point=pos+right*offset+V.new(0,height,0)
                    for _,p in colliders do
                        if p~=lane and not seen[p] then
                            local q=p.CFrame:PointToObjectSpace(point); local half=p.Size/2
                            if math.abs(q.X)<half.X-0.03 and math.abs(q.Y)<half.Y-0.03 and math.abs(q.Z)<half.Z-0.03 then
                                seen[p]=true
                                table.insert(conflicts,{lane=lane:GetFullName(),obstacle=p:GetFullName(),position={pos.X,pos.Y,pos.Z},offset=offset,height=height})
                            end
                        end
                    end
                end
            end
        end
    end
    results[letter]={conflicts=conflicts,method="Static sampled lane volume, hat width11 and height11.5; not physics/NPC proof"}
    fs.writeFile("treasure/map-v3/ingame/"..letter.."-geometry.json",serde.encode("json",meshes))
    print(letter.." sampled lane conflicts: "..#conflicts)
    for j=1,math.min(#conflicts,16) do print(serde.encode("json",conflicts[j])) end
end
fs.writeFile("treasure/map-v3/ingame/collision-audit.json",serde.encode("json",results,true))
