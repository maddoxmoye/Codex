import {readFile,writeFile,mkdir,copyFile,cp,stat} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'dist/models');
await mkdir(out,{recursive:true});await mkdir(path.join(root,'godot-models/.templates'),{recursive:true});
await copyFile(path.join(root,'godot-demo/.templates/web_nothreads_release.zip'),path.join(root,'godot-models/.templates/web_nothreads_release.zip'));
const env={...process.env,XDG_CACHE_HOME:process.env.XDG_CACHE_HOME||'/tmp/wildfall-godot-cache',XDG_CONFIG_HOME:process.env.XDG_CONFIG_HOME||'/tmp/wildfall-godot-config',XDG_DATA_HOME:process.env.XDG_DATA_HOME||'/tmp/wildfall-godot-data'};
for(const args of [['--headless','--path','godot-models','--editor','--import'],['--headless','--path','godot-models','--script','check_assets.gd'],['--headless','--path','godot-models','--export-release','Web',path.join(out,'roster.html')]]){
 const r=spawnSync(process.env.GODOT_BIN||'godot',args,{cwd:root,env,encoding:'utf8',maxBuffer:24*1024*1024});
 process.stdout.write(r.stdout||'');process.stderr.write(r.stderr||'');
 if(r.error||r.status!==0||/SCRIPT ERROR:|Parse Error:|Failed to export project/.test((r.stdout||'')+(r.stderr||'')))throw Error('Godot atelier export failed');
}
const generated=await readFile(path.join(out,'roster.html'),'utf8');
const config=JSON.parse(generated.match(/const GODOT_CONFIG\s*=\s*(\{[^\n]*\});/)[1]);
// Share the same engine download as the Moonwell; the studio has its own project pack.
config.executable='../godot-demo/engine';config.mainPack='roster.pck';
config.fileSizes={'roster.pck':(await stat(path.join(out,'roster.pck'))).size,'../godot-demo/engine.wasm':(await stat(path.join(root,'dist/godot-demo/engine.wasm'))).size};
const manifest=await readFile(path.join(root,'godot-models/assets/manifest.json'),'utf8');
const downloadSize=Object.values(config.fileSizes).reduce((a,b)=>a+b,0);
const html=(await readFile(path.join(root,'godot-models/web-shell.html'),'utf8')).replace('{{GODOT_CONFIG}}',()=>JSON.stringify(config)).replace('{{MANIFEST}}',()=>manifest.trim()).replace('{{DOWNLOAD_MB}}',String(Math.ceil(downloadSize/1024/1024)));
await writeFile(path.join(out,'index.html'),html);
await cp(path.join(root,'godot-models/assets'),path.join(out,'assets'),{recursive:true,filter:src=>!src.endsWith('.import')});
await copyFile(path.join(root,'art/blender/renders/roster.png'),path.join(out,'roster.png'));
const zip=spawnSync('python3',['-c',`import zipfile, pathlib
root=pathlib.Path(${JSON.stringify(root)})
with zipfile.ZipFile(root/'dist/models/wildfall-models.zip','w',zipfile.ZIP_DEFLATED) as z:
 for folder in ['art/blender','godot-models']:
  for p in (root/folder).rglob('*'):
   if p.is_file() and not any(s.startswith('.') or s=='__pycache__' for s in p.relative_to(root).parts) and not p.name.endswith('-combat.blend') and p.name not in ['build_briar_king.py','briar-king.blend','briar-king-palette.png','briar-king.png','animate_combat_roster.py','animate_companions.py','animate_monsters.py','sporecaller-motion.blend','thornback-motion.blend','hollowhart-motion.blend','animate_briarling.py','briarling-motion.blend','build_monsters.py','wildfall-monsters.blend','monster-palette.png','monster-lineup.png','animate_fox.py','fox-motion.blend','animate_rowan.py','rowan-motion.blend','rowan-draw.png'] and not p.name.endswith(('.blend1','.blend2','.import')):
    z.write(p,p.relative_to(root))
`],{cwd:root,encoding:'utf8'});
if(zip.status!==0)throw Error(zip.stderr);
console.log('Built Godot model atelier, GLB downloads and Blender source archive: dist/models/');
