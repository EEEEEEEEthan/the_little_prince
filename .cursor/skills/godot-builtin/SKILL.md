---
name: godot-builtin
description: 本仓库资源放置：只用过一次的脚本/贴图/shader 必须写进所属 tscn 的 builtin。编写或审查 .tscn/.gd/.gdshader/贴图引用时使用。
---

# 单次引用必须 builtin

只被**一个** `.tscn` 引用的资源不要留独立文件，写进该场景：

| 类型 | 写法 |
|------|------|
| 脚本 | `[sub_resource type="GDScript"]` + `script/source` |
| Shader | `[sub_resource type="Shader"]` + `code` |
| 仅一处用的 PNG | `[sub_resource type="Texture2D"]` + `EditableTexture` 的 `_base64_data` |

Godot **禁止** builtin 脚本写 `class_name`。跨文件类型改用已有工具类上的枚举，或 `has_method` / 无类型节点引用。需要全局 `class_name` 的脚本必须外置。

## 继续留独立文件的

- 被多个场景挂载或 `preload`/`load`/`extends "res://...gd"` 的脚本（如 `planet_run_shell.gd`、`surface_prop.gd`、`planet_playable.gd`）
- 多星球共用的 shader / 贴图 / 音频（如 `sky.gdshader`、`starfield.png`、BGM）
- 无场景挂载的工具类（`WorldConstants`、`SkyPhase`、`DialogueCatalog`）
- `addons/` 插件

## 场景根

继承场景（如 `main.tscn` 实例化 `planet_run_shell.tscn`）的根脚本用 builtin。非继承、且脚本只服务该场景时，根脚本同样 builtin，不必再配同名 `.gd`。

## 手改 tscn

`script/source` / `code` 里的 `"` 写成 `\"`。优先在编辑器里改嵌入脚本。
