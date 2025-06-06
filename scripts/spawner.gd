extends Node3D

#class Galactic:
	#var Name: String
	#var Level: int

@onready var core = get_tree().get_first_node_in_group("core")
@onready var info = get_tree().get_first_node_in_group("info")

@onready var asteroid_scene: Resource = load("res://scenes/asteroid.tscn")
@onready var planet_scene: Resource = load("res://scenes/planet.tscn")
@onready var moon_scene: Resource = load("res://scenes/moon.tscn")
@onready var star_scene: Resource = load("res://scenes/star.tscn")
@onready var player_scene: Resource = load("res://scenes/player.tscn")

var bodies_infos: Dictionary = {}
var to_instantiate: Array = []
var sync_span: float = 1
var instantiate_timer: float = 0
var instantiate_limit: float = 0.01

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	for key in bodies_infos:
		var body = get_node_or_null(str(key)) as Node3D
		assert(body)
		var body_info = bodies_infos[key]
		body_info.timer += delta
		if !bodies_infos.has(body_info.gravity_center):
			continue
		var gravity_center = get_node_or_null(str(body_info.gravity_center))
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

	if core.state != State.Core.PLAYING_SOLO && core.state != State.Core.PLAYING_ONLINE:
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
				add_child(galactic_tree)
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
