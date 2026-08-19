class_name WorldConstants
extends RefCounted
## 圆弧星球世界的全局配置：几何、地物规格与贴图生成尺寸。

## 星球半径（内部 256×224 像素视口坐标系）。
const PLANET_RADIUS: float = 87.36
## 弧顶（小王子站立处）相对视口高度的比例；偏下使地面留在屏幕底部。
const APEX_Y_RATIO: float = 0.88

## 相对弧顶超过此角的地物视为背面并隐藏。
const VISIBLE_HALF_ARC: float = PI * 0.55

const VOLCANO_COUNT: int = 3
const BAOBAB_COUNT: int = 16

const SPAWN_ANGLE_OFFSET: float = 0.12

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
const CLOUD_COUNT: int = 6
## 白天半宽（弧度）：正午蓝天与黎明各自覆盖的角度，越大白天越长、黄昏夜晚越短。
const DAY_HALF_ARC: float = PI * 0.65

## 地物 / 玩家贴图的生成尺寸（像素）。火山与猴面包树以 spritesheet 横向拼接，
## 每个变体一帧，帧尺寸仍为 *_SPRITE_SIZE。小王子为 idle+walk 横拼 spritesheet。
const VOLCANO_SPRITE_SIZE: int = 36
const BAOBAB_SPRITE_SIZE: int = 32
const ROSE_SPRITE_SIZE: int = 20
const CLOUD_SPRITE_WIDTH: int = 32
const CLOUD_SPRITE_HEIGHT: int = 16
const CLOUD_VARIANT_COUNT: int = 4
const PLAYER_SPRITE_WIDTH: int = 12
const PLAYER_SPRITE_HEIGHT: int = 18
## 相对弧顶再下移的像素，让脚更贴地。
const PLAYER_VISUAL_Y_OFFSET: float = 2.0
const PLAYER_IDLE_FRAME_COUNT: int = 2
const PLAYER_WALK_FRAME_COUNT: int = 4
const PLAYER_SPRITE_FRAME_COUNT: int = PLAYER_IDLE_FRAME_COUNT + PLAYER_WALK_FRAME_COUNT
const PLAYER_IDLE_FPS: float = 2.0
const PLAYER_WALK_FPS: float = 8.0

## 火山 spritesheet：死火山变体在前，活火山在后（熔岩发光；烟雾由粒子绘制）。
const VOLCANO_VARIANT_COUNT: int = 3
const VOLCANO_DEAD_VARIANT_COUNT: int = 2
const VOLCANO_ACTIVE_VARIANT: int = 2

## 猴面包树 spritesheet 变体数量（放置时随机外观）。
const BAOBAB_VARIANT_COUNT: int = 4
