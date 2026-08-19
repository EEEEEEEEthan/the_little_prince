class_name DialogueCatalog
extends RefCounted
## 对话目录。当前只有猴面包树 placeholder，之后按 id 扩展。

const _PRINCE := preload("res://ui/portraits/prince.png")

static func lines_for_id(id: StringName) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	match id:
		&"baobab":
			lines.append(DialogueLine.new("小王子", "这棵猴面包树长得太快了。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "再不拔掉，会把整颗星球撑裂的。", _PRINCE))
		_:
			pass
	return lines
