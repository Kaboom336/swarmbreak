-- Geometry adapter for the existing Scene.meadow entry point. Only enable after coordinate migration.
-- The current guardian place is deliberately untouched.
local Loader = {}
local Builder = require(script.Parent.Builder)
function Loader.wrap(legacy)
    return function(parent, origin, layout, make)
        if workspace:GetAttribute("UseMeadowV4") ~= true then
            return legacy(parent, origin, layout, make)
        end
        -- Preserve live handles created by Arena.build. Never import stand-in into the real Keeper place.
        local handles = {Guardian=true, ThrowArm=true, ReturnPortal=true, SafePadAndApron=true,
            SafeEntryPad=true, SafeWestApron=true}
        for _, item in parent:GetChildren() do
            if handles[item.Name] then
                item.Parent = parent
            else
                -- Live handles may have been parented under legacy chunk models.
                for _, child in item:GetChildren() do
                    if handles[child.Name] then child.Parent = parent end
                end
                item:Destroy()
            end
        end
        local meadow = Builder.build(parent, origin)
        for _, part in meadow:GetChildren() do
            if part:GetAttribute("MeadowV4Category") == "keeper"
                or part.Name == "GoldenAcorn" or part.Name == "AcornCap" or part.Name == "AcornStem"
            then part:Destroy() end
        end
        parent:SetAttribute("MeadowV4CoordinateMigrationRequired", false)
        parent:SetAttribute("MeadowV4Summit", Vector3.new(0,48,-96))
        parent:SetAttribute("MeadowV4Portal", Vector3.new(0,0,136))
        return meadow
    end
end
return Loader
