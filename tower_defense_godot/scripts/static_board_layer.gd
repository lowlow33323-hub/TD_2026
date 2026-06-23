extends Node2D

var owner_node: Node = null


func _draw() -> void:
	if owner_node != null and owner_node.has_method("_draw_static_layer"):
		owner_node._draw_static_layer(self)
