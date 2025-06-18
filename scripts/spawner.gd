extends Node3D

@onready var asteroid_scene: Resource = load("res://scenes/asteroid.tscn")
@onready var planet_scene: Resource = load("res://scenes/planet.tscn")
@onready var moon_scene: Resource = load("res://scenes/moon.tscn")
@onready var star_scene: Resource = load("res://scenes/star.tscn")
@onready var player_scene: Resource = load("res://scenes/player.tscn")

@onready var core = get_tree().get_first_node_in_group("core")
@onready var info = get_tree().get_first_node_in_group("info")

var to_instantiate: Dictionary = {}
var timer: float = 0
var cache: Dictionary = {}

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	timer += delta
	info.set_visible(!to_instantiate.is_empty())

	if timer > 1:
		for id in to_instantiate:
			var galactic_info = to_instantiate[id]
			var galactic_tree = get_colored_galactic_node(galactic_info.type)
			galactic_tree.position = galactic_info.coords
			galactic_tree.set_name(str(id))
			galactic_tree.rotating_speed = galactic_info.rotating_speed
			if galactic_info.type == "1":
				galactic_tree.set_process(false)
			else:
				galactic_tree.gravity_center_id = galactic_info.gravity_center_id
			cache[id] = galactic_tree
			add_child(galactic_tree)
		to_instantiate.clear()
		timer = 0

func stop():
	for node in get_children():
		remove_child(node);
	to_instantiate.clear()
	timer = 0
	set_process(false)

func get_colored_galactic_node(type: String) -> Node:
	var color: Color
	var galactic_tree: Node
	if type == "4":
		galactic_tree = asteroid_scene.instantiate()
		color = Color(1, 0, 0)
	elif type == "2":
		galactic_tree = planet_scene.instantiate()
		color = Color(0, 0, 1)
	elif type == "3":
		galactic_tree = moon_scene.instantiate()
		color = Color(0, 1, 1)
	elif type == "1":
		galactic_tree = star_scene.instantiate()
		color = Color(1, 1, 1)
	else:
		assert(false)
	var model = galactic_tree.get_child(0)
	(model.material as StandardMaterial3D).albedo_color = color
	return galactic_tree
