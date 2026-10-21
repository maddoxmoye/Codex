"""Three original boss models and their authored attacks; approved Briar King preserved.
blender -b --factory-startup --python art/blender/build_guardians.py
"""
import bpy, math, json, importlib.util, sys
from pathlib import Path
from mathutils import Vector, Quaternion, Euler
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('king_helpers',ROOT/'art/blender/build_briar_king.py')
k=importlib.util.module_from_spec(spec);spec.loader.exec_module(k);b=k.b;m=k.m
ART=ROOT/'art/blender';OUT=ROOT/'godot-boss/assets'
SPECS={
 'frost-oracle':dict(name='The Frost Oracle',subtitle='Keeper of the white silence',wave=10,tier=2,scale=1.08,color='8ddbe8',health=2100,arrowDamage=175,melee=dict(name='Glacial Verdict',contact=1.40,warningStart=.10,warningEnd=1.40,radius=2.8,damage=48,waveDuration=.65,recovery=2.35,events=[1.40,2.00],multipliers=[1,.5],pattern='frost'),ranged=dict(name='Whiteout Constellation',releases=[1.12,1.52,1.92],warningStart=.16,speed=8.8,damage=22,recovery=2.40,shotsPerVolley=5,style='ice',hazardDuration=1.6,hazardDelay=.80,hazardDamage=8),description='A floating ice seer with a split crystal mantle, star halo and forked staff.',meleeDetail='48 impact + 24 aftershock. Two expanding frost rings.',rangedDetail='3 × 5 ice bolts · 22 per bolt. Frost patches deal 8 delayed damage.'),
 'hollow-monarch':dict(name='The Hollow Monarch',subtitle='A crown with nothing beneath',wave=15,tier=3,scale=1.15,color='bf9ce5',health=3400,arrowDamage=240,melee=dict(name='Hollow Requiem',contact=1.15,warningStart=.10,warningEnd=1.15,radius=3.2,damage=64,waveDuration=.55,recovery=2.55,events=[1.15,1.95],multipliers=[1,.5],pattern='sweep'),ranged=dict(name='Grave Procession',releases=[1.00,1.60],warningStart=.12,speed=8.8,damage=32,recovery=2.35,shotsPerVolley=5,style='void',splitAt=.26,splitAngle=.065),description='A hollow armored revenant with a spectral ribcage, torn mantle and a crescent scythe.',meleeDetail='64 outward sweep + 32 return sweep. Alternating danger sectors.',rangedDetail='2 × 5 void orbs. Each forks into two 32-damage shards.'),
 'gilded-colossus':dict(name='The Gilded Colossus',subtitle='The walking brood foundry',wave=20,tier=4,scale=1.30,color='efbb6c',health=5200,arrowDamage=325,melee=dict(name='Titan’s Toll',contact=1.45,warningStart=.08,warningEnd=1.45,radius=3.6,damage=88,waveDuration=.62,recovery=2.55,events=[1.45,2.05],multipliers=[1,.5],pattern='foundry'),ranged=dict(name='Solar Foundry',releases=[.95,1.30,1.65],warningStart=.10,speed=10.,damage=44,recovery=2.25,shotsPerVolley=7,style='solar'),summon=dict(name='Brood Furnace',releases=[1.10,1.45,1.80],perRelease=2,maxAlive=6,damage=14,health=60,contact=.56,attackInterval=1.35,warningStart=.15),description='A towering gold-and-stone engine. Its chest opens into a living enemy foundry.',meleeDetail='88 hammer impact + 44 aftershock. Largest danger area.',rangedDetail='3 × 7 solar spears · 44 per hit. Faster, denser firing lanes.')
}
ID='';F=1.;rig=None

