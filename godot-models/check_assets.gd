extends SceneTree
## Run after --editor --import: godot --headless --path godot-models --script check_assets.gd
func _init() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	var failures: Array[String] = []
	for asset in manifest.assets:
		var model = load("res://" + asset.file).instantiate()
		root.add_child(model)
		var skeletons = model.find_children("*","Skeleton3D",true,false)
		var players = model.find_children("*","AnimationPlayer",true,false)
		if skeletons.size() != 1 or players.size() != 1:
			failures.append(asset.id + " missing skeleton or animation player")
			model.free()
			continue
		var skeleton: Skeleton3D = skeletons[0]
		var player: AnimationPlayer = players[0]
		if skeleton.get_bone_count() != int(asset.bones):
			failures.append(asset.id + " bone count mismatch")
		for clip in asset.clips:
			if not player.has_animation(clip):
				failures.append(asset.id + " missing " + clip)
				continue
			player.play(clip)
			player.advance(0)
			var before := []
			for i in skeleton.get_bone_count():
				before.append(skeleton.get_bone_pose(i))
			player.advance(player.get_animation(clip).length * 0.25)
			var changed := false
			for i in skeleton.get_bone_count():
				if not skeleton.get_bone_pose(i).is_equal_approx(before[i]):
					changed = true
			if not changed:
				failures.append(asset.id + " " + clip + " has no working bone movement")
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if not mesh.skin or mesh.mesh.get_surface_count() > 3:
				failures.append(asset.id + " invalid skin or material surface budget")
		print("GODOT_ASSET_CHECK: ",asset.id," / ",skeleton.get_bone_count()," bones / ",player.get_animation_list())
		model.free()
	for failure in failures:
		push_error(failure)
	print("MODEL_VALIDATION: ","PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
