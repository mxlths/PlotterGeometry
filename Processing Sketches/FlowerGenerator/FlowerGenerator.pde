import controlP5.*;
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class
import processing.event.MouseEvent; // For mouse wheel event
import java.util.HashMap; // For L-System rules
import java.util.Stack; // For Turtle state
import java.util.ArrayList; // For Turtle state stack

// --- ControlP5 GUI ---
ControlP5 cp5;
PFont labelFont;

// --- Generator Selection ---
String[] generatorTypes = {"L-System"}; // Add others later: "Space Colonization"
String selectedGeneratorType = "L-System";
TreeGenerator currentGenerator;

// --- L-System Parameters (Defaults for a simple 3D plant) ---
String lSystemAxiom = "X";
// Rules: One rule per line, format: Character=ReplacementString
// Example:
// X=F[+X][-X]FX
// F=FF
String lSystemRulesInput = "X=F[+X][-X]FX\nF=FF";
float lSystemAngle = 25.7; // Degrees
float lSystemSegmentLength = 5.0;
int lSystemIterations = 4;

// --- Drawing Parameters ---
float lineWidth = 1.0;
int guiWidth = 250; // Increased width for L-System controls
int drawingWidth = 800;
int canvasHeight = 600;

// --- 3D View Parameters ---
float rotX = 0;
float rotY = 0;
float zoom = 1.0;
float transX = 0;
float transY = 0;
int lastMouseX = 0;
int lastMouseY = 0;

// --- SVG Export ---
boolean recordSVG = false;
String svgOutputPath = null;

// --- Settings Function ---
void settings() {
  // Use P3D renderer for 3D
  size(drawingWidth + guiWidth, canvasHeight, P3D);
  smooth(4); // Add anti-aliasing
}

