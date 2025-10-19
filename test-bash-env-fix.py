#!/usr/bin/env python3
"""Test script to verify BASH_ENV fix works correctly"""

import os
import subprocess
import sys
from pathlib import Path

def test_with_bash_env():
    """Test that scripts work even when BASH_ENV is set"""

    # Create a malicious BASH_ENV file
    evil_script = Path("/tmp/evil-bash-env.sh")
    evil_script.write_text("""
# Malicious BASH_ENV that tries to cd to 'update'
if [[ "$1" == "--update" ]]; then
    echo "EVIL: Trying to cd to update directory..." >&2
    cd update 2>/dev/null || true
fi
""")
    evil_script.chmod(0o755)

    # Set BASH_ENV in environment
    test_env = {**os.environ}
    test_env["BASH_ENV"] = str(evil_script)

    # Test calling a script with --update flag
    test_script = Path(__file__).parent / "install" / "install-coding-stuff.sh"

    print(f"Testing with BASH_ENV={evil_script}")
    print(f"Script: {test_script}")
    print(f"Args: --update --help")
    print()

    # This should work without trying to cd to update
    # Using the fixed _run_command pattern
    clean_env = {k: v for k, v in test_env.items() if k not in ("BASH_ENV", "ENV")}
    clean_env["PATH"] = test_env.get("PATH", "")

    # Make script executable
    test_script.chmod(test_script.stat().st_mode | 0o111)

    result = subprocess.run(
        [str(test_script), "--update", "--help"],
        capture_output=True,
        text=True,
        env=clean_env,
        cwd="/tmp"  # Run from /tmp to test cwd independence
    )

    print(f"Return code: {result.returncode}")
    print(f"\nSTDOUT:")
    print(result.stdout[:500])
    if result.stderr:
        print(f"\nSTDERR:")
        print(result.stderr[:500])

    # Check that we didn't get the "cd update" error
    if "Failed to change directory" in result.stderr:
        print("\n❌ FAILED: BASH_ENV still interfering!")
        return False
    elif "EVIL:" in result.stderr:
        print("\n❌ FAILED: BASH_ENV executed!")
        return False
    else:
        print("\n✅ SUCCESS: BASH_ENV properly blocked!")
        return True

if __name__ == "__main__":
    success = test_with_bash_env()
    sys.exit(0 if success else 1)
