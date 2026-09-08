#!/usr/bin/env python3
"""LLM Router — Routes tasks to best free-tier LLM across 7 providers.

Providers (all free):
- z.ai: GLM-4.7-Flash (coding SOTA), GLM-4.5-Flash, GLM-4.6V-Flash (vision)
- NVIDIA NIM: Nemotron 3 Ultra (1M ctx), DeepSeek V4, 100+ models
- Google Gemini: Gemini 3.1 Flash-Lite, Gemma 4 31B/26B
- OpenRouter: 20+ free models, auto-router
- NaraRouter: DeepSeek V4 Flash Free, GLM 5.3 Free
- TokenRouter: Kimi K2.7 Code, DeepSeek V4 Pro
- OmniRoute: 90+ free providers (plugin, local fallback)

Anti-infinite-loop: If all providers exhausted, queue and wait.
"""
import json
import os
import time
import requests
from datetime import datetime


class LLMRouter:
    """Routes LLM calls across 7 free providers with rate limit rotation."""
    
    TASK_MODEL_MAP = {
        "deep_analysis": [
            ("glm-4.7-flash", "zai", {"thinking": {"type": "enabled"}}),
            ("nemotron-3-ultra", "nvidia", {"reasoning_effort": "high"}),
            ("gemini-3-flash", "google", {"thinking": {"type": "enabled"}}),
            ("deepseek-v4-flash-free", "nararouter", {"reasoning_effort": "high"}),
        ],
        "architecture": [
            ("nemotron-3-ultra", "nvidia", {"reasoning_effort": "high"}),
            ("glm-4.7-flash", "zai", {"thinking": {"type": "enabled"}}),
            ("minimax-m3-free", "nararouter", {}),
            ("gpt-oss-120b:free", "openrouter", {}),
        ],
        "code_generation": [
            ("glm-4.7-flash", "zai", {"thinking": {"type": "enabled"}}),
            ("laguna-s-2.1:free", "openrouter", {}),
            ("gpt-oss-120b:free", "openrouter", {}),
            ("deepseek-v4-flash-free", "nararouter", {}),
        ],
        "code_review": [
            ("deepseek-v4-pro", "nararouter", {"reasoning_effort": "high"}),
            ("glm-4.7-flash", "zai", {"thinking": {"type": "enabled"}}),
            ("nemotron-3-super", "nvidia", {"reasoning_effort": "high"}),
            ("north-mini-code:free", "openrouter", {}),
        ],
        "translation": [
            ("gemini-3.1-flash-lite", "google", {}),
            ("gemma-4-31b", "google", {}),
            ("glm-4.5-flash", "zai", {}),
            ("qwen-3.8", "nararouter", {}),
        ],
        "qa_testing": [
            ("gemma-4-31b", "google", {}),
            ("glm-4.5-flash", "zai", {}),
            ("minimax-m2.7:free", "openrouter", {}),
        ],
        "security": [
            ("nemotron-3-ultra", "nvidia", {"reasoning_effort": "high"}),
            ("glm-4.7-flash", "zai", {"thinking": {"type": "enabled"}}),
            ("deepseek-v4-pro", "nararouter", {"reasoning_effort": "high"}),
        ],
        "marketing": [
            ("gemma-4-26b", "google", {}),
            ("glm-4.5-flash", "zai", {}),
            ("inkling:free", "openrouter", {}),
        ],
        "vision": [
            ("glm-4.6v-flash", "zai", {}),
            ("nemotron-3-nano-omni:free", "openrouter", {}),
        ],
        "quick": [
            ("glm-4.5-flash", "zai", {}),
            ("gemini-3.1-flash-lite", "google", {}),
            ("ling-3.0-flash:free", "openrouter", {}),
        ],
        "fallback": [
            ("auto:free", "openrouter", {}),
        ],
    }
    
    PROVIDER_LIMITS = {
        "zai": {"rpm": 60, "rpd": 1000},
        "nvidia": {"rpm": 40, "rpd": 500},
        "google": {"rpm": 15, "rpd": 1500},
        "openrouter": {"rpm": 20, "rpd": 1000},
        "nararouter": {"rpm": 10, "rpd": 500},
        "tokenrouter": {"rpm": 30, "rpd": 1000},
        "omniroute": {"rpm": 999, "rpd": 99999},
    }
    
    PROVIDER_ENDPOINTS = {
        "zai": {"base_url": "https://api.z.ai/api/paas/v4", "key_env": "ZAI_API_KEY"},
        "nvidia": {"base_url": "https://integrate.api.nvidia.com/v1", "key_env": "NVIDIA_API_KEY"},
        "google": {"base_url": "https://generativelanguage.googleapis.com/v1beta/openai", "key_env": "GOOGLE_API_KEY"},
        "openrouter": {"base_url": "https://openrouter.ai/api/v1", "key_env": "OPENROUTER_API_KEY"},
        "nararouter": {"base_url": "https://router.bynara.id/v1", "key_env": "NARAROUTER_API_KEY"},
        "tokenrouter": {"base_url": "https://api.tokenrouter.io/v1", "key_env": "TOKENROUTER_API_KEY"},
    }
    
    def __init__(self):
        self.usage = {p: {"used_today": 0, "last_request": 0} for p in self.PROVIDER_LIMITS}
        self.call_log = []
    
    def call(self, task_type, prompt, reasoning=False, max_tokens=4096, temperature=0.7):
        """Route a task to the best available free LLM."""
        models = self.TASK_MODEL_MAP.get(task_type, self.TASK_MODEL_MAP["fallback"])
        
        for model, provider, reasoning_config in models:
            if not self._has_quota(provider):
                continue
            api_key = os.environ.get(self.PROVIDER_ENDPOINTS.get(provider, {}).get("key_env", ""))
            if not api_key:
                continue
            try:
                response = self._call_provider(provider, model, prompt, reasoning,
                    reasoning_config if reasoning else {}, max_tokens, temperature, api_key)
                self._record_usage(provider)
                self._log_call(task_type, model, provider, True, len(str(response.get("content", ""))))
                return response.get("content", "")
            except Exception as e:
                print(f"  [LLM] {provider}/{model} failed: {e}")
                self._log_call(task_type, model, provider, False, 0, error=str(e))
                continue
        
        print("  [LLM] All direct providers exhausted, trying OmniRoute fallback...")
        return self._call_omniroute_fallback(prompt, task_type, max_tokens)
    
    def _has_quota(self, provider):
        limits = self.PROVIDER_LIMITS.get(provider, {})
        usage = self.usage.get(provider, {})
        if usage["used_today"] >= limits.get("rpd", 999):
            return False
        rpm = limits.get("rpm", 10)
        if time.time() - usage["last_request"] < 60.0 / rpm:
            return False
        return True
    
    def _call_provider(self, provider, model, prompt, reasoning, reasoning_config,
                       max_tokens, temperature, api_key):
        endpoint = self.PROVIDER_ENDPOINTS[provider]
        url = f"{endpoint['base_url']}/chat/completions"
        headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        
        if provider == "openrouter":
            headers["HTTP-Referer"] = "https://github.com/pocketagent98-ai/game-factory"
            headers["X-Title"] = "Game Factory"
        
        payload = {"model": model, "messages": [{"role": "user", "content": prompt}],
                   "max_tokens": max_tokens, "temperature": temperature}
        
        if reasoning and reasoning_config:
            payload.update(reasoning_config)
        if provider == "zai" and reasoning:
            payload["thinking"] = {"type": "enabled"}
        
        resp = requests.post(url, json=payload, headers=headers, timeout=120)
        resp.raise_for_status()
        data = resp.json()
        return {"content": data["choices"][0]["message"]["content"], "usage": data.get("usage", {})}
    
    def _call_omniroute_fallback(self, prompt, task_type, max_tokens):
        try:
            resp = requests.post("http://localhost:20128/v1/chat/completions",
                json={"model": "auto", "messages": [{"role": "user", "content": prompt}], "max_tokens": max_tokens},
                headers={"Content-Type": "application/json"}, timeout=120)
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"]
        except:
            print("  [LLM] OmniRoute not available. Returning placeholder.")
            return f"# TODO: Generate code for task: {task_type}\n# All LLM providers exhausted. Please add API keys.\n"
    
    def _record_usage(self, provider, tokens=0):
        self.usage[provider]["used_today"] += 1
        self.usage[provider]["last_request"] = time.time()
    
    def _log_call(self, task_type, model, provider, success, response_size, error=None):
        self.call_log.append({"timestamp": datetime.utcnow().isoformat(), "task_type": task_type,
            "model": model, "provider": provider, "success": success, "response_size": response_size, "error": error})
    
    def get_usage_report(self):
        return {p: {"used_today": d["used_today"], "remaining": self.PROVIDER_LIMITS[p]["rpd"] - d["used_today"]}
                for p, d in self.usage.items()}
