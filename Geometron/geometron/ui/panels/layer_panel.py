from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QListWidget, QListWidgetItem, 
    QPushButton, QAbstractItemView, QLabel, QDialog
)
from PyQt6.QtCore import Qt, pyqtSignal
# Assuming LayerManager is in geometron.core.layer
from ...core.layer import LayerManager, Layer 
from ..dialogs.algorithm_select_dialog import AlgorithmSelectDialog

class LayerPanel(QWidget):
    """UI Panel for managing layers."""
    
    # Signal to request adding a new layer (could eventually pass algorithm type)
    add_layer_requested = pyqtSignal() 
    parameter_focus_requested = pyqtSignal() # Signal to focus parameter panel

    def __init__(self, layer_manager: LayerManager, parent=None):
        super().__init__(parent)
        self.layer_manager = layer_manager
        
        # Internal flag to prevent unwanted signal handling during refresh
        self._is_refreshing = False

        self.setup_ui()
        
        # Connect signals from LayerManager
        self.layer_manager.layers_changed.connect(self.refresh_layer_list)
        self.layer_manager.active_layer_changed.connect(self.update_selection)
        self.layer_manager.layer_updated.connect(self.refresh_layer_list) # Refresh list if name/visibility changes

        # Initial population
        self.refresh_layer_list()
        
    def setup_ui(self):
        """Set up the panel UI."""
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0) # Use full space
        layout.setSpacing(5)

        # --- Layer List ---
        self.layer_list = QListWidget()
        self.layer_list.setDragDropMode(QAbstractItemView.DragDropMode.InternalMove)
        self.layer_list.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        
        # Connect signals for selection and reordering
        self.layer_list.currentRowChanged.connect(self.on_layer_selection_changed)
        self.layer_list.model().rowsMoved.connect(self.on_layer_reordered)
        self.layer_list.itemDoubleClicked.connect(self.on_layer_double_clicked) # Connect double-click
        
        layout.addWidget(self.layer_list)
        
        # --- Buttons ---
        btn_layout = QHBoxLayout()
        btn_layout.setSpacing(5)

        self.add_btn = QPushButton("+")
        self.add_btn.setToolTip("Add new layer")
        self.add_btn.clicked.connect(self.on_add_layer)
        btn_layout.addWidget(self.add_btn)
        
        self.duplicate_btn = QPushButton("Dup")
        self.duplicate_btn.setToolTip("Duplicate selected layer")
        self.duplicate_btn.clicked.connect(self.on_duplicate_layer)
        btn_layout.addWidget(self.duplicate_btn)
        
        self.delete_btn = QPushButton("-")
        self.delete_btn.setToolTip("Delete selected layer")
        self.delete_btn.clicked.connect(self.on_delete_layer)
        btn_layout.addWidget(self.delete_btn)
        
        btn_layout.addStretch() # Push buttons to the left

        layout.addLayout(btn_layout)
        
        self.setLayout(layout)

    def refresh_layer_list(self):
        """Update the layer list UI from the layer manager."""
        print("--- Refreshing Layer List UI ---") # DEBUG
        if self._is_refreshing: 
            print("DEBUG: Already refreshing, returning.") # DEBUG
            return 

        self._is_refreshing = True
        print(f"DEBUG: Manager has {len(self.layer_manager.layers)} layers.") # DEBUG
        
        # Store current selection if possible
        current_index = self.layer_list.currentRow()
        selected_layer_id = None
        if current_index >= 0:
             item = self.layer_list.item(current_index)
             if item:
                 selected_layer_id = item.data(Qt.ItemDataRole.UserRole)

        self.layer_list.clear()
        print("DEBUG: List cleared.") # DEBUG
        
        # Populate list in reverse order (top layer = top of list)
        if not self.layer_manager.layers:
             print("DEBUG: No layers in manager to display.") # DEBUG
             
        for i, layer in enumerate(reversed(self.layer_manager.layers)):
            original_index = len(self.layer_manager.layers) - 1 - i
            print(f"DEBUG: Adding item for layer: {layer.name} (Original Index: {original_index})") # DEBUG
            item = QListWidgetItem(layer.name)
            # Store the layer's unique ID in the item data
            item.setData(Qt.ItemDataRole.UserRole, layer.id)
            
            # TODO: Add icons for visibility/lock state
            font = item.font()
            font.setItalic(not layer.visible)
            item.setFont(font)
            
            # Add appropriate flags for drag/drop
            item.setFlags(item.flags() | Qt.ItemFlag.ItemIsDragEnabled | Qt.ItemFlag.ItemIsDropEnabled)
            
            self.layer_list.addItem(item)

        print(f"DEBUG: List count after adding: {self.layer_list.count()}") # DEBUG
        # Restore selection based on ID
        if selected_layer_id:
             for i in range(self.layer_list.count()):
                 item = self.layer_list.item(i)
                 if item and item.data(Qt.ItemDataRole.UserRole) == selected_layer_id:
                     self.layer_list.setCurrentRow(i)
                     break
        else:
             # If nothing was selected, select the new active layer if possible
             self.update_selection(self.layer_manager.get_active_layer())
        
        self._is_refreshing = False
        self.update_button_states()
        print("--- Layer List Refresh Complete ---") # DEBUG


    def update_selection(self, active_layer: Layer | None):
        """Update the list selection based on the active layer."""
        if self._is_refreshing: return

        self._is_refreshing = True
        if active_layer:
            for i in range(self.layer_list.count()):
                item = self.layer_list.item(i)
                if item and item.data(Qt.ItemDataRole.UserRole) == active_layer.id:
                    if self.layer_list.currentRow() != i:
                        self.layer_list.setCurrentRow(i)
                    break
            else: # Layer not found in list (shouldn't happen ideally)
                 self.layer_list.setCurrentRow(-1)
        else:
            self.layer_list.setCurrentRow(-1) # No active layer, deselect
        
        self._is_refreshing = False
        self.update_button_states()


    def on_layer_selection_changed(self, current_row):
        """Handle layer selection change in the list widget."""
        if self._is_refreshing or current_row < 0:
            # If deselected or during refresh, potentially set manager active to None
            if current_row < 0 and self.layer_manager.active_layer_index != -1:
                 self.layer_manager.active_layer_index = -1
            return

        item = self.layer_list.item(current_row)
        if item:
            layer_id = item.data(Qt.ItemDataRole.UserRole)
            # Find the actual index in the manager based on ID
            for i, layer in enumerate(self.layer_manager.layers):
                 if layer.id == layer_id:
                     if self.layer_manager.active_layer_index != i:
                         self.layer_manager.active_layer_index = i # Setter will emit signal
                     break
        self.update_button_states()


    def on_layer_reordered(self, source_parent, source_start, source_end, dest_parent, destination_row):
        """Handle drag-and-drop reordering."""
        if self._is_refreshing: return

        # The list widget is displayed reversed from the manager's list
        count = len(self.layer_manager.layers)
        
        # Calculate original index from the list's row (which is reversed)
        # The item being moved is at `source_start` row in the list
        from_index = count - 1 - source_start 
        
        # Calculate the target index in the manager's list
        # `destination_row` is where it LANDS in the list view. 
        # If it moves down (destination_row > source_start), the target index in the *original* list is lower.
        # If it moves up (destination_row < source_start), the target index in the *original* list is higher.
        
        # Let's simplify: get the ID of the item *before* which it was dropped
        dropped_on_item = self.layer_list.item(destination_row)
        target_id = dropped_on_item.data(Qt.ItemDataRole.UserRole) if dropped_on_item else None

        # Find the target index in the original layer list based on the ID
        to_index = -1
        if target_id:
             for i, layer in enumerate(self.layer_manager.layers):
                 if layer.id == target_id:
                      to_index = i
                      break
        else:
             # If dropped at the end of the list view, it means the start of the manager list
             to_index = 0 

        # Adjust index because insert happens *before* the target index
        if from_index < to_index:
             # Moving down in the manager list (up in the view list), insert before is correct
             pass
        elif from_index > to_index and to_index != -1:
             # Moving up in the manager list (down in the view list)
             # If dropped onto row 3 (index 2), target ID is index `count - 1 - 2`. 
             # We want to insert it *after* this item in the original list.
             # Let manager handle the logic, just pass the indices.
              pass
        elif to_index == -1: # Should only happen when dropped at the end (target index 0)
              pass
        else: # from_index == to_index
             return # No move occurred


        # Perform the move in the manager
        # Need to be careful here, map view rows to manager indices correctly
        
        # Let's rethink the index calculation based on list widget rows:
        # List rows are 0 (top) to N-1 (bottom)
        # Manager indices are 0 (bottom) to N-1 (top)
        mgr_count = len(self.layer_manager.layers)
        from_mgr_idx = mgr_count - 1 - source_start
        
        # Calculate the manager index *before* which the item should be inserted
        # `destination_row` is the row in the LIST WIDGET where the item ends up.
        if destination_row >= mgr_count: # Dropped past the end
             to_mgr_idx = 0 
        else:
             to_mgr_idx = mgr_count - destination_row

        # Perform the move in the manager
        print(f"Moving from manager index {from_mgr_idx} to before manager index {to_mgr_idx}")
        self.layer_manager.move_layer(from_mgr_idx, to_mgr_idx)
        # Manager emits layers_changed, which triggers refresh_layer_list


    def on_layer_double_clicked(self, item: QListWidgetItem):
        """Handle double-click: select the layer and request parameter focus."""
        # Selection should already be handled by single click signal, just emit focus request
        print("DEBUG: Layer double-clicked, requesting parameter focus.")
        self.parameter_focus_requested.emit()


    def on_add_layer(self):
        """Handle add layer button click by showing the algorithm selection dialog."""
        # Create and execute the dialog
        # Pass the layer manager's algorithm registry to the dialog
        dialog = AlgorithmSelectDialog(self.layer_manager.algorithm_registry, self)
        
        if dialog.exec() == QDialog.DialogCode.Accepted:
            selected_algo_name = dialog.selected_algorithm_name
            if selected_algo_name:
                print(f"Adding layer with algorithm: {selected_algo_name}")
                # Pass the selected algorithm name to the layer manager
                self.layer_manager.add_layer(algorithm_name=selected_algo_name)
            else:
                print("Add layer cancelled or no algorithm selected.")
        else:
            print("Add layer cancelled.")


    def on_duplicate_layer(self):
        """Handle duplicate layer button click."""
        active_index = self.layer_manager.active_layer_index
        if active_index != -1:
            print(f"Requesting duplicate layer at index {active_index}...")
            self.layer_manager.duplicate_layer(active_index)


    def on_delete_layer(self):
        """Handle delete layer button click."""
        active_index = self.layer_manager.active_layer_index
        if active_index != -1:
            print(f"Requesting delete layer at index {active_index}...")
            # TODO: Add confirmation dialog?
            self.layer_manager.remove_layer(active_index)
            
    def update_button_states(self):
        """Enable/disable buttons based on selection."""
        has_selection = self.layer_manager.active_layer_index != -1
        self.duplicate_btn.setEnabled(has_selection)
        self.delete_btn.setEnabled(has_selection)