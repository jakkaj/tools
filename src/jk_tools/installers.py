"""
Cross-platform tool installers for jk-tools.

RATIONALE FOR THIS MODULE
=========================
The original installer architecture used individual bash scripts (.sh files)
orchestrated by a Python setup_manager.py. This created three layers of
indirection: Python → bash → actual tool commands (npm, cargo, curl, etc.).

This was fundamentally broken on Windows and fragile everywhere:
- Windows has no /bin/bash; Git Bash or WSL shims were required
- Each .sh script was essentially a one-liner wrapped in 200 lines of
  boilerplate (OS detection, error handling, PATH management)
- The actual tool commands (npm install, cargo install, curl, etc.) are
  ALREADY cross-platform — the bash wrapper added nothing but pain

This module replaces ALL bash installer scripts with pure Python functions.
Each installer calls subprocess.run() directly with the real tool commands.
No shell dependency. Works natively on Windows, macOS, and Linux.

The .sh files are retained in install/ for anyone running them standalone,
but setup_manager.py no longer invokes them.
"""

import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    import tomllib  # Python 3.11+
    _load_toml = tomllib.loads
except ModuleNotFoundError:
    try:
        import tomli  # type: ignore
        _load_toml = tomli.loads
    except ModuleNotFoundError:
        _load_toml = None

try:
    import tomli_w  # type: ignore
    _dump_toml = tomli_w.dumps
except ModuleNotFoundError:
    try:
        import toml  # type: ignore
        _dump_toml = toml.dumps
    except ModuleNotFoundError:
        _dump_toml = None


# ---------------------------------------------------------------------------
# InstallResult (shared with setup_manager)
# ---------------------------------------------------------------------------
from dataclasses import dataclass


@dataclass
class InstallResult:
    """Result of an installation attempt."""
    name: str
    success: bool
    message: str
    output: str
    error: str
    duration: float
    version_before: Optional[str] = None
    version_after: Optional[str] = None


# ---------------------------------------------------------------------------
# ToolInstaller
# ---------------------------------------------------------------------------

