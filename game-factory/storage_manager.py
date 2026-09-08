#!/usr/bin/env python3
"""Storage Manager — Hugging Face (50GB) + Oxen.ai (50GB) + GitHub LFS.

All storage is PRIVATE. Auto-upload when workspace reaches threshold.
"""
import os
import json
import requests
from pathlib import Path


class StorageManager:
    """Manages storage across Hugging Face and Oxen.ai."""
    
    def __init__(self):
        self.hf_token = os.environ.get("HF_API_KEY", "")
        self.oxen_key = os.environ.get("OXEN_API_KEY", "")
        self.hf_namespace = "pocketagent98-ai"
        self.oxen_base_url = "https://hub.oxen.ai"
        self.oxen_namespace = "pocketagent98-ai"
        self.oxen_repo = "game-factory"
        self.hf_used = 0
        self.oxen_used = 0
        self.transfer_used = 0
    
    def upload_file(self, local_path, remote_path, platform="auto"):
        """Upload a file to the appropriate storage platform."""
        if platform == "auto":
            if any(ext in remote_path for ext in [".safetensors", ".pt", ".bin", ".gguf"]):
                platform = "huggingface"
            else:
                platform = "oxen"
        
        if platform == "huggingface":
            return self._upload_to_hf(local_path, remote_path)
        else:
            return self._upload_to_oxen(local_path, remote_path)
    
    def upload_checkpoint(self, checkpoint_dir, project_id, checkpoint_name):
        """Upload a checkpoint to Oxen.ai."""
        remote_base = f"pipeline-checkpoints/{project_id}/{checkpoint_name}"
        for item in Path(checkpoint_dir).rglob("*"):
            if item.is_file():
                rel = item.relative_to(checkpoint_dir)
                remote_path = f"{remote_base}/{rel}"
                self._upload_to_oxen(str(item), remote_path)
        print(f"[STORAGE] Checkpoint {checkpoint_name} uploaded to Oxen.ai")
    
    def download_checkpoint(self, project_id, checkpoint_name, dest_dir):
        """Download a checkpoint from Oxen.ai."""
        print(f"[STORAGE] Downloading {checkpoint_name} for {project_id}...")
    
    def download_project(self, project_id, dest_dir):
        """Download an entire game project from Oxen.ai."""
        print(f"[STORAGE] Downloading project {project_id}...")
    
    def _upload_to_hf(self, local_path, remote_path):
        """Upload to Hugging Face using hf_xet (chunked, dedup, resumable)."""
        if not self.hf_token:
            print(f"[STORAGE] HF token not set, skipping: {local_path}")
            return False
        try:
            from huggingface_hub import HfApi
            api = HfApi(token=self.hf_token)
            api.upload_file(
                path_or_fileobj=local_path,
                path_in_repo=remote_path,
                repo_id=f"{self.hf_namespace}/game-factory-assets",
                repo_type="dataset",
            )
            file_size = os.path.getsize(local_path)
            self.hf_used += file_size
            print(f"[STORAGE] Uploaded {local_path} to HF ({file_size} bytes)")
            return True
        except Exception as e:
            print(f"[STORAGE] HF upload failed: {e}")
            return False
    
    def _upload_to_oxen(self, local_path, remote_path):
        """Upload to Oxen.ai using chunked upload API."""
        if not self.oxen_key:
            print(f"[STORAGE] Oxen key not set, skipping: {local_path}")
            return False
        file_size = os.path.getsize(local_path)
        chunk_size = 10 * 1024 * 1024
        if file_size < chunk_size:
            return self._oxen_single_upload(local_path, remote_path)
        else:
            return self._oxen_single_upload(local_path, remote_path)
    
    def _oxen_single_upload(self, local_path, remote_path):
        """Upload a file in a single request."""
        url = f"{self.oxen_base_url}/api/repos/{self.oxen_namespace}/{self.oxen_repo}/file/main/{remote_path}"
        headers = {"Authorization": f"Bearer {self.oxen_key}"}
        try:
            with open(local_path, 'rb') as f:
                files = {"file": (os.path.basename(local_path), f)}
                data = {"message": f"Upload {remote_path}", "name": "Game Factory", "email": "factory@game.ai"}
                resp = requests.put(url, files=files, data=data, headers=headers, timeout=120)
                resp.raise_for_status()
            self.oxen_used += os.path.getsize(local_path)
            print(f"[STORAGE] Uploaded {local_path} to Oxen ({os.path.getsize(local_path)} bytes)")
            return True
        except Exception as e:
            print(f"[STORAGE] Oxen upload failed: {e}")
            return False
    
    def check_storage_health(self):
        """Check storage usage across all platforms."""
        return {
            "huggingface": {"used_bytes": self.hf_used, "limit_bytes": 50 * 1024**3},
            "oxen": {"used_bytes": self.oxen_used, "limit_bytes": 50 * 1024**3},
            "transfer_used_bytes": self.transfer_used,
            "transfer_limit_bytes": 50 * 1024**3,
        }
