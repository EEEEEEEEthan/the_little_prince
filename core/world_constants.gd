class_name WorldConstants
extends RefCounted
## 圆弧星球世界的全局配置：几何、地物规格与贴图生成尺寸。

## 星球半径（内部 256×224 像素视口坐标系）。
const PLANET_RADIUS: float = 72.8
## 弧顶（小王子站立处）相对视口高度的比例；偏下使地面留在屏幕底部。
const APEX_Y_RATIO: float = 0.88

## 相对弧顶超过此角的地物视为背面并隐藏。
const VISIBLE_HALF_ARC: float = PI * 0.55

const VOLCANO_COUNT: int = 3
const BAOBAB_COUNT: int = 16

const SPAWN_ANGLE_OFFSET: float = 0.12

## 玩家沿线最大速度（像素/秒）；目标角速度 = PLAYER_SPEED / PLANET_RADIUS。
const PLAYER_SPEED: float = 20.0
## 移动阻尼系数（1/秒）：越大起步/刹车越干脆，越小越绵软。
const PLAYER_DAMPING: float = 12.0

const STARFIELD_SIZE: int = 640
const STAR_ROTATION_SPEED: float = 0.01
## 白天半宽（弧度）：正午蓝天与黎明各自覆盖的角度，越大白天越长、黄昏夜晚越短。
const DAY_HALF_ARC: float = PI * 0.65

## 地物 / 玩家贴图的生成尺寸（像素）。火山与猴面包树以 spritesheet 横向拼接，
## 每个变体一帧，帧尺寸仍为 *_SPRITE_SIZE。
const VOLCANO_SPRITE_SIZE: int = 36
const BAOBAB_SPRITE_SIZE: int = 32
const ROSE_SPRITE_SIZE: int = 20
const PLAYER_SPRITE_WIDTH: int = 12
const PLAYER_SPRITE_HEIGHT: int = 18

## 火山 spritesheet：前 2 帧为死火山（形态各异），第 3 帧为活火山（熔岩发光 + 烟）。
const VOLCANO_VARIANT_COUNT: int = 3
const VOLCANO_DEAD_VARIANT_COUNT: int = 2
const VOLCANO_ACTIVE_VARIANT: int = 2

## 猴面包树 spritesheet 变体数量（放置时随机外观）。
const BAOBAB_VARIANT_COUNT: int = 4
