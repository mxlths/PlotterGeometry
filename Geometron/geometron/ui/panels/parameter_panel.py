from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QFormLayout, QLabel, QLineEdit, QGroupBox, 
    QDoubleSpinBox, QSpinBox, QCheckBox, QPushButton, QComboBox, 
    QSizePolicy
)
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QColor, QPalette
from functools import partial
from typing import Any

from ...core.layer import LayerManager, Layer 
from ...core.algorithms.base import AlgorithmParameter

class ParameterPanel(QWidget):
    """UI Panel for editing Algorithm parameters of the active layer."""

    def __init__(self, layer_manager: LayerManager, parent=None):
        super().__init__(parent)
        self.layer_manager = layer_manager
        
        self._current_layer: Layer | None = None
        self._is_updating_ui = False # Flag to prevent signal loops
        self._param_widgets = {} # Store created widgets: {param_name: widget}

        self.setup_ui()
        
        # Connect signals from LayerManager
        self.layer_manager.active_layer_changed.connect(self.set_current_layer)
        self.layer_manager.layer_updated.connect(self.on_layer_updated) 

        # Initial population
        self.set_current_layer(self.layer_manager.get_active_layer())

    def setup_ui(self):
        """Set up the panel UI structure."""
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(5, 5, 5, 5)
        main_layout.setSpacing(10)

        self.algorithm_group = QGroupBox("Algorithm Parameters")
        # Use QFormLayout for label-widget pairs
        self.param_form_layout = QFormLayout(self.algorithm_group)
        self.param_form_layout.setFieldGrowthPolicy(QFormLayout.FieldGrowthPolicy.ExpandingFieldsGrow)
        self.param_form_layout.setLabelAlignment(Qt.AlignmentFlag.AlignLeft)
        self.param_form_layout.setRowWrapPolicy(QFormLayout.RowWrapPolicy.WrapLongRows)
        
        main_layout.addWidget(self.algorithm_group)
        main_layout.addStretch() # Push group to the top
        self.setLayout(main_layout)
        
    def set_current_layer(self, layer: Layer | None):
        """Update the panel to show parameters for the given layer."""
        self._current_layer = layer
        self.update_parameter_ui()

    def on_layer_updated(self, updated_layer: Layer):
        """Handle updates if the currently displayed layer changed, potentially parameter values."""
        if self._current_layer and updated_layer.id == self._current_layer.id:
            # print(f"ParameterPanel: Updating UI for layer {self._current_layer.name}") # DEBUG
            # Re-populate UI in case parameters were changed externally (less efficient but safer)
            # A more optimized way would be to only update specific widgets if needed.
            self.update_parameter_ui()
            
    def update_parameter_ui(self):
        """Clear and repopulate the algorithm parameter UI."""
        self._is_updating_ui = True
        
        # Clear existing algorithm widgets from the form layout
        while self.param_form_layout.count() > 0:
             self.param_form_layout.removeRow(0)
        self._param_widgets.clear()
                 
        is_enabled = self._current_layer is not None and not self._current_layer.locked
        self.setEnabled(is_enabled) # Enable/disable the whole panel
        self.algorithm_group.setEnabled(is_enabled) 
                 
        if self._current_layer and self._current_layer.algorithm:
             algo = self._current_layer.algorithm
             params = self._current_layer.parameters
             param_defs = algo.get_parameters()
             
             self.algorithm_group.setTitle(f"Parameters: {algo.get_name()}")
             self.algorithm_group.setVisible(True)
             
             # Dynamically create widgets based on parameter definitions
             for param_def in param_defs:
                 widget = self.create_widget_for_parameter(param_def, params.get(param_def.name))
                 if widget:
                      label = QLabel(f"{param_def.name}:")
                      label.setToolTip(param_def.description)
                      self.param_form_layout.addRow(label, widget)
                      self._param_widgets[param_def.name] = widget # Store widget reference
                      
        else:
             self.algorithm_group.setTitle("Algorithm Parameters")
             self.algorithm_group.setVisible(False) # Hide if no layer/algorithm
             
        self._is_updating_ui = False
        
    def create_widget_for_parameter(self, param_def: AlgorithmParameter, current_value: Any) -> QWidget | None:
        """Creates the appropriate Qt widget based on parameter type."""
        widget = None
        param_type = param_def.type.lower()
        param_name = param_def.name
        options = param_def.options

        if param_type == 'int':
            widget = QSpinBox()
            widget.setRange(options.get('min', -2147483648), options.get('max', 2147483647))
            widget.setSingleStep(options.get('step', 1))
            widget.setValue(current_value if current_value is not None else param_def.default)
            widget.valueChanged.connect(partial(self.on_parameter_changed, param_name))
        elif param_type == 'float':
            widget = QDoubleSpinBox()
            widget.setRange(options.get('min', -float('inf')), options.get('max', float('inf')))
            widget.setDecimals(options.get('decimals', 3))
            widget.setSingleStep(options.get('step', 0.1))
            widget.setValue(current_value if current_value is not None else param_def.default)
            widget.valueChanged.connect(partial(self.on_parameter_changed, param_name))
        elif param_type == 'bool':
            widget = QCheckBox()
            widget.setChecked(current_value if current_value is not None else param_def.default)
            widget.stateChanged.connect(partial(self.on_parameter_changed, param_name))
        elif param_type == 'string':
            widget = QLineEdit()
            widget.setText(current_value if current_value is not None else param_def.default)
            widget.editingFinished.connect(partial(self.on_parameter_changed, param_name))
        elif param_type == 'combo' or param_type == 'choice':
            widget = QComboBox()
            items = options.get('items', [])
            if items:
                 widget.addItems(items)
            current_text = str(current_value if current_value is not None else param_def.default)
            widget.setCurrentText(current_text)
            widget.currentTextChanged.connect(partial(self.on_parameter_changed, param_name))
        # Add more types like 'color', 'file' etc. here later
        else:
             print(f"Warning: Unsupported parameter type '{param_type}' for '{param_name}'")
             widget = QLabel(f"(Unsupported type: {param_type})")
             
        if widget:
            widget.setToolTip(param_def.description)
            
        return widget
        
    # --- Signal Handler --- 

    def on_parameter_changed(self, param_name: str, value=None):
        """Handle value changes from any parameter widget."""
        if self._is_updating_ui or not self._current_layer: 
             print(f"DEBUG: Param changed ({param_name}), but UI is updating or no layer.")
             return
        
        widget = self._param_widgets.get(param_name)
        if not widget: return

        # Get the current value from the widget that emitted the signal
        actual_value = None
        if isinstance(widget, (QSpinBox, QDoubleSpinBox)):
             actual_value = widget.value()
        elif isinstance(widget, QCheckBox):
             # stateChanged provides the state enum, we need bool
             actual_value = widget.isChecked() 
        elif isinstance(widget, QLineEdit):
             actual_value = widget.text()
        elif isinstance(widget, QComboBox):
             actual_value = widget.currentText()
             
        print(f"DEBUG: Parameter '{param_name}' changed to: {actual_value} (Widget: {type(widget)})")

        # Check if value actually changed compared to layer's current value
        if self._current_layer.parameters.get(param_name) != actual_value:
            active_index = self.layer_manager.active_layer_index
            if active_index != -1:
                 # Update the layer via the manager
                 print(f"  >> Updating layer manager for {param_name} = {actual_value}")
                 self.layer_manager.set_layer_parameter(active_index, param_name, actual_value)
                 # The manager will emit layer_updated, which might trigger on_layer_updated -> update_parameter_ui
        else:
             print(f"  >> Value {actual_value} is same as current, no update needed.") 