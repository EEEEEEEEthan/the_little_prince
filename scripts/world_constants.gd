class_name WorldConstants
extends RefCounted
## 全局世界常量：固定 256×224 像素视口内的圆弧星球布局与地物规格。

## ---------- 内部像素视口（SubViewport 原生分辨率） ----------
const INTERNAL_WIDTH: int = 256
const INTERNAL_HEIGHT: int = 224

## ---------- 星球几何（直接在 256×224 坐标系中定义） ----------
## 半径刻意大于「960 参考窗等比缩到 224 高」的约 51px，让可见弧面更宽
const PLANET_RADIUS: float = 84.0
## 弧顶（小王子站立处）相对内部视口高度的比例（0=顶，1=底）
## 保持偏下，使地面/弧顶 Y 不往上移
const APEX_Y_RATIO: float = 0.88
## 内部视口短边；分辨率固定后 visual_scale 恒为 1，仅作兼容引用
const REFERENCE_VIEWPORT: float = float(INTERNAL_HEIGHT)

## ---------- 可见半弧与深度排序 ----------
## 相对弧顶超过此角的地物视为背面（隐藏或淡化）
const VISIBLE_HALF_ARC: float = PI * 0.55
## 背面地物 modulate 透明度下限（0=完全隐藏）
const BACKFACE_ALPHA: float = 0.0

## ---------- 地物数量 ----------
const VOLCANO_COUNT: int = 3
const ROSE_COUNT: int = 1
const BAOBAB_COUNT: int = 28

## 固定世界种子，保证地物角布局可复现
const WORLD_SEED: int = 20260817

## 玫瑰固定角（弧度，0 = 弧顶基准角）
const ROSE_ANGLE: float = 0.0
## 玩家出生角相对玫瑰的偏移（靠近玫瑰）
const SPAWN_ANGLE_OFFSET: float = 0.12

## 火山之间的最小角间距（弧度）
const VOLCANO_MIN_ANGLE: float = TAU / 3.0 * 0.72
## 猴面包树之间的最小角间距
const BAOBAB_MIN_ANGLE: float = 0.10
## 地物与玫瑰/火山的最小角间距（树-树另用 BAOBAB_MIN_ANGLE）
const PROP_CLEARANCE: float = 0.15

## 玩家沿线速度（像素/秒）；角速度 = PLAYER_SPEED / planet_radius
## 相对半径 84 微调，使角速度接近旧 960 窗下 140/220 的手感
const PLAYER_SPEED: float = 56.0

## ---------- 侧视精灵像素尺寸（相对半径 ~84 的像素风比例） ----------
## 静态 PNG 真实像素边长；运行时 preload，不再每次生成
const SPRITE_VOLCANO: int = 36
const SPRITE_BAOBAB: int = 32
const SPRITE_ROSE: int = 20
const SPRITE_PLAYER_W: int = 12
const SPRITE_PLAYER_H: int = 18

## 地物 / 玩家相对 visual_scale 的额外乘数（内部固定分辨率下通常为 1）
const PROP_SCALE: float = 1.0
const PLAYER_SCALE: float = 1.0

## ---------- 星空 ----------
## 星空贴图边长：以球心为中心、覆盖「随玩家角任意旋转」所需方形
## （内切圆半径须 ≥ 球心到视口最远角，约 309px）
const STARFIELD_SIZE: int = 640
## 星空相对星球的自转角速度（弧度/秒）；缓慢持续
const STAR_ROTATION_SPEED: float = 0.02

## ---------- 静态资源路径（由导出脚本写入，运行时 preload） ----------
const ASSET_PRINCE := "res://assets/sprites/prince.png"
const ASSET_ROSE := "res://assets/sprites/rose.png"
const ASSET_VOLCANO := "res://assets/sprites/volcano.png"
const ASSET_BAOBAB := "res://assets/sprites/baobab.png"
const ASSET_PLANET_BODY := "res://assets/planet/body.png"
const ASSET_STARFIELD := "res://assets/bg/starfield.png"
