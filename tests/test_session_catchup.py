import sys
import os
import json
import unittest
import tempfile
import shutil
from pathlib import Path
from datetime import datetime

# Add the script directory to sys.path to allow importing
SCRIPT_DIR = Path(__file__).parent.parent / ".claude" / "skills" / "planning-with-files" / "scripts"
sys.path.append(str(SCRIPT_DIR))

# Import the module to be tested
import importlib.util

spec = importlib.util.spec_from_file_location("session_catchup", SCRIPT_DIR / "session-catchup.py")
session_catchup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(session_catchup)

class TestSessionCatchup(unittest.TestCase):

    def setUp(self):
        """Create a temporary directory for testing."""
        self.test_dir = tempfile.mkdtemp()
        self.mock_project_dir = Path(self.test_dir) / ".claude" / "projects" / "test-project"
        self.mock_project_dir.mkdir(parents=True)

    def tearDown(self):
        """Clean up the temporary directory."""
        shutil.rmtree(self.test_dir)

    def create_session_file(self, messages, timestamp=None):
        """Helper to create a session file with JSONL content."""
        if timestamp is None:
            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        
        file_path = self.mock_project_dir / f"{timestamp}.jsonl"
        with open(file_path, "w") as f:
            for msg in messages:
                f.write(json.dumps(msg) + "\n")
        return file_path

    def test_find_last_planning_update(self):
        """Test finding the last update to planning files."""
        messages = [
            {"type": "user", "message": {"content": "Hello"}, "_line_num": 0},
            {"type": "assistant", "message": {"content": [
                {"type": "tool_use", "name": "Write", "input": {"file_path": "/path/to/task_plan.md"}}
            ]}, "_line_num": 1},
            {"type": "user", "message": {"content": "Next step"}, "_line_num": 2}
        ]
        
        line, file = session_catchup.find_last_planning_update(messages)
        self.assertEqual(line, 1)
        self.assertEqual(file, "task_plan.md")

    def test_find_last_planning_update_none(self):
        """Test when no planning file is updated."""
        messages = [
            {"type": "user", "message": {"content": "Hello"}, "_line_num": 0},
            {"type": "assistant", "message": {"content": "Hi there"}, "_line_num": 1}
        ]
        
        line, file = session_catchup.find_last_planning_update(messages)
        self.assertEqual(line, -1)
        self.assertIsNone(file)

    def test_extract_messages_after(self):
        """Test extracting messages after a certain line."""
        messages = [
            {"type": "user", "message": {"content": [{"type": "text", "text": "Before this message is long enough"}]}, "_line_num": 0, "role": "user"},
            {"type": "assistant", "message": {"content": "Update"}, "_line_num": 1, "role": "assistant"},
            {"type": "user", "message": {"content": [{"type": "text", "text": "After 1 - this message needs to be longer than 20 chars"}]}, "_line_num": 2, "role": "user"},
            {"type": "assistant", "message": {"content": "Response 1"}, "_line_num": 3, "role": "assistant"}
        ]
        
        # Extract after line 1
        result = session_catchup.extract_messages_after(messages, 1)
        
        self.assertEqual(len(result), 2)
        self.assertIn("After 1", result[0]["content"])
        self.assertEqual(result[1]["content"], "Response 1")

    def test_extract_messages_after_with_tools(self):
        """Test extracting messages that contain tool use."""
        messages = [
            {"type": "user", "message": {"content": [{"type": "text", "text": "Do something that is definitely longer than twenty characters to pass the filter"}]}, "_line_num": 0},
            {"type": "assistant", "message": {"content": [
                {"type": "text", "text": "I will run a command."},
                {"type": "tool_use", "name": "Bash", "input": {"command": "ls -la"}}
            ]}, "_line_num": 1}
        ]
        
        # Extract all (after line -1)
        result = session_catchup.extract_messages_after(messages, -1)
        
        self.assertEqual(len(result), 2)
        self.assertIn("Bash: ls -la", result[1]["tools"])

    def test_get_sessions_sorted(self):
        """Test session file sorting."""
        # Create files with different mtimes
        file1 = self.create_session_file([], "2023-01-01_10-00-00")
        file2 = self.create_session_file([], "2023-01-02_10-00-00")
        
        # Ensure file2 is newer
        os.utime(file1, (10000, 10000))
        os.utime(file2, (20000, 20000))
        
        sessions = session_catchup.get_sessions_sorted(self.mock_project_dir)
        self.assertEqual(len(sessions), 2)
        self.assertEqual(sessions[0].name, file2.name)

if __name__ == '__main__':
    unittest.main()
