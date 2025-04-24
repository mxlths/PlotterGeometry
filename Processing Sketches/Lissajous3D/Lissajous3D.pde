import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class

ControlP5 cp5;
PFont labelFont; // Font for the labels

// Lissajous Curve 3D Parameters
float A = 200; // Amplitude X
float B = 200; // Amplitude Y
float C = 200; // Amplitude Z
float a = 3;   // Frequency X
float b = 4;   // Frequency Y
float c = 5;   // Frequency Z
float deltaDegrees = 90; // Phase shift X (relative to sin) - standard Lissajous
float phi_zDegrees = 0;  // Phase shift Z (relative to sin)

// Drawing Parameters
float scaleFactor = 1.0;
int numPoints = 1000;
float lineWidth = 1.0;
float tCycles = 1.0; // How many full 2*PI cycles for t

// Rotation Parameters (degrees)
float rotX = 0.0;
float rotY = 0.0;
float rotZ = 0.0;

// Mouse Rotation Variables
float mouseRotX = 0.0;
float mouseRotY = 0.0;
float prevMouseX = 0;
float prevMouseY = 0;
boolean mousePressedOverCanvas = false;
int guiWidth = 220; // Approximate width of the GUI panel

// SVG Export
boolean recordSVG = false; // Flag to trigger SVG export
String svgOutputPath = null; // Path for SVG output

