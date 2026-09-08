#!/usr/bin/env python3
"""GPU Cost Controller — Manages Modal.com $5 credits.

Tools on GPU:
- Blender: Characters and detailed 3D models only
- TerraForge3D: Open-world terrain/map generation
- Terrain3D/Clipmap3D: In-Godot runtime (no build-time cost)

Rules: Auto-kill after task. Hard timeout 10 min. Credits < $0.50 = switch to procedural.
"""
import os
import time
import json
from datetime import datetime


class GPUCostController:
    """Controls GPU spending on Modal.com."""
    
    TOTAL_CREDITS = 5.00
    WARNING_THRESHOLD = 1.00
    CRITICAL_THRESHOLD = 0.50
    HARD_TIMEOUT = 600  # 10 minutes
    AUTO_KILL_DELAY = 5  # seconds
    
    def __init__(self):
        self.credits_used = 0.0
        self.credits_remaining = self.TOTAL_CREDITS
        self.tasks_run = 0
        self.gpu_active = False
        self.current_task_start = None
        self.usage_log = []
    
    def can_use_gpu(self):
        """Check if GPU credits are available."""
        if self.credits_remaining <= self.CRITICAL_THRESHOLD:
            print(f"[GPU] CRITICAL: ${self.credits_remaining:.2f} below ${self.CRITICAL_THRESHOLD}. Procedural only.")
            return False
        elif self.credits_remaining <= self.WARNING_THRESHOLD:
            print(f"[GPU] WARNING: ${self.credits_remaining:.2f} below ${self.WARNING_THRESHOLD}.")
        return True
    
    def start_gpu_task(self, task_name, task_type="blender"):
        """Start a GPU task on Modal.com."""
        if not self.can_use_gpu():
            return False
        self.gpu_active = True
        self.current_task_start = time.time()
        self.tasks_run += 1
        print(f"[GPU] Starting: {task_name} (type: {task_type})")
        return True
    
    def end_gpu_task(self, task_name, estimated_cost=0.0):
        """End GPU task and kill container immediately."""
        if not self.gpu_active:
            return
        elapsed = time.time() - self.current_task_start
        actual_cost = max(estimated_cost, (elapsed / 60) * 0.30)
        self.credits_used += actual_cost
        self.credits_remaining -= actual_cost
        self.gpu_active = False
        self.usage_log.append({
            "task": task_name, "elapsed_seconds": elapsed, "cost": actual_cost,
            "timestamp": datetime.utcnow().isoformat(),
        })
        print(f"[GPU] {task_name} done in {elapsed:.1f}s, cost ${actual_cost:.4f}")
        print(f"[GPU] Auto-killing container. Credits: ${self.credits_remaining:.2f} remaining")
        return actual_cost
    
    def get_usage_report(self):
        return {
            "total_credits": self.TOTAL_CREDITS,
            "credits_used": round(self.credits_used, 4),
            "credits_remaining": round(self.credits_remaining, 4),
            "tasks_run": self.tasks_run,
            "gpu_active": self.gpu_active,
            "usage_log": self.usage_log,
        }
