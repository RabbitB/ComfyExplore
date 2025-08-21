"""Window interface for ComfyExplore."""

from abc import ABC, abstractmethod
from blessed import Terminal

class Window(ABC):
    """Interface for all windows in ComfyExplore."""

    @abstractmethod
    def redraw(self, term: Terminal):
        """Redraw the window using the provided terminal."""
        pass

    @abstractmethod
    def step(self, key) -> bool:
        """
        Process input and update window.
        Return True if the key was consumed, False otherwise.
        """
        pass