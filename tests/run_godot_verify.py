#!/usr/bin/env python3
"""Run Godot verification while failing fast on engine errors or hangs."""

from __future__ import annotations

import argparse
import re
import selectors
import subprocess
import sys
import time


ERROR_LINE = re.compile(r"(?im)^\s*(?:ERROR|SCRIPT ERROR|PARSE ERROR|PARSER ERROR):")
ENGINE_SHUTDOWN_NOISE = re.compile(
    r"resources still in use at exit|ObjectDB instances were leaked"
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("a Godot command is required")

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
    error_seen = False

    try:
        while selector.get_map():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                print(f"Godot verification timed out after {args.timeout:g}s", file=sys.stderr)
                error_seen = True
                break
            for key, _ in selector.select(remaining):
                data = key.fileobj.read(4096)
                if not data:
                    selector.unregister(key.fileobj)
                    continue
                text = data.decode(errors="replace")
                print(text, end="", file=sys.stderr if key.data == "stderr" else sys.stdout, flush=True)
                if key.data == "stderr":
                    has_actionable_error = False
                    for stderr_line in text.splitlines():
                        if ENGINE_SHUTDOWN_NOISE.search(stderr_line):
                            continue
                        if ERROR_LINE.search(stderr_line):
                            has_actionable_error = True
                            break
                    if has_actionable_error:
                        error_seen = True
            if error_seen:
                break
    finally:
        selector.close()
        if error_seen and process.poll() is None:
            process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()

    return 1 if error_seen else process.returncode


if __name__ == "__main__":
    raise SystemExit(main())
