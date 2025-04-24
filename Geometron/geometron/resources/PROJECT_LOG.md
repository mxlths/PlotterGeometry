# Geometron Project Log

## Overview

This log tracks major features, milestones, and significant changes during the development of the Geometron application.

---

## Log Entries

** 24-04-2025/1707 - **Initial Setup & Core Architecture**

*   Set up Python virtual environment (`venv`).
*   Established core project structure (`geometron` package with `core`, `ui`, `resources`, `tests` subdirectories).
*   Created basic geometry primitives (`Point`, `Line`, `Path`, `Shape`, `Group`) in `geometron/core/geometry/primitives.py`.
*   Implemented transformation utilities (`Transform` class) in `geometron/core/geometry/transform.py`.
*   Developed initial `Layer` and `LayerManager` classes in `geometron/core/layer.py` using PyQt signals.
*   Set up basic UI framework (`MainWindow`, dockable panels, `CanvasWidget`) using PyQt6 and PyQtGraph.
*   Configured project for installation using `setup.py` (added `attrs` dependency).
*   Implemented canvas size controls and dynamic grid lines in `CanvasWidget`.
*   Added canvas outline rectangle.
*   Styled dock widget titles.
*   Implemented basic Algorithm framework (`AlgorithmBase`, `AlgorithmParameter`, `AlgorithmRegistry`, dummy algorithms).
*   Integrated `AlgorithmRegistry` with `LayerManager`.
*   Created `AlgorithmSelectDialog` for adding new layers.
*   Created placeholder `PropertiesPanel` and integrated into `MainWindow`. 