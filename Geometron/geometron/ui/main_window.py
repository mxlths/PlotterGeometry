from PyQt6.QtWidgets import (QMainWindow, QDockWidget, QWidget, QVBoxLayout,
                            QToolBar, QStatusBar, QLabel, QGroupBox, QTabBar, QTabWidget)
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QPalette, QColor
import pyqtgraph as pg
from .canvas.canvas_widget import CanvasWidget
from ..core.layer import LayerManager
from ..core.algorithms.registry import AlgorithmRegistry
from .panels.layer_panel import LayerPanel
from .panels.layer_properties_panel import LayerPropertiesPanel
from .panels.parameter_panel import ParameterPanel
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
        
        # Apply stylesheet for dock widgets, tabs, and content
        self.setStyleSheet("""
            /* Dock Widget Title Bar */
            QDockWidget::title {
                background-color: #555555; /* Dark Grey */
                color: #EEEEEE; /* Light Grey Text */
                border: 1px solid #222222; /* Dark Border */
                padding: 4px;
                text-align: left;
            }

            /* Force background color on ALL children of our dock widgets */
            #layer_panel_dock QWidget,
            #parameter_panel_dock QWidget,
            #global_param_panel QWidget,
            #properties_dock QWidget {
                background-color: #444444; /* Main Dark Background for Content */
                color: #EEEEEE; /* Default Light Text for Content */
            }
            
            /* Override for scroll areas and viewport */
            #layer_panel_dock QScrollArea,
            #parameter_panel_dock QScrollArea, 
            #global_param_panel QScrollArea,
            #properties_dock QScrollArea {
                background-color: #444444 !important;
                border: none !important; /* Remove border from scroll area itself */
            }
            #layer_panel_dock QScrollArea > QWidget > QWidget,
            #parameter_panel_dock QScrollArea > QWidget > QWidget,
            #global_param_panel QScrollArea > QWidget > QWidget,
            #properties_dock QScrollArea > QWidget > QWidget,
            #layer_panel_dock QScrollArea QWidget#qt_scrollarea_viewport,
            #parameter_panel_dock QScrollArea QWidget#qt_scrollarea_viewport,
            #global_param_panel QScrollArea QWidget#qt_scrollarea_viewport,
            #properties_dock QScrollArea QWidget#qt_scrollarea_viewport,
            #layer_panel_dock QScrollArea QWidget#qt_scrollarea_viewport > QWidget,
            #parameter_panel_dock QScrollArea QWidget#qt_scrollarea_viewport > QWidget,
            #global_param_panel QScrollArea QWidget#qt_scrollarea_viewport > QWidget,
            #properties_dock QScrollArea QWidget#qt_scrollarea_viewport > QWidget {
                background-color: #444444 !important;
                color: #EEEEEE;
                border: none !important; /* Ensure no border on viewport or its child */
            }

            /* Default text color for various common widget types */
            #layer_panel_dock QLabel,
            #parameter_panel_dock QLabel,
            #global_param_panel QLabel,
            #properties_dock QLabel {
                color: #EEEEEE; 
                background-color: transparent; 
            }

            /* Group Boxes styling */
            QGroupBox {
                background-color: transparent; /* Blend with panel background */
                border: 1px solid #777777; /* Visible but not too bright border */
                border-radius: 4px;
                margin-top: 10px; /* Space above the group box */
                padding-top: 10px; /* Space inside above the title */
                color: #EEEEEE; /* Title text color (inherited by ::title) */
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                subcontrol-position: top left;
                padding: 0 5px; /* Padding around the title */
                left: 10px; /* Indent title slightly */
            }

            /* Checkboxes styling */
            #layer_panel_dock QCheckBox,
            #parameter_panel_dock QCheckBox,
            #global_param_panel QCheckBox,
            #properties_dock QCheckBox {
                color: #EEEEEE; 
                background-color: transparent;
            }
            #layer_panel_dock QCheckBox::indicator,
            #parameter_panel_dock QCheckBox::indicator,
            #global_param_panel QCheckBox::indicator,
            #properties_dock QCheckBox::indicator {
                 border: 1px solid #888888;
                 background-color: #555555;
            }
            #layer_panel_dock QCheckBox::indicator:checked,
            #parameter_panel_dock QCheckBox::indicator:checked,
            #global_param_panel QCheckBox::indicator:checked,
            #properties_dock QCheckBox::indicator:checked {
                 background-color: #77AAFF; /* Example check color */
            }
            
            /* Buttons styling - with specific exception for layer buttons */
            #layer_panel_dock QPushButton:not(.layer-button),
            #parameter_panel_dock QPushButton,
            #global_param_panel QPushButton,
            #properties_dock QPushButton {
                color: #EEEEEE; 
                background-color: #666666;
                border: 1px solid #888888;
                padding: 4px 8px;
                border-radius: 3px;
            }
            
            /* Special styling for layer buttons to preserve their appearance */
            #layer_panel_dock QPushButton.layer-button {
                color: #EEEEEE;
                background-color: #666666;
                border: 1px solid #888888;
                padding: 2px 10px;
                border-radius: 3px;
                min-height: 24px;
                min-width: 24px;
                font-weight: bold;
                font-size: 14px;
            }
            
            #layer_panel_dock QPushButton:hover:not(.layer-button),
            #parameter_panel_dock QPushButton:hover,
            #global_param_panel QPushButton:hover,
            #properties_dock QPushButton:hover {
                background-color: #777777;
            }
            #layer_panel_dock QPushButton.layer-button:hover {
                background-color: #777777;
            }
            #layer_panel_dock QPushButton:pressed:not(.layer-button),
            #parameter_panel_dock QPushButton:pressed,
            #global_param_panel QPushButton:pressed,
            #properties_dock QPushButton:pressed {
                background-color: #555555;
            }
            #layer_panel_dock QPushButton.layer-button:pressed {
                background-color: #555555;
            }
            #layer_panel_dock QPushButton:disabled:not(.layer-button),
            #parameter_panel_dock QPushButton:disabled,
            #global_param_panel QPushButton:disabled,
            #properties_dock QPushButton:disabled {
                color: #888888;
                background-color: #505050;
            }

            /* Input widgets styling with forced dark background */
            #layer_panel_dock QLineEdit,
            #parameter_panel_dock QLineEdit,
            #global_param_panel QLineEdit,
            #properties_dock QLineEdit,
            #layer_panel_dock QSpinBox,
            #parameter_panel_dock QSpinBox,
            #global_param_panel QSpinBox,
            #properties_dock QSpinBox, 
            #layer_panel_dock QDoubleSpinBox,
            #parameter_panel_dock QDoubleSpinBox,
            #global_param_panel QDoubleSpinBox,
            #properties_dock QDoubleSpinBox,
            #layer_panel_dock QComboBox,
            #parameter_panel_dock QComboBox,
            #global_param_panel QComboBox,
            #properties_dock QComboBox {
                border: 1px solid #888888;
                padding: 2px;
                background-color: #555555;
                color: #EEEEEE;
            }
            
            /* Specifically target the text edit part of spin boxes */
            QSpinBox::edit-field, QDoubleSpinBox::edit-field {
                background-color: #555555;
                color: #EEEEEE;
                border: none;
            }
            
            /* Fix for any editable widgets */
            QAbstractSpinBox {
                background-color: #555555;
                color: #EEEEEE;
            }
            
            /* Style the line edit inside spin boxes and combo boxes */
            QAbstractSpinBox QLineEdit, QComboBox QLineEdit {
                border: none;
                background-color: #555555;
                color: #EEEEEE;
            }
            
            /* Override for QFrame which may be used as separators or panels */
            #layer_panel_dock QFrame,
            #parameter_panel_dock QFrame,
            #global_param_panel QFrame,
            #properties_dock QFrame {
                background-color: #444444;
                color: #EEEEEE;
            }
            
            /* Combobox dropdown styling */
            #layer_panel_dock QComboBox QAbstractItemView,
            #parameter_panel_dock QComboBox QAbstractItemView,
            #global_param_panel QComboBox QAbstractItemView,
            #properties_dock QComboBox QAbstractItemView {
                background-color: #555555;
                color: #EEEEEE;
                selection-background-color: #666666;
            }
            
            /* SpinBox and DoubleSpinBox button styling */
            #layer_panel_dock QSpinBox::up-button,
            #parameter_panel_dock QSpinBox::up-button,
            #global_param_panel QSpinBox::up-button,
            #properties_dock QSpinBox::up-button,
            #layer_panel_dock QDoubleSpinBox::up-button,
            #parameter_panel_dock QDoubleSpinBox::up-button,
            #global_param_panel QDoubleSpinBox::up-button,
            #properties_dock QDoubleSpinBox::up-button,
            #layer_panel_dock QSpinBox::down-button,
            #parameter_panel_dock QSpinBox::down-button,
            #global_param_panel QSpinBox::down-button,
            #properties_dock QSpinBox::down-button,
            #layer_panel_dock QDoubleSpinBox::down-button,
            #parameter_panel_dock QDoubleSpinBox::down-button,
            #global_param_panel QDoubleSpinBox::down-button,
            #properties_dock QDoubleSpinBox::down-button {
                background-color: #666666;
                border: 1px solid #777777;
            }
            
            /* Tab Bar Styling (Bottom where docks are tabbed) */
            QTabBar::tab {
                background-color: #666666; /* Medium Grey */
                color: #EEEEEE; /* Light Grey Text */
                border: 1px solid #444444; /* Darker border */
                border-bottom: none;
                padding: 6px 12px;
                margin-right: 1px;
                border-top-left-radius: 4px;
                border-top-right-radius: 4px;
            }
            QTabBar::tab:selected {
                background-color: #777777; /* Lighter Grey for selected */
                margin-bottom: -1px; 
                border-bottom: 1px solid #777777; /* Blend bottom border */
            }
            QTabBar::tab:hover:!selected {
                background-color: #707070; 
            }
            QTabWidget::pane { /* The area below the tab bar */
                border-top: 1px solid #444444;
                background-color: #444444; 
                border: none;
                top: -1px; /* Move content up to eliminate the gap */
                margin-top: 0px;
                padding-top: 0px;
            }
            QTabBar {
                qproperty-drawBase: 0; /* No default base line */
                left: 5px; /* Indent tabs */
            }
            
            /* Target the specific area under tabbed docks */
            .QWidget[tabPosition="1"] {  /* South tabs */
                background-color: #444444 !important;
                border: none !important;
                margin: 0px !important;
                padding: 0px !important;
            }
            
            /* Override QMainWindow internals related to tabified docks */
            QMainWindow::separator {
                background: #444444;
                width: 0px; /* width of the separator */
                height: 0px; /* height of the separator */
                margin: 0px;
                padding: 0px;
            }
            QMainWindow > QWidget > QAbstractScrollArea {
                background-color: #444444 !important;
                border: none !important;
            }
            QMainWindow > QWidget {
                background-color: #444444 !important;
                border: none !important;
                margin: 0px !important;
                padding: 0px !important;
            }
            
            /* Target for form layouts which might be creating white bars */
            QFormLayout, 
            QFormLayout > QWidget,
            QFormLayout > QLayoutItem,
            QFormLayout > QSpacerItem,
            #layer_panel_dock QFormLayout,
            #parameter_panel_dock QFormLayout,
            #global_param_panel QFormLayout,
            #properties_dock QFormLayout {
                background-color: #444444 !important;
                border: none !important;
                spacing: 0px !important;
                margin: 0px !important;
            }
            
            /* Target potential splitters */
            QSplitter, QSplitter::handle {
                background-color: #444444 !important;
                border: none !important;
            }
            
            /* Override for any table views or list views */
            QTableView, QListView, QTreeView {
                background-color: #444444 !important;
                alternate-background-color: #4A4A4A !important;
                border: none !important;
            }
            
            /* Target horizontal and vertical lines */
            QFrame[frameShape="4"], /* HLine */
            QFrame[frameShape="5"]  /* VLine */ {
                background-color: #666666 !important;
                border: none !important;
            }
        """)
        
        # Connect signals
        self.layer_panel_widget.parameter_focus_requested.connect(self.focus_parameter_panel)
        
        # Update status bar with initial canvas size
        self._update_canvas_size_status(self.canvas.width_spin.value(), self.canvas.height_spin.value())
        
        # Use a timer to apply additional styling after the UI is fully constructed
        # This helps catch any Qt-created internal widgets that appear after initialization
        QTimer.singleShot(100, self._apply_delayed_styling)
    
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
        self.layer_panel_dock.setObjectName("layer_panel_dock")
        self.layer_panel_dock.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        self.layer_panel_dock.setContentsMargins(0, 0, 0, 0)
        
        self.layer_panel_widget = LayerPanel(self.layer_manager)
        self.layer_panel_widget.setContentsMargins(0, 0, 0, 0)
        self.layer_panel_dock.setWidget(self.layer_panel_widget)
        
        self.addDockWidget(Qt.DockWidgetArea.RightDockWidgetArea, self.layer_panel_dock)
    
    def _create_parameter_panel(self):
        """Create the algorithm parameter panel."""
        self.parameter_panel_dock = QDockWidget("Parameters", self)
        self.parameter_panel_dock.setObjectName("parameter_panel_dock")
        self.parameter_panel_dock.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        self.parameter_panel_dock.setContentsMargins(0, 0, 0, 0)
        
        self.parameter_panel_widget = ParameterPanel(self.layer_manager)
        self.parameter_panel_widget.setContentsMargins(0, 0, 0, 0)
        self.parameter_panel_dock.setWidget(self.parameter_panel_widget)
        
        self.addDockWidget(Qt.DockWidgetArea.RightDockWidgetArea, self.parameter_panel_dock)
    
    def _create_global_parameter_panel(self):
        """Create the global parameter panel."""
        self.global_param_panel = QDockWidget("Global Parameters", self)
        self.global_param_panel.setObjectName("global_param_panel")
        self.global_param_panel.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        self.global_param_panel.setContentsMargins(0, 0, 0, 0)
        
        global_param_content = QWidget()
        global_param_content.setContentsMargins(0, 0, 0, 0)
        global_param_layout = QVBoxLayout()
        global_param_layout.setContentsMargins(0, 0, 0, 0)
        global_param_layout.setSpacing(0)
        global_param_content.setLayout(global_param_layout)
        global_param_layout.addWidget(QLabel("Global Parameters Table (Placeholder)"))
        global_param_layout.addStretch()
        
        self.global_param_panel.setWidget(global_param_content)
        self.addDockWidget(Qt.DockWidgetArea.RightDockWidgetArea, self.global_param_panel)
    
    def _create_properties_panel(self):
        """Create the layer properties panel."""
        self.properties_dock = QDockWidget("Properties", self)
        self.properties_dock.setObjectName("properties_dock")
        self.properties_dock.setAllowedAreas(Qt.DockWidgetArea.RightDockWidgetArea)
        self.properties_dock.setContentsMargins(0, 0, 0, 0)

        self.properties_panel_widget = LayerPropertiesPanel(self.layer_manager)
        self.properties_panel_widget.setContentsMargins(0, 0, 0, 0)
        self.properties_dock.setWidget(self.properties_panel_widget)
        
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
        self.parameter_panel_dock.setMinimumWidth(250)
        self.global_param_panel.setMinimumWidth(250)
        self.properties_dock.setMinimumWidth(250)
        
        # Stack panels vertically on the right
        self.tabifyDockWidget(self.layer_panel_dock, self.parameter_panel_dock)
        self.tabifyDockWidget(self.parameter_panel_dock, self.global_param_panel)
        self.tabifyDockWidget(self.global_param_panel, self.properties_dock)
        
        # Show the layer panel by default
        self.layer_panel_dock.raise_()
        
        # Apply consistent dark backgrounds using palette
        self._setup_panel_backgrounds()
        
        # Find and customize tab bars created through tabification
        self._customize_dock_tab_bars()

    def _customize_dock_tab_bars(self):
        """Find all tab bars in the window and apply additional customization."""
        # Find all tab bars in the window
        tab_bars = self.findChildren(QTabBar)
        
        # Apply additional styling to each tab bar
        for tab_bar in tab_bars:
            # Set custom background color and ensure no margins/spacing
            tab_bar.setStyleSheet("""
                QTabBar {
                    background-color: #444444;
                    border: none;
                    margin: 0px;
                    padding: 0px;
                }
                QTabBar::tab {
                    background-color: #666666;
                    color: #EEEEEE;
                    padding: 6px 12px;
                    margin-right: 1px;
                    border: 1px solid #444444;
                    border-bottom: none;
                    border-top-left-radius: 4px;
                    border-top-right-radius: 4px;
                }
                QTabBar::tab:selected {
                    background-color: #777777;
                    margin-bottom: -1px;
                }
            """)
            
            # Check the parent widget to see if it contains a QWidget with layout
            parent = tab_bar.parent()
            if parent:
                # Set explicit styling on parent widget
                parent.setStyleSheet("""
                    background-color: #444444 !important;
                    border: none !important;
                    margin: 0px !important;
                    padding: 0px !important;
                """)
                
                # Try to find and style the pane area (if accessible)
                for child in parent.children():
                    if isinstance(child, QWidget) and not isinstance(child, QTabBar):
                        child.setStyleSheet("""
                            background-color: #444444;
                            border: none;
                            margin: 0px;
                            padding: 0px;
                        """)
                        child.setContentsMargins(0, 0, 0, 0)

    def _setup_panel_backgrounds(self):
        """Ensure all panels have consistent dark backgrounds using both palette and stylesheet approaches."""
        dark_palette = QPalette()
        dark_bg = QColor('#444444')
        light_text = QColor('#EEEEEE')
        
        # Set background and text colors for all color roles that could affect our panels
        dark_palette.setColor(QPalette.ColorRole.Window, dark_bg)
        dark_palette.setColor(QPalette.ColorRole.Base, dark_bg)
        dark_palette.setColor(QPalette.ColorRole.AlternateBase, dark_bg)
        dark_palette.setColor(QPalette.ColorRole.ToolTipBase, dark_bg)
        dark_palette.setColor(QPalette.ColorRole.Button, QColor('#555555'))
        dark_palette.setColor(QPalette.ColorRole.Text, light_text)
        dark_palette.setColor(QPalette.ColorRole.ButtonText, light_text)
        dark_palette.setColor(QPalette.ColorRole.WindowText, light_text)
        dark_palette.setColor(QPalette.ColorRole.ToolTipText, light_text)
        dark_palette.setColor(QPalette.ColorRole.PlaceholderText, QColor('#AAAAAA'))
        
        # Direct stylesheet for all panel widgets
        panel_stylesheet = """
        * {
            background-color: #444444;
            color: #EEEEEE;
            border: none;
        }
        QFrame, QLabel, QWidget {
            background-color: #444444;
            border: none;
        }
        QScrollArea, QScrollArea > QWidget, QScrollArea QWidget#qt_scrollarea_viewport {
            background-color: #444444;
            border: none;
        }
        """
        
        # Apply palette and direct stylesheet to all dock content widgets
        for dock in [self.layer_panel_dock, self.parameter_panel_dock, self.global_param_panel, self.properties_dock]:
            content_widget = dock.widget()
            if content_widget:
                # Apply palette
                content_widget.setPalette(dark_palette)
                content_widget.setAutoFillBackground(True)
                
                # Apply stylesheet directly
                content_widget.setStyleSheet(panel_stylesheet)
                
                # Force all child widgets to inherit this background
                self._apply_dark_background_to_children(content_widget, dark_bg, light_text)
    
    def _apply_dark_background_to_children(self, widget, bg_color, text_color):
        """Recursively apply dark background to all child widgets."""
        # Find all widgets - alternative approach without using FindDirectChildrenOnly
        for child in widget.children():
            # Only process QWidget objects
            if isinstance(child, QWidget):
                # Set palette and auto-fill background
                palette = child.palette()
                palette.setColor(QPalette.ColorRole.Window, bg_color)
                palette.setColor(QPalette.ColorRole.Base, bg_color)
                palette.setColor(QPalette.ColorRole.AlternateBase, bg_color)
                palette.setColor(QPalette.ColorRole.Text, text_color)
                palette.setColor(QPalette.ColorRole.WindowText, text_color)
                child.setPalette(palette)
                child.setAutoFillBackground(True)
                
                # Recursively apply to this widget's children
                self._apply_dark_background_to_children(child, bg_color, text_color)

    def focus_parameter_panel(self):
        """Make the Parameter dock widget visible and raise it."""
        if hasattr(self, 'parameter_panel_dock') and self.parameter_panel_dock:
            self.parameter_panel_dock.setVisible(True)
            self.parameter_panel_dock.raise_()
            print("DEBUG: Focusing Parameter Panel") # DEBUG 

    def _apply_delayed_styling(self):
        """Apply additional styling after the UI is fully constructed to fix any remaining white bars."""
        # Find all QTabBar instances in the window
        for tab_bar in self.findChildren(QTabBar):
            # Apply more aggressive styling to each tab bar's parent widget
            parent = tab_bar.parent()
            if parent:
                # Set an explicit dark background
                parent_palette = parent.palette()
                parent_palette.setColor(QPalette.ColorRole.Window, QColor('#444444'))
                parent_palette.setColor(QPalette.ColorRole.Base, QColor('#444444'))
                parent.setPalette(parent_palette)
                parent.setAutoFillBackground(True)
                parent.setStyleSheet("background-color: #444444 !important; border: none !important;")
                
                # Look for siblings of the tab bar (QTabBar and the widget that shows the content)
                for sibling in parent.children():
                    if isinstance(sibling, QWidget) and sibling is not tab_bar:
                        # This is likely the content widget with the white bar
                        sibling_palette = sibling.palette()
                        sibling_palette.setColor(QPalette.ColorRole.Window, QColor('#444444'))
                        sibling_palette.setColor(QPalette.ColorRole.Base, QColor('#444444'))
                        sibling.setPalette(sibling_palette)
                        sibling.setAutoFillBackground(True)
                        sibling.setStyleSheet("background-color: #444444 !important; border: none !important;")
                        sibling.setContentsMargins(0, 0, 0, 0)
                        
                        # Check the children of this sibling (where the actual white bar might be)
                        for child in sibling.children():
                            if isinstance(child, QWidget):
                                child_palette = child.palette()
                                child_palette.setColor(QPalette.ColorRole.Window, QColor('#444444'))
                                child_palette.setColor(QPalette.ColorRole.Base, QColor('#444444'))
                                child.setPalette(child_palette)
                                child.setAutoFillBackground(True)
                                child.setStyleSheet("background-color: #444444 !important; border: none !important;")
                                child.setContentsMargins(0, 0, 0, 0)
        
        # Find the layer buttons and add the layer-button class
        from PyQt6.QtWidgets import QPushButton
        
        # Look for add and remove buttons in the LayerPanel
        if hasattr(self, 'layer_panel_widget'):
            for button in self.layer_panel_widget.findChildren(QPushButton):
                # Check for common add/remove button labels or object names
                button_text = button.text().strip().lower()
                if button_text in ['+', '-', 'add', 'remove'] or 'add' in button.objectName().lower() or 'remove' in button.objectName().lower():
                    current_class = button.property('class')
                    if current_class:
                        # Append layer-button class if it doesn't already have it
                        if 'layer-button' not in current_class:
                            button.setProperty('class', f"{current_class} layer-button")
                    else:
                        button.setProperty('class', 'layer-button')
                    
                    # Apply the styles by forcing a style refresh
                    button.style().unpolish(button)
                    button.style().polish(button) 