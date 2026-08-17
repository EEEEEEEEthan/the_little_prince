class_name Starfield
extends Sprite2D
## 深空星野：静态 assets/bg/starfield.png（256×224），铺满内部像素视口。

const _STAR_TEX: Texture2D = preload("res://assets/bg/starfield.png")

func _ready() -> void:
	z_index = -100
	texture = _STAR_TEX
	centered = false
	position = Vector2.ZERO
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