// --- Setup Function ---
void setup() {
  cp5 = new ControlP5(this);
  labelFont = createFont("Arial", 12, true);

  // Initialize 3D view
  resetView();

  // --- GUI Controls ---
  int inputX = 10 + 120;
  int inputY = 10;
  int inputW = guiWidth - inputX - 10; // Adjust width based on label
  int inputH = 20;
  int spacing = 25;
  int currentY = inputY;
  int labelW = 110;

  // Generator Type Dropdown
  cp5.addLabel("Generator Type:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  DropdownList generatorDropdown = cp5.addDropdownList("generatorTypeSelector")
     .setPosition(inputX, currentY).setSize(inputW, 100) // Height expands
     .setItemHeight(20).setBarHeight(inputH)
     .setColorBackground(color(60)).setColorActive(color(255, 128))
     .setCaptionLabel("Select Generator");
  for (int i = 0; i < generatorTypes.length; i++) {
    generatorDropdown.addItem(generatorTypes[i], i);
  }
  // Find and set initial value
  for(int i=0; i<generatorTypes.length; i++) {
    if (generatorTypes[i].equals(selectedGeneratorType)) {
      generatorDropdown.setValue(i);
      break;
    }
  }

  // --- L-System Specific Controls (Group them) ---
  Group lSystemGroup = cp5.addGroup("lSystemControls")
                          .setLabel("L-System Parameters")
                          .setBackgroundColor(color(220, 220, 220)) // Lighter group background
                          .setBackgroundHeight(250) // Adjust as needed
                          .setPosition(10, currentY + spacing + 20) // Position group below dropdown
                          .setWidth(guiWidth - 20);

  int groupY = 10; // Relative Y within the group
  int groupLabelW = 60;
  int groupInputX = 10 + groupLabelW + 5;
  int groupInputW = (guiWidth - 20) - groupInputX - 10;

  // Axiom
  cp5.addLabel("Axiom:")
     .setPosition(10, groupY + 4).setSize(groupLabelW, inputH)
     .setColorValue(color(0)).setFont(labelFont).moveTo(lSystemGroup);
  cp5.addTextfield("lSystemAxiom")
     .setPosition(groupInputX, groupY).setSize(groupInputW, inputH)
     .setText(lSystemAxiom).moveTo(lSystemGroup);

  groupY += spacing;
  // Rules (Text Area)
  cp5.addLabel("Rules:")
     .setPosition(10, groupY + 4).setSize(groupLabelW, inputH)
     .setColorValue(color(0)).setFont(labelFont).moveTo(lSystemGroup);
  cp5.addTextarea("lSystemRulesInput")
     .setPosition(groupInputX, groupY).setSize(groupInputW, inputH * 3)
     .setLineHeight(14)
     .setText(lSystemRulesInput).moveTo(lSystemGroup);

  groupY += spacing * 3 + 5; // Extra space after text area
  // Iterations
  cp5.addLabel("Iterations:")
     .setPosition(10, groupY + 4).setSize(groupLabelW+10, inputH)
     .setColorValue(color(0)).setFont(labelFont).moveTo(lSystemGroup);
  cp5.addSlider("lSystemIterations")
     .setPosition(groupInputX, groupY).setSize(groupInputW, inputH)
     .setRange(0, 10).setNumberOfTickMarks(11)
     .setValue(lSystemIterations).setDecimalPrecision(0)
     .showTickMarks(true).snapToTickMarks(true).moveTo(lSystemGroup);

  groupY += spacing;
  // Angle
  cp5.addLabel("Angle:")
     .setPosition(10, groupY + 4).setSize(groupLabelW, inputH)
     .setColorValue(color(0)).setFont(labelFont).moveTo(lSystemGroup);
  cp5.addSlider("lSystemAngle")
     .setPosition(groupInputX, groupY).setSize(groupInputW, inputH)
     .setRange(0, 90).setValue(lSystemAngle).setDecimalPrecision(1)
     .moveTo(lSystemGroup);

  groupY += spacing;
  // Length
  cp5.addLabel("Length:")
     .setPosition(10, groupY + 4).setSize(groupLabelW, inputH)
     .setColorValue(color(0)).setFont(labelFont).moveTo(lSystemGroup);
  cp5.addSlider("lSystemSegmentLength")
     .setPosition(groupInputX, groupY).setSize(groupInputW, inputH)
     .setRange(0.1, 20).setValue(lSystemSegmentLength).setDecimalPrecision(1)
     .moveTo(lSystemGroup);

  currentY += spacing + 20 + lSystemGroup.getHeight() + 10; // Update currentY below the group

  // Line Width
  cp5.addLabel("Line Width:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addSlider("lineWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setRange(0.1, 10).setValue(lineWidth).setDecimalPrecision(1);

  // --- View Reset Button ---
  currentY += spacing + 10;
  cp5.addButton("viewReset")
     .setLabel("Reset View")
     .setPosition(10, currentY)
     .setSize(100, inputH + 5);

  // --- Export Button ---
  cp5.addButton("exportSVG")
     .setLabel("Export SVG")
     .setPosition(120, currentY)
     .setSize(100, inputH + 5);

  // --- Initial Generator Setup ---
  createGenerator();
}

// --- Draw Function ---
void draw() {
  // --- Handle SVG Recording ---
  if (recordSVG) {
    try {
      println("Creating SVG...");
      // Use drawingWidth for SVG size, not full width
      PGraphicsSVG svg = (PGraphicsSVG) createGraphics(drawingWidth, height, SVG, svgOutputPath);
      svg.beginDraw();
      svg.background(255); // Set SVG background explicitly if needed

      // Apply the SAME transformations as the main view to the SVG
      svg.translate(drawingWidth / 2.0 + transX, height / 2.0 + transY);
      svg.rotateX(rotX);
      svg.rotateY(rotY);
      svg.scale(zoom);
      // Move origin to bottom center for drawing the tree
      svg.translate(0, height * 0.45); // Match the main draw transform

      // Tell the generator to draw to the SVG context
      if (currentGenerator != null) {
        currentGenerator.draw(svg);
      } else {
        println("SVG Error: No generator active.");
      }

      svg.endDraw();
      svg.dispose();
      println("SVG potentially saved to: " + svgOutputPath);

      // Confirmation Dialog
      File outputFile = new File(svgOutputPath);
      if (outputFile.exists() && outputFile.length() > 0) {
          JOptionPane.showMessageDialog(null, "SVG exported successfully to:\n" + svgOutputPath, "SVG Export", JOptionPane.INFORMATION_MESSAGE);
      } else {
          JOptionPane.showMessageDialog(null, "Error: SVG file may not have been created or is empty.\nCheck console output.", "SVG Export Error", JOptionPane.ERROR_MESSAGE);
      }
    } catch (Exception e) {
      println("Error creating SVG: " + e.getMessage());
      e.printStackTrace();
      JOptionPane.showMessageDialog(null, "Error creating SVG: " + e.getMessage(), "SVG Export Error", JOptionPane.ERROR_MESSAGE);
    } finally {
      recordSVG = false;
      svgOutputPath = null;
      System.gc();
    }
  }

  // --- Main Screen Drawing ---
  background(240); // Light gray background for drawing area

  // --- Draw GUI Background ---
  fill(200); // Darker gray for the panel
  noStroke(); // No outline for the panel
  rect(drawingWidth, 0, guiWidth, height);

  // --- Draw the 3D Scene ---
  pushMatrix(); // Isolate 3D scene transformations

  // Apply 3D camera transformations to the main drawing area
  translate(drawingWidth / 2.0 + transX, height / 2.0 + transY);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoom);

  // Center the tree base (bottom-middle of the drawing area) after camera transforms
  // Origin is now where the base of the tree should start
  translate(0, height * 0.45); // Move origin down slightly more than half

  // Draw the generated structure using the current generator
  if (currentGenerator != null) {
    currentGenerator.draw(g); // Draw to the main PGraphics (g)
  } else {
    // Optionally draw placeholder text if no generator
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("No generator created.", 0, -height*0.2); // Adjusted position
  }

  popMatrix(); // Restore transformations before drawing UI

  // --- Draw UI ---
  hint(DISABLE_DEPTH_TEST); // Ensure UI is drawn on top
  camera(); // Reset camera for UI
  noLights();
  // Draw GUI Panel Title
  fill(0);
  textAlign(CENTER, TOP);
  textSize(14);
  text("Controls", drawingWidth + guiWidth/2, 5);

  cp5.draw(); // Draw ControlP5 elements
  hint(ENABLE_DEPTH_TEST);
}

// --- Generator Instantiation ---
void createGenerator() {
  println("Creating/Updating generator: " + selectedGeneratorType);
  if (selectedGeneratorType.equals("L-System")) {
    HashMap<Character, String> rules = parseLSystemRules(lSystemRulesInput);
    if (rules.isEmpty() && !lSystemRulesInput.trim().isEmpty()) {
        println("Warning: L-System rules seem invalid. Check format (e.g., F=FF).");
    }
    currentGenerator = new LSystemGenerator(lSystemAxiom, rules, lSystemIterations,
                                          radians(lSystemAngle), lSystemSegmentLength,
                                          lineWidth);
  }
  // else if (selectedGeneratorType.equals("Space Colonization")) {
  //   currentGenerator = new SpaceColonizationGenerator(/* params */);
  // }
  else {
    println("Unknown generator type selected: " + selectedGeneratorType);
    currentGenerator = null;
  }

  // Trigger generation if the generator was created successfully
  if (currentGenerator != null) {
    try {
      currentGenerator.generate(); // Perform the generation step
    } catch (Exception e) {
       println("Error during generation: " + e);
       e.printStackTrace();
       currentGenerator = null; // Invalidate generator on error
    }
  }
}

// Helper to parse rules from TextArea
HashMap<Character, String> parseLSystemRules(String rulesText) {
    HashMap<Character, String> rules = new HashMap<Character, String>();
    if (rulesText == null) return rules; // Handle null input
    String[] lines = rulesText.trim().split("\\r?\\n"); // Split by newline
    for (String line : lines) {
        String[] parts = line.split("=", 2); // Split by the first '=' only
        if (parts.length == 2) {
            String keyStr = parts[0].trim();
            String valueStr = parts[1].trim();
            if (keyStr.length() == 1 && !valueStr.isEmpty()) { // Ensure key is a single char and value exists
                rules.put(keyStr.charAt(0), valueStr);
            } else {
                 println("Skipping invalid rule format: '" + line + "'");
            }
        } else if (!line.trim().isEmpty()) {
             println("Skipping invalid rule format (no '=' found): '" + line + "'");
        }
    }
    return rules;
}


// ============================================
//      Generator Interface and Classes
// ============================================

// --- Generator Interface ---
interface TreeGenerator {
  void generate(); // Generate the internal representation (e.g., L-System string)
  void draw(PGraphics pg); // Draw the structure to the given graphics context
}

// --- L-System Generator ---
class LSystemGenerator implements TreeGenerator {
  String axiom;
  HashMap<Character, String> rules;
  int iterations;
  float angleRadians; // Store angle in radians internally
  float length;
  float strokeWidth;
  String currentString; // Stores the result after generation

  // Constructor
  LSystemGenerator(String ax, HashMap<Character, String> r, int iter, float angRad, float len, float sw) {
    axiom = (ax == null || ax.isEmpty()) ? "F" : ax; // Default axiom if empty
    rules = r;
    iterations = max(0, iter); // Ensure non-negative iterations
    angleRadians = angRad;
    length = len;
    strokeWidth = sw;
    currentString = ""; // Initialize as empty, generate() will populate it
  }

  @Override
  void generate() {
    currentString = axiom; // Start with the axiom for this generation pass
    println("Generating L-System: Iter 0 = " + currentString);
    if (rules == null || rules.isEmpty()) {
        println("Warning: No rules provided for L-System generation.");
        // Keep axiom as the result if no rules
    } else {
        for (int i = 0; i < iterations; i++) {
            // Check for excessive string length to prevent OutOfMemoryError
            if (currentString.length() > 1000000) { // Limit string length
                 println("Warning: L-System string exceeds length limit at iteration " + i + ". Stopping generation.");
                 break;
            }

            StringBuilder nextString = new StringBuilder();
            for (int j = 0; j < currentString.length(); j++) {
                char c = currentString.charAt(j);
                // If a rule exists for this character, apply it; otherwise, keep the character
                nextString.append(rules.getOrDefault(c, String.valueOf(c)));
            }
            currentString = nextString.toString();
            println("Iter " + (i+1) + " (" + currentString.length() + " chars)");
            // Optional: Print string only if short enough
            // if (currentString.length() < 500) { println("   " + currentString); }
        }
    }
    println("L-System generation complete. Final length: " + currentString.length());
  }

  @Override
  void draw(PGraphics pg) {
    if (currentString == null || currentString.isEmpty()) {
      // Don't print error here, might just be 0 iterations
      return;
    }

    pg.pushStyle(); // Isolate style changes for this draw call
    pg.strokeWeight(strokeWidth);
    pg.stroke(0); // Black lines
    pg.noFill();

    Turtle turtle = new Turtle(pg, length, angleRadians); // Create a turtle for this drawing context
    turtle.interpret(currentString); // Tell the turtle to draw based on the string

    pg.popStyle(); // Restore previous style
  }
}

// --- Turtle Class for 3D L-System Interpretation ---
class Turtle {
  PGraphics pg; // Graphics context to draw on
  float length; // Length of 'F' step
  float angle; // Angle for turns (+, -, &, ^, \\, /) in radians
  Stack<TurtleState> stateStack; // Stack to save states for branching

  // Current Turtle State - stored directly for modification
  PVector position;
  PVector heading; // Direction turtle is facing (normalized) H
  PVector left;    // Direction relative left (normalized) L
  PVector up;      // Direction relative up (normalized) U

  // Constructor
  Turtle(PGraphics targetPG, float len, float angRad) {
    pg = targetPG;
    length = len;
    angle = angRad;
    stateStack = new Stack<TurtleState>();

    // Initial state: at origin (0,0,0 relative to translate in draw())
    // Facing 'upwards' in the processing window (-Y axis)
    position = new PVector(0, 0, 0);
    heading = new PVector(0, -1, 0); // H = (0, -1, 0)
    left    = new PVector(-1, 0, 0); // L = (-1, 0, 0) - Points left on screen initially
    up      = new PVector(0, 0, -1); // U = (0, 0, -1) - Points into the screen initially
    // Check basis: H x L = (0,-1,0) x (-1,0,0) = (0, 0, -1) = U. Correct.
  }

  // Interpret the L-System string
  void interpret(String s) {
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      switch (c) {
        case 'F': // Draw forward
          PVector nextPos = PVector.add(position, PVector.mult(heading, length));
          // Check if pg is available (might be null during setup)
          if (pg != null) {
              pg.line(position.x, position.y, position.z, nextPos.x, nextPos.y, nextPos.z);
          }
          position = nextPos;
          break;
        case 'f': // Move forward without drawing
          position.add(PVector.mult(heading, length));
          break;
        case '+': // Turn left (yaw positive around U vector)
          rotate(up, angle);
          break;
        case '-': // Turn right (yaw negative around U vector)
          rotate(up, -angle);
          break;
        case '&': // Pitch down (pitch positive around L vector)
          rotate(left, angle);
          break;
        case '^': // Pitch up (pitch negative around L vector)
          rotate(left, -angle);
          break;
        case '\\': // Roll left (roll positive around H vector) - Note: Processing uses '\' as escape, need double backslash in rules, e.g., X=\\\\F
           rotate(heading, angle);
           break;
        case '/': // Roll right (roll negative around H vector)
           rotate(heading, -angle);
           break;
        case '[': // Push state
          stateStack.push(new TurtleState(position, heading, left, up));
          break;
        case ']': // Pop state
          if (!stateStack.isEmpty()) {
            TurtleState ts = stateStack.pop();
            position = ts.position;
            heading = ts.heading;
            left = ts.left;
            up = ts.up;
          } else {
            println("Warning: Tried to pop from empty turtle stack.");
          }
          break;
        // Other characters are ignored (can be used for rules without drawing, e.g., 'X')
      }
    }
  }

  // Helper function for Rodrigues' rotation formula
  void rotate(PVector axis, float rotationAngle) {
      // Normalize the axis just in case (should be normalized already)
      axis.normalize();

      // Rodrigues' rotation formula components
      float cosA = cos(rotationAngle);
      float sinA = sin(rotationAngle);
      float oneMinusCosA = 1.0 - cosA;

      // Rotate Heading vector H' = H*cosA + (axis x H)*sinA + axis*(axis . H)*(1-cosA)
      PVector axisCrossH = axis.cross(heading);
      float axisDotH = axis.dot(heading);
      PVector newH = PVector.mult(heading, cosA);
      newH.add(PVector.mult(axisCrossH, sinA));
      newH.add(PVector.mult(axis, axisDotH * oneMinusCosA));
      heading = newH;

      // Rotate Left vector L' = L*cosA + (axis x L)*sinA + axis*(axis . L)*(1-cosA)
      PVector axisCrossL = axis.cross(left);
      float axisDotL = axis.dot(left);
      PVector newL = PVector.mult(left, cosA);
      newL.add(PVector.mult(axisCrossL, sinA));
      newL.add(PVector.mult(axis, axisDotL * oneMinusCosA));
      left = newL;

      // Rotate Up vector U' = U*cosA + (axis x U)*sinA + axis*(axis . U)*(1-cosA)
      PVector axisCrossU = axis.cross(up);
      float axisDotU = axis.dot(up);
      PVector newU = PVector.mult(up, cosA);
      newU.add(PVector.mult(axisCrossU, sinA));
      newU.add(PVector.mult(axis, axisDotU * oneMinusCosA));
      up = newU;

      // It's crucial to maintain orthogonality after potential floating point errors
      // Re-orthogonalize L and U with respect to H using Gram-Schmidt process (simplified)
      // U = normalize(U - (U.H)H)
      // L = normalize(L - (L.H)H - (L.U)U) --- or more simply L = U x H
      heading.normalize(); // Ensure H is normalized
      up.sub(PVector.mult(heading, up.dot(heading))); // Make U orthogonal to H
      up.normalize(); // Normalize new U
      left = up.cross(heading); // Calculate new L = U x H (guaranteed orthogonal)
      left.normalize(); // Normalize new L
  }
}

