from .base import AlgorithmBase, AlgorithmParameter, GeometryData
from typing import List, Dict, Any

class DummyCircleAlgo(AlgorithmBase):
    """A simple placeholder algorithm for generating circles."""

    @classmethod
    def get_name(cls) -> str:
        return "Dummy Circle"

    @classmethod
    def get_description(cls) -> str:
        return "Generates a simple circle outline (placeholder)."

    @classmethod
    def get_parameters(cls) -> List[AlgorithmParameter]:
        return [
            AlgorithmParameter("radius", "float", 50.0, "Radius of the circle", min=1.0, max=500.0, step=1.0),
            AlgorithmParameter("segments", "int", 32, "Number of segments", min=3, max=100),
            AlgorithmParameter("dashed", "bool", False, "Use dashed line")
        ]

    def generate_geometry(self, parameters: Dict[str, Any]) -> GeometryData | None:
        print(f"Generating circle with parameters: {parameters}")
        # In a real implementation, this would create and return geometry data
        return None # Placeholder

class DummySquareAlgo(AlgorithmBase):
    """A simple placeholder algorithm for generating squares."""

    @classmethod
    def get_name(cls) -> str:
        return "Dummy Square"

    @classmethod
    def get_description(cls) -> str:
        return "Generates a simple square outline (placeholder)."

    @classmethod
    def get_parameters(cls) -> List[AlgorithmParameter]:
        return [
            AlgorithmParameter("size", "float", 100.0, "Side length of the square", min=1.0, max=1000.0),
            AlgorithmParameter("centered", "bool", True, "Center the square at origin")
        ]

    def generate_geometry(self, parameters: Dict[str, Any]) -> GeometryData | None:
        print(f"Generating square with parameters: {parameters}")
        # In a real implementation, this would create and return geometry data
        return None # Placeholder 