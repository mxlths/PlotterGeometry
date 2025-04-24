"""
Core geometry primitives for the Geometron application.

This module defines the fundamental geometric objects used throughout the application.
"""

import math
import copy
from enum import Enum
from typing import List, Tuple, Optional, Dict, Any, Union
import numpy as np
import attr
from dataclasses import dataclass


class GeometryType(Enum):
    """Types of geometry that can be generated."""
    POINT = 1
    LINE = 2
    PATH = 3
    SHAPE = 4
    GROUP = 5


@attr.s(auto_attribs=True)
class StyleAttributes:
    """Style attributes for geometry objects."""
    color: Tuple[int, int, int] = (0, 0, 0)  # RGB color
    weight: float = 1.0  # Line weight/thickness
    opacity: float = 1.0  # Opacity (0-1)
    fill_color: Optional[Tuple[int, int, int]] = None  # Fill color for closed shapes
    fill_opacity: float = 1.0  # Fill opacity (0-1)
    dash_pattern: Optional[List[float]] = None  # Dash pattern [on, off, on, off, ...]
    cap_style: str = "butt"  # Line cap style: 'butt', 'round', 'square'
    join_style: str = "miter"  # Line join style: 'miter', 'round', 'bevel'

    def as_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return attr.asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'StyleAttributes':
        """Create from dictionary."""
        return cls(**{k: v for k, v in data.items() if k in attr.fields_dict(cls)})


class GeometryObject:
    """Base class for all geometry objects."""
    
    def __init__(self, geometry_type: GeometryType):
        self.geometry_type = geometry_type
        self.style = StyleAttributes()
        
    def transform(self, matrix: np.ndarray) -> 'GeometryObject':
        """Apply transformation matrix to this geometry.
        
        Returns self for method chaining.
        """
        # To be implemented by subclasses
        return self
        
    def to_svg_element(self) -> str:
        """Convert this geometry to SVG element string."""
        # To be implemented by subclasses
        return ""
        
    def copy(self) -> 'GeometryObject':
        """Create a deep copy of this geometry object."""
        return copy.deepcopy(self)
        
    def as_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "type": self.geometry_type.name,
            "style": self.style.as_dict()
        }
        
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'GeometryObject':
        """Create from dictionary. Factory method dispatching to appropriate subclass."""
        geom_type = GeometryType[data["type"]]
        
        if geom_type == GeometryType.POINT:
            return Point.from_dict(data)
        elif geom_type == GeometryType.LINE:
            return Line.from_dict(data)
        elif geom_type == GeometryType.PATH:
            return Path.from_dict(data)
        elif geom_type == GeometryType.SHAPE:
            return Shape.from_dict(data)
        elif geom_type == GeometryType.GROUP:
            return Group.from_dict(data)
        else:
            raise ValueError(f"Unknown geometry type: {geom_type}")


@dataclass
class Point:
    """A point in 2D or 3D space.
    
    Attributes:
        coords: Numpy array of coordinates [x, y] or [x, y, z]
        is_3d: Boolean indicating if this is a 3D point
    """
    coords: np.ndarray
    is_3d: bool = False
    
    def __init__(self, x: float, y: float, z: Optional[float] = None):
        """Initialize a Point with 2D or 3D coordinates."""
        self.is_3d = z is not None
        self.coords = np.array([x, y, z] if self.is_3d else [x, y])
    
    def __repr__(self) -> str:
        return f"Point({', '.join(map(str, self.coords))})"


@dataclass
class Line:
    """A line segment between two points.
    
    Attributes:
        start: Starting point
        end: Ending point
        style: Dictionary containing style attributes (color, width, etc.)
    """
    start: Point
    end: Point
    style: dict = None
    
    def __post_init__(self):
        """Ensure style dictionary exists."""
        if self.style is None:
            self.style = {}
        # Ensure both points are same dimensionality
        if self.start.is_3d != self.end.is_3d:
            raise ValueError("Line endpoints must both be 2D or both be 3D")


@dataclass
class Path:
    """A collection of connected lines.
    
    Attributes:
        points: List of points defining the path
        closed: Whether the path forms a closed loop
        style: Dictionary containing style attributes
    """
    points: List[Point]
    closed: bool = False
    style: dict = None
    
    def __post_init__(self):
        """Validate path and ensure style dictionary exists."""
        if self.style is None:
            self.style = {}
        if len(self.points) < 2:
            raise ValueError("Path must contain at least 2 points")
        # Ensure all points are same dimensionality
        is_3d = self.points[0].is_3d
        if not all(p.is_3d == is_3d for p in self.points):
            raise ValueError("All points in path must be same dimensionality")


