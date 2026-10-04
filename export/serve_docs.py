#!/usr/bin/env python3
"""本地预览 docs/：对已 gzip 原地压缩的 wasm/pck 补 Content-Encoding。"""
from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class DocsHandler(SimpleHTTPRequestHandler):
	extensions_map = {
		**SimpleHTTPRequestHandler.extensions_map,
		".wasm": "application/wasm",
		".pck": "application/octet-stream",
	}

	def end_headers(self) -> None:
		path = Path(self.translate_path(self.path))
		if path.suffix in {".wasm", ".pck"}:
			self.send_header("Content-Encoding", "gzip")
			self.send_header("Cache-Control", "no-transform")
		self.send_header("Cross-Origin-Opener-Policy", "same-origin")
		self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
		super().end_headers()


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--dir", default="docs")
	parser.add_argument("--port", type=int, default=8080)
	args = parser.parse_args()
	root = Path(args.dir).resolve()
	handler = partial(DocsHandler, directory=str(root))
	server = ThreadingHTTPServer(("0.0.0.0", args.port), handler)
	print(f"serving {root} on http://127.0.0.1:{args.port}")
	server.serve_forever()


if __name__ == "__main__":
	main()
