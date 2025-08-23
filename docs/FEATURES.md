# ComfyExplore — Features

### Legacy Bash Script Features

- Interactive batch triage for AI-generated images
- Handles "final" images in current directory and "full-size" images in ./full_size
- Retain, trash, and view images
- Batch selection: choose how many images per batch and which batch to process
- Labeling system for images (numeric and alphabetic)
- Commands for viewing images, viewing metadata, refreshing, emptying trash, and quitting
- Metadata extraction (EXIF, PNG chunks, JSON blobs)
- Retained and trashed images are moved to dedicated folders
- Trash can be emptied (with system trash integration if available)
- Image viewing via various tools (display, kitty, viu, xdg-open, etc.)
- Metadata viewing and saving (parameters, workflow, raw JSON)
- Directory setup for retained, trashed, and metadata files
- Error handling and user prompts for all major actions

---
### Intended Features

- Retain, archive, or delete images
- Trash management (empty, restore)
- View images (inline or external)
- View and expand image metadata
- Project selection and management

---
### Migration/Change Log

- [To Review] For each legacy feature, decide: Keep, Change, Drop, or Improve
- [To Do] Update this section as features are ported, changed, or improved in Python

---
### Developer quality-of-life

- pytest-based test suite
- CLI with subcommands
- Well-documented code
