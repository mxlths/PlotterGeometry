# Plotter Geometry Sketches

This repository contains Processing sketches designed for generating vector line art suitable for pen plotters.

## Sketches

### 1. Lissajous Curve (2D)

**File:** `LissajousCurve/LissajousCurve.pde`

**Description:**
Generates classic 2D Lissajous curves with extensive modulation options. Allows for creating complex patterns through layered effects like rotation, duplication, wave modulation, and offset scaling cycles.

**Controls:**

*   **Curve Shape:**
    *   `Amplitude X (A)`: Controls the maximum horizontal displacement.
    *   `Amplitude Y (B)`: Controls the maximum vertical displacement.
    *   `Frequency X (a)`: Sets the frequency of the horizontal oscillation.
    *   `Frequency Y (b)`: Sets the frequency of the vertical oscillation.
    *   `Phase Shift (deg)`: Sets the phase difference (delta) between X and Y oscillations (in degrees).
    *   `T Cycles (x 2*PI)`: Determines how many full cycles (0 to 2*PI) the parameter `t` goes through to draw the curve.
*   **Drawing Style:**
    *   `Scale Factor`: Overall scaling of the entire pattern.
    *   `Points (Resolution)`: Number of vertices used to draw the curve (higher means smoother).
    *   `Line Width`: Thickness of the lines.
    *   `Draw Mode (0/1)`: Selects drawing mode: 0 for the standard curve, 1 for perpendicular lines along the curve's path.
    *   `Line Density`: (Mode 1) Number of perpendicular lines to draw.
    *   `Perp Line Len`: (Mode 1) Length of each perpendicular line.
*   **Duplication & Rotation:**
    *   `Base Rotation (deg)`: Initial rotation applied to the base curve(s).
    *   `Rotation Step (deg)`: Angular rotation applied between successive duplicated curves (used in offset cycle mode).
*   **Wave Modulation:**
    *   `Wave Depth (px)`: Amplitude of the sinusoidal displacement applied perpendicular to the curve.
    *   `Wave Freq`: Frequency of the wave modulation along the curve's length (relative to T Cycles).
*   **Offset Cycles (Duplication Effect):**
    *   `Offset Cycle Count`: Number of steps within a single shrink/grow cycle.
    *   `Num Offset Cycles`: How many times the full shrink/grow cycle repeats.
    *   `Initial Scale Off`: Starting scale factor for the outermost curve relative to the base `scaleFactor`.
    *   `Scale Decay`: Multiplicative factor applied to the scale offset at each step in the cycle.
*   **Export:**
    *   `Export SVG` button: Saves the current visual as an SVG file.
    *   `S` key: Keyboard shortcut for SVG export.

### 2. Lissajous Curve (3D)

**File:** `Lissajous3D/Lissajous3D.pde`

**Description:**
Generates a Lissajous curve in 3D space. Allows viewing the curve from different angles using rotation controls (both GUI and mouse drag). Exports the *projected* 2D view of the 3D curve as an SVG file.

**Controls:**

*   **Curve Shape:**
    *   `Amplitude X (A)`: Controls the maximum displacement along the X-axis.
    *   `Amplitude Y (B)`: Controls the maximum displacement along the Y-axis.
    *   `Amplitude Z (C)`: Controls the maximum displacement along the Z-axis.
    *   `Frequency X (a)`: Sets the frequency of oscillation along the X-axis.
    *   `Frequency Y (b)`: Sets the frequency of oscillation along the Y-axis.
    *   `Frequency Z (c)`: Sets the frequency of oscillation along the Z-axis.
    *   `Phase Shift X (deg)`: Sets the phase difference (delta) for the X oscillation (relative to `sin(a*t)`).
    *   `Phase Shift Z (deg)`: Sets the phase difference (phi_z) for the Z oscillation (relative to `sin(c*t)`).
    *   `T Cycles (x 2*PI)`: Determines how many full cycles (0 to 2*PI) the parameter `t` goes through to draw the curve.
