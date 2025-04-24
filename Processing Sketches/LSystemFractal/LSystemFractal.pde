import controlP5.*;
import processing.svg.*;
import javax.swing.JOptionPane;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Stack;

ControlP5 cp5;
PFont labelFont;

// --- L-System Parameters ---
String axiom = "F"; // Starting string
String ruleF = "F+F-F-F+F"; // Rule for 'F'
String ruleX = ""; // Rule for 'X' (optional, depends on system)
String ruleY = ""; // Rule for 'Y' (optional, depends on system)
float angleDegrees = 90.0; // Turning angle
float initialLength = 400.0; // Initial length of 'F' segment
int iterations = 3; // Number of rewriting iterations
float lengthFactor = 0.4; // Factor to multiply length by each iteration (usually < 1)
float lineWidth = 1.0;

// --- Turtle Graphics State ---
class TurtleState {
  PVector pos;
  float angle;
  float len;
  TurtleState(PVector p, float a, float l) {
    pos = p.copy();
    angle = a;
    len = l;
  }
}

// --- Data Structures ---
String currentString;
ArrayList<PVector> pathPoints; // Store the vertices of the path
boolean needsRegen = true;

// --- SVG Export ---
boolean recordSVG = false;
String svgOutputPath = null;

// --- Setup & UI ---
void setup() {
  size(1000, 1000); // Canvas size
  labelFont = createFont("Arial", 12, true);
  cp5 = new ControlP5(this);

  int inputX = 150;
  int inputY = 10;
  int inputW = 200; // Wider for rules
  int inputH = 20;
  int spacing = 28;
  int currentY = inputY;

  // Axiom
  cp5.addLabel("Axiom:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("axiom").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(axiom);

  // Rule F
  currentY += spacing;
  cp5.addLabel("Rule F:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("ruleF").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(ruleF);
  
  // Rule X (optional)
  currentY += spacing;
  cp5.addLabel("Rule X:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("ruleX").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(ruleX);

  // Rule Y (optional)
  currentY += spacing;
  cp5.addLabel("Rule Y:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("ruleY").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(ruleY);

  // Angle
  currentY += spacing;
  inputW = 60; // Back to normal width
  cp5.addLabel("Angle (Deg):").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("angleDegrees").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(angleDegrees, 1, 1));

  // Iterations
  currentY += spacing;
  cp5.addLabel("Iterations:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("iterations").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+iterations);

  // Initial Length
  currentY += spacing;
  cp5.addLabel("Initial Length:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("initialLength").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(initialLength, 1, 1));

  // Length Factor
  currentY += spacing;
  cp5.addLabel("Length Factor:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("lengthFactor").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lengthFactor, 1, 2));

  // Line Width
  currentY += spacing;
  cp5.addLabel("Line Width:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("lineWidth").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lineWidth, 1, 2));

  // Buttons
  currentY += spacing + 10;
  cp5.addButton("regenerateLSystem").setLabel("Regenerate").setPosition(10, currentY).setSize(100, inputH+5);
  cp5.addButton("exportSVG").setLabel("Export SVG").setPosition(120, currentY).setSize(100, inputH+5);

  // Preset Buttons
  currentY += spacing;
  cp5.addButton("presetKoch").setLabel("Preset: Koch").setPosition(10, currentY).setSize(100, inputH+5);
  cp5.addButton("presetSierpinski").setLabel("Preset: Sierpinski").setPosition(120, currentY).setSize(120, inputH+5);
  cp5.addButton("presetDragon").setLabel("Preset: Dragon").setPosition(250, currentY).setSize(110, inputH+5);

  pathPoints = new ArrayList<PVector>();
}

// --- L-System Generation ---
void regenerateLSystem() {
  println("Generating L-System...");
  currentString = axiom;
  float currentDrawLength = initialLength;
  iterations = max(0, iterations); // Ensure non-negative iterations

  // Build rule map (ignoring empty rules)
  HashMap<Character, String> rules = new HashMap<Character, String>();
  if (ruleF != null && !ruleF.isEmpty()) rules.put('F', ruleF);
  if (ruleX != null && !ruleX.isEmpty()) rules.put('X', ruleX);
  if (ruleY != null && !ruleY.isEmpty()) {
      // Special handling for Sierpinski preset where ruleY holds the 'G' rule
      if (axiom.equals("F-G-G") && ruleY.equals("GG")) {
          rules.put('G', ruleY); 
      } else {
          // Otherwise, assume it's a rule for Y
          rules.put('Y', ruleY);
      }
  }
  // Add more rules here if needed (e.g., 'G')

  // Apply rules iteratively
  for (int i = 0; i < iterations; i++) {
    StringBuilder nextString = new StringBuilder();
    for (int j = 0; j < currentString.length(); j++) {
      char c = currentString.charAt(j);
      if (rules.containsKey(c)) {
        nextString.append(rules.get(c));
      } else {
        nextString.append(c);
      }
    }
    currentString = nextString.toString();
    currentDrawLength *= lengthFactor; // Adjust length for the next iteration's draw commands
  }
  println("Final string length: " + currentString.length());
  
  // Interpret the string to generate path
  interpretLSystem(currentDrawLength);
  
  needsRegen = false;
  println("L-System generated.");
}

// --- Turtle Graphics Interpretation ---
void interpretLSystem(float drawLength) {
  pathPoints = new ArrayList<PVector>();
  Stack<TurtleState> stateStack = new Stack<TurtleState>();

  float currentAngle = radians(90); // Start pointing up
  PVector currentPos = new PVector(width / 2, height * 0.9); // Start near bottom center
  float len = drawLength;
  float angle = radians(angleDegrees);

  pathPoints.add(currentPos.copy()); // Add starting point

  for (int i = 0; i < currentString.length(); i++) {
    char cmd = currentString.charAt(i);

    switch (cmd) {
      case 'F': // Move forward and draw
      case 'G': // Move forward without drawing (can add rule for G if needed)
        PVector nextPos = new PVector(
          currentPos.x + len * cos(currentAngle),
          currentPos.y - len * sin(currentAngle) // Subtract Y because screen coords are inverted
        );
        if (cmd == 'F') {
           pathPoints.add(nextPos.copy()); // Add segment end point
        } else {
           // If G, we just move, but need to restart the shape for plotter path
           // For simplicity here, we'll just treat G like F for pathPoints,
           // assuming the plotter will handle pen up/down based on segments.
           // A more complex approach would store segments separately.
           pathPoints.add(nextPos.copy()); 
        }
        currentPos = nextPos;
        break;
      case '+': // Turn left
        currentAngle -= angle;
        break;
      case '-': // Turn right
        currentAngle += angle;
        break;
      case '[': // Push state
        stateStack.push(new TurtleState(currentPos, currentAngle, len));
        break;
      case ']': // Pop state
        if (!stateStack.isEmpty()) {
          TurtleState restoredState = stateStack.pop();
          currentPos = restoredState.pos;
          currentAngle = restoredState.angle;
          len = restoredState.len;
          // Add current pos again to start a new line segment after jump
          pathPoints.add(currentPos.copy()); 
        }
        break;
      // Ignore other characters (like X, Y if they don't draw)
    }
  }
  
  // Optimize path: remove consecutive duplicate points (can happen with pop state)
  if (pathPoints.size() > 1) {
    ArrayList<PVector> optimizedPath = new ArrayList<PVector>();
    optimizedPath.add(pathPoints.get(0));
    for (int i = 1; i < pathPoints.size(); i++) {
      if (pathPoints.get(i).dist(pathPoints.get(i-1)) > 0.01) { // Check for distance
        optimizedPath.add(pathPoints.get(i));
      }
    }
    pathPoints = optimizedPath;
  }
}

// --- Drawing Loop ---
void draw() {
   if (recordSVG) {
    exportToSVG(); // Handle SVG export
    recordSVG = false; // Reset flag
  }
  
  if (needsRegen) {
      regenerateLSystem();
  }

  background(255); // White background

  // Draw the generated path
  if (pathPoints != null && pathPoints.size() > 1) {
    stroke(0);
    strokeWeight(lineWidth);
    noFill();
    beginShape();
    for (PVector p : pathPoints) {
      vertex(p.x, p.y);
    }
    endShape();
  }
  
  // Draw GUI
  hint(DISABLE_DEPTH_TEST);
  camera();
  ortho();
  cp5.draw();
  hint(ENABLE_DEPTH_TEST);
}

// --- SVG Export Logic ---
void exportToSVG() {
  if (svgOutputPath == null) {
    selectOutput("Save SVG as...", "svgFileSelected", 
      new File(sketchPath(""), "LSystem_" + getTimestamp() + ".svg"), this);
    return; // Wait for file selection
  }
  
  println("Creating SVG...");
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
  
  svg.beginDraw();
  svg.background(255); // Ensure SVG background is white
  svg.stroke(0);       // Black lines for SVG
  svg.strokeWeight(lineWidth);
  svg.noFill();
  
  // Draw the path to SVG
  if (pathPoints != null && pathPoints.size() > 1) {
    svg.beginShape();
    for (PVector p : pathPoints) {
      svg.vertex(p.x, p.y);
    }
    svg.endShape();
  }
  
  svg.endDraw();
  svg.dispose();
  println("SVG saved to: " + svgOutputPath);
  
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists() && outputFile.length() > 0) {
      JOptionPane.showMessageDialog(null, "SVG exported successfully to:\n" + svgOutputPath); 
  } else {
      JOptionPane.showMessageDialog(null, "Error: SVG file not created or empty.\nSee console."); 
  }
  svgOutputPath = null; // Reset for next export
  System.gc();
}

// --- ControlP5 Handlers ---
public void axiom(String val) { axiom = val; needsRegen = true; }
public void ruleF(String val) { ruleF = val; needsRegen = true; }
public void ruleX(String val) { ruleX = val; needsRegen = true; }
public void ruleY(String val) { ruleY = val; needsRegen = true; }
public void angleDegrees(String val) { try { angleDegrees = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){println("Invalid angle");} finally { if(cp5!=null)((Textfield)cp5.getController("angleDegrees")).setValue(nf(angleDegrees,1,1));} }
public void iterations(String val) { try { iterations = Integer.parseInt(val); needsRegen=true;} catch (NumberFormatException e){println("Invalid iterations");} finally { if(cp5!=null)((Textfield)cp5.getController("iterations")).setValue(""+iterations);} }
public void initialLength(String val) { try { initialLength = max(0.1, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){println("Invalid length");} finally { if(cp5!=null)((Textfield)cp5.getController("initialLength")).setValue(nf(initialLength,1,1));} }
public void lengthFactor(String val) { try { lengthFactor = max(0.01, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){println("Invalid factor");} finally { if(cp5!=null)((Textfield)cp5.getController("lengthFactor")).setValue(nf(lengthFactor,1,2));} }
public void lineWidth(String val) { try { lineWidth = max(0.1, Float.parseFloat(val)); } catch (NumberFormatException e){println("Invalid width");} finally { if(cp5!=null)((Textfield)cp5.getController("lineWidth")).setValue(nf(lineWidth,1,2));} }

// --- Button Handlers & Helpers ---
public void regenerateLSystem(int theValue) { // Button handler
  needsRegen = true;
}

public void exportSVG(int theValue) { // Button handler
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "LSystem_" + getTimestamp() + ".svg"), this);
}

void svgFileSelected(File selection) {
  if (selection == null) { println("SVG export cancelled."); svgOutputPath = null; return; }
  svgOutputPath = selection.getAbsolutePath();
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    if (!outputFile.delete()) println("Warning: Could not delete existing file.");
  }
  recordSVG = true; 
}

String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" + 
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

void keyPressed() {
  if (key == 's' || key == 'S') {
      exportSVG(0); 
  }
}

// --- Preset Handlers ---

void presetKoch(int theValue) {
  println("Loading Koch Preset...");
  axiom = "F";
  ruleF = "F-F++F-F";
  ruleX = "";
  ruleY = "";
  angleDegrees = 60.0;
  // Keep iterations, length, factor, width as they are
  
  // Update GUI fields
  if (cp5 != null) {
    ((Textfield)cp5.getController("axiom")).setValue(axiom);
    ((Textfield)cp5.getController("ruleF")).setValue(ruleF);
    ((Textfield)cp5.getController("ruleX")).setValue(ruleX);
    ((Textfield)cp5.getController("ruleY")).setValue(ruleY);
    ((Textfield)cp5.getController("angleDegrees")).setValue(nf(angleDegrees, 1, 1));
  }
  needsRegen = true;
}

void presetSierpinski(int theValue) {
  println("Loading Sierpinski Preset...");
  axiom = "F-G-G";
  ruleF = "F-G+F+G-F";
  ruleX = ""; // Not used directly, but rule G is
  ruleY = "GG"; // Assigning G rule to Y field for GUI (adjust if you add G rule field)
  angleDegrees = 120.0;
  // Keep iterations, length, factor, width as they are

  // Update GUI fields
  if (cp5 != null) {
    ((Textfield)cp5.getController("axiom")).setValue(axiom);
    ((Textfield)cp5.getController("ruleF")).setValue(ruleF);
    ((Textfield)cp5.getController("ruleX")).setValue(ruleX); 
    ((Textfield)cp5.getController("ruleY")).setValue(ruleY); // Display G rule in Y field
    ((Textfield)cp5.getController("angleDegrees")).setValue(nf(angleDegrees, 1, 1));
  }
  // We need to manually add the rule for 'G' in regenerateLSystem if it's not empty
  needsRegen = true;
}

void presetDragon(int theValue) {
  println("Loading Dragon Preset...");
  axiom = "FX";
  ruleF = ""; // F doesn't change
  ruleX = "X+YF+";
  ruleY = "-FX-Y";
  angleDegrees = 90.0;
  // Keep iterations, length, factor, width as they are

  // Update GUI fields
  if (cp5 != null) {
    ((Textfield)cp5.getController("axiom")).setValue(axiom);
    ((Textfield)cp5.getController("ruleF")).setValue(ruleF);
    ((Textfield)cp5.getController("ruleX")).setValue(ruleX);
    ((Textfield)cp5.getController("ruleY")).setValue(ruleY);
    ((Textfield)cp5.getController("angleDegrees")).setValue(nf(angleDegrees, 1, 1));
  }
  needsRegen = true;
} 