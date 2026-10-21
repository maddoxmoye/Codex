extends SceneTree
func _init() -> void:
	call_deferred("validate")
func validate() -> void:
	var failures: Array[String] = []
	var stage = load("res://bestiary.tscn").instantiate()
	root.add_child(stage)
	stage.set_process(false)
	if stage.manifest.assets.size()!=4:failures.append("Expected four monster concepts")
	for item in stage.manifest.assets:
		var model: Node3D = stage.models[item.id]
		var skeletons := model.find_children("*","Skeleton3D",true,false)
		if skeletons.size()!=1 or skeletons[0].get_bone_count()!=int(item.bones):failures.append(item.id+" skeleton mismatch")
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if not mesh.skin or mesh.mesh.get_surface_count()>3:failures.append(item.id+" invalid skin/material count")
		for player in model.find_children("*","AnimationPlayer",true,false):
			if player.get_animation_list().size()>0:failures.append(item.id+" unexpected animation in static design pass")
		stage.select_model(item.id)
		if not model.visible or model.position!=Vector3.ZERO:failures.append(item.id+" cannot be inspected at origin")
		for other in stage.models:
			if other!=item.id and stage.models[other].visible:failures.append("Other models obscure selected monster")
	stage.select_model("lineup")
	for item in stage.manifest.assets:
		if not stage.models[item.id].visible or not is_equal_approx(stage.models[item.id].position.x,float(item.slot)):failures.append("Lineup loses original proportions/spacing")
	stage.set_environment(false)
	if stage.environment.visible or not stage.studio.visible:failures.append("Studio backdrop toggle fails")
	stage.set_environment(true)
	if not stage.environment.visible:failures.append("Woodland backdrop toggle fails")
	for size in [Vector2i(1280,900),Vector2i(390,844)]:
		root.size = size
		for item in stage.manifest.assets:
			stage.select_model(item.id)
			for turn in [0.12,PI/2,PI]:
				stage.turn = turn
				stage.update_camera(1.0)
				var camera: Camera3D = stage.camera
				for mesh in stage.models[item.id].find_children("*","MeshInstance3D",true,false):
					var bounds: AABB = mesh.mesh.get_aabb()
					for i in 8:
						var point: Vector3 = mesh.global_transform*bounds.get_endpoint(i)
						if camera.is_position_behind(point):failures.append(item.id+" behind camera")
						var screen := camera.unproject_position(point)
						if screen.x<0 or screen.x>size.x or screen.y<0 or screen.y>size.y:failures.append(item.id+" clipped at viewport "+str(size))
	for failure in failures:push_error(failure)
	print("BESTIARY_VALIDATION: ","PASS" if failures.is_empty() else "FAIL")
	stage.free()
	quit(0 if failures.is_empty() else 1)