*   **Drawing & View:**
    *   `Scale Factor`: Overall scaling of the 3D curve.
    *   `Points (Resolution)`: Number of vertices used to draw the curve.
    *   `Line Width`: Thickness of the curve line.
    *   `Rotation X (deg)`: Base rotation around the X-axis (applied via GUI).
    *   `Rotation Y (deg)`: Base rotation around the Y-axis (applied via GUI).
    *   `Rotation Z (deg)`: Base rotation around the Z-axis (applied via GUI).
    *   *Mouse Drag*: Click and drag on the canvas (outside the GUI panel) to rotate the view around the X and Y axes.
*   **Export:**
    *   `Export SVG` button: Saves the current *projected* 2D view as an SVG file.
    *   `S` key: Keyboard shortcut for SVG export.

### 3. Circle Web

**File:** `CircleWeb/CircleWeb.pde`

**Description:**
Creates intricate web-like patterns by connecting points distributed around several primary circles. Points can be connected with straight lines, quadratic curves, or bezier curves, allowing for various visual styles.

**Controls:**

*   **Primary Circles:**
    *   `Number of Circles`: How many main circles to arrange.
    *   `Circle Radius`: The radius of the primary circles.
    *   `Distance from Center`: How far the center of each primary circle is from the canvas center.
    *   `Points per Circle`: How many points are distributed around each primary circle.
    *   `Draw Primary Circles`: Toggle to show/hide the primary circles themselves.
*   **Connections:**
    *   `Connections per Point`: Maximum number of connections originating from each point.
    *   `Density`: Controls the overall density of connections made.
    *   `Connection Bias`: Influences the likelihood of connecting to points on different circles (vs. the same circle).
    *   `Line Mode (0-2)`: 0 for quadratic curves, 1 for straight lines, 2 for bezier curves.
    *   `Curve Tension`: (Mode 0/2) Controls the amount of curvature for quadratic/bezier lines.
*   **Drawing Style:**
    *   `Line Weight`: Thickness of the connecting lines.
    *   `Use Transparency`: Toggle whether lines should have transparency.
    *   `Line Alpha (0-255)`: Sets the alpha value (opacity) if transparency is enabled.
*   **Actions:**
    *   `Regenerate` button: Creates a new pattern based on the current settings.
    *   `Export SVG` button: Saves the current pattern as an SVG file.
    *   `S` key: Keyboard shortcut for SVG export.

### 4. Interpolated Circle

**File:** `InterpolatedCircle/InterpolatedCircle.pde`

**Description:**
Generates patterns based on interpolating shapes derived from points on a circle. It features a duplication mechanism that creates concentric, scaled, and slightly randomized copies of the base shape, forming intricate layered effects. Can draw the shapes as curves or as sets of radial lines.

**Controls:**

*   **Base Shape:**
    *   `Points (N)`: Number of points defining the base shape.
    *   `Radius Offset`: Base offset applied to the radius of each point (influences overall size and shape).
    *   `Fluctuation`: Amount of random variation applied to the radius of each point in each duplicated shape.
*   **Duplication Cycle:**
    *   `Cycle Count`: Number of duplicated shapes in one shrink/grow cycle.
    *   `Number of Cycles`: How many times the full shrink/grow cycle repeats.
    *   `Initial Scale`: Relative scale factor of the outermost shape compared to the base shape.
    *   `Scale Decay`: Multiplicative factor applied to the scale offset at each step in the cycle (controls shrinking/growing speed).
*   **Drawing Style:**
    *   `Draw Mode (0/1)`: 0 for closed curve shapes, 1 for radial lines originating from the center towards the curve points.
    *   `Radial Length`: (Mode 1) Length of the radial lines (relative to radius units).
    *   `Segments Per Curve`: (Mode 1) Number of points along the curve path where radial lines are drawn.
    *   `Line Rotation (deg)`: (Mode 1) Angular offset applied to the set of radial lines for each duplicated shape.
*   **Actions:**
    *   `Regenerate` button: Recalculates random values and redraws the entire pattern.
    *   `Export SVG` button: Saves the current pattern as an SVG file.
    *   `S` key: Keyboard shortcut for SVG export.

### 5. Interpolated Moiré

**File:** `InterpolatedMoire/InterpolatedMoire.pde`

