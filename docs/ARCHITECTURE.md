ComfyExplore — Architecture and Layout

## High level

- Small package `comfy_explore` containing CLI and core modules
- CLI (`comfy_explore.cli`) parses args, dispatches to core functions
- Core (`comfy_explore.main`) implements discovery and operations
- `utils` for small helpers (filesystem)
- `tests/` holds pytest tests

## Planned package layout

comfy_explore/
- \_\_init__.py      -- package exports and version
- \_\_main__.py      -- module entrypoint
- cli.py           -- argparse setup and entrypoint
- main.py          -- core operations (list, count, discover)
- io.py            -- file IO helpers (thumbnails, copy/move)
- metadata.py      -- parsing filename metadata and sidecar handling
- utils.py         -- small helpers

## UI Architecture

- Terminal UI is implemented using the **Blessed** library for handling input, output, colors, and screen drawing.
- The interface supports:
    - Smooth scrolling image list, autosized to fit available terminal space minus reserved interface elements.
    - Toggle for viewing images inline (resized if needed) or in an external window.
    - Inline image display includes a label indicating native resolution or resized.
    - Metadata display: basic info (e.g., image size) shown in the image list; detailed info in a dedicated info panel; command to expand info panel for full metadata.
    - For each image: options to retain, archive, or delete (with deleted images moved to a managed trash folder).
    - Option to empty trash, moving files from managed trash to system trash.

## Project Management

- Projects are user-defined and selectable via a project selection interface.
- Each project can have multiple folders, with a hierarchy of image storage paths (relative to project root).
- Each folder entry includes:
    - A user-friendly name
    - A simple filename match is performed first; if no image matches, a regex is used to find possible matches. The regex supports special identifiers (base filename, extension, metadata values).
  - All project configuration is editable from the UI.

## Configuration and Data Storage

- Configuration and project data are stored using the **platformdirs** library, which selects the appropriate user configuration folder for each OS:
    - Linux: `~/.config/comfy`
    - Windows: `%APPDATA%\comfy`
    - macOS: `~/Library/Application Support/comfy`
- JSON is used as the default format for saving project configuration.

## Design contracts (tiny)

- list_samples(path: str) -> List[str]
  - returns full paths, sorted
  - returns [] if path missing

- parse_filename(fn: str) -> dict
  - best-effort parse for model/seed/prompt metadata

## Edge cases to handle

- Non-UTF file names
- Large directories (do not read image bytes unless needed)
- Mixed case extensions
- Files with names that look like images but are not

## Extensibility

- Operations should be small, testable functions.

## Startup Behavior

- On launch, the program can open to either:
    - The project selection/management window
    - The last open project
- This behavior is controlled by a user setting.
- If no projects exist, the program always opens to the project selection/management window.

## User Settings Accessibility

- User settings can be accessed from any window in the program.
- Exiting the user settings always returns to the last open window.
