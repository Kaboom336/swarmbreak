return function(round)
 local fs,serde=require('@lune/fs'),require('@lune/serde')
 local a=serde.decode('json',fs.readFile('treasure/cave-sections/C6/ROCK-PLAN.json'))
 if round~='r1'then
  local path=round=='r2'and'CUE-PLAN.json'or'CUE-'..round..'.json'
  for _,g in serde.decode('json',fs.readFile('treasure/cave-sections/C6/'..path))do table.insert(a,g)end
 end
 return a
end
