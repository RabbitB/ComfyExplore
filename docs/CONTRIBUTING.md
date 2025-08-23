Contributing to ComfyExplore

Local setup

1. Create a virtual environment and activate it:

```zsh
python3 -m venv .venv
source .venv/bin/activate
```

2. Install dev dependencies:

```zsh
python -m pip install -U pip
python -m pip install -r requirements.txt
python -m pip install -e .
python -m pip install pytest
```

Run tests

```zsh
python -m pytest -q
```

Coding conventions

- Keep functions small and pure when possible.
- Add tests for new behavior.
- Update `FEATURES.md` / `ROADMAP.md` when introducing new user-visible behavior.

Pull requests

- Target `main` branch.
- Include tests and short changelog entry.
- Ensure new code has type hints where helpful.

Launching in an external terminal (Konsole example)

If you want to run the program in an external terminal (e.g., Konsole), create a script like this (do not track it in git):

```bash
#!/bin/bash
konsole --hold -e zsh -c "
    cd \"$(dirname \"$0\")\"
    source .venv/bin/activate
    python -m comfy_explore
"
```

Add this script to your `.gitignore` as it is machine-specific.
