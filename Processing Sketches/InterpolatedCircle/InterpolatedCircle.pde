import java.util.ArrayList;
import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class

ControlP5 cp5;
boolean recordSVG = false; // Flag to trigger SVG export
String svgOutputPath = null; // Path for SVG output
boolean debugScaling = false; // Flag to control debug output for scaling calculations
PGraphics svgOutput; // SVG graphics object for direct export
// String focusedControllerName = null; // Removed
PFont labelFont; // Font for the labels

int n = 7; // Number of points
float offset = 2.0; // Offset for the radius
// float offsetStep = 0.5; // No longer needed with text input
float radiusScale = 50; // Scale factor for the radius units
int minPoints = 3;

// Duplication parameters
int cycleCount = 100; // Total duplicates in one shrink-then-grow cycle
int numberOfCycles = 1; // New: Number of times to repeat the cycle
float initialScaleOffset = 1.1; 
float scaleDecay = 0.9;       
float fluctuationAmount = 0.1;
int drawMode = 0; // 0 = curves, 1 = radial lines
float radialLineLengthUnits = 0.05;
int segmentsPerCurve = 100; // New: Number of radial lines per curve path
float lineRotationDegrees = 15.0; // New: Rotation angle for each set of lines in degrees

// Data structures for storing random values
ArrayList<PVector> points; // Stores calculated positions
ArrayList<Float> baseRandomDistances; // Stores random distance (1-7) for base shape
ArrayList<ArrayList<Float>> fluctuationOffsets; // Stores random factor (-1 to 1) for fluctuation [duplicate][point]