def crystal(name,pos,radius,height,color,bone,glow=False):
 x,y,z=pos
 return b.loft(name,[((x,y,z-height*.5),.005,.005),((x,y,z-height*.13),radius,radius*.72),((x,y,z+height*.22),radius*.72,radius*.58),((x,y,z+height*.5),.002,.002)],color,bone,sides=6,kind='Luminous inlay' if glow else 'Cloth & fur',smooth=False)

def make_rig():
 global rig
 bones=[('body',(0,0,1.20),(0,0,1.75),'root'),('chest',(0,0,1.75),(0,0,2.52),'body'),('core',(0,-.24,2.02),(0,-.24,2.35),'chest'),('head',(0,0,2.52),(0,0,3.10),'chest'),('crown',(0,.015,3.08),(0,.015,3.60),'head'),('jaw',(0,-.20,2.75),(0,-.38,2.60),'head')]
 for side,s in [('.L',1),('.R',-1)]:
  bones += [('cape'+side,(s*.35,.25,2.50),(s*.55,.42,1.40),'chest'),('arm'+side,(s*.72,0,2.42),(s*1.08,.03,1.72),'chest'),('forearm'+side,(s*1.08,.03,1.72),(s*1.22,-.12,.93),'arm'+side),('hand'+side,(s*1.22,-.12,.93),(s*1.22,-.20,.63),'forearm'+side),('thigh'+side,(s*.35,0,1.28),(s*.45,.02,.68),'body'),('shin'+side,(s*.45,.02,.68),(s*.48,-.05,.17),'thigh'+side),('foot'+side,(s*.48,-.05,.17),(s*.48,-.42,.10),'shin'+side)]
  if ID=='gilded-colossus':bones += [('pod'+side,(s*.44,-.51,2.13),(s*.44,-.51,2.70),'chest')]
  else:bones += [('pod'+side,(s*.48,.16,2.48),(s*.72,.18,2.85),'chest')]
 bones += [('cannon',(1.22,-.15,1.0),(1.22,-.75,1.0),'hand.L')]
 m.rig_begin({'id':ID,'name':SPECS[ID]['name']},bones);rig=b.RIG;k.rig=rig

def arms(kind):
 for side,s in [('.L',1),('.R',-1)]:
  if kind=='ice':
   crystal('Crystal shoulder',(s*.72,0,2.42),.25,.60,'silver','arm'+side)
   b.tube('Glacial upper arm',[(s*.72,0,2.42),(s*1.08,.03,1.72)],.10,'teal_dark','arm'+side,sides=8,radii=[.13,.085])
   crystal('Faceted ice bracer',(s*1.16,-.06,1.35),.16,.68,'moon','forearm'+side)
   b.ball('Oracle casting glove',(s*1.22,-.12,.95),(.13,.12,.17),'silver','hand'+side,segments=10,rings=6)
  elif kind=='void':
   b.block('Obsidian pauldrons',(s*.75,0,2.42),(.67,.56,.36),'indigo','arm'+side,.08,rotation=(0,s*.28,0))
   b.tube('Dark armored upper arm',[(s*.72,0,2.42),(s*1.08,.03,1.72)],.16,'steel_dark','arm'+side,sides=8,radii=[.21,.14])
   b.loft('Ridged wraith vambrace',[((s*1.08,.03,1.72),.17,.15),((s*1.18,-.07,1.25),.23,.18),((s*1.22,-.12,.98),.15,.14)],'indigo','forearm'+side,sides=8,smooth=False)
   b.ball('Spectral hand',(s*1.22,-.12,.91),(.17,.14,.20),'steel_dark','hand'+side,segments=10,rings=6)
   for j in range(3):b.tube('Long silver claw',[(s*1.22+(j-1)*.09,-.20,.91),(s*1.22+(j-1)*.10,-.32,.72),(s*1.22+(j-1)*.11,-.30,.65)],.025,'silver','hand'+side,sides=5,radii=[.04,.025,.002])
  else:
   b.block('Massive foundry shoulder',(s*.77,0,2.44),(.86,.70,.58),'brass','arm'+side,.10)
   b.block('Sun plate shoulder inset',(s*.77,-.36,2.46),(.58,.055,.31),'gold','arm'+side,.03)
   for offset in [-.10,.10]:b.tube('Exposed shoulder piston',[(s*.75+offset,0,2.35),(s*1.08+offset,.03,1.72)],.07,'stone','arm'+side,'Forged details',sides=8)
   b.block('Gold segmented forearm',(s*1.17,-.05,1.36),(.49,.44,.82),'brass','forearm'+side,.075,rotation=(0,s*.12,0))
   b.block('Forearm inset rail',(s*1.17,-.285,1.39),(.20,.025,.57),'stone_light','forearm'+side,.015)
   for j in range(2):b.ball('Forearm amber rivet',(s*1.17,-.31,1.17+j*.38),(.045,.02,.045),'amber','forearm'+side,'Luminous inlay',8,6)

