"""Original Blender attack/motion studies for Sporecaller, Thornback and Hollowhart.
blender -b --factory-startup --python art/blender/animate_monsters.py
Static approved models and Briarling's separate motion study are preserved.
"""
import bpy, math, json, importlib.util, sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion, Euler
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('monster_builder',ROOT/'art/blender/build_monsters.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);b=m.b
OUT=ROOT/'godot-monsters/assets';rig=None;SPEC=None
SPECS={
 'sporecaller':dict(clips={'Idle':2.8,'Run':1.0,'Attack':2.2,'Hit':.7,'Death':1.6},attackType='spore',attackContact=.72,attackRecovery=1.65,windupTime=.50,health=90,arrowDamage=30,dummyDamage=14,hitCenter=.76,hitRadius=.31,healthBone='cap',healthOffset=.74,flightTime=1.05,damageStyle='spores',runLabel='Waddle',attackLabel='Spore lob',bones=9),
 'thornback':dict(clips={'Idle':3.2,'Run':.88,'Attack':2.65,'Hit':.8,'Death':1.8},attackType='charge',attackContact=1.23,attackRecovery=1.65,windupTime=.62,health=120,arrowDamage=40,dummyDamage=24,hitCenter=.70,hitRadius=.40,healthBone='body',healthOffset=1.02,chargeStart=.78,chargeEnd=1.25,chargeDistance=1.65,damageStyle='armor',runLabel='Heavy trot',attackLabel='Tusks down',bones=17),
 'hollowhart':dict(clips={'Idle':3.6,'Run':1.4,'Attack':3.1,'Hit':.95,'Death':2.2},attackType='slam',attackContact=1.42,attackRecovery=2.0,windupTime=.90,health=180,arrowDamage=60,dummyDamage=36,hitCenter=1.43,hitRadius=.40,healthBone='head',healthOffset=1.37,damageStyle='heart',runLabel='Heavy walk',attackLabel='Root hammer',bones=18)
}
def smooth(t):
    t=max(0,min(1,t));return t*t*(3-2*t)
def ease(t,a,z):return smooth((t-a)/(z-a))
def rot(name,angles):rig.pose.bones[name].rotation_quaternion=Euler(angles,'XYZ').to_quaternion()
def world_bone(name,head,delta):
    p=rig.pose.bones[name];p.matrix=Matrix.Translation(Vector(head)) @ (delta @ p.bone.matrix_local.to_quaternion()).to_matrix().to_4x4();bpy.context.view_layer.update()
def anchor(name):
    p=rig.pose.bones[name];return p.parent.matrix @ p.parent.bone.matrix_local.inverted() @ p.bone.head_local

def ik(upper,lower,end,pole):
    p=rig.pose.bones[upper];q=rig.pose.bones[lower];start=anchor(upper);end=Vector(end);delta=end-start
    distance=max(abs(p.bone.length-q.bone.length)+.001,min(delta.length,p.bone.length+q.bone.length-.001));axis=delta.normalized();end=start+axis*distance
    pole=Vector(pole)-start;side=(pole-axis*pole.dot(axis)).normalized();a=(p.bone.length**2+distance**2-q.bone.length**2)/(2*distance)
    joint=start+axis*a+side*math.sqrt(max(0,p.bone.length**2-a*a))
    for bone,head,tail in [(p,start,joint),(q,joint,end)]:world_bone(bone.name,head,(bone.bone.tail_local-bone.bone.head_local).rotation_difference((tail-head).normalized()))
    return end

def step(t,cycle,offset,stride,lift):
    u=(t/cycle+offset)%1
    if u<.60:return -stride*.5+stride*u/.60,0
    v=(u-.60)/.40;return stride*.5-stride*smooth(v),math.sin(v*math.pi)*lift

def spore_pose(t,clip):
    cycle=SPEC['clips'][clip];phase=t/cycle*math.tau;run=clip=='Run';attack=clip=='Attack';hit=clip=='Hit';dead=clip=='Death'
    charge=ease(t,.1,.6)*(1-ease(t,.72,.92)) if attack else 0
    pop=math.sin(max(0,min(1,(t-.72)/.40))*math.pi) if attack else 0
    recoil=math.sin(min(1,t/.7)*math.pi)*(1-ease(t,.42,.7)) if hit else 0
    fall=ease(t,.12,1.25) if dead else 0
    body=rig.pose.bones['body'];body.location.y=(abs(math.sin(phase))*.04 if run else .008*math.sin(phase))-.11*charge+.06*pop-.16*fall
    body.scale=(1+.07*charge+.18*fall,1-.11*charge-.40*fall,1+.07*charge+.16*fall)
    rot('body',(.035*math.sin(phase),.04*math.sin(phase) if run else .32*fall,0))
    rot('head',(-.10*charge+.13*pop-.16*recoil,0,.035*math.sin(phase-.4)))
    rot('cap',(.04*math.sin(phase-.5)+.15*recoil-.10*pop,.035*math.sin(phase-.8),.04*math.sin(phase-.8)+.14*fall))
    rig.pose.bones['cap'].scale=(1+.05*charge+.09*fall,1-.14*charge-.25*fall,1+.05*charge+.09*fall)
    bpy.context.view_layer.update()
    for side,s in [('.L',1),('.R',-1)]:
        rot('arm'+side,(-.55*charge+.25*pop+s*.20*math.sin(phase) if run else -.55*charge+.25*pop,.05*s*recoil,s*(.05+.28*charge+.22*recoil+.3*fall)))
        rot('pod'+side,(.14*math.sin(phase-.7+s*.2)+.30*pop-.23*recoil,0,.10*s*math.sin(phase-.7)))
        y=z=0
        if run:y,z=step(t,1.0,0 if s==1 else .5,.16,.055)
        world_bone('foot'+side,(s*(.20+.025*fall),y,.23+z),Quaternion())


def boar_pose(t,clip):
    run=clip=='Run';attack=clip=='Attack';hit=clip=='Hit';dead=clip=='Death';cycle=.88 if run else 3.2;phase=t/cycle*math.tau
    brace=ease(t,.12,.65)*(1-ease(t,1.40,2.55)) if attack else 0
    charge=ease(t,.74,.83)*(1-ease(t,1.30,1.47)) if attack else 0
    recoil=math.sin(min(1,t/.8)*math.pi)*(1-ease(t,.5,.8)) if hit else 0
    fall=ease(t,.15,1.35) if dead else 0
    body=rig.pose.bones['body'];body.location.z=-(abs(math.sin(phase))*.022 if run else .006*math.sin(phase))+.05*brace+.25*fall
    rot('body',(.01*math.sin(phase),.98*fall,.025*math.sin(phase) if run else 0))
    rot('chest',(.08*brace-.13*recoil,0,.035*math.sin(phase) if run else 0))
    rot('head',(.30*brace-.15*recoil,0,.025*math.sin(phase-.3)))
    rot('jaw',(.10*charge+.10*recoil,0,0));rot('tail',(.08*math.sin(phase-.5),.10*math.sin(phase),0))
    bpy.context.view_layer.update()
    for side,s in [('.L',1),('.R',-1)]:
        for prefix,y in [('front',-.35),('back',.45)]:
            shift=lift=0
            if run or charge>.01:
                gait=t if run else (t-.78)*1.6
                shift,lift=step(gait,.88,0 if (s==1)==(prefix=='front') else .5,.34,.105)
                if attack:shift*=charge;lift*=charge
            target=(s*.32,y-.08+shift,.09+lift)
            if dead:
                rot(prefix+side,(.6*fall,0,s*.25*fall));rot(prefix+'_hoof'+side,(-.4*fall,0,0));continue
            paw=ik(prefix+side,prefix+'_hoof'+side,target,(s*.32,(-1 if prefix=='front' else 1),.25))
            world_bone(prefix+'_paw'+side,paw,Quaternion())


def guardian_pose(t,clip):
    run=clip=='Run';attack=clip=='Attack';hit=clip=='Hit';dead=clip=='Death';cycle=1.4 if run else 3.6;phase=t/cycle*math.tau
    raise_arm=ease(t,.10,.95)*(1-ease(t,1.08,1.43)) if attack else 0
    slam=ease(t,1.02,1.42)*(1-ease(t,1.95,2.95)) if attack else 0
    recoil=math.sin(min(1,t/.95)*math.pi)*(1-ease(t,.58,.95)) if hit else 0
    fall=ease(t,.20,1.85) if dead else 0
    body=rig.pose.bones['body'];body.location.y=(-.045+abs(math.sin(phase))*.035 if run else .009*math.sin(phase))-.43*slam-.60*fall
    rot('body',(.04 if run else 0, .035*math.sin(phase) if run else 0,0))
    rot('chest',(-.10*raise_arm+.72*slam-.18*recoil+.55*fall,.035*math.sin(phase),.07*recoil))
    rot('head',(.08*raise_arm-.28*slam+.12*recoil-.10*fall,.03*math.sin(phase-.4),0))
    rig.pose.bones['core'].scale=(1+.045*math.sin(phase*2)+.15*recoil,)*3
    for side,s in [('.L',1),('.R',-1)]:rot('antler'+side,(.018*math.sin(phase-.5),s*.025*recoil,.025*s*math.sin(phase-.4)))
    bpy.context.view_layer.update()
    for side,s in [('.L',1),('.R',-1)]:
        shift=lift=0
        if run:shift,lift=step(t,1.4,0 if s==1 else .5,.40,.12)
        foot=ik('leg'+side,'foot'+side,(s*(.32+.03*fall),-.13+shift-.10*fall,.10+lift),(s*.32,-1,.6))
        world_bone('toe'+side,foot,Quaternion())
        rest=Vector((s*.74,-.12,.83))
        if run:rest+=Vector((0,s*.14*math.sin(phase),.02))
        raised=Vector((s*.47,-.12,2.60))
        strike=Vector((s*.44,-.80,.29))
        hand=rest.lerp(raised,raise_arm).lerp(strike,slam)
        if hit:hand+=Vector((s*.14,.12,.08))*recoil
        if dead:hand=hand.lerp(Vector((s*.56,-.65,.22)),fall)
        reached=ik('arm'+side,'forearm'+side,hand,(s*1.35,.15,1.65))
        world_bone('hand'+side,reached,Quaternion(Vector((1,0,0)),-.65*raise_arm+.3*slam))


def pose(t,clip):
    for p in rig.pose.bones:
        p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0);p.scale=(1,1,1)
    {'sporecaller':spore_pose,'thornback':boar_pose,'hollowhart':guardian_pose}[SPEC['id']](t,clip)
    bpy.context.view_layer.update()


