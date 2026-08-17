class_name InputSetup
extends RefCounted
## 运行时保证 WASD + 方向键的 move_* 动作已注册。
## 即便 project.godot 的 [input] 解析失败，游戏也不会刷 InputMap 报错。

const ACTION_LEFT := "move_left"
const ACTION_RIGHT := "move_right"
const ACTION_UP := "move_up"
const ACTION_DOWN := "move_down"

const ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
]

static var _ensured: bool = false

## 幂等：多次调用只注册一次。在 Main / Player 读输入之前调用即可。
static func ensure_move_actions() -> void:
	if _ensured:
		return
	_ensured = true
	_ensure_action(ACTION_LEFT, [KEY_LEFT, KEY_A])
	_ensure_action(ACTION_RIGHT, [KEY_RIGHT, KEY_D])
	_ensure_action(ACTION_UP, [KEY_UP, KEY_W])
	_ensure_action(ACTION_DOWN, [KEY_DOWN, KEY_S])

static func _ensure_action(action: StringName, physical_keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	for keycode in physical_keys:
		if _action_has_physical_key(action, int(keycode)):
			continue
		var event := InputEventKey.new()
		event.device = -1
		event.physical_keycode = keycode as Key
		InputMap.action_add_event(action, event)

static func _action_has_physical_key(action: StringName, physical_keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and int(key.physical_keycode) == physical_keycode:
			return true
	return false
