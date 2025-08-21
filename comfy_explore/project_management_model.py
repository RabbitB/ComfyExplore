"""Model for project management in ComfyExplore."""

class ProjectManagementModel:
    """Holds state for the project management window."""

    def __init__(self, projects=None):
        self.projects = projects if projects is not None else []
        self.selected_index = 0

    def add_project(self, name):
        self.projects.append(name)

    def remove_selected(self):
        if self.projects:
            self.projects.pop(self.selected_index)
            self.selected_index = max(0, self.selected_index - 1)

    def select_next(self):
        if self.projects:
            self.selected_index = (self.selected_index + 1) % len(self.projects)

    def select_prev(self):
        if self.projects:
            self.selected_index = (self.selected_index - 1) % len(self.projects)

    def get_selected(self):
        if self.projects:
            return self.projects[self.selected_index]
        return None

# Default test data for development only
DEFAULT_TEST_PROJECTS_MODEL = ProjectManagementModel(
    projects=["Project Alpha", "Project Beta", "Project Gamma"]
)