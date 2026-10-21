"""Original Wildfall monster designs / Blender 4.3+. Static, skinned review models.
blender -b --factory-startup --python art/blender/build_monsters.py
No attacks, hit reactions, AI or changes to the approved roster in this pass.
"""
import bpy, math, json, sys, random, importlib.util
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('roster_helpers',ROOT/'art/blender/build_roster.py')
b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
OUT=ROOT/'godot-monsters/assets';OUT.mkdir(parents=True,exist_ok=True)
ART=ROOT/'art/blender';ASSETS=[];ENVS=[];rng=random.Random(46)
EXTRA={'bark':'534438','bark_light':'8b7150','root':'a78a61','leaf_dark':'284c42','leaf_bright':'8d9d57','spore_cap':'986d91','spore_rim':'dfb6bd','spore_dark':'57475d','stone':'697e80','stone_light':'a5b3a3','soil':'35483b','grass':'526d48','path':'9b9477','core':'b9e0bc','fungus':'d1ae7b','deep':'172e30'}
b.COLORS.update(EXTRA);b.INDEX={name:i for i,name in enumerate(b.COLORS)}
assert len(b.COLORS)<=64


def rig_begin(d,bones):
    b.new_asset(d['id'],d['name'])
    for name,head,tail,parent in bones:b.bone(name,head,tail,parent)
    bpy.ops.object.mode_set(mode='OBJECT');b.RIG.select_set(False)


def eye(name,pos,size,color='amber',bone='head'):
    b.ball(name+' socket',pos,(size*1.40,size*.45,size*1.15),'deep',bone,segments=12,rings=8)
    b.ball(name+' luminous iris',(pos[0],pos[1]-.018,pos[2]),(size*.80,size*.38,size*.78),color,bone,kind='Luminous inlay',segments=12,rings=8)
    b.ball(name+' pupil',(pos[0],pos[1]-.035,pos[2]),(size*.19,size*.12,size*.58),'ink',bone,segments=8,rings=6)


