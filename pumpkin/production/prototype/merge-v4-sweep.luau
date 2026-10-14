local fs,luau,rb,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local V,C=rb.Vector3,rb.CFrame
local path="models/meadow-keeper/anim/"
local modules={}
for _,name in {"Skeleton","Kinematics","Clips","Animator"} do
    modules[name]=luau.load(fs.readFile(path..name..".luau"),{environment={
        game={GetService=function() return {JSONDecode=function(_,s) return serde.decode("json",s) end} end},
        script={Parent={Skeleton="Skeleton",Clips="Clips"}},require=function(n) return modules[n] end,
        Vector3=V,CFrame=C
    }})()
end
local geometry=serde.decode("json",fs.readFile(path.."throw-geometry.json"))
local result={}
for _,name in {"idle","chase","patrol","return","warn","lob","fan","slam","dash"} do
    local clip=assert(modules.Clips.clips[name],name)
    local radius,height,width=0,0,0
    for frame=0,40 do
        local pose=modules.Animator.sample(name,clip.duration*frame/40)
        for _,yaw in {-.45,0,.45} do
            local p=table.clone(pose);p.Head*=C.Angles(0,yaw,0)
            local world=modules.Kinematics.world(p,C.identity)
            local minX,maxX=math.huge,-math.huge
            for _,section in geometry do
                local pivot=V.new(unpack(section.pivot))
                for _,vertex in section.vertices do
                    local v=world[section.rig_part]:PointToWorldSpace(V.new(unpack(vertex))-pivot)
                    radius=math.max(radius,math.sqrt(v.X*v.X+v.Z*v.Z));height=math.max(height,v.Y)
                    minX=math.min(minX,v.X);maxX=math.max(maxX,v.X)
                end
            end
            width=math.max(width,maxX-minX)
        end
    end
    result[name]={swept_horizontal_diameter=radius*2,max_height=height,max_width=width}
    print(name,string.format("diameter %.3f / width %.3f / height %.3f",radius*2,width,height))
end
fs.writeFile("prototype/MERGE-V4-KEEPER-SWEEP.json",serde.encode("json",{sampled_poses_per_clip=123,clips=result,
    navigation_body={width=4,height=11,agent_radius=2},Studio_continuous_sweep="UNKNOWN"},true))
for _,name in {"chase","patrol","return"} do
    assert(result[name].swept_horizontal_diameter<18,"walking visual envelope exceeds surface route")
    assert(result[name].max_height<20,"walking rig exceeds audited headroom")
end
