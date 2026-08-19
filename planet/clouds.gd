extends Node2D
## 绕行星的云层：随星球旋转并缓慢自转。
## 子云钉在各自轨道半径上，本地 -Y 朝外，底部始终对着球心。

var planet_rotation: float = 0.0
var _self_rotation: float = 0.0


func _ready() -> void:
	for child in get_children():
		var cloud := child as Sprite2D
		var orbital_angle := atan2(cloud.position.x, -cloud.position.y)
		cloud.position = (
				Vector2(sin(orbital_angle), -cos(orbital_angle)) * cloud.position.length()
		)
		cloud.rotation = orbital_angle
	_sync_transform()


func set_planet_rotation(value: float) -> void:
	planet_rotation = value
	_sync_transform()


func _process(delta: float) -> void:
	_self_rotation = fposmod(
			_self_rotation - WorldConstants.CLOUD_DRIFT_SPEED * delta, TAU
	)
	_sync_transform()


func _sync_transform() -> void:
	rotation = planet_rotation + _self_rotation
	for child in get_children():
		var cloud := child as Sprite2D
		var relative_angle := angle_difference(0.0, cloud.global_rotation)
		cloud.visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
		cloud.z_index = int(cos(relative_angle) * 50.0)