**Description:**
Builds upon the `InterpolatedCircle` concept by adding the ability to overlay multiple layers of the generated pattern. Each layer can have slight variations in rotation, scale, center position, point count, and alpha, creating complex Moiré interference patterns.

**Controls:**

*   **Base Shape & Duplication:** (Inherited from Interpolated Circle)
    *   `Points (N)`, `Radius Offset`, `Fluctuation`
    *   `Cycle Count`, `Number of Cycles`, `Initial Scale`, `Scale Decay`
    *   `Draw Mode (0/1)`, `Radial Length`, `Segments Per Curve`, `Line Rotation (deg)`
*   **Moiré Effect:**
    *   `Enable Moiré Effect`: Toggle the multi-layer Moiré effect on/off.
    *   `Number of Layers`: How many pattern layers to overlay.
    *   `Layer Rotation`: Angular offset (degrees) applied cumulatively to each subsequent layer.
    *   `Layer Scale Offset`: Scale factor applied cumulatively to each subsequent layer.
    *   `Layer Point Offset`: Difference in the number of points (`N`) between subsequent layers.
    *   `Layer Center Offset X/Y`: Controls the X/Y displacement of each layer's center relative to the previous layer.
    *   `Layer Alpha`: Controls the transparency (0-255) of each layer.
*   **Actions:**
    *   `Regenerate` button: Recalculates random values and redraws the entire pattern.
    *   `Export SVG` button: Saves the current pattern as an SVG file.
    *   `S` key: Keyboard shortcut for SVG export.

### 6. Reaction-Diffusion Contours

**File:** `ReactionDiffusion/ReactionDiffusion.pde`

**Description:**
Simulates the Gray-Scott model of reaction-diffusion, creating complex organic patterns (spots, stripes, labyrinths). It then extracts contour lines (isolines) at a specific concentration level of one of the simulated chemicals, generating line art suitable for plotting.

**Controls:**

*   **Simulation Parameters:**
    *   `Diffusion A (dA)` / `Diffusion B (dB)`: Control how fast chemicals A and B spread. Affects the *scale* of the resulting patterns. (Default: dA=1.0, dB=0.5)
    *   `Feed Rate (f)`: Rate at which chemical A is added. **Critical parameter.** Small changes strongly influence the pattern type. (Default: 0.055)
    *   `Kill Rate (k)`: Rate at which chemical B is removed. **Critical parameter.** Works with `feed` to determine the pattern type. (Default: 0.062)
    *   `Time Step (dt)`: Simulation time step size. Affects stability; may need decreasing if simulation behaves erratically with extreme parameters. (Default: 1.0)
    *   `Total Sim Steps`: How many steps the simulation runs before generating the final contours. Determines pattern maturity. (Default: 5000)
*   **Contouring:**
    *   `Contour Level`: The chemical B concentration threshold for drawing lines. Needs to be within the actual min/max range of B in the final pattern to produce output. (Default: 0.5)
    *   `Line Width`: Visual thickness of the contour lines.
*   **Actions:**
    *   `Regenerate` button: Restarts the simulation with the current parameters and generates final contours.
    *   `Export SVG` button: Saves the current contour lines as an SVG file.
    *   `S` key: Keyboard shortcut for SVG export.

### 7. Generative Cycloid

**File:** `GenerativeCycloid/GenerativeCycloid.pde`

**Description:**
Simulates a dual-wheel cycloid drawing machine (similar to a harmonograph or spirograph), where two wheels with attachment points are connected by rods to a pen. Offers both 2D mode with standard circular paths and 3D mode where the drawing board rotates in the Z-axis over time, creating three-dimensional helical structures.

**Controls:**

*   **Simulation Parameters:**
    *   `Sim Steps`: Maximum number of steps in the simulation.
    *   `Wheel 1/2 Attach Dist`: Distance from the center of each wheel to its attachment point.
    *   `Wheel 1/2 Speed (rad/s)`: Angular velocity of each wheel.
    *   `Canvas Rot Speed (rad/s)`: How fast the canvas rotates in either 2D or 3D mode.
