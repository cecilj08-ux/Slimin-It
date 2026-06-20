extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body is Enemy: body.death("fall")
	else: body.queue_free()
