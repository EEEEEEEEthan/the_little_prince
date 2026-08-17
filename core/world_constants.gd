class_name WorldConstants
extends RefCounted
## 圆弧星球世界的全局配置：几何、地物规格与贴图生成尺寸。

## 星球半径（内部 256×224 像素视口坐标系）。刻意大于等比缩放值，让可见弧面更宽。
const PLANET_RADIUS: float = 84.0
## 弧顶（小王子站立处）相对视口高度的比例；偏下使地面留在屏幕底部。
const APEX_Y_RATIO: float = 0.88

## 相对弧顶超过此角的地物视为背面并隐藏。
const VISIBLE_HALF_ARC: float = PI * 0.55

const VOLCANO_COUNT: int = 3
const BAOBAB_COUNT: int = 28
const WORLD_SEED: int = 20260817

const ROSE_ANGLE: float = 0.0
const SPAWN_ANGLE_OFFSET: float = 0.12

const VOLCANO_MIN_ANGLE: float = TAU / 3.0 * 0.72
const BAOBAB_MIN_ANGLE: float = 0.10
const PROP_CLEARANCE: float = 0.15

## 玩家沿线速度（像素/秒）；角速度 = PLAYER_SPEED / PLANET_RADIUS。
const PLAYER_SPEED: float = 56.0

const STARFIELD_SIZE: int = 640
const STAR_ROTATION_SPEED: float = 0.02

## 地物 / 玩家贴图的生成尺寸（像素）。
const VOLCANO_SPRITE_SIZE: int = 36
const BAOBAB_SPRITE_SIZE: int = 32
const ROSE_SPRITE_SIZE: int = 20
const PLAYER_SPRITE_WIDTH: int = 12
const PLAYER_SPRITE_HEIGHT: int = 18
