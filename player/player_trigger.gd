class_name PlayerTrigger
extends Area2D
## 玩家邻近检测：脚底 Area 与本触发器重叠即视为进入草地、可交互范围或日落。

enum Kind {
	GRASS,
	INTERACT,
	SUNSET,
}

@export var kind: Kind = Kind.INTERACT
@export var radius: float = WorldConstants.INTERACT_RANGE_PX:
	set(value):
		radius = value
		if not is_node_ready():
			await ready
		(%CollisionShape2D.shape as CircleShape2D).radius = radius


func hosted_surface_prop() -> SurfaceProp:
	return get_parent() as SurfaceProp
