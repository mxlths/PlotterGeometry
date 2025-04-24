from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QFormLayout, QLabel, QLineEdit, QGroupBox, 
    QDoubleSpinBox, QHBoxLayout, QPushButton, QCheckBox, QColorDialog # Added Checkbox, ColorDialog
)
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QColor, QPalette
from functools import partial # For connecting signals with arguments
# Assuming LayerManager and Layer are in geometron.core.layer
from ...core.layer import LayerManager, Layer 

class LayerPropertiesPanel(QWidget):
    """UI Panel for editing general properties (Name, Transform, Style) of the active layer."""

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
        
        # --- Visibility/Lock ---
        status_layout = QHBoxLayout()
        self.visible_checkbox = QCheckBox("Visible")
        self.visible_checkbox.stateChanged.connect(self.on_visibility_changed)
        self.locked_checkbox = QCheckBox("Locked")
        self.locked_checkbox.stateChanged.connect(self.on_lock_changed)
        status_layout.addWidget(self.visible_checkbox)
        status_layout.addStretch()
        status_layout.addWidget(self.locked_checkbox)
        main_layout.addLayout(status_layout)
        
        # --- Transform Controls --- #
        transform_group = QGroupBox("Transform")
        transform_layout = QFormLayout(transform_group)
        
        # Position
        self.pos_x = QDoubleSpinBox()
        self.pos_x.setRange(-10000, 10000)
        self.pos_x.setDecimals(2)
        self.pos_x.setSingleStep(1.0)
        self.pos_x.valueChanged.connect(partial(self.on_transform_changed, 'pos_x'))
        
        self.pos_y = QDoubleSpinBox()
        self.pos_y.setRange(-10000, 10000)
        self.pos_y.setDecimals(2)
        self.pos_y.setSingleStep(1.0)
        self.pos_y.valueChanged.connect(partial(self.on_transform_changed, 'pos_y'))
        
        pos_layout = QHBoxLayout()
        pos_layout.addWidget(QLabel("X:"))
        pos_layout.addWidget(self.pos_x)
        pos_layout.addWidget(QLabel("Y:"))
        pos_layout.addWidget(self.pos_y)
        transform_layout.addRow("Position:", pos_layout)
        
        # Scale
        self.scale_x = QDoubleSpinBox()
        self.scale_x.setRange(0.01, 1000.0)
        self.scale_x.setDecimals(3)
        self.scale_x.setSingleStep(0.1)
        self.scale_x.setValue(1.0)
        self.scale_x.valueChanged.connect(partial(self.on_transform_changed, 'scale_x'))
        
        self.scale_y = QDoubleSpinBox()
        self.scale_y.setRange(0.01, 1000.0)
        self.scale_y.setDecimals(3)
        self.scale_y.setSingleStep(0.1)
        self.scale_y.setValue(1.0)
        self.scale_y.valueChanged.connect(partial(self.on_transform_changed, 'scale_y'))
        
        scale_layout = QHBoxLayout()
        scale_layout.addWidget(QLabel("X:"))
        scale_layout.addWidget(self.scale_x)
        scale_layout.addWidget(QLabel("Y:"))
        scale_layout.addWidget(self.scale_y)
        transform_layout.addRow("Scale:", scale_layout)
        
        # Rotation
        self.rotation = QDoubleSpinBox()
        self.rotation.setRange(-360*5, 360*5) # Allow multiple turns
        self.rotation.setDecimals(2)
        self.rotation.setSingleStep(5.0)
        self.rotation.setWrapping(True) # Wrap around
        self.rotation.valueChanged.connect(partial(self.on_transform_changed, 'rotation'))
        transform_layout.addRow("Rotation (°):", self.rotation)
        
        main_layout.addWidget(transform_group)

        # --- Style Controls --- #
        style_group = QGroupBox("Style")
        style_layout = QFormLayout(style_group)

        self.color_button = QPushButton("Change...")
        self.color_button.clicked.connect(self.on_color_button_clicked)
        self.color_swatch = QLabel()
        self.color_swatch.setFixedSize(40, 20)
        self.color_swatch.setAutoFillBackground(True)
        color_layout = QHBoxLayout()
        color_layout.addWidget(self.color_swatch)
        color_layout.addWidget(self.color_button)
        color_layout.addStretch()
        style_layout.addRow("Color:", color_layout)
        
        self.line_weight = QDoubleSpinBox()
        self.line_weight.setRange(0.01, 100.0)
        self.line_weight.setDecimals(2)
        self.line_weight.setSingleStep(0.1)
        self.line_weight.setValue(1.0)
        self.line_weight.valueChanged.connect(self.on_style_changed)
        style_layout.addRow("Weight:", self.line_weight)
        
        main_layout.addWidget(style_group)
        
        main_layout.addStretch() # Push everything up
        self.setLayout(main_layout)
        
    def set_current_layer(self, layer: Layer | None):
        """Update the panel to show properties for the given layer."""
        self._current_layer = layer
        self.update_ui_from_layer()

    def on_layer_updated(self, updated_layer: Layer):
        """Handle updates if the currently displayed layer changed."""
        if self._current_layer and updated_layer.id == self._current_layer.id:
            # print(f"LayerPropertiesPanel: Updating UI for layer {self._current_layer.name}") # DEBUG
            self.update_ui_from_layer()
            
    def update_ui_from_layer(self):
        """Refresh all UI elements from the self._current_layer."""
        self._is_updating_ui = True # Prevent signal loops
        
        is_enabled = self._current_layer is not None
        is_editable = is_enabled and not self._current_layer.locked
        
        # Enable/disable based on selection AND lock state
        self.setEnabled(is_enabled)
        self.name_edit.setEnabled(is_editable)
        # Allow toggling visibility/lock even when locked
        self.visible_checkbox.setEnabled(is_enabled) 
        self.locked_checkbox.setEnabled(is_enabled)
        # Disable editing widgets if locked
        self.pos_x.setEnabled(is_editable)
        self.pos_y.setEnabled(is_editable)
        self.scale_x.setEnabled(is_editable)
        self.scale_y.setEnabled(is_editable)
        self.rotation.setEnabled(is_editable)
        self.color_button.setEnabled(is_editable)
        self.line_weight.setEnabled(is_editable)
        
        if self._current_layer:
            layer = self._current_layer
            self.name_edit.setText(layer.name)
            self.visible_checkbox.setChecked(layer.visible)
            self.locked_checkbox.setChecked(layer.locked)
            
            # Update transform
            self.pos_x.setValue(layer.position.x)
            self.pos_y.setValue(layer.position.y)
            self.scale_x.setValue(layer.scale.x)
            self.scale_y.setValue(layer.scale.y)
            self.rotation.setValue(layer.rotation)
            
            # Update style 
            palette = self.color_swatch.palette()
            palette.setColor(QPalette.ColorRole.Window, QColor(*layer.line_color))
            self.color_swatch.setPalette(palette)
            self.line_weight.setValue(layer.line_weight)
            
        else:
            # Clear fields when no layer is selected
            self.name_edit.clear()
            self.visible_checkbox.setChecked(False)
            self.locked_checkbox.setChecked(False)
            self.pos_x.setValue(0)
            self.pos_y.setValue(0)
            self.scale_x.setValue(1)
            self.scale_y.setValue(1)
            self.rotation.setValue(0)
            palette = self.color_swatch.palette()
            palette.setColor(QPalette.ColorRole.Window, QColor("lightgrey"))
            self.color_swatch.setPalette(palette)
            self.line_weight.setValue(1)
            
        self._is_updating_ui = False
        
    # --- Signal Handlers for UI changes --- 

    def on_name_changed(self):
        if self._is_updating_ui or not self._current_layer: return
        new_name = self.name_edit.text()
        if new_name != self._current_layer.name:
             active_index = self.layer_manager.active_layer_index
             if active_index != -1:
                 self.layer_manager.rename_layer(active_index, new_name)

    def on_visibility_changed(self, state): 
        if self._is_updating_ui or not self._current_layer: return
        is_visible = state == Qt.CheckState.Checked.value
        if is_visible != self._current_layer.visible:
             active_index = self.layer_manager.active_layer_index
             if active_index != -1:
                 self.layer_manager.set_layer_visibility(active_index, is_visible)
                 
    def on_lock_changed(self, state):
        if self._is_updating_ui or not self._current_layer: return
        is_locked = state == Qt.CheckState.Checked.value
        if is_locked != self._current_layer.locked:
             active_index = self.layer_manager.active_layer_index
             if active_index != -1:
                 self.layer_manager.set_layer_lock(active_index, is_locked)
                 self.update_ui_from_layer() # Re-enable/disable controls immediately

    def on_transform_changed(self, control_name: str, value: float):
        if self._is_updating_ui or not self._current_layer: return
        active_index = self.layer_manager.active_layer_index
        if active_index == -1: return
        
        layer = self._current_layer
        changed = False
        if control_name == 'pos_x' and layer.position.x != value: layer.position.x = value; changed = True
        elif control_name == 'pos_y' and layer.position.y != value: layer.position.y = value; changed = True
        elif control_name == 'scale_x' and layer.scale.x != value: layer.scale.x = value; changed = True
        elif control_name == 'scale_y' and layer.scale.y != value: layer.scale.y = value; changed = True
        elif control_name == 'rotation' and layer.rotation != value: layer.rotation = value; changed = True
            
        if changed:
            # We can notify the manager directly or add specific methods
            # For now, let's just emit the generic update signal after changing the layer object
            layer.needs_update = True # Geometry likely needs update
            self.layer_manager.layer_updated.emit(layer) 
            print(f"DEBUG: Transform changed: {control_name} = {value}") # DEBUG
            
    def on_color_button_clicked(self):
        if self._is_updating_ui or not self._current_layer: return
        active_index = self.layer_manager.active_layer_index
        if active_index == -1: return

        layer = self._current_layer
        initial_color = QColor(*layer.line_color)
        color = QColorDialog.getColor(initial_color, self, "Select Line Color")
        
        if color.isValid() and color.getRgb()[:3] != layer.line_color:
            layer.line_color = color.getRgb()[:3]
            layer.needs_update = True # May affect rendering even if not geometry
            self.layer_manager.layer_updated.emit(layer)
            # Update swatch immediately
            palette = self.color_swatch.palette()
            palette.setColor(QPalette.ColorRole.Window, color)
            self.color_swatch.setPalette(palette)
            print(f"DEBUG: Color changed: {layer.line_color}") # DEBUG

    def on_style_changed(self):
        if self._is_updating_ui or not self._current_layer: return
        active_index = self.layer_manager.active_layer_index
        if active_index == -1: return
        
        layer = self._current_layer
        new_weight = self.line_weight.value()
        
        if layer.line_weight != new_weight:
            layer.line_weight = new_weight
            layer.needs_update = True # May affect rendering
            self.layer_manager.layer_updated.emit(layer)
            print(f"DEBUG: Weight changed: {new_weight}") # DEBUG 