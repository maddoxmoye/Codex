import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const project=fileURLToPath(new URL('../godot-native/',import.meta.url));
const env={...process.env,XDG_CACHE_HOME:process.env.XDG_CACHE_HOME||'/tmp/wildfall-godot-cache',XDG_DATA_HOME:process.env.XDG_DATA_HOME||'/tmp/wildfall-godot-data',XDG_CONFIG_HOME:process.env.XDG_CONFIG_HOME||'/tmp/wildfall-godot-config'};
const commands=[['--editor','--import'],...['check_hunt.gd','check_animation.gd','check_run.gd','check_motion.gd','check_native.gd','check_hud.gd','check_campaign.gd'].map(name=>['--script',name])];
for(const args of commands){
 const result=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--path',project,...args],{env,encoding:'utf8',maxBuffer:32*1024*1024});
 const output=(result.stdout||'')+(result.stderr||'');
 if(result.error||result.status!==0||/SCRIPT ERROR:|Parse Error:|\bERROR:|_FAILED:/.test(output)){process.stdout.write(output);throw result.error||new Error(`Native validation failed: ${args.join(' ')}`);}
 process.stdout.write(output.split('\n').filter(line=>/_OK:|READY:/.test(line)).join('\n')+'\n');
}
