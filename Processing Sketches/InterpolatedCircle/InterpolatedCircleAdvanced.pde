import java.util.ArrayList;
import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library

ControlP5 cp5;
boolean recordSVG = false; // Flag to trigger SVG export
// String focusedControllerName = null; // Removed

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

// Data structures for storing random values
ArrayList<PVector> points; // Stores calculated positions
ArrayList<Float> baseRandomDistances; // Stores random distance (1-7) for base shape
ArrayList<ArrayList<Float>> fluctuationOffsets; // Stores random factor (-1 to 1) for fluctuation [duplicate][point]

void setup() {
  size(2036, 1440); // Set canvas size
  
  cp5 = new ControlP5(this); // Initialize ControlP5
  
  // Create Textfields and link them to variables
  int inputX = 160; // Increased X for longer labels
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 30;
  int currentY = inputY; // Use a separate variable for layout
  
  cp5.addLabel("Points (N):").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("n")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+n);

  currentY += spacing;
  cp5.addLabel("Radius Offset:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("offset")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(offset, 1, 1));
     
  currentY += spacing;
  cp5.addLabel("Cycle Count:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("cycleCount")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+cycleCount);

  currentY += spacing;
  cp5.addLabel("Number of Cycles:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("numberOfCycles")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+numberOfCycles);

  currentY += spacing;
  cp5.addLabel("Initial Scale:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("initialScaleOffset")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(initialScaleOffset, 1, 2));
     
  currentY += spacing;
  cp5.addLabel("Scale Decay:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("scaleDecay")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(scaleDecay, 1, 2));

  currentY += spacing;
  cp5.addLabel("Fluctuation:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("fluctuationAmount")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(fluctuationAmount, 1, 2));

  // --- New Mode Textfields ---
  currentY += spacing;
  cp5.addLabel("Draw Mode (0/1):").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("drawMode")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+drawMode);
  
  currentY += spacing;
  cp5.addLabel("Radial Length:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("radialLineLengthUnits")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(radialLineLengthUnits, 1, 2));

  // --- New Segments Textfield ---
  currentY += spacing;
  cp5.addLabel("Segments Per Curve:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("segmentsPerCurve")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+segmentsPerCurve);

  // --- Regenerate Button ---
  currentY += spacing + 10; // Add extra space before button
  cp5.addButton("regeneratePattern")
     .setLabel("Regenerate")
     .setPosition(10, currentY)
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
void drawFluctuatedCurve(PVector center, float totalScale, int duplicateIndex) {
    if (totalScale <= 1e-6) return; // Skip if scale is too small/negative
    if (points == null || points.size() < n || n < minPoints) return; // Safety checks

    beginShape();
    // Control points (indices n-1, 0, 1)
    PVector fluctuatedLastP = getFluctuatedScaledPoint(points.get(n - 1), center, totalScale, duplicateIndex, n - 1, fluctuationAmount, radiusScale);
    curveVertex(fluctuatedLastP.x, fluctuatedLastP.y);

    // Main points (indices 0 to n-1)
    for (int i = 0; i < n; i++) {
        PVector fluctuatedP = getFluctuatedScaledPoint(points.get(i), center, totalScale, duplicateIndex, i, fluctuationAmount, radiusScale);
        curveVertex(fluctuatedP.x, fluctuatedP.y);
    }

    // Closing control points (indices 0, 1)
    PVector fluctuatedFirstP = getFluctuatedScaledPoint(points.get(0), center, totalScale, duplicateIndex, 0, fluctuationAmount, radiusScale);
    curveVertex(fluctuatedFirstP.x, fluctuatedFirstP.y);
    PVector fluctuatedSecondP = getFluctuatedScaledPoint(points.get(1), center, totalScale, duplicateIndex, 1, fluctuationAmount, radiusScale);
    curveVertex(fluctuatedSecondP.x, fluctuatedSecondP.y);

    endShape();
}

// Helper function to draw a short radial line *inward* from a point towards the center
void drawInwardRadialLine(PVector point, PVector center, float lengthPixels) {
    PVector dirToCenter = PVector.sub(center, point);
    if (dirToCenter.magSq() < 1e-6) return; // Avoid drawing for points at the center
    dirToCenter.normalize();
    PVector endPoint = PVector.add(point, PVector.mult(dirToCenter, lengthPixels)); // Move towards center
    line(point.x, point.y, endPoint.x, endPoint.y);
}

void draw() {
  if (recordSVG) {
    beginRecord(SVG, "InterpolatedCircle-####.svg");
  }

  background(255); 
  PVector center = new PVector(width / 2.0, height / 2.0);
  
  if (points != null && points.size() >= n && n >= minPoints) { 
    stroke(0); 
    strokeWeight(1); 
    noFill();
    
    // Variables needed by both draw modes
    float radialLengthPixels = radialLineLengthUnits * radiusScale;
    int numSegments = max(1, segmentsPerCurve);

    // Draw Original Curve (or its radial lines)
    if (drawMode == 0) {
        // Draw CURVES Mode - Original curve
        beginShape();
        curveVertex(points.get(n - 1).x, points.get(n - 1).y); 
        for (int i = 0; i < n; i++) {
          curveVertex(points.get(i).x, points.get(i).y);
        }
        curveVertex(points.get(0).x, points.get(0).y);
        curveVertex(points.get(1).x, points.get(1).y); 
        endShape();
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
            drawInwardRadialLine(new PVector(interpX, interpY), center, radialLengthPixels);
        }
    }

    // --- Draw Duplicate Cycles (Multiplicative Scaling) --- 
    int effectiveCycleCount = max(2, cycleCount);
    int effectiveNumCycles = max(1, numberOfCycles);
    println("--- Starting Duplicates --- Cycles:", effectiveNumCycles, " Steps/Cycle:", effectiveCycleCount); // DEBUG
    
    int halfCycle = effectiveCycleCount / 2;
    float firstRelativeOffset = max(0.01, initialScaleOffset - 1.0); // Ensure at least small positive value
    println("  firstRelativeOffset:", firstRelativeOffset); // DEBUG
    
    // For each cycle, start with the scale from the end of the previous cycle
    // or 1.0 for the first cycle
    float currentTotalScale = 1.0;

    // Outer loop for cycles
    for (int cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
        println("  Entering Cycle:", cycleNum); // DEBUG
        
        // Inner loop for steps within a cycle
        for (int d = 0; d < effectiveCycleCount; d++) { 
            int exponentIndex = (d < halfCycle) ? d : (effectiveCycleCount - 1 - d);
            float stepScaleFactor = 1.0 + firstRelativeOffset * pow(scaleDecay, exponentIndex); 
            currentTotalScale *= stepScaleFactor; 

            println("    d:", d, " expIdx:", exponentIndex, " stepFactor:", nf(stepScaleFactor,1,4), " totalScale:", nf(currentTotalScale,1,4)); // DEBUG

            if (currentTotalScale <= 1e-6) {
                 println("      Scale too small, skipping rest."); // DEBUG
                 continue; 
            }

            int totalDuplicateIndex = cycleNum * effectiveCycleCount + d;

            if (drawMode == 0) {
                // Draw curve with current scale
                drawFluctuatedCurve(center, currentTotalScale, totalDuplicateIndex);
            } else {
                // Draw radial lines with current scale
                ArrayList<PVector> currentAnchorPoints = new ArrayList<PVector>();
                for(int i = 0; i < n; i++) {
                     currentAnchorPoints.add(getFluctuatedScaledPoint(points.get(i), center, currentTotalScale, totalDuplicateIndex, i, fluctuationAmount, radiusScale));
                }
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
                    drawInwardRadialLine(new PVector(interpX, interpY), center, radialLengthPixels);
                }
            }
        }
    }
    println("--- Finished Duplicates ---"); // DEBUG
  }
  
  if (!recordSVG) {
      cp5.draw(); 
  }

  if (recordSVG) {
    endRecord();
    println("SVG record finished.");
    recordSVG = false; 
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