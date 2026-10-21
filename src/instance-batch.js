import * as T from 'three';
import {WORLD} from './world.js';

// Keep model geometry and materials shared. The GPU draws all copies of a part
// together, instead of submitting every creature's eyes, horns and body alone.
function instanceBuckets(scene){
 const buckets=new Map();
 function resize(bucket,capacity){
  const previous=bucket.mesh;
  const mesh=new T.InstancedMesh(bucket.geometry,bucket.material,capacity);
  mesh.instanceMatrix.setUsage(T.DynamicDrawUsage);
  mesh.frustumCulled=false; // Callers cull individual creatures before submission.
  mesh.castShadow=bucket.castShadow;mesh.receiveShadow=true;mesh.count=0;
  bucket.capacity=capacity;bucket.mesh=mesh;scene.add(mesh);
  if(previous){scene.remove(previous);previous.dispose();}
 }
 return {
  get(geometry,material,castShadow=false){
   const key=geometry.uuid+material.uuid+castShadow;
   if(!buckets.has(key)){const bucket={geometry,material,castShadow,count:0};resize(bucket,256);buckets.set(key,bucket);}
   return buckets.get(key);
  },
  begin(size){for(const bucket of buckets.values()){bucket.count=0;if(size>bucket.capacity)resize(bucket,2**Math.ceil(Math.log2(size)));}},
  push(bucket,matrix,color){const index=bucket.count++;bucket.mesh.setMatrixAt(index,matrix);if(color)bucket.mesh.setColorAt(index,color);},
  end(){for(const bucket of buckets.values()){bucket.mesh.count=bucket.count;bucket.mesh.visible=bucket.count>0;if(bucket.count){bucket.mesh.instanceMatrix.needsUpdate=true;if(bucket.mesh.instanceColor)bucket.mesh.instanceColor.needsUpdate=true;}}},
  dispose(){for(const bucket of buckets.values()){scene.remove(bucket.mesh);bucket.mesh.dispose();}buckets.clear();}
 };
}
export function createEnemyBatch(scene){
 const instances=instanceBuckets(scene),frustum=new T.Frustum(),projection=new T.Matrix4(),bounds=new T.Sphere(),tintColor=new T.Color();
 return {
  register(root){
   const parts=[];root.userData.body.traverse(mesh=>{if(mesh.isMesh)parts.push({mesh,bucket:instances.get(mesh.geometry,mesh.material,mesh.castShadow),color:new T.Color()});});
   root.userData.batchParts=parts;root.userData.body.visible=false;
  },
  update(enemies,camera){
   instances.begin(enemies.size);camera.updateMatrixWorld();frustum.setFromProjectionMatrix(projection.multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse));
   for(const [enemy,root] of enemies){
    bounds.center.copy(root.position);bounds.center.y+=enemy.kind==='boss'?1.5:1;bounds.radius=enemy.kind==='boss'?3.5:1.8;
    if(!frustum.intersectsSphere(bounds))continue;
    root.updateMatrixWorld(true);
    const tint=enemy.hitFlash>0?'#f6dfbd':enemy.poison>0?'#b34dff':enemy.burn>0?'#ff334d':enemy.slow>0?'#397dff':null;
    const changed=root.userData.batchTint!==tint;root.userData.batchTint=tint;
    if(tint)tintColor.set(tint);
    for(const part of root.userData.batchParts){
     if(changed){
      const original=part.mesh.material.color;
      part.color.copy(original);if(tint)part.color.lerp(tintColor,.6);
      // instanceColor multiplies the material; divide to retain the intended hue.
      part.color.setRGB(part.color.r/Math.max(.0001,original.r),part.color.g/Math.max(.0001,original.g),part.color.b/Math.max(.0001,original.b));
     }
     instances.push(part.bucket,part.mesh.matrixWorld,part.color);
    }
   }
   instances.end();
  },
  dispose:()=>instances.dispose()
 };
}
export function createPickupBatch(scene,geometry,materials){
 const instances=instanceBuckets(scene),transform=new T.Object3D(),buckets={};
 for(const kind of ['coin','xp','heal'])buckets[kind]=instances.get(kind==='coin'?geometry.coin:geometry.gem,materials[kind]);
 return {
  update(pickups,time){
   instances.begin(pickups.length);
   for(const pickup of pickups){
    transform.position.set((pickup.x-WORLD.width/2)/100,.16+Math.sin(time*3+pickup.x)*.045,(pickup.y-WORLD.height/2)/100);
    transform.rotation.set(pickup.kind==='coin'?Math.PI/2:0,time*1.8,0);transform.scale.set(.065,pickup.kind==='coin'?.025:.1,.065);transform.updateMatrix();
    instances.push(buckets[pickup.kind]||buckets.coin,transform.matrix);
   }
   instances.end();
  },
  dispose:()=>instances.dispose()
 };
}
