extends Node2D

@export_enum("Male") var body_type: String = "Male"

var parts := {
	"BackHand": "back_hand",
	"BackShoulder": "back_shoulder",
	"BackThigh": "back_thigh",
	"BackShin": "back_shin",
	"BackFoot": "back_foot",
	"Chest": "chest",
	"Head": "head",
	"FrontThigh": "front_thigh",
	"FrontShin_Idle": "front_shin",
	"FrontShin_Run": "back_shin",
	"FrontFoot_Idle": "front_foot",
	"FrontFoot_Run": "back_foot",
	"FrontShoulder": "front_shoulder",
	"FrontHand": "front_hand"
}

func _ready() -> void:
	load_body_textures()

func load_body_textures() -> void:
	for node_name in parts:
		var sprite: Sprite2D = get_node("Body/%s/Skin" % node_name)

		var texture_path = (
			"res://Entities/Models/Data/Human/Art/%s/%s/armour.png"
			% [body_type, parts[node_name]]
		)

		var tex = load(texture_path)

		if tex:
			sprite.texture = tex
		else:
			push_warning("Texture not found: " + texture_path)
