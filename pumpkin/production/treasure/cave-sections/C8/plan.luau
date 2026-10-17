return function(tag)
 local fs,serde=require('@lune/fs'),require('@lune/serde')
 local plan=serde.decode('json',fs.readFile('treasure/cave-sections/C8/ROCK-PLAN.json'))
 if tag~='r1' then
  local name=tag=='r2' and 'R2-ADDITIONS.json' or (tag=='r3' and 'R3-ADDITIONS.json' or 'R4-ADDITIONS.json')
  for _,g in serde.decode('json',fs.readFile('treasure/cave-sections/C8/'..name))do table.insert(plan,g)end
 end
 return plan
end
