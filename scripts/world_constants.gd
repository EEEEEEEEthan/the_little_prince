class_name WorldConstants
extends RefCounted
## 全局世界常量：2D 圆弧星球的布局与地物规格集中管理。

## ---------- 星球几何（相对 960×960 参考分辨率，运行时按窗口缩放） ----------
## 参考分辨率下的星球半径（像素）；刻意做小，营造「小星球」剪影
## 球心在屏幕下方外，底部只露出浅浅一段弧面
const PLANET_RADIUS: float = 220.0
## 弧顶（小王子站立处）相对视口高度的比例（0=顶，1=底）
## 大幅偏下，使可见地表贴在屏幕底部
const APEX_Y_RATIO: float = 0.88
## 参考视口短边，用于把 PLANET_RADIUS 缩放到实际窗口
const REFERENCE_VIEWPORT: float = 960.0

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
const PLAYER_SPEED: float = 140.0

## ---------- 侧视精灵像素尺寸（小星球 + 大地物：相对半径应明显高于旧大圆） ----------
## 贴图像素边长；运行时再乘 visual_scale（≈1 @ 参考窗），故「变大」主要靠这些常量
const SPRITE_VOLCANO: int = 120
const SPRITE_BAOBAB: int = 96
const SPRITE_ROSE: int = 60
const SPRITE_PLAYER_W: int = 40
const SPRITE_PLAYER_H: int = 58

## 地物 / 玩家相对 visual_scale 的额外乘数（保持 ≈1 时仅靠 SPRITE_* 定绝对大小）
## 需要微调观感时改这里，避免把窗口缩放逻辑搅糊
const PROP_SCALE: float = 1.0
const PLAYER_SCALE: float = 1.0
