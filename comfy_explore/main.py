"""Core functionality for ComfyExplore"""

from blessed import Terminal
from comfy_explore.window import Window


def should_quit():
    """Exit the program cleanly."""
    exit(0)



from comfy_explore.project_management import ProjectManagementWindow

def comfy_explore_main():
    term = Terminal()
    current_window = ProjectManagementWindow()

    with term.cbreak():
        try:
            print(term.hide_cursor(), end="")
            current_window.redraw(term)
            while True:
                key = term.inkey()
                if key:
                    consumed = current_window.step(key)
                    if not consumed and key == 'q':
                        print(term.normal_cursor(), end="")
                        should_quit()
                    current_window.redraw(term)
        finally:
            print(term.normal_cursor(), end="")
