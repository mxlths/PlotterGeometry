import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class

ControlP5 cp5;
PFont labelFont; // Font for the labels

// Lissajous Curve Parameters
float A = 200; // Amplitude X
float B = 200; // Amplitude Y
float a = 3;   // Frequency X
float b = 4;   // Frequency Y
float deltaDegrees = 90; // Phase shift in degrees

// Drawing Parameters
float scaleFactor = 1.0;
int numPoints = 1000;
float lineWidth = 1.0;
float tCycles = 1.0; // How many full 2*PI cycles for t

// New Duplication/Rotation Parameters
int numDuplicates = 10;          // Number of curves to draw
float rotationStepDegrees = 5.0; // Degrees to rotate between each duplicate
float baseRotationDegrees = 0.0; // Initial rotation for the first curve

// New Wave Modulation Parameters
float waveDepth = 0.0; // Amplitude of the wave offset (pixels)
float waveFreq = 5.0;  // Frequency of the wave along the curve (cycles per 2*PI of t)

// New Perpendicular Line Mode Parameters
int drawMode = 0; // 0 = Curve, 1 = Perpendicular Lines
int lineDensity = 500; // Number of perpendicular lines to draw
float perpLineLength = 10.0; // Length of each perpendicular line (pixels)

// New Offset Cycle Parameters (inspired by InterpolatedCircle)
int offsetCycleCount = 20;      // Steps per shrink/grow cycle
int numberOfOffsetCycles = 1;   // Number of times to repeat the cycle
float initialScaleOffset = 1.1; // Initial relative size factor (e.g., 1.1 = 10% larger)
float scaleDecay = 0.95;      // Decay factor for scaling per step

// SVG Export
boolean recordSVG = false; // Flag to trigger SVG export
String svgOutputPath = null; // Path for SVG output

