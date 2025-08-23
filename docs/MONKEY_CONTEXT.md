MONKEY_CONTEXT.md — MASTER RECORD: This file is the authoritative record of all critical project knowledge for ComfyExplore.

Purpose
- This file documents anything that is essential for maintainers, contributors, or automation to know about the project.
- It includes (but is not limited to):
	- Environment/venv requirements and command patterns
	- Known bugs, pitfalls, and troubleshooting steps
	- Special runtime requirements or workarounds
	- Important notes, reminders, or project-specific quirks
- Whenever a new issue, requirement, or important note arises, update this file so it remains the single source of truth for the project.

Key requirement
- Tests and other terminal commands that import the package (for example, `pytest`, `python -m comfy_explore`, or editable installs) must be run with the project's virtual environment Python. Do not rely on shell auto-activation from external tools — use the `.venv` interpreter explicitly or activate the venv in the shell you are using.

Why
- Some terminals/sessions do not automatically start inside the project's venv. Running `pytest` or other Python commands from a system interpreter can cause `ModuleNotFoundError: No module named 'comfy_explore'` or editable-install failures.

How to run (recommended, explicit interpreter)
1. From the repository root, run tests with the venv Python:

```bash
cd /path/to/ComfyExplore
.venv/bin/python -m pytest -q
```

2. Run the CLI or modules with the venv Python:

```bash
cd /path/to/ComfyExplore
.venv/bin/python -m comfy_explore
```

3. Install editable (if needed) using the venv pip:

```bash
cd /path/to/ComfyExplore
.venv/bin/python -m pip install -e .
```

How to run (alternate, activate venv in your terminal)

```bash
cd /path/to/ComfyExplore
source .venv/bin/activate
# then run commands as normal, e.g. pytest -q
```

Notes and reminders
- Always prefer the explicit `.venv/bin/python` invocation in automation and CI to make runs reproducible.
- If you add tools or editor integrations, point them at the `.venv` interpreter for this project.
- If future environment problems occur, add the troubleshooting steps and relevant commands to this file so this master record stays current.

Ownership
- This file is the single source of truth for environment/venv guidance for the project. Update it whenever a new requirement or workflow is introduced.

UI Implementation Principle
- All UI activity should be handled by the Blessed library unless there is a clear, justified reason to use another method for specific cases.

Module Usage Note
- Do not add `if __name__ == "__main__":` blocks to files in this project. All code is intended to be used as part of a module/package, not as standalone scripts.

Code Style
- All code in this project should follow the [PEP 8](https://peps.python.org/pep-0008/) styling guide. This includes (but is not limited to) indentation, naming conventions, whitespace, imports, and line length.
- Contributors should review and format their code for PEP 8 compliance before submitting changes.
