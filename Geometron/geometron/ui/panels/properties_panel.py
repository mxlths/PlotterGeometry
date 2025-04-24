from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QFormLayout, QLabel, QLineEdit, QGroupBox, 
    QDoubleSpinBox, QHBoxLayout, QPushButton
)
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QColor, QPalette
# Assuming LayerManager and Layer are in geometron.core.layer
from ...core.layer import LayerManager, Layer 

class PropertiesPanel(QWidget):
    """UI Panel for editing properties of the active layer."""

    def __init__(self, layer_manager: LayerManager, parent=None):
        super().__init__(parent)
        self.layer_manager = layer_manager
        
        self._current_layer: Layer | None = None
        self._is_updating_ui = False # Flag to prevent signal loops

        self.setup_ui()
        
        # Connect signals from LayerManager
        self.layer_manager.active_layer_changed.connect(self.set_current_layer)
        self.layer_manager.layer_updated.connect(self.on_layer_updated) # Update if current layer changes

        # Initial population based on current active layer
        self.set_current_layer(self.layer_manager.get_active_layer())

    def setup_ui(self):
        """Set up the panel UI with placeholders."""
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(5, 5, 5, 5)
        main_layout.setSpacing(10)
        
        # --- Layer Name ---
        name_layout = QHBoxLayout()
        name_layout.addWidget(QLabel("Name:"))
        self.name_edit = QLineEdit()
        self.name_edit.editingFinished.connect(self.on_name_changed)
        name_layout.addWidget(self.name_edit)
        main_layout.addLayout(name_layout)
        
        # --- Visibility/Lock (Placeholders - maybe use checkboxes later) ---
        status_layout = QHBoxLayout()
        self.visible_label = QLabel("Visible: Yes")
        self.locked_label = QLabel("Locked: No")
        status_layout.addWidget(self.visible_label)
        status_layout.addStretch()
        status_layout.addWidget(self.locked_label)
        main_layout.addLayout(status_layout)
        
        # --- Transform Controls (Placeholders) ---
        transform_group = QGroupBox("Transform")
        transform_layout = QFormLayout(transform_group)
        
        self.pos_x = QDoubleSpinBox() # Placeholder values
        self.pos_y = QDoubleSpinBox()
        pos_layout = QHBoxLayout()
        pos_layout.addWidget(self.pos_x)
        pos_layout.addWidget(self.pos_y)
        transform_layout.addRow("Position (X,Y):", pos_layout)
        
        self.scale_x = QDoubleSpinBox()
        self.scale_y = QDoubleSpinBox()
        scale_layout = QHBoxLayout()
        scale_layout.addWidget(self.scale_x)
        scale_layout.addWidget(self.scale_y)
        transform_layout.addRow("Scale (X,Y):", scale_layout)
        
        self.rotation = QDoubleSpinBox()
        transform_layout.addRow("Rotation (°):", self.rotation)
        
        main_layout.addWidget(transform_group)

        # --- Style Controls (Placeholders) ---
        style_group = QGroupBox("Style")
        style_layout = QFormLayout(style_group)

        self.color_swatch = QLabel()
        self.color_swatch.setFixedSize(40, 20)
        self.color_swatch.setAutoFillBackground(True)
        style_layout.addRow("Color:", self.color_swatch)
        
        self.line_weight = QDoubleSpinBox()
        style_layout.addRow("Weight:", self.line_weight)
        
        main_layout.addWidget(style_group)
        
        # --- Algorithm Parameters Container ---
        self.algorithm_group = QGroupBox("Algorithm Parameters")
        self.algorithm_layout = QVBoxLayout(self.algorithm_group)
        # We will populate this dynamically later
        self.algorithm_layout.addWidget(QLabel("(Parameters appear here)"))
        self.algorithm_layout.addStretch()
        main_layout.addWidget(self.algorithm_group)

        main_layout.addStretch() # Push everything up
        self.setLayout(main_layout)
        
    def set_current_layer(self, layer: Layer | None):
        """Update the panel to show properties for the given layer."""
        self._current_layer = layer
        self.update_ui_from_layer()

    def on_layer_updated(self, updated_layer: Layer):
        """Handle updates if the currently displayed layer changed."""
        if self._current_layer and updated_layer.id == self._current_layer.id:
            print(f"PropertiesPanel: Updating UI for layer {self._current_layer.name}")
            self.update_ui_from_layer()
            
    def update_ui_from_layer(self):
        """Refresh all UI elements from the self._current_layer."""
        self._is_updating_ui = True # Prevent signal loops
        
        is_enabled = self._current_layer is not None
        self.setEnabled(is_enabled)
        
        if self._current_layer:
            layer = self._current_layer
            self.name_edit.setText(layer.name)
            self.visible_label.setText(f"Visible: {'Yes' if layer.visible else 'No'}")
            self.locked_label.setText(f"Locked: {'Yes' if layer.locked else 'No'}")
            
            # Update transform placeholders (actual connection later)
            self.pos_x.setValue(layer.position.x)
            self.pos_y.setValue(layer.position.y)
            self.scale_x.setValue(layer.scale.x)
            self.scale_y.setValue(layer.scale.y)
            self.rotation.setValue(layer.rotation)
            
            # Update style placeholders (actual connection later)
            palette = self.color_swatch.palette()
            palette.setColor(QPalette.ColorRole.Window, QColor(*layer.line_color))
            self.color_swatch.setPalette(palette)
            self.line_weight.setValue(layer.line_weight)
            
            # Update algorithm section (placeholder)
            self.update_algorithm_ui()
            
        else:
            # Clear fields when no layer is selected
            self.name_edit.clear()
            self.visible_label.setText("Visible: -")
            self.locked_label.setText("Locked: -")
            # Clear or reset other fields as needed
            self.pos_x.setValue(0)
            self.pos_y.setValue(0)
            self.scale_x.setValue(1)
            self.scale_y.setValue(1)
            self.rotation.setValue(0)
            palette = self.color_swatch.palette()
            palette.setColor(QPalette.ColorRole.Window, QColor("lightgrey"))
            self.color_swatch.setPalette(palette)
            self.line_weight.setValue(1)
            self.update_algorithm_ui() # Clear algorithm UI too
            
        self._is_updating_ui = False
        
    def update_algorithm_ui(self):
        """Clear and potentially repopulate the algorithm parameter UI (Placeholder)."""
        # Clear existing algorithm widgets
        while self.algorithm_layout.count() > 0:
             item = self.algorithm_layout.takeAt(0)
             widget = item.widget()
             if widget:
                 widget.deleteLater()
                 
        if self._current_layer and self._current_layer.algorithm:
             algo = self._current_layer.algorithm
             params = self._current_layer.parameters
             self.algorithm_group.setTitle(f"Parameters: {algo.get_name()}")
             
             # TODO: Dynamically create widgets based on algo.get_parameters()
             param_form_layout = QFormLayout()
             # Example: Add parameter widgets dynamically
             for param_def in algo.get_parameters():
                  # Create appropriate widget based on param_def.type
                  # Connect its changed signal to self.on_parameter_changed
                  # Set its initial value from params[param_def.name]
                  placeholder_label = QLabel(f"{param_def.name}: {params.get(param_def.name)} ({param_def.type})")
                  param_form_layout.addRow(f"{param_def.name}:", placeholder_label)
             
             self.algorithm_layout.addLayout(param_form_layout)
             self.algorithm_layout.addStretch()
             self.algorithm_group.setVisible(True)
        else:
             self.algorithm_group.setTitle("Algorithm Parameters")
             self.algorithm_group.setVisible(False) # Hide if no algorithm

    # --- Signal Handlers for UI changes --- 

    def on_name_changed(self):
        """Handle editing finished for the name field."""
        if self._is_updating_ui or not self._current_layer:
             return
        
        new_name = self.name_edit.text()
        if new_name != self._current_layer.name:
             # Call LayerManager method to rename, which emits signals
             active_index = self.layer_manager.active_layer_index
             if active_index != -1:
                 self.layer_manager.rename_layer(active_index, new_name)
                 # The rename_layer signal will trigger on_layer_updated -> update_ui_from_layer

    # TODO: Add handlers for transform/style changes (pos_x.valueChanged etc.)
    # These handlers would call corresponding LayerManager methods 
    # e.g., self.layer_manager.set_layer_position(index, x, y)
    # and the manager would emit layer_updated.
    
    # TODO: Add handler for algorithm parameter changes
    # def on_parameter_changed(self, param_name, value):
    #     if self._is_updating_ui or not self._current_layer:
    #          return
    #     active_index = self.layer_manager.active_layer_index
    #     if active_index != -1:
    #          self.layer_manager.set_layer_parameter(active_index, param_name, value) 