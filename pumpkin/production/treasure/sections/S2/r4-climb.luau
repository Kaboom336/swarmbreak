local rb,fs=require('@lune/roblox'),require('@lune/fs')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local serde=require('@lune/serde')
local scene=serde.decode('json',fs.readFile('treasure/sections/S2/r4-after.json'))
local shells=0
for _,q in scene.parts do if q.name=='S2_ShoulderSlopeShell' then
 shells+=1;assert(not q.collidable and not q.query and not q.touch,'new climbable shoulder')
end end
assert(shells==2)
local before=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s2r4.rbxl'))
assert(p.StarterPlayer.CharacterMaxSlopeAngle==before.StarterPlayer.CharacterMaxSlopeAngle)
fs.writeFile('treasure/sections/S2/r4-CLIMB.json',serde.encode('json',{CharacterMaxSlopeAngle=p.StarterPlayer.CharacterMaxSlopeAngle,unchanged_player_setting=true,nonphysical_slope_shells=shells,no_new_colliding_shoulder_slopes=true,original_collision_core_geometry='exact; see REMOVED-R4.json',live_Humanoid='UNKNOWN'},true))
print('PASS unchanged slope limit',p.StarterPlayer.CharacterMaxSlopeAngle,'and two nonphysical slope shells; original collision cores retained')
