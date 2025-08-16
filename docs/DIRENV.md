direnv — automatic project environment loading

Why use direnv

`direnv` safely loads and unloads per-project environment changes when you cd into and out of a folder. It is explicit (you must `direnv allow` each `.envrc`) so it's safer than automatically sourcing arbitrary files.

Quick setup

1. Install direnv (platform package manager, e.g. `sudo apt install direnv` or `brew install direnv`).
2. Hook direnv into your shell (recommended): add the following to `~/.bashrc` or `~/.zshrc`:

```sh
# example for zsh
eval "$(direnv hook zsh)"
```

3. Create a `.envrc` in the project root (see example file `docs/.envrc.example`).
4. Allow the `.envrc` once:

```sh
direnv allow
```

Example `.envrc` (what it does)

- Activates the local `.venv` without modifying shell startup files.
- Is explicit per-repo and must be approved by you.

See `docs/.envrc.example` for a minimal example.

Security note

Only `direnv allow` `.envrc` files you trust. The `.envrc` can run arbitrary shell commands, so review the file before allowing it.