def legs(kind):
 for side,s in [('.L',1),('.R',-1)]:
  if kind=='ice':
   crystal('Hanging crystal calf',(s*.40,0,.55),.12,.70,'silver','shin'+side)
   crystal('Hovering ice skate',(s*.48,-.14,.18),.16,.18,'moon','foot'+side,True)
  else:
   color='steel_dark' if kind=='void' else 'stone'
   b.tube('Armored thigh',[(s*.35,0,1.28),(s*.45,.02,.68)],.18,color,'thigh'+side,sides=10,radii=[.23,.16])
   b.loft('Segmented royal greave',[((s*.48,-.02,.20),.23,.21),((s*.48,.0,.48),.24,.21),((s*.45,.02,.72),.17,.16)],'indigo' if kind=='void' else 'brass','shin'+side,sides=8,smooth=False)
   b.block('Heavy planted boot',(s*.48,-.19,.14),(.47,.69,.27),color,'foot'+side,.05)
   b.block('Boot toe cap',(s*.48,-.45,.255),(.43,.22,.17),'silver' if kind=='void' else 'gold','foot'+side,.035)

def oracle():
 arms('ice');legs('ice')
 b.loft('Glacial mantle body',[((0,.03,1.12),.22,.22),((0,.03,1.65),.33,.25),((0,.03,2.24),.38,.26),((0,.03,2.54),.22,.20)],'teal_dark','body',sides=12,smooth=False)
 crystal('Oracle heart',(0,-.26,2.10),.12,.43,'glow','core',True)
 for side,s in [('.L',1),('.R',-1)]:
  for j in range(4):
   x=s*(.12+j*.10)
   crystal('Split crystalline skirt',(x,.04+j*.018,.80+j*.12),.13,1.25-j*.12,'silver' if j%2 else 'moon','cape'+side)
  b.leaf('Split ice shoulder train',(s*.20,.22,2.50),(s*.72,.46,1.36),.23,'moon','cape'+side)
  b.leaf('Mantle pale edge',(s*.40,.25,2.40),(s*.61,.40,1.32),.055,'silver','cape'+side)
  crystal('Floating seer diamond',(s*.72,.20,2.78),.12,.42,'glow','pod'+side,True)
  b.tube('Silver chest crescent',[(s*.05,-.28,2.41),(s*.30,-.30,2.30),(s*.27,-.29,2.04)],.025,'silver','chest','Forged details',sides=6)
 b.loft('Icy oracle hood',[((0,0,2.55),.18,.20),((0,.04,2.90),.33,.29),((0,.08,3.20),.24,.24),((0,.13,3.46),.015,.02)],'silver','head',sides=12,smooth=False)
 b.ball('Recessed mask',(0,-.25,2.94),(.22,.055,.23),'teal_dark','head',segments=12,rings=8)
 for s in [-1,1]:
  m.eye('Oracle star eye',(s*.105,-.307,2.98),.042,'moon')
  b.tube('Swept crystalline brow',[(s*.02,-.30,3.09),(s*.22,-.27,3.15),(s*.29,-.16,3.30)],.027,'moon','head',sides=5)
 # A star halo, rather than the King's thorn crown.
 for i in range(9):
  a=i*math.tau/9
  crystal('Nine-point seer halo',(math.sin(a)*.48,.13,3.25+math.cos(a)*.48),.06,.25,'moon','crown',True)
 b.tube('Oracle staff shaft',[(-1.22,-.16,.12),(-1.22,-.16,2.05)],.038,'silver','hand.R','Forged details',sides=8)
 crystal('Staff glacial star',(-1.22,-.16,2.20),.16,.53,'glow','hand.R',True)
 for s in [-1,1]:b.tube('Forked staff ice prong',[(-1.22+s*.08,-.16,1.85),(-1.22+s*.24,-.16,2.15),(-1.22+s*.15,-.16,2.48)],.035,'moon','hand.R',sides=6,radii=[.045,.033,.002])
 crystal('Palm constellation focus',(1.22,-.48,1.02),.13,.33,'glow','cannon',True)

