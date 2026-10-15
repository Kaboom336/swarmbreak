-- Binary generated-art packaging; all authored edits use apply_patch.
local fs, net = require('@lune/fs'), require('@lune/net')
local source = 'C:/Users/zerha/.codex/generated_images/01a13a9a-edaf-7be2-aeb1-a9ba24ae6b10/exec-173f6731-3234-4ad4-9b8b-d3d817d71d69.png'
fs.writeFile('treasure/cave-v2/concept-v2.1.png', fs.readFile(source))
local ok, response = pcall(net.request, 'https://cdn.static.pikoya.com/robloxgo/games/10660791703/thumbnail_4')
if ok and response.ok then
    fs.writeFile('treasure/cave-v2/reference-cart-ride-around-nothing.jpg', response.body)
    print('reference downloaded; requires visual inspection')
else print('reference download unavailable') end
print('treasure/cave-v2/concept-v2.1.png')
