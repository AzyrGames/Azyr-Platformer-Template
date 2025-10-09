# class_name EventBus
extends Node

signal trait_added(component_name: String, node: Node)
signal trait_removed(component_name: String, node: Node)
signal component_added(component_name: String, node: Node)
signal component_removed(component_name: String, node: Node)
signal component_enabled(component_name: String)
signal component_disabled(component_name: String)




signal start_game
signal pause_game

signal exit_game
signal quit_game

signal game_started
signal game_paused(_paused: bool)
signal game_exited
signal game_frozen(time_scale: float, duration: float)
signal game_unfrozen()


signal is_full_screen(_value: bool)