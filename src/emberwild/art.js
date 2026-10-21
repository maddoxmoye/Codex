import {Color3,DynamicTexture,Mesh,MeshBuilder,PBRMaterial,StandardMaterial,TransformNode,Vector3} from '@babylonjs/core';
export const C=hex=>Color3.FromHexString(hex);
export function createArt(scene){
 const materials=new Map(),primitives=new Map();let serial=0;
 const material=(name,color,{metal=0,rough=.8,glow=0,alpha=1,unlit=false,texture=null}={})=>{
  if(materials.has(name))return materials.get(name);
  const m=unlit?new StandardMaterial(name,scene):new PBRMaterial(name,scene);
  if(unlit){m.diffuseColor=C(color);m.emissiveColor=C(color);m.disableLighting=true;if(texture)m.diffuseTexture=texture;}
  else{m.albedoColor=C(color);m.metallic=metal;m.roughness=rough;m.environmentIntensity=.6;if(texture)m.albedoTexture=texture;m.emissiveColor=C(color).scale(glow);}
  m.alpha=alpha;m.backFaceCulling=false;materials.set(name,m);return m;
 };
 const node=(name,parent=null,x=0,y=0,z=0)=>{const n=new TransformNode(name,scene);n.parent=parent;n.position.set(x,y,z);return n;};
 const part=(type,parent,m,x=0,y=0,z=0,sx=1,sy=sx,sz=sx)=>{
  const name=type+'-'+serial++,opts=type==='sphere'?{diameter:2,segments:16}:(type==='ico'||type==='petal')?{radius:1,subdivisions:type==='petal'?1:2,flat:type!=='petal'}:type==='cone'?{height:1,diameterBottom:2,diameterTop:0,tessellation:10}:type==='cylinder'?{height:1,diameter:2,tessellation:14}:type==='capsule'?{height:1,radius:.2,tessellation:12,subdivisions:3}:type==='torus'?{diameter:2,thickness:.06,tessellation:40}:{size:1};
  let source=primitives.get(type);if(!source){source=type==='sphere'?MeshBuilder.CreateSphere(name,opts,scene):(type==='ico'||type==='petal')?MeshBuilder.CreateIcoSphere(name,opts,scene):type==='cone'||type==='cylinder'?MeshBuilder.CreateCylinder(name,opts,scene):type==='capsule'?MeshBuilder.CreateCapsule(name,opts,scene):type==='torus'?MeshBuilder.CreateTorus(name,opts,scene):MeshBuilder.CreateBox(name,opts,scene);source.setEnabled(false);primitives.set(type,source);}
  const mesh=source.clone(name,parent,true);mesh.setEnabled(true);
  mesh.parent=parent;mesh.position.set(x,y,z);mesh.scaling.set(sx,sy,sz);mesh.material=m;mesh.isPickable=false;mesh.receiveShadows=true;return mesh;
 };
 const tube=(parent,points,r,m)=>{const mesh=MeshBuilder.CreateTube('curve-'+serial++,{path:points.map(v=>new Vector3(...v)),radius:r,tessellation:8,cap:Mesh.CAP_ALL},scene);mesh.parent=parent;mesh.material=m;mesh.isPickable=false;mesh.receiveShadows=true;return mesh;};
 const ring=(parent,m,r=1,y=.025,thickness=.025)=>{const mesh=MeshBuilder.CreateTorus('sigil-'+serial++,{diameter:r*2,thickness,tessellation:64},scene);mesh.parent=parent;mesh.position.y=y;mesh.material=m;mesh.isPickable=false;return mesh;};
 const texture=(name,size,paint)=>{const t=new DynamicTexture(name,{width:size,height:size},scene,false);paint(t.getContext(),size);t.update(false);t.anisotropicFilteringLevel=8;return t;};
 const palette={stone:material('limestone','#c0b59e'),darkStone:material('basalt','#4a6165'),wood:material('bark','#6b4c38'),cloth:material('linen','#e6dbc2'),gold:material('antique-gold','#c89951',{metal:.72,rough:.29}),black:material('ink','#182e35'),bone:material('ivory','#eadfc3'),moss:material('moss','#6c977d'),skin:material('skin','#deb197',{rough:.64}),eye:material('eyes','#142832',{rough:.25}),white:material('white','#e4e6d5'),fire:material('fire','#ff3556',{glow:2}),ice:material('ice','#4d9cff',{glow:1.5,metal:.2,rough:.2}),poison:material('poison','#b64dff',{glow:1.5}),magic:material('aether','#6fe4d2',{glow:1.4}),red:material('mythic','#ff3657',{glow:2}),amber:material('amber','#ffd88c',{glow:1.3}),leather:material('leather','#59423b',{rough:.9})};
 return {scene,material,node,part,tube,ring,texture,palette,materials};
}
