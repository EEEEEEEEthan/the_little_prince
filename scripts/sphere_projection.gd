class_name SphereProjection
extends RefCounted
## 与 sphere_fisheye.gdshader 一致的正/逆球面投影工具。
##
## Shader 正向（屏幕 p → UV offset）：
##   r = |p|; z = sqrt(1-r^2); angle = acos(z)*curvature
##   offset = dir * (angle/HALF_PI) * (view_span*0.5)
##
## 本类提供逆映射：地物 UV → 屏幕像素，供 PropScreenOverlay 使用。

const HALF_PI: float = PI * 0.5
## 与 shader 默认值对齐，避免 Main 尚未读到材质时漂移
const DEFAULT_CURVATURE: float = 1.55
const DEFAULT_VIEW_SPAN: float = 0.48
## 环面 UV 差视为「球心」的阈值
const CENTER_EPSILON: float = 1e-8

## 环面最短 UV 差，分量约落在 [-0.5, 0.5]
static func torus_delta_uv(prop_uv: Vector2, player_uv: Vector2) -> Vector2:
	var d := prop_uv - player_uv
	d.x -= floorf(d.x + 0.5)
	d.y -= floorf(d.y + 0.5)
	return d

## 地物 UV → PlanetView 屏幕像素。
## 返回字典：visible, screen_pos, p, r, z, dir, lean, delta_uv
static func world_to_screen(
	prop_uv: Vector2,
	player_uv: Vector2,
	view_size: Vector2,
	curvature: float = DEFAULT_CURVATURE,
	view_span: float = DEFAULT_VIEW_SPAN
) -> Dictionary:
	var delta_uv := torus_delta_uv(prop_uv, player_uv)
	var offset_len := delta_uv.length()
	var size := Vector2(maxf(view_size.x, 1.0), maxf(view_size.y, 1.0))
	var min_side := minf(size.x, size.y)
	var center := size * 0.5

	if offset_len < CENTER_EPSILON:
		# 与玩家重合 → 球心；无径向，lean=0
		return {
			"visible": true,
			"screen_pos": center,
			"p": Vector2.ZERO,
			"r": 0.0,
			"z": 1.0,
			"dir": Vector2(0, -1),
			"lean": 0.0,
			"delta_uv": delta_uv,
		}

	var dir := delta_uv / offset_len
	# offset_len = (angle/HALF_PI)*(view_span*0.5) → angle
	var angle := offset_len / (view_span * 0.5) * HALF_PI
	var ang_over_curv := angle / curvature
	# 越过球面剪影（正交半球 z<=0）则不可见；完整背面阈为 PI，此处用 HALF_PI
	if ang_over_curv >= HALF_PI:
		return {
			"visible": false,
			"screen_pos": center,
			"p": Vector2.ZERO,
			"r": 0.0,
			"z": cos(ang_over_curv),
			"dir": dir,
			"lean": 0.0,
			"delta_uv": delta_uv,
		}

	var z := cos(ang_over_curv)
	var r := sqrt(maxf(0.0, 1.0 - z * z))
	var p := dir * r
	var screen_pos := center + p * (min_side * 0.5)
	# lean：屏幕半径 smoothstep，中心 0 → 边缘 1
	var lean := r * r * (3.0 - 2.0 * r)

	return {
		"visible": true,
		"screen_pos": screen_pos,
		"p": p,
		"r": r,
		"z": z,
		"dir": dir,
		"lean": lean,
		"delta_uv": delta_uv,
	}

## 世界像素 → 屏幕像素的统一尺度（sprite.scale 与 pitch 换算共用）。
## 近球心线性化，与 shader 的 curvature / view_span 对齐：
##   d(screen)/d(world) = (HALF_PI/curvature) * min_side / (WORLD_PIXELS * view_span)
## extra_scale：额外放大（默认 1；pitch 凸出可用 STACK_SCREEN_PITCH_SCALE）
static func world_to_screen_scale(
	min_side: float,
	view_span: float = DEFAULT_VIEW_SPAN,
	curvature: float = DEFAULT_CURVATURE,
	extra_scale: float = 1.0
) -> float:
	var curv := maxf(curvature, 0.001)
	var span := maxf(view_span, 0.001)
	var side := maxf(min_side, 1.0)
	return (HALF_PI / curv) * side / (float(WorldConstants.WORLD_PIXELS) * span) * maxf(extra_scale, 0.0)

## 世界 pitch（贴图像素间距）→ 屏幕像素间距；与 world_to_screen_scale 一致。
static func world_pitch_to_screen(
	world_pitch: float,
	min_side: float,
	view_span: float = DEFAULT_VIEW_SPAN,
	curvature: float = DEFAULT_CURVATURE,
	scale: float = -1.0
) -> float:
	var s := scale if scale > 0.0 else WorldConstants.STACK_SCREEN_PITCH_SCALE
	return world_pitch * world_to_screen_scale(min_side, view_span, curvature, s)

## 层叠后顶层的有效屏幕半径（单位圆坐标）。>1 即戳出球面剪影。
static func effective_screen_r(
	anchor_r: float,
	lean: float,
	screen_pitch: float,
	layer_index: int,
	min_side: float
) -> float:
	var pixel_radius := min_side * 0.5
	if pixel_radius < 1.0:
		return anchor_r
	var extra := screen_pitch * float(layer_index) * lean / pixel_radius
	return anchor_r + extra
