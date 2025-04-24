from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
import numpy as np
from .geometry.primitives import Group
from .geometry.transform import Transform
import uuid
import math
from PyQt6.QtCore import QObject, pyqtSignal
from .algorithms.base import AlgorithmBase, AlgorithmParameter
from .algorithms.registry import AlgorithmRegistry

# Basic placeholder for geometry data or vectors if needed later
class Vector2D:
    def __init__(self, x=0.0, y=0.0):
        self.x = x
        self.y = y

@dataclass
class Layer:
    """A layer containing geometry and associated properties.
    
    Attributes:
        name: Layer name
        geometry: Group containing all geometry in this layer
        visible: Whether the layer is visible
        locked: Whether the layer is locked for editing
        opacity: Layer opacity (0.0 to 1.0)
        transform: Transformation matrix for the entire layer
    """
    name: str
    geometry: Group
    visible: bool = True
    locked: bool = False
    opacity: float = 1.0
    transform: Optional[np.ndarray] = None
    
    def __post_init__(self):
        """Initialize default values."""
        if self.transform is None:
            # Determine if layer contains 3D geometry
            is_3d = any(hasattr(elem, 'is_3d') and elem.is_3d 
                       for elem in self.geometry.elements)
            self.transform = np.eye(4 if is_3d else 3)
    
    def apply_transform(self, matrix: np.ndarray) -> None:
        """Apply a transformation to the layer.
        
        Args:
            matrix: Transformation matrix to apply
        """
        self.transform = matrix @ self.transform
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert layer to dictionary for serialization."""
        return {
            'name': self.name,
            'visible': self.visible,
            'locked': self.locked,
            'opacity': self.opacity,
            'transform': self.transform.tolist(),
            # Geometry serialization will be handled by geometry classes
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any], registry: AlgorithmRegistry) -> 'Layer | None':
        """Create layer from dictionary."""
        algo_name = data.get("algorithm_name")
        algorithm_instance = None
        if algo_name:
            algorithm_instance = registry.create_algorithm_instance(algo_name)
            if not algorithm_instance:
                 print(f"Warning: Could not find or create algorithm '{algo_name}' during load.")
                 # Optionally return None or create a layer without an algorithm
                 # return None 

        # Create layer, passing the algorithm instance
        layer = cls(
            name=data.get("name"),
            geometry=Group([]),  # Placeholder, geometry loaded separately
            visible=data.get('visible', True),
            locked=data.get('locked', False),
            opacity=data.get('opacity', 1.0),
            transform=np.array(data.get('transform', None))
        )
        
        layer.id = uuid.UUID(data.get("id", str(uuid.uuid4()))) # Ensure ID exists
        layer.algorithm = algorithm_instance # Store the algorithm *instance*
        layer.parameters = data.get("parameters", {}) # Parameters specific to this layer instance
        if layer.algorithm:
             # Initialize parameters with defaults from the algorithm class
             for param_def in layer.algorithm.get_parameters():
                 layer.parameters[param_def.name] = param_def.default
             layer.name = layer.name or layer.algorithm.get_name() # Default name from algo
        else:
             layer.name = layer.name or f"Layer {str(layer.id)[:4]}"
        
        # Transformation properties
        pos = data.get("position", [0, 0])
        layer.position = Vector2D(pos[0], pos[1])
        scale = data.get("scale", [1, 1])
        layer.scale = Vector2D(scale[0], scale[1])
        layer.rotation = data.get("rotation", 0.0) # In degrees
        
        # Styling properties
        layer.line_color = tuple(data.get("line_color", [0, 0, 0]))
        layer.line_weight = data.get("line_weight", 1.0)
        
        # Cache - Placeholder for now
        layer.geometry_cache = None
        layer.needs_update = True
        
        return layer


class LayerManager(QObject):
    """Manages a collection of layers and their ordering.
    
    Attributes:
        layers: List of layers in order from bottom to top
        active_layer: Currently selected layer
    """
    def __init__(self, algorithm_registry: AlgorithmRegistry):
        super().__init__()
        self.layers: List[Layer] = []
        self._active_layer_index = -1
        self.algorithm_registry = algorithm_registry # Store registry
    
    @property
    def active_layer_index(self):
        return self._active_layer_index

    @active_layer_index.setter
    def active_layer_index(self, index):
        count = len(self.layers)
        new_index = -1
        if 0 <= index < count:
            new_index = index
        
        if self._active_layer_index != new_index:
            self._active_layer_index = new_index
            self.active_layer_changed.emit(self.get_active_layer())

    def add_layer(self, algorithm_name: str | None = None, index: int | None = None):
        """Add a new layer using an algorithm from the registry."""
        algorithm_instance = None
        if algorithm_name:
             algorithm_instance = self.algorithm_registry.create_algorithm_instance(algorithm_name)
             if not algorithm_instance:
                 print(f"Error: Could not create algorithm '{algorithm_name}'")
                 return None # Failed to add layer
        # If no name provided, create a layer without an algorithm (or handle error)
        # For now, let's allow algorithm=None for a basic layer
        
        layer = Layer(algorithm=algorithm_instance)
        
        if index is None or index < 0 or index > len(self.layers):
            self.layers.append(layer)
            new_index = len(self.layers) - 1
        else:
            self.layers.insert(index, layer)
            new_index = index

        self.active_layer_index = new_index
        self.layers_changed.emit()
        print(f"Added layer '{layer.name}' at index {new_index}")
        return layer
        
    def remove_layer(self, index: int):
        """Remove a layer.
        
        Args:
            index: Index of layer to remove
        """
        if 0 <= index < len(self.layers):
             layer = self.layers.pop(index)
             # Update active index logic (careful)
             current_active = self._active_layer_index
             new_active = -1
             if len(self.layers) > 0:
                 if current_active == index: # We removed the active layer
                     new_active = max(0, index - 1) # Try selecting layer before
                 elif current_active > index: # We removed a layer before the active one
                     new_active = current_active - 1
                 else: # We removed a layer after the active one
                     new_active = current_active
             
             # Use the setter to emit signal if changed
             self.active_layer_index = new_active 
             
             self.layers_changed.emit()
             print(f"Removed layer '{layer.name}'")
             return layer
        return None

    def duplicate_layer(self, index: int):
        """Duplicate a layer at the specified index."""
        if 0 <= index < len(self.layers):
            source_layer = self.layers[index]
            layer_data = source_layer.as_dict()
            # Use from_dict which now handles algorithm lookup via registry
            new_layer = Layer.from_dict(layer_data, self.algorithm_registry)
            if new_layer:
                 new_layer.id = uuid.uuid4() # Ensure a new unique ID
                 new_layer.name = f"{source_layer.name} Copy"
                 
                 # Insert after the source layer
                 insert_pos = index + 1
                 self.layers.insert(insert_pos, new_layer)
                 self.active_layer_index = insert_pos # Make duplicate active
                 self.layers_changed.emit()
                 print(f"Duplicated layer '{new_layer.name}' at index {insert_pos}")
                 return new_layer
            else:
                 print("Error: Failed to duplicate layer (could not create from dict).")
        return None

    def move_layer(self, from_index: int, to_index: int):
         """Move a layer to a new position.
         
         Args:
             from_index: Index of layer to move
             to_index: New position in layer stack
         """
         count = len(self.layers)
         # Clamp to_index to valid range for insertion
         to_index_clamped = max(0, min(to_index, count))
         
         if 0 <= from_index < count and from_index != to_index_clamped:
             layer = self.layers.pop(from_index)
             
             # Adjust target index if removing from before affects the insert position
             insert_pos = to_index_clamped
             if from_index < to_index_clamped:
                 insert_pos -= 1
             
             self.layers.insert(insert_pos, layer)
             
             # Update active layer index if it was the one moved
             current_active = self._active_layer_index
             new_active = current_active
             if current_active == from_index:
                 new_active = insert_pos
             elif from_index < current_active <= insert_pos:
                 new_active = current_active - 1
             elif insert_pos <= current_active < from_index:
                 new_active = current_active + 1

             # Use setter for active index
             self.active_layer_index = new_active
             
             self.layers_changed.emit()
             print(f"Moved layer from {from_index} to {insert_pos}")
             return True
         return False

    def get_visible_layers(self) -> List[Layer]:
        """Get list of visible layers in order."""
        return [layer for layer in self.layers if layer.visible]
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert layer manager state to dictionary."""
        return {
            'layers': [layer.to_dict() for layer in self.layers],
            'active_layer_index': self.active_layer_index
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any], registry: AlgorithmRegistry) -> 'LayerManager':
        """Create layer manager from dictionary."""
        manager = cls(registry)
        for layer_data in data.get('layers', []):
            layer = Layer.from_dict(layer_data, registry)
            if layer: # Only add if creation succeeded
                 manager.layers.append(layer)
            
        # Set active layer index after loading all layers
        loaded_index = data.get("active_layer_index", -1)
        # Don't use setter here as we don't want signal on load
        if 0 <= loaded_index < len(manager.layers):
            manager._active_layer_index = loaded_index
        else:
             manager._active_layer_index = -1 if len(manager.layers) == 0 else 0

        print(f"Loaded {len(manager.layers)} layers. Active index: {manager._active_layer_index}")
        return manager

    def get_active_layer(self):
        """Get the currently active layer object, or None."""
        if 0 <= self.active_layer_index < len(self.layers):
            return self.layers[self.active_layer_index]
        return None

    def set_active_layer_by_id(self, layer_id):
        """Set the active layer by its UUID."""
        for i, layer in enumerate(self.layers):
            if layer.id == layer_id:
                self.active_layer_index = i
                return True
        return False

    # --- Methods for modifying layer properties ---
    # These methods ensure the layer_updated signal is emitted

    def set_layer_parameter(self, index: int, param_name: str, value: Any):
        if 0 <= index < len(self.layers):
            layer = self.layers[index]
            if layer.locked:
                 print(f"Layer '{layer.name}' is locked.")
                 return False
            layer.set_parameter(param_name, value)
            self.layer_updated.emit(layer)
            return True
        return False

    def set_layer_visibility(self, index, visible):
        if 0 <= index < len(self.layers):
            layer = self.layers[index]
            if layer.visible != visible:
                layer.visible = visible
                self.layer_updated.emit(layer)
                return True
        return False

    def set_layer_lock(self, index, locked):
        if 0 <= index < len(self.layers):
            layer = self.layers[index]
            if layer.locked != locked:
                layer.locked = locked
                self.layer_updated.emit(layer)
                return True
        return False

    def rename_layer(self, index, name):
         if 0 <= index < len(self.layers):
            layer = self.layers[index]
            if layer.name != name:
                layer.name = name
                self.layer_updated.emit(layer)
                # Also emit layers_changed as the name appears in the list
                self.layers_changed.emit()
                return True
         return False

    # --- Serialization ---
    def as_dict(self) -> Dict[str, Any]:
        """Convert all layers to dictionary for serialization."""
        return {
            "layers": [layer.as_dict() for layer in self.layers],
            "active_layer_index": self.active_layer_index
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any], registry: AlgorithmRegistry) -> 'LayerManager':
        """Create a layer manager from serialized data."""
        manager = cls(registry)
        for layer_data in data.get("layers", []):
            layer = Layer.from_dict(layer_data, registry)
            if layer: # Only add if creation succeeded
                 manager.layers.append(layer)
            
        # Set active layer index after loading all layers
        loaded_index = data.get("active_layer_index", -1)
        # Don't use setter here as we don't want signal on load
        if 0 <= loaded_index < len(manager.layers):
            manager._active_layer_index = loaded_index
        else:
             manager._active_layer_index = -1 if len(manager.layers) == 0 else 0

        print(f"Loaded {len(manager.layers)} layers. Active index: {manager._active_layer_index}")
        return manager 