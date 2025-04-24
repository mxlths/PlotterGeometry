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

# --- Reinstating Layer class structure from e932368c --- 
class Layer:
    """Represents a single layer in the composition."""
    
    def __init__(self, algorithm: Optional[AlgorithmBase] = None, name: Optional[str] = None):
        self.id = uuid.uuid4()  # Unique identifier
        self.algorithm = algorithm # Store the algorithm *instance*
        self.parameters = {} # Parameters specific to this layer instance
        if self.algorithm:
             # Initialize parameters with defaults from the algorithm class
             for param_def in self.algorithm.get_parameters():
                 self.parameters[param_def.name] = param_def.default
             self.name = name or self.algorithm.get_name() # Default name from algo
        else:
             self.name = name or f"Layer {str(self.id)[:4]}"
             
        self.visible = True
        self.locked = False
        
        # Transformation properties
        self.position = Vector2D(0, 0)
        self.scale = Vector2D(1, 1)
        self.rotation = 0.0  # In degrees
        
        # Styling properties
        self.line_color = (0, 0, 0)  # RGB tuple (0-255)
        self.line_weight = 1.0
        
        # Cache - Placeholder for now
        self.geometry_cache = None
        self.needs_update = True
        
    def set_parameter(self, param_name: str, value: Any):
        """Set a parameter value and mark layer for update."""
        if param_name in self.parameters:
             if self.parameters[param_name] != value:
                 self.parameters[param_name] = value
                 self.needs_update = True
                 # LayerManager should emit layer_updated after this call
        else:
             print(f"Warning: Parameter '{param_name}' not found for layer '{self.name}'")
             
    def update_geometry(self):
        """Regenerate geometry if needed."""
        if self.needs_update and self.algorithm:
            try:
                self.geometry_cache = self.algorithm.generate_geometry(self.parameters)
                self.needs_update = False
                print(f"Layer '{self.name}' geometry updated.")
            except Exception as e:
                 print(f"Error generating geometry for layer '{self.name}': {e}")
                 self.geometry_cache = None # Ensure cache is cleared on error
                 # Keep needs_update True so it retries later?
        elif not self.algorithm:
             self.geometry_cache = None
             self.needs_update = False # Nothing to update

    def get_geometry(self):
        """Get the transformed geometry of this layer."""
        self.update_geometry() # Ensure cache is up-to-date
        
        if self.geometry_cache:
            # TODO: Implement actual geometry transformation
            # Create a copy of the geometry
            # transformed = self.geometry_cache.copy()
            
            # Apply transformations (using matrix math eventually)
            # transform_matrix = Matrix.identity()
            # transform_matrix.translate(self.position.x, self.position.y)
            # transform_matrix.rotate(math.radians(self.rotation))
            # transform_matrix.scale(self.scale.x, self.scale.y)
            # transformed.transform(transform_matrix)
            # return transformed
            return self.geometry_cache # Return untransformed for now
            
        return None

    def as_dict(self):
        """Convert layer to dictionary for serialization."""
        return {
            "id": str(self.id),
            "name": self.name,
            "algorithm_name": self.algorithm.get_name() if self.algorithm else None,
            "parameters": self.parameters,
            "visible": self.visible,
            "locked": self.locked,
            "position": [self.position.x, self.position.y],
            "scale": [self.scale.x, self.scale.y],
            "rotation": self.rotation,
            "line_color": list(self.line_color),
            "line_weight": self.line_weight
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any], registry: AlgorithmRegistry) -> 'Layer | None':
        """Create a layer from serialized data using the registry."""
        algo_name = data.get("algorithm_name")
        algorithm_instance = None
        if algo_name:
            algorithm_instance = registry.create_algorithm_instance(algo_name)
            if not algorithm_instance:
                 print(f"Warning: Could not find or create algorithm '{algo_name}' during load.")
                 # Optionally return None or create a layer without an algorithm
                 # return None 

        # Create layer, passing the algorithm instance
        layer = cls(algorithm=algorithm_instance, name=data.get("name"))
        
        layer.id = uuid.UUID(data.get("id", str(uuid.uuid4()))) # Ensure ID exists
        layer.visible = data.get("visible", True)
        layer.locked = data.get("locked", False)
        
        pos = data.get("position", [0, 0])
        layer.position = Vector2D(pos[0], pos[1])
        
        scale = data.get("scale", [1, 1])
        layer.scale = Vector2D(scale[0], scale[1])
        
        layer.rotation = data.get("rotation", 0.0)
        
        layer.line_color = tuple(data.get("line_color", [0, 0, 0]))
        layer.line_weight = data.get("line_weight", 1.0)
        
        # Set parameters *after* creating layer with defaults
        layer.parameters = data.get("parameters", {}) 
        # We might want to validate loaded parameters against algorithm definition here
        
        layer.needs_update = True # Assume update needed after loading
        return layer
# --- End Reinstated Layer Class --- 

# --- LayerManager remains the same --- 
class LayerManager(QObject):
    """Manages a collection of layers and their ordering.
    
    Attributes:
        layers: List of layers in order from bottom to top
        active_layer: Currently selected layer
    """

    # --- Define Signals as Class Attributes --- #
    layers_changed = pyqtSignal() # Emitted when layers are added, removed, or reordered
    active_layer_changed = pyqtSignal(object) # Emitted with the new active Layer object (or None)
    layer_updated = pyqtSignal(object) # Emitted with the updated Layer object
    # --- End Signal Definitions --- #

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