@dataclass
class Shape:
    """A closed path that may contain a fill.
    
    Attributes:
        path: The Path object defining the shape's boundary
        fill: Dictionary containing fill attributes (color, pattern, etc.)
    """
    path: Path
    fill: Optional[dict] = None
    
    def __post_init__(self):
        """Ensure path is closed and fill dictionary exists if specified."""
        self.path.closed = True
        if self.fill is None:
            self.fill = {}


@dataclass
class Group:
    """A collection of geometry objects that can be transformed together.
    
    Attributes:
        elements: List of geometry objects (Points, Lines, Paths, Shapes, or other Groups)
        transform: Optional transformation matrix
    """
    elements: List[Union[Point, Line, Path, Shape, 'Group']]
    transform: Optional[np.ndarray] = None
    
    def __post_init__(self):
        """Initialize default transformation matrix if none provided."""
        if self.transform is None:
            # Create identity matrix of appropriate size based on first element
            first_elem = self.elements[0] if self.elements else None
            is_3d = (isinstance(first_elem, Point) and first_elem.is_3d) or \
                    (isinstance(first_elem, Line) and first_elem.start.is_3d) or \
                    (isinstance(first_elem, Path) and first_elem.points[0].is_3d)
            self.transform = np.eye(4 if is_3d else 3)


class GeometryCollection:
    """Container for multiple geometry objects."""
    
    def __init__(self):
        self.objects: List[GeometryObject] = []
        
    def add(self, obj: GeometryObject) -> None:
        """Add an object to the collection."""
        self.objects.append(obj)
        
    def transform(self, matrix: np.ndarray) -> 'GeometryCollection':
        """Apply transformation to all contained geometry."""
        for obj in self.objects:
            obj.transform(matrix)
        return self
        
    def copy(self) -> 'GeometryCollection':
        """Create a deep copy of this collection."""
        new_collection = GeometryCollection()
        for obj in self.objects:
            new_collection.add(obj.copy())
        return new_collection
    
    def as_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "objects": [obj.as_dict() for obj in self.objects]
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'GeometryCollection':
        """Create from dictionary."""
        collection = cls()
        for obj_data in data.get("objects", []):
            collection.add(GeometryObject.from_dict(obj_data))
        return collection
    
    def __repr__(self) -> str:
        return f"GeometryCollection({len(self.objects)} objects)"


class Matrix:
    """Utility class for transformation matrices."""
    
    @staticmethod
    def identity() -> np.ndarray:
        """Return 4x4 identity matrix for homogeneous coordinates."""
        return np.identity(4)
    
    @staticmethod
    def translation(tx: float, ty: float, tz: float = 0.0) -> np.ndarray:
        """Create a translation matrix."""
        matrix = np.identity(4)
        matrix[0, 3] = tx
        matrix[1, 3] = ty
        matrix[2, 3] = tz
        return matrix
    
    @staticmethod
    def scaling(sx: float, sy: float, sz: float = 1.0) -> np.ndarray:
        """Create a scaling matrix."""
        matrix = np.identity(4)
        matrix[0, 0] = sx
        matrix[1, 1] = sy
        matrix[2, 2] = sz
        return matrix
    
    @staticmethod
    def rotation_z(angle_rad: float) -> np.ndarray:
        """Create a rotation matrix around Z axis."""
        matrix = np.identity(4)
        cos_a = math.cos(angle_rad)
        sin_a = math.sin(angle_rad)
        matrix[0, 0] = cos_a
        matrix[0, 1] = -sin_a
        matrix[1, 0] = sin_a
        matrix[1, 1] = cos_a
        return matrix
    
    @staticmethod
    def rotation_x(angle_rad: float) -> np.ndarray:
        """Create a rotation matrix around X axis."""
        matrix = np.identity(4)
        cos_a = math.cos(angle_rad)
        sin_a = math.sin(angle_rad)
        matrix[1, 1] = cos_a
        matrix[1, 2] = -sin_a
        matrix[2, 1] = sin_a
        matrix[2, 2] = cos_a
        return matrix
    
    @staticmethod
    def rotation_y(angle_rad: float) -> np.ndarray:
        """Create a rotation matrix around Y axis."""
        matrix = np.identity(4)
        cos_a = math.cos(angle_rad)
        sin_a = math.sin(angle_rad)
        matrix[0, 0] = cos_a
        matrix[0, 2] = sin_a
        matrix[2, 0] = -sin_a
        matrix[2, 2] = cos_a
        return matrix 