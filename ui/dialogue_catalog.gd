class_name DialogueCatalog
extends RefCounted
## 对话目录。按地物 id 取小王子旁白。

const _PRINCE := preload("res://ui/portraits/prince.png")


static func lines_for_id(id: StringName) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	match id:
		&"baobab", &"baobab_shoot":
			lines.append(DialogueLine.new("小王子", "刚长出来的时候，跟玫瑰差不多。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "等到太晚，就再也拔不掉了。", _PRINCE))
		&"rose":
			lines.append(DialogueLine.new("小王子", "她是我的玫瑰。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "全宇宙只有这一朵。", _PRINCE))
		&"volcano_active":
			lines.append(DialogueLine.new("小王子", "这座还活着。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "早上热早点很方便。", _PRINCE))
		&"volcano_dead":
			lines.append(DialogueLine.new("小王子", "这座已经熄了。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "谁知道呢。", _PRINCE))
	return lines