def monarch():
 arms('void');legs('void')
 b.loft('Empty sovereign cuirass',[((0,.04,1.10),.36,.29),((0,.04,1.75),.51,.34),((0,.04,2.35),.51,.34),((0,.04,2.52),.28,.24)],'ink','body',sides=10,smooth=False)
 crystal('Hollow violet heart',(0,-.35,2.08),.15,.47,'violet','core',True)
 for side,s in [('.L',1),('.R',-1)]:
  for j in range(4):
   b.tube('Spectral silver rib',[(s*.36,-.10,1.51+j*.22),(s*.39,-.30,1.61+j*.22),(s*.17,-.38,1.70+j*.22)],.035,'silver','chest','Forged details',sides=6,radii=[.05,.04,.01])
  for j in range(4):
   x=s*(.10+j*.15)
   b.leaf('Torn royal cloak',(x,.27,2.51),(x+s*.16,.45,0.68+(j%2)*.22),.21,'indigo' if j%2 else 'coal','cape'+side)
   b.tube('Cloak moon binding',[(x,.29,2.45),(x+s*.09,.41,1.40),(x+s*.13,.44,.86+(j%2)*.20)],.016,'violet','cape'+side,sides=5)
  b.tube('Swept monarch shoulder spike',[(s*.71,.0,2.56),(s*1.12,.02,2.91),(s*1.20,.06,2.77)],.06,'silver','arm'+side,sides=6,radii=[.09,.045,.002])
  crystal('Orbital soul shard',(s*.61,.19,2.79),.11,.34,'lilac','pod'+side,True)
 b.loft('Hollow high helm',[((0,.01,2.54),.16,.20),((0,.04,2.94),.31,.26),((0,.08,3.29),.26,.23),((0,.14,3.48),.08,.09)],'indigo','head',sides=10,smooth=False)
 b.ball('Empty face shadow',(0,-.23,2.96),(.24,.045,.25),'deep','head',segments=12,rings=8)
 for s in [-1,1]:
  b.tube('Severe silver face edge',[(s*.23,-.24,3.19),(s*.18,-.28,2.89),(s*.07,-.23,2.64)],.025,'silver','head',sides=6)
  b.block('Narrow ghost eye',(s*.10,-.283,3.02),(.12,.02,.032),'lilac','head',.006,rotation=(0,s*.1,s*.12),kind='Luminous inlay')
  b.tube('Sweeping horn crown',[(s*.19,.04,3.27),(s*.38,.10,3.59),(s*.32,.14,3.83),(s*.18,.15,3.90)],.05,'silver','crown','Forged details',sides=6,radii=[.08,.05,.028,.002])
 b.tube('Crescent scythe shaft',[(-1.22,-.16,.16),(-1.22,-.16,2.52)],.038,'steel_dark','hand.R','Forged details',sides=8)
 b.tube('Scythe crescent spine',[(-1.22,-.16,2.48),(-1.50,-.16,2.66),(-1.88,-.16,2.54),(-2.12,-.16,2.26)],.10,'silver','hand.R','Forged details',sides=7,radii=[.12,.14,.09,.002])
 b.leaf('Scythe spectral cutting edge',(-1.42,-.17,2.57),(-2.06,-.17,2.28),.13,'lilac','hand.R')
 b.ball('Palm void lantern',(1.22,-.46,1.02),(.14,.14,.14),'violet','cannon','Luminous inlay',12,8)
 for i in range(4):
  a=i*math.tau/4;b.tube('Void focus silver cage',[(1.22+math.cos(a)*.18,-.30,1.02+math.sin(a)*.18),(1.22+math.cos(a)*.16,-.59,1.02+math.sin(a)*.16)],.018,'silver','cannon','Forged details',sides=5)

