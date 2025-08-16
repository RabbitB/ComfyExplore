import argparse
from . import run


def build_parser():
    p = argparse.ArgumentParser(prog="comfy-explore", description="Explore and manipulate ComfyUI/SwarmUI images")
    p.add_argument("--samples", "-s", default="samples", help="Path to samples folder")
    p.add_argument("--list", action="store_true", help="List sample files")
    p.add_argument("--count", action="store_true", help="Print count of sample files")
    p.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    return p


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    run(args)