// Helper class to store turtle state for push/pop
class TurtleState {
  PVector position;
  PVector heading;
  PVector left;
  PVector up;

  TurtleState(PVector p, PVector h, PVector l, PVector u) {
    position = p.copy();
    heading = h.copy();
    left = l.copy();
    up = u.copy();
  }
}


// ============================================
//      Mouse and GUI Handlers
// ============================================

// --- Mouse Interaction for 3D View ---
void mousePressed() {
    // Record initial mouse position only if over the drawing area and not over a GUI element
    if (mouseX <= drawingWidth && !cp5.isMouseOver()) {
       lastMouseX = mouseX;
       lastMouseY = mouseY;
    }
}

void mouseDragged() {
  if (mouseX <= drawingWidth && !cp5.isMouseOver()) { // Only process drags in drawing area
     int dx = mouseX - lastMouseX;
     int dy = mouseY - lastMouseY;

     if (mouseButton == LEFT) { // Rotation
       // Map horizontal drag to rotation around world Y axis
       // Map vertical drag to rotation around world X axis
       rotY += dx * 0.01; // Adjust sensitivity as needed
       rotX -= dy * 0.01;
       // Clamp rotX to avoid flipping upside down gimbal lock issues
       rotX = constrain(rotX, -HALF_PI + 0.01, HALF_PI - 0.01);
     } else if (mouseButton == RIGHT) { // Translation (Pan)
       transX += dx;
       transY += dy;
     }
     lastMouseX = mouseX;
     lastMouseY = mouseY;
  }
}

