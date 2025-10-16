extends Node3D

@onready var core = get_tree().get_first_node_in_group("core")

var rotating_speed = null
var gravity_center_id = null

var gravity_center: Node = null

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !gravity_center:
		if core.spawner.cache.has(gravity_center_id):
			gravity_center = core.spawner.cache[gravity_center_id]
			core.spawner.remove_child(self)
			gravity_center.add_child(self)
		return

	#global_rotate(Vector3.UP, rotating_speed * delta)
