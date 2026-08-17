class_name SkyPhase
extends RefCounted
## 天空一天循环的「相位」映射：把星空相对角度（0=正午、DAY_HALF_ARC=日出、
## π=午夜、TAU-DAY_HALF_ARC=日落）映射到天空渐变（天顶/地平线/夜空）的
## X 坐标（0=午夜、0.25=日出、0.5=正午、0.75=日落、1=午夜），反之亦然。
## 烘焙工具与运行时共用同一套映射，保证渐变点与游戏角度一一对应。

## 正午在贴图上的 X 坐标。
const NOON_PHASE: float = 0.5
## 日出（中心与左端的中点）在贴图上的 X 坐标。
const SUNRISE_PHASE: float = 0.25
## 日落（中心与右端的中点）在贴图上的 X 坐标。
const SUNSET_PHASE: float = 0.75

static func angle_to_phase(angle: float) -> float:
	var a := fposmod(angle, TAU)
	var dawn := WorldConstants.DAY_HALF_ARC
	var night := PI - dawn
	if a <= dawn:
		return NOON_PHASE - SUNRISE_PHASE * (a / dawn)
	if a <= PI:
		return SUNRISE_PHASE - SUNRISE_PHASE * ((a - dawn) / night)
	if a <= TAU - dawn:
		return 1.0 - SUNRISE_PHASE * ((a - PI) / night)
	return SUNSET_PHASE - SUNRISE_PHASE * ((a - (TAU - dawn)) / dawn)

static func phase_to_angle(phase: float) -> float:
	var x := fposmod(phase, 1.0)
	var dawn := WorldConstants.DAY_HALF_ARC
	var night := PI - dawn
	if x <= SUNRISE_PHASE:
		return dawn + 4.0 * night * (SUNRISE_PHASE - x)
	if x <= NOON_PHASE:
		return 4.0 * dawn * (NOON_PHASE - x)
	if x <= SUNSET_PHASE:
		return TAU - dawn + 4.0 * dawn * (SUNSET_PHASE - x)
	return PI + 4.0 * night * (1.0 - x)