def refine_rig(id):
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    if id=='thornback':
        for side,s in [('.L',1),('.R',-1)]:
            for prefix,y in [('front',-.35),('back',.45)]:b.bone(prefix+'_paw'+side,(s*.32,y-.08,.09),(s*.32,y-.24,.06),prefix+'_hoof'+side)
    if id=='hollowhart':
        for side,s in [('.L',1),('.R',-1)]:b.bone('toe'+side,(s*.32,-.13,.10),(s*.32,-.40,.05),'foot'+side)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    for ob in b.PARTS:
        if id=='thornback' and ob.name.startswith(('Cloven dark hoof','Hoof split')):
            old=ob.vertex_groups[0].name;ob.vertex_groups.clear();g=ob.vertex_groups.new(name=old.replace('_hoof','_paw'));g.add(list(range(len(ob.data.vertices))),1,'REPLACE')
        elif id=='thornback' and ob.name.startswith('Stocky plated leg'):
            old=ob.vertex_groups[0].name;side=old[-2:];prefix=old[:-2];ob.vertex_groups.clear();up=ob.vertex_groups.new(name=old);down=ob.vertex_groups.new(name=prefix+'_hoof'+side)
            for v in ob.data.vertices:
                w=smooth((v.co.z-.20)/.20)
                if w>0:up.add([v.index],w,'REPLACE')
                if w<1:down.add([v.index],1-w,'REPLACE')
        elif id=='hollowhart' and ob.name.startswith('Guardian root toes'):
            side=ob.vertex_groups[0].name[-2:];ob.vertex_groups.clear();g=ob.vertex_groups.new(name='toe'+side);g.add(list(range(len(ob.data.vertices))),1,'REPLACE')


def capture(d):
    global rig
    rig=b.RIG;id=d['id'];refine_rig(id);mesh=m.join_parts(d['name']+' / motion skin',rig);rig.animation_data_create();actions={}
    for clip,length in SPEC['clips'].items():
        action=bpy.data.actions.new(d['name']+' / '+clip);rig.animation_data.action=action
        for t in sorted(set([i/30 for i in range(int(length*30)+1)]+[length,SPEC['attackContact']] if clip=='Attack' else [i/30 for i in range(int(length*30)+1)]+[length])):
            bpy.context.scene.frame_set(1+int(t*30));pose(t,clip)
            for p in rig.pose.bones:
                for path in ['location','rotation_quaternion','scale']:p.keyframe_insert(path,frame=1+t*30,group=p.name)
        actions[clip]=action;track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action);track.mute=True;rig.animation_data.action=None
    for tr in rig.animation_data.nla_tracks:tr.mute=False
    bpy.context.scene.render.fps=30;bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
    path=OUT/(id+'-motion.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
    for tr in rig.animation_data.nla_tracks:tr.mute=True
    rig.animation_data.action=actions['Attack'];bpy.context.scene.frame_set(1+int(SPEC['windupTime']*30));bpy.context.scene.frame_end=1+round(SPEC['clips']['Attack']*30)
    sockets={}
    if id=='thornback':sockets['nose']=dict(bone='head',local=list(rig.data.bones['head'].matrix_local.inverted() @ Vector((0,-1.175,.55))))
    if id=='sporecaller':sockets['launch']=dict(bone='head',local=list(rig.data.bones['head'].matrix_local.inverted() @ Vector((0,-.30,.96))))
    if id=='hollowhart':
        for side,s in [('L',1),('R',-1)]:sockets['hand'+side]=dict(bone='hand.'+side,local=list(rig.data.bones['hand.'+side].matrix_local.inverted() @ Vector((s*.76,-.27,.63))))
    metadata={**SPEC,'name':d['name']+' / motion study','file':'assets/'+path.name,'triangles':len(mesh.data.loop_triangles),'sockets':sockets,'notes':'Authored Blender clips; isolated attack timing and damage study, not campaign AI or balance.'}
    assert sum(bone.use_deform for bone in rig.data.bones)==SPEC['bones']
    (OUT/(id+'-motion.json')).write_text(json.dumps(metadata,indent=2)+'\n')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender'/(id+'-motion.blend')),compress=True)
    print('MONSTER_MOTION_EXPORTED',id,metadata['triangles'],metadata['bones'],flush=True)

for id in SPECS:
    if '--' in sys.argv and sys.argv[sys.argv.index('--')+1:] and id not in sys.argv[sys.argv.index('--')+1:]:continue
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for image in list(bpy.data.images):
        if image.name.startswith('Wildfall Palette'):bpy.data.images.remove(image)
    b.MATS.clear();image=bpy.data.images.load(str(ROOT/'art/blender/monster-palette.png'));image.name='Wildfall Palette';image.pack()
    SPEC={'id':id,**SPECS[id]};m.export=capture;getattr(m,id)()
