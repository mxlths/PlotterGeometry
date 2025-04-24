# Geometron Algorithm Implementation Guide

## Core Algorithm Categories

### 1. 2D Pattern Generators

#### Lissajous Curves
```python
def generate_lissajous(a, b, delta, t_cycles, num_points):
    """Generate 2D Lissajous curve points."""
    points = []
    for i in range(num_points):
        t = map(i, 0, num_points, 0, TWO_PI * t_cycles)
        x = A * sin(a * t + delta)
        y = B * sin(b * t)
        points.append((x, y))
    return points
```

#### Interpolated Circles
```python
def generate_interpolated_circle(n, radius_offset, fluctuation):
    """Generate interpolated circle with random variations."""
    points = []
    for i in range(n):
        angle = TWO_PI * i / n
        radius = radius_offset + random(-fluctuation, fluctuation)
        x = radius * cos(angle)
        y = radius * sin(angle)
        points.append((x, y))
    return points
```

#### Circle Web
```python
def generate_circle_web(num_circles, points_per_circle, connection_density):
    """Generate web-like pattern connecting points on multiple circles."""
    circles = []
    for i in range(num_circles):
        circle = generate_circle_points(points_per_circle)
        circles.append(circle)
    
    connections = []
    for circle in circles:
        for point in circle:
            # Connect to other points based on density and bias
            connections.extend(create_connections(point, circles, connection_density))
    return connections
```

### 2. 3D Pattern Generators

#### 3D Lissajous
```python
def generate_3d_lissajous(a, b, c, delta, phi_z, t_cycles, num_points):
    """Generate 3D Lissajous curve points."""
    points = []
    for i in range(num_points):
        t = map(i, 0, num_points, 0, TWO_PI * t_cycles)
        x = A * sin(a * t + delta)
        y = B * sin(b * t)
        z = C * sin(c * t + phi_z)
        points.append((x, y, z))
    return points
```

#### Generative Cycloid
```python
def generate_cycloid(wheel1_attach, wheel2_attach, wheel1_speed, wheel2_speed, canvas_rot_speed):
    """Generate cycloid pattern from dual-wheel system."""
    points = []
    for t in range(sim_steps):
        # Calculate wheel positions
        wheel1_pos = calculate_wheel_position(wheel1_attach, wheel1_speed, t)
        wheel2_pos = calculate_wheel_position(wheel2_attach, wheel2_speed, t)
        
        # Calculate pen position
        pen_pos = calculate_pen_position(wheel1_pos, wheel2_pos)
        
        # Apply canvas rotation if in 3D mode
        if is_3d:
            pen_pos = rotate_3d(pen_pos, canvas_rot_speed * t)
            
        points.append(pen_pos)
    return points
```

### 3. Pattern Modifiers

#### Duplication and Scaling
```python
def duplicate_and_scale(points, cycle_count, initial_scale, scale_decay):
    """Create multiple scaled copies of a pattern."""
    result = []
    for i in range(cycle_count):
        scale = initial_scale * (scale_decay ** i)
        scaled_points = [scale_point(p, scale) for p in points]
        result.append(scaled_points)
    return result
```

#### Wave Modulation
```python
def apply_wave_modulation(points, wave_depth, wave_freq):
    """Apply sinusoidal displacement to points."""
    result = []
    for i, point in enumerate(points):
        t = map(i, 0, len(points), 0, TWO_PI)
        displacement = wave_depth * sin(wave_freq * t)
        normal = calculate_normal(point)
        displaced = point + normal * displacement
        result.append(displaced)
    return result
```

#### Moiré Effect
```python
def create_moire_effect(base_pattern, num_layers, rotation_offset, scale_offset):
    """Create Moiré effect by overlaying multiple transformed patterns."""
    layers = []
    for i in range(num_layers):
        rotation = i * rotation_offset
        scale = 1.0 + (i * scale_offset)
        transformed = transform_pattern(base_pattern, rotation, scale)
        layers.append(transformed)
    return layers
```

### 4. Contour Generation

#### Reaction-Diffusion Contours
```python
def generate_reaction_diffusion_contours(dA, dB, feed, kill, steps, contour_level):
    """Generate contour lines from reaction-diffusion simulation."""
    # Run simulation
    grid = run_reaction_diffusion(dA, dB, feed, kill, steps)
    
    # Extract contours
    contours = extract_contours(grid, contour_level)
    return contours
```

### 5. Recursive Patterns

#### Recursive Tiling
```python
def generate_recursive_tiling(grid_size, depth, mode):
    """Generate recursive tiling pattern."""
    if mode == "square":
        return generate_truchet_tiles(grid_size, depth)
    else:  # triangle
        return generate_triangle_subdivision(grid_size, depth)
```

### 6. L-System Fractals
```python
class LSystem:
    def __init__(self, axiom, rules, angle, segment_length):
        self.axiom = axiom
        self.rules = rules
        self.angle = angle
        self.segment_length = segment_length
        self.state_stack = []
        
    def generate(self, iterations):
        """Generate L-System string through iterations."""
        result = self.axiom
        for _ in range(iterations):
            result = self.apply_rules(result)
        return result
        
    def apply_rules(self, string):
        """Apply production rules to the string."""
        result = ""
        for char in string:
            result += self.rules.get(char, char)
        return result
        
    def interpret(self, string):
        """Interpret L-System string as geometry."""
        turtle = Turtle()
        for char in string:
            if char == 'F':
                turtle.forward(self.segment_length)
            elif char == '+':
                turtle.turn(self.angle)
            elif char == '-':
                turtle.turn(-self.angle)
            elif char == '[':
                self.state_stack.append(turtle.get_state())
            elif char == ']':
                turtle.set_state(self.state_stack.pop())
        return turtle.get_path()
```

