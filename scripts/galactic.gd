extends Node3D

@onready var core = get_tree().get_first_node_in_group("core")
@onready var debug_scene: Resource = load("res://scenes/debug.tscn")

var rotating_speed: float
var gravity_center_id = null

var gravity_center: Node = null
var debug_tree: Node3D = null

var prev_coord = null
func _ready() -> void:
	debug_tree = debug_scene.instantiate()
	#debug_tree.scale.z *= 10
	add_child(debug_tree)
var timer = 0

func _process(delta: float) -> void:
	if !gravity_center:
		if core.spawner.cache.has(gravity_center_id):
			gravity_center = core.spawner.cache[gravity_center_id]
			var pos_delta: Vector3 = gravity_center.global_position - global_position
			debug_tree.translate(Vector3.FORWARD * pos_delta.length() / 2)
			debug_tree.global_transform = debug_tree.global_transform.scaled(Vector3(1, 1, pos_delta.length()))

		return
#
	#timer += delta
	##if timer > 1:
	#debug_tree.look_at(gravity_center.global_position, Vector3.UP, true)
		#timer = 0

	# translate(-gravity_center.position)
	# rotate(Vector3.UP, rotating_speed * delta)
	# translate(gravity_center.position)
