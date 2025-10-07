extends Node2D
class_name Game2D



@export var asp_projectile_destroy: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_event_bus()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func connect_event_bus() -> void:
	pass