def join_parts(name,rig=None):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in b.PARTS:ob.select_set(True)
    bpy.context.view_layer.objects.active=b.PARTS[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name=name
    unique=[];mapping={}
    for i,m in enumerate(mesh.data.materials):
        if m not in unique:unique.append(m)
        mapping[i]=unique.index(m)
    indices=[mapping[p.material_index] for p in mesh.data.polygons];mesh.data.materials.clear()
    for m in unique:mesh.data.materials.append(m)
    for p,i in zip(mesh.data.polygons,indices):p.material_index=i
    if rig:
        mesh.parent=rig;mod=mesh.modifiers.new('Wildfall monster skin','ARMATURE');mod.object=rig
        for v in mesh.data.vertices:
            assert abs(sum(g.weight for g in v.groups)-1)<1e-4
            assert len([g for g in v.groups if g.weight>0])<=4
    else:mesh.vertex_groups.clear()
    mesh.data.calc_loop_triangles()
    return mesh


def export(d):
    rig=b.RIG;mesh=join_parts(d['name']+' / palette skin',rig)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
    path=OUT/(d['id']+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
    points=[Vector(v) for v in mesh.bound_box];height=max(v.z for v in points)-min(v.z for v in points)
    radius=max(math.hypot(v.x,v.y) for v in points)
    entry={**d,'file':'assets/'+path.name,'triangles':len(mesh.data.loop_triangles),'bones':sum(x.use_deform for x in rig.data.bones),'materials':len(mesh.data.materials),'heightMeters':round(height,3),'radius':round(radius,3),'clips':[],'bytes':path.stat().st_size}
    ASSETS.append((entry,rig,mesh));print('MONSTER_EXPORTED',json.dumps(entry),flush=True)


def briarling():
    d=dict(id='briarling',name='Briarling',role='Swarm / close-range',description='A crooked little root creature with a carved seed mask, thorn fingers and a fern collar.',damagePlan='Next pass: a quick chest recoil, leaf shake and small bark chips. Its amber eyes remain visible during hit flashes.',attackPlan='Next pass: a low two-claw swipe, with a clear crouch before the lunge.',slot=-4.5)
    rig_begin(d,[('body',(0,0,.34),(0,0,.66),'root'),('chest',(0,0,.66),(0,0,.88),'body'),('head',(0,-.025,.88),(0,-.025,1.18),'chest')]+[(name+side,a,z,parent+side if parent=='arm' else parent) for side,s in [('.L',1),('.R',-1)] for name,a,z,parent in [('arm',(s*.20,0,.78),(s*.36,-.08,.52),'chest'),('claw',(s*.36,-.08,.52),(s*.39,-.15,.37),'arm'),('leg',(s*.13,0,.38),(s*.20,-.04,.10),'body')]])
    b.loft('Tapered twisted trunk',[((0,0,.28),.14,.12),((0,0,.48),.22,.16),((0,0,.70),.19,.13),((0,0,.84),.13,.12)],'bark','body',sides=10,smooth=False)
    for s in [-1,1]:
        side='.L' if s==1 else '.R'
        b.tube('Knotted root arm',[(s*.17,0,.78),(s*.29,.015,.70),(s*.36,-.08,.52)],.075,'bark_light','arm'+side,sides=8,radii=[.09,.075,.045])
        b.ball('Root knuckle',(s*.36,-.08,.50),(.08,.07,.09),'bark','claw'+side)
        for i in range(3):b.tube('Hooked thorn finger',[(s*(.32+i*.038),-.10,.49),(s*(.32+i*.04),-.17,.39),(s*(.33+i*.045),-.23,.43)],.02,'root','claw'+side,sides=5,radii=[.026,.017,.003])
        b.tube('Bowleg root',[(s*.13,0,.40),(s*.21,.03,.24),(s*.20,-.04,.08)],.07,'bark','leg'+side,sides=8,radii=[.085,.065,.075])
        for k in [-1,0,1]:b.tube('Splayed root toe',[(s*.20,-.02,.08),(s*.20+k*.06,-.18,.045)],.025,'bark_light','leg'+side,sides=5,radii=[.04,.008])
        b.leaf('Long pointed leaf ear',(s*.13,0,1.06),(s*.44,.01,1.32),.10,'moss','head')
        for i in range(4):b.leaf('Fern shoulder mantle',(s*.04,0,.87),(s*(.19+i*.055),-.05+i*.065,.66-i*.015),.065,'leaf_bright' if i%2 else 'forest','chest')
    b.ball('Seed mask skull',(0,-.03,1.01),(.235,.155,.245),'root','head',segments=16,rings=10)
    b.loft('Central bark face ridge',[((0,-.155,.84),.055,.025),((0,-.18,1.03),.08,.025),((0,-.13,1.23),.025,.02)],'bark_light','head',sides=6,smooth=False)
    for s in [-1,1]:
        eye('Seed eye',(s*.105,-.16,1.04),.052)
        b.tube('Angled carved brow',[(s*.04,-.177,1.12),(s*.15,-.157,1.15)],.022,'bark','head',sides=5)
    b.tube('Carved jagged mouth',[(-.09,-.17,.94),(-.04,-.19,.915),(0,-.19,.93),(.04,-.19,.91),(.10,-.17,.94)],.012,'deep','head',sides=4)
    for x in [-.06,.04]:b.leaf('Crown sprout',(x,0,1.20),(x+.04,0,1.39),.052,'sage','head')
    export(d)


def sporecaller():
    d=dict(id='sporecaller',name='Sporecaller',role='Ranged / area denial',description='A squat forest fungus with a broad plum cap, luminous gills, dangling spore pods and soft, ringed feet.',damagePlan='Next pass: the cap compresses and rebounds, the body squashes, and a few harmless spores scatter.',attackPlan='Next pass: the gills brighten before a lobbed spore attack and a visible landing circle.',slot=-1.65)
    rig_begin(d,[('body',(0,0,.20),(0,0,.65),'root'),('head',(0,0,.65),(0,0,1.02),'body'),('cap',(0,0,1.02),(0,0,1.43),'head'),('arm.L',(.26,0,.73),(.49,-.08,.43),'body'),('arm.R',(-.26,0,.73),(-.49,-.08,.43),'body'),('foot.L',(.20,0,.23),(.20,-.16,.08),'body'),('foot.R',(-.20,0,.23),(-.20,-.16,.08),'body'),('pod.L',(.56,0,1.03),(.56,0,.73),'cap'),('pod.R',(-.56,.03,1.03),(-.56,.03,.73),'cap')])
    b.loft('Pale fluted stem',[((0,0,.14),.25,.20),((0,0,.34),.34,.26),((0,0,.70),.27,.23),((0,0,1.04),.22,.20)],'cream','body',sides=16)
    for s in [-1,1]:
        b.ball('Padded ringed foot',(s*.22,-.05,.11),(.21,.28,.11),'spore_dark','foot.L' if s==1 else 'foot.R')
        b.tube('Fungal arm',[(s*.27,0,.74),(s*.43,-.02,.57),(s*.48,-.12,.43)],.085,'spore_rim','arm.L' if s==1 else 'arm.R',sides=10,radii=[.09,.065,.08])
        b.ball('Spore palm',(s*.49,-.12,.43),(.105,.09,.12),'cream','arm.L' if s==1 else 'arm.R')
        eye('Sleepy fungal eye',(s*.105,-.235,.79),.053,'lilac')
    b.ball('Soft beak nose',(0,-.255,.69),(.065,.055,.045),'spore_cap','head')
    # A revolved mushroom silhouette, with a deep rim and radial underside gills.
    b.loft('Velvet domed mushroom cap',[((0,.015,1.00),.48,.42),((0,.015,1.07),.73,.62),((0,.015,1.18),.78,.66),((0,.015,1.34),.59,.51),((0,.015,1.52),.28,.25),((0,.015,1.57),.025,.025)],'spore_cap','cap',sides=24)
    b.loft('Rolled cream cap lip',[((0,.015,1.04),.71,.60),((0,.015,1.09),.77,.65),((0,.015,1.14),.76,.64)],'spore_rim','cap',sides=24)
    for i in range(18):
        a=i*math.tau/18;b.tube('Radial luminous gill',[(math.cos(a)*.27,math.sin(a)*.23,1.025),(math.cos(a)*.65,math.sin(a)*.55,1.055)],.012,'lilac','cap',kind='Luminous inlay',sides=4)
    for x,y,z,r in [(-.35,-.19,1.42,.12),(.30,-.24,1.43,.10),(0,-.40,1.33,.085),(.48,.04,1.36,.085),(-.20,.27,1.48,.09),(0,-.09,1.575,.07)]:b.ball('Cream cap freckle',(x,y,z),(r,r,.022),'cream','cap',segments=12,rings=6)
    for s in [-1,1]:
        bn='pod.L' if s==1 else 'pod.R';b.tube('Hanging spore thread',[(s*.57,0,1.07),(s*.57,0,.83)],.016,'spore_rim',bn,sides=5)
        b.ball('Pendant spore lantern',(s*.57,0,.78),(.10,.09,.135),'violet',bn,kind='Luminous inlay')
    for z in [.30,.42,.54]:b.tube('Stem fold',[(-.25,-.16,z),(0,-.27,z-.025),(.25,-.16,z)],.012,'fungus','body',sides=5)
    export(d)


def thornback():
    d=dict(id='thornback',name='Thornback',role='Heavy / charging',description='A low, broad woodland boar, with overlapping slate-bark armor, curling ivory tusks and thorn-covered shoulders.',damagePlan='Next pass: a heavy shoulder jolt and pale chips on armored hits. The exposed face and flank give clearer damage feedback.',attackPlan='Next pass: it digs in, lowers its tusks, then charges along a clearly marked lane.',slot=1.5)
    bones=[('body',(0,.35,.62),(0,-.25,.66),'root'),('chest',(0,-.25,.66),(0,-.58,.70),'body'),('head',(0,-.58,.70),(0,-1.05,.61),'chest'),('jaw',(0,-.76,.51),(0,-1.10,.46),'head'),('tail',(0,.63,.65),(0,.97,.90),'body')]
    for side,s in [('.L',1),('.R',-1)]:
        for prefix,y in [('front',-.35),('back',.45)]:bones.extend([(prefix+side,(s*.30,y,.56),(s*.32,y,.26),'chest' if prefix=='front' else 'body'),(prefix+'_hoof'+side,(s*.32,y,.26),(s*.32,y-.08,.09),prefix+side)])
    rig_begin(d,bones)
    b.ball('Broad powerful body',(0,.12,.65),(.49,.72,.47),'bark','body',segments=20,rings=12)
    b.ball('Hunched shoulder mass',(0,-.30,.77),(.48,.40,.44),'stone','chest',segments=16,rings=10)
    b.ball('Boar wedge head',(0,-.67,.62),(.35,.41,.30),'bark_light','head',segments=16,rings=10)
    b.ball('Broad armored snout',(0,-1.01,.53),(.26,.18,.18),'spore_dark','head',segments=14,rings=8)
    b.ball('Lower tusked jaw',(0,-.86,.39),(.24,.29,.11),'bark','jaw')
    for s in [-1,1]:
        side='.L' if s==1 else '.R';eye('Boar eye',(s*.23,-.86,.75),.048,'ember')
        b.ball('Snout nostril',(s*.105,-1.175,.55),(.05,.014,.04),'deep','head')
        b.leaf('Boar pointed ear',(s*.20,-.49,.85),(s*.45,-.38,1.12),.14,'bark','head')
        b.leaf('Boar ear lining',(s*.235,-.51,.88),(s*.40,-.42,1.06),.065,'russet','head')
        b.tube('Sweeping ivory tusk',[(s*.22,-.92,.40),(s*.36,-1.03,.42),(s*.43,-1.06,.59),(s*.39,-1.06,.76)],.06,'linen','jaw',sides=10,radii=[.075,.065,.04,.004])
        for prefix,y in [('front',-.35),('back',.45)]:
            b.tube('Stocky plated leg',[(s*.30,y,.65),(s*.35,y,.32),(s*.32,y-.03,.10)],.12,'bark_light',prefix+side,sides=10,radii=[.17,.13,.10])
            b.block('Cloven dark hoof',(s*.32,y-.07,.09),(.24,.29,.17),'deep',prefix+'_hoof'+side,bevel=.025)
            b.tube('Hoof split',[(s*.32,y-.218,.035),(s*.32,y-.218,.14)],.008,'root',prefix+'_hoof'+side,sides=4)
    for j,y in enumerate([-.35,-.05,.27,.55]):
        for s in [-1,1]:
            b.block('Overlapping slate bark plate',(s*.20,y,1.00-j*.018),(.37,.39,.18),'stone' if j%2 else 'stone_light','chest' if j==0 else 'body',bevel=.055,rotation=(0,s*.40,0))
            b.tube('Shoulder thorn',[(s*.29,y,1.04),(s*.40,y+.035,1.38-j*.04)],.065,'bark','chest' if j==0 else 'body',sides=6,radii=[.085,.003])
    b.tube('Curled root tail',[(0,.70,.69),(0,.93,.79),(.10,1.02,.93),(.19,.98,.93),(.17,.90,.88)],.04,'bark_light','tail',sides=7,radii=[.065,.045,.035,.025,.008])
    for s in [-1,1]:b.leaf('Moss flank tuft',(s*.39,.25,.88),(s*.56,.45,.73),.10,'moss','body')
    export(d)


def hollowhart():
    d=dict(id='hollowhart',name='Hollowhart',role='Guardian / boss concept',description='An ancient antlered tree guardian with split bark armor, a hanging root beard and a luminous seed-heart inside its hollow chest.',damagePlan='Next pass: armored limbs shed bark chips; a vulnerable seed-heart pulses and the torso recoils on a clean hit.',attackPlan='Next pass: a root hammer slam, with an overhead windup and a spreading ground warning.',slot=4.7)
    bones=[('body',(0,0,.85),(0,0,1.30),'root'),('chest',(0,0,1.30),(0,0,1.90),'body'),('core',(0,-.08,1.49),(0,-.08,1.75),'chest'),('head',(0,0,1.90),(0,0,2.32),'chest'),('antler.L',(.19,0,2.26),(.55,.02,2.82),'head'),('antler.R',(-.19,0,2.26),(-.55,.02,2.82),'head')]
    for side,s in [('.L',1),('.R',-1)]:bones.extend([('arm'+side,(s*.42,0,1.78),(s*.64,-.04,1.28),'chest'),('forearm'+side,(s*.64,-.04,1.28),(s*.74,-.12,.83),'arm'+side),('hand'+side,(s*.74,-.12,.83),(s*.76,-.14,.62),'forearm'+side),('leg'+side,(s*.21,0,.99),(s*.29,0,.48),'body'),('foot'+side,(s*.29,0,.48),(s*.32,-.13,.10),'leg'+side)])
    rig_begin(d,bones)
    b.loft('Tapered hollow torso',[((0,.04,.88),.23,.20),((0,.04,1.15),.34,.23),((0,.04,1.55),.40,.27),((0,.04,1.87),.26,.22)],'deep','body',sides=12,smooth=False)
    # The inset heart stays exposed between separate ribs; it has its own deform bone.
    b.ball('Luminous seed-heart',(0,-.235,1.56),(.135,.10,.21),'core','core',kind='Luminous inlay',segments=16,rings=10)
    for s in [-1,1]:
        side='.L' if s==1 else '.R'
        for j in range(3):b.tube('Open rib of weathered bark',[(s*.28,.04,1.27+j*.19),(s*.35,-.15,1.32+j*.19),(s*.20,-.28,1.37+j*.19)],.07,'bark_light','chest',sides=7,radii=[.10,.075,.025])
        b.tube('Long trunk thigh',[(s*.20,.03,1.03),(s*.28,.03,.68),(s*.29,0,.43)],.14,'bark','leg'+side,sides=9,radii=[.18,.15,.11])
        b.tube('Flared root shin',[(s*.29,0,.50),(s*.32,0,.20),(s*.32,-.04,.09)],.13,'bark_light','foot'+side,sides=8,radii=[.12,.15,.19])
        for k in [-1,0,1]:b.tube('Guardian root toes',[(s*.32,0,.13),(s*.32+k*.11,-.24,.065),(s*.32+k*.14,-.39,.035)],.045,'root','foot'+side,sides=5,radii=[.08,.055,.005])
        b.tube('Massive branch upper arm',[(s*.37,0,1.80),(s*.56,.01,1.60),(s*.64,-.04,1.28)],.15,'bark','arm'+side,sides=10,radii=[.23,.17,.13])
        b.loft('Faceted hammer forearm',[((s*.64,-.04,1.32),.15,.14),((s*.71,-.09,1.12),.23,.19),((s*.74,-.12,.85),.17,.14)],'bark_light','forearm'+side,sides=8,smooth=False)
        b.ball('Heavy root hand',(s*.76,-.14,.73),(.19,.15,.17),'bark','hand'+side)
        for i in range(3):b.tube('Guardian curled finger',[(s*(.64+i*.10),-.18,.73),(s*(.65+i*.10),-.25,.57),(s*(.66+i*.10),-.32,.62)],.035,'root','hand'+side,sides=6,radii=[.055,.035,.006])
        for i in range(3):b.leaf('Layered shoulder moss',(s*.34,0,1.93),(s*(.55+i*.12),.03,1.70-i*.045),.11,'moss' if i%2 else 'leaf_bright','arm'+side)
    b.loft('Long carved guardian mask',[((0,-.07,1.94),.09,.11),((0,-.08,2.11),.23,.14),((0,-.05,2.31),.27,.17),((0,-.01,2.40),.16,.13)],'root','head',sides=10,smooth=False)
    for s in [-1,1]:
        eye('Guardian eye',(s*.12,-.205,2.20),.052,'core')
        b.tube('Ancient mask brow',[(s*.035,-.22,2.26),(s*.20,-.18,2.29)],.027,'bark','head',sides=5)
        b.tube('Split antler trunk',[(s*.19,.015,2.31),(s*.36,.04,2.52),(s*.55,.03,2.77),(s*.64,.06,3.04)],.06,'bark_light','antler.L' if s==1 else 'antler.R',sides=7,radii=[.095,.07,.045,.005])
        for a,z in [(.35,2.52),(.52,2.74)]:
            bn='antler.L' if s==1 else 'antler.R';b.tube('Antler tine',[(s*a,.04,z),(s*(a+.24),-.01,z+.06),(s*(a+.36),-.02,z+.23)],.035,'root',bn,sides=6,radii=[.055,.03,.003])
        b.tube('Inner antler tine',[(s*.35,.04,2.52),(s*.27,-.01,2.79),(s*.29,0,2.91)],.03,'root','antler.L' if s==1 else 'antler.R',sides=6,radii=[.045,.025,.003])
        for j in range(2):b.leaf('Antler new growth',(s*.55,.03,2.77),(s*(.70+j*.10),-.02,2.87-j*.08),.07,'sage','antler.L' if s==1 else 'antler.R')
    for i in range(5):
        x=(i-2)*.043;b.tube('Hanging root beard',[(x,-.11,1.99),(x*1.3,-.13,1.81-abs(i-2)*.03),(x*1.15,-.15,1.72-abs(i-2)*.01)],.02,'bark','head',sides=5,radii=[.033,.02,.003])
    for s in [-1,1]:b.tube('Carved torso grain',[(s*.29,-.17,1.16),(s*.23,-.24,1.05),(s*.20,-.19,.94)],.012,'root','body',sides=4)
    export(d)


def environment():
    # Merged static backdrop: same palette, no transparent foliage or expensive shaders.
    b.PARTS=[];b.COLLECTION=bpy.data.collections.new('Woodland / environment study');bpy.context.scene.collection.children.link(b.COLLECTION)
    b.block('Woodland earth',(0,.8,-.18),(19,16,.30),'soil',bevel=.18)
    for i in range(18):
        x=-8+i*.95;y=-.8+.22*math.sin(i*.8)
        b.ball('Winding pale path',(x,y,-.025),(1.05,1.12,.045),'path',segments=12,rings=6)
    for i in range(26):
        x=rng.uniform(-8.7,8.7);y=rng.uniform(-4.5,7.0)
        if -6<x<6 and -2.5<y<2.2:continue
        b.ball('Ground moss bank',(x,y,.015),(rng.uniform(.35,.8),rng.uniform(.3,.65),.045),'grass',segments=10,rings=5)
    tree_points=[(-8,1),(-7.4,4.6),(-5.1,6),(-2.2,7),(1.6,7),(4.8,6.6),(7.6,4.6),(8.3,1.3),(-8,-3),(8,-2.5)]
    for i,(x,y) in enumerate(tree_points):
        h=rng.uniform(4.2,6.2);b.tube('Faceted forest trunk',[(x,y,0),(x+.1,y,h*.48),(x-.12,y+.06,h)],.24,'bark',sides=9,radii=[.40,.23,.12])
        for s in [-1,1]:
            b.tube('Root flare',[(x,y,.25),(x+s*.75,y-.2,.035)],.10,'bark_light',sides=6,radii=[.22,.015])
            b.tube('Canopy branch',[(x,y,h*.65),(x+s*.85,y+.15,h*.88)],.12,'bark_light',sides=7,radii=[.15,.03])
        for j in range(3):
            pos=(x+(j-1)*.75,y+.10*math.sin(j),h+.20-(j%2)*.35)
            b.ball('Solid clustered tree crown',pos,(1.25,1.10,1.0),'leaf_dark' if (i+j)%2 else 'forest',segments=10,rings=6)
    for i in range(28):
        x=rng.uniform(-8,8);y=rng.choice([rng.uniform(3.1,5.6),rng.uniform(-4.8,-3.2)])
        if y<0 and abs(x)<5.7:continue
        b.ball('Faceted perimeter rock',(x,y,.20),(rng.uniform(.25,.60),rng.uniform(.25,.55),rng.uniform(.22,.48)),'stone',segments=7,rings=4)
    # Broken sector stones suggest a future arena without filling the combat space.
    for x in [-6.8,6.8]:
        b.block('Ruined waystone',(x,2.4,.76),(.42,.44,1.50),'stone',bevel=.08,rotation=(0,.13 if x<0 else -.12,.10))
        b.block('Waystone pale carving',(x,2.16,.95),(.20,.015,.06),'sage',bevel=.005)
        b.block('Broken stone cap',(x,2.4,1.58),(.60,.60,.20),'stone_light',bevel=.045)
    b.tube('Fallen log',[(-6.5,3.2,.28),(-4.1,3.8,.28)],.28,'bark',sides=12)
    for x,y in [(-6.55,3.18),(-4.08,3.8)]:b.ball('Log cut end',(x,y,.28),(.07,.26,.26),'root',segments=12,rings=8)
    for i in range(36):
        x=rng.uniform(-8.3,8.3);y=rng.uniform(-4.2,6.5)
        if -6.2<x<6.2 and -2.4<y<2.6:continue
        for j in range(4):
            a=j*math.tau/4+rng.random();b.leaf('Ground fern',(x,y,.02),(x+math.cos(a)*.32,y+math.sin(a)*.32,.25),.07,'leaf_bright' if j%2 else 'moss')
    for x,y in [(-6,2.9),(-5.75,3.05),(6.2,3.0),(6.4,3.2),(-7,-2.5)]:
        b.tube('Small fungus stem',[(x,y,.02),(x,y,.22)],.025,'cream',sides=6)
        b.ball('Small fungus cap',(x,y,.25),(.13,.12,.07),'fungus',segments=10,rings=5)
    mesh=join_parts('Woodland clearing / merged solid scenery')
    bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
    path=OUT/'woodland.glb';bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False)
    ENVS.append(mesh)
    return {'file':'assets/woodland.glb','triangles':len(mesh.data.loop_triangles),'materials':len(mesh.data.materials),'collisions':False,'note':'Static visual backdrop only; no navigation, collision or gameplay environment integration.'}


def render_stage():
    for d,rig,mesh in ASSETS:rig.location.x=d['slot']
    studio=bpy.data.collections.new('Presentation / lights and camera');bpy.context.scene.collection.children.link(studio)
    def area(name,pos,power,tint,size):
        data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=tint;data.size=size
        ob=bpy.data.objects.new(name,data);studio.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,1))-ob.location).to_track_quat('-Z','Y').to_euler()
    area('Warm clearing light',(-4,-6,9),1500,(1,.88,.69),8);area('Sky fill',(7,-2,6),1100,(.65,.82,1),7);area('Forest rim',(0,6,7),1800,(.76,1,.78),7)
    world=bpy.data.worlds.new('Woodland sky');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.15,.22,.24,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45;bpy.context.scene.world=world
    camdata=bpy.data.cameras.new('Monster lineup camera');camera=bpy.data.objects.new('Monster lineup camera',camdata);studio.objects.link(camera);camera.location=(5,-19,8.5);camera.rotation_euler=(Vector((0,.25,1.25))-camera.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=14.5
    scene=bpy.context.scene;scene.camera=camera;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False
    scene.render.resolution_x=1800;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ART/'renders/monster-lineup.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(ART/'wildfall-monsters.blend'),compress=True)
    if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)


def main():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    palette=ART/'monster-palette.png';b.png(palette);image=bpy.data.images.load(str(palette));image.name='Wildfall Palette';image.pack()
    briarling();sporecaller();thornback();hollowhart();env=environment()
    (OUT/'manifest.json').write_text(json.dumps({'edition':'Woodland monster designs 01','units':'meters','blenderVersion':bpy.app.version_string,'paletteSize':256,'animated':False,'environment':env,'assets':[x[0] for x in ASSETS]},indent=2)+'\n')
    render_stage()

if __name__=='__main__':main()
