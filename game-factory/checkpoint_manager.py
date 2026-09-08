#!/usr/bin/env python3
"""Auto-Checkpoint Manager — Saves pipeline state every 5 minutes to Oxen.ai.

If GitHub Actions fails mid-run, pipeline resumes from last checkpoint.
Maximum 5 minutes of progress lost on failure.
"""
import json
import os
import shutil
import threading
import time
from pathlib import Path
from datetime import datetime, timezone


class CheckpointManager:
    """Manages auto-checkpoints during pipeline execution."""
    
    def __init__(self, project_id, run_id, storage=None):
        self.project_id = project_id
        self.run_id = run_id
        self.storage = storage
        self.checkpoint_number = 0
        self.last_checkpoint_time = 0
        self._auto_checkpoint_thread = None
        self._auto_checkpoint_running = False
        self._get_state_callback = None
    
    def start_auto_checkpoint(self, interval, get_state, workspace_dir):
        """Start auto-checkpoint thread that runs every `interval` seconds."""
        self._get_state_callback = get_state
        self._auto_checkpoint_running = True
        self._auto_checkpoint_thread = threading.Thread(
            target=self._auto_checkpoint_loop,
            args=(interval, workspace_dir),
            daemon=True,
        )
        self._auto_checkpoint_thread.start()
        print(f"[CHECKPOINT] Auto-checkpoint started (every {interval}s)")
    
    def stop_auto_checkpoint(self):
        """Stop auto-checkpoint thread."""
        self._auto_checkpoint_running = False
        if self._auto_checkpoint_thread:
            self._auto_checkpoint_thread.join(timeout=5)
        print("[CHECKPOINT] Auto-checkpoint stopped")
    
    def _auto_checkpoint_loop(self, interval, workspace_dir):
        """Background loop that creates checkpoints periodically."""
        while self._auto_checkpoint_running:
            time.sleep(interval)
            if not self._auto_checkpoint_running:
                break
            try:
                state = self._get_state_callback() if self._get_state_callback else {}
                self.create_checkpoint(
                    workspace_dir=workspace_dir,
                    current_step=state.get("current_step", "unknown"),
                    step_progress=state.get("step_progress", 0),
                )
            except Exception as e:
                print(f"[CHECKPOINT] Error: {e}")
    
    def create_checkpoint(self, workspace_dir, current_step, step_progress):
        """Create a checkpoint of current pipeline state."""
        self.checkpoint_number += 1
        checkpoint_name = f"checkpoint-{self.checkpoint_number:03d}"
        checkpoint_dir = Path(f"/scratch/work/checkpoints/{checkpoint_name}")
        checkpoint_dir.mkdir(parents=True, exist_ok=True)
        
        workspace = Path(workspace_dir)
        if workspace.exists():
            for item in workspace.rglob("*"):
                if item.is_file():
                    rel = item.relative_to(workspace)
                    dest = checkpoint_dir / rel
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(item, dest)
        
        state = {
            "project_id": self.project_id,
            "run_id": self.run_id,
            "checkpoint_number": self.checkpoint_number,
            "current_step": current_step,
            "step_progress": step_progress,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        (checkpoint_dir / "state.json").write_text(json.dumps(state, indent=2))
        
        if self.storage:
            try:
                self.storage.upload_checkpoint(checkpoint_dir, self.project_id, checkpoint_name)
            except Exception as e:
                print(f"[CHECKPOINT] Upload failed (will keep local): {e}")
        
        self._cleanup_old_checkpoints()
        self.last_checkpoint_time = time.time()
        print(f"[CHECKPOINT] #{self.checkpoint_number} created at {current_step} ({step_progress:.0f}%)")
        return self.checkpoint_number
    
    def restore(self, checkpoint_number, bible_path=None):
        """Restore pipeline from a specific checkpoint."""
        checkpoint_name = f"checkpoint-{checkpoint_number:03d}"
        
        if self.storage:
            try:
                self.storage.download_checkpoint(self.project_id, checkpoint_name, "/scratch/work/checkpoints/")
            except:
                pass
        
        checkpoint_dir = Path(f"/scratch/work/checkpoints/{checkpoint_name}")
        if not checkpoint_dir.exists():
            print(f"[CHECKPOINT] Checkpoint {checkpoint_number} not found!")
            return None
        
        state = json.loads((checkpoint_dir / "state.json").read_text())
        
        workspace = Path("output")
        workspace.mkdir(exist_ok=True)
        for item in checkpoint_dir.rglob("*"):
            if item.is_file() and item.name != "state.json":
                rel = item.relative_to(checkpoint_dir)
                dest = workspace / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(item, dest)
        
        print(f"[CHECKPOINT] Restored from #{checkpoint_number}: {state['current_step']} ({state['step_progress']:.0f}%)")
        return state
    
    def _cleanup_old_checkpoints(self):
        """Keep only the latest 2 checkpoints locally."""
        checkpoints_dir = Path("/scratch/work/checkpoints")
        if not checkpoints_dir.exists():
            return
        checkpoints = sorted(checkpoints_dir.glob("checkpoint-*"))
        if len(checkpoints) > 2:
            for old in checkpoints[:-2]:
                shutil.rmtree(old)
                print(f"[CHECKPOINT] Cleaned up {old.name}")
    
    def get_latest_checkpoint_number(self):
        return self.checkpoint_number


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["restore"])
    parser.add_argument("--checkpoint", type=int, required=True)
    parser.add_argument("--bible", default="")
    args = parser.parse_args()
    
    if args.command == "restore":
        manager = CheckpointManager("unknown", "manual", None)
        state = manager.restore(args.checkpoint, args.bible)
        if state:
            print(json.dumps(state, indent=2))
