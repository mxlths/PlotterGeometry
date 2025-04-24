from PyQt6.QtWidgets import (QMainWindow, QDockWidget, QWidget, QVBoxLayout,
                            QToolBar, QStatusBar, QLabel)
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QPalette, QColor
import pyqtgraph as pg
from .canvas.canvas_widget import CanvasWidget
from ..core.layer import LayerManager
from ..core.algorithms.registry import AlgorithmRegistry
from .panels.layer_panel import LayerPanel
from .panels.properties_panel import PropertiesPanel
import sys

class MainWindow(QMainWindow):
    """Main window of the Geometron application."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Geometron")
        self.setMinimumSize(1200, 800)
        
        # Create core components
        self.algorithm_registry = AlgorithmRegistry()
        self.layer_manager = LayerManager(self.algorithm_registry)
        
        # Set white background for the main window
        palette = self.palette()
        palette.setColor(QPalette.ColorRole.Window, QColor('white'))
        self.setPalette(palette)
        self.setAutoFillBackground(True)
        
        # Create central canvas
        self.canvas = CanvasWidget()
        self.setCentralWidget(self.canvas)
        
        # Connect canvas signals
        self.canvas.size_changed.connect(self._on_canvas_size_changed)
        
        # Create and setup panels
        self._create_toolbar()
        self._create_layer_panel()
        self._create_parameter_panel()
        self._create_global_parameter_panel()
        self._create_properties_panel()
        self._create_status_bar()
        
        # Set initial panel sizes
        self._setup_panel_sizes()
        
        # Apply stylesheet for dock widgets
        self.setStyleSheet("""
            QDockWidget::title {
                background-color: grey;
                color: white;
                border: 1px solid black;
                padding: 4px;
            }
            QDockWidget {
                border: 1px solid black;
            }
        """)
        
        # Update status bar with initial canvas size
        self._update_canvas_size_status(self.canvas.width_spin.value(), self.canvas.height_spin.value())
    
    def _on_canvas_size_changed(self, width, height):
        """Handle canvas size changes."""
        self._update_canvas_size_status(width, height)
    
    def _update_canvas_size_status(self, width, height):
        """Update the canvas size in the status bar."""
        self.status_bar.showMessage(f"Canvas: {width}x{height} | Zoom: 100% | Tool: None")
    
    def _create_toolbar(self):
        """Create the top toolbar."""
        self.toolbar = QToolBar("Tools")
        self.toolbar.setMovable(False)
        self.addToolBar(Qt.ToolBarArea.TopToolBarArea, self.toolbar)
        
        # Add placeholder buttons (will be implemented later)
        self.toolbar.addAction("Move")
        self.toolbar.addAction("Rotate")
        self.toolbar.addAction("Align")
        self.toolbar.addAction("Center")
    
    def _create_layer_panel(self):
        """Create the layer panel on the right side."""
        self.layer_panel_dock = QDockWidget("Layers", self)
        self.layer_panel_dock.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        
        self.layer_panel_widget = LayerPanel(self.layer_manager)
        self.layer_panel_dock.setWidget(self.layer_panel_widget)
        
        self.addDockWidget(Qt.DockWidgetArea.RightDockWidgetArea, self.layer_panel_dock)
    
    def _create_parameter_panel(self):
        """Create the algorithm parameter panel."""
        self.parameter_panel = QDockWidget("Parameters", self)
        self.parameter_panel.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        
        param_content = QWidget()
        param_layout = QVBoxLayout()
        param_content.setLayout(param_layout)
        param_layout.addWidget(QLabel("Algorithm Parameters (Placeholder)"))
        param_layout.addStretch()
        
        self.parameter_panel.setWidget(param_content)
        self.addDockWidget(Qt.DockWidgetArea.RightDockWidgetArea, self.parameter_panel)
    
    def _create_global_parameter_panel(self):
        """Create the global parameter panel."""
        self.global_param_panel = QDockWidget("Global Parameters", self)
        self.global_param_panel.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        
        global_param_content = QWidget()
        global_param_layout = QVBoxLayout()
        global_param_content.setLayout(global_param_layout)
        global_param_layout.addWidget(QLabel("Global Parameters Table (Placeholder)"))
        global_param_layout.addStretch()
        
        self.global_param_panel.setWidget(global_param_content)
        self.addDockWidget(Qt.DockWidgetArea.RightDockWidgetArea, self.global_param_panel)
    
    def _create_properties_panel(self):
        """Create the layer properties panel."""
        self.properties_dock = QDockWidget("Properties", self)
        self.properties_dock.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)

        self.properties_panel_widget = PropertiesPanel(self.layer_manager)
        self.properties_dock.setWidget(self.properties_panel_widget)
        
        # We'll create the actual PropertiesPanel widget later
        properties_content = QWidget()
        properties_layout = QVBoxLayout()
        properties_content.setLayout(properties_layout)
        properties_layout.addWidget(QLabel("Layer Properties (Placeholder)"))
        properties_layout.addStretch()
        
        self.properties_dock.setWidget(properties_content)
        self.addDockWidget(Qt.DockWidgetArea.RightDockWidgetArea, self.properties_dock)
    
    def _create_status_bar(self):
        """Create the status bar."""
        self.status_bar = QStatusBar()
        self.setStatusBar(self.status_bar)
        
        # Add status indicators
        self._update_canvas_size_status(self.canvas.width_spin.value(), self.canvas.height_spin.value())
    
    def _setup_panel_sizes(self):
        """Set initial sizes for dockable panels."""
        self.layer_panel_dock.setMinimumWidth(250)
        self.parameter_panel.setMinimumWidth(250)
        self.global_param_panel.setMinimumWidth(250)
        self.properties_dock.setMinimumWidth(250)
        
        # Stack panels vertically on the right
        self.tabifyDockWidget(self.layer_panel_dock, self.parameter_panel)
        self.tabifyDockWidget(self.parameter_panel, self.global_param_panel)
        self.tabifyDockWidget(self.global_param_panel, self.properties_dock)
        
        # Show the layer panel by default
        self.layer_panel_dock.raise_() 