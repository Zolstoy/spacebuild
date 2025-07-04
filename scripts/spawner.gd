extends Node3D

@onready var body_scene: Resource = load("res://scenes/body.tscn")
# @onready var player_scene: Resource = load("res://scenes/player.tscn")

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
	cache.clear()
	timer = 0
	set_process(false)

func get_colored_galactic_node(type: String) -> Node:
	var color: Color
	var galactic_tree: Node3D = body_scene.instantiate()
	var model: CSGSphere3D = galactic_tree.get_child(0)

	if type == "4":
		galactic_tree.scale *= 1
		color = Color.DARK_MAGENTA
	elif type == "2":
		galactic_tree.scale *= 100
		color = Color.ALICE_BLUE
	elif type == "3":
		galactic_tree.scale *= 10
		color = Color.LAWN_GREEN
	elif type == "1":
		galactic_tree.scale *= 1000
		color = Color.GHOST_WHITE
	else:
		assert(false)

	(model.material as StandardMaterial3D).albedo_color = color
	return galactic_tree