void mouseWheel(MouseEvent event) {
  if (mouseX <= drawingWidth && !cp5.isMouseOver()) { // Only process scroll in drawing area
    float count = event.getCount();
    zoom *= pow(0.95, count); // Adjust zoom sensitivity (0.95^negative = zoom in)
    zoom = max(0.05, zoom); // Prevent zooming too far in/out or inverting
  }
}

// --- ControlP5 Handlers ---

// Generator selection
public void generatorTypeSelector(int n) {
  if (n >= 0 && n < generatorTypes.length) {
     selectedGeneratorType = generatorTypes[n];
     println("Selected Generator Type: " + selectedGeneratorType);
     // Potentially show/hide specific GUI groups based on type here
     createGenerator(); // Recreate and generate with the new type
  }
}

// L-System parameters
boolean lSystemParamsChanged = false; // Flag to trigger regeneration on focus lost/enter

public void lSystemAxiom(String theValue) {
  if (!theValue.equals(lSystemAxiom)) {
      lSystemAxiom = theValue;
      lSystemParamsChanged = true;
      println("Axiom changed: " + lSystemAxiom + " (Regen pending)");
  }
}

public void lSystemRulesInput(String theValue) {
 if (!theValue.equals(lSystemRulesInput)) {
     lSystemRulesInput = theValue;
     lSystemParamsChanged = true;
     println("Rules changed (Regen pending)");
 }
}

