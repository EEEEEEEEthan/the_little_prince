class_name DialogueCatalog
extends RefCounted
## 对话目录。按地物 id 取小王子旁白。

const PRINCE_SPEAKER := "小王子"
const ROSE_SPEAKER := "玫瑰"
const PRINCE_PORTRAIT := preload("res://ui/portraits/prince.png")
const ROSE_PORTRAIT := preload("res://ui/portraits/rose.png")


static func lines_for_id(id: StringName) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	match id:
		&"baobab", &"baobab_shoot":
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "刚长出来的时候，跟玫瑰差不多。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "等到太晚，就再也拔不掉了。", PRINCE_PORTRAIT
			))
		&"rose":
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "她是我的玫瑰。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "全宇宙只有这一朵。", PRINCE_PORTRAIT
			))
	return lines
