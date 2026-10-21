"""Original first boss: the Briar King. Editable geometry + baked attacks.
blender -b --factory-startup --python art/blender/build_briar_king.py
Floor origin, meters, Blender -Y forward; Godot +Z forward. No paid assets.
"""
import bpy, math, json, importlib.util, sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion, Euler
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('monster_helpers',ROOT/'art/blender/build_monsters.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);b=m.b
OUT=ROOT/'godot-boss/assets';ART=ROOT/'art/blender'
CLIPS={'Idle':3.6,'Run':1.2,'Melee':3.4,'Ranged':3.8,'Hit':.9,'Death':3.0}
RELEASES=[1.20,1.55,1.90];CONTACT=1.55;rig=None

def smooth(t):t=max(0,min(1,t));return t*t*(3-2*t)
def ease(t,a,z):return smooth((t-a)/(z-a))
def rot(name,angles):rig.pose.bones[name].rotation_quaternion=Euler(angles).to_quaternion()
def world(name,head,delta):
 p=rig.pose.bones[name];p.matrix=Matrix.Translation(Vector(head)) @ (delta @ p.bone.matrix_local.to_quaternion()).to_matrix().to_4x4();bpy.context.view_layer.update()
def anchor(name):
 p=rig.pose.bones[name];return p.parent.matrix @ p.parent.bone.matrix_local.inverted() @ p.bone.head_local
def ik(upper,lower,end,pole):
 p=rig.pose.bones[upper];q=rig.pose.bones[lower];start=anchor(upper);end=Vector(end);delta=end-start
 d=max(abs(p.bone.length-q.bone.length)+.001,min(delta.length,p.bone.length+q.bone.length-.001));axis=delta.normalized();end=start+axis*d
 pole=Vector(pole)-start;side=(pole-axis*pole.dot(axis)).normalized();a=(p.bone.length**2+d*d-q.bone.length**2)/(2*d);joint=start+axis*a+side*math.sqrt(max(0,p.bone.length**2-a*a))
 for bone,head,tail in [(p,start,joint),(q,joint,end)]:world(bone.name,head,(bone.bone.tail_local-bone.bone.head_local).rotation_difference((tail-head).normalized()))
 return end

def geometry():
 global rig
 d={'id':'briar-king','name':'The Briar King'}
 bones=[('body',(0,0,1.20),(0,0,1.75),'root'),('chest',(0,0,1.75),(0,0,2.52),'body'),('core',(0,-.24,2.02),(0,-.24,2.35),'chest'),('head',(0,0,2.52),(0,0,3.10),'chest'),('crown',(0,.015,3.08),(0,.015,3.60),'head'),('jaw',(0,-.20,2.75),(0,-.38,2.60),'head')]
 for side,s in [('.L',1),('.R',-1)]:
  bones += [('cape'+side,(s*.35,.25,2.50),(s*.55,.42,1.40),'chest'),('arm'+side,(s*.72,0,2.42),(s*1.08,.03,1.72),'chest'),('forearm'+side,(s*1.08,.03,1.72),(s*1.22,-.12,.93),'arm'+side),('hand'+side,(s*1.22,-.12,.93),(s*1.22,-.20,.63),'forearm'+side),('thigh'+side,(s*.35,0,1.28),(s*.45,.02,.68),'body'),('shin'+side,(s*.45,.02,.68),(s*.48,-.05,.17),'thigh'+side),('foot'+side,(s*.48,-.05,.17),(s*.48,-.42,.10),'shin'+side),('pod'+side,(s*.48,.16,2.48),(s*.72,.18,2.85),'chest')]
 bones += [('cannon',(1.22,-.15,1.0),(1.22,-.75,1.0),'hand.L')]
 m.rig_begin(d,bones);rig=b.RIG
 # Squat, layered trunk armor: a deliberate contrast to Hollowhart's antlered silhouette.
 b.loft('Ancient barrel trunk',[((0,.06,1.05),.42,.34),((0,.06,1.45),.60,.40),((0,.06,1.98),.69,.43),((0,.06,2.42),.52,.36),((0,.06,2.56),.32,.28)],'deep','body',sides=14,smooth=False)
 b.ball('Amber heart in the hollow',(0,-.40,2.08),(.19,.14,.29),'amber','core','Luminous inlay',16,10)
 for side,s in [('.L',1),('.R',-1)]:
  for j in range(4):
   z=1.45+j*.23
   b.tube('Royal split bark ribs',[(s*.40,.02,z-.05),(s*.55,-.20,z),(s*.27,-.44,z+.10)],.105,'bark_light' if j%2 else 'bark','chest',sides=8,radii=[.15,.13,.045])
   b.tube('Amber grain inlay',[(s*.47,-.26,z+.04),(s*.32,-.43,z+.11)],.014,'gold','chest','Luminous inlay',sides=4)
  b.loft('Root girdle armor',[((s*.29,.03,1.18),.30,.35),((s*.34,.02,1.40),.31,.33),((s*.33,.02,1.57),.23,.28)],'bark','body',sides=8,smooth=False)
  b.tube('Heavy trunk thigh',[(s*.35,0,1.29),(s*.42,.02,.95),(s*.45,.02,.67)],.20,'bark','thigh'+side,sides=10,radii=[.24,.22,.17])
  b.loft('Flared stump greave',[((s*.48,-.03,.18),.26,.23),((s*.48,-.02,.40),.28,.24),((s*.45,.02,.72),.19,.19)],'bark_light','shin'+side,sides=10,smooth=False)
  b.ball('Root foot',(s*.48,-.17,.13),(.27,.38,.13),'bark','foot'+side,segments=12,rings=6)
  for k in [-1,0,1]:b.tube('Ironwood claw toe',[(s*.48+k*.115,-.15,.14),(s*.48+k*.14,-.47,.09),(s*.48+k*.17,-.64,.04)],.055,'root','foot'+side,sides=6,radii=[.09,.055,.004])
  b.ball('Knotted shoulder',(s*.73,0,2.43),(.39,.36,.35),'bark','arm'+side,segments=14,rings=8)
  b.tube('Ancient bough upper arm',[(s*.72,0,2.42),(s*.93,.04,2.12),(s*1.08,.03,1.72)],.20,'bark_light','arm'+side,sides=10,radii=[.27,.22,.17])
  b.tube('Deep rooted forearm',[(s*1.08,.03,1.75),(s*1.18,-.04,1.35),(s*1.22,-.12,.95)],.22,'bark','forearm'+side,sides=10,radii=[.21,.27,.22])
  for j in range(3):
   b.leaf('Serrated shoulder leaves',(s*.46,.02,2.62),(s*(.94+j*.16),.13,2.42-j*.12),.19,'leaf_dark' if j%2 else 'moss','arm'+side)
   b.tube('Royal shoulder thorn',[(s*(.68+j*.10),.08,2.55-j*.07),(s*(.88+j*.17),.13,2.94-j*.11)],.075,'root','arm'+side,sides=6,radii=[.10,.003])
  # Solid, layered leaf mantle on two independent controls.
  for j in range(4):
   for k in range(3):
    x=s*(.12+k*.18+j*.035);z=2.46-j*.22
    b.leaf('Overlapping royal mantle',(x,.31+j*.04,z),(x+s*.09,.43+j*.06,z-.45),.16,'forest' if (j+k)%2 else 'leaf_dark','cape'+side)
  b.tube('Mantle braided trim',[(s*.22,.30,2.47),(s*.53,.49,1.91),(s*.64,.63,1.27)],.025,'gold','cape'+side,sides=6)
  b.ball('Sealed thorn seed pod',(s*.55,.20,2.66),(.18,.17,.30),'moss','pod'+side,segments=12,rings=8)
  for k in range(3):b.tube('Pod amber seam',[(s*.55+(k-1)*.07,.045,2.48),(s*.55+(k-1)*.065,.035,2.73)],.012,'amber','pod'+side,'Luminous inlay',sides=4)
 # Right arm: asymmetrical root gauntlet and curled thorn fingers, not a loose weapon.
 b.ball('Thronebreaker root gauntlet',(-1.22,-.14,.87),(.36,.32,.37),'bark_light','hand.R',segments=14,rings=8)
 for j in range(3):
  x=-1.22+(j-1)*.20
  b.tube('Hammer curled finger',[(x,-.30,1.02),(x,-.42,.74),(x,-.30,.55)],.10,'bark','hand.R',sides=7,radii=[.12,.10,.045])
  b.tube('Gauntlet knuckle thorn',[(x,-.13,1.08),(x-.05,-.14,1.40)],.055,'root','hand.R',sides=6,radii=[.075,.003])
 b.tube('Royal gauntlet binding',[(-1.55,-.09,.94),(-1.38,-.43,.96),(-1.05,-.43,.96),(-.91,-.10,.94)],.035,'gold','hand.R','Forged details',sides=6)
 # Left arm: a living seed launcher with a visibly open muzzle and claw-like petals.
 b.ball('Seed cannon body',(1.22,-.30,1.00),(.28,.43,.25),'leaf_dark','cannon',segments=16,rings=10)
 b.ball('Dark open cannon muzzle',(1.22,-.72,1.00),(.20,.025,.17),'deep','cannon',segments=14,rings=8)
 b.ball('Charged amber seed',(1.22,-.745,1.00),(.075,.025,.075),'amber','cannon','Luminous inlay',12,8)
 for k in range(6):
  a=k*math.tau/6;x=1.22+math.cos(a)*.20;z=1.0+math.sin(a)*.18
  b.tube('Petaled cannon lip',[(x,-.27,z),(x,-.59,z),(1.22+math.cos(a)*.16,-.86,1.0+math.sin(a)*.14)],.04,'root' if k%2 else 'moss','cannon',sides=6,radii=[.065,.045,.004])
 b.tube('Left wrist vine',[(.99,-.09,1.13),(1.05,-.51,1.19),(1.39,-.49,1.17)],.03,'gold','cannon',sides=6)
 # A severe carved mask, layered brow, lower jaw, and a five-point thorn crown.
 b.loft('King carved bark face',[((0,-.04,2.57),.16,.18),((0,-.04,2.78),.30,.25),((0,0,3.05),.35,.28),((0,.03,3.22),.25,.22)],'root','head',sides=12,smooth=False)
 for s in [-1,1]:
  m.eye('King eye',(s*.15,-.272,2.96),.068,'amber')
  b.tube('Deep angled royal brow',[(s*.035,-.30,3.04),(s*.20,-.29,3.10),(s*.32,-.22,3.05)],.045,'bark','head',sides=6)
  b.leaf('Bark cheek guard',(s*.27,-.19,2.89),(s*.23,-.25,2.64),.08,'bark','head')
 b.loft('King lower jaw',[((0,-.16,2.55),.13,.11),((0,-.19,2.74),.21,.12)],'bark','jaw',sides=8,smooth=False)
 for x in [-.10,0,.10]:b.tube('Root beard tassel',[(x,-.22,2.62),(x*1.3,-.22,2.40-abs(x)),(x*1.4,-.18,2.29-abs(x))],.028,'bark_light','jaw',sides=5,radii=[.04,.024,.003])
 b.tube('Crown ancient circlet',[(-.33,-.08,3.16),(-.22,-.23,3.19),(0,-.28,3.22),(.22,-.23,3.19),(.33,-.08,3.16),(.27,.18,3.18),(0,.27,3.22),(-.27,.18,3.18),(-.33,-.08,3.16)],.055,'brass','crown','Forged details',sides=7)
 for j in range(5):
  x=(j-2)*.18;height=.66-abs(j-2)*.10
  b.tube('Five sovereign crown thorns',[(x,-.02,3.16),(x*1.28,.02,3.16+height*.55),(x*1.16,-.07,3.16+height)],.07,'bark_light','crown',sides=7,radii=[.095,.065,.003])
  if j in [0,2,4]:b.ball('Crown amber bud',(x*1.28,-.015,3.16+height*.55),(.045,.03,.06),'amber','crown','Luminous inlay',10,6)
 for s in [-1,1]:
  b.leaf('Crown leaf pennant',(s*.30,.06,3.37),(s*.65,.14,3.22),.10,'sage','crown')
 return m.join_parts('The Briar King / original palette skin',rig)

def pose(t,clip):
 for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0);p.scale=(1,1,1)
 phase=t/(1.2 if clip=='Run' else 3.6)*math.tau
 melee=clip=='Melee';ranged=clip=='Ranged';run=clip=='Run';hit=clip=='Hit';death=clip=='Death'
 lift=ease(t,.10,1.0)*(1-ease(t,1.16,CONTACT)) if melee else 0
 slam=ease(t,1.15,CONTACT)*(1-ease(t,2.0,3.25)) if melee else 0
 aim=ease(t,.08,.75)*(1-ease(t,2.20,3.55)) if ranged else 0
 recoil=sum(math.sin(max(0,min(1,(t-at)/.22))*math.pi)*math.exp(-max(0,t-at)*4) for at in RELEASES) if ranged else 0
 stagger=math.sin(min(1,t/.9)*math.pi)*(1-ease(t,.55,.9)) if hit else 0
 fall=ease(t,.1,2.5) if death else 0
 body=rig.pose.bones['body'];body.location.y=(.012*math.sin(phase) if not run else -.03+abs(math.sin(phase))*.035)-.62*slam-.72*fall
 rot('body',(.035 if run else 0,0,.05*stagger))
 rot('chest',(-.10*lift+.56*slam-.13*stagger+.44*fall,-.10*aim+.03*math.sin(phase),0))
 rot('head',(.04*lift-.22*slam+.07*stagger+.25*fall,.07*aim,.01*math.sin(phase)))
 rot('jaw',(.05*aim+.09*slam+.18*fall,0,0));rot('crown',(.015*math.sin(phase-.5),0,.015*math.sin(phase-.7)))
 rig.pose.bones['core'].scale=Vector((1,1,1))*(1+.035*math.sin(phase*2)+.08*aim)
 for side,s in [('.L',1),('.R',-1)]:
  rot('cape'+side,(-.06*math.sin(phase-.5)-.18*lift+.17*slam,.06*s*math.sin(phase-.7),.04*s*aim))
  rot('pod'+side,(-.25*aim+.12*recoil,s*.18*aim,0))
 bpy.context.view_layer.update()
 for side,s in [('.L',1),('.R',-1)]:
  shift=height=0
  if run:
   u=(t/1.2+(0 if s==1 else .5))%1
   if u<.6:shift=-.21+.42*u/.6
   else:v=(u-.6)/.4;shift=.21-.42*smooth(v);height=math.sin(v*math.pi)*.13
  foot=ik('thigh'+side,'shin'+side,(s*.48,-.05+shift,.17+height),(s*.48,-1,.7));world('foot'+side,foot,Quaternion())
  rest=Vector((s*1.22,-.12,.93))
  if run:rest+=Vector((0,s*.16*math.sin(phase),.03))
  if s==-1:
   hand=rest.lerp(Vector((-.62,-.08,3.62)),lift).lerp(Vector((-.76,-1.05,.48)),slam)
   delta=Quaternion(Vector((1,0,0)),-.75*lift+.10*slam)
  else:
   hand=rest.lerp(Vector((.72,-.55,2.08)),aim);hand.y+=.10*recoil
   if melee:hand=hand.lerp(Vector((1.13,-.22,1.40)),lift).lerp(Vector((.95,-.38,1.13)),slam)
   delta=Quaternion(Vector((1,0,0)),.16*aim)
  hand+=Vector((s*.10,.12,.03))*stagger
  if death:hand=hand.lerp(Vector((s*1.1,-.63,.50)),fall)
  reached=ik('arm'+side,'forearm'+side,hand,(s*1.8,.1,2.0));world('hand'+side,reached,delta)
 bpy.context.view_layer.update()

