import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { build } from 'esbuild';
const root = new URL('./', import.meta.url);
const read = file => readFile(new URL(file, root), 'utf8');
const [html, css, ui, bundle] = await Promise.all([
  read('index.html'), read('src/style.css'), read('src/emberwild/ui.css'),
  build({ entryPoints: [new URL('src/main.js', root).pathname], bundle: true, write: false, format: 'iife', target: ['es2022'], minify: true, legalComments: 'inline' })
]);
const notices = 'Babylon.js — Apache-2.0\n' + await read('node_modules/@babylonjs/core/license.md') + '\n' + await read('node_modules/@babylonjs/core/NOTICE.md') + '\nThree.js — MIT (legacy visual trial)\n' + await read('node_modules/three/LICENSE');
const script = '/*\n'+notices.replace(/\*\//g,'* /')+'\n*/\n'+bundle.outputFiles[0].text;
// Escape HTML script terminators even if a dependency ever includes one.
const standalone = html
  .replace('<link rel="stylesheet" href="/src/style.css">', () => '<style>' + css + '</style>')
  .replace('<link rel="stylesheet" href="/src/emberwild/ui.css">', () => '<style>' + ui + '</style>')
  .replace('href="/"', 'href="#"')
  .replace('<script type="module" src="/dist/game.js"></script>', () => '<script>\n' + script.replace(/<\/script/gi, '<\\/script') + '\n</script>');
await mkdir(new URL('dist/', root), { recursive: true });
await writeFile(new URL('dist/game.js', root), script);
await writeFile(new URL('wildfall.html', root), standalone);
await writeFile(new URL('dist/index.html', root), standalone);
await writeFile(new URL('dist/.nojekyll', root), '');
await writeFile(new URL('dist/THIRD-PARTY-NOTICES.txt',root),notices);
console.log('Built Babylon.js 3D + 2D game: wildfall.html and dist/index.html.');

// An isolated, playable art-direction study, published beside the full game.
const [trialHtml,trialCss,trialBundle]=await Promise.all([
  read('visual-trial.html'),read('src/trial.css'),
  build({entryPoints:[new URL('src/trial-main.js',root).pathname],bundle:true,write:false,format:'iife',target:['es2022'],minify:true,legalComments:'inline'})
]);
const trialScript=trialBundle.outputFiles[0].text;
const trialStandalone=trialHtml
  .replace('<link rel="stylesheet" href="/src/trial.css">',()=>'<style>'+trialCss+'</style>')
  .replace('<script type="module" src="/dist/trial.js"></script>',()=>'<script>\n'+trialScript.replace(/<\/script/gi,'<\\/script')+'\n</script>');
await writeFile(new URL('dist/trial.js',root),trialScript);
await writeFile(new URL('dist/visual-trial.html',root),trialStandalone);
console.log('Built isolated graphics study: dist/visual-trial.html.');
