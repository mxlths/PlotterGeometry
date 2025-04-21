# Procedural 3D Tree Generator - Design Document

## 1. Project Goal

The primary goal of this project is to create a Processing sketch that procedurally generates 3D tree structures rendered as wireframes. The generated trees should exhibit organic complexity suitable for export as 2D projected SVG files, intended for use with pen plotters or other vector-based applications.

## 2. Core Features

*   **Procedural Tree Generation:** Implement algorithms to create diverse tree structures. Start with L-Systems (Lindenmayer Systems) and potentially explore others like Space Colonization later.
*   **3D Wireframe Rendering:** Display the generated tree structure using lines in a 3D space (using Processing's P3D renderer).
*   **Interactive 3D Viewport:** Allow users to navigate the 3D scene:
    *   **Rotate:** Orbit the tree model using mouse dragging.
    *   **Pan:** Translate the view horizontally and vertically using mouse dragging (e.g., with the right mouse button).
    *   **Zoom:** Increase or decrease the view magnification using the mouse wheel.
*   **Graphical User Interface (GUI):** Provide controls (using ControlP5) for:
    *   Selecting generation algorithms (initially focusing on L-System presets/parameters).
    *   Adjusting algorithm parameters (e.g., L-System rules, iterations, angles, segment length/decay, randomness factors).
    *   Controlling line width and potentially other visual aspects.
    *   Initiating SVG export.
*   **SVG Export:** Export the *current 2D projection* of the 3D wireframe tree as an SVG file. The SVG should represent the lines as seen on the screen, suitable for plotting.
*   **Leaf Generation (Optional Integration):** Incorporate the previously developed leaf generation logic, allowing leaves (as outlines) to be placed at the tips of branches, potentially with GUI controls for enabling/disabling or selecting leaf types.

## 3. Technical Approach

*   **Platform:** Processing (Java Mode)
*   **Renderer:** P3D
*   **Libraries:**
    *   `ControlP5`: For GUI elements.
    *   `processing.svg`: For SVG export.
*   **Core Classes:**
    *   `LSystem`: Handles L-System rule storage, string rewriting (iteration).
    *   `Turtle`: Interprets the generated L-System string to create the 3D geometry. Uses a state (position, orientation matrix/vectors) and commands (move forward, turn, push/pop state).
    *   `Branch` (or similar segment representation): Might be implicitly handled by the Turtle drawing lines, or explicitly stored if needed for later manipulation (less likely with pure L-Systems).
    *   `Leaf`: The existing leaf generation class.
*   **L-System Implementation:**
    *   Define data structures for rules (e.g., `HashMap<Character, String>`).
    *   Implement the iterative string rewriting process.
    *   Define a mapping from L-System symbols to Turtle actions (e.g., 'F' -> draw forward, '+' -> turn right, '[' -> push state, ']' -> pop state).
*   **3D Navigation:** Implement `mousePressed()`, `mouseDragged()`, and `mouseWheel()` functions to update rotation (e.g., `rotX`, `rotY`), translation (`transX`, `transY`), and zoom (`zoom`) variables, similar to the `LissajousSpiral.pde` example.
*   **SVG Export:**
    *   When exporting, capture the necessary parameters (L-System state, view settings).
    *   Create a `PGraphicsSVG` object.
    *   Re-run the L-System generation and Turtle interpretation, drawing directly onto the `PGraphicsSVG` context.
    *   Apply the *same* view transformations (translate, rotate, scale) used in the main PGraphics display to the SVG context before drawing the tree, effectively drawing the 2D projection.

## 4. Potential Future Enhancements

*   Implement Space Colonization algorithm.
*   Advanced L-System features (stochastic rules, context-sensitive rules).
*   More sophisticated leaf placement and orientation.
*   Color options.
*   Saving/loading presets for generator parameters.
*   Basic environmental interaction (e.g., ground plane). 