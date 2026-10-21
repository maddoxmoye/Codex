export const PROGRESS_KEYS=Object.freeze({run:['wildfall-run'],all:['wildfall-run','wildfall-unlocks','wildfall-best']});
// Only progress keys are removed. Restore their previous values if an operation fails.
export function clearProgressStorage(storage,scope){
 const keys=PROGRESS_KEYS[scope];if(!keys)return false;
 let previous;
 try{previous=keys.map(key=>[key,storage.getItem(key)]);for(const key of keys)storage.removeItem(key);return true;}
 catch{if(previous)for(const [key,value] of previous){try{if(value===null)storage.removeItem(key);else storage.setItem(key,value);}catch{}}return false;}
}
