"""Blender 4.3+ / focused Rowan motion study, separate from the approved base roster.
blender -b --factory-startup --python art/blender/animate_rowan.py
"""
import bpy, math, json, importlib.util, sys
from pathlib import Path
from mathutils import Vector, Quaternion, Euler, Matrix
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('roster_builder',ROOT/'art/blender/build_roster.py')
b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
OUT=ROOT/'godot-animation/assets';OUT.mkdir(parents=True,exist_ok=True)
FPS=30
RELEASE=1.82
GRIP=Vector((.58,-.115,.91));STRING=Vector((.58,.095,.91))
rig=None
mesh=None

def smooth(t):
    t=max(0,min(1,t));return t*t*(3-2*t)

def ease(t,a,z):return smooth((t-a)/(z-a))

def world_bone(name,head,rotation):
    p=rig.pose.bones[name]
    p.matrix=Matrix.Translation(Vector(head)) @ (rotation @ p.bone.matrix_local.to_quaternion()).to_matrix().to_4x4()
    bpy.context.view_layer.update()

def anchor(name):
    p=rig.pose.bones[name]
    return p.parent.matrix @ p.parent.bone.matrix_local.inverted() @ p.bone.head_local if p.parent else p.bone.head_local.copy()

def limb(upper,lower,end,pole):
    p=rig.pose.bones[upper];q=rig.pose.bones[lower];start=anchor(upper);end=Vector(end)
    delta=end-start;dist=delta.length;l1=p.bone.length;l2=q.bone.length
    dist=max(abs(l1-l2)+.001,min(dist,l1+l2-.001));axis=delta.normalized();end=start+axis*dist
    pole=Vector(pole)-start;perp=(pole-axis*pole.dot(axis)).normalized()
    along=(l1*l1+dist*dist-l2*l2)/(2*dist);height=math.sqrt(max(0,l1*l1-along*along));elbow=start+axis*along+perp*height
    for name,head,tail in [(upper,start,elbow),(lower,elbow,end)]:
        bone=rig.data.bones[name];rest=(bone.tail_local-bone.head_local).normalized()
        world_bone(name,head,rest.rotation_difference((tail-head).normalized()))
    return end

