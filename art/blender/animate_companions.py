"""Wolf: planted trot, jaw-driven bite, raised-muzzle howl.
Beetle: six-leg crawl, opening carapace, wing flight, collection and delivery.
blender -b --factory-startup --python art/blender/animate_companions.py
"""
import bpy, math, json, importlib.util
from pathlib import Path
from mathutils import Vector, Euler, Quaternion
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('fox_motion',ROOT/'art/blender/animate_fox.py')
f=importlib.util.module_from_spec(spec);spec.loader.exec_module(f);b=f.b
OUT=ROOT/'godot-combat/assets';rig=None;KIND=''

def wolf_pose(t,clip):
    # Retain planted feet, independent ears and three tail segments; larger wolf proportions.
    for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0)
    phase=t/(.72 if clip=='Trot' else 3.2)*math.tau
    bite=clip=='Bite';howl=clip=='Howl';trot=clip=='Trot'
    brace=f.smooth(t/.18)*(1-f.smooth((t-.43)/.37)) if bite else 0
    lift=f.smooth(t/.45)*(1-f.smooth((t-1.2)/.5)) if howl else 0
    rig.pose.bones['body'].location.y=abs(math.sin(phase))*.025 if trot else math.sin(phase)*.006
    rig.pose.bones['chest'].rotation_quaternion=Euler((-.12*brace+.08*lift,0,0)).to_quaternion()
    rig.pose.bones['neck'].rotation_quaternion=Euler((-.12*brace-.40*lift,0,0)).to_quaternion()
    rig.pose.bones['head'].rotation_quaternion=Euler((.16*brace-.36*lift,0,.025*math.sin(phase)*(1-brace-lift))).to_quaternion()
    jaw=f.smooth(t/.18)*(1-f.smooth((t-.24)/.10))*.58 if bite else .26*lift
    rig.pose.bones['jaw'].rotation_quaternion=Euler((jaw,0,0)).to_quaternion()
    for side,s in [('L',1),('R',-1)]:rig.pose.bones['ear.'+side].rotation_quaternion=Euler((-.2*brace+.07*math.sin(phase+s),0,s*.08*lift)).to_quaternion()
    for i in range(3):rig.pose.bones['tail0'+str(i+1)].rotation_quaternion=Euler((-.12*lift,.14*math.sin(phase-i*.6)*(1-brace),0)).to_quaternion()
    bpy.context.view_layer.update()
    for side,s in [('L',1),('R',-1)]:
        for prefix,y in [('front',-.28),('back',.30)]:
            z=.06;shift=0
            if trot:
                u=(t/.72+(0 if (s==1)==(prefix=='front') else .5))%1
                if u<.55:shift=-.15+.30*u/.55
                else:
                    v=(u-.55)/.45;shift=.15-.30*f.smooth(v);z+=math.sin(v*math.pi)*.12
            f.limb(prefix,side,(s*.14,y-.04+shift,z))

def beetle_pose(t,clip):
    for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0)
    phase=t/(.8 if clip=='Crawl' else .4 if clip=='Fly' else 3.2)*math.tau
    if clip=='Fly':opening=1.
    elif clip=='Collect':opening=f.smooth(t/.18)*(1-f.smooth((t-.55)/.45))
    elif clip=='Deliver':opening=1-f.smooth(t/.65)
    else:opening=0.
    rig.pose.bones['body'].location.y=.018*math.sin(phase) if clip=='Fly' else .004*math.sin(phase)
    rig.pose.bones['head'].rotation_quaternion=Euler((.18*math.sin(min(1,t/.9)*math.pi) if clip=='Collect' else .03*math.sin(phase),0,0)).to_quaternion()
    for side,s in [('L',1),('R',-1)]:
        # Hinges align along the shell's longitudinal axis; wings spread and beat below.
        rig.pose.bones['shell.'+side].rotation_quaternion=Euler((s*.9*opening,0,0)).to_quaternion()
        rig.pose.bones['wing.'+side].rotation_quaternion=Euler((s*(.15+.65*math.sin(t*math.tau*10))*opening,0,0)).to_quaternion()
        rig.pose.bones['antenna.'+side].rotation_quaternion=Euler((.10*math.sin(phase+s),.08*math.cos(phase+s),0)).to_quaternion()
        for i in range(3):
            u=phase+(i%2)*math.pi+(0 if s==1 else math.pi)
            rig.pose.bones['leg%d.%s'%(i,side)].rotation_quaternion=Euler((.18*math.sin(u) if clip=='Crawl' else -.2*opening,0,.25*math.cos(u) if clip=='Crawl' else s*.10*opening)).to_quaternion()

