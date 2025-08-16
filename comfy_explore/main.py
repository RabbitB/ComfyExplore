"""Core functionality for ComfyExplore"""
import os
from typing import List

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tiff", ".tif"}


def is_image_file(name: str) -> bool:
    return os.path.splitext(name.lower())[1] in IMAGE_EXTS


def list_samples(samples_dir: str) -> List[str]:
    """Return a sorted list of sample file paths (relative) found under samples_dir."""
    if not os.path.exists(samples_dir):
        return []
    files = []
    for entry in sorted(os.listdir(samples_dir)):
        full = os.path.join(samples_dir, entry)
        if os.path.isfile(full) and is_image_file(entry):
            files.append(full)
    return files


def run(args) -> None:
    samples = list_samples(args.samples)
    if args.count:
        print(len(samples))
        return
    if args.list:
        for p in samples:
            print(p)
        return
    # default action: show summary
    print(f"Samples dir: {args.samples}")
    print(f"Found {len(samples)} image files.")
    if getattr(args, "verbose", False):
        for p in samples[:20]:
            print(" -", p)
