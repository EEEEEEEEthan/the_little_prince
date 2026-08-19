extends Node2D
## 绕行星的云层：小帧团簇叠成云团，随星球旋转并缓慢自转。
## 每实例本地 -Y 朝外，底部始终对着球心。背面按可见半弧缩到零。

var planet_rotation: float = 0.0
var _self_rotation: float = 0.0

@onready var _cloud_sprites: MultiMeshInstance2D = %CloudSprites


func _ready() -> void:
	_rebuild_instances()
	_sync_transform()


func set_planet_rotation(value: float) -> void:
	planet_rotation = value
	_sync_transform()


func _process(delta: float) -> void:
	_self_rotation = fposmod(
			_self_rotation - WorldConstants.CLOUD_DRIFT_SPEED * delta, TAU
	)
	_sync_transform()


func _rebuild_instances() -> void:
	var cloud_multimesh := MultiMesh.new()
	cloud_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	cloud_multimesh.use_colors = true
	var quad_mesh := QuadMesh.new()
	quad_mesh.orientation = PlaneMesh.FACE_Z
	quad_mesh.size = Vector2(
			WorldConstants.CLOUD_FRAME_WIDTH, WorldConstants.CLOUD_FRAME_HEIGHT
	)
	cloud_multimesh.mesh = quad_mesh
	var frame_material := _cloud_sprites.material as ShaderMaterial
	frame_material.set_shader_parameter(
			"frame_columns", float(WorldConstants.CLOUD_FRAME_COLUMNS)
	)
	frame_material.set_shader_parameter(
			"frame_rows", float(WorldConstants.CLOUD_FRAME_ROWS)
	)
	var sprite_count := WorldConstants.CLOUD_INSTANCE_COUNT
	cloud_multimesh.instance_count = sprite_count
	var placement_rng := RandomNumberGenerator.new()
	placement_rng.seed = WorldConstants.CLOUD_PLACEMENT_SEED
	var instance_index := 0
	while instance_index < sprite_count:
		var orbital_angle := placement_rng.randf() * TAU
		var orbit_radius := placement_rng.randf_range(
				WorldConstants.CLOUD_ORBIT_MIN_RADIUS,
				WorldConstants.CLOUD_ORBIT_MAX_RADIUS,
		)
		var outward := Vector2(sin(orbital_angle), -cos(orbital_angle))
		var tangent := Vector2(cos(orbital_angle), sin(orbital_angle))
		var sprites_in_mass := mini(
				placement_rng.randi_range(
						WorldConstants.CLOUD_SPRITES_PER_MASS_MIN,
						WorldConstants.CLOUD_SPRITES_PER_MASS_MAX,
				),
				sprite_count - instance_index,
		)
		for _sprite_index in sprites_in_mass:
			var offset_unit := (
					Vector2.from_angle(placement_rng.randf() * TAU)
					* placement_rng.randf()
					* placement_rng.randf()
			)
			var local_position := (
					outward * orbit_radius
					+ tangent * offset_unit.x * WorldConstants.CLOUD_CLUSTER_RADIUS.x
					+ outward * offset_unit.y * WorldConstants.CLOUD_CLUSTER_RADIUS.y
			)
			local_position = Vector2(roundf(local_position.x), roundf(local_position.y))
			var orbit_distance := local_position.length()
			if orbit_distance < WorldConstants.CLOUD_ORBIT_MIN_RADIUS:
				local_position *= WorldConstants.CLOUD_ORBIT_MIN_RADIUS / orbit_distance
				local_position = Vector2(roundf(local_position.x), roundf(local_position.y))
			var instance_orbit_angle := atan2(local_position.x, -local_position.y)
			cloud_multimesh.set_instance_transform_2d(
					instance_index,
					Transform2D(instance_orbit_angle, local_position),
			)
			var row_index := placement_rng.randi_range(
					0, WorldConstants.CLOUD_FRAME_ROWS - 1
			)
			cloud_multimesh.set_instance_color(
					instance_index,
					Color(
							float(row_index) / float(WorldConstants.CLOUD_FRAME_ROWS - 1),
							placement_rng.randf(),
							placement_rng.randf(),
							placement_rng.randf_range(
									WorldConstants.CLOUD_INSTANCE_ALPHA_MIN,
									WorldConstants.CLOUD_INSTANCE_ALPHA_MAX,
							),
					),
			)
			instance_index += 1
	_cloud_sprites.multimesh = cloud_multimesh


func _sync_transform() -> void:
	rotation = planet_rotation + _self_rotation
	var cloud_multimesh := _cloud_sprites.multimesh
	for instance_index in cloud_multimesh.instance_count:
		var local_position := cloud_multimesh.get_instance_transform_2d(instance_index).origin
		var orbital_angle := atan2(local_position.x, -local_position.y)
		var relative_angle := angle_difference(0.0, rotation + orbital_angle)
		var instance_scale := Vector2.ONE
		if absf(relative_angle) > WorldConstants.VISIBLE_HALF_ARC:
			instance_scale = Vector2.ZERO
		cloud_multimesh.set_instance_transform_2d(
				instance_index,
				Transform2D(orbital_angle, instance_scale, 0.0, local_position),
		)
