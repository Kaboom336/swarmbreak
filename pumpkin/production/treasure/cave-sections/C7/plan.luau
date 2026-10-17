return function(round)
 local fs,serde=require('@lune/fs'),require('@lune/serde')
 local a=serde.decode('json',fs.readFile('treasure/cave-sections/C7/ROCK-PLAN.json'))
 if round~='r1'then
  for _,g in serde.decode('json',fs.readFile('treasure/cave-sections/C7/CUE-PLAN.json'))do table.insert(a,g)end
 end
 return a
end