class ToolInstaller:
    """Cross-platform installer for developer tools.

    Each ``install_*`` method installs one tool and returns an InstallResult.
    No bash dependency — all commands are invoked directly via subprocess.
    """

    def __init__(self, resource_root: Path, *, verbose: bool = False):
        self.resource_root = resource_root
        self.verbose = verbose
        self.is_windows = platform.system() == "Windows"
        self.is_macos = platform.system() == "Darwin"
        self.path_sep = ";" if self.is_windows else ":"
        self.home = Path.home()

    # ------------------------------------------------------------------
    # Dry-run / preflight
    # ------------------------------------------------------------------

    def preflight(self) -> List[dict]:
        """Return a preflight report for every install step.

        Each entry is a dict with keys:
            name, description, status ('ready', 'skip', 'missing_prereq'),
            prereqs (list of {name, found}), action (what would happen)
        """
        steps = [
            self._preflight_just(),
            self._preflight_rust(),
            self._preflight_code2prompt(),
            self._preflight_fs2(),
            self._preflight_agents(),
            self._preflight_claude_code(),
            self._preflight_codex(),
            self._preflight_copilot_cli(),
            self._preflight_aliases(),
        ]
        return steps

    def _pf(self, name, desc, prereqs, action, installed_check=None):
        """Build a single preflight entry."""
        found = {p: self._check_command(p) for p in prereqs}
        already = bool(installed_check and self._check_command(installed_check))
        if already:
            ver = self._get_version(installed_check) or "unknown"
            return dict(name=name, description=desc,
                        status="skip", reason=f"Already installed ({ver})",
                        prereqs=[{"name": k, "found": v} for k, v in found.items()],
                        action="No action needed")
        all_ok = all(found.values()) if found else True
        return dict(name=name, description=desc,
                    status="ready" if all_ok else "missing_prereq",
                    reason="" if all_ok else f"Missing: {', '.join(k for k,v in found.items() if not v)}",
                    prereqs=[{"name": k, "found": v} for k, v in found.items()],
                    action=action if all_ok else f"BLOCKED — {action}")

    def _preflight_just(self):
        return self._pf("just", "Command runner (alternative to make)",
                        ["curl"] if not self.is_windows else [],
                        "Download binary from just.systems", "just")

    def _preflight_rust(self):
        return self._pf("rust", "Rust toolchain (rustc, cargo, rustup)",
                        ["curl"] if not self.is_windows else [],
                        "Download and run rustup installer", "cargo")

    def _preflight_code2prompt(self):
        return self._pf("code2prompt", "Code-to-LLM-prompt converter",
                        ["cargo"], "cargo install code2prompt", "code2prompt")

    def _preflight_fs2(self):
        return self._pf("fs2", "FlowSpace code intelligence + MCP server",
                        ["uvx"], "uvx install from git+flow_squared", "fs2")

    def _preflight_agents(self):
        v2 = self.resource_root / "agents" / "v2-commands"
        mcp = self.resource_root / "agents" / "mcp" / "servers.json"
        prereqs_ok = v2.is_dir() and mcp.is_file()
        return dict(name="agents", description="MCP configs + agent command files",
                    status="ready" if prereqs_ok else "missing_prereq",
                    reason="" if prereqs_ok else "Missing agents/v2-commands or servers.json",
                    prereqs=[{"name": "agents/v2-commands/", "found": v2.is_dir()},
                             {"name": "agents/mcp/servers.json", "found": mcp.is_file()}],
                    action="Copy v2-commands to CLI dirs, generate MCP configs")

    def _preflight_claude_code(self):
        return self._pf("claude-code", "Anthropic Claude Code CLI",
                        ["npm"], "npm install -g @anthropic-ai/claude-code", "claude")

    def _preflight_codex(self):
        return self._pf("codex", "OpenAI Codex CLI",
                        ["npm"], "npm install -g @openai/codex", "codex")

    def _preflight_copilot_cli(self):
        return self._pf("copilot-cli", "GitHub Copilot CLI",
                        ["npm"], "npm install -g @githubnext/github-copilot-cli", "copilot")

    def _preflight_aliases(self):
        scripts = self.resource_root / "scripts"
        return dict(name="aliases", description="Shell aliases for scripts/",
                    status="ready" if scripts.is_dir() else "skip",
                    reason="" if scripts.is_dir() else "No scripts/ directory",
                    prereqs=[], action="Generate ~/.tools_aliases")

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _run(
        self,
        cmd: List[str],
        timeout: int = 300,
        env: Optional[Dict[str, str]] = None,
    ) -> Tuple[int, str, str]:
        """Run a command, return (returncode, stdout, stderr)."""
        run_env = os.environ.copy()
        if env:
            run_env.update(env)
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=run_env,
            )
            return result.returncode, result.stdout, result.stderr
        except FileNotFoundError:
            return -1, "", f"Command not found: {cmd[0]}"
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except Exception as exc:
            return -1, "", str(exc)

    def _check_command(self, name: str) -> bool:
        """Return True if *name* is on PATH."""
        return shutil.which(name) is not None

    def _get_version(self, command: str) -> Optional[str]:
        """Run ``command --version`` and return the first line, or None."""
        try:
            r = subprocess.run(
                [command, "--version"],
                capture_output=True, text=True, timeout=10,
            )
            if r.returncode == 0:
                ver = r.stdout.strip().split("\n")[0].strip()
                if command == "codex" and ver.startswith("codex-cli "):
                    return ver.replace("codex-cli ", "")
                if command == "claude" and " (Claude Code)" in ver:
                    return ver.replace(" (Claude Code)", "")
                return ver
        except Exception:
            pass
        return None

    def _npm_prefix(self) -> Path:
        """Return (and create) the user-local npm prefix directory."""
        prefix = self.home / ".npm-global"
        prefix.mkdir(parents=True, exist_ok=True)
        return prefix

    def _ensure_npm_path(self) -> None:
        """Add the npm prefix to the current process PATH."""
        prefix = self._npm_prefix()
        # On Windows npm puts binaries directly in the prefix dir
        dirs_to_add = [str(prefix / "bin"), str(prefix)] if self.is_windows else [str(prefix / "bin")]
        current = os.environ.get("PATH", "")
        for d in dirs_to_add:
            if d not in current:
                os.environ["PATH"] = d + self.path_sep + os.environ.get("PATH", "")

    def _npm_install(self, package: str) -> Tuple[int, str, str]:
        """Run ``npm install -g <package>`` with user-local prefix."""
        prefix = self._npm_prefix()
        # Set prefix
        self._run(["npm", "config", "set", "prefix", str(prefix)], timeout=30)
        self._ensure_npm_path()
        return self._run(["npm", "install", "-g", package], timeout=120)

    def _ensure_cargo_path(self) -> None:
        """Add ~/.cargo/bin to PATH if not already there."""
        cargo_bin = str(self.home / ".cargo" / "bin")
        if cargo_bin not in os.environ.get("PATH", ""):
            os.environ["PATH"] = cargo_bin + self.path_sep + os.environ.get("PATH", "")

    def _timed(self, name: str, fn) -> InstallResult:
        """Run *fn*, capture timing, return InstallResult."""
        start = time.time()
        try:
            success, message, output, error = fn()
        except Exception as exc:
            success, message, output, error = False, str(exc), "", str(exc)
        return InstallResult(
            name=name,
            success=success,
            message=message,
            output=output,
            error=error,
            duration=time.time() - start,
        )

    # ------------------------------------------------------------------
    # Simple installers
    # ------------------------------------------------------------------

    def install_just(self) -> InstallResult:
        """Install *just* command runner."""
        def _do():
            if self._check_command("just"):
                ver = self._get_version("just") or "unknown"
                return True, f"just already installed ({ver})", "", ""

            local_bin = self.home / ".local" / "bin"
            local_bin.mkdir(parents=True, exist_ok=True)

            if self.is_windows:
                # Use PowerShell to download and extract
                url = "https://just.systems/install.sh"
                rc, out, err = self._run(
                    ["powershell", "-Command",
                     f"iwr -useb {url} | & {{ $input | bash -s -- --to '{local_bin}' }}"],
                    timeout=60,
                )
                # Fallback: try cargo
                if rc != 0 and self._check_command("cargo"):
                    rc, out, err = self._run(["cargo", "install", "just"], timeout=300)
            else:
                # Unix: curl | bash
                rc, out, err = self._run(
                    ["bash", "-c",
                     f"curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to {local_bin}"],
                    timeout=60,
                )

            # Add to PATH
            bin_str = str(local_bin)
            if bin_str not in os.environ.get("PATH", ""):
                os.environ["PATH"] = bin_str + self.path_sep + os.environ.get("PATH", "")

            if self._check_command("just"):
                ver = self._get_version("just") or ""
                return True, f"Successfully installed just {ver}", out, err
            return rc == 0, "just installed (verify PATH)" if rc == 0 else f"Failed to install just", out, err

        return self._timed("just", _do)

    def install_rust(self) -> InstallResult:
        """Install Rust via rustup."""
        def _do():
            self._ensure_cargo_path()
            if self._check_command("cargo") and self._check_command("rustc"):
                ver = self._get_version("rustc") or "unknown"
                return True, f"Rust already installed ({ver})", "", ""

            if self.is_windows:
                # On Windows, download rustup-init.exe
                rustup_init = self.home / "rustup-init.exe"
                try:
                    urllib.request.urlretrieve(
                        "https://win.rustup.rs/x86_64", str(rustup_init)
                    )
                except Exception as exc:
                    return False, f"Failed to download rustup: {exc}", "", str(exc)
                rc, out, err = self._run([str(rustup_init), "-y", "--default-toolchain", "stable"], timeout=600)
                rustup_init.unlink(missing_ok=True)
            else:
                rc, out, err = self._run(
                    ["bash", "-c",
                     "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"],
                    timeout=600,
                )

            self._ensure_cargo_path()
            if self._check_command("cargo"):
                ver = self._get_version("rustc") or ""
                return True, f"Successfully installed Rust {ver}", out, err
            return False, "Failed to install Rust", out, err

        return self._timed("rust", _do)

    def install_code2prompt(self) -> InstallResult:
        """Install code2prompt via cargo."""
        def _do():
            self._ensure_cargo_path()
            if self._check_command("code2prompt"):
                ver = self._get_version("code2prompt") or "unknown"
                return True, f"code2prompt already installed ({ver})", "", ""

            if not self._check_command("cargo"):
                return False, "cargo not found — install Rust first", "", "cargo not found"

            rc, out, err = self._run(["cargo", "install", "code2prompt"], timeout=600)
            if self._check_command("code2prompt"):
                ver = self._get_version("code2prompt") or ""
                return True, f"Successfully installed code2prompt {ver}", out, err
            return rc == 0, "Installed code2prompt" if rc == 0 else "Failed to install code2prompt", out, err

        return self._timed("code2prompt", _do)

    def install_claude_code(self) -> InstallResult:
        """Install Claude Code CLI via npm."""
        def _do():
            self._ensure_npm_path()
            if self._check_command("claude"):
                ver = self._get_version("claude") or "unknown"
                return True, f"Claude Code already installed ({ver})", "", ""

            if not self._check_command("npm"):
                return False, "npm not found — install Node.js first", "", "npm not found"

            rc, out, err = self._npm_install("@anthropic-ai/claude-code")
            self._ensure_npm_path()
            if self._check_command("claude"):
                ver = self._get_version("claude") or ""
                return True, f"Successfully installed Claude Code {ver}", out, err
            # npm install succeeded but binary not found in PATH yet
            if rc == 0:
                return True, "Installed Claude Code (restart shell to use)", out, err
            return False, "Failed to install Claude Code", out, err

        return self._timed("claude-code", _do)

    def install_codex(self) -> InstallResult:
        """Install OpenAI Codex CLI via npm."""
        def _do():
            self._ensure_npm_path()
            if self._check_command("codex"):
                ver = self._get_version("codex") or "unknown"
                return True, f"Codex already installed ({ver})", "", ""

            if not self._check_command("npm"):
                return False, "npm not found — install Node.js first", "", "npm not found"

            rc, out, err = self._npm_install("@openai/codex")
            self._ensure_npm_path()
            if self._check_command("codex"):
                ver = self._get_version("codex") or ""
                return True, f"Successfully installed Codex {ver}", out, err
            if rc == 0:
                return True, "Installed Codex (restart shell to use)", out, err
            return False, "Failed to install Codex", out, err

        return self._timed("codex", _do)

    def install_copilot_cli(self) -> InstallResult:
        """Install GitHub Copilot CLI via npm."""
        def _do():
            self._ensure_npm_path()
            if self._check_command("copilot"):
                ver = self._get_version("copilot") or "unknown"
                return True, f"Copilot CLI already installed ({ver})", "", ""

            if not self._check_command("npm"):
                return False, "npm not found — install Node.js first", "", "npm not found"

            rc, out, err = self._npm_install("@githubnext/github-copilot-cli")
            self._ensure_npm_path()
            if rc == 0:
                return True, "Successfully installed Copilot CLI", out, err
            return False, "Failed to install Copilot CLI", out, err

        return self._timed("copilot-cli", _do)

    def install_fs2(self) -> InstallResult:
        """Install FlowSpace (fs2) via uvx."""
        def _do():
            if self._check_command("fs2"):
                ver = self._get_version("fs2") or "unknown"
                return True, f"fs2 already installed ({ver})", "", ""

            uv_cmd = "uv"
            if not self._check_command(uv_cmd):
                return False, "uv not found — install uv first", "", "uv not found"

            rc, out, err = self._run(
                ["uvx", "--from", "git+https://github.com/AI-Substrate/flow_squared", "fs2", "install"],
                timeout=120,
            )
            if rc == 0:
                return True, "Successfully installed fs2", out, err
            return False, "Failed to install fs2", out, err

        return self._timed("fs2", _do)

    # ------------------------------------------------------------------
    # Aliases
    # ------------------------------------------------------------------

    def install_aliases(self) -> InstallResult:
        """Generate convention-based aliases for scripts."""
        def _do():
            scripts_path = self.resource_root / "scripts"
            if not scripts_path.exists():
                return True, "No scripts directory found, skipping aliases", "", ""

            scripts = [f for f in scripts_path.iterdir()
                       if f.is_file() and (self.is_windows or os.access(f, os.X_OK))]
            if not scripts:
                return True, "No scripts found, skipping aliases", "", ""

            new_aliases: Dict[str, str] = {}
            for script_file in scripts:
                name = script_file.stem
                if "-" not in name:
                    continue
                parts = name.split("-")
                alias = "jk-" + "".join(p[0].lower() for p in parts if p)
                if shutil.which(alias):
                    continue  # avoid conflicts
                new_aliases[alias] = str(script_file.resolve())

            if not new_aliases:
                return True, "No aliases to create", "", ""

            aliases_file = self.home / ".tools_aliases"
            with open(aliases_file, "w") as f:
                f.write("# Auto-generated aliases for tools repository\n")
                f.write("# Generated by jk-tools installers.py\n")
                f.write("# DO NOT EDIT - This file is auto-generated\n\n")
                for alias, command in sorted(new_aliases.items()):
                    f.write(f"alias {alias}='{command}'\n")

            # Source in .zshrc (Unix only)
            if not self.is_windows:
                zshrc = self.home / ".zshrc"
                source_line = f'[ -f "{aliases_file}" ] && source "{aliases_file}" # Tools repository aliases'
                if zshrc.exists():
                    content = zshrc.read_text()
                    if str(aliases_file) not in content:
                        with open(zshrc, "a") as f:
                            f.write(f"\n{source_line}\n")

            return True, f"Created {len(new_aliases)} alias(es)", "", ""

        return self._timed("aliases", _do)

    # ------------------------------------------------------------------
    # Agents (MCP config + command file installation)
    # ------------------------------------------------------------------

    def install_agents(
        self,
        *,
        clear_mcp: bool = False,
        commands_local: str = "",
        local_dir: str = "",
    ) -> InstallResult:
        """Install agent commands and MCP server configs.

        This replaces agents.sh — copies v2-commands to all CLI directories
        and generates MCP configurations from servers.json.
        """
        def _do():
            repo_root = self.resource_root
            v2_source = repo_root / "agents" / "v2-commands"
            mcp_source = repo_root / "agents" / "mcp" / "servers.json"

            # Local mode
            if commands_local:
                return self._install_local_commands(
                    commands_local, local_dir or str(Path.cwd()), v2_source,
                )

            # Validate source
            if not v2_source.is_dir():
                return False, f"v2-commands not found: {v2_source}", "", ""
            md_files = sorted(v2_source.glob("*.md"))
            if not md_files:
                return False, f"No .md files in {v2_source}", "", ""

            output_lines: List[str] = []

            # Target directories
            claude_dir = self.home / ".claude" / "commands"
            opencode_dir = self.home / ".config" / "opencode" / "command"
            codex_dir = self.home / ".codex" / "prompts"
            copilot_prompts = self.home / ".config" / "github-copilot" / "prompts"
            copilot_cli_dir = Path(os.environ.get("XDG_CONFIG_HOME", str(self.home))) / ".copilot"
            copilot_cli_agents = copilot_cli_dir / "agents"
            copilot_cli_default = self.home / ".copilot"
            copilot_cli_default_agents = copilot_cli_default / "agents"

            if self.is_macos:
                vscode_user_dir = self.home / "Library" / "Application Support" / "Code" / "User"
            else:
                vscode_user_dir = self.home / ".config" / "Code" / "User"
            vscode_project_dir = repo_root / ".vscode"

            # Create all dirs
            for d in [claude_dir, opencode_dir, codex_dir, copilot_prompts,
                       copilot_cli_dir, copilot_cli_agents,
                       vscode_user_dir, vscode_project_dir]:
                d.mkdir(parents=True, exist_ok=True)

            # Clean stale plan commands
            for d, pat in [
                (claude_dir, "plan-[0-9]*"),
                (opencode_dir, "plan-[0-9]*"),
                (codex_dir, "plan-[0-9]*"),
                (vscode_project_dir, "plan-[0-9]*"),
                (copilot_prompts, "plan-[0-9]*.prompt.md"),
                (copilot_cli_agents, "plan-[0-9]*"),
            ]:
                for stale in d.glob(pat):
                    stale.unlink()

            # Copy v2-commands to all targets
            for md in md_files:
                shutil.copy2(md, claude_dir / md.name)
                shutil.copy2(md, opencode_dir / md.name)
                shutil.copy2(md, codex_dir / md.name)
                shutil.copy2(md, vscode_project_dir / md.name)
                prompt_name = md.stem + ".prompt.md"
                shutil.copy2(md, copilot_prompts / prompt_name)

            output_lines.append(f"Copied {len(md_files)} command files to all targets")

            # Generate Copilot CLI agent files
            skip = {"README.md", "GETTING-STARTED.md"}
            agent_count = 0
            for md in md_files:
                if md.name in skip:
                    continue
                self._generate_agent_md(md, copilot_cli_agents)
                agent_count += 1

            # Mirror to default location if XDG override
            if str(copilot_cli_dir) != str(copilot_cli_default):
                copilot_cli_default_agents.mkdir(parents=True, exist_ok=True)
                for af in copilot_cli_agents.glob("*.agent.md"):
                    shutil.copy2(af, copilot_cli_default_agents / af.name)

            output_lines.append(f"Generated {agent_count} Copilot CLI agents")

            # MCP config generation
            if mcp_source.is_file():
                ok, msg = self._generate_mcp_configs(
                    mcp_source=mcp_source,
                    repo_root=repo_root,
                    vscode_user_config=vscode_user_dir / "mcp.json",
                    vscode_project_config=vscode_project_dir / "mcp.json",
                    copilot_cli_mcp=copilot_cli_dir / "mcp-config.json",
                    clear_mcp=clear_mcp,
                )
                if ok:
                    output_lines.append("MCP configuration updated")
                else:
                    return False, msg, "\n".join(output_lines), msg
            else:
                output_lines.append("No servers.json found, skipping MCP config")

            return True, "Successfully installed agents", "\n".join(output_lines), ""

        return self._timed("agents", _do)

    def _generate_agent_md(self, source: Path, dest_dir: Path) -> None:
        """Convert a v2-command .md file into a Copilot CLI .agent.md file."""
        content = source.read_text(encoding="utf-8")
        agent_name = source.stem
        desc = f"Command: {agent_name}"
        content_body = content

        if content.startswith("---"):
            fm = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
            if fm:
                for line in fm.group(1).split("\n"):
                    if line.strip().startswith("description:"):
                        desc = line.partition(":")[2].strip().strip("\"'")
                        break
                content_body = content[fm.end():]

        frontmatter = (
            f'---\nname: "{agent_name}"\n'
            f'description: "{desc}"\n'
            f'tools:\n  - "*"\n---\n\n'
        )
        dest = dest_dir / f"{source.stem}.agent.md"
        dest.write_text(frontmatter + content_body.lstrip(), encoding="utf-8")

    def _load_env_file(self) -> Dict[str, str]:
        """Load .env key=value pairs from the first found env file."""
        candidates = [
            Path.cwd() / ".env",
            self.home / ".jk-tools.env",
            self.resource_root / ".env",
        ]
        for path in candidates:
            if path.is_file():
                result: Dict[str, str] = {}
                for line in path.read_text(encoding="utf-8").splitlines():
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if "=" in line:
                        k, _, v = line.partition("=")
                        result[k.strip()] = v.strip()
                return result
        return {}

    def _generate_mcp_configs(
        self,
        *,
        mcp_source: Path,
        repo_root: Path,
        vscode_user_config: Path,
        vscode_project_config: Path,
        copilot_cli_mcp: Path,
        clear_mcp: bool,
    ) -> Tuple[bool, str]:
        """Generate MCP configs for all CLIs from servers.json.

        Returns (success, message).
        """
        env_vars = self._load_env_file()
        perplexity_key = env_vars.get("PERPLEXITY_API_KEY", "")
        perplexity_model = env_vars.get("PERPLEXITY_MODEL", "sonar")
        openrouter_key = env_vars.get("MCP_LLM_OPENROUTER_API_KEY", "")

        # Check perplexity requirement
        servers_text = mcp_source.read_text(encoding="utf-8")
        if '"perplexity"' in servers_text and '"enabled": true' in servers_text:
            if not perplexity_key or perplexity_key == "your_perplexity_api_key_here":
                env_file = self.home / ".jk-tools.env"
                if not env_file.exists():
                    env_file.write_text(
                        "# Perplexity MCP Server Configuration\n"
                        "PERPLEXITY_API_KEY=your_perplexity_api_key_here\n\n"
                        "# MCP Browser Use Configuration (optional)\n"
                        "# MCP_LLM_OPENROUTER_API_KEY=your_key_here\n",
                        encoding="utf-8",
                    )
                return False, (
                    f"Perplexity MCP server is enabled but PERPLEXITY_API_KEY is not set.\n"
                    f"Edit {env_file} and add your API key, or disable Perplexity in servers.json."
                )

        # Substitute env vars
        if openrouter_key:
            servers_text = servers_text.replace("${OPENROUTER_API_KEY}", openrouter_key)
        if perplexity_key:
            servers_text = servers_text.replace("${PERPLEXITY_API_KEY}", perplexity_key)
        if perplexity_model:
            servers_text = servers_text.replace("${PERPLEXITY_MODEL}", perplexity_model)

        servers = json.loads(servers_text)

        # Config file paths
        opencode_global_path = self.home / ".config" / "opencode" / "opencode.json"
        opencode_project_path = repo_root / "opencode.json"
        claude_global_path = self.home / ".claude.json"
        codex_global_path = self.home / ".codex" / "config.toml"

        # Ensure parent dirs
        for p in [opencode_global_path, codex_global_path, vscode_user_config,
                  vscode_project_config, copilot_cli_mcp]:
            p.parent.mkdir(parents=True, exist_ok=True)

        # Load existing configs
        opencode_global = self._migrate_opencode(self._load_json(opencode_global_path))
        opencode_project = self._migrate_opencode(self._load_json(opencode_project_path))
        claude_cfg = self._load_json(claude_global_path)
        codex_cfg = self._load_toml(codex_global_path)
        vscode_user = self._load_json(vscode_user_config)
        vscode_project = self._load_json(vscode_project_config)
        copilot_cli_cfg = self._load_json(copilot_cli_mcp)

        # Clear if requested
        if clear_mcp:
            opencode_global.pop("mcp", None)
            opencode_project.pop("mcp", None)
            claude_cfg.pop("mcpServers", None)
            codex_cfg.pop("mcp_servers", None)
            vscode_user.pop("mcpServers", None)
            vscode_project.pop("mcpServers", None)
            copilot_cli_cfg.pop("mcpServers", None)

        # Get/create sections
        oc_g_mcp = opencode_global.setdefault("mcp", {})
        oc_p_mcp = opencode_project.setdefault("mcp", {})
        claude_servers = claude_cfg.setdefault("mcpServers", {})
        codex_servers = codex_cfg.setdefault("mcp_servers", {})
        vs_u_servers = vscode_user.setdefault("mcpServers", {})
        vs_p_servers = vscode_project.setdefault("mcpServers", {})
        cop_servers = copilot_cli_cfg.setdefault("mcpServers", {})

        for name, config in servers.items():
            if not isinstance(config, dict):
                continue
            if name.startswith("_") or not config.get("enabled", True):
                continue

            server_type = self._normalize_type(config.get("type")) or "local"
            enabled = bool(config.get("enabled", True))
            environment = config.get("environment") or config.get("env") or {}
            command_list = self._merge_cmd_args(config.get("command"), config.get("args"))
            url = config.get("url")
            headers = config.get("headers")

            # OpenCode
            oc_entry: Dict = {"type": server_type, "enabled": enabled}
            if server_type == "remote" and url:
                oc_entry["url"] = url
                if headers:
                    oc_entry["headers"] = headers
            elif command_list:
                oc_entry["command"] = command_list
            if environment:
                oc_entry["environment"] = environment
            oc_g_mcp[name] = dict(oc_entry)
            oc_p_mcp[name] = dict(oc_entry)

            # Claude
            claude_servers[name] = {
                "type": "stdio",
                "command": config.get("command"),
                "args": config.get("args", []),
                "env": environment if isinstance(environment, dict) else {},
            }

            # Codex
            codex_server: Dict = {"command": config.get("command"), "args": config.get("args", [])}
            if environment and isinstance(environment, dict):
                codex_server["env"] = environment
            if server_type == "remote":
                if url:
                    codex_server["url"] = url
                if headers:
                    codex_server["headers"] = headers
            codex_servers[name] = codex_server

            # VS Code
            vs_entry: Dict = {
                "command": config.get("command"),
                "args": config.get("args", []),
                "enabled": enabled,
            }
            if environment and isinstance(environment, dict):
                vs_entry["env"] = environment
            if server_type == "remote":
                if url:
                    vs_entry["url"] = url
                if headers:
                    vs_entry["headers"] = headers
            vs_u_servers[name] = dict(vs_entry)
            vs_p_servers[name] = dict(vs_entry)

            # Copilot CLI
            cop_servers[name] = {
                "type": "local",
                "command": config.get("command"),
                "args": config.get("args", []),
                "tools": ["*"],
                **({"env": environment} if environment and isinstance(environment, dict) else {}),
            }

        # Backup and write
        all_json = [
            (opencode_global_path, opencode_global),
            (opencode_project_path, opencode_project),
            (claude_global_path, claude_cfg),
            (vscode_user_config, vscode_user),
            (vscode_project_config, vscode_project),
            (copilot_cli_mcp, copilot_cli_cfg),
        ]
        for path, data in all_json:
            self._backup(path)
            self._write_json(path, data)

        self._backup(codex_global_path)
        self._write_toml(codex_global_path, codex_cfg)

        return True, "MCP configuration updated"

    def _install_local_commands(
        self, cli_list: str, target_dir: str, v2_source: Path,
    ) -> Tuple[bool, str, str, str]:
        """Install commands to a local project directory."""
        if not v2_source.is_dir():
            return False, f"Source not found: {v2_source}", "", ""
        md_files = sorted(v2_source.glob("*.md"))
        if not md_files:
            return False, "No .md files found", "", ""

        output_lines: List[str] = []
        target = Path(target_dir)
        skip = {"README.md", "GETTING-STARTED.md"}

        if "claude" in cli_list:
            d = target / ".claude" / "commands"
            d.mkdir(parents=True, exist_ok=True)
            for md in md_files:
                shutil.copy2(md, d / md.name)
            output_lines.append(f"Claude: {len(md_files)} files → {d}")

        if "opencode" in cli_list:
            d = target / ".opencode" / "command"
            d.mkdir(parents=True, exist_ok=True)
            for md in md_files:
                shutil.copy2(md, d / md.name)
            output_lines.append(f"OpenCode: {len(md_files)} files → {d}")

        if "ghcp" in cli_list:
            d = target / ".github" / "prompts"
            d.mkdir(parents=True, exist_ok=True)
            for md in md_files:
                prompt = md.stem + ".prompt.md"
                shutil.copy2(md, d / prompt)
            output_lines.append(f"GitHub Copilot: {len(md_files)} prompts → {d}")

        if "copilot-cli" in cli_list:
            d = target / ".github" / "agents"
            d.mkdir(parents=True, exist_ok=True)
            count = 0
            for md in md_files:
                if md.name in skip:
                    continue
                self._generate_agent_md(md, d)
                count += 1
            output_lines.append(f"Copilot CLI: {count} agents → {d}")

        if "codex" in cli_list:
            output_lines.append("Codex: local commands not supported (global only)")

        return True, "Local commands installed", "\n".join(output_lines), ""

    # ------------------------------------------------------------------
    # JSON / TOML helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _load_json(path: Path) -> dict:
        if path.exists():
            try:
                return json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                backup = path.with_suffix(path.suffix + ".bak")
                path.rename(backup)
        return {}

    @staticmethod
    def _write_json(path: Path, data: dict) -> None:
        path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

    @staticmethod
    def _load_toml(path: Path) -> dict:
        if _load_toml and path.exists():
            try:
                return _load_toml(path.read_text(encoding="utf-8"))
            except Exception:
                backup = path.with_suffix(path.suffix + ".bak")
                path.rename(backup)
        return {}

    @staticmethod
    def _write_toml(path: Path, data: dict) -> None:
        if _dump_toml:
            path.write_text(_dump_toml(data), encoding="utf-8")

    @staticmethod
    def _backup(path: Path) -> None:
        if path.exists():
            ts = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
            shutil.copy2(path, path.with_suffix(f"{path.suffix}.backup-{ts}"))

    @staticmethod
    def _normalize_type(value) -> Optional[str]:
        mapping = {"stdio": "local", "sse": "remote"}
        if isinstance(value, str):
            return mapping.get(value, value)
        return None

    @staticmethod
    def _merge_cmd_args(command, args) -> list:
        cmd_list = [command] if isinstance(command, str) else (list(command) if command else [])
        if isinstance(args, (list, tuple)):
            cmd_list.extend(str(a) for a in args)
        elif isinstance(args, str):
            cmd_list.append(args)
        return cmd_list

    @staticmethod
    def _migrate_opencode(data: dict) -> dict:
        if not isinstance(data, dict):
            data = {}
        data.setdefault("$schema", "https://opencode.ai/config.json")
        mcp = data.setdefault("mcp", {})
        legacy = data.pop("mcpServers", {})
        if isinstance(legacy, dict):
            for name, entry in legacy.items():
                if not isinstance(entry, dict):
                    continue
                new: Dict = {"type": ToolInstaller._normalize_type(entry.get("type")) or "local"}
                env = entry.get("environment") or entry.get("env")
                if env:
                    new["environment"] = env
                if new["type"] == "remote":
                    if entry.get("url"):
                        new["url"] = entry["url"]
                else:
                    cmd = ToolInstaller._merge_cmd_args(entry.get("command"), entry.get("args"))
                    if cmd:
                        new["command"] = cmd
                mcp.setdefault(name, {}).update(new)
        return data
