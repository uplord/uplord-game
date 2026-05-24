extends CharacterBody2D
class_name Player

@onready var body = $Base/Model

func _ready():
	await get_tree().process_frame
