from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QListWidget, QListWidgetItem, QLabel, 
    QDialogButtonBox, QSplitter
)
from PyQt6.QtCore import Qt
from ...core.algorithms.registry import AlgorithmRegistry

class AlgorithmSelectDialog(QDialog):
    """Dialog to select an algorithm from the registry."""

    def __init__(self, registry: AlgorithmRegistry, parent=None):
        super().__init__(parent)
        self.registry = registry
        self.selected_algorithm_name: str | None = None

        self.setWindowTitle("Select Algorithm")
        self.setMinimumSize(400, 300)

        self.setup_ui()
        self.populate_list()
        self.update_description() # Initial state

    def setup_ui(self):
        """Create the UI elements."""
        main_layout = QVBoxLayout(self)

        # Splitter for list and description
        splitter = QSplitter(Qt.Orientation.Vertical)

        # Algorithm List
        self.algo_list = QListWidget()
        self.algo_list.currentItemChanged.connect(self.update_description)
        splitter.addWidget(self.algo_list)

        # Description Area
        self.description_label = QLabel("Select an algorithm to see its description.")
        self.description_label.setWordWrap(True)
        self.description_label.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        self.description_label.setStyleSheet("padding: 5px;") # Add some padding
        splitter.addWidget(self.description_label)
        
        splitter.setSizes([200, 100]) # Initial sizes for list and description

        main_layout.addWidget(splitter)

        # Dialog Buttons
        self.button_box = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        self.button_box.accepted.connect(self.accept)
        self.button_box.rejected.connect(self.reject)
        self.button_box.button(QDialogButtonBox.StandardButton.Ok).setEnabled(False) # Disabled initially

        main_layout.addWidget(self.button_box)
        self.setLayout(main_layout)

    def populate_list(self):
        """Fill the list widget with algorithm names."""
        self.algo_list.clear()
        algo_names = self.registry.list_algorithms()
        for name in algo_names:
            item = QListWidgetItem(name)
            self.algo_list.addItem(item)

    def update_description(self):
        """Update the description label based on selection."""
        current_item = self.algo_list.currentItem()
        if current_item:
            algo_name = current_item.text()
            algo_cls = self.registry.get_algorithm_class(algo_name)
            if algo_cls:
                description = algo_cls.get_description()
                self.description_label.setText(description or "No description available.")
                self.button_box.button(QDialogButtonBox.StandardButton.Ok).setEnabled(True)
            else:
                self.description_label.setText("Error: Algorithm class not found.")
                self.button_box.button(QDialogButtonBox.StandardButton.Ok).setEnabled(False)
        else:
            self.description_label.setText("Select an algorithm to see its description.")
            self.button_box.button(QDialogButtonBox.StandardButton.Ok).setEnabled(False)

    def accept(self):
        """Store the selected algorithm name before accepting."""
        current_item = self.algo_list.currentItem()
        if current_item:
            self.selected_algorithm_name = current_item.text()
        else:
            self.selected_algorithm_name = None
        super().accept() 