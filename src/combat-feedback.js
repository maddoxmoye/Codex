// Both renderers share the same health bars and combat-number presentation.
export const DAMAGE_COLORS={physical:'#fff1ce',fire:'#ff6575',ice:'#83b5ff',poison:'#d08aff',pet:'#ffbf82',mythic:'#ff526d',critical:'#ffe077',thorn:'#a7dc8b'};
export function formatDamage(amount){
 if(amount<.01)return '<0.01';
 return Number(amount.toFixed(amount<.1?2:1)).toString();
}
export function enemyLabelHeight(e){
 if(e.kind==='boss')return [1.9,1.65,1.9,1.85][e.tier-1]||1.9;
 return ({archer:.85,shaman:1.02,bomber:.75,boar:.65,wisp:.55,brute:.5,stalker:.78,juggernaut:.95}[e.kind]||.4)*(e.elite?2.15:1.8)+.16;
}
export function drawCombatFeedback(ctx,game,project,width,height){
 ctx.save();ctx.textAlign='center';ctx.textBaseline='bottom';ctx.lineJoin='round';
 for(const e of game.enemies){
  if(e.hp<=0)continue;
  const point=project(e.x,e.y,enemyLabelHeight(e),e.r);if(!point||point.x< -60||point.x>width+60||point.y< -30||point.y>height+20)continue;
  const max=e.maxHp||e.hp,ratio=Math.max(0,Math.min(1,e.hp/max)),w=e.kind==='boss'?74:e.elite?44:36,x=point.x-w/2,y=point.y;
  ctx.fillStyle='#101710e8';ctx.fillRect(x-2,y-2,w+4,9);ctx.fillStyle=e.kind==='boss'?'#f48b87':e.elite?'#f3cb81':'#a4d887';ctx.fillRect(x,y,w*ratio,5);
  ctx.strokeStyle=e.hitFlash>0?'#fff8df':'#223425';ctx.lineWidth=1;ctx.strokeRect(x-1,y-1,w+2,7);
  ctx.font='600 9px system-ui,sans-serif';ctx.lineWidth=3;ctx.strokeStyle='#101710';ctx.strokeText(`${Math.ceil(e.hp)}/${Math.ceil(max)}`,point.x,y-3);ctx.fillStyle='#e6ebdb';ctx.fillText(`${Math.ceil(e.hp)}/${Math.ceil(max)}`,point.x,y-3);
 }
 for(const number of game.damageNumbers||[]){
  const point=project(number.x,number.y,number.height,number.r);if(!point||point.x< -70||point.x>width+70||point.y< -70||point.y>height+70)continue;
  const progress=1-number.life/number.maxLife,x=point.x+number.lane*8,y=point.y-15-progress*40;
  ctx.globalAlpha=Math.min(1,number.life/.25);ctx.font=`800 ${number.critical?18:14}px system-ui,sans-serif`;ctx.lineWidth=3;ctx.strokeStyle='#102015';
  const text=formatDamage(number.amount)+(number.critical?'!':'');ctx.strokeText(text,x,y);ctx.fillStyle=DAMAGE_COLORS[number.critical?'critical':number.element]||DAMAGE_COLORS.physical;ctx.fillText(text,x,y);
 }
 ctx.restore();
}
