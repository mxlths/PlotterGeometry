import sys
from PyQt6.QtWidgets import QApplication
from geometron.ui.main_window import MainWindow

def main():
    """Main application entry point."""
    app = QApplication(sys.argv)
    
    # Set application style
    app.setStyle('Fusion')  # Use Fusion style for a clean, modern look
    
    # Create and show main window
    window = MainWindow()
    window.show()
    
    # Start event loop
    sys.exit(app.exec())

if __name__ == '__main__':
    main() 