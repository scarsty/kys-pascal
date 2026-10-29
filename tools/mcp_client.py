"""Small stdlib MCP client for reproducible native game investigations.

This is a test/automation client; the executable itself is the MCP server.
"""
from __future__ import annotations

import json
from pathlib import Path
import queue
import subprocess
import threading


class Game:
    def __init__(self, executable: str | Path, mod: str | Path, *, debug=False, timeout=30, save_dir=None, allow_legacy_checkpoints=False):
        args = [str(Path(executable).resolve()), "--mod", str(Path(mod).resolve())]
        if debug:
            args.append("--debug")
        if allow_legacy_checkpoints:
            args.append("--allow-legacy-checkpoints")
        if save_dir is not None:
            args.extend(["--save-dir", str(Path(save_dir).resolve())])
        self.process = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE, text=True, encoding="utf-8")
        self.timeout = timeout
        self.sequence = 0
        self.output = queue.Queue()
        self.diagnostics: list[str] = []
        self.reader = threading.Thread(target=self._read, daemon=True)
        self.error_reader = threading.Thread(target=self._read_errors, daemon=True)
        self.reader.start()
        self.error_reader.start()
        try:
            self.rpc("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                    "clientInfo": {"name": "kys-validation", "version": "1"}})
            self.process.stdin.write('{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
            self.process.stdin.flush()
        except BaseException:
            self.close()
            raise

    def _read(self):
        for line in self.process.stdout:
            self.output.put(line)
        self.output.put(None)

    def _read_errors(self):
        self.diagnostics.extend(self.process.stderr)

    def rpc(self, method, params=None):
        self.sequence += 1
        self.process.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.sequence,
                                            "method": method, "params": params or {}}) + "\n")
        self.process.stdin.flush()
        try:
            line = self.output.get(timeout=self.timeout)
        except queue.Empty as exc:
            raise TimeoutError(f"Native MCP timeout in {method}; stderr={''.join(self.diagnostics)}") from exc
        if line is None:
            raise RuntimeError(f"Native MCP exited ({self.process.poll()}): {''.join(self.diagnostics)}")
        response = json.loads(line)
        assert response["id"] == self.sequence, response
        if "error" in response:
            raise RuntimeError(response["error"])
        return response["result"]

    def call(self, name, **arguments):
        result = self.rpc("tools/call", {"name": name, "arguments": arguments})
        value = json.loads(result["content"][0]["text"])
        if result.get("isError"):
            raise RuntimeError(value)
        return value

    def close(self):
        self.process.stdin.close()
        if self.process.poll() is None:
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        self.reader.join(timeout=1)
        self.error_reader.join(timeout=1)
        for stream in (self.process.stdout, self.process.stderr):
            stream.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()