// Sliders trigger immediate regeneration via controlEvent
public void lSystemIterations(float theValue) {
  int newIterations = (int)theValue;
  if (newIterations != lSystemIterations) {
    lSystemIterations = newIterations;
    println("Iterations changed: " + lSystemIterations);
    createGenerator(); // Regenerate immediately
  }
}

public void lSystemAngle(float theValue) {
  if (abs(theValue - lSystemAngle) > 0.05) { // Check for significant change
      lSystemAngle = theValue;
      println("Angle changed: " + lSystemAngle);
      createGenerator(); // Regenerate immediately
  }
}

public void lSystemSegmentLength(float theValue) {
   if (abs(theValue - lSystemSegmentLength) > 0.05) { // Check for significant change
     lSystemSegmentLength = theValue;
     println("Length changed: " + lSystemSegmentLength);
     createGenerator(); // Regenerate immediately
   }
}

// Line width doesn't require regeneration, just redraw
public void lineWidth(float theValue) {
  float newWidth = max(0.1, theValue);
  if (abs(newWidth - lineWidth) > 0.05) {
      lineWidth = newWidth;
      println("Line Width changed: " + lineWidth);
      // Update the current generator's line width if it exists and is LSystem type
      if (currentGenerator instanceof LSystemGenerator) {
          ((LSystemGenerator)currentGenerator).strokeWidth = lineWidth;
      }
      // No regeneration needed, redraw handles it
  }
}

// Handle regeneration after Textfield/Textarea changes
public void controlEvent(ControlEvent theEvent) {
  // Check if the event is focus lost or enter pressed for relevant text inputs
  if (lSystemParamsChanged && theEvent.isController()) {
     String name = theEvent.getController().getName();
     if (name.equals("lSystemAxiom") || name.equals("lSystemRulesInput")) {
         // Check if focus was lost or Enter was pressed (less direct way in ControlP5)
         // We'll trigger on any event from these for simplicity now
         println("Regenerating L-System due to text change in: " + name);
         createGenerator();
         lSystemParamsChanged = false; // Reset flag after regeneration
     }
  }
  // Note: Slider changes trigger regeneration directly in their respective handlers above
}


// --- Button Handlers ---
public void viewReset() { // Connected to the viewReset button by name
  println("Resetting view.");
  resetView();
}

void resetView() {
  rotX = 0;
  rotY = 0;
  transX = 0;
  transY = 0;
  zoom = 1.0;
}

public void exportSVG() { // Connected to the exportSVG button by name
  println("SVG export requested via button");
  if (recordSVG) { println("Export already in progress."); return; }
  // Use a timestamp in the default filename
  String defaultFilename = "TreeGen_" + selectedGeneratorType + "_" + getTimestamp() + ".svg";
  selectOutput("Save SVG as...", "svgFileSelected",
    new File(sketchPath(""), defaultFilename), this);
}

// Callback function for selectOutput()
void svgFileSelected(File selection) {
  if (selection == null) {
    println("SVG export cancelled.");
    return;
  }

  svgOutputPath = selection.getAbsolutePath();
  println("Selected SVG path: " + svgOutputPath);

  // Check and delete existing file (optional, but good practice)
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    println("File already exists, attempting to delete: " + svgOutputPath);
    if (!outputFile.delete()) {
        println("Warning: Could not delete existing file. SVG export might fail or overwrite.");
    } else {
         println("Existing file deleted.");
    }
  }
  recordSVG = true; // Set flag to trigger SVG generation in the next draw() cycle
}

String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" +
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}


