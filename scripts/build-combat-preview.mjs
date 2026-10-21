import {readFile,writeFile,mkdir,copyFile,cp,stat} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'dist/combat-preview');
await mkdir(out,{recursive:true});await mkdir(path.join(root,'godot-combat/.templates'),{recursive:true});
await copyFile(path.join(root,'godot-demo/.templates/web_nothreads_release.zip'),path.join(root,'godot-combat/.templates/web_nothreads_release.zip'));
const env={...process.env,XDG_CACHE_HOME:process.env.XDG_CACHE_HOME||'/tmp/wildfall-godot-cache',XDG_CONFIG_HOME:process.env.XDG_CONFIG_HOME||'/tmp/wildfall-godot-config',XDG_DATA_HOME:process.env.XDG_DATA_HOME||'/tmp/wildfall-godot-data'};
for(const args of [['--headless','--path','godot-combat','--editor','--import'],['--headless','--path','godot-combat','--script','check_combat.gd'],['--headless','--path','godot-combat','--export-release','Web',path.join(out,'combat.html')]]){
 const r=spawnSync(process.env.GODOT_BIN||'godot',args,{cwd:root,env,encoding:'utf8',maxBuffer:24*1024*1024});
 process.stdout.write(r.stdout||'');process.stderr.write(r.stderr||'');
 if(r.error||r.status!==0||/SCRIPT ERROR:|Parse Error:|Failed to export project/.test((r.stdout||'')+(r.stderr||'')))throw Error('Godot combat export failed');
}
const generated=await readFile(path.join(out,'combat.html'),'utf8');
const config=JSON.parse(generated.match(/const GODOT_CONFIG\s*=\s*(\{[^\n]*\});/)[1]);
// Share the same engine download as the Moonwell; the studio has its own project pack.
const packVersion=createHash('sha256').update(await readFile(path.join(out,'combat.pck'))).digest('hex').slice(0,12);
const packName='combat-'+packVersion+'.pck';
await copyFile(path.join(out,'combat.pck'),path.join(out,packName));
config.executable='../godot-demo/engine';config.mainPack=packName;
config.fileSizes={[packName]:(await stat(path.join(out,'combat.pck'))).size,'../godot-demo/engine.wasm':(await stat(path.join(root,'dist/godot-demo/engine.wasm'))).size};
const downloadSize=Object.values(config.fileSizes).reduce((a,b)=>a+b,0);
const kits={};
for(const id of ['ash','briar','nyx','pip'])kits[id]=JSON.parse(await readFile(path.join(root,'godot-combat/assets',id+'.json'),'utf8'));
kits.rowan={name:'Rowan',role:'Wayfarer',color:'c4d994',description:'The original forest archer: wind, a steady bow, and eight empowered arrows.',spaceName:'Windskip',attackName:'Flock & Awe',spaceDetail:'0.19s dash; brief invulnerability.',attackDetail:'Eight arrows at 1.4× base damage.'};
const html=(await readFile(path.join(root,'godot-combat/web-shell.html'),'utf8')).replace('{{GODOT_CONFIG}}',()=>JSON.stringify(config)).replace('{{KITS}}',()=>JSON.stringify(kits)).replace('{{DOWNLOAD_MB}}',String(Math.ceil(downloadSize/1024/1024)));
await writeFile(path.join(out,'index.html'),html);
await cp(path.join(root,'godot-combat/assets'),path.join(out,'assets'),{recursive:true,filter:src=>!src.endsWith('.import')});
const zip=spawnSync('python3',['-c',`import zipfile, pathlib
root=pathlib.Path(${JSON.stringify(root)})
files=['art/blender/rowan-motion.blend','art/blender/fox-motion.blend','art/blender/animate_combat_roster.py','art/blender/animate_companions.py','art/blender/animate_rowan.py','art/blender/animate_fox.py','art/blender/build_roster.py','art/blender/wildfall-palette.png']+[f'art/blender/{id}-combat.blend' for id in ['ash','briar','nyx','pip','wolf','beetle']]
with zipfile.ZipFile(root/'dist/combat-preview/combat-studies.zip','w',zipfile.ZIP_DEFLATED) as z:
 for file in files:z.write(root/file,file)
 for p in (root/'godot-combat').rglob('*'):
  if p.is_file() and not any(s.startswith('.') or s=='__pycache__' for s in p.relative_to(root).parts) and not p.name.endswith('.import'):
   z.write(p,p.relative_to(root))
`],{cwd:root,encoding:'utf8'});
if(zip.status!==0)throw Error(zip.stderr);
console.log('Built five-character combat preview: dist/combat-preview/');
