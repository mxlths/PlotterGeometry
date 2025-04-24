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
int numShrinkingDuplicates = 5; // Renamed from numDuplicates
int numGrowingDuplicates = 5;   // New parameter
float initialScaleOffset = 1.1; 
float scaleDecay = 0.9;       
float fluctuationAmount = 0.1;

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
  cp5.addLabel("Shrinking Duplicates:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("numShrinkingDuplicates")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+numShrinkingDuplicates);

  currentY += spacing;
  cp5.addLabel("Growing Duplicates:").setPosition(10, currentY + 4).setSize(140, inputH);
  cp5.addTextfield("numGrowingDuplicates")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+numGrowingDuplicates);

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
  int totalMaxDuplicates = max(max(0, numShrinkingDuplicates), max(0, numGrowingDuplicates));
  for (int d = 0; d < totalMaxDuplicates; d++) {
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

void draw() {
  if (recordSVG) {
    println("Starting SVG record...");
    beginRecord(SVG, "InterpolatedCircle-####.svg");
  }

  background(255); 
  PVector center = new PVector(width / 2.0, height / 2.0);
  
  if (points != null && points.size() >= n && n >= minPoints) { 
    stroke(0); 
    strokeWeight(1); 
    noFill(); 

    // --- Draw Original Curve ---
    beginShape();
    curveVertex(points.get(n - 1).x, points.get(n - 1).y); 
    for (int i = 0; i < n; i++) {
      curveVertex(points.get(i).x, points.get(i).y);
    }
    curveVertex(points.get(0).x, points.get(0).y);
    curveVertex(points.get(1).x, points.get(1).y); 
    endShape();

    // --- Draw Shrinking Gap Duplicates ---
    int effectiveShrinkingDuplicates = max(0, numShrinkingDuplicates);
    float firstOffsetAmount = max(0, initialScaleOffset - 1.0); 
    float currentShrinkingScale = 1.0; 
    for (int d = 0; d < effectiveShrinkingDuplicates; d++) { 
      float offsetThisStep = firstOffsetAmount * pow(scaleDecay, d); 
      currentShrinkingScale += offsetThisStep;
      drawFluctuatedCurve(center, currentShrinkingScale, d); 
    }
    
    // Capture the final scale after shrinking duplicates
    float lastShrinkingScale = currentShrinkingScale; // Will be 1.0 if loop didn't run

    // --- Draw Growing Gap Duplicates ---
    int effectiveGrowingDuplicates = max(0, numGrowingDuplicates);
    float growthFactor = (abs(scaleDecay) > 1e-6) ? (1.0 / scaleDecay) : 1000.0; 
    // Initialize growing scale from the last shrinking scale
    float currentGrowingScale = lastShrinkingScale;
    
    // The duplicate index for fluctuation should continue from shrinking ones if possible,
    // but fluctuationOffsets is sized for max(shrink, grow), so using d_grow is safe
    // and ensures unique fluctuation per visual ring.
    for (int d_grow = 0; d_grow < effectiveGrowingDuplicates; d_grow++) {
        float offsetThisStep = firstOffsetAmount * pow(growthFactor, d_grow); 
        currentGrowingScale += offsetThisStep;
        // Use d_grow directly as the index into fluctuationOffsets 
        // Requires fluctuationOffsets to be large enough for max(shrink, grow)
        drawFluctuatedCurve(center, currentGrowingScale, d_grow); 
    }
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

public void numShrinkingDuplicates(String theValue) {
  try {
    int newNum = Integer.parseInt(theValue);
    numShrinkingDuplicates = max(0, newNum);
    // Check if fluctuation data needs resizing
    int totalMaxDuplicates = max(numShrinkingDuplicates, max(0, numGrowingDuplicates));
    while (fluctuationOffsets.size() < totalMaxDuplicates) {
        ArrayList<Float> newDupOffsets = new ArrayList<Float>();
        for(int i=0; i<n; i++) newDupOffsets.add(random(-1, 1));
        fluctuationOffsets.add(newDupOffsets);
    }
    if (cp5 != null && numShrinkingDuplicates != newNum) {
       ((Textfield)cp5.getController("numShrinkingDuplicates")).setValue(""+numShrinkingDuplicates);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for numShrinkingDuplicates: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("numShrinkingDuplicates")).setValue(""+numShrinkingDuplicates);
  }
}

public void numGrowingDuplicates(String theValue) {
  try {
    int newNum = Integer.parseInt(theValue);
    numGrowingDuplicates = max(0, newNum);
    // Check if fluctuation data needs resizing
    int totalMaxDuplicates = max(max(0, numShrinkingDuplicates), numGrowingDuplicates);
    while (fluctuationOffsets.size() < totalMaxDuplicates) {
        ArrayList<Float> newDupOffsets = new ArrayList<Float>();
        for(int i=0; i<n; i++) newDupOffsets.add(random(-1, 1));
        fluctuationOffsets.add(newDupOffsets);
    }
    if (cp5 != null && numGrowingDuplicates != newNum) {
       ((Textfield)cp5.getController("numGrowingDuplicates")).setValue(""+numGrowingDuplicates);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for numGrowingDuplicates: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("numGrowingDuplicates")).setValue(""+numGrowingDuplicates);
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