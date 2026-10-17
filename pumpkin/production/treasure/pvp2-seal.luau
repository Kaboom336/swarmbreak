local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local function read(path)return serde.decode('json',fs.readFile(path))end
local build=read('treasure/PVP2-BUILD.json')
local original=fs.readFile(build.backup)
local mounted=fs.readFile('slice-v2/prototype/guardian-greybox.rbxl')
assert(serde.hash('sha256',original)==build.backup_sha256,'backup changed')
assert(serde.hash('sha256',mounted)==build.mounted_sha256,'mount changed')
local before,after=rb.deserializePlace(original),rb.deserializePlace(mounted)
local runner=after.ServerScriptService.GreyboxLoopTestRunner.Source
assert(runner==fs.readFile('slice-v2/prototype/LoopTest.luau'),'mounted runner parity')
after.ServerScriptService.GreyboxLoopTestRunner.Source=before.ServerScriptService.GreyboxLoopTestRunner.Source
assert(rb.serializePlace(after)==rb.serializePlace(before),'unrelated state changed')
local function assertionLines(s)
 local lines={}
 for line in s:gmatch('[^\r\n]+') do if line:find('assert(',1,true) then lines[line]=(lines[line] or 0)+1 end end
 return lines
end
local assertions=assertionLines(runner)
for line,count in assertionLines(before.ServerScriptService.GreyboxLoopTestRunner.Source) do
 assert((assertions[line] or 0)>=count,'old assertion removed: '..line)
end
local negative,positive=read('treasure/PVP2-BEFORE.json'),read('treasure/PVP2-AFTER.json')
assert(negative.cases==864 and negative.failures==144 and not negative.target.ok)
assert(math.abs(negative.target.distance-12.262)<.001 and negative.target.hit)
assert(positive.cases==864 and positive.failures==0 and positive.target.ok)
assert(positive.stale_socket.ok and positive.stale_socket.navigations>=2)
assert(#positive.production_handoff_sequences==40 and #negative.production_handoff_sequences==40)
local files={
 'treasure/PVP2-BUILD.json','treasure/PVP2-BEFORE.json','treasure/PVP2-AFTER.json',
 'treasure/PVP2-BEFORE-CASES.json','treasure/PVP2-AFTER-CASES.json','treasure/PVP2-CONTRACTS.json',
 'treasure/pvp2-repro.luau','treasure/pvp2-checks.luau','treasure/pvp2-build.luau','treasure/PVP-SUITE-FLAKE.md',
}
for _,entry in {
 {'before','"failures": 144'}, {'after','"failures": 0'},
 {'behavior','PASS production Arena.reset and overlapping path completion epochs'},
 {'contracts','PASS nonzero origin'}, {'50-seed','PASS built binary sources'}, {'build','PASS mount;'},
} do
 local path='treasure/pvp2-'..entry[1]..'.log'
 local s=fs.readFile(path)
 if s:sub(1,2)=='\255\254' then s=s:sub(3):gsub('%z','') end -- PowerShell redirected UTF-16 ASCII logs.
 assert(s:find(entry[2],1,true),'missing PASS '..path)
 assert(not s:find('[Stack Begin]',1,true) and not s:find('NativeCommandError',1,true),'failed check '..path)
 table.insert(files,path)
end
local hashes={}
for _,path in files do hashes[path]=serde.hash('sha256',fs.readFile(path)) end
for _,name in {'repro','checks','build','seal'} do
 for level=0,2 do luau.compile(fs.readFile('treasure/pvp2-'..name..'.luau'),{optimizationLevel=level}) end
end
fs.writeFile('treasure/PVP2-FINAL.json',serde.encode('json',{
 result='PASS',before={cases=864,refusals=144,exact_distance=negative.target.distance},
 after={cases=864,refusals=0,handoff_sequences=40,stale_socket='PASS'},
 source_only_mount=true,backup_sha256=build.backup_sha256,mounted_sha256=build.mounted_sha256,
 existing_assertion_lines_preserved=true,compiled_O0_O1_O2=build.compiled_O0_O1_O2,evidence_sha256=hashes,
 live_cause_attribution='INFERRED; deterministic interrupted-hold mechanism reproduced',
 studio_play='NOT RUN',live_physics_navmesh='UNKNOWN',commit='NONE'
},true))
print('PASS sealed: 864 before/after; 144 -> 0 refusals; 40 handoffs; stale socket; existing checks; source-only mount/backup parity')
