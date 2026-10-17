-- Exact Roblox envelopes; rock silhouettes only in R1, frozen in R2.
return function(round)
local a={
 {name='C1_WestRockA',c={-182,5.03,127},s={12,14,12},color={76,82,107},kit=true,shape='Wedge'},
 {name='C1_WestRockB',c={-183,2.53,138},s={10,9,10},color={91,91,118},kit=true,shape='Wedge'},
 {name='C1_WestRockC',c={-183,1.53,147},s={10,7,8},color={65,74,99},kit=true,shape='Wedge'},
 {name='C1_EastRockA',c={-113,2.03,143},s={14,20,12},color={70,78,103},kit=true,shape='Wedge'},
 {name='C1_EastRockB',c={-113,-1.97,134},s={8,12,8},color={88,88,114},kit=true,shape='Wedge'},
 {name='C1_EastRockC',c={-119,-3.97,151},s={10,8,6},color={61,70,95},kit=true,shape='Wedge'},
}
-- R2 additions are selected only after R1 camera review.
if round=='r2'or round=='r3'or round=='r4'then
 for _,g in {
  {name='C1_ApronRockA',c={-130,2,114},s={6,4,6},color={79,84,109},kit=true,shape='Wedge',apronShoulder=true},
  {name='C1_ApronRockB',c={-130,1.5,123},s={6,3,8},color={91,91,118},kit=true,shape='Wedge',apronShoulder=true},
  {name='C1_ApronRockC',c={-130,1,132},s={6,2,8},color={64,72,97},kit=true,shape='Wedge',apronShoulder=true},
  {name='C1_LampBearing',c={-130,.5,137},s={2,1,2},color={65,73,97},apronShoulder=true},
  {name='C1_LampBase',c={-130,1.15,137},s={1.5,.3,1.5},color={35,37,46},material='Metal',apronShoulder=true},
  {name='C1_LampGlass',c={-130,2,137},s={1,1.4,1},color={255,187,88},material='Neon',light=true,apronShoulder=true},
  {name='C1_LampCap',c={-130,2.85,137},s={1.6,.3,1.6},color={35,37,46},material='Metal',apronShoulder=true},
 }do table.insert(a,g)end
end
if round=='r3'or round=='r4'then
 -- Increase the supported outer silhouette, keeping its checked footprint.
 a[1].s={12,30,12};a[1].c={-182,13.03,127};a[1].color={81,96,120}
 for _,g in {
  {name='C1_EastWalkRock',c={-107,4.03,132},s={8,24,8},color={70,83,107},kit=true,shape='Wedge'},
  {name='C1_NearRockCrown',c={-130,3,114},s={6,6,6},color={101,113,135},kit=true,shape='Wedge',apronShoulder=true},
 }do table.insert(a,g)end
end
if round=='r4'then
 -- R3 camera review: move visual weight to the right edge without moving feet.
 a[8].s={6,5,8};a[8].c={-130,2.5,123};a[8].color={76,92,116}
 a[9].s={6,7,8};a[9].c={-130,3.5,132};a[9].color={99,112,136}
 a[#a].s={6,2,6};a[#a].c={-130,1,114}
end
return a
end