def capture(d,kind):
    global rig
    rig=b.RIG;f.rig=rig
    if KIND=='wolf':
        bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT');b.bone('jaw',(0,-.45,.64),(0,-.72,.61),'head');bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
        # A lower jaw and incisors remain visible in side-on contact views.
        b.ball('Articulated lower jaw',(0,-.58,.596),(.09,.15,.035),'wolf_light','jaw',segments=12,rings=6)
        for x in [-.068,.068]:b.loft('Canine tooth',[((x,-.65,.61),.014,.014),((x,-.65,.66),.001,.001)],'linen','jaw',sides=6)
        mesh=f.prepare(d,kind)
    else:
        bpy.ops.object.select_all(action='DESELECT')
        for part in b.PARTS:part.select_set(True)
        bpy.context.view_layer.objects.active=b.PARTS[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.parent=rig;mesh.modifiers.new('Beetle skin','ARMATURE').object=rig
        # Deduplicate shared palette materials after joining.
        materials=list(mesh.data.materials);unique=list(dict.fromkeys(materials));indices=[unique.index(materials[p.material_index]) for p in mesh.data.polygons];mesh.data.materials.clear()
        for m in unique:mesh.data.materials.append(m)
        for p,i in zip(mesh.data.polygons,indices):p.material_index=i
    mesh.name=d['name']+' / companion motion'
    clips={'Idle':3.2,'Trot':.72,'Bite':.8,'Howl':1.7} if KIND=='wolf' else {'Idle':3.2,'Crawl':.8,'Fly':.4,'Collect':1.,'Deliver':1.}
    actions={};rig.animation_data_create()
    for clip,length in clips.items():
        action=bpy.data.actions.new(d['name']+' / '+clip);rig.animation_data.action=action
        for t in sorted({i/30 for i in range(int(length*30)+1)}|{length}):
            bpy.context.scene.frame_set(1+int(t*30));(wolf_pose if KIND=='wolf' else beetle_pose)(t,clip)
            for p in rig.pose.bones:p.keyframe_insert('rotation_quaternion',frame=1+t*30,group=p.name);p.keyframe_insert('location',frame=1+t*30,group=p.name)
        actions[clip]=action;tr=rig.animation_data.nla_tracks.new();tr.name=clip;tr.strips.new(clip,1,action);tr.mute=True;rig.animation_data.action=None
    for tr in rig.animation_data.nla_tracks:tr.mute=False
    bpy.context.scene.render.fps=30;bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/(KIND+'-motion.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
    for tr in rig.animation_data.nla_tracks:tr.mute=True
    rig.animation_data.action=actions['Howl' if KIND=='wolf' else 'Collect'];bpy.context.scene.frame_set(18);bpy.context.scene.frame_end=52
    mesh.data.calc_loop_triangles();metadata={'id':KIND,'name':d['name'],'file':KIND+'-motion.glb','clips':clips,'bones':len(rig.data.bones)-1,'triangles':len(mesh.data.loop_triangles),'biteContact':.29,'biteCooldown':.8,'howlCooldown':6.,'slowDuration':2.,'damageMultiplier':1.3,'notes':'Companion animation study; independent of player element.'} if KIND=='wolf' else {'id':KIND,'name':d['name'],'file':KIND+'-motion.glb','clips':clips,'bones':len(rig.data.bones)-1,'triangles':len(mesh.data.loop_triangles),'collectTime':.48,'notes':'Non-combat collector. Visual flight, pickup and delivery; does not create or award saved currency.'}
    (OUT/(KIND+'.json')).write_text(json.dumps(metadata,indent=2)+'\n');bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender'/(KIND+'-combat.blend')),compress=True);print('COMPANION_EXPORTED',KIND,json.dumps(metadata),flush=True)

for id in ['wolf','beetle']:
    KIND=id;bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);b.MATS.clear()
    for image in list(bpy.data.images):bpy.data.images.remove(image)
    image=bpy.data.images.load(str(ROOT/'art/blender/wildfall-palette.png'));image.name='Wildfall Palette';image.pack();b.finalize=capture
    if id=='wolf':b.make_animal(True)
    else:b.make_beetle()
