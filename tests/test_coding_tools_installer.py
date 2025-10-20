"""
Unit tests for CodingToolsInstaller

Tests the foundation methods:
- System detection
- Version comparison
- Command checking
- Environment filtering
"""

import unittest
from unittest.mock import patch, MagicMock
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from install.coding_tools_installer import CodingToolsInstaller
from rich.console import Console


class TestSystemDetection(unittest.TestCase):
    """Test system detection methods"""

    def setUp(self):
        self.console = Console()
        self.installer = CodingToolsInstaller(console=self.console)

    @patch('platform.system')
    def test_detect_os_linux(self, mock_system):
        """Test Linux detection"""
        mock_system.return_value = "Linux"
        installer = CodingToolsInstaller(console=self.console)
        self.assertEqual(installer.os_type, "Linux")

    @patch('platform.system')
    def test_detect_os_macos(self, mock_system):
        """Test macOS detection"""
        mock_system.return_value = "Darwin"
        installer = CodingToolsInstaller(console=self.console)
        self.assertEqual(installer.os_type, "macOS")

    @patch('platform.system')
    def test_detect_os_windows(self, mock_system):
        """Test Windows detection"""
        mock_system.return_value = "Windows"
        installer = CodingToolsInstaller(console=self.console)
        self.assertEqual(installer.os_type, "Windows")

    @patch('platform.system')
    def test_detect_os_unknown(self, mock_system):
        """Test unknown OS detection"""
        mock_system.return_value = "FreeBSD"
        installer = CodingToolsInstaller(console=self.console)
        self.assertEqual(installer.os_type, "Unknown")

    def test_check_command_exists(self):
        """Test command existence checking with real commands"""
        # python3 should exist on all test systems
        self.assertTrue(self.installer._check_command("python3"))

        # This command should not exist
        self.assertFalse(self.installer._check_command("nonexistent-command-xyz-123"))


class TestVersionUtilities(unittest.TestCase):
    """Test version parsing and comparison"""

    def setUp(self):
        self.console = Console()
        self.installer = CodingToolsInstaller(console=self.console)

    def test_version_gte_greater(self):
        """Test version comparison: greater"""
        self.assertTrue(self.installer._version_gte("20.0.0", "18.0.0"))
        self.assertTrue(self.installer._version_gte("2.0.0", "1.9.9"))
        self.assertTrue(self.installer._version_gte("1.0.1", "1.0.0"))

    def test_version_gte_equal(self):
        """Test version comparison: equal"""
        self.assertTrue(self.installer._version_gte("20.0.0", "20.0.0"))
        self.assertTrue(self.installer._version_gte("1.2.3", "1.2.3"))

    def test_version_gte_less(self):
        """Test version comparison: less"""
        self.assertFalse(self.installer._version_gte("18.0.0", "20.0.0"))
        self.assertFalse(self.installer._version_gte("1.9.9", "2.0.0"))
        self.assertFalse(self.installer._version_gte("1.0.0", "1.0.1"))

    def test_version_gte_semantic(self):
        """Test version comparison with semantic versioning"""
        self.assertTrue(self.installer._version_gte("2.0.0-beta", "1.9.9"))
        self.assertTrue(self.installer._version_gte("1.0.0+build.1", "1.0.0"))


class TestEnvironmentCleaning(unittest.TestCase):
    """Test clean environment generation"""

    def setUp(self):
        self.console = Console()
        self.installer = CodingToolsInstaller(console=self.console)

    def test_clean_env_removes_bash_env(self):
        """Test that BASH_ENV is removed from environment"""
        with patch.dict('os.environ', {'BASH_ENV': '/tmp/evil.sh', 'PATH': '/usr/bin'}):
            clean_env = self.installer._get_clean_env()
            self.assertNotIn('BASH_ENV', clean_env)
            self.assertIn('PATH', clean_env)

    def test_clean_env_removes_env(self):
        """Test that ENV is removed from environment"""
        with patch.dict('os.environ', {'ENV': '/tmp/evil.sh', 'PATH': '/usr/bin'}):
            clean_env = self.installer._get_clean_env()
            self.assertNotIn('ENV', clean_env)

    def test_clean_env_removes_bash_functions(self):
        """Test that BASH_FUNC_* variables are removed"""
        with patch.dict('os.environ', {
            'BASH_FUNC_foo': '() { echo bar; }',
            'BASH_FUNC_baz%%': '() { echo qux; }',
            'PATH': '/usr/bin'
        }):
            clean_env = self.installer._get_clean_env()
            # Check no BASH_FUNC_ variables remain
            bash_func_vars = [k for k in clean_env.keys() if k.startswith('BASH_FUNC_')]
            self.assertEqual(len(bash_func_vars), 0)

    def test_clean_env_removes_cdpath(self):
        """Test that CDPATH is removed"""
        with patch.dict('os.environ', {'CDPATH': '/tmp:/home', 'PATH': '/usr/bin'}):
            clean_env = self.installer._get_clean_env()
            self.assertNotIn('CDPATH', clean_env)

    def test_clean_env_preserves_safe_vars(self):
        """Test that safe variables are preserved"""
        with patch.dict('os.environ', {
            'PATH': '/usr/bin',
            'HOME': '/home/user',
            'USER': 'testuser',
            'BASH_ENV': '/tmp/evil.sh'  # Should be removed
        }):
            clean_env = self.installer._get_clean_env()
            self.assertIn('PATH', clean_env)
            self.assertIn('HOME', clean_env)
            self.assertIn('USER', clean_env)
            self.assertNotIn('BASH_ENV', clean_env)


class TestCommandExecution(unittest.TestCase):
    """Test subprocess execution methods"""

    def setUp(self):
        self.console = Console()
        self.installer = CodingToolsInstaller(console=self.console)

    def test_run_command_success(self):
        """Test successful command execution"""
        returncode, stdout, stderr = self.installer._run_command(
            ["echo", "hello world"],
            timeout=5
        )
        self.assertEqual(returncode, 0)
        self.assertEqual(stdout.strip(), "hello world")

    def test_run_command_failure(self):
        """Test failed command execution"""
        returncode, stdout, stderr = self.installer._run_command(
            ["ls", "/nonexistent-directory-xyz-123"],
            timeout=5
        )
        self.assertNotEqual(returncode, 0)
        self.assertIn("No such file or directory", stderr)

    def test_run_shell_script_success(self):
        """Test successful shell script execution"""
        script = """
#!/bin/bash
echo "Script executed"
exit 0
"""
        returncode, stdout, stderr = self.installer._run_shell_script(script, timeout=5)
        self.assertEqual(returncode, 0)
        self.assertIn("Script executed", stdout)

    def test_run_shell_script_failure(self):
        """Test failed shell script execution"""
        script = """
#!/bin/bash
echo "Script failed" >&2
exit 1
"""
        returncode, stdout, stderr = self.installer._run_shell_script(script, timeout=5)
        self.assertEqual(returncode, 1)
        self.assertIn("Script failed", stderr)


if __name__ == '__main__':
    unittest.main()
