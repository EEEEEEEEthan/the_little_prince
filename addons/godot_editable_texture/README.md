# EditableTexture

A **Godot 4** editor plugin that adds `EditableTexture`, a `Texture2D` resource whose pixel data is stored in the scene/resource (Base64 PNG) and can be edited in an **external** image editor from the inspector, with **undo/redo** when changes are applied.

## Features

- **Serializable texture** — PNG bytes are stored as Base64 via `@export_storage`, so the image travels with your `.tscn` / `.tres` without a separate file dependency.
- **Inspector preview** — Selected `EditableTexture` shows a 128×128 preview in the inspector.
- **Edit in external app** — **Edit** saves a temp PNG, launches your configured editor, and reapplies changes when the file changes (while the Godot editor window is focused).
- **Editor path** — **⚙** picks the executable once; path is stored in editor settings (`editable_texture/external_editor_path`).
- **Undo** — Applying a new image uses `EditorUndoRedoManager` so you can revert.

## Requirements

- Godot **4.x** (uses `@tool`, `EditorInspectorPlugin`, `EditorUndoRedoManager`, etc.)

## Installation

1. Copy this folder into your project as:

   `res://addons/godot_editable_texture`

2. Open **Project → Project Settings → Plugins**, enable **EditableTexture**.

## Usage

1. Create or assign an `EditableTexture` where a `Texture2D` is expected (e.g. `TextureRect`, `Sprite2D`, style textures).
    <img width="379" height="241" alt="image" src="https://github.com/user-attachments/assets/8e7d222d-f0cb-4494-9cd2-27c5fc362ef8" />
2. Use **⚙** if you need to change the external program.
3. In the inspector, use **Edit** to open the temp PNG in your external editor; save the file there to update the resource in Godot.

Empty or invalid data falls back to a 16×16 white placeholder until you set real image data.

## How it works (brief)

- `EditableTexture` extends `Texture2D` and forwards drawing and size/RID queries to an internal `ImageTexture`.
- On edit, the plugin writes a cache PNG, starts a process, polls MD5 while the editor window has focus, and on change loads the PNG back into `EditableTexture` with undo recording.

## License

Add a `LICENSE` file in this repository if you distribute the addon; none is included by default.
