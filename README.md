# Game Factory

Autonomous A-to-Z game production pipeline using **free LLMs only**, **Godot 4**, and **GitHub Actions**.

## What It Does

You give a game brief. The system:
1. Deeply analyzes it (DeerFlow 2.0 + deep reasoning LLMs)
2. Breaks it into tasks and plans the game
3. Generates 3D assets (procedural + AI + Blender via Modal.com GPU)
4. Writes all GDScript code (DeepSeek Harness)
5. Generates 30+ language translations (GlobalLanguage.gd)
6. Runs 30-40 QA test cycles (generate/test/diagnose/fix)
7. Tests on 11 smart device profiles (parallel, not exhaustive)
8. Packages store listing (images, videos, logo, metadata)
9. Delivers a polished, multi-language, cross-platform game

## Key Features

- **100% FREE**: Uses 7 free LLM providers + OmniRoute plugin fallback. No paid API calls.
- **Anti-Infinite-Loop**: Max 40 test cycles, max 3 fix attempts per issue, max 4 hours total
- **Auto-Checkpoint**: Every 5 minutes, progress saved to Oxen.ai. If Actions fails, resume from last checkpoint (max 5-min loss)
- **Smart GPU**: Modal.com $5 credits for Blender (characters) + Terrain3D/TerraForge3D (open-world maps). Auto-kill after task.
- **Game Updates**: Each game gets a Project ID. Update months/years later without breaking existing functionality (Regression Gate)
- **Godot Version Detection**: Auto-detects latest stable. For updates, detects old version and upgrades safely.
- **Godot In-Built Analytics**: Every game has AnalyticsManager.gd (100% built-in, zero extra size)

## Architecture (24 Layers)

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the complete architecture.

## Quick Start

1. Add your API keys as GitHub Secrets (see below)
2. Edit `test-games/temple-run/game-bible/game_spec.yaml` with your game brief
3. Go to Actions tab -> "Game Factory Pipeline" -> Run workflow
4. Wait for pipeline to complete (~22 hours)
5. Download your game from the Actions artifacts

## GitHub Secrets Required

| Secret | Description | Free? |
|--------|-------------|-------|
| `ZAI_API_KEY` | z.ai API key (GLM-4.7-Flash, coding) | Yes, free forever |
| `NVIDIA_API_KEY` | NVIDIA NIM API key | Yes, free |
| `GOOGLE_API_KEY` | Google Gemini API key | Yes, free tier |
| `OPENROUTER_API_KEY` | OpenRouter API key | Yes, free tier |
| `NARAROUTER_API_KEY` | NaraRouter API key | Yes, free |
| `HF_API_KEY` | Hugging Face token (50GB storage) | Yes, free |
| `OXEN_API_KEY` | Oxen.ai API key (50GB storage) | Yes, free |
| `MODAL_API_KEY` | Modal.com token ($5 GPU credits) | Yes, free |
| `SUPABASE_URL` | Supabase project URL | Yes, free |
| `SUPABASE_KEY` | Supabase anon key | Yes, free |

**Optional**: `TOKENROUTER_API_KEY` (TokenRouter), OmniRoute plugin (runs locally)

## LLM Providers (All Free)

| Provider | Models | Best For |
|----------|--------|----------|
| z.ai | GLM-4.7-Flash (200K ctx), GLM-4.5-Flash, GLM-4.6V-Flash | Coding, reasoning, vision |
| NVIDIA NIM | Nemotron 3 Ultra (1M ctx), DeepSeek V4, 100+ models | Deep reasoning |
| Google Gemini | Gemini 3.1 Flash-Lite, Gemma 4 31B/26B | Translation, multilingual |
| OpenRouter | 20+ free models, auto-router | Fallback for everything |
| NaraRouter | DeepSeek V4 Flash Free, GLM 5.3 Free | Additional coding |
| TokenRouter | Kimi K2.7 Code, DeepSeek V4 Pro | Specialized tasks |
| OmniRoute | 90+ free providers aggregated | Universal fallback + token compression |

## Storage (100GB Free, All Private)

- **Hugging Face** (50GB): Knowledge base, shared assets, models
- **Oxen.ai** (50GB): Game projects, checkpoints, builds
- **GitHub LFS** (10GB): Source code

## License

MIT
