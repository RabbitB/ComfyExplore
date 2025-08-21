"""
Project management window for ComfyExplore.
"""

from comfy_explore.window import Window


from comfy_explore.project_management_model import DEFAULT_TEST_PROJECTS_MODEL, ProjectManagementModel

# Key bindings
KEY_ADD_PROJECT = "KEY_TAB"
KEY_DELETE_PROJECT = "KEY_DELETE"
KEY_UP = "KEY_UP"
KEY_DOWN = "KEY_DOWN"
KEY_ENTER = "KEY_ENTER"
KEY_BACKSPACE = "KEY_BACKSPACE"
KEY_ESCAPE = "KEY_ESCAPE"

CURSOR_SYMBOL = "█"

class ProjectManagementWindow(Window):
    """Project management window with interactive features."""

    def __init__(self):
        self.model = DEFAULT_TEST_PROJECTS_MODEL
        self.term = None
        self.input_buffer = ""
        self.input_mode = False

    def redraw(self, term):
        self.term = term
        if self.input_mode:
            print(term.home + term.clear)
            print(term.bold_red_on_black("Add New Project"))
            print(term.bold("Type the project name and press Enter."))
            print(term.bold("Press Esc to cancel, Backspace to edit."))
            print()
            print(term.bold("New project: ") + term.reverse(self.input_buffer + CURSOR_SYMBOL))
            print()
            return

        print(term.home + term.clear)
        print(term.bold("Project Management Window"))
        print(f"Press 'q' to quit. Use ↑/↓ to select. {KEY_ADD_PROJECT.replace('KEY_', '')} to add, {KEY_DELETE_PROJECT.replace('KEY_', '')} to delete.")
        print()
        for idx, name in enumerate(self.model.projects):
            selected = idx == self.model.selected_index
            label = f"{idx+1:02d}. "
            line = label + name
            if selected:
                print(term.reverse(line))
            else:
                print(line)
        print()

    def step(self, key):
        consumed = True
        # Explicit input mode for new project name
        if self.input_mode:
            if key.is_sequence and key.name == KEY_ENTER:
                if self.input_buffer.strip():
                    self.model.add_project(self.input_buffer.strip())
                    self.model.selected_index = len(self.model.projects) - 1
                self.input_buffer = ""
                self.input_mode = False
            elif key.is_sequence and key.name == KEY_BACKSPACE:
                self.input_buffer = self.input_buffer[:-1]
            elif key.is_sequence and key.name == KEY_ESCAPE:
                self.input_buffer = ""
                self.input_mode = False
            elif key and not key.is_sequence:
                self.input_buffer += str(key)
        else:
            if key == 'q':
                # Only allow quit if not in input mode
                consumed = False
            elif key.is_sequence and key.name == KEY_ADD_PROJECT:
                self.input_mode = True
                self.input_buffer = ""
            elif key.is_sequence and key.name == KEY_DELETE_PROJECT:
                self.model.remove_selected()
            elif key.is_sequence:
                if key.name == KEY_UP:
                    self.model.select_prev()
                elif key.name == KEY_DOWN:
                    self.model.select_next()
        return consumed