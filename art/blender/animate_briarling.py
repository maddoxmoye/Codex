"""Blender-authored first enemy motion study; original static models stay intact.
blender -b --factory-startup --python art/blender/animate_briarling.py
"""
import bpy, math, json, importlib.util
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion, Euler
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('monsters',ROOT/'art/blender/build_monsters.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);b=m.b
OUT=ROOT/'godot-monsters/assets';FPS=30;rig=None
CLIPS={'Idle':2.4,'Run':.72,'Attack':1.2,'Hit':.55,'Death':1.4}

def smooth(x):
    x=max(0,min(1,x));return x*x*(3-2*x)
def ease(t,a,z):return smooth((t-a)/(z-a))
def world_bone(name,head,delta):
    p=rig.pose.bones[name];p.matrix=Matrix.Translation(Vector(head)) @ (delta @ p.bone.matrix_local.to_quaternion()).to_matrix().to_4x4();bpy.context.view_layer.update()
def anchor(name):
    p=rig.pose.bones[name];return p.parent.matrix @ p.parent.bone.matrix_local.inverted() @ p.bone.head_local

def leg(side,end):
    p=rig.pose.bones['leg'+side];q=rig.pose.bones['shin'+side];start=anchor(p.name);end=Vector(end);delta=end-start
    length=max(.005,min(delta.length,p.bone.length+q.bone.length-.001));axis=delta.normalized();end=start+axis*length
    pole=Vector((0,-1,0));perp=(pole-axis*pole.dot(axis)).normalized();a=(p.bone.length**2+length**2-q.bone.length**2)/(2*length)
    knee=start+axis*a+perp*math.sqrt(max(0,p.bone.length**2-a*a))
    for joint,head,tail in [(p,start,knee),(q,knee,end)]:world_bone(joint.name,head,(joint.bone.tail_local-joint.bone.head_local).rotation_difference((tail-head).normalized()))
    world_bone('foot'+side,end,Quaternion())

def pose(t,clip):
    for p in rig.pose.bones:
        p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0);p.scale=(1,1,1)
    phase=t/(.72 if clip=='Run' else 2.4)*math.tau
    breath=math.sin(phase)
    attack=clip=='Attack';hit=clip=='Hit';dead=clip=='Death';run=clip=='Run'
    charge=ease(t,.06,.36)*(1-ease(t,.43,.62)) if attack else 0
    slash=ease(t,.40,.58)*(1-ease(t,.73,1.14)) if attack else 0
    recoil=math.sin(min(1,t/.55)*math.pi)*(1-ease(t,.35,.55)) if hit else 0
    fall=ease(t,.10,1.0) if dead else 0
    body=rig.pose.bones['body'];body.location.y=(-.035+abs(math.sin(phase))*.025) if run else .006*breath
    body.location.y-=charge*.065+fall*.20
    body.rotation_quaternion=Euler((.12 if run else .02*breath-.90*fall, .14*math.sin(phase) if run else 0,0)).to_quaternion()
    rig.pose.bones['chest'].rotation_quaternion=Euler((-.20*charge+.40*slash-.30*recoil-.25*fall,.12*charge-.20*slash,0),'XYZ').to_quaternion()
    rig.pose.bones['head'].rotation_quaternion=Euler((.08*charge-.10*slash+.18*recoil+.35*fall,.04*math.sin(phase-.4),0),'XYZ').to_quaternion()
    bpy.context.view_layer.update()
    for side,s in [('.L',1),('.R',-1)]:
        x=s*.20;y=-.04;z=.08
        if run:
            u=(t/.72+(0 if s==1 else .5))%1
            if u<.56:y=-.17+.26*u/.56
            else:
                v=(u-.56)/.44;y=.09-.26*smooth(v);z+=math.sin(v*math.pi)*.10
        if attack:y+=s*.04*charge-.035*slash
        if hit:y+=s*.025*recoil
        if dead:y-=.11*fall;x+=s*.04*fall
        leg(side,(x,y,z))
        arm=rig.pose.bones['arm'+side]
        arm.rotation_quaternion=Euler((s*.40*math.sin(phase) if run else .025*breath,0,s*.04),'XYZ').to_quaternion()
        if attack:arm.rotation_quaternion=Euler((-.9*charge+.95*slash,s*.15*charge,-s*.60*charge+s*.23*slash),'XYZ').to_quaternion()
        if hit:arm.rotation_quaternion=Euler((-.48*recoil,0,-s*.25*recoil),'XYZ').to_quaternion()
        if dead:arm.rotation_quaternion=Euler((.45*fall,0,-s*.50*fall),'XYZ').to_quaternion()
        rig.pose.bones['claw'+side].rotation_quaternion=Euler((-.20*charge+.30*slash,.10*s*slash,0),'XYZ').to_quaternion()
        if attack:
            name='arm'+side;bone=rig.data.bones[name];start=anchor(name)
            parent=rig.pose.bones[name].parent
            neutral=(parent.matrix @ parent.bone.matrix_local.inverted() @ bone.tail_local)-start
            direction=neutral.normalized().lerp(Vector((s*.65,.30,.65)).normalized(),charge)
            direction=direction.lerp(Vector((s*.18,-.94,-.12)).normalized(),slash).normalized()
            world_bone(name,start,(bone.tail_local-bone.head_local).normalized().rotation_difference(direction))
    bpy.context.view_layer.update()

def capture(d):
    global rig
    rig=b.RIG;bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for side,s in [('.L',1),('.R',-1)]:
        rig.data.edit_bones['leg'+side].tail=(s*.21,.03,.24)
        b.bone('shin'+side,(s*.21,.03,.24),(s*.20,-.04,.08),'leg'+side)
        b.bone('foot'+side,(s*.20,-.04,.08),(s*.20,-.20,.045),'shin'+side)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    for ob in b.PARTS:
        if ob.name.startswith('Splayed root toe'):
            side=ob.vertex_groups[0].name[-2:];ob.vertex_groups.clear();g=ob.vertex_groups.new(name='foot'+side);g.add(list(range(len(ob.data.vertices))),1,'REPLACE')
        elif ob.name.startswith('Bowleg root'):
            side=ob.vertex_groups[0].name[-2:];ob.vertex_groups.clear()
            upper=ob.vertex_groups.new(name='leg'+side);lower=ob.vertex_groups.new(name='shin'+side)
            for v in ob.data.vertices:
                weight=smooth((v.co.z-.18)/.12)
                if weight>0:upper.add([v.index],weight,'REPLACE')
                if weight<1:lower.add([v.index],1-weight,'REPLACE')
    mesh=m.join_parts('Briarling / motion study skin',rig);actions={};rig.animation_data_create()
    for clip,length in CLIPS.items():
        action=bpy.data.actions.new('Briarling / '+clip);rig.animation_data.action=action
        for t in sorted(set([i/FPS for i in range(int(length*FPS)+1)]+[length])):
            bpy.context.scene.frame_set(1+int(t*FPS));pose(t,clip)
            for p in rig.pose.bones:
                p.keyframe_insert('location',frame=1+t*FPS,group=p.name);p.keyframe_insert('rotation_quaternion',frame=1+t*FPS,group=p.name)
        actions[clip]=action;track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);track.mute=True;rig.animation_data.action=None
    for track in rig.animation_data.nla_tracks:track.mute=False
    bpy.context.scene.render.fps=FPS;bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/'briarling-motion.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
    for track in rig.animation_data.nla_tracks:track.mute=True
    rig.animation_data.action=actions['Attack'];bpy.context.scene.frame_set(12);bpy.context.scene.frame_end=37
    metadata={'name':'Briarling / enemy motion study 01','file':'assets/briarling-motion.glb','bones':13,'triangles':len(mesh.data.loop_triangles),'clips':CLIPS,'attackContact':.56,'attackRecovery':.73,'runStrideSpeed':.26/(.72*.56),'health':60,'arrowDamage':20,'dummyDamage':12,'notes':'First enemy motion prototype. Three other designs remain static. No full-game AI or gameplay integration.'}
    metadata['clawSocket']={side:list(rig.data.bones['claw.'+side].matrix_local.inverted() @ Vector((s*.37,-.23,.43))) for side,s in [('L',1),('R',-1)]}
    (OUT/'briarling-motion.json').write_text(json.dumps(metadata,indent=2)+'\n')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/briarling-motion.blend'),compress=True)
    print('BRIARLING_MOTION_EXPORTED',json.dumps(metadata),flush=True)

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
image=bpy.data.images.load(str(ROOT/'art/blender/monster-palette.png'));image.name='Wildfall Palette';image.pack()
m.export=capture;m.briarling()
