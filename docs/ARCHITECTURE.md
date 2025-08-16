ComfyExplore — Architecture and Layout

High level

- small package `comfy_explore` containing CLI and core modules
- CLI (`comfy_explore.cli`) parses args, dispatches to core functions
- Core (`comfy_explore.main`) implements discovery and operations
- `utils` for small helpers (filesystem)
- `tests/` holds pytest tests

Planned package layout

comfy_explore/
- __init__.py      -- package exports and version
- __main__.py      -- module entrypoint
- cli.py           -- argparse setup and entrypoint
- main.py          -- core operations (list, count, discover)
- io.py            -- file IO helpers (thumbnails, copy/move)
- metadata.py      -- parsing filename metadata and sidecar handling
- utils.py         -- small helpers

Design contracts (tiny)

- list_samples(path: str) -> List[str]
  - returns full paths, sorted
  - returns [] if path missing

- parse_filename(fn: str) -> dict
  - best-effort parse for model/seed/prompt metadata

Edge cases to handle

- Non-UTF file names
- Large directories (do not read image bytes unless needed)
- Mixed case extensions
- Files with names that look like images but are not

Extensibility

- Operations should be small, testable functions.
- Add plugin points later for custom extractors or exporters.
