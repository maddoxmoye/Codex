import {readFile,writeFile,mkdir,stat,copyFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'dist/godot-demo');
await mkdir(out,{recursive:true});
const command=process.env.GODOT_BIN||'godot';
const env={...process.env,XDG_CACHE_HOME:process.env.XDG_CACHE_HOME||'/tmp/wildfall-godot-cache',XDG_CONFIG_HOME:process.env.XDG_CONFIG_HOME||'/tmp/wildfall-godot-config',XDG_DATA_HOME:process.env.XDG_DATA_HOME||'/tmp/wildfall-godot-data'};
for(const args of [['--headless','--path','godot-demo','--editor','--import'],['--headless','--path','godot-demo','--export-release','Web',path.join(out,'engine.html')]]){
 const result=spawnSync(command,args,{cwd:root,env,encoding:'utf8',maxBuffer:16*1024*1024});
 process.stdout.write(result.stdout||'');process.stderr.write(result.stderr||'');
 if(result.error||result.status!==0||/SCRIPT ERROR:|Parse Error:|Failed to export project/.test((result.stdout||'')+(result.stderr||'')))throw new Error('Godot import/export failed: '+(result.error?.message||result.status));
}
const generated=await readFile(path.join(out,'engine.html'),'utf8');
const match=generated.match(/const GODOT_CONFIG\s*=\s*(\{[^\n]*\});/);
if(!match)throw new Error('Godot export configuration not found; inspect generated shell.');
const config=JSON.parse(match[1]);
const files=await Promise.all(['engine.wasm','engine.pck'].map(async file=>(await stat(path.join(out,file))).size));
const shell=(await readFile(path.join(root,'godot-demo/web-shell.html'),'utf8')).replace('{{GODOT_CONFIG}}',()=>JSON.stringify(config)).replace('{{DOWNLOAD_MB}}',String(Math.ceil(files.reduce((a,b)=>a+b,0)/1024/1024)));
await writeFile(path.join(out,'index.html'),shell);
for(const file of ['GODOT-LICENSE.txt','GODOT-COPYRIGHT.txt'])await copyFile(path.join(root,'godot-demo',file),path.join(out,file));
console.log('Built Godot mobile web study: dist/godot-demo/index.html');
