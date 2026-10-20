import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { build } from 'esbuild';
const root = new URL('./', import.meta.url);
const read = file => readFile(new URL(file, root), 'utf8');
const [html, css, bundle] = await Promise.all([
  read('index.html'), read('src/style.css'),
  build({ entryPoints: [new URL('src/main.js', root).pathname], bundle: true, write: false, format: 'iife', target: ['es2022'], minify: true, legalComments: 'inline' })
]);
const script = bundle.outputFiles[0].text;
// Escape HTML script terminators even if a dependency ever includes one.
const standalone = html
  .replace('<link rel="stylesheet" href="/src/style.css">', () => '<style>' + css + '</style>')
  .replace('href="/"', 'href="#"')
  .replace('<script type="module" src="/dist/game.js"></script>', () => '<script>\n' + script.replace(/<\/script/gi, '<\\/script') + '\n</script>');
await mkdir(new URL('dist/', root), { recursive: true });
await writeFile(new URL('dist/game.js', root), script);
await writeFile(new URL('wildfall.html', root), standalone);
await writeFile(new URL('dist/index.html', root), standalone);
await writeFile(new URL('dist/.nojekyll', root), '');
console.log('Built 3D + 2D game: wildfall.html and dist/index.html.');
