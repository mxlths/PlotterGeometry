from abc import ABC, abstractmethod
from typing import List, Dict, Any

# Placeholder for geometry data
class GeometryData:
    pass

class AlgorithmParameter:
    def __init__(self, name: str, param_type: str, default: Any, description: str = "", **kwargs):
        self.name = name
        self.type = param_type # e.g., 'int', 'float', 'bool', 'string', 'color'
        self.default = default
        self.description = description
        self.options = kwargs # e.g., min, max, step, items (for combo)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'type': self.type,
            'default': self.default,
            'description': self.description,
            **self.options
        }

class AlgorithmBase(ABC):
    """Abstract base class for all generative algorithms."""

    @classmethod
    @abstractmethod
    def get_name(cls) -> str:
        """Return the user-facing name of the algorithm."""
        pass

    @classmethod
    def get_description(cls) -> str:
        """Return a brief description of what the algorithm does."""
        return ""

    @classmethod
    @abstractmethod
    def get_parameters(cls) -> List[AlgorithmParameter]:
        """Return a list defining the parameters this algorithm accepts."""
        pass

    @abstractmethod
    def generate_geometry(self, parameters: Dict[str, Any]) -> GeometryData | None:
        """Generate the geometric output based on the given parameters."""
        pass 