*   **Drawing Mode:**
    *   `3D Canvas Rotation`: Toggle between 2D mode (flat drawing) and 3D mode (helical drawing).
    *   `Instant Render`: Toggle between animated drawing and immediate calculation of the entire path.
*   **View Control:**
    *   *Mouse Drag*: Click and drag on the canvas to rotate the 3D view.
*   **Actions:**
    *   `Restart Sim` button: Recalculates the entire path with current settings.
    *   `Export SVG` button: Saves the current pattern as an SVG file, preserving the 3D perspective when in 3D mode.

### 8. Recursive Tiling

**File:** `RecursiveTiling/RecursiveTiling.pde`

**Description:**
Generates geometric patterns by recursively subdividing space and applying pattern rules. Features two main modes: Square Truchet tiles (creating complex interwoven curves) and Triangle subdivision (creating fractal-like triangular patterns).

**Controls:**

*   **Tiling Parameters:**
    *   `Grid Columns/Rows`: Initial grid dimensions (for Square mode).
    *   `Recursion Depth`: How many levels of subdivision to apply.
    *   `Arc Resolution`: Number of line segments used to draw each curved section (Square mode).
    *   `Line Width`: Thickness of the pattern lines.
    *   `Random Orient.`: Toggle between random and deterministic tile orientation (Square mode).
    *   `Tiling Mode`: Select between Square (Truchet) and Triangle (Midpoint) patterns.
*   **Rotation Parameters:**
    *   `Num Rot. Copies`: Number of rotated duplicates to create.
    *   `Rotation (Deg)`: Angular increment between each rotated copy.
*   **Actions:**
    *   `Regenerate` button: Creates a new pattern based on the current settings.
    *   `Export SVG` button: Saves the current pattern as an SVG file.

### 9. Interpolated Lissajous

**File:** `InterpolatedLissajous/InterpolatedLissajous.pde`

**Description:**
Combines the concepts of interpolated curves with Lissajous figures, creating complex patterns with layered Lissajous curves that can be modulated and transformed. Provides extensive control over both the interpolation parameters and Lissajous parameters.

**Controls:**

*   **Interpolation Parameters:**
    *   `Interpolation Points`: Number of points to interpolate between.
    *   `Base Radial Length`: Base size of the radial pattern.
    *   `Radial Variation`: Amount of variation in the radial distances.
    *   `Cycle Repeat`: Number of times to repeat the scaling cycle.
    *   `Max Scale`: Maximum relative scale for the pattern.
*   **Lissajous Parameters:**
    *   `Use Lissajous`: Toggle to enable/disable Lissajous curves.
    *   `Freq X/Y`: Frequency parameters for the Lissajous curves.
    *   `Lissajous Layers`: Number of Lissajous curves to draw with varying parameters.
    *   `Lissajous Cycles`: Number of cycles for each Lissajous curve.
*   **Style Controls:**
    *   `Line Weight`: Thickness of the drawn lines.
    *   `Line Opacity`: Transparency level of the lines.
*   **Actions:**
    *   `Regenerate Pattern` button: Creates a new pattern with the current settings.
    *   `Export SVG` button: Saves the current pattern as an SVG file.

### 10. Polar Spirograph

**File:** `PolarSpirograph/PolarSpirograph.pde`

**Description:**
Creates complex spirograph-like patterns using polar equations. The pattern is generated from the formula r = scaleFactor * (baseRadius + A1*sin(f1*θ + p1) + A2*sin(f2*θ + p2) + A3*sin(f3*θ + p3)), allowing for intricate flower-like and star-like patterns.

**Controls:**

*   **Pattern Parameters:**
    *   `Scale Factor`: Overall size scaling of the pattern.
    *   `Min Gap Radius`: Minimum radius before scaling, ensuring a hole in the center.
    *   `Amplitude (A1/A2/A3)`: Controls the amplitude of each sine term.
    *   `Frequency (f1/f2/f3)`: Sets the frequency of each sine term relative to θ.
    *   `Phase (deg)`: Phase offset in degrees for each sine term.
*   **Drawing Parameters:**
    *   `Theta Cycles`: How many full 2*PI cycles θ goes through.
    *   `Num Points`: Resolution of the curve (higher for smoother curves).
    *   `Line Width`: Thickness of the pattern lines.