void setup() {
  size(2036, 1440); // Set canvas size
  
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

  // Phase Shift (delta)
  currentY += spacing;
  cp5.addLabel("Phase Shift (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("deltaDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(deltaDegrees, 1, 1));

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
      
  // New: Base Rotation
  currentY += spacing;
  cp5.addLabel("Base Rotation (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("baseRotationDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(baseRotationDegrees, 1, 1));
      
  // New: Rotation Step
  currentY += spacing;
  cp5.addLabel("Rotation Step (deg):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("rotationStepDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(rotationStepDegrees, 1, 1));
      
  // T Cycles
  currentY += spacing;
  cp5.addLabel("T Cycles (x 2*PI):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("tCycles")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(tCycles, 1, 2));

  // New: Wave Depth
  currentY += spacing;
  cp5.addLabel("Wave Depth (px):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("waveDepth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(waveDepth, 1, 1));
      
  // New: Wave Frequency
  currentY += spacing;
  cp5.addLabel("Wave Freq:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("waveFreq")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(waveFreq, 1, 1));

  // --- New Perpendicular Line Controls ---
  currentY += spacing;
  cp5.addLabel("Draw Mode (0/1):")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("drawMode")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+drawMode);
      
  currentY += spacing;
  cp5.addLabel("Line Density:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("lineDensity")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+lineDensity);

  currentY += spacing;
  cp5.addLabel("Perp Line Len:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("perpLineLength")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(perpLineLength, 1, 1));

  // --- New Offset Cycle Controls ---
  currentY += spacing;
  cp5.addLabel("Offset Cycle Count:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("offsetCycleCount")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+offsetCycleCount);
     
  currentY += spacing;
  cp5.addLabel("Num Offset Cycles:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("numberOfOffsetCycles")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numberOfOffsetCycles);
     
  currentY += spacing;
  cp5.addLabel("Initial Scale Off:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("initialScaleOffset")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(initialScaleOffset, 1, 2));
     
  currentY += spacing;
  cp5.addLabel("Scale Decay:")
     .setPosition(10, currentY + 4).setSize(130, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("scaleDecay")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(scaleDecay, 1, 2));

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
      drawPattern(svg); // Draw pattern to SVG
      svg.endDraw();
      svg.dispose();
      println("SVG saved to: " + svgOutputPath);
      
      File outputFile = new File(svgOutputPath);
      if (outputFile.exists() && outputFile.length() > 0) {
          JOptionPane.showMessageDialog(null, "SVG exported successfully to:\n" + svgOutputPath, 
              "SVG Export", JOptionPane.INFORMATION_MESSAGE);
      } else {
          JOptionPane.showMessageDialog(null, "Error: SVG file was not created or is empty.\nCheck console output.", 
              "SVG Export Error", JOptionPane.ERROR_MESSAGE);
      }
    } catch (Exception e) {
      println("Error creating SVG: " + e.getMessage());
      e.printStackTrace();
      JOptionPane.showMessageDialog(null, "Error creating SVG: " + e.getMessage(), 
          "SVG Export Error", JOptionPane.ERROR_MESSAGE);
    } finally {
      recordSVG = false;
      svgOutputPath = null;
      System.gc(); 
    }
  }

  // --- Main Screen Drawing ---
  background(255); // White background
  
  // Draw the pattern with duplicates and rotation
  drawPattern(this.g); 

  // --- Draw UI ---
  if (!recordSVG) {
    cp5.draw();
  }
}

// New function to draw the complete pattern with duplicates
void drawPattern(PGraphics g) {
  // --- Use Offset Cycle Logic --- 
  int effectiveCycleCount = max(2, offsetCycleCount);
  int effectiveNumCycles = max(1, numberOfOffsetCycles);
  int halfCycle = effectiveCycleCount / 2;
  // Ensure the relative offset is positive for calculation
  float firstRelativeOffset = max(1e-6, initialScaleOffset - 1.0); 
  
  // Base scale for the innermost curve (can be modified by UI)
  float currentTotalScale = scaleFactor; 

  // Outer loop for cycles
  for (int cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
      // Inner loop for steps within a cycle
      for (int d = 0; d < effectiveCycleCount; d++) { 
          // Calculate exponent for decay based on shrink/grow phase
          int exponentIndex = (d < halfCycle) ? d : (effectiveCycleCount - 1 - d);
          // Calculate the scale factor for this specific step relative to the previous
          float stepScaleFactor = 1.0 + firstRelativeOffset * pow(scaleDecay, exponentIndex); 
          // Apply the step scale factor cumulatively
          currentTotalScale *= stepScaleFactor; 

          if (currentTotalScale <= 1e-6) { // Skip if scale becomes too small
               continue; 
          }

          // Calculate the overall duplicate index for rotation
          int totalDuplicateIndex = cycleNum * effectiveCycleCount + d;
          // Calculate rotation for this duplicate
          float currentRotationDegrees = baseRotationDegrees + (totalDuplicateIndex * rotationStepDegrees);
          
          // Call the Lissajous drawing function for this duplicate 
          // with its specific rotation and calculated total scale
          drawLissajous(g, currentRotationDegrees, currentTotalScale); 
      }
      // Reset the scale for the next cycle to start from the base scale again
      // If you want cycles to continue scaling from the previous, remove this reset.
      currentTotalScale = scaleFactor; 
  }
  
  // --- Draw the original base curve (scale = scaleFactor) --- 
  // This ensures the base curve is always drawn, even if cycles are 0 or scale becomes tiny.
  drawLissajous(g, baseRotationDegrees, scaleFactor); 
}

// Modified function to draw ONE Lissajous curve with a specific rotation and scale
// Takes rotation (degrees) and totalScale as arguments
void drawLissajous(PGraphics g, float rotationDeg, float totalScale) { 
  g.pushMatrix(); // Isolate transformations
  g.translate(width / 2.0, height / 2.0); // Center the origin
  g.rotate(radians(rotationDeg)); // Apply the specified rotation for THIS curve
  g.scale(totalScale); // Apply the calculated total scale for THIS curve

  g.stroke(0); // Black lines
  g.strokeWeight(lineWidth);
  g.noFill(); // No fill

  // Calculate common values
  float delta = radians(deltaDegrees); // Convert phase shift to radians
  float tMax = TWO_PI * tCycles;
  
  // --- Branch based on Draw Mode ---
  if (drawMode == 0) { // Draw Mode 0: Curve
      int steps = max(2, numPoints); // Ensure at least 2 points for curve
      g.beginShape();
      for (int i = 0; i <= steps; i++) {
        float t = map(i, 0, steps, 0, tMax);
        
        // Base Lissajous point
        float x = A * sin(a * t + delta);
        float y = B * sin(b * t);
        
        // Apply wave modulation ONLY in curve mode if depth is significant
        if (abs(waveDepth) > 1e-3) {
          // Calculate tangent vector (derivative dx/dt, dy/dt)
          float tx = A * a * cos(a * t + delta);
          float ty = B * b * cos(b * t);
          
          // Calculate normal vector (rotate tangent 90 degrees)
          float nx = -ty;
          float ny = tx;
          
          // Normalize the normal vector
          float mag = sqrt(nx*nx + ny*ny);
          if (mag > 1e-6) { // Avoid division by zero if tangent is zero
            nx /= mag;
            ny /= mag;
            
            // Calculate wave offset for this point 't'
            float waveOffset = waveDepth * sin(waveFreq * t);
            
            // Displace the point along the normal
            x += nx * waveOffset;
            y += ny * waveOffset;
          }
        }
        
        g.vertex(x, y);
      }
      g.endShape();
      
  } else { // Draw Mode 1: Perpendicular Lines
      int numLines = max(1, lineDensity); // Ensure at least 1 line
      float halfLineLen = perpLineLength / 2.0;
      
      for (int i = 0; i < numLines; i++) {
         // Calculate t for this line segment
         float t = map(i, 0, numLines, 0, tMax); // Map across the density
         
         // Calculate base point on the curve (center of the line)
         float cx = A * sin(a * t + delta);
         float cy = B * sin(b * t);
         
         // Calculate tangent vector (derivative dx/dt, dy/dt)
         float tx = A * a * cos(a * t + delta);
         float ty = B * b * cos(b * t);
            
         // Calculate normal vector (rotate tangent 90 degrees)
         float nx = -ty;
         float ny = tx;
         
         // Normalize the normal vector
         float mag = sqrt(nx*nx + ny*ny);
         if (mag > 1e-6) { // Avoid division by zero if tangent is zero
            nx /= mag;
            ny /= mag;
            
            // Calculate endpoints of the perpendicular line
            float x1 = cx + nx * halfLineLen;
            float y1 = cy + ny * halfLineLen;
            float x2 = cx - nx * halfLineLen;
            float y2 = cy - ny * halfLineLen;
            
            // Draw the line segment
            g.line(x1, y1, x2, y2);
         } 
         // Else: if mag is near zero, tangent is undefined/zero, skip drawing line for this point
      }
  }
  
  g.popMatrix(); // Restore previous transformation state
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
public void a(String theValue) {
  try { a = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid a"); if (cp5 != null) ((Textfield)cp5.getController("a")).setValue(nf(a, 1, 1)); }
}
public void b(String theValue) {
  try { b = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid b"); if (cp5 != null) ((Textfield)cp5.getController("b")).setValue(nf(b, 1, 1)); }
}
public void deltaDegrees(String theValue) {
  try { deltaDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid deltaDegrees"); if (cp5 != null) ((Textfield)cp5.getController("deltaDegrees")).setValue(nf(deltaDegrees, 1, 1)); }
}
public void scaleFactor(String theValue) {
  try { scaleFactor = max(0.01, Float.parseFloat(theValue)); } // Prevent zero or negative scale
  catch (NumberFormatException e) { println("Invalid scaleFactor"); scaleFactor = max(0.01, scaleFactor);} // Keep last valid value or 0.01
  finally { if (cp5 != null) ((Textfield)cp5.getController("scaleFactor")).setValue(nf(scaleFactor, 1, 2)); } // Update field if clamped
}
public void numPoints(String theValue) {
  try { numPoints = max(2, Integer.parseInt(theValue)); } // Need at least 2 points
  catch (NumberFormatException e) { println("Invalid numPoints"); numPoints = max(2, numPoints); } // Keep last valid value or 2
  finally { if (cp5 != null) ((Textfield)cp5.getController("numPoints")).setValue(""+numPoints); } // Update field if clamped
}
public void lineWidth(String theValue) {
  try { lineWidth = max(0.1, Float.parseFloat(theValue)); } // Prevent zero or negative width
  catch (NumberFormatException e) { println("Invalid lineWidth"); lineWidth = max(0.1, lineWidth); } // Keep last valid value or 0.1
  finally { if (cp5 != null) ((Textfield)cp5.getController("lineWidth")).setValue(nf(lineWidth, 1, 1)); } // Update field if clamped
}
public void baseRotationDegrees(String theValue) {
  try { baseRotationDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid baseRotationDegrees"); if (cp5 != null) ((Textfield)cp5.getController("baseRotationDegrees")).setValue(nf(baseRotationDegrees, 1, 1)); }
}
public void rotationStepDegrees(String theValue) {
  try { rotationStepDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid rotationStepDegrees"); if (cp5 != null) ((Textfield)cp5.getController("rotationStepDegrees")).setValue(nf(rotationStepDegrees, 1, 1)); }
}
public void tCycles(String theValue) {
  try { tCycles = max(0.01, Float.parseFloat(theValue)); } // Ensure positive cycles
  catch (NumberFormatException e) { println("Invalid tCycles"); tCycles = max(0.01, tCycles); } // Keep last valid value or 0.01
  finally { if (cp5 != null) ((Textfield)cp5.getController("tCycles")).setValue(nf(tCycles, 1, 2)); } // Update field if clamped
}
public void waveDepth(String theValue) {
  try { waveDepth = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid waveDepth"); if (cp5 != null) ((Textfield)cp5.getController("waveDepth")).setValue(nf(waveDepth, 1, 1)); }
}
public void waveFreq(String theValue) {
  try { waveFreq = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid waveFreq"); if (cp5 != null) ((Textfield)cp5.getController("waveFreq")).setValue(nf(waveFreq, 1, 1)); }
}
public void drawMode(String theValue) {
  try { 
    int newMode = Integer.parseInt(theValue);
    drawMode = (newMode == 1) ? 1 : 0; // Clamp to 0 or 1
  } catch (NumberFormatException e) { 
    println("Invalid drawMode"); 
    drawMode = max(0, min(1, drawMode)); // Keep last valid value (0 or 1)
  } finally { 
    if (cp5 != null) ((Textfield)cp5.getController("drawMode")).setValue(""+drawMode); 
  }
}
public void lineDensity(String theValue) {
  try { 
    lineDensity = Integer.parseInt(theValue);
    lineDensity = max(1, lineDensity); // Ensure at least 1 line
  } catch (NumberFormatException e) { 
    println("Invalid lineDensity"); 
    lineDensity = max(1, lineDensity); // Keep last valid value or 1
  } finally { 
    if (cp5 != null) ((Textfield)cp5.getController("lineDensity")).setValue(""+lineDensity); 
  }
}
public void perpLineLength(String theValue) {
  try { 
    perpLineLength = Float.parseFloat(theValue);
    perpLineLength = max(0, perpLineLength); // Ensure non-negative length
  } catch (NumberFormatException e) { 
    println("Invalid perpLineLength"); 
    perpLineLength = max(0, perpLineLength); // Keep last valid value or 0
  } finally { 
    if (cp5 != null) ((Textfield)cp5.getController("perpLineLength")).setValue(nf(perpLineLength, 1, 1)); 
  }
}

// --- SVG Export Logic ---

public void exportSVG() {
  println("SVG export requested via button");
  if (recordSVG) { println("Export already in progress."); return; }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "Lissajous_" + getTimestamp() + ".svg"), this);
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

// --- New Handlers for Offset Cycles ---
public void offsetCycleCount(String theValue) {
  try { 
    offsetCycleCount = Integer.parseInt(theValue);
    offsetCycleCount = max(2, offsetCycleCount); // Need at least 2 for a cycle
  } catch (NumberFormatException e) { 
    println("Invalid offsetCycleCount"); 
    offsetCycleCount = max(2, offsetCycleCount);
  } finally { 
    if (cp5 != null) ((Textfield)cp5.getController("offsetCycleCount")).setValue(""+offsetCycleCount); 
  }
}

public void numberOfOffsetCycles(String theValue) {
  try { 
    numberOfOffsetCycles = Integer.parseInt(theValue);
    numberOfOffsetCycles = max(1, numberOfOffsetCycles);
  } catch (NumberFormatException e) { 
    println("Invalid numberOfOffsetCycles"); 
    numberOfOffsetCycles = max(1, numberOfOffsetCycles);
  } finally { 
    if (cp5 != null) ((Textfield)cp5.getController("numberOfOffsetCycles")).setValue(""+numberOfOffsetCycles);
  }
}

public void initialScaleOffset(String theValue) {
  try { 
    initialScaleOffset = Float.parseFloat(theValue);
    initialScaleOffset = max(0.01, initialScaleOffset); // Must be positive
  } catch (NumberFormatException e) { 
    println("Invalid initialScaleOffset"); 
    initialScaleOffset = max(0.01, initialScaleOffset);
  } finally { 
    if (cp5 != null) ((Textfield)cp5.getController("initialScaleOffset")).setValue(nf(initialScaleOffset, 1, 2)); 
  }
}

public void scaleDecay(String theValue) {
  try { 
    scaleDecay = Float.parseFloat(theValue);
    scaleDecay = max(0.0, scaleDecay); // Allow 0, but must be non-negative
  } catch (NumberFormatException e) { 
    println("Invalid scaleDecay"); 
    scaleDecay = max(0.0, scaleDecay);
  } finally { 
    if (cp5 != null) ((Textfield)cp5.getController("scaleDecay")).setValue(nf(scaleDecay, 1, 2)); 
  }
} 