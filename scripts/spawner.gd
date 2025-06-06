extends Node3D

class Galactic:
	var Name: String
	var Level: int

var to_instantiate = []

func _process(delta: float) -> void:
	if state == State.PLAYING_SOLO || state == State.PLAYING_ONLINE:
			for key in bodies_infos:
				var body = container.get_node_or_null(str(key)) as Node3D
				assert(body)
				var body_info = bodies_infos[key]
				body_info.timer += delta
				if !bodies_infos.has(body_info.gravity_center):
					continue
				var gravity_center = container.get_node_or_null(str(body_info.gravity_center))
				assert(gravity_center)
				#var body_transform = body.transform as Transform3D
				#body_transform = body_transform.translated(-gravity_center.global_position)
				#body_transform = body_transform.rotated(Vector3.UP, body_info.rotating_speed * delta)
				#body_transform = body_transform.translated(gravity_center.global_position)
				#body.transform = body_transform
				if body_info.timer >= sync_span:
					body_info.timer = 0
					body.position = body_info["new_coords"]
					if body_info.has("prev_coords"):
						body_info["velocity"] = (body_info["new_coords"] - body_info["prev_coords"]).normalized()
					body_info["prev_coords"] = body_info["new_coords"]
					
				if body_info.has("velocity"):
					body.translate(body_info["velocity"] * delta)

		if state != State.PLAYING_SOLO && state != State.PLAYING_ONLINE:
			instantiate_timer = 0
		else:
			instantiate_timer += delta
			if instantiate_timer < instantiate_limit || to_instantiate.is_empty():
				info.set_visible(false)
			else:
				info.set_visible(true)
				for galactic_to_instantiate in to_instantiate:
					#print("Instantiating %s" % galactic_to_instantiate)
					var color = Color()
					var galactic_tree
					if galactic_to_instantiate.type == "Asteroid":
						galactic_tree = asteroid_scene.instantiate()
						color = Color(1, 0, 0)
					elif galactic_to_instantiate.type == "Planet":
						galactic_tree = planet_scene.instantiate()
						color = Color(0, 0, 1)
					elif galactic_to_instantiate.type == "Moon":
						galactic_tree = moon_scene.instantiate()
						color = Color(0, 1, 1)
					elif galactic_to_instantiate.type == "Star":
						galactic_tree = star_scene.instantiate()
						color = Color(1, 1, 1)
					elif galactic_to_instantiate.type == "Player":
						galactic_tree = player_scene.instantiate()
						color = Color(0, 1, 0)
					else:
						assert(false)
					var model = galactic_tree.get_child(0)
					(model.material as StandardMaterial3D).albedo_color = color
					galactic_tree.position = galactic_to_instantiate.coords
					galactic_tree.set_name(str(int(galactic_to_instantiate.id)))
					container.add_child(galactic_tree)
					bodies_infos[int(galactic_to_instantiate.id)] = {
						"timer": 0,
						"new_coords": galactic_tree.position,
						"gravity_center": galactic_to_instantiate.gravity_center,
						"rotating_speed": galactic_to_instantiate.rotating_speed,
					}
					instantiate_timer -= instantiate_limit
					if instantiate_timer < instantiate_limit:
						break
				to_instantiate.clear()
