from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QLabel, QSpinBox, QPushButton
from PyQt6.QtCore import Qt, pyqtSignal, QRectF
import pyqtgraph as pg
import numpy as np

class CanvasWidget(QWidget):
    """Custom canvas widget for 2D and 3D rendering."""
    
    # Signals
    view_changed = pyqtSignal()  # Emitted when view parameters change
    size_changed = pyqtSignal(int, int)  # Emitted when canvas size changes
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        self.h_grid_lines = []
        self.v_grid_lines = []
        
        # Create layout
        self.layout = QVBoxLayout()
        self.setLayout(self.layout)
        
        # Create size and grid controls
        self._create_controls()
        
        # Create graphics view
        self.view = pg.GraphicsView()
        self.layout.addWidget(self.view)
        
        # Create view box for 2D content
        self.view_box = pg.ViewBox()
        self.view_box.setAspectLocked(True)
        self.view.setCentralItem(self.view_box)
        
        # Initialize view parameters
        self._setup_view()
        
        # Create canvas outline
        self._create_canvas_outline()
        
        # Create initial grid
        self._update_grid()
        
        # Connect signals
        self.view_box.sigRangeChanged.connect(self._on_view_changed)
    
    def _create_canvas_outline(self):
        """Create a rectangle to show canvas dimensions."""
        # Create a rectangle item for the canvas outline
        width = self.width_spin.value()
        height = self.height_spin.value()
        
        # Create the rectangle
        self.canvas_rect = pg.RectROI(
            [0, 0],  # Position
            [width, height],  # Size
            pen=pg.mkPen(color='k', width=2)  # Black outline
        )
        self.canvas_rect.setZValue(-1)  # Place behind other items
        self.view_box.addItem(self.canvas_rect)
        
        # Disable ROI handles and movement
        self.canvas_rect.translatable = False
        self.canvas_rect.rotatable = False
        self.canvas_rect.resizable = False
    
    def _create_controls(self):
        """Create controls for canvas size, view snapping, and grid lines."""
        control_layout = QHBoxLayout()
        
        # Width control
        width_label = QLabel("W:")
        self.width_spin = QSpinBox()
        self.width_spin.setRange(100, 5000)
        self.width_spin.setValue(800)
        self.width_spin.valueChanged.connect(self._on_size_changed)
        
        # Height control
        height_label = QLabel("H:")
        self.height_spin = QSpinBox()
        self.height_spin.setRange(100, 5000)
        self.height_spin.setValue(600)
        self.height_spin.valueChanged.connect(self._on_size_changed)
        
        # Snap View button
        self.snap_button = QPushButton("Snap")
        self.snap_button.setToolTip("Snap view to canvas size")
        self.snap_button.clicked.connect(self.snap_view_to_canvas)

        # Horizontal Grid Lines control
        h_grid_label = QLabel("H Grid:")
        self.h_grid_spin = QSpinBox()
        self.h_grid_spin.setRange(0, 100)
        self.h_grid_spin.setValue(10)
        self.h_grid_spin.valueChanged.connect(self._update_grid)
        
        # Vertical Grid Lines control
        v_grid_label = QLabel("V Grid:")
        self.v_grid_spin = QSpinBox()
        self.v_grid_spin.setRange(0, 100)
        self.v_grid_spin.setValue(10)
        self.v_grid_spin.valueChanged.connect(self._update_grid)

        # Add controls to layout
        control_layout.addWidget(width_label)
        control_layout.addWidget(self.width_spin)
        control_layout.addWidget(height_label)
        control_layout.addWidget(self.height_spin)
        control_layout.addWidget(self.snap_button)
        control_layout.addSpacing(20) # Add some space
        control_layout.addWidget(h_grid_label)
        control_layout.addWidget(self.h_grid_spin)
        control_layout.addWidget(v_grid_label)
        control_layout.addWidget(self.v_grid_spin)
        control_layout.addStretch()
        
        self.layout.addLayout(control_layout)
    
    def _setup_view(self):
        """Initialize view parameters and settings."""
        # Set background color to white
        self.view_box.setBackgroundColor('w')
        
        # Enable mouse interaction
        self.view_box.setMouseEnabled(x=True, y=True)
        
        # Disable default grid (we draw our own)
        # self.grid = pg.GridItem()
        # self.view_box.addItem(self.grid)
        
        # Set initial view range (snap to initial canvas size)
        self.snap_view_to_canvas() # Call snap view initially

    def _update_grid(self):
        """Draw manual grid lines based on spinbox values."""
        # Remove old grid lines
        for line in self.h_grid_lines:
            self.view_box.removeItem(line)
        for line in self.v_grid_lines:
            self.view_box.removeItem(line)
        self.h_grid_lines.clear()
        self.v_grid_lines.clear()

        width = self.width_spin.value()
        height = self.height_spin.value()
        num_h_lines = self.h_grid_spin.value()
        num_v_lines = self.v_grid_spin.value()
        
        grid_pen = pg.mkPen(color=(200, 200, 200), style=Qt.PenStyle.DashLine) # Light grey dashed lines

        # Draw horizontal lines
        if num_h_lines > 0:
            h_spacing = height / (num_h_lines + 1)
            for i in range(1, num_h_lines + 1):
                y = i * h_spacing
                line = pg.InfiniteLine(pos=y, angle=0, pen=grid_pen)
                line.setZValue(-0.5) # Place behind outline but above background
                self.view_box.addItem(line)
                self.h_grid_lines.append(line)
                
        # Draw vertical lines
        if num_v_lines > 0:
            v_spacing = width / (num_v_lines + 1)
            for i in range(1, num_v_lines + 1):
                x = i * v_spacing
                line = pg.InfiniteLine(pos=x, angle=90, pen=grid_pen)
                line.setZValue(-0.5)
                self.view_box.addItem(line)
                self.v_grid_lines.append(line)

    def _on_size_changed(self):
        """Handle canvas size changes."""
        width = self.width_spin.value()
        height = self.height_spin.value()
        
        # Update canvas outline
        if hasattr(self, 'canvas_rect'):
            self.view_box.removeItem(self.canvas_rect)
        self._create_canvas_outline()
        
        # Update grid
        self._update_grid()
        
        # Emit signal
        self.size_changed.emit(width, height)
    
    def _on_view_changed(self):
        """Handle view changes."""
        self.view_changed.emit()
    
    def add_item(self, item):
        """Add a graphics item to the canvas."""
        self.view_box.addItem(item)
    
    def remove_item(self, item):
        """Remove a graphics item from the canvas."""
        self.view_box.removeItem(item)
    
    def clear(self):
        """Clear all items from the canvas."""
        self.view_box.clear()
        self._create_canvas_outline()  # Re-add canvas outline
    
    def get_view_range(self):
        """Get current view range."""
        return self.view_box.viewRange()
    
    def set_view_range(self, x_range, y_range):
        """Set view range."""
        self.view_box.setRange(xRange=x_range, yRange=y_range)
    
    def zoom_to_fit(self):
        """Zoom to fit all items in view."""
        self.view_box.autoRange()
    
    def wheelEvent(self, event):
        """Handle mouse wheel events for zooming."""
        if event.angleDelta().y() > 0:
            self.view_box.scaleBy(1.1)
        else:
            self.view_box.scaleBy(0.9)
        event.accept()
    
    def snap_view_to_canvas(self):
        """Center the view on the canvas rectangle with padding."""
        width = self.width_spin.value()
        height = self.height_spin.value()
        # Define the rectangle representing the canvas
        canvas_rect = QRectF(0, 0, width, height)
        # Set the view range to this rectangle, adding 5% padding
        self.view_box.setRange(rect=canvas_rect, padding=0.05) 