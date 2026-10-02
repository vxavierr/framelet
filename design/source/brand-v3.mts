import {writeFileSync} from 'node:fs';
const geometry='<path d="M8 28V8h20v7H15v13z"/><path d="M36 8h20v18C56 40 41 56 25 56H8V36h7v13h10C40 49 49 39 49 26V15H36z"/>';
for(const [variant,color] of Object.entries({symbol:'#c87553',positive:'#292f35',reverse:'#faf7f0'})) {
 writeFileSync(new URL(`../concepts/frame-sweep-v3-${variant}.svg`,import.meta.url),`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="${color}"><title>Framelet</title>${geometry}</svg>\n`);
}
