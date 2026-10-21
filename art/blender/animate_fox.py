"""Dedicated Forest Fox study. Blender 4.3+, no changes to the base roster."""
import bpy, math, json, importlib.util
from pathlib import Path
from mathutils import Vector, Quaternion, Euler, Matrix
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('roster',ROOT/'art/blender/build_roster.py')
b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
OUT=ROOT/'godot-animation/assets'
rig=None

def smooth(t):
    t=max(0,min(1,t));return t*t*(3-2*t)

def world_bone(name,head,rotation):
    p=rig.pose.bones[name];p.matrix=Matrix.Translation(Vector(head)) @ (rotation @ p.bone.matrix_local.to_quaternion()).to_matrix().to_4x4();bpy.context.view_layer.update()

def limb(prefix,side,end):
    p=rig.pose.bones[prefix+'_upper.'+side];q=rig.pose.bones[prefix+'_lower.'+side]
    start=p.parent.matrix @ p.parent.bone.matrix_local.inverted() @ p.bone.head_local
    delta=Vector(end)-start;dist=max(.01,min(delta.length,p.bone.length+q.bone.length-.001));axis=delta.normalized()
    pole=Vector((0,1 if prefix=='back' else -1,0));perp=(pole-axis*pole.dot(axis)).normalized()
    a=(p.bone.length**2+dist**2-q.bone.length**2)/(2*dist);joint=start+axis*a+perp*math.sqrt(max(0,p.bone.length**2-a*a));end=start+axis*dist
    for bone,head,tail in [(p,start,joint),(q,joint,end)]:
        world_bone(bone.name,head,(bone.bone.tail_local-bone.bone.head_local).rotation_difference((tail-head).normalized()))
    world_bone(prefix+'_paw.'+side,end,Quaternion())

def pose(t,clip):
    for p in rig.pose.bones:
        p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0)
    phase=t/(.64 if clip=='Trot' else 3.2)*math.tau
    attack=clip=='Attack';trot=clip=='Trot'
    brace=smooth(t/.16)*(1-smooth((t-.34)/.40)) if attack else 0
    recoil=math.sin(max(0,min(1,(t-.32)/.25))*math.pi)*.14 if attack else 0
    rig.pose.bones['body'].location.y=abs(math.sin(phase))*.025 if trot else math.sin(phase)*.005
    rig.pose.bones['body'].location.z=-.025*brace
    rig.pose.bones['chest'].rotation_quaternion=Euler((-.10*brace+recoil,0,0)).to_quaternion()
    rig.pose.bones['neck'].rotation_quaternion=Euler((.10*brace-recoil*.5,0,0)).to_quaternion()
    rig.pose.bones['head'].rotation_quaternion=Euler((.025*math.sin(phase) if trot else -.06*brace,0,.06*math.sin(phase)*(1-brace))).to_quaternion()
    for side,s in [('L',1),('R',-1)]:
        rig.pose.bones['ear.'+side].rotation_quaternion=Euler((-.24*brace+.07*math.sin(phase+s),0,s*.07*math.sin(phase))).to_quaternion()
    for i in range(3):rig.pose.bones['tail0'+str(i+1)].rotation_quaternion=Euler((.06*math.sin(phase-i*.6),.22*math.sin(phase-i*.6)*(1-brace),0)).to_quaternion()
    bpy.context.view_layer.update()
    for side,s in [('L',1),('R',-1)]:
        for prefix,y in [('front',-.18),('back',.22)]:
            z=.06;shift=0
            if trot:
                u=(t/.64+(0 if (s==1)==(prefix=='front') else .5))%1
                if u<.55:shift=-.115+.23*u/.55
                else:
                    v=(u-.55)/.45;shift=.115-.23*smooth(v);z+=math.sin(v*math.pi)*.09
            limb(prefix,side,(s*.14,y-.04+shift,.06 if not trot else z))

def prepare(d,kind):
    global rig
    rig=b.RIG;bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for side,s in [('L',1),('R',-1)]:
        for prefix,y in [('front',-.28 if d['id']=='wolf' else -.18),('back',.30 if d['id']=='wolf' else .22)]:b.bone(prefix+'_paw.'+side,(s*.14,y-.04,.06),(s*.14,y-.17,.06),prefix+'_lower.'+side)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    for part in b.PARTS:
        if part.name.startswith(('Rounded paw','Ivory claw')):
            old=part.vertex_groups[0].name;part.vertex_groups.clear();vg=part.vertex_groups.new(name=old.replace('_lower','_paw'));vg.add(list(range(len(part.data.vertices))),1,'REPLACE')
    bpy.ops.object.select_all(action='DESELECT')
    for part in b.PARTS:part.select_set(True)
    bpy.context.view_layer.objects.active=b.PARTS[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name='Forest Fox / motion study';mesh.parent=rig
    mod=mesh.modifiers.new('Fox skin','ARMATURE');mod.object=rig
    unique=[];mapping={}
    for i,m in enumerate(mesh.data.materials):
        if m not in unique:unique.append(m)
        mapping[i]=unique.index(m)
    indices=[mapping[p.material_index] for p in mesh.data.polygons];mesh.data.materials.clear()
    for m in unique:mesh.data.materials.append(m)
    for p,i in zip(mesh.data.polygons,indices):p.material_index=i
    return mesh

def capture(d,kind):
    global rig
    mesh=prepare(d,kind)
    actions={};clips={'Idle':3.2,'Trot':.64,'Attack':.85};rig.animation_data_create()
    for clip,length in clips.items():
        action=bpy.data.actions.new('Forest Fox / '+clip);rig.animation_data.action=action
        for t in sorted(set([frame/30 for frame in range(int(length*30)+1)]+[length])):
            bpy.context.scene.frame_set(1+int(t*30));pose(t,clip)
            for p in rig.pose.bones:
                p.keyframe_insert('rotation_quaternion',frame=1+t*30,group=p.name);p.keyframe_insert('location',frame=1+t*30,group=p.name)
        actions[clip]=action;track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);track.mute=True;rig.animation_data.action=None
    for tr in rig.animation_data.nla_tracks:tr.mute=False
    bpy.context.scene.render.fps=30;bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/'fox-motion.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
    for tr in rig.animation_data.nla_tracks:tr.mute=True
    rig.animation_data.action=actions['Attack'];bpy.context.scene.frame_set(9);bpy.context.scene.frame_end=27
    muzzle=rig.data.bones['head'].matrix_local.inverted() @ Vector((0,-.68,.55))
    mesh.data.calc_loop_triangles()
    metadata={'name':'Forest Fox','file':'fox-motion.glb','bones':21,'triangles':len(mesh.data.loop_triangles),'clips':clips,'releaseTime':.32,'attackInterval':1.1,'darts':3,'spread':[-.12,0,.12],'damageMultiplier':.45,'element':'physical','muzzleBone':'head','muzzleLocal':list(muzzle),'trotStrideSpeed':.23/(.64*.55)}
    (OUT/'fox-motion.json').write_text(json.dumps(metadata,indent=2)+'\n')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/fox-motion.blend'),compress=True)
    print('FOX_MOTION_EXPORTED',json.dumps(metadata),flush=True)

if __name__ == '__main__':
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    image=bpy.data.images.load(str(ROOT/'art/blender/wildfall-palette.png'));image.name='Wildfall Palette';image.pack();b.finalize=capture;b.make_animal(False)
