class_name DialogueCatalog
extends RefCounted
## 对话目录。按地物 id 取小王子旁白。

const _PRINCE := preload("res://ui/portraits/prince.png")

static func lines_for_id(id: StringName) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	match id:
		&"baobab":
			lines.append(DialogueLine.new("小王子", "这棵猴面包树长得太快了。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "再不拔掉，会把整颗星球撑裂的。", _PRINCE))
		&"rose":
			lines.append(DialogueLine.new("小王子", "她是我的玫瑰。全宇宙只有这一朵。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "我每天给她浇水，夜里还要罩上玻璃罩。", _PRINCE))
		&"volcano_active":
			lines.append(DialogueLine.new("小王子", "这座火山还活着。我每天都要疏通它。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "不然哪天喷火，会把整颗星球烧掉。", _PRINCE))
		&"volcano_dead":
			lines.append(DialogueLine.new("小王子", "这座火山已经熄灭了。", _PRINCE))
			lines.append(DialogueLine.new("小王子", "不过我还是会打扫。谁知道它会不会再醒过来。", _PRINCE))
	return lines