def main():
 OUT.mkdir(parents=True,exist_ok=True);bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 palette=ART/'briar-king-palette.png';b.png(palette);image=bpy.data.images.load(str(palette));image.name='Wildfall Palette';image.pack()
 mesh=geometry();rig.animation_data_create();actions={}
 for clip,length in CLIPS.items():
  action=bpy.data.actions.new('The Briar King / '+clip);rig.animation_data.action=action
  times={i/30 for i in range(int(length*30)+1)}|{length}
  if clip=='Melee':times|={CONTACT-.01,CONTACT,CONTACT+.04}
  if clip=='Ranged':
   for at in RELEASES:times|={at-.01,at,at+.04}
  for t in sorted(times):
   bpy.context.scene.frame_set(1+int(t*30));pose(t,clip)
   for p in rig.pose.bones:
    p.keyframe_insert('rotation_quaternion',frame=1+t*30,group=p.name);p.keyframe_insert('location',frame=1+t*30,group=p.name);p.keyframe_insert('scale',frame=1+t*30,group=p.name)
  actions[clip]=action;tr=rig.animation_data.nla_tracks.new();tr.name=clip;tr.strips.new(clip,1,action);tr.mute=True;rig.animation_data.action=None
 for tr in rig.animation_data.nla_tracks:tr.mute=False
 bpy.context.scene.render.fps=30;bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
 path=OUT/'briar-king.glb';bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
 for tr in rig.animation_data.nla_tracks:tr.mute=True
 rig.animation_data.action=actions['Idle'];bpy.context.scene.frame_set(1);pose(0,'Idle')
 sockets={}
 for id,bone,point in [('muzzle','cannon',(1.22,-.86,1.0)),('breech','cannon',(1.22,-.25,1.0)),('knuckle','hand.R',(-1.22,-.30,.53)),('heart','core',(0,-.40,2.08))]:
  sockets[id]={'bone':bone,'local':list(rig.data.bones[bone].matrix_local.inverted() @ Vector(point))}
 mesh.data.calc_loop_triangles();bounds=[Vector(v) for v in mesh.bound_box]
 meta={'id':'briar-king','name':'The Briar King','subtitle':'Sovereign of the overgrowth','file':'assets/briar-king.glb','clips':CLIPS,'bones':sum(x.use_deform for x in rig.data.bones),'triangles':len(mesh.data.loop_triangles),'materials':len(mesh.data.materials),'heightMeters':max(v.z for v in bounds),'sockets':sockets,'melee':{'name':'Thronebreaker','contact':CONTACT,'warningStart':.12,'warningEnd':CONTACT,'radius':2.3,'damage':36,'waveDuration':.60,'recovery':2.0},'ranged':{'name':'Briar Decree','releases':RELEASES,'warningStart':.18,'speed':8.,'damage':16,'recovery':2.25,'shotsPerVolley':3},'health':1200,'arrowDamage':120,'hitCenter':2.06,'hitRadius':.55,'healthBone':'crown','healthOffset':.95,'notes':'Isolated original boss animation draft; damage and HP are demonstration values, not campaign balance. Bone cloth and baked analytical IK, no paid motion capture.'}
 (OUT/'briar-king-motion.json').write_text(json.dumps(meta,indent=2)+'\n');print('BRIAR_KING_EXPORTED',json.dumps(meta),flush=True)
 # Editable studio source and a real Blender beauty render for the loading card.
 studio=bpy.data.collections.new('Briar King / review studio');bpy.context.scene.collection.children.link(studio)
 def light(name,pos,power,tint,size):
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=tint;data.size=size;ob=bpy.data.objects.new(name,data);studio.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,1.8))-ob.location).to_track_quat('-Z','Y').to_euler()
 light('Warm key',(-5,-6,7),1000,(1,.83,.62),5);light('Cool fill',(5,-2,4),750,(.62,.83,1),5);light('Forest rim',(0,5,6),1500,(.7,1,.75),4)
 worlddata=bpy.data.worlds.new('Briar King studio world');worlddata.use_nodes=True;worlddata.node_tree.nodes['Background'].inputs[0].default_value=(.055,.09,.09,1);worlddata.node_tree.nodes['Background'].inputs[1].default_value=.4;bpy.context.scene.world=worlddata
 camera_data=bpy.data.cameras.new('Briar King portrait');camera=bpy.data.objects.new('Briar King portrait',camera_data);studio.objects.link(camera);camera.location=(-5,-8,4.5);camera.rotation_euler=(Vector((0,0,1.95))-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.type='ORTHO';camera_data.ortho_scale=4.65
 scene=bpy.context.scene;scene.camera=camera;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.render.resolution_x=1200;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ART/'renders/briar-king.png');scene.frame_end=115
 bpy.ops.wm.save_as_mainfile(filepath=str(ART/'briar-king.blend'),compress=True)
 if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)
if __name__=='__main__':main()
