class_name WorldConstants
extends RefCounted
## 圆弧星球世界的全局默认配置：几何、地物规格与贴图生成尺寸。
## 具体星球实例的半径 / 贴图 / 自转等以 Planet 导出参数为准。

## 星球半径（内部 256×224 像素视口坐标系）。
const PLANET_RADIUS: float = 87.36
## 弧顶（小王子站立处）相对视口高度的比例；偏下使地面留在屏幕底部。
const APEX_Y_RATIO: float = 0.88

## 相对弧顶超过此角的地物视为背面并隐藏。
const VISIBLE_HALF_ARC: float = PI * 0.55

const VOLCANO_COUNT: int = 3
const BAOBAB_COUNT: int = 9
const FLORA_COUNT: int = 75
const BUTTERFLY_COUNT: int = 8

const SPAWN_ANGLE_OFFSET: float = 0.12
## 国王星球只比 B612 大一圈：走几十秒能到觐见，不是第二座能逛的世界。
const KING_PLANET_RADIUS: float = PLANET_RADIUS * 1.2
## 觐见禁区半宽（弧度）：走不到王座脚下，贴边绕行会被弧度带出视野。
const KING_AUDIENCE_KEEP_AWAY_ARC: float = 0.70
## 先听见国王、人还在地平线后：比可见半弧更远。
const KING_DISTANT_VOICE_ARC: float = 2.08

## 可互动物体相对弧顶的半宽（像素，沿圆周）。
const INTERACT_RANGE_PX: float = 16.0
## A 键提示跟随点：地物本地坐标 Y（沿半径向外为负），提示本身不继承旋转。
const INTERACT_PROMPT_LOCAL_Y: float = -38.0
## 头顶打字机：相对弧顶的本地 Y（向上为负），Label 底边对齐此点。
const OVERHEAD_TYPEWRITER_LOCAL_Y: float = -24.0

## 玩家沿线最大速度（像素/秒）；目标角速度 = PLAYER_SPEED / PLANET_RADIUS。
const PLAYER_SPEED: float = 16.0
## 移动阻尼系数（1/秒）：越大起步/刹车越干脆，越小越绵软。
const PLAYER_DAMPING: float = 12.0

const STARFIELD_SIZE: int = 640
const STAR_ROTATION_SPEED: float = 0.01
const CLOUD_DRIFT_SPEED: float = 0.006
const CLOUD_INSTANCE_COUNT: int = 192
const CLOUD_ORBIT_MIN_RADIUS: float = 145.0
const CLOUD_ORBIT_MAX_RADIUS: float = 188.0
const CLOUD_CLUSTER_RADIUS := Vector2(42.0, 16.0)
const CLOUD_SPRITES_PER_MASS_MIN: int = 8
const CLOUD_SPRITES_PER_MASS_MAX: int = 12
const CLOUD_PLACEMENT_SEED: int = 20260819
const CLOUD_INSTANCE_ALPHA_MIN: float = 0.10
const CLOUD_INSTANCE_ALPHA_MAX: float = 0.16
## 白天半宽（弧度）：正午蓝天与黎明各自覆盖的角度，越大白天越长、黄昏夜晚越短。
const DAY_HALF_ARC: float = PI * 0.65

## 地物 / 玩家贴图的生成尺寸（像素）。火山、猴面包树与地表植物以 spritesheet 横向拼接，
## 每个变体一帧，帧尺寸仍为 *_SPRITE_SIZE。小王子为 idle+walk 横拼 spritesheet。
const VOLCANO_SPRITE_SIZE: int = 36
const BAOBAB_SPRITE_SIZE: int = 32
const ROSE_SPRITE_SIZE: int = 20
const KING_SPRITE_WIDTH: int = 20
const KING_SPRITE_HEIGHT: int = 24
const GOLD_SPIRED_THRONE_WIDTH: int = 28
const GOLD_SPIRED_THRONE_HEIGHT: int = 72
const CRIMSON_CAPE_SPREAD_WIDTH: int = 56
const CRIMSON_CAPE_SPREAD_HEIGHT: int = 24
const UNROLLED_PARCHMENT_WIDTH: int = 14
const UNROLLED_PARCHMENT_HEIGHT: int = 10
const SCRATCHED_BORDER_LINES_WIDTH: int = 18
const SCRATCHED_BORDER_LINES_HEIGHT: int = 8
const PALE_PAW_PRINTS_WIDTH: int = 14
const PALE_PAW_PRINTS_HEIGHT: int = 8
const RAT_SPRITE_WIDTH: int = 10
const RAT_SPRITE_HEIGHT: int = 8
const FLORA_SPRITE_SIZE: int = 16
const CLOUD_FRAME_WIDTH: int = 16
const CLOUD_FRAME_HEIGHT: int = 8
const CLOUD_FRAME_COLUMNS: int = 4
const CLOUD_FRAME_ROWS: int = 8
const PLAYER_SPRITE_WIDTH: int = 12
const PLAYER_SPRITE_HEIGHT: int = 18
## 相对弧顶再下移的像素，让脚更贴地。
const PLAYER_VISUAL_Y_OFFSET: float = 2.0
const PLAYER_IDLE_FRAME_COUNT: int = 2
const PLAYER_WALK_FRAME_COUNT: int = 4
const PLAYER_SPRITE_FRAME_COUNT: int = PLAYER_IDLE_FRAME_COUNT + PLAYER_WALK_FRAME_COUNT
const PLAYER_IDLE_FPS: float = 2.0
const PLAYER_WALK_FPS: float = 8.0
## 脚底探测圆半径（像素），用于与草丛 Area 重叠。
const PLAYER_FOOTPRINT_RADIUS: float = 6.0
## 草丛触发区物理层；Area 仅挂此层，不挡行走与互动。
const FLORA_GRASS_PHYSICS_LAYER_INDEX: int = 2
## 每丛 FLORA 一份圆形 Area，比半幅视觉略大。
const FLORA_GRASS_TRIGGER_RADIUS: float = FLORA_SPRITE_SIZE * 0.5 * 1.35

## 火山 spritesheet：死火山变体在前，活火山在后（熔岩发光；烟雾由粒子绘制）。
const VOLCANO_VARIANT_COUNT: int = 3
const VOLCANO_DEAD_VARIANT_COUNT: int = 2
const VOLCANO_ACTIVE_VARIANT: int = 2

## 猴面包树 spritesheet 变体数量（放置时随机外观）。
const BAOBAB_VARIANT_COUNT: int = 4

## 地表植物 spritesheet 变体数量（草绿与冷青干草等）。
const FLORA_VARIANT_COUNT: int = 6
