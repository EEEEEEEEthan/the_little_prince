extends SceneTree

## 由命令行触发：在主场景加载并跑若干帧后抓取 %GameViewport (SubViewport) 的纹理并保存为 PNG。
## 用法（配合 Xvfb 等虚拟显示）：
##   DISPLAY=:42 .engine/.engine --path . \
##       --script res://tests/capture_screenshot.gd --frame 90 --out /workspace/screenshot.png
##
## 不使用 --headless，否则 viewport 纹理不可用。
## 用 SceneTree.process_frame 信号，避免覆写 _process 时签名不匹配。
## 优先抓 %GameViewport（SubViewport）的纹理；OpenGL fallback 下根 Window 纹理抓不到内容。

var _frames_to_wait: int = 90
var _out_path: String = "res://screenshot.png"
var _frames_left: int = 0
var _done: bool = false

func _init():
	var args := OS.get_cmdline_args()
	var i := 0
	while i < args.size():
		var a := args[i]
		if a == "--frame" and i + 1 < args.size():
			_frames_to_wait = int(args[i + 1])
			i += 2
			continue
		if a == "--out" and i + 1 < args.size():
			_out_path = args[i + 1]
			i += 2
			continue
		i += 1
	_frames_left = _frames_to_wait
	print("[capture_screenshot] waiting %d frames, out=%s" % [_frames_to_wait, _out_path])
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if _done:
		return
	if _frames_left > 0:
		_frames_left -= 1
		return
	# 用协程抓取，以便 await 一帧渲染完成
	_capture.call_deferred()

func _capture() -> void:
	if _done:
		return
	_done = true
	# 等待当前帧的渲染提交到 RenderingServer
	await RenderingServer.frame_post_draw
	var root := get_root()
	var vp_tex: ViewportTexture
	# 优先抓 SubViewport（%GameViewport）
	var gv_path := NodePath("/root/Main/GameView/GameViewport")
	var gv := root.get_node_or_null(gv_path)
	if gv == null:
		# 退一步：尝试按 unique name
		gv = root.get_node_or_null(NodePath("/root/Main/%GameViewport"))
	if gv != null and gv is Viewport:
		vp_tex = (gv as Viewport).get_texture()
		print("[capture_screenshot] using SubViewport %s" % gv.get_path())
	else:
		print("[capture_screenshot] GameViewport not found, falling back to root")
		vp_tex = root.get_texture()
	if vp_tex == null:
		print("[capture_screenshot] ERROR: no viewport texture")
		quit(1)
		return
	var img := vp_tex.get_image()
	if img == null:
		print("[capture_screenshot] ERROR: image is null")
		quit(1)
		return
	var err := img.save_png(_out_path)
	if err != OK:
		print("[capture_screenshot] ERROR saving png: %d" % err)
		quit(1)
		return
	# 统计非透明像素数，便于判断是否真的有内容
	var non_transparent := 0
	var w := img.get_width()
	var h := img.get_height()
	var step_max := 1024
	var step := 1 if w * h <= step_max else int(w * h / step_max)
	for y in range(0, h, 1):
		for x in range(0, w, max(1, step)):
			if img.get_pixel(x, y).a > 0.01:
				non_transparent += 1
	print("[capture_screenshot] saved %s size=%s non_transparent_sampled=%d" % [_out_path, img.get_size(), non_transparent])
	quit(0)
