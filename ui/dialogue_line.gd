class_name DialogueLine
extends RefCounted
## 一句对话：说话人、正文、头像。之后可扩成 Resource。

var speaker: String
var text: String
var portrait: Texture2D

func _init(
	p_speaker: String = "", p_text: String = "", p_portrait: Texture2D = null
) -> void:
	speaker = p_speaker
	text = p_text
	portrait = p_portrait
