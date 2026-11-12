// Renders icons/harbour-health.svg into the launcher PNGs
// (icons/<size>x<size>/harbour-health.png, the sizes in SAILFISHAPP_ICONS).
//
// Usage (resvg-js installed in the current directory, outside the repository):
//   npm install @resvg/resvg-js@2.6.2
//   node <repo>/tools/render_app_icon.js <repo>
'use strict';
const fs = require('fs');
const path = require('path');
const { Resvg } = require(require.resolve('@resvg/resvg-js', { paths: [process.cwd()] }));

const repo = process.argv[2] || path.join(__dirname, '..');
const svg = fs.readFileSync(path.join(repo, 'icons', 'harbour-health.svg'));
for (const size of [86, 108, 128, 172]) {
    const dir = path.join(repo, 'icons', size + 'x' + size);
    fs.mkdirSync(dir, { recursive: true });
    const png = new Resvg(svg, { fitTo: { mode: 'width', value: size } }).render().asPng();
    fs.writeFileSync(path.join(dir, 'harbour-health.png'), png);
}
console.log('rendered launcher icons');