void setup() {
  size(2036, 1440); // Set canvas size
  
  cp5 = new ControlP5(this); // Initialize ControlP5
  
  // Create a larger font for labels
  labelFont = createFont("Arial", 14, true);
  
  // Create Textfields and link them to variables
  int inputX = 160; // Increased X for longer labels
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 30;
  int currentY = inputY; // Use a separate variable for layout
  
  cp5.addLabel("Points (N):")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("n")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+n);

  currentY += spacing;
  cp5.addLabel("Radius Offset:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("offset")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(offset, 1, 1));
     
  currentY += spacing;
  cp5.addLabel("Cycle Count:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("cycleCount")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+cycleCount);

  currentY += spacing;
  cp5.addLabel("Number of Cycles:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("numberOfCycles")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+numberOfCycles);

  currentY += spacing;
  cp5.addLabel("Initial Scale:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("initialScaleOffset")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(initialScaleOffset, 1, 2));
     
  currentY += spacing;
  cp5.addLabel("Scale Decay:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("scaleDecay")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(scaleDecay, 1, 2));

  currentY += spacing;
  cp5.addLabel("Fluctuation:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("fluctuationAmount")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(fluctuationAmount, 1, 2));

  // --- New Mode Textfields ---
  currentY += spacing;
  cp5.addLabel("Draw Mode (0/1):")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("drawMode")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+drawMode);
  
  currentY += spacing;
  cp5.addLabel("Radial Length:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("radialLineLengthUnits")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(radialLineLengthUnits, 1, 2));

  // --- New Segments Textfield ---
  currentY += spacing;
  cp5.addLabel("Segments Per Curve:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("segmentsPerCurve")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+segmentsPerCurve);

  // --- New Line Rotation Textfield ---
  currentY += spacing;
  cp5.addLabel("Line Rotation (deg):")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("lineRotationDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lineRotationDegrees, 1, 1));

  // --- Regenerate Button ---
  currentY += spacing + 10; // Add extra space before button
  cp5.addButton("regeneratePattern")
     .setLabel("Regenerate")
     .setPosition(10, currentY)
     .setSize(100, inputH + 5);

  // --- SVG Export Button ---
  cp5.addButton("exportSVG")
     .setLabel("Export SVG")
     .setPosition(120, currentY)
     .setSize(100, inputH + 5);

  // Initialize data structures and generate initial pattern
  points = new ArrayList<PVector>();
  baseRandomDistances = new ArrayList<Float>();
  fluctuationOffsets = new ArrayList<ArrayList<Float>>();
  regeneratePattern(); 
}

// Function to generate and store all random values
void regeneratePattern() {
  println("Regenerating pattern...");
  cycleCount = max(2, cycleCount);
  numberOfCycles = max(1, numberOfCycles);
  int totalDuplicates = cycleCount * numberOfCycles;
  
  baseRandomDistances.clear();
  fluctuationOffsets.clear();

  // Generate base distances
  for (int i = 0; i < n; i++) {
    baseRandomDistances.add(random(1, 7));
  }

  // Generate fluctuation offsets for all potential duplicates
  // We generate for the *current* numDuplicates. If numDuplicates increases,
  // the new duplicates won't have stored fluctuations initially, but draw handles this.
  // If numDuplicates decreases, the extra data is ignored.
  for (int d = 0; d < totalDuplicates; d++) {
    ArrayList<Float> currentDuplicateOffsets = new ArrayList<Float>();
    for (int i = 0; i < n; i++) {
      currentDuplicateOffsets.add(random(-1, 1)); // Store factor -1 to 1
    }
    fluctuationOffsets.add(currentDuplicateOffsets);
  }
  
  calculatePoints(); // Calculate positions based on new random data
}

// Calculate point positions using stored random base distances
void calculatePoints() {
  n = max(minPoints, n); // Ensure n is valid
  // Ensure baseRandomDistances list matches current n (important if n changed)
  while (baseRandomDistances.size() < n) baseRandomDistances.add(random(1, 7));
  while (baseRandomDistances.size() > n) baseRandomDistances.remove(baseRandomDistances.size() - 1);

  // Update textfield if clamped
  if(cp5 != null) {
    Textfield nInput = (Textfield)cp5.getController("n");
    if (nInput != null && !nInput.getStringValue().equals(""+n)) {
        nInput.setValue(""+n);
    }
  }

  points.clear(); // Clear previous positions
  float centerX = width / 2.0;
  float centerY = height / 2.0;
  for (int i = 0; i < n; i++) {
    float angle = map(i, 0, n, 0, TWO_PI);
    float baseDist = baseRandomDistances.get(i); // Use stored random value
    float dist = (baseDist + offset) * radiusScale;
    float x = centerX + cos(angle) * dist;
    float y = centerY + sin(angle) * dist;
    points.add(new PVector(x, y));
  }
}

// Use stored fluctuation offset
PVector getFluctuatedScaledPoint(PVector originalPoint, PVector center, float totalScale, 
                               int duplicateIndex, int pointIndex, 
                               float fluctAmountUnits, float scaleUnits) 
{
  PVector scaledP = PVector.sub(originalPoint, center);
  scaledP.mult(totalScale);
  scaledP.add(center);

  PVector dir = PVector.sub(originalPoint, center);
  if (dir.magSq() > 1e-6) {
    dir.normalize();
    
    // Get stored fluctuation factor
    float fluctFactor = 0;
    // Check bounds before accessing fluctuationOffsets
    if (duplicateIndex >= 0 && duplicateIndex < fluctuationOffsets.size()) {
       ArrayList<Float> currentDupOffsets = fluctuationOffsets.get(duplicateIndex);
       if (pointIndex >= 0 && pointIndex < currentDupOffsets.size()) {
            fluctFactor = currentDupOffsets.get(pointIndex);
       }
    }

    float randFluctPixels = fluctFactor * fluctAmountUnits * scaleUnits;
    PVector fluctVec = PVector.mult(dir, randFluctPixels);
    scaledP.add(fluctVec); 
  }
  return scaledP;
}

// Helper function to draw one curve
void drawFluctuatedCurve(PGraphics g, PVector center, float totalScale, int duplicateIndex) {
    if (totalScale <= 1e-6) return; // Skip if scale is too small/negative
    if (points == null || points.size() < n || n < minPoints) return; // Safety checks

    g.beginShape();
    // Control points (indices n-1, 0, 1)
    PVector fluctuatedLastP = getFluctuatedScaledPoint(points.get(n - 1), center, totalScale, duplicateIndex, n - 1, fluctuationAmount, radiusScale);
    g.curveVertex(fluctuatedLastP.x, fluctuatedLastP.y);

    // Main points (indices 0 to n-1)
    for (int i = 0; i < n; i++) {
        PVector fluctuatedP = getFluctuatedScaledPoint(points.get(i), center, totalScale, duplicateIndex, i, fluctuationAmount, radiusScale);
        g.curveVertex(fluctuatedP.x, fluctuatedP.y);
    }

    // Closing control points (indices 0, 1)
    PVector fluctuatedFirstP = getFluctuatedScaledPoint(points.get(0), center, totalScale, duplicateIndex, 0, fluctuationAmount, radiusScale);
    g.curveVertex(fluctuatedFirstP.x, fluctuatedFirstP.y);
    PVector fluctuatedSecondP = getFluctuatedScaledPoint(points.get(1), center, totalScale, duplicateIndex, 1, fluctuationAmount, radiusScale);
    g.curveVertex(fluctuatedSecondP.x, fluctuatedSecondP.y);

    g.endShape();
}

// Helper function to draw a short radial line *inward* from a point towards the center
void drawInwardRadialLine(PGraphics g, PVector point, PVector center, float lengthPixels) {
    PVector dirToCenter = PVector.sub(center, point);
    if (dirToCenter.magSq() < 1e-6) return; // Avoid drawing for points at the center
    dirToCenter.normalize();
    PVector endPoint = PVector.add(point, PVector.mult(dirToCenter, lengthPixels)); // Move towards center
    g.line(point.x, point.y, endPoint.x, endPoint.y);
}

// New helper function to draw a rotated radial line
void drawRotatedRadialLine(PGraphics g, PVector point, PVector center, float lengthPixels, float rotationAngleRadians) {
    PVector dirToCenter = PVector.sub(center, point);
    if (dirToCenter.magSq() < 1e-6) return; // Avoid drawing for points at the center
    dirToCenter.normalize();
    
    // Calculate the perpendicular vector for rotation
    PVector perpVector = new PVector(-dirToCenter.y, dirToCenter.x);
    
    // Calculate rotated direction
    PVector rotatedDir = new PVector();
    rotatedDir.x = dirToCenter.x * cos(rotationAngleRadians) - dirToCenter.y * sin(rotationAngleRadians);
    rotatedDir.y = dirToCenter.x * sin(rotationAngleRadians) + dirToCenter.y * cos(rotationAngleRadians);
    
    // Calculate the line end point
    PVector endPoint = PVector.add(point, PVector.mult(rotatedDir, lengthPixels));
    
    g.line(point.x, point.y, endPoint.x, endPoint.y);
}

void draw() {
  // Main drawing to the screen
  background(255);
  PVector center = new PVector(width / 2.0, height / 2.0);
  
  if (points != null && points.size() >= n && n >= minPoints) { 
    stroke(0); 
    strokeWeight(1); 
    noFill();
    
    // Draw the pattern to the screen
    drawPattern(this.g, center);
  }
  
  // Always draw the UI controls unless we're recording
  if (!recordSVG) {
    cp5.draw();
  }
  
  // Handle SVG recording if needed
  if (recordSVG) {
    try {
      println("Creating SVG...");
      
      // Create a new PGraphicsSVG object
      PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
      
      // Begin drawing to the SVG
      svg.beginDraw();
      svg.background(255);
      
      // Draw the pattern to the SVG graphics object
      if (points != null && points.size() >= n && n >= minPoints) {
        svg.stroke(0);
        svg.strokeWeight(1);
        svg.noFill();
        drawPattern(svg, center);
      }
      
      // Finish and save the SVG
      svg.endDraw();
      svg.dispose();
      println("SVG saved to: " + svgOutputPath);
      
      // Verify the file exists and has content
      File outputFile = new File(svgOutputPath);
      if (outputFile.exists() && outputFile.length() > 0) {
        println("SVG file verified: " + svgOutputPath + " (Size: " + outputFile.length() + " bytes)");
        JOptionPane.showMessageDialog(null, "SVG exported successfully to:\n" + svgOutputPath, 
            "SVG Export", JOptionPane.INFORMATION_MESSAGE);
      } else {
        println("ERROR: SVG file not found or empty after export: " + svgOutputPath);
        JOptionPane.showMessageDialog(null, "Error: SVG file was not created or is empty.\nTry restarting Processing.", 
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
      System.gc(); // Help clean up resources
    }
  }
}

// New method to encapsulate all pattern drawing logic
void drawPattern(PGraphics g, PVector center) {
  // Variables needed by both draw modes
  float radialLengthPixels = radialLineLengthUnits * radiusScale;
  int numSegments = max(1, segmentsPerCurve);

  // Draw Original Curve (or its radial lines)
  if (drawMode == 0) {
      // Draw CURVES Mode - Original curve
      g.beginShape();
      g.curveVertex(points.get(n - 1).x, points.get(n - 1).y); 
      for (int i = 0; i < n; i++) {
        g.curveVertex(points.get(i).x, points.get(i).y);
      }
      g.curveVertex(points.get(0).x, points.get(0).y);
      g.curveVertex(points.get(1).x, points.get(1).y); 
      g.endShape();
  } else {
      // Draw INTERPOLATED INWARD RADIAL LINES Mode - Original curve
      for (int j = 0; j < numSegments; j++) {
          float t_global = map(j, 0, numSegments, 0, n);
          int segIndex = floor(t_global) % n;
          float t_segment = t_global - floor(t_global);
          
          PVector p0 = points.get((segIndex - 1 + n) % n);
          PVector p1 = points.get(segIndex);
          PVector p2 = points.get((segIndex + 1) % n);
          PVector p3 = points.get((segIndex + 2) % n);
          
          float interpX = curvePoint(p0.x, p1.x, p2.x, p3.x, t_segment);
          float interpY = curvePoint(p0.y, p1.y, p2.y, p3.y, t_segment);
          drawInwardRadialLine(g, new PVector(interpX, interpY), center, radialLengthPixels);
      }
  }

  // --- Draw Duplicate Cycles (Multiplicative Scaling) --- 
  int effectiveCycleCount = max(2, cycleCount);
  int effectiveNumCycles = max(1, numberOfCycles);
  if (debugScaling) {
    println("--- Starting Duplicates --- Cycles:", effectiveNumCycles, " Steps/Cycle:", effectiveCycleCount);
  }
  
  int halfCycle = effectiveCycleCount / 2;
  float firstRelativeOffset = max(0.01, initialScaleOffset - 1.0); // Ensure at least small positive value
  if (debugScaling) {
    println("  firstRelativeOffset:", firstRelativeOffset);
  }
  
  // For each cycle, start with the scale from the end of the previous cycle
  // or 1.0 for the first cycle
  float currentTotalScale = 1.0;

  // Outer loop for cycles
  for (int cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
      if (debugScaling) {
        println("  Entering Cycle:", cycleNum);
      }
      
      // Inner loop for steps within a cycle
      for (int d = 0; d < effectiveCycleCount; d++) { 
          int exponentIndex = (d < halfCycle) ? d : (effectiveCycleCount - 1 - d);
          float stepScaleFactor = 1.0 + firstRelativeOffset * pow(scaleDecay, exponentIndex); 
          currentTotalScale *= stepScaleFactor; 

          if (debugScaling) {
            println("    d:", d, " expIdx:", exponentIndex, " stepFactor:", nf(stepScaleFactor,1,4), " totalScale:", nf(currentTotalScale,1,4));
          }

          if (currentTotalScale <= 1e-6) {
               if (debugScaling) {
                 println("      Scale too small, skipping rest.");
               }
               continue; 
          }

          int totalDuplicateIndex = cycleNum * effectiveCycleCount + d;

          if (drawMode == 0) {
              // Draw curve with current scale
              drawFluctuatedCurve(g, center, currentTotalScale, totalDuplicateIndex);
          } else {
              // Draw radial lines with current scale
              ArrayList<PVector> currentAnchorPoints = new ArrayList<PVector>();
              for(int i = 0; i < n; i++) {
                   currentAnchorPoints.add(getFluctuatedScaledPoint(points.get(i), center, currentTotalScale, totalDuplicateIndex, i, fluctuationAmount, radiusScale));
              }
              
              // Calculate rotation for this set of lines
              float rotationAngle = radians(lineRotationDegrees * totalDuplicateIndex);
              
              for (int j = 0; j < numSegments; j++) {
                  float t_global = map(j, 0, numSegments, 0, n);
                  int segIndex = floor(t_global) % n;
                  float t_segment = t_global - floor(t_global);
                  PVector p0 = currentAnchorPoints.get((segIndex - 1 + n) % n);
                  PVector p1 = currentAnchorPoints.get(segIndex);
                  PVector p2 = currentAnchorPoints.get((segIndex + 1) % n);
                  PVector p3 = currentAnchorPoints.get((segIndex + 2) % n);
                  float interpX = curvePoint(p0.x, p1.x, p2.x, p3.x, t_segment);
                  float interpY = curvePoint(p0.y, p1.y, p2.y, p3.y, t_segment);
                  // Use the rotated line drawing function
                  drawRotatedRadialLine(g, new PVector(interpX, interpY), center, radialLengthPixels, rotationAngle);
              }
          }
      }
  }
  if (debugScaling) {
    println("--- Finished Duplicates ---");
  }
}

// Remove generic controlEvent handler
/*
void controlEvent(ControlEvent theEvent) {
  ...
}
*/

// Add specific handlers for each textfield

public void n(String theValue) {
  try {
    int newN = Integer.parseInt(theValue);
    if (newN != n) { // Only regenerate if n actually changes
        n = max(minPoints, newN);
        regeneratePattern(); // Regenerate random data and recalculate points
    }
  } catch (NumberFormatException e) {
    println("Invalid input for n: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("n")).setValue(""+n);
  }
}

public void offset(String theValue) {
  try {
    float newOffset = Float.parseFloat(theValue);
    if (newOffset != offset) {
        offset = newOffset;
        calculatePoints(); // Only recalculate positions
    }
  } catch (NumberFormatException e) {
    println("Invalid input for offset: " + theValue);
     if (cp5 != null) ((Textfield)cp5.getController("offset")).setValue(nf(offset, 1, 1));
  }
}

public void cycleCount(String theValue) {
  try {
    int currentTotalDuplicates = max(2, cycleCount) * max(1, numberOfCycles);
    int newCount = Integer.parseInt(theValue);
    newCount = max(2, newCount);
    int newTotalDuplicates = newCount * max(1, numberOfCycles);
    
    if (newCount != cycleCount) {
        cycleCount = newCount;
        // Regenerate only if total number of duplicates changes
        if (newTotalDuplicates != currentTotalDuplicates) {
             regeneratePattern(); 
        }
    }
    // Update text field if clamped
    if (cp5 != null && !((Textfield)cp5.getController("cycleCount")).getStringValue().equals(""+cycleCount)) {
       ((Textfield)cp5.getController("cycleCount")).setValue(""+cycleCount);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for cycleCount: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("cycleCount")).setValue(""+cycleCount);
  }
}

public void initialScaleOffset(String theValue) {
  try {
     float newScale = Float.parseFloat(theValue);
     initialScaleOffset = max(0, newScale); 
     if (cp5 != null && initialScaleOffset != newScale) {
       ((Textfield)cp5.getController("initialScaleOffset")).setValue(nf(initialScaleOffset, 1, 2));
    }
  } catch (NumberFormatException e) {
    println("Invalid input for initialScaleOffset: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("initialScaleOffset")).setValue(nf(initialScaleOffset, 1, 2));
  }
}

public void scaleDecay(String theValue) {
  try {
    float newDecay = Float.parseFloat(theValue);
    scaleDecay = max(0, newDecay); 
    if (cp5 != null && scaleDecay != newDecay) {
       ((Textfield)cp5.getController("scaleDecay")).setValue(nf(scaleDecay, 1, 2));
    }
  } catch (NumberFormatException e) {
    println("Invalid input for scaleDecay: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("scaleDecay")).setValue(nf(scaleDecay, 1, 2));
  }
}

public void fluctuationAmount(String theValue) {
  try {
     float newFluct = Float.parseFloat(theValue);
     fluctuationAmount = max(0, newFluct); 
     if (cp5 != null && fluctuationAmount != newFluct) {
       ((Textfield)cp5.getController("fluctuationAmount")).setValue(nf(fluctuationAmount, 1, 2));
    }
  } catch (NumberFormatException e) {
    println("Invalid input for fluctuationAmount: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("fluctuationAmount")).setValue(nf(fluctuationAmount, 1, 2));
  }
}

// Add handlers for new mode controls
public void drawMode(String theValue) {
  try {
    int newMode = Integer.parseInt(theValue);
    drawMode = (newMode == 1) ? 1 : 0; // Clamp to 0 or 1
    if (cp5 != null && drawMode != newMode) { 
       ((Textfield)cp5.getController("drawMode")).setValue(""+drawMode);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for drawMode: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("drawMode")).setValue(""+drawMode);
  }
}

public void radialLineLengthUnits(String theValue) {
  try {
     float newLength = Float.parseFloat(theValue);
     radialLineLengthUnits = max(0, newLength); // Ensure non-negative length
     if (cp5 != null && radialLineLengthUnits != newLength) {
       ((Textfield)cp5.getController("radialLineLengthUnits")).setValue(nf(radialLineLengthUnits, 1, 2));
    }
  } catch (NumberFormatException e) {
    println("Invalid input for radialLineLengthUnits: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("radialLineLengthUnits")).setValue(nf(radialLineLengthUnits, 1, 2));
  }
}

// Add handler for segmentsPerCurve
public void segmentsPerCurve(String theValue) {
  try {
    int newSegments = Integer.parseInt(theValue);
    segmentsPerCurve = max(1, newSegments); // Ensure at least 1 segment
    if (cp5 != null && segmentsPerCurve != newSegments) { 
       ((Textfield)cp5.getController("segmentsPerCurve")).setValue(""+segmentsPerCurve);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for segmentsPerCurve: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("segmentsPerCurve")).setValue(""+segmentsPerCurve);
  }
}

// Add handler for numberOfCycles
public void numberOfCycles(String theValue) {
  try {
    int currentTotalDuplicates = max(2, cycleCount) * max(1, numberOfCycles);
    int newNumCycles = Integer.parseInt(theValue);
    newNumCycles = max(1, newNumCycles); 
    int newTotalDuplicates = max(2, cycleCount) * newNumCycles;

    if (newNumCycles != numberOfCycles) {
        numberOfCycles = newNumCycles;
         // Regenerate only if total number of duplicates changes
        if (newTotalDuplicates != currentTotalDuplicates) {
            regeneratePattern(); 
        }
    }
    // Update text field if clamped
     if (cp5 != null && !((Textfield)cp5.getController("numberOfCycles")).getStringValue().equals(""+numberOfCycles)) {
       ((Textfield)cp5.getController("numberOfCycles")).setValue(""+numberOfCycles);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for numberOfCycles: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("numberOfCycles")).setValue(""+numberOfCycles);
  }
}

// Add handler for lineRotationDegrees
public void lineRotationDegrees(String theValue) {
  try {
    float newRotation = Float.parseFloat(theValue);
    lineRotationDegrees = newRotation; // Allow any value including negative
    if (cp5 != null && !nf(lineRotationDegrees, 1, 1).equals(nf(newRotation, 1, 1))) { 
       ((Textfield)cp5.getController("lineRotationDegrees")).setValue(nf(lineRotationDegrees, 1, 1));
    }
  } catch (NumberFormatException e) {
    println("Invalid input for lineRotationDegrees: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("lineRotationDegrees")).setValue(nf(lineRotationDegrees, 1, 1));
  }
}

// Add a handler for the SVG export button
public void exportSVG() {
  println("SVG export requested via button");
  
  // Make sure we're not already in the middle of an export
  if (recordSVG) {
    println("Export already in progress, ignoring request");
    return;
  }
  
  // Open file selection dialog
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "InterpolatedCircle_" + getTimestamp() + ".svg"), 
    this);
}

// Callback function for the file selection dialog
void svgFileSelected(File selection) {
  if (selection == null) {
    println("SVG export cancelled.");
    return;
  }
  
  svgOutputPath = selection.getAbsolutePath();
  println("Selected SVG path: " + svgOutputPath);
  
  // Check if file exists and delete it to avoid issues
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    println("File already exists, deleting: " + svgOutputPath);
    outputFile.delete();
  }
  
  recordSVG = true;
}

// Helper function to generate timestamp string
String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" + 
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

// Uncomment and modify keyPressed for SVG export trigger
void keyPressed() {
  if (key == 's' || key == 'S') {
      if (!recordSVG) { // Prevent triggering multiple saves at once
          println("Setting recordSVG flag to true");
          recordSVG = true;
      }
  }
  // Add other key presses here if needed
}

/*
// Old commented out version
void keyPressed() {
 ...
}
*/ 