def colossus():
 arms('gold');legs('gold')
 b.block('Walking foundry chassis',(0,.05,1.91),(1.27,.86,1.48),'stone','body',.14)
 b.block('Foundry belt',(0,-.01,1.23),(1.24,.96,.26),'brass','body',.06)
 for s in [-1,1]:
  b.block('Golden rib bastion',(s*.48,-.40,2.10),(.25,.16,1.10),'brass','chest',.055)
  for z in [1.64,2.10,2.51]:b.ball('Bastion rivet',(s*.49,-.51,z),(.052,.025,.052),'gold','chest','Forged details',8,6)
  b.block('Hinged brood furnace door',(s*.22,-.545,2.12),(.41,.10,.83),'brass','pod.L' if s==1 else 'pod.R',.035)
  b.block('Furnace door sun inlay',(s*.22,-.605,2.12),(.20,.025,.51),'gold','pod.L' if s==1 else 'pod.R',.025)
  b.block('Foundry back exhaust',(s*.40,.47,2.43),(.31,.33,.65),'brass','cape.L' if s==1 else 'cape.R',.045)
  for z in [2.24,2.39,2.54]:b.block('Exhaust vent',(s*.40,.645,z),(.23,.018,.055),'ink','cape.L' if s==1 else 'cape.R',.005)
 b.block('Dark brood hatch',(0,-.47,2.08),(.85,.08,.87),'deep','chest',.02)
 b.ball('Living furnace core',(0,-.52,2.10),(.19,.03,.30),'ember','core','Luminous inlay',12,8)
 b.block('Golden top breast lintel',(0,-.44,2.62),(1.10,.24,.27),'gold','chest',.055)
 b.block('Pile-driver hammer fist',(-1.22,-.14,.84),(.72,.66,.65),'brass','hand.R',.08)
 for j in range(3):b.block('Hammer finger block',(-1.22+(j-1)*.21,-.46,.80),(.17,.22,.47),'gold','hand.R',.025)
 for x in [-1.48,-.96]:b.ball('Hammer inset bolt',(x,-.485,.98),(.055,.025,.055),'stone','hand.R','Forged details',8,6)
 b.ball('Solar palm cannon',(1.22,-.30,.98),(.31,.40,.28),'brass','cannon',segments=12,rings=8)
 b.ball('Solar cannon aperture',(1.22,-.695,.98),(.21,.025,.20),'deep','cannon',segments=12,rings=8)
 b.ball('Solar cannon heart',(1.22,-.72,.98),(.13,.025,.12),'ember','cannon','Luminous inlay',12,8)
 for i in range(6):
  a=i*math.tau/6
  b.tube('Solar cannon muzzle ray',[(1.22+math.cos(a)*.23,-.50,.98+math.sin(a)*.23),(1.22+math.cos(a)*.23,-.78,.98+math.sin(a)*.23)],.035,'gold','cannon','Forged details',sides=6)
 b.block('Colossus angular helm',(0,.03,2.98),(.68,.58,.66),'brass','head',.095)
 b.block('Shadow visor slit',(0,-.28,3.03),(.53,.035,.18),'deep','head',.015)
 for s in [-1,1]:b.block('Furnace eye',(s*.135,-.305,3.045),(.15,.02,.055),'ember','head',.008,kind='Luminous inlay')
 b.block('Golden armored jaw',(0,-.20,2.72),(.48,.30,.19),'gold','jaw',.035)
 # A forged sun disc instead of a royal crown or horns.
 points=[(math.sin(i*math.tau/24)*.43,.21,3.12+math.cos(i*math.tau/24)*.43) for i in range(25)]
 b.tube('Forged sun halo',points,.05,'gold','crown','Forged details',sides=6)
 for i in range(7):
  a=-math.pi*.60+i*math.pi*1.2/6
  b.tube('Sun crest ray',[(math.sin(a)*.42,.21,3.12+math.cos(a)*.42),(math.sin(a)*.68,.21,3.12+math.cos(a)*.68)],.05,'brass','crown','Forged details',sides=6,radii=[.08,.002])

def pose(t,clip):
 for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0);p.scale=(1,1,1)
 spec=SPECS[ID];melee=clip=='Melee';ranged=clip=='Ranged';summon=clip=='Summon';run=clip=='Run';hit=clip=='Hit';death=clip=='Death'
 phase=t/(1.2 if run else 3.6)*math.tau;contact=spec['melee']['contact']
 raise_arm=k.ease(t,.1,contact-.32)*(1-k.ease(t,contact-.22,contact)) if melee else 0
 slam=k.ease(t,contact-.24,contact)*(1-k.ease(t,2.35,3.35)) if melee else 0
 aim=k.ease(t,.08,.70)*(1-k.ease(t,2.25,3.65)) if ranged else 0
 stagger=math.sin(min(1,t/.9)*math.pi)*(1-k.ease(t,.55,.9)) if hit else 0
 fall=k.ease(t,.1,2.50) if death else 0
 opened=k.ease(t,.10,.95)*(1-k.ease(t,2.7,4.35)) if summon else 0
 recoil=sum(math.sin(max(0,min(1,(t-at)/.20))*math.pi)*math.exp(-max(0,t-at)*4) for at in spec['ranged']['releases']) if ranged else 0
 body=rig.pose.bones['body'];body.location.y=F*((.01*math.sin(phase) if not run else -.03+abs(math.sin(phase))*.035)-(.18 if ID=='frost-oracle' else .62)*slam-.72*fall-.12*opened)
 k.rot('body',(.025 if run else 0,0,.04*stagger));k.rot('chest',(-.08*raise_arm+(.10 if ID=='frost-oracle' else .56)*slam-.14*stagger+.44*fall,-.12*aim,0))
 k.rot('head',(-.08*aim+.08*stagger+.20*fall,.04*aim,.015*math.sin(phase)));k.rot('jaw',(.03*aim+.16*fall,0,0));k.rot('crown',(.015*math.sin(phase-.4),0,.015*math.sin(phase-.7)))
 rig.pose.bones['core'].scale=(1+.05*math.sin(phase)+.09*aim,)*3
 for side,s in [('.L',1),('.R',-1)]:
  k.rot('cape'+side,(-.05*math.sin(phase-.6)-.13*raise_arm+.08*slam,.04*s*math.sin(phase),.03*s*aim))
  k.rot('pod'+side,(-.14*aim,(-s*1.25*opened if ID=='gilded-colossus' else s*.22*aim),.04*s*math.sin(phase)))
 bpy.context.view_layer.update()
 for side,s in [('.L',1),('.R',-1)]:
  shift=height=0
  if run:
   u=(t/1.2+(0 if s==1 else .5))%1
   if u<.6:shift=-.21+.42*u/.6
   else:v=(u-.6)/.4;shift=.21-.42*k.smooth(v);height=math.sin(v*math.pi)*.13
  foot=k.ik('thigh'+side,'shin'+side,Vector((s*.48,-.05+shift,.17+height))*F,Vector((s*.48,-1,.7))*F);k.world('foot'+side,foot,Quaternion())
  hand=Vector((s*1.22,-.12,.93))
  delta=Quaternion()
  if melee:
   if ID=='frost-oracle':
    if s==-1:hand=hand.lerp(Vector((-.85,-.20,2.15)),raise_arm).lerp(Vector((-1.0,-.65,1.01)),slam)
    else:hand=hand.lerp(Vector((.8,-.40,1.8)),raise_arm)
   elif ID=='hollow-monarch':
    sweep1=k.ease(t,.55,1.15);sweep2=k.ease(t,1.4,1.95);recover=k.ease(t,2.2,3.45)
    if s==-1:
     hand=Vector((-1.22,-.12,.93)).lerp(Vector((-1.12,-.45,1.85)),k.ease(t,0,.55));hand.x+=1.35*sweep1-1.50*sweep2;hand=hand.lerp(Vector((-1.22,-.12,.93)),recover)
     delta=Euler((.10,.0,-1.05*sweep1+1.2*sweep2)).to_quaternion()
    else:hand=hand.lerp(Vector((.8,-.3,1.40)),raise_arm)
   else:
    if s==-1:hand=hand.lerp(Vector((-.62,-.08,3.60)),raise_arm).lerp(Vector((-.76,-1.05,.50)),slam)
    else:hand=hand.lerp(Vector((.95,-.38,1.13)),slam)
  if ranged:
   if s==1:hand=hand.lerp(Vector((.70,-.55,2.10)),aim);hand.y+=.10*recoil;delta=Quaternion(Vector((1,0,0)),.16*aim)
   elif ID=='frost-oracle':hand=hand.lerp(Vector((-.95,-.25,1.80)),aim)
   elif ID=='hollow-monarch':hand=hand.lerp(Vector((-1.35,.0,1.25)),aim)
  if summon:hand=hand.lerp(Vector((s*1.40,-.22,1.85)),opened)
  if run:hand+=Vector((0,s*.16*math.sin(phase),.03))
  hand+=Vector((s*.10,.12,.03))*stagger
  if death:hand=hand.lerp(Vector((s*1.1,-.63,.50)),fall)
  reached=k.ik('arm'+side,'forearm'+side,hand*F,Vector((s*1.8,.1,2.0))*F);k.world('hand'+side,reached,delta)
 bpy.context.view_layer.update()

