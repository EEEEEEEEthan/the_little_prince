extends SceneTree
## 天空材质应共享；相位与天顶渐变走 instance param，互不影响。


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var holder := Node.new()
	root.add_child(holder)
	var default_planet: Node2D = (load("res://planet/planet.tscn") as PackedScene).instantiate()
	var king_planet: Node2D = (load("res://planet/325.tscn") as PackedScene).instantiate()
	holder.add_child(default_planet)
	holder.add_child(king_planet)
	var default_sky: Sprite2D = default_planet.get_node("%Sky")
	var king_sky: Sprite2D = king_planet.get_node("%Sky")
	if default_sky.material != king_sky.material:
		push_error("[sky_instance_params] 派生星球不应再复制天空 ShaderMaterial")
		quit(1)
		return
	default_sky.commanded_daylight_phase = 0.5
	king_sky.commanded_daylight_phase = 0.0
	var default_phase: float = default_sky.get_instance_shader_parameter(&"phase")
	var king_phase: float = king_sky.get_instance_shader_parameter(&"phase")
	if not is_equal_approx(default_phase, 0.5) or not is_equal_approx(king_phase, 0.0):
		push_error("[sky_instance_params] phase 未按实例写入：%s / %s" % [default_phase, king_phase])
		quit(1)
		return
	if default_sky.zenith_gradient == king_sky.zenith_gradient:
		push_error("[sky_instance_params] zenith_gradient 应按星球实例区分")
		quit(1)
		return
	print("[sky_instance_params] 通过")
	quit(0)
