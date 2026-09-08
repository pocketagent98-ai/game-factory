# Game Factory Architecture (Summary)

## 24-Layer Architecture

| Layer | Name | Purpose |
|-------|------|---------|
| 0 | Godot Version Detection | Scan latest stable, handle upgrades |
| 1 | Game Bible System | Project ID, version tracking, update mode |
| 2 | DeerFlow 2.0 | Orchestration + deep research + mini agents |
| 3 | DeepSeek Harness | Coding brain (GDScript generation) |
| 4 | Ruflo | Adaptive coordination + memory + learning |
| 5 | Agency Agents | On-demand specialists (3-5 active at a time) |
| 6 | OpenSandbox | Isolated execution environment |
| 7 | Godot Engine | Game engine + production |
| 8 | Asset Generation | 3-tier: procedural (FREE) + AI (LOW) + Blender GPU ($5) |
| 9 | Multi-Language | GlobalLanguage.gd + 30+ languages |
| 10 | AI QA Loop | 30-40 test cycles with anti-infinite-loop |
| 11 | Regression Gate | Updates don't break existing (one-by-one verification) |
| 12 | Cross-Platform Test | 11 smart profiles, parallel |
| 13 | Security | PCK encryption, anti-cheat |
| 14 | Backend | Epic EOS + Supabase |
| 15 | Store Listing | Logo, screenshots, videos, metadata |
| 16 | Knowledge Foundation | RAG + Vector DB + Godot datasets |
| 17 | GitHub Actions | 14-step pipeline orchestrator |
| 18 | GPU Cost Controller | Modal.com $5 credits, auto-kill |
| 19 | LLM Routing | 7 free providers + OmniRoute fallback |
| 20 | Storage Management | Hugging Face 50GB + Oxen.ai 50GB |
| 21 | Auto-Checkpoint | Every 5 min, upload to Oxen.ai |
| 22 | Compute Budget | Actions 1900 min + Codespaces 60 hrs |
| 23 | Godot Analytics | Built-in HTTPRequest -> Supabase |

## Anti-Infinite-Loop Safeguards
- Max 40 test cycles
- Max 3 fix attempts per issue
- Max 4 hours total runtime
- Failed profiles marked "known issue" (don't block)
- If same issue recurs 5 times: escalate to deeper reasoning
- Auto-checkpoint every 5 min (max 5-min loss on failure)

## GPU Tools (Modal.com $5 credits)
1. **Blender** — Characters and detailed 3D models only
2. **TerraForge3D** — Open-world terrain/map generation (exports GLTF/OBJ)
3. **Terrain3D** — In-Godot runtime terrain (no build-time cost)
4. **Clipmap3D** — Infinite procedural terrain with GPU compute shaders

## 3D Open-World Map Generation

The system uses multiple approaches for 3D world generation:

| Tool | Type | Cost | Best For |
|------|------|------|----------|
| Terrain3D | Godot plugin (C++) | FREE | In-game terrain, up to 65.5x65.5km |
| Clipmap3D | Godot plugin (GDScript+Shaders) | FREE | Infinite terrain, GPU compute shaders |
| TerraForge3D | Standalone (GPU) | Modal.com $5 | Pre-generating terrain meshes, exports GLTF/OBJ |
| ProceduralTerrains | Web tool (WebGL2) | FREE | Pre-generating terrain, exports GLB with Godot preset |
| Blender (Modal.com) | 3D modeling | Modal.com $5 | Characters, vehicles, detailed props |

## LLM Providers (All Free)
- z.ai: GLM-4.7-Flash (coding), GLM-4.5-Flash, GLM-4.6V-Flash (vision)
- NVIDIA NIM: Nemotron 3 Ultra (1M ctx), 100+ models
- Google: Gemini Flash-Lite, Gemma 4 31B/26B
- OpenRouter: 20+ free models, auto-router
- NaraRouter: DeepSeek V4 Flash Free, 5M tokens/day
- TokenRouter: Kimi K2.7 Code, DeepSeek V4 Pro
- OmniRoute: 90+ free providers (plugin, local fallback)

## Storage (100GB Free)
- Hugging Face (50GB): Knowledge, shared assets, models
- Oxen.ai (50GB): Game projects, checkpoints, builds
- GitHub LFS (10GB): Source code
