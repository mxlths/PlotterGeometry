import numpy as np
from typing import Tuple, Union
from .primitives import Point

class Transform:
    """Utility class for geometric transformations in 2D and 3D space."""
    
    @staticmethod
    def translation_matrix(dx: float, dy: float, dz: float = 0.0) -> np.ndarray:
        """Create a translation matrix.
        
        Args:
            dx: Translation in x direction
            dy: Translation in y direction
            dz: Translation in z direction (0 for 2D)
            
        Returns:
            4x4 transformation matrix
        """
        matrix = np.eye(4)
        matrix[0:3, 3] = [dx, dy, dz]
        return matrix
    
    @staticmethod
    def rotation_matrix_2d(angle: float) -> np.ndarray:
        """Create a 2D rotation matrix.
        
        Args:
            angle: Rotation angle in radians
            
        Returns:
            3x3 transformation matrix
        """
        cos_a = np.cos(angle)
        sin_a = np.sin(angle)
        matrix = np.eye(3)
        matrix[0:2, 0:2] = [[cos_a, -sin_a],
                           [sin_a, cos_a]]
        return matrix
    
    @staticmethod
    def rotation_matrix_3d(angle: float, axis: str) -> np.ndarray:
        """Create a 3D rotation matrix around specified axis.
        
        Args:
            angle: Rotation angle in radians
            axis: Rotation axis ('x', 'y', or 'z')
            
        Returns:
            4x4 transformation matrix
        """
        cos_a = np.cos(angle)
        sin_a = np.sin(angle)
        matrix = np.eye(4)
        
        if axis.lower() == 'x':
            matrix[1:3, 1:3] = [[cos_a, -sin_a],
                               [sin_a, cos_a]]
        elif axis.lower() == 'y':
            matrix[0::2, 0::2] = [[cos_a, sin_a],
                                 [-sin_a, cos_a]]
        elif axis.lower() == 'z':
            matrix[0:2, 0:2] = [[cos_a, -sin_a],
                               [sin_a, cos_a]]
        else:
            raise ValueError("Axis must be 'x', 'y', or 'z'")
            
        return matrix
    
    @staticmethod
    def scale_matrix(sx: float, sy: float, sz: float = 1.0) -> np.ndarray:
        """Create a scaling matrix.
        
        Args:
            sx: Scale factor in x direction
            sy: Scale factor in y direction
            sz: Scale factor in z direction (1.0 for 2D)
            
        Returns:
            4x4 transformation matrix
        """
        return np.diag([sx, sy, sz, 1.0])
    
    @staticmethod
    def transform_point(point: Point, matrix: np.ndarray) -> Point:
        """Apply transformation matrix to a point.
        
        Args:
            point: Point to transform
            matrix: Transformation matrix (3x3 for 2D or 4x4 for 3D)
            
        Returns:
            Transformed point
        """
        # Convert to homogeneous coordinates
        coords = np.append(point.coords, 1.0)
        
        # Apply transformation
        if matrix.shape == (3, 3):  # 2D transformation
            coords = np.append(point.coords, 1.0)
            transformed = matrix @ coords
            new_coords = transformed[:-1] / transformed[-1]
        else:  # 3D transformation
            transformed = matrix @ coords
            new_coords = transformed[:-1] / transformed[-1]
            
        return Point(*new_coords) 