def pose(t,clip):
    run=clip in ['Run','RunShoot'];shoot=clip in ['Shoot','RunShoot'];dodge=clip=='Dodge'
    for p in rig.pose.bones:
        p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0);p.scale=(1,1,1)
    phase=t/.8*math.tau;breath=math.sin(t/3.2*math.tau)
    raised=(ease(t,0,.45)*(1-ease(t,2.2,3.05))) if shoot else 0
    draw=ease(t,.75,1.5) if shoot else 0
    if shoot and t>=RELEASE:draw=1-ease(t,RELEASE,RELEASE+.065)
    lean=.10 if run else .012*breath
    hips=rig.pose.bones['hips'];hips.location.y=(-.075+abs(math.sin(phase))*.025) if run else 0
    hips.location.x=math.sin(phase)*.018 if run else 0
    if dodge:
        duck=ease(t,0,.18)*(1-ease(t,.55,.9));hips.location.y=-.18*duck;hips.location.x=-.08*duck;lean=.18*duck
    hips.rotation_quaternion=Euler((lean,.025*math.sin(phase) if run else .10*raised,0),'XYZ').to_quaternion()
    rig.pose.bones['spine'].rotation_quaternion=Euler((.015*breath,.04*raised,0),'XYZ').to_quaternion()
    rig.pose.bones['chest'].rotation_quaternion=Euler((.015*breath,.10*raised+(.045*math.sin(phase) if run else 0),0),'XYZ').to_quaternion()
    rig.pose.bones['head'].rotation_quaternion=Euler((-.04*raised,.42*raised,.015*breath),'XYZ').to_quaternion()
    rig.pose.bones['cape'].rotation_quaternion=Euler((-.08+math.sin(phase-.6)*.065 if run else math.sin(t*3)*.025,.035*math.sin(phase) if run else 0,0),'XYZ').to_quaternion()
    bpy.context.view_layer.update()
    # Analytic leg IK keeps boots flat during the stance and gives the swing foot clearance.
    for side,s in [('L',1),('R',-1)]:
        y=0;z=.17;x=s*.155
        if run:
            u=(t/.8+(0 if s==1 else .5))%1
            if u<.55:y=-.28+.56*u/.55
            else:
                swing=(u-.55)/.45;y=.28-.56*smooth(swing);z+=math.sin(swing*math.pi)*.18
        elif shoot:
            x+=s*.035*raised;y=(-.08 if s==1 else .08)*raised
        elif dodge:
            x+=(-.14 if s==1 else .06)*ease(t,.05,.3);y=(.12 if s==1 else -.10)*math.sin(t/.9*math.pi)
        foot=limb('thigh.'+side,'shin.'+side,(x,y,z),(x,-1,.50))
        world_bone('foot.'+side,foot,Quaternion())
    # Raise the left wrist into an extended bow hold. The right hand nocks, draws and follows through.
    baseL=Vector((.57,-.05,.96));baseR=Vector((-.57,-.05,.96))
    if run:
        baseL+=Vector((0,-math.sin(phase)*.16,.035));baseR+=Vector((0,math.sin(phase)*.22,.035))
    if dodge:
        duck=ease(t,0,.18)*(1-ease(t,.55,.9));baseL+=Vector((-.05,0,-.12))*duck;baseR+=Vector((.10,-.12,.05))*duck
    left=baseL.lerp(Vector((.19,-.51,1.48)),raised)
    hand_delta=Quaternion(Vector((1,0,0)),-math.pi/2*raised)
    left=limb('upper_arm.L','forearm.L',left,(.85,-.08,1.24))
    world_bone('hand.L',left,hand_delta)
    hand=rig.pose.bones['hand.L'];grip=hand.matrix @ hand.bone.matrix_local.inverted() @ GRIP
    world_bone('bow',grip,Quaternion())
    # The slight limb bend and string overshoot are baked into the GLB, not faked in the viewer.
    bend=draw*.085
    if shoot and RELEASE<t<RELEASE+.22:bend+=math.sin((t-RELEASE)*85)*.018*math.exp(-(t-RELEASE)*15)
    world_bone('bow_upper',grip,Quaternion(Vector((1,0,0)),-bend))
    world_bone('bow_lower',grip,Quaternion(Vector((1,0,0)),bend))
    rest=grip+(STRING-GRIP)
    nock=rest+Vector((-.04,0,0))*raised
    full=grip+Vector((-.27,.31,.065))
    string=nock.lerp(full,draw)
    if shoot and t>RELEASE+.065:
        string=rest+Vector((0,math.sin((t-RELEASE)*85)*.018*math.exp(-(t-RELEASE)*15),0))
    world_bone('bowstring',string,Quaternion())
    offset=hand_delta @ Vector((-.01,-.015,-.05))
    right_target=string-offset
    if shoot and t>=RELEASE:
        follow=full+Vector((-.06,.09,.025))*ease(t,RELEASE,RELEASE+.16)
        right_target=follow-offset
    right=baseR.lerp(right_target,raised)
    right=limb('upper_arm.R','forearm.R',right,(-.85,.18,1.46))
    world_bone('hand.R',right,hand_delta)
    bpy.context.view_layer.update()


def capture(d,kind):
    global rig,mesh
    rig=b.RIG
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for name,head,tail,parent in [('bow',GRIP,GRIP+Vector((0,0,.55)),'root'),('bowstring',STRING,STRING+Vector((0,0,.15)),'bow'),('bow_upper',GRIP,GRIP+Vector((0,0,.55)),'bow'),('bow_lower',GRIP,GRIP-Vector((0,0,.55)),'bow')]:b.bone(name,head,tail,parent)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    for part in b.PARTS:
        if not part.vertex_groups.get('hand.L') or part.name.startswith(('Gloved hand','Thumb')):continue
        part.vertex_groups.clear()
        if part.name.startswith('Bowstring'):
            for v in part.data.vertices:
                group='bow_lower' if v.co.z<.7 else 'bow_upper' if v.co.z>1.2 else 'bowstring'
                vg=part.vertex_groups.get(group) or part.vertex_groups.new(name=group);vg.add([v.index],1,'REPLACE')
        else:
            for v in part.data.vertices:
                diff=v.co.z-GRIP.z;w=min(1,abs(diff)/.4)
                for name,weight in [('bow',1-w),('bow_upper' if diff>=0 else 'bow_lower',w)]:
                    vg=part.vertex_groups.get(name) or part.vertex_groups.new(name=name);vg.add([v.index],weight,'REPLACE')
    bpy.ops.object.select_all(action='DESELECT')
    for ob in b.PARTS:ob.select_set(True)
    bpy.context.view_layer.objects.active=b.PARTS[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name='Rowan motion study / skinned mesh';mesh.parent=rig
    mod=mesh.modifiers.new('Motion study skin','ARMATURE');mod.object=rig
    unique=[];mapping={}
    for i,m in enumerate(mesh.data.materials):
        if m not in unique:unique.append(m)
        mapping[i]=unique.index(m)
    indices=[mapping[p.material_index] for p in mesh.data.polygons];mesh.data.materials.clear()
    for m in unique:mesh.data.materials.append(m)
    for p,i in zip(mesh.data.polygons,indices):p.material_index=i
    actions={};clips={'Idle':3.2,'Run':.8,'Shoot':3.2,'RunShoot':3.2,'Dodge':.9};rig.animation_data_create()
    for clip,duration in clips.items():
        action=bpy.data.actions.new('Rowan / '+clip);rig.animation_data.action=action
        frames=round(duration*FPS)
        times=sorted(set([i/FPS for i in range(frames+1)]+([RELEASE-.005,RELEASE,RELEASE+.065] if clip in ['Shoot','RunShoot'] else [])))
        for t in times:
            bpy.context.scene.frame_set(1+int(t*FPS));pose(t,clip)
            for p in rig.pose.bones:
                p.keyframe_insert('rotation_quaternion',frame=1+t*FPS,group=p.name)
                p.keyframe_insert('location',frame=1+t*FPS,group=p.name)
        actions[clip]=action
        track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);strip.action_frame_start=1;strip.action_frame_end=1+frames;track.mute=True
        rig.animation_data.action=None
    for tr in rig.animation_data.nla_tracks:tr.mute=False
    bpy.context.scene.render.fps=FPS;bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=97
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/'rowan-motion.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_optimize_animation_size=True,export_rest_position_armature=True)
    for tr in rig.animation_data.nla_tracks:tr.mute=True
    rig.animation_data.action=actions['Shoot'];bpy.context.scene.frame_set(53)
    pose(52/FPS,'Shoot')
    mesh.data.calc_loop_triangles()
    metadata={'name':'Rowan / motion study 01','file':'rowan-motion.glb','bones':22,'triangles':len(mesh.data.loop_triangles),'clips':clips,'releaseTime':RELEASE,'anchorTime':1.75,'bowBone':'bow','stringBone':'bowstring','runStrideSpeed':.56/(.8*.55),'loopClips':['Idle','Run','RunShoot'],'notes':'Prototype IK-baked motion. Fixed mitten hands; no finger or facial rig. Dodge is a short sidestep, not a roll.'}
    (OUT/'motion.json').write_text(json.dumps(metadata,indent=2)+'\n')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/rowan-motion.blend'),compress=True)
    print('ROWAN_MOTION_EXPORTED',json.dumps(metadata),flush=True)
    # A single anchor pose render catches hand/string or skinning errors before Godot export.
    studio=bpy.data.collections.new('Motion study studio');bpy.context.scene.collection.children.link(studio)
    def area(name,pos,energy,color):
        data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.size=4;data.color=color;ob=bpy.data.objects.new(name,data);studio.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,1.4))-ob.location).to_track_quat('-Z','Y').to_euler()
    area('Key',(3,-4,5),550,(1,.86,.7));area('Fill',(-4,-2,3),450,(.65,.82,1));area('Rim',(0,3,4),700,(.7,1,.85))
    world=bpy.data.worlds.new('Motion studio world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.10,.14,.18,1);world.node_tree.nodes['Background'].inputs[1].default_value=.4;bpy.context.scene.world=world
    camera_data=bpy.data.cameras.new('Motion review camera');camera=bpy.data.objects.new('Motion review camera',camera_data);studio.objects.link(camera);camera.location=(-3.4,-4.0,2.7);camera.rotation_euler=(Vector((0,-.1,1.2))-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.type='ORTHO';camera_data.ortho_scale=2.65
    scene=bpy.context.scene;scene.camera=camera;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ROOT/'art/blender/renders/rowan-draw.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/rowan-motion.blend'),compress=True)
    if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
image=bpy.data.images.load(str(ROOT/'art/blender/wildfall-palette.png'));image.name='Wildfall Palette';image.pack()
b.finalize=capture
b.make_archer(b.ARCHERS[0])