*   **Actions:**
    *   `Regenerate` button: Creates a new pattern with the current settings.
    *   `Export SVG` button: Saves the current pattern as an SVG file.

### 11. L-System Fractal

**File:** `LSystemFractal/LSystemFractal.pde`

**Description:**
Implements L-System fractals, using a set of production rules to generate complex recursive patterns. Includes turtle graphics interpretation to draw the generated L-System strings, and several built-in presets (Koch snowflake, Sierpinski triangle, Dragon curve).

**Controls:**

*   **L-System Definition:**
    *   `Axiom`: Starting string for the L-System.
    *   `Rule F/X/Y`: Production rules for replacing each symbol during iterations.
    *   `Angle (Deg)`: Turning angle for the turtle graphics interpreter.
    *   `Iterations`: Number of times to apply the production rules.
*   **Drawing Parameters:**
    *   `Initial Length`: Starting length of line segments.
    *   `Length Factor`: How much to scale down length at each recursive level.
    *   `Line Width`: Thickness of the drawn lines.
*   **Presets:**
    *   `Preset: Koch/Sierpinski/Dragon` buttons: Quick access to common L-System configurations.
*   **Actions:**
    *   `Regenerate` button: Creates a new pattern with the current settings.
    *   `Export SVG` button: Saves the current pattern as an SVG file.

### 12. Perlin Noise Flow

**File:** `PerlinNoiseFlow/PerlinNoiseFlow.pde`

**Description:**
Generates flowing patterns based on Perlin noise fields. Virtual particles trace paths through a 2D noise field, creating organic, fluid-like patterns suitable for plotting.

**Controls:**

*   **Field Parameters:**
    *   `Noise Scale`: Detail level of the noise field (lower = smoother).
    *   `Noise Seed`: Seed for the 3rd dimension of noise (allows different field patterns).
    *   `Flow Strength`: How strongly the noise angle affects direction.
*   **Particle Parameters:**
    *   `Num Particles`: Number of particles to trace through the field.
    *   `Particle Steps`: Max number of steps each particle takes (path length).
    *   `Step Length`: How far a particle moves in each step.
    *   `Wrap Edges`: Toggle whether particles wrap around screen edges.
*   **Drawing Style:**
    *   `Line Width`: Thickness of the particle paths.
    *   `Line Alpha`: Transparency of the paths.
*   **Actions:**
    *   `Regenerate` button: Creates a new flow field pattern.
    *   `Export SVG` button: Saves the current pattern as an SVG file.

### 13. Sacred Geometry

**File:** `SacredGeometry/SacredGeometry.pde`

**Description:**
Generates various sacred geometry patterns including the Flower of Life, Seed of Life, Metatron's Cube, Sri Yantra, and Vesica Piscis. Creates precise geometric constructions following traditional proportions and relationships.

**Controls:**

*   **Pattern Selection:**
    *   `Pattern Type` dropdown: Choose between different sacred geometry patterns.
*   **Pattern Parameters:**
    *   `Iterations`: Controls the complexity for recursive patterns like Flower of Life.
    *   `Circle Detail`: Number of segments used to draw circles.
    *   `Stroke Weight`: Thickness of the pattern lines.
    *   `Show Guides`: Toggle to show/hide guide lines and constructions.
*   **Actions:**
    *   `Save SVG` button: Exports the current pattern as an SVG file.

### 14. Islamic Geometric Pattern

**File:** `Islamic Geometry/IslamicPattern.pde`

**Description:**
Generates traditional Islamic geometric patterns based on repeating tiled motifs. Creates an 8-pointed star pattern that repeats across the canvas in a regular grid, following traditional geometric principles.

**Parameters:**
*   `Pattern Size`: Size of the basic repeating unit.
*   `Stroke Weight`: Thickness of the pattern lines.

**Features:**
*   Automatically creates a tiled pattern that extends across the canvas.
*   Generates a clean SVG file suitable for plotting.
*   Uses the 8-pointed star as the base motif, a common element in Islamic geometric art.
