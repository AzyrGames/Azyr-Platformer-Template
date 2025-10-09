extends Area2D
class_name Checkpoint2D

@export var character_respawn_point: CharacterRespawnPoint

@export var collision_shape : CollisionShape2D
@export var sprite_static : Sprite2D
@export var sprite_indicator : Sprite2D

@export var is_active: bool = false:
	set(value):
		is_active = value
		sprite_indicator.visible = value


func _input(event: InputEvent) -> void:
	pass


func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:

	if GameManager.current_checkpoint:
		GameManager.current_checkpoint.is_active = false
	GameManager.current_checkpoint = self
	is_active = true
	EventBus.check_point_entered.emit(true)
	pass # Replace with function body.




func _on_area_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	area.is_inside_check_point = false
	EventBus.check_point_entered.emit(false)
	pass # Replace with function body.