def build(id):
 global ID,F,rig
 ID=id;spec=SPECS[id];F=spec['scale'];bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);b.MATS.clear()
 for image in list(bpy.data.images):bpy.data.images.remove(image)
 image=bpy.data.images.load(str(ART/'briar-king-palette.png'));image.name='Wildfall Palette';image.pack()
 make_rig();{'frost-oracle':oracle,'hollow-monarch':monarch,'gilded-colossus':colossus}[id]()
 mesh=m.join_parts(spec['name']+' / original skin',rig)
 # Scale rest geometry and rest bones before baking, keeping exported object transforms at identity.
 for v in mesh.data.vertices:v.co*=F
 bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 for bone in rig.data.edit_bones:bone.head*=F;bone.tail*=F
 bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
 clips={'Idle':3.6,'Run':1.2,'Melee':3.6,'Ranged':3.8,'Hit':.9,'Death':3.0}
 if 'summon' in spec:clips['Summon']=4.6
 actions={};rig.animation_data_create()
 for clip,length in clips.items():
  action=bpy.data.actions.new(spec['name']+' / '+clip);rig.animation_data.action=action
  times={i/30 for i in range(int(length*30)+1)}|{length}
  markers=spec['melee']['events'] if clip=='Melee' else spec['ranged']['releases'] if clip=='Ranged' else spec.get('summon',{}).get('releases',[]) if clip=='Summon' else []
  for at in markers:times|={at-.01,at,at+.04}
  for t in sorted(times):
   bpy.context.scene.frame_set(1+int(t*30));pose(t,clip)
   for p in rig.pose.bones:
    p.keyframe_insert('rotation_quaternion',frame=1+t*30,group=p.name);p.keyframe_insert('location',frame=1+t*30,group=p.name);p.keyframe_insert('scale',frame=1+t*30,group=p.name)
  actions[clip]=action;tr=rig.animation_data.nla_tracks.new();tr.name=clip;tr.strips.new(clip,1,action);tr.mute=True;rig.animation_data.action=None
 for tr in rig.animation_data.nla_tracks:tr.mute=False
 bpy.context.scene.render.fps=30;bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(OUT/(id+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
 for tr in rig.animation_data.nla_tracks:tr.mute=True
 rig.animation_data.action=actions['Idle'];bpy.context.scene.frame_set(1);pose(0,'Idle')
 sockets={}
 points=[('muzzle','cannon',(1.22,-.76,1.0)),('breech','cannon',(1.22,-.25,1.0)),('knuckle','hand.R',(-1.22,-.22,.53)),('heart','core',(0,-.4,2.08)),('hatch','chest',(0,-.72,2.10)),('staffTip','hand.R',(-1.22,-.16,.12))]
 for name,bone,point in points:sockets[name]={'bone':bone,'local':list(rig.data.bones[bone].matrix_local.inverted()@(Vector(point)*F))}
 mesh.data.calc_loop_triangles();bounds=[Vector(v) for v in mesh.bound_box]
 meta={**{key:val for key,val in spec.items() if key!='scale'},'id':id,'file':'assets/'+id+'.glb','clips':clips,'bones':sum(x.use_deform for x in rig.data.bones),'triangles':len(mesh.data.loop_triangles),'materials':len(mesh.data.materials),'heightMeters':max(v.z for v in bounds),'sockets':sockets,'hitCenter':2.08*F,'hitRadius':.55*F,'healthBone':'crown','healthOffset':1.0*F,'notes':'Original Blender boss study. Damage and mechanics are proposed values for this preview, not campaign balance.'}
 (OUT/(id+'-motion.json')).write_text(json.dumps(meta,indent=2)+'\n')
 studio=bpy.data.collections.new(spec['name']+' / studio');bpy.context.scene.collection.children.link(studio)
 def light(name,pos,power,color):
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=5;data.color=color;ob=bpy.data.objects.new(name,data);studio.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,2))-ob.location).to_track_quat('-Z','Y').to_euler()
 light('Warm key',(-5,-6,7),1050,(1,.86,.69));light('Cool fill',(5,-2,4),800,(.64,.82,1));light('Edge',(0,5,6),1500,(.72,1,.85))
 world=bpy.data.worlds.new('Guardian studio');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.055,.09,.10,1);world.node_tree.nodes['Background'].inputs[1].default_value=.4;bpy.context.scene.world=world
 data=bpy.data.cameras.new('Guardian portrait');cam=bpy.data.objects.new('Guardian portrait',data);studio.objects.link(cam);cam.location=(-5,-8,4.6);focus=Vector((0,0,meta['heightMeters']*.50));cam.rotation_euler=(focus-cam.location).to_track_quat('-Z','Y').to_euler();data.type='ORTHO';data.ortho_scale=max(4.9,meta['heightMeters']*1.23)
 scene=bpy.context.scene;scene.camera=cam;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.render.resolution_x=1200;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ART/'renders'/(id+'.png'));scene.frame_end=139
 bpy.ops.wm.save_as_mainfile(filepath=str(ART/(id+'.blend')),compress=True)
 print('GUARDIAN_EXPORTED',id,json.dumps(meta),flush=True)
 if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)

if __name__=='__main__':
 for id in SPECS:build(id)
