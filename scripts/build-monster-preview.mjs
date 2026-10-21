import {readFile,writeFile,mkdir,copyFile,cp,stat} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'dist/monster-preview');
await mkdir(out,{recursive:true});await mkdir(path.join(root,'godot-monsters/.templates'),{recursive:true});
await copyFile(path.join(root,'godot-demo/.templates/web_nothreads_release.zip'),path.join(root,'godot-monsters/.templates/web_nothreads_release.zip'));
const env={...process.env,XDG_CACHE_HOME:process.env.XDG_CACHE_HOME||'/tmp/wildfall-godot-cache',XDG_CONFIG_HOME:process.env.XDG_CONFIG_HOME||'/tmp/wildfall-godot-config',XDG_DATA_HOME:process.env.XDG_DATA_HOME||'/tmp/wildfall-godot-data'};
for(const args of [['--headless','--path','godot-monsters','--editor','--import'],['--headless','--path','godot-monsters','--script','check_assets.gd'],['--headless','--path','godot-monsters','--script','check_motion.gd'],['--headless','--path','godot-monsters','--script','check_other_motion.gd'],['--headless','--path','godot-monsters','--export-release','Web',path.join(out,'bestiary.html')]]){
 const r=spawnSync(process.env.GODOT_BIN||'godot',args,{cwd:root,env,encoding:'utf8',maxBuffer:24*1024*1024});
 process.stdout.write(r.stdout||'');process.stderr.write(r.stderr||'');
 if(r.error||r.status!==0||/SCRIPT ERROR:|Parse Error:|Failed to export project/.test((r.stdout||'')+(r.stderr||'')))throw Error('Godot bestiary export failed');
}
const generated=await readFile(path.join(out,'bestiary.html'),'utf8');
const config=JSON.parse(generated.match(/const GODOT_CONFIG\s*=\s*(\{[^\n]*\});/)[1]);
// Share the same engine download as the Moonwell; the studio has its own project pack.
const packVersion=createHash('sha256').update(await readFile(path.join(out,'bestiary.pck'))).digest('hex').slice(0,12);
const packName='bestiary-'+packVersion+'.pck';
await copyFile(path.join(out,'bestiary.pck'),path.join(out,packName));
config.executable='../godot-demo/engine';config.mainPack=packName;
config.fileSizes={[packName]:(await stat(path.join(out,'bestiary.pck'))).size,'../godot-demo/engine.wasm':(await stat(path.join(root,'dist/godot-demo/engine.wasm'))).size};
const downloadSize=Object.values(config.fileSizes).reduce((a,b)=>a+b,0);
const readManifest=await readFile(path.join(root,'godot-monsters/assets/manifest.json'),'utf8');
const html=(await readFile(path.join(root,'godot-monsters/web-shell.html'),'utf8')).replace('{{GODOT_CONFIG}}',()=>JSON.stringify(config)).replace('{{MANIFEST}}',()=>readManifest.trim()).replace('{{DOWNLOAD_MB}}',String(Math.ceil(downloadSize/1024/1024)));
await writeFile(path.join(out,'index.html'),html);
await cp(path.join(root,'godot-monsters/assets'),path.join(out,'assets'),{recursive:true,filter:src=>!src.endsWith('.import')});
await copyFile(path.join(root,'art/blender/renders/monster-lineup.png'),path.join(out,'lineup.png'));
const zip=spawnSync('python3',['-c',`import zipfile, pathlib
root=pathlib.Path(${JSON.stringify(root)})
files=['art/blender/animate_monsters.py','art/blender/sporecaller-motion.blend','art/blender/thornback-motion.blend','art/blender/hollowhart-motion.blend','art/blender/animate_briarling.py','art/blender/briarling-motion.blend','art/blender/build_monsters.py','art/blender/build_roster.py','art/blender/wildfall-monsters.blend','art/blender/monster-palette.png','art/blender/renders/monster-lineup.png']
with zipfile.ZipFile(root/'dist/monster-preview/wildfall-monsters.zip','w',zipfile.ZIP_DEFLATED) as z:
 for file in files:z.write(root/file,file)
 for p in (root/'godot-monsters').rglob('*'):
  if p.is_file() and not any(s.startswith('.') or s=='__pycache__' for s in p.relative_to(root).parts) and not p.name.endswith('.import'):
   z.write(p,p.relative_to(root))
`],{cwd:root,encoding:'utf8'});
if(zip.status!==0)throw Error(zip.stderr);
console.log('Built woodland monster preview: dist/monster-preview/');
