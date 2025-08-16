ComfyExplore — Project Overview

Purpose

ComfyExplore is a small utility suite to explore, inspect, and perform simple manipulations on images produced by ComfyUI / SwarmUI. The goal is to make it fast and convenient to browse generated samples, extract metadata encoded in filenames, produce thumbnails, and perform batch operations (move, rename, tag, export).

Users

- Artists using ComfyUI/SwarmUI who want quick inspection and lightweight tooling.
- Engineers building downstream tooling around image assets (batch processing, dataset curation).

Success criteria (v0.1)

- CLI to list and count sample images in a workspace.
- Reliable image file discovery (common image formats).
- Easy local dev setup with venv and tests.
- Clean, documented code layout so new features can be added easily.

Out of scope (initial)

- Heavy GUI editing.
- Large-scale indexing or DB-backed catalogs (can be added later).

Notes

This repo started as a bash script and is being migrated to Python for better portability, testing and extensibility.
