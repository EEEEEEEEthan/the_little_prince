#!/usr/bin/env python3
"""启动 Godot 跑回归脚本；任意 ERROR/WARNING 或超时即失败。"""

from __future__ import annotations

import argparse
import os
import re
import selectors
import subprocess
import sys
import time
from pathlib import Path


FINALIZED_PLANET_IDS = ("B612",)
FAILURE_LINE = re.compile(
    r"(?im)^\s*(?:\x1b\[[0-9;]*m)*"
    r"(?:ERROR|WARNING|SCRIPT ERROR|PARSE ERROR|PARSER ERROR|USER ERROR|USER WARNING)\s*:"
)


def repository_root() -> Path:
    return Path(__file__).resolve().parent.parent


def default_engine_path() -> Path:
    return repository_root() / ".engine" / ".engine"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="跑已定稿星球的完整玩法回归（当前仅 B612）。"
    )
    parser.add_argument(
        "--planet",
        choices=FINALIZED_PLANET_IDS,
        help="只跑指定星球；省略则跑全部已定稿星球",
    )
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument(
        "--engine",
        type=Path,
        default=default_engine_path(),
        help="Godot 可执行文件路径",
    )
    args = parser.parse_args()
    engine_path = args.engine
    if not os.access(engine_path, os.X_OK):
        parser.error(f"找不到可执行引擎：{engine_path}（先运行 .engine-prepare.sh）")

    command = [
        str(engine_path),
        "--headless",
        "--path",
        str(repository_root()),
        "--script",
        "res://tests/regression.gd",
        "--",
    ]
    if args.planet is not None:
        command.extend(["--planet", args.planet])

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=0,
    )
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ, "stdout")
    selector.register(process.stderr, selectors.EVENT_READ, "stderr")
    deadline = time.monotonic() + args.timeout
    failed = False
    failure_reason = ""

    try:
        while selector.get_map():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                failure_reason = f"回归超时（{args.timeout:g}s）"
                failed = True
                break
            for key, _ in selector.select(remaining):
                data = key.fileobj.read(4096)
                if not data:
                    selector.unregister(key.fileobj)
                    continue
                text = data.decode(errors="replace")
                stream = sys.stderr if key.data == "stderr" else sys.stdout
                print(text, end="", file=stream, flush=True)
                if FAILURE_LINE.search(text):
                    failure_reason = "检测到 ERROR 或 WARNING"
                    failed = True
            if failed:
                break
    finally:
        selector.close()
        if failed and process.poll() is None:
            process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()

    if failed:
        print(failure_reason, file=sys.stderr)
        return 1
    if process.returncode != 0:
        print(f"Godot 退出码 {process.returncode}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
