# Geometron

A cross-platform application for creating, manipulating, and exporting complex geometric art for pen plotters. Geometron combines multiple algorithm-driven generative art techniques in a layer-based interface, allowing artists to create intricate compositions by combining and transforming various patterns.

## Features

- Algorithm-driven geometry generation
- Layer-based composition system
- 2D and 3D geometry support
- SVG export optimized for pen plotters
- Extensible plugin architecture for algorithms
- Parametric design capabilities

## Requirements

- Python 3.10 or higher
- Qt6
- NumPy, SciPy for geometry processing
- PyQtGraph/Vispy for rendering
- Additional dependencies listed in requirements.txt

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/geometron.git
cd geometron
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Development Status

Currently in Phase 1 of development:
- Implementing core geometry primitives
- Building layer management system
- Designing algorithm interface
- Creating basic UI framework

## Project Structure

```
geometron/
├── core/
│   ├── geometry/     # Geometry primitives and operations
│   ├── algorithms/   # Algorithm implementations
│   ├── modulations/  # Geometry transformation systems
│   └── io/          # File I/O and export
├── ui/
│   ├── panels/      # UI panel implementations
│   ├── widgets/     # Custom widgets
│   ├── canvas/      # Rendering system
│   └── dialogs/     # Dialog windows
├── resources/       # Icons, styles, etc.
└── tests/          # Unit tests
```

## Contributing

This project is currently in early development. Contribution guidelines will be added soon.

## License

[License information to be added] 