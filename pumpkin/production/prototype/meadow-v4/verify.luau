-- Offline Rojo artifact integrity; no Studio runtime claims.
local fs = require("@lune/fs")
local rb = require("@lune/roblox")
local serde = require("@lune/serde")
local luau = require("@lune/luau")
local place = rb.deserializePlace(fs.readFile("prototype/meadow-v4.rbxl"))
local ws = place:FindFirstChildOfClass("Workspace")
assert(ws, "Workspace")
local model = ws:FindFirstChild("MeadowV4")
assert(model and model:IsA("Model"), "Rojo model loaded")
local scene = serde.decode("json", fs.readFile("prototype/meadow-v4/scene.json"))
local count, lights, anchored = 0, 0, 0
for _, p in model:GetDescendants() do
    if p:IsA("BasePart") then
        count += 1
        if p.Anchored then anchored += 1 end
        assert(p.CanTouch == false, "test geometry should not trigger touch gameplay")
    elseif p:IsA("PointLight") then lights += 1 end
end
assert(count == #scene.parts, "place and manifest part count mismatch")
assert(anchored == count, "unanchored map parts")
assert(lights > 0, "lantern lights omitted")
assert(model:FindFirstChild("GoldenAcorn"), "summit treasure missing")
assert(model:FindFirstChild("KeeperHatBrim"), "stand-in missing")
local rs = place:FindFirstChildOfClass("ReplicatedStorage")
assert(rs.MeadowV4.Builder and rs.MeadowV4.Data and rs.MeadowV4.Loader, "isolated modules missing")
local scripts = 0
for _, item in place:GetDescendants() do
    if item:IsA("LuaSourceContainer") then
        assert(luau.load(item.Source), "Luau compilation: " .. item.Name)
        scripts += 1
    end
end
print("PASS Rojo artifact: " .. count .. " anchored parts; " .. lights .. " lantern lights; acorn/stand-in/modules present")
print("PASS compile: " .. scripts .. " Luau containers (not executed in Studio)")
