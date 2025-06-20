extends Node3D

@onready var core = get_tree().get_first_node_in_group("core")

var rotating_speed: float
var gravity_center_id = null

var gravity_center: Node = null

var prev_coord = null
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !gravity_center:
		if core.spawner.cache.has(gravity_center_id):
			gravity_center = core.spawner.cache[gravity_center_id]
		return

	translate(-gravity_center.position)
	rotate(Vector3.UP, rotating_speed * delta)
	translate(gravity_center.position)