### 7. Flow Fields
```python
def generate_flow_field(width, height, noise_scale, noise_strength):
    """Generate flow field using Perlin noise."""
    field = np.zeros((height, width, 2))  # 2D vector field
    for y in range(height):
        for x in range(width):
            # Sample noise at different scales for more interesting patterns
            angle = noise(x * noise_scale, y * noise_scale) * TWO_PI
            field[y, x] = [cos(angle) * noise_strength, sin(angle) * noise_strength]
    return field

def trace_particle(field, start_pos, steps, step_size):
    """Trace a particle through the flow field."""
    path = [start_pos]
    pos = np.array(start_pos)
    
    for _ in range(steps):
        # Get field vector at current position
        x, y = int(pos[0]), int(pos[1])
        if 0 <= x < field.shape[1] and 0 <= y < field.shape[0]:
            vec = field[y, x]
            # Update position
            pos += vec * step_size
            path.append(pos.copy())
        else:
            break
            
    return path
```

### 8. Space Colonization
```python
class SpaceColonization:
    def __init__(self, attractors, min_dist, max_dist):
        self.attractors = attractors
        self.min_dist = min_dist
        self.max_dist = max_dist
        self.nodes = []
        self.edges = []
        
    def grow(self, iterations):
        """Grow the tree through space colonization."""
        for _ in range(iterations):
            # Find closest attractors for each node
            node_attractors = self.find_closest_attractors()
            
            # Grow nodes toward their attractors
            self.grow_nodes(node_attractors)
            
            # Remove attractors that are too close
            self.remove_attractors()
            
    def find_closest_attractors(self):
        """Find closest attractors for each node."""
        node_attractors = {}
        for node in self.nodes:
            closest = []
            for attractor in self.attractors:
                dist = distance(node.pos, attractor)
                if dist < self.max_dist:
                    closest.append((attractor, dist))
            if closest:
                node_attractors[node] = closest
        return node_attractors
        
    def grow_nodes(self, node_attractors):
        """Grow nodes toward their attractors."""
        for node, attractors in node_attractors.items():
            # Calculate average direction to attractors
            direction = np.zeros(3)
            for attractor, _ in attractors:
                direction += normalize(attractor - node.pos)
            direction = normalize(direction)
            
            # Create new node
            new_pos = node.pos + direction * self.min_dist
            new_node = Node(new_pos)
            self.nodes.append(new_node)
            self.edges.append((node, new_node))
```

### 9. 3D Tree Generation
```python
class TreeGenerator3D:
    def __init__(self, trunk_length, branch_angle, branch_length_ratio):
        self.trunk_length = trunk_length
        self.branch_angle = branch_angle
        self.branch_length_ratio = branch_length_ratio
        
    def generate(self, depth):
        """Generate 3D tree structure."""
        self.branches = []
        self.generate_branch(
            start=np.array([0, 0, 0]),
            direction=np.array([0, -1, 0]),
            length=self.trunk_length,
            depth=depth
        )
        return self.branches
        
    def generate_branch(self, start, direction, length, depth):
        """Recursively generate branches."""
        if depth <= 0:
            return
            
        # Calculate end point
        end = start + direction * length
        
        # Add branch
        self.branches.append((start, end))
        
        if depth > 1:
            # Generate child branches
            for angle in [-self.branch_angle, self.branch_angle]:
                # Rotate direction around random axis
                axis = np.random.rand(3)
                axis = normalize(axis)
                rot_dir = rotate_around_axis(direction, axis, angle)
                
                # Recursive call with reduced length
                self.generate_branch(
                    end,
                    rot_dir,
                    length * self.branch_length_ratio,
                    depth - 1
                )
```

## Implementation Guidelines

### 1. Algorithm Interface
- Each algorithm should implement a standard interface:
  ```python
  class Algorithm:
      def generate(self, parameters):
          """Generate geometry based on parameters."""
          pass
      
      def get_parameters(self):
          """Return default parameters."""
          pass
      
      def validate_parameters(self, parameters):
          """Validate parameter values."""
          pass
  ```

### 2. Parameter Management
- Use a parameter system that supports:
  - Numeric ranges with min/max values
  - Boolean toggles
  - Enumerated choices
  - Color selection
  - File paths

### 3. Geometry Representation
- Use a common geometry format:
  ```python
  class Geometry:
      def __init__(self):
          self.points = []  # List of (x,y) or (x,y,z) tuples
          self.lines = []   # List of line segments
          self.curves = []  # List of curve definitions
  ```

### 4. Transformation System
- Implement a transformation stack:
  ```python
  class Transform:
      def __init__(self):
          self.translation = (0, 0, 0)
          self.rotation = (0, 0, 0)
          self.scale = (1, 1, 1)
          
      def apply(self, geometry):
          """Apply transformation to geometry."""
          pass
  ```

### 5. Export System
- Support multiple export formats:
  ```python
  class Exporter:
      def export_svg(self, geometry, filename):
          """Export geometry to SVG."""
          pass
      
      def export_dxf(self, geometry, filename):
          """Export geometry to DXF."""
          pass
  ```

## Best Practices

1. **Performance Optimization**
   - Use numpy for vectorized operations
   - Implement caching for expensive calculations
   - Support progressive rendering for complex patterns

2. **Error Handling**
   - Validate all parameters before processing
   - Provide meaningful error messages
   - Handle edge cases gracefully

3. **Documentation**
   - Document all parameters and their effects
   - Include example parameter sets
   - Provide visual examples of pattern variations

4. **Testing**
   - Unit tests for core algorithms
   - Visual regression tests
   - Performance benchmarks

5. **Extensibility**
   - Design for easy addition of new algorithms
   - Support custom parameter types
   - Allow for custom geometry types