void setup() {
  size(1200, 900, P3D); // Set canvas size using P3D renderer
  
  cp5 = new ControlP5(this); // Initialize ControlP5
  
  // Create a font for labels
  labelFont = createFont("Arial", 12, true);
  
  // --- GUI Controls ---
  int inputX = 150; 
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 28;
  int currentY = inputY; 
  
  // Amplitude X (A)
  cp5.addLabel("Amplitude X (A):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("A")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(A, 1, 1));

  // Amplitude Y (B)
  currentY += spacing;
  cp5.addLabel("Amplitude Y (B):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("B")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(B, 1, 1));
     
  // Amplitude Z (C)
  currentY += spacing;
  cp5.addLabel("Amplitude Z (C):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("C")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(C, 1, 1));

  // Frequency X (a)
  currentY += spacing;
  cp5.addLabel("Frequency X (a):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("a")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(a, 1, 1));
     
  // Frequency Y (b)
  currentY += spacing;
  cp5.addLabel("Frequency Y (b):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("b")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(b, 1, 1));
     
  // Frequency Z (c)
  currentY += spacing;
  cp5.addLabel("Frequency Z (c):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("c")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(c, 1, 1));

  // Phase Shift X (delta)
  currentY += spacing;
  cp5.addLabel("Phase Shift X (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("deltaDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(deltaDegrees, 1, 1));
     
  // Phase Shift Z (phi_z)
  currentY += spacing;
  cp5.addLabel("Phase Shift Z (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("phi_zDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(phi_zDegrees, 1, 1));

  // Scale Factor
  currentY += spacing;
  cp5.addLabel("Scale Factor:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("scaleFactor")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(scaleFactor, 1, 2));

  // Number of Points
  currentY += spacing;
  cp5.addLabel("Points (Resolution):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("numPoints")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numPoints);

  // Line Width
  currentY += spacing;
  cp5.addLabel("Line Width:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("lineWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(lineWidth, 1, 1));
      
  // T Cycles
  currentY += spacing;
  cp5.addLabel("T Cycles (x 2*PI):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("tCycles")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(tCycles, 1, 2));

  // Rotation X
  currentY += spacing;
  cp5.addLabel("Rotation X (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("rotX")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(rotX, 1, 1));

  // Rotation Y
  currentY += spacing;
  cp5.addLabel("Rotation Y (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("rotY")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(rotY, 1, 1));
     
  // Rotation Z
  currentY += spacing;
  cp5.addLabel("Rotation Z (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("rotZ")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(rotZ, 1, 1));

  // --- Buttons ---
  currentY += spacing + 10; // Add extra space before buttons
  cp5.addButton("exportSVG")
     .setLabel("Export SVG")
     .setPosition(10, currentY)
     .setSize(100, inputH + 5);
     
  // No "Regenerate" button needed as changes update live
}

void draw() {
  // Handle SVG recording first
  if (recordSVG) {
    try {
      println("Creating SVG...");
      PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
      svg.beginDraw();
      // Call the new function specifically for exporting projected points
      exportProjectedLissajousToSVG(svg); 
      svg.endDraw();
      svg.dispose();
      println("SVG saved to: " + svgOutputPath);
      
      File outputFile = new File(svgOutputPath);
      if (outputFile.exists() && outputFile.length() > 0) {
          JOptionPane.showMessageDialog(null, "SVG exported successfully to:\n" + svgOutputPath); 
      } else {
          JOptionPane.showMessageDialog(null, "Error: SVG file not created or empty.\nSee console."); 
      }
    } catch (Exception e) {
      println("Error creating SVG: " + e.getMessage());
      e.printStackTrace();
      JOptionPane.showMessageDialog(null, "Error creating SVG: " + e.getMessage()); 
    } finally {
      recordSVG = false;
      svgOutputPath = null;
      System.gc(); 
    }
  }

  // --- Main Screen Drawing ---
  background(255); // White background
  
  // Use the main graphics context 'g' (which is P3D)
  drawLissajous3D(this.g); 

  // --- Draw UI ---
  // Draw UI on top using Processing's 2D rendering context after 3D scene
  hint(DISABLE_DEPTH_TEST); // Disable depth testing for 2D overlay
  camera(); // Reset camera to default 2D view
  ortho();  // Use orthographic projection for UI
  if (!recordSVG) {
      // Draw a background rectangle behind the GUI for clarity 
      // (and to help define the mouse interaction area)
      fill(240); // Light grey background for GUI area
      noStroke();
      rect(0, 0, guiWidth, height);
      cp5.draw(); // Draw ControlP5 GUI elements
  }
  hint(ENABLE_DEPTH_TEST); // Re-enable depth testing for next 3D frame
}


// Function to draw the 3D Lissajous curve
void drawLissajous3D(PGraphics g) { 
  g.pushMatrix(); // Isolate transformations for the curve
  
  // Center the coordinate system in the middle of the window
  g.translate(g.width / 2.0, g.height / 2.0, 0); 
  
  // Apply rotations: GUI first, then mouse drag rotations
  g.rotateZ(radians(rotZ));
  g.rotateY(radians(rotY));
  g.rotateX(radians(rotX));
  g.rotateY(mouseRotY); // Apply mouse rotation around Y
  g.rotateX(mouseRotX); // Apply mouse rotation around X
  
  // Apply scaling
  g.scale(scaleFactor); 

  g.stroke(0); // Black lines
  g.strokeWeight(lineWidth);
  g.noFill(); // No fill for the curve itself

  // Calculate common values
  float delta = radians(deltaDegrees); // Convert phase shift X to radians
  float phi_z = radians(phi_zDegrees); // Convert phase shift Z to radians
  float tMax = TWO_PI * tCycles;
  int steps = max(3, numPoints); // Ensure at least 3 points for a 3D shape

  g.beginShape();
  for (int i = 0; i <= steps; i++) {
    float t = map(i, 0, steps, 0, tMax);
    
    // Calculate 3D coordinates
    float x = A * sin(a * t + delta);
    float y = B * sin(b * t);
    float z = C * sin(c * t + phi_z);
    
    // Add the vertex in 3D space
    g.vertex(x, y, z);
  }
  g.endShape();
  
  g.popMatrix(); // Restore previous transformation state
}

// New function to calculate projected 2D points and draw them to an SVG context
void exportProjectedLissajousToSVG(PGraphicsSVG svg) {
  // We need to apply the same transformations used in drawLissajous3D 
  // to the main graphics context ('this.g') so screenX/screenY work correctly.
  // We don't actually draw anything to the screen here, just set up the view.
  pushMatrix(); // Use the main context's matrix stack
  translate(width / 2.0, height / 2.0, 0); 
  rotateZ(radians(rotZ));
  rotateY(radians(rotY));
  rotateX(radians(rotX));
  rotateY(mouseRotY);
  rotateX(mouseRotX); 
  scale(scaleFactor); 

  // Calculate common values
  float delta = radians(deltaDegrees); 
  float phi_z = radians(phi_zDegrees); 
  float tMax = TWO_PI * tCycles;
  int steps = max(3, numPoints); 

  ArrayList<PVector> projectedPoints = new ArrayList<PVector>();

  // Calculate all projected points first
  for (int i = 0; i <= steps; i++) {
    float t = map(i, 0, steps, 0, tMax);
    
    // Calculate original 3D coordinates (relative to origin before transformations)
    float x = A * sin(a * t + delta);
    float y = B * sin(b * t);
    float z = C * sin(c * t + phi_z);
    
    // Get the 2D screen coordinates using the main P3D context's projection
    float screen_x = screenX(x, y, z);
    float screen_y = screenY(x, y, z);
    
    projectedPoints.add(new PVector(screen_x, screen_y));
  }
  
  popMatrix(); // Restore the main context's matrix state

  // Now draw the calculated 2D points to the SVG
  svg.stroke(0); 
  svg.strokeWeight(lineWidth);
  svg.noFill(); 
  
  svg.beginShape();
  for (PVector p : projectedPoints) {
    svg.vertex(p.x, p.y);
  }
  svg.endShape();
}


// --- ControlP5 Handlers (called automatically) ---

public void A(String theValue) {
  try { A = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid A"); if (cp5 != null) ((Textfield)cp5.getController("A")).setValue(nf(A, 1, 1)); }
}
public void B(String theValue) {
  try { B = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid B"); if (cp5 != null) ((Textfield)cp5.getController("B")).setValue(nf(B, 1, 1)); }
}
public void C(String theValue) {
  try { C = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid C"); if (cp5 != null) ((Textfield)cp5.getController("C")).setValue(nf(C, 1, 1)); }
}
public void a(String theValue) {
  try { a = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid a"); if (cp5 != null) ((Textfield)cp5.getController("a")).setValue(nf(a, 1, 1)); }
}
public void b(String theValue) {
  try { b = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid b"); if (cp5 != null) ((Textfield)cp5.getController("b")).setValue(nf(b, 1, 1)); }
}
public void c(String theValue) {
  try { c = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid c"); if (cp5 != null) ((Textfield)cp5.getController("c")).setValue(nf(c, 1, 1)); }
}
public void deltaDegrees(String theValue) {
  try { deltaDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid deltaDegrees"); if (cp5 != null) ((Textfield)cp5.getController("deltaDegrees")).setValue(nf(deltaDegrees, 1, 1)); }
}
public void phi_zDegrees(String theValue) {
  try { phi_zDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid phi_zDegrees"); if (cp5 != null) ((Textfield)cp5.getController("phi_zDegrees")).setValue(nf(phi_zDegrees, 1, 1)); }
}
public void scaleFactor(String theValue) {
  try { scaleFactor = max(0.01, Float.parseFloat(theValue)); } // Prevent zero or negative scale
  catch (NumberFormatException e) { println("Invalid scaleFactor"); scaleFactor = max(0.01, scaleFactor);} // Keep last valid value or 0.01
  finally { if (cp5 != null) ((Textfield)cp5.getController("scaleFactor")).setValue(nf(scaleFactor, 1, 2)); } // Update field if clamped
}
public void numPoints(String theValue) {
  try { numPoints = max(3, Integer.parseInt(theValue)); } // Need at least 3 points for 3D
  catch (NumberFormatException e) { println("Invalid numPoints"); numPoints = max(3, numPoints); } // Keep last valid value or 3
  finally { if (cp5 != null) ((Textfield)cp5.getController("numPoints")).setValue(""+numPoints); } // Update field if clamped
}
public void lineWidth(String theValue) {
  try { lineWidth = max(0.1, Float.parseFloat(theValue)); } // Prevent zero or negative width
  catch (NumberFormatException e) { println("Invalid lineWidth"); lineWidth = max(0.1, lineWidth); } // Keep last valid value or 0.1
  finally { if (cp5 != null) ((Textfield)cp5.getController("lineWidth")).setValue(nf(lineWidth, 1, 1)); } // Update field if clamped
}
public void tCycles(String theValue) {
  try { tCycles = max(0.01, Float.parseFloat(theValue)); } // Ensure positive cycles
  catch (NumberFormatException e) { println("Invalid tCycles"); tCycles = max(0.01, tCycles); } // Keep last valid value or 0.01
  finally { if (cp5 != null) ((Textfield)cp5.getController("tCycles")).setValue(nf(tCycles, 1, 2)); } // Update field if clamped
}
public void rotX(String theValue) {
  try { rotX = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid rotX"); if (cp5 != null) ((Textfield)cp5.getController("rotX")).setValue(nf(rotX, 1, 1)); }
}
public void rotY(String theValue) {
  try { rotY = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid rotY"); if (cp5 != null) ((Textfield)cp5.getController("rotY")).setValue(nf(rotY, 1, 1)); }
}
public void rotZ(String theValue) {
  try { rotZ = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid rotZ"); if (cp5 != null) ((Textfield)cp5.getController("rotZ")).setValue(nf(rotZ, 1, 1)); }
}


// --- SVG Export Logic ---

public void exportSVG() {
  println("SVG export requested via button");
  if (recordSVG) { println("Export already in progress."); return; }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "Lissajous3D_" + getTimestamp() + ".svg"), this);
}

void svgFileSelected(File selection) {
  if (selection == null) { println("SVG export cancelled."); return; }
  
  svgOutputPath = selection.getAbsolutePath();
  println("Selected SVG path: " + svgOutputPath);
  
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    println("File already exists, deleting: " + svgOutputPath);
    if (!outputFile.delete()) {
        println("Warning: Could not delete existing file. SVG export might fail or overwrite.");
    }
  }
  recordSVG = true; // Set flag to trigger SVG generation in draw()
}

String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" + 
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

// Optional: Key press for SVG export
void keyPressed() {
  if (key == 's' || key == 'S') {
      exportSVG(); // Call the same function as the button
  }
}

// --- Mouse Interaction for Rotation ---
void mousePressed() {
  // Only start dragging if the mouse is outside the GUI area
  if (mouseX > guiWidth) {
    mousePressedOverCanvas = true;
    prevMouseX = mouseX;
    prevMouseY = mouseY;
  } else {
    mousePressedOverCanvas = false;
  }
}

void mouseDragged() {
  if (mousePressedOverCanvas) {
    float dx = mouseX - prevMouseX;
    float dy = mouseY - prevMouseY;
    
    // Adjust mouse rotation based on drag
    // Sensitivity factor can be adjusted (e.g., 0.01)
    mouseRotY += dx * 0.01;
    mouseRotX -= dy * 0.01; // Subtract dy because increasing Y goes down
    
    prevMouseX = mouseX;
    prevMouseY = mouseY;
  }
}

void mouseReleased() {
  mousePressedOverCanvas = false;
} 