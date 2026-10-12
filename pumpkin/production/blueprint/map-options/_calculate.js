// Artifact arithmetic only. No game files are loaded or changed.
const fs = require('fs');
const path = require('path');
const out = __dirname;
const gates = [[-90,-96],[-30,-96],[30,-96],[90,-96],[-60,96],[0,96],[60,96]];
const rows = [-54,-18,18,54];
const routes = [];
for (let p=0;p<8;p++) for(let z=0;z<7;z++) {
  const x = p<4 ? -67 : 67;
  const [gx,gz] = gates[z];
  const distance = 17 + Math.hypot(x-gx, rows[p%4]-gz) + 64;
  const timing = n => ({carrySpeed:16-n,outbound:distance/16,return:distance/(16-n),stealPlace:distance/16+distance/(16-n)+3,includingHatchReveal:distance/16+distance/(16-n)+11.2});
  routes.push({pen:p+1,zone:z+1,approach:[x,rows[p%4]],gate:[gx,gz],oneWayStuds:distance,onePumpkin:timing(1),threePumpkins:timing(3)});
}
const summary = {minStuds:Math.min(...routes.map(x=>x.oneWayStuds)),maxStuds:Math.max(...routes.map(x=>x.oneWayStuds)),minStealPlace:Math.min(...routes.map(x=>x.onePumpkin.stealPlace)),maxStealPlace:Math.max(...routes.map(x=>x.threePumpkins.stealPlace)),maxWithHatchReveal:Math.max(...routes.map(x=>x.threePumpkins.includingHatchReveal))};
fs.writeFileSync(path.join(out,'route-numbers.json'),JSON.stringify({evidence:'PROPOSED geometry; inferred arithmetic, not runtime testing',formula:'D=17+hypot(penApproach-gate)+64; T=D/16+D/(16-n)+3; hatch/reveal adds8.2',summary,routes},null,2));
console.log(JSON.stringify(summary));
