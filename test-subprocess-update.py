#!/usr/bin/env python3
"""Test script to reproduce the subprocess issue"""

import os
import subprocess
import sys

# Simulate what our setup_manager does
clean_env = {**os.environ}
bash_env_before = clean_env.get("BASH_ENV", "<not set>")
print(f"BASH_ENV before: {bash_env_before}")

clean_env.pop("BASH_ENV", None)
clean_env.pop("ENV", None)
clean_env.pop("PROMPT_COMMAND", None)
clean_env.pop("CDPATH", None)

script = "/bin/bash"
args = ["-c", "echo 'Args received:' && for arg in \"$@\"; do echo \"  - $arg\"; done", "bash", "--update"]

cmd = ["/bin/bash", "--noprofile", "--norc", "--", "-c",
       "echo 'Working dir:' && pwd && echo 'Args:' && for arg in \"$@\"; do echo \"  $arg\"; done",
       "bash", "--update"]

print(f"Command: {cmd}")
print(f"Working dir: {os.getcwd()}")

result = subprocess.run(cmd, capture_output=True, text=True, env=clean_env)
print(f"\nReturn code: {result.returncode}")
print(f"STDOUT:\n{result.stdout}")
print(f"STDERR:\n{result.stderr}")
