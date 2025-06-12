extends Node3D

@onready var asteroid_scene: Resource = load("res://scenes/asteroid.tscn")
@onready var planet_scene: Resource = load("res://scenes/planet.tscn")
@onready var moon_scene: Resource = load("res://scenes/moon.tscn")
@onready var star_scene: Resource = load("res://scenes/star.tscn")
@onready var player_scene: Resource = load("res://scenes/player.tscn")

@onready var core = get_tree().get_first_node_in_group("core")
@onready var info = get_tree().get_first_node_in_group("info")

var bodies_infos: Dictionary = {}
var to_instantiate: Array = []
var sync_span: float = 1
var instantiate_timer: float = 0
var instantiate_limit: float = 1

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	for key in bodies_infos:
		var body = get_node_or_null(str(key)) as Node3D
		assert(body)
		var body_info = bodies_infos[key]
		body.position = body_info["new_coords"]

	for galactic_to_instantiate in to_instantiate:
		var galactic_tree = get_colored_galactic_node(galactic_to_instantiate.type)
		galactic_tree.position = galactic_to_instantiate.coords
		galactic_tree.set_name(str(galactic_to_instantiate.id))
		add_child(galactic_tree)
		bodies_infos[galactic_to_instantiate.id] = {
			"new_coords": galactic_tree.position,
		}
	to_instantiate.clear()

func get_colored_galactic_node(type: String) -> Node:
	var color: Color
	var galactic_tree: Node
	if type == "Asteroid":
		galactic_tree = asteroid_scene.instantiate()
		color = Color(1, 0, 0)
	elif type == "Planet":
		galactic_tree = planet_scene.instantiate()
		color = Color(0, 0, 1)
	elif type == "Moon":
		galactic_tree = moon_scene.instantiate()
		color = Color(0, 1, 1)
	elif type == "Star":
		galactic_tree = star_scene.instantiate()
		color = Color(1, 1, 1)
	elif type == "Player":
		galactic_tree = player_scene.instantiate()
		color = Color(0, 1, 0)
	else:
		assert(false)
	var model = galactic_tree.get_child(0)
	(model.material as StandardMaterial3D).albedo_color = color
	return galactic_tree
