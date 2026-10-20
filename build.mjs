import { readFile, writeFile, mkdir } from 'node:fs/promises';
const root = new URL('./', import.meta.url);
const read = file => readFile(new URL(file, root), 'utf8');
const [html, css, engine, ui] = await Promise.all(['index.html', 'src/style.css', 'src/game.js', 'src/main.js'].map(read));
const script = engine.replace(/^export /gm, '') + '\n' + ui.replace(/^import .*\n/, '');
const standalone = html
  .replace('<link rel="stylesheet" href="/src/style.css">', '<style>' + css + '</style>')
  .replace('href="/"', 'href="#"')
  .replace('<script type="module" src="/src/main.js"></script>', '<script>\n(() => {\n' + script + '\n})();\n</script>');
await writeFile(new URL('wildfall.html', root), standalone);
await mkdir(new URL('dist/', root), { recursive: true });
await writeFile(new URL('dist/index.html', root), standalone);
await writeFile(new URL('dist/.nojekyll', root), '');
console.log('Created wildfall.html and dist/index.html — ready for static hosting.');
