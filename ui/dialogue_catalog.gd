class_name DialogueCatalog
extends RefCounted
## 对话目录。按地物 id 取小王子旁白。

const PRINCE_PORTRAIT := preload("res://ui/prince.png")
const DRUNKARD_PORTRAIT := preload("res://ui/slumped_wine_drinker.png")
const GEOGRAPHER_PORTRAIT := preload("res://ui/gray_beard_parchment_scholar.png")


static func lines_for_id(id: StringName) -> Array[DialogueLine]:
	const prince_speaker := "小王子"
	const drunkard_speaker := "酒鬼"
	const geographer_speaker := "地理学家"
	var lines: Array[DialogueLine] = []
	match id:
		&"baobab", &"baobab_shoot":
			lines.append(DialogueLine.new(
					prince_speaker, "刚长出来的时候，跟玫瑰差不多。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					prince_speaker, "等到太晚，就再也拔不掉了。", PRINCE_PORTRAIT
			))
		&"rose":
			lines.append(DialogueLine.new(
					prince_speaker, "她是我的玫瑰。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					prince_speaker, "全宇宙只有这一朵。", PRINCE_PORTRAIT
			))
		&"king":
			lines.append(DialogueLine.new(
					prince_speaker, "他是一位绝对的君主。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					prince_speaker, "他的命令都是通情达理的。", PRINCE_PORTRAIT
			))
		&"drunkard":
			lines.append(DialogueLine.new(
					drunkard_speaker, "喝是为了忘羞耻", DRUNKARD_PORTRAIT
			))
		&"star_jar":
			lines.append(DialogueLine.new(
					prince_speaker, "他把星星锁进玻璃罐。", PRINCE_PORTRAIT
			))
		&"street_lamp":
			lines.append(DialogueLine.new(
					prince_speaker, "帮他点一次。", PRINCE_PORTRAIT
			))
		&"geographer":
			lines.append(DialogueLine.new(
					geographer_speaker, "我只记下别人的报告。", GEOGRAPHER_PORTRAIT
			))
	return lines
