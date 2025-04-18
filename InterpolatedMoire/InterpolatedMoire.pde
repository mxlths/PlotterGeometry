import java.util.ArrayList;
import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class
import java.util.HashMap; // Import HashMap class

ControlP5 cp5;
boolean recordSVG = false; // Flag to trigger SVG export
String svgOutputPath = null; // Path for SVG output
boolean debugScaling = false; // Flag to control debug output for scaling calculations
PGraphics svgOutput; // SVG graphics object for direct export
PFont labelFont; // Font for the labels

// Basic pattern parameters
int n = 7; // Number of points
float offset = 2.0; // Offset for the radius
float radiusScale = 50; // Scale factor for the radius units
int minPoints = 3;

// Duplication parameters
int cycleCount = 100; // Total duplicates in one shrink-then-grow cycle
int numberOfCycles = 1; // Number of times to repeat the cycle
float initialScaleOffset = 1.1; 
float scaleDecay = 0.9;       
float fluctuationAmount = 0.1;
int drawMode = 0; // 0 = curves, 1 = radial lines
float radialLineLengthUnits = 0.05;
int segmentsPerCurve = 100; // Number of radial lines per curve path
float lineRotationDegrees = 15.0; // Rotation angle for each set of lines in degrees

// Moiré effect parameters
boolean enableMoireEffect = true; // Toggle for moiré effect
int numLayers = 2; // Number of overlapping pattern layers
float layerRotationOffset = 3.0; // Rotation offset between layers (degrees)
float layerScaleOffset = 0.02; // Scale offset between layers
int layerPointOffset = 0; // Point count offset between layers
PVector[] layerCenterOffsets; // Array to store center offsets for each layer
float[] layerAlphas; // Array for layer transparency

// Data structures for storing random values
ArrayList<PVector> points; // Stores calculated positions
ArrayList<Float> baseRandomDistances; // Stores random distance (1-7) for base shape
ArrayList<ArrayList<Float>> fluctuationOffsets; // Stores random factor (-1 to 1) for fluctuation [duplicate][point]
HashMap<Integer, ArrayList<PVector>> customPointsCache; // Cache for custom point counts to prevent shifting

void setup() {
  size(2036, 1440); // Set canvas size
  
  cp5 = new ControlP5(this); // Initialize ControlP5
  
  // Create a larger font for labels
  labelFont = createFont("Arial", 14, true);
  
  // Initialize Moiré effect arrays
  layerCenterOffsets = new PVector[numLayers];
  layerAlphas = new float[numLayers];
  
  // Set default values
  for (int i = 0; i < numLayers; i++) {
    layerCenterOffsets[i] = new PVector(i * 10, i * 10); // Default offset
    layerAlphas[i] = 150; // Default alpha (0-255)
  }
  
  // Create UI
  createUI();
  
  // Initialize data structures and generate initial pattern
  points = new ArrayList<PVector>();
  baseRandomDistances = new ArrayList<Float>();
  fluctuationOffsets = new ArrayList<ArrayList<Float>>();
  customPointsCache = new HashMap<Integer, ArrayList<PVector>>();
  regeneratePattern(); 
}

void createUI() {
  // Create Textfields and link them to variables
  int inputX = 160; // Increased X for longer labels
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 30;
  int currentY = inputY; // Use a separate variable for layout
  
  // --- Original Controls ---
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

  currentY += spacing;
  cp5.addLabel("Segments Per Curve:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("segmentsPerCurve")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+segmentsPerCurve);

  currentY += spacing;
  cp5.addLabel("Line Rotation (deg):")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("lineRotationDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lineRotationDegrees, 1, 1));

  // --- New Moiré Effect Controls ---
  currentY += spacing;
  cp5.addLabel("Enable Moiré Effect:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addToggle("enableMoireEffect")
     .setPosition(inputX, currentY)
     .setSize(inputW/2, inputH)
     .setValue(enableMoireEffect);

  currentY += spacing;
  cp5.addLabel("Number of Layers:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("numLayers")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+numLayers);

  currentY += spacing;
  cp5.addLabel("Layer Rotation:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("layerRotationOffset")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(layerRotationOffset, 1, 2));

  currentY += spacing;
  cp5.addLabel("Layer Scale Offset:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("layerScaleOffset")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(layerScaleOffset, 1, 3));

  currentY += spacing;
  cp5.addLabel("Layer Points Offset:")
     .setPosition(10, currentY + 4)
     .setSize(140, inputH)
     .setColor(color(255, 0, 0))
     .setFont(labelFont);
     
  cp5.addTextfield("layerPointOffset")
     .setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+layerPointOffset);

  // --- Regenerate Button and Export Button ---
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
}

// Function to generate and store all random values
void regeneratePattern() {
  println("Regenerating pattern...");
  cycleCount = max(2, cycleCount);
  numberOfCycles = max(1, numberOfCycles);
  int totalDuplicates = cycleCount * numberOfCycles;
  
  // Update the arrays for the current numLayers
  if (layerCenterOffsets.length != numLayers) {
    PVector[] newOffsets = new PVector[numLayers];
    float[] newAlphas = new float[numLayers];
    
    // Copy existing values where possible
    for (int i = 0; i < numLayers; i++) {
      if (i < layerCenterOffsets.length) {
        newOffsets[i] = layerCenterOffsets[i];
        newAlphas[i] = layerAlphas[i];
      } else {
        newOffsets[i] = new PVector(i * 10, i * 10); // Default offset
        newAlphas[i] = 150; // Default alpha (0-255)
      }
    }
    
    layerCenterOffsets = newOffsets;
    layerAlphas = newAlphas;
  }
  
  baseRandomDistances.clear();
  fluctuationOffsets.clear();
  customPointsCache.clear(); // Clear the custom points cache

  // Generate base distances
  for (int i = 0; i < n; i++) {
    baseRandomDistances.add(random(1, 7));
  }

  // Generate fluctuation offsets for all potential duplicates
  for (int d = 0; d < totalDuplicates; d++) {
    ArrayList<Float> currentDuplicateOffsets = new ArrayList<Float>();
    for (int i = 0; i < n; i++) {
      currentDuplicateOffsets.add(random(-1, 1)); // Store factor -1 to 1
    }
    fluctuationOffsets.add(currentDuplicateOffsets);
  }
  
  calculatePoints(); // Calculate positions based on new random data
  
  // Pre-generate custom points for each potential layer point count
  if (enableMoireEffect && layerPointOffset != 0) {
    for (int layer = 0; layer < numLayers; layer++) {
      int layerN = n + (layer * layerPointOffset);
      if (layerN >= minPoints && !customPointsCache.containsKey(layerN)) {
        // Calculate center position
        PVector center = new PVector(width / 2.0, height / 2.0);
        // Generate and cache the custom points
        customPointsCache.put(layerN, generateCustomPoints(center, layerN));
      }
    }
  }
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
  
  if (points != null && points.size() >= n && n >= minPoints) {
    // Draw pattern (or multiple patterns for moiré effect)
    if (enableMoireEffect && numLayers > 1) {
      // Draw each layer with its own transformations for moiré effect
      for (int layer = 0; layer < numLayers; layer++) {
        // Create a PGraphics buffer for this layer
        PGraphics layerBuffer = createGraphics(width, height);
        layerBuffer.beginDraw();
        layerBuffer.background(255, 0); // Transparent background
        
        // Set up the drawing style
        layerBuffer.stroke(0, layerAlphas[layer]);
        layerBuffer.strokeWeight(1);
        layerBuffer.noFill();
        
        // Calculate the center for this layer with offset
        PVector layerCenter = new PVector(
          width / 2.0 + layerCenterOffsets[layer].x,
          height / 2.0 + layerCenterOffsets[layer].y
        );
        
        // Calculate effective parameters for this layer
        int layerN = n + (layer * layerPointOffset);
        layerN = max(minPoints, layerN);
        float layerRotation = layer * layerRotationOffset;
        float layerScale = 1.0 + (layer * layerScaleOffset);
        
        // Draw the pattern with layer-specific transformations
        drawPatternWithTransform(layerBuffer, layerCenter, layerRotation, layerScale, layerN);
        
        layerBuffer.endDraw();
        
        // Draw the layer to the main canvas
        image(layerBuffer, 0, 0);
      }
    } else {
      // Draw a single pattern (no moiré effect)
      stroke(0);
      strokeWeight(1);
      noFill();
      PVector center = new PVector(width / 2.0, height / 2.0);
      drawPattern(this.g, center);
    }
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
      
      // Draw the pattern(s) to the SVG graphics object
      if (points != null && points.size() >= n && n >= minPoints) {
        svg.stroke(0);
        svg.strokeWeight(1);
        svg.noFill();
        
        if (enableMoireEffect && numLayers > 1) {
          // Draw each layer with its own transformations for moiré effect
          for (int layer = 0; layer < numLayers; layer++) {
            // Set up the drawing style
            svg.stroke(0, layerAlphas[layer]);
            
            // Calculate the center for this layer with offset
            PVector layerCenter = new PVector(
              width / 2.0 + layerCenterOffsets[layer].x,
              height / 2.0 + layerCenterOffsets[layer].y
            );
            
            // Calculate effective parameters for this layer
            int layerN = n + (layer * layerPointOffset);
            layerN = max(minPoints, layerN);
            float layerRotation = layer * layerRotationOffset;
            float layerScale = 1.0 + (layer * layerScaleOffset);
            
            // Draw the pattern with layer-specific transformations
            drawPatternWithTransform(svg, layerCenter, layerRotation, layerScale, layerN);
          }
        } else {
          // Draw a single pattern
          PVector center = new PVector(width / 2.0, height / 2.0);
          drawPattern(svg, center);
        }
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

// Draw pattern with transformations (for layered moiré effect)
void drawPatternWithTransform(PGraphics g, PVector center, float rotation, float scale, int pointCount) {
  g.pushMatrix();
  
  // Apply rotation around the pattern center
  if (rotation != 0) {
    g.translate(center.x, center.y);
    g.rotate(radians(rotation));
    g.translate(-center.x, -center.y);
  }
  
  // Draw a modified pattern with specified parameters
  // We use the main pattern and apply scaling
  if (points != null && points.size() >= n && n >= minPoints) {
    // Variables needed by both draw modes
    float radialLengthPixels = radialLineLengthUnits * radiusScale * scale;
    int numSegments = max(1, segmentsPerCurve);

    // Draw Original Curve (or its radial lines)
    if (drawMode == 0) {
      // Draw CURVES Mode - Original curve
      if (pointCount == n) {
        // Can use the original points with scaling
        drawScaledCurve(g, center, scale);
      } else {
        // Need to calculate different points
        drawCustomCurve(g, center, pointCount, scale);
      }
    } else {
      // Draw INTERPOLATED INWARD RADIAL LINES Mode - Original curve
      if (pointCount == n) {
        drawScaledRadialLines(g, center, numSegments, radialLengthPixels, scale);
      } else {
        drawCustomRadialLines(g, center, pointCount, numSegments, radialLengthPixels, scale);
      }
    }

    // --- Draw Duplicate Cycles (Multiplicative Scaling) --- 
    int effectiveCycleCount = max(2, cycleCount);
    int effectiveNumCycles = max(1, numberOfCycles);
    
    int halfCycle = effectiveCycleCount / 2;
    float firstRelativeOffset = max(0.01, initialScaleOffset - 1.0);
    
    float currentTotalScale = scale; // Start with the layer scale

    // Outer loop for cycles
    for (int cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
      // Inner loop for steps within a cycle
      for (int d = 0; d < effectiveCycleCount; d++) { 
        int exponentIndex = (d < halfCycle) ? d : (effectiveCycleCount - 1 - d);
        float stepScaleFactor = 1.0 + firstRelativeOffset * pow(scaleDecay, exponentIndex); 
        currentTotalScale *= stepScaleFactor; 

        if (currentTotalScale <= 1e-6) {
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
  }
  
  g.popMatrix();
}

// Helper methods for drawing patterns with different point counts
void drawScaledCurve(PGraphics g, PVector center, float scale) {
  g.beginShape();
  // Control points (indices n-1, 0, 1)
  PVector scaledLastP = scalePoint(points.get(n - 1), center, scale);
  g.curveVertex(scaledLastP.x, scaledLastP.y);

  // Main points (indices 0 to n-1)
  for (int i = 0; i < n; i++) {
    PVector scaledP = scalePoint(points.get(i), center, scale);
    g.curveVertex(scaledP.x, scaledP.y);
  }

  // Closing control points (indices 0, 1)
  PVector scaledFirstP = scalePoint(points.get(0), center, scale);
  g.curveVertex(scaledFirstP.x, scaledFirstP.y);
  PVector scaledSecondP = scalePoint(points.get(1), center, scale);
  g.curveVertex(scaledSecondP.x, scaledSecondP.y);

  g.endShape();
}

// Draw a curve with a custom number of points
void drawCustomCurve(PGraphics g, PVector center, int customN, float scale) {
  ArrayList<PVector> customPoints = generateCustomPoints(center, customN);
  
  g.beginShape();
  // Control points
  PVector scaledLastP = scalePoint(customPoints.get(customN - 1), center, scale);
  g.curveVertex(scaledLastP.x, scaledLastP.y);

  // Main points
  for (int i = 0; i < customN; i++) {
    PVector scaledP = scalePoint(customPoints.get(i), center, scale);
    g.curveVertex(scaledP.x, scaledP.y);
  }

  // Closing control points
  PVector scaledFirstP = scalePoint(customPoints.get(0), center, scale);
  g.curveVertex(scaledFirstP.x, scaledFirstP.y);
  PVector scaledSecondP = scalePoint(customPoints.get(1), center, scale);
  g.curveVertex(scaledSecondP.x, scaledSecondP.y);

  g.endShape();
}

// Generate a set of custom points with the specified count
ArrayList<PVector> generateCustomPoints(PVector center, int customN) {
  // Check if we already have cached points for this count
  if (customPointsCache.containsKey(customN)) {
    return customPointsCache.get(customN);
  }
  
  ArrayList<PVector> customPoints = new ArrayList<PVector>();
  
  // Use a fixed seed for consistent randomness based on customN
  randomSeed(customN * 10000 + 12345);
  
  // Generate random distances for this point count
  ArrayList<Float> customDists = new ArrayList<Float>();
  for (int i = 0; i < customN; i++) {
    customDists.add(random(1, 7));
  }
  
  // Reset the random seed to avoid affecting other randomness
  randomSeed(System.currentTimeMillis());
  
  // Calculate positions
  for (int i = 0; i < customN; i++) {
    float angle = map(i, 0, customN, 0, TWO_PI);
    float baseDist = customDists.get(i);
    float dist = (baseDist + offset) * radiusScale;
    float x = center.x + cos(angle) * dist;
    float y = center.y + sin(angle) * dist;
    customPoints.add(new PVector(x, y));
  }
  
  // Cache the result
  customPointsCache.put(customN, customPoints);
  
  return customPoints;
}

// Draw radial lines with scaling
void drawScaledRadialLines(PGraphics g, PVector center, int numSegments, float radialLengthPixels, float scale) {
  for (int j = 0; j < numSegments; j++) {
    float t_global = map(j, 0, numSegments, 0, n);
    int segIndex = floor(t_global) % n;
    float t_segment = t_global - floor(t_global);
    
    PVector p0 = scalePoint(points.get((segIndex - 1 + n) % n), center, scale);
    PVector p1 = scalePoint(points.get(segIndex), center, scale);
    PVector p2 = scalePoint(points.get((segIndex + 1) % n), center, scale);
    PVector p3 = scalePoint(points.get((segIndex + 2) % n), center, scale);
    
    float interpX = curvePoint(p0.x, p1.x, p2.x, p3.x, t_segment);
    float interpY = curvePoint(p0.y, p1.y, p2.y, p3.y, t_segment);
    drawInwardRadialLine(g, new PVector(interpX, interpY), center, radialLengthPixels);
  }
}

// Draw radial lines with custom point count
void drawCustomRadialLines(PGraphics g, PVector center, int customN, int numSegments, float radialLengthPixels, float scale) {
  ArrayList<PVector> customPoints = generateCustomPoints(center, customN);
  
  for (int j = 0; j < numSegments; j++) {
    float t_global = map(j, 0, numSegments, 0, customN);
    int segIndex = floor(t_global) % customN;
    float t_segment = t_global - floor(t_global);
    
    PVector p0 = scalePoint(customPoints.get((segIndex - 1 + customN) % customN), center, scale);
    PVector p1 = scalePoint(customPoints.get(segIndex), center, scale);
    PVector p2 = scalePoint(customPoints.get((segIndex + 1) % customN), center, scale);
    PVector p3 = scalePoint(customPoints.get((segIndex + 2) % customN), center, scale);
    
    float interpX = curvePoint(p0.x, p1.x, p2.x, p3.x, t_segment);
    float interpY = curvePoint(p0.y, p1.y, p2.y, p3.y, t_segment);
    drawInwardRadialLine(g, new PVector(interpX, interpY), center, radialLengthPixels);
  }
}

// Simple scaling of a point around a center
PVector scalePoint(PVector originalPoint, PVector center, float scale) {
  PVector result = PVector.sub(originalPoint, center);
  result.mult(scale);
  result.add(center);
  return result;
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
    new File(sketchPath(""), "InterpolatedMoire_" + getTimestamp() + ".svg"), 
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

// Event handlers for UI controls
public void enableMoireEffect(boolean value) {
  enableMoireEffect = value;
}

public void numLayers(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    newValue = max(1, newValue); // Ensure at least 1 layer
    if (newValue != numLayers) {
      numLayers = newValue;
      
      // Update arrays for the new size
      PVector[] newOffsets = new PVector[numLayers];
      float[] newAlphas = new float[numLayers];
      
      for (int i = 0; i < numLayers; i++) {
        if (i < layerCenterOffsets.length) {
          newOffsets[i] = layerCenterOffsets[i];
          newAlphas[i] = layerAlphas[i];
        } else {
          newOffsets[i] = new PVector(i * 10, i * 10);
          newAlphas[i] = 150;
        }
      }
      
      layerCenterOffsets = newOffsets;
      layerAlphas = newAlphas;
      
      // Pre-generate custom points for any new layers if needed
      if (enableMoireEffect && layerPointOffset != 0) {
        for (int layer = 0; layer < numLayers; layer++) {
          int layerN = n + (layer * layerPointOffset);
          if (layerN >= minPoints && !customPointsCache.containsKey(layerN)) {
            PVector center = new PVector(width / 2.0, height / 2.0);
            customPointsCache.put(layerN, generateCustomPoints(center, layerN));
          }
        }
      }
    }
    
    if (cp5 != null && numLayers != newValue) {
      ((Textfield)cp5.getController("numLayers")).setValue(""+numLayers);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for numLayers: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("numLayers")).setValue(""+numLayers);
  }
}

public void layerRotationOffset(String theValue) {
  try {
    float newValue = Float.parseFloat(theValue);
    layerRotationOffset = newValue;
  } catch (NumberFormatException e) {
    println("Invalid input for layerRotationOffset: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("layerRotationOffset")).setValue(nf(layerRotationOffset, 1, 2));
  }
}

public void layerScaleOffset(String theValue) {
  try {
    float newValue = Float.parseFloat(theValue);
    layerScaleOffset = newValue;
  } catch (NumberFormatException e) {
    println("Invalid input for layerScaleOffset: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("layerScaleOffset")).setValue(nf(layerScaleOffset, 1, 3));
  }
}

public void layerPointOffset(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    if (layerPointOffset != newValue) {
      layerPointOffset = newValue;
      
      // Clear and regenerate the custom points cache for all affected layers
      customPointsCache.clear();
      
      // Pre-generate custom points for each layer if needed
      if (enableMoireEffect && layerPointOffset != 0) {
        for (int layer = 0; layer < numLayers; layer++) {
          int layerN = n + (layer * layerPointOffset);
          if (layerN >= minPoints) {
            PVector center = new PVector(width / 2.0, height / 2.0);
            customPointsCache.put(layerN, generateCustomPoints(center, layerN));
          }
        }
      }
    }
  } catch (NumberFormatException e) {
    println("Invalid input for layerPointOffset: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("layerPointOffset")).setValue(""+layerPointOffset);
  }
}

// Original parameter handlers
public void n(String theValue) {
  try {
    int newN = Integer.parseInt(theValue);
    if (newN != n) {
      n = max(minPoints, newN);
      regeneratePattern();
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
      calculatePoints();
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
      if (newTotalDuplicates != currentTotalDuplicates) {
        regeneratePattern();
      }
    }
    if (cp5 != null && !((Textfield)cp5.getController("cycleCount")).getStringValue().equals(""+cycleCount)) {
      ((Textfield)cp5.getController("cycleCount")).setValue(""+cycleCount);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for cycleCount: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("cycleCount")).setValue(""+cycleCount);
  }
}

public void numberOfCycles(String theValue) {
  try {
    int currentTotalDuplicates = max(2, cycleCount) * max(1, numberOfCycles);
    int newNumCycles = Integer.parseInt(theValue);
    newNumCycles = max(1, newNumCycles);
    int newTotalDuplicates = max(2, cycleCount) * newNumCycles;

    if (newNumCycles != numberOfCycles) {
      numberOfCycles = newNumCycles;
      if (newTotalDuplicates != currentTotalDuplicates) {
        regeneratePattern();
      }
    }
    if (cp5 != null && !((Textfield)cp5.getController("numberOfCycles")).getStringValue().equals(""+numberOfCycles)) {
      ((Textfield)cp5.getController("numberOfCycles")).setValue(""+numberOfCycles);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for numberOfCycles: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("numberOfCycles")).setValue(""+numberOfCycles);
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

public void drawMode(String theValue) {
  try {
    int newMode = Integer.parseInt(theValue);
    drawMode = (newMode == 1) ? 1 : 0;
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
    radialLineLengthUnits = max(0, newLength);
    if (cp5 != null && radialLineLengthUnits != newLength) {
      ((Textfield)cp5.getController("radialLineLengthUnits")).setValue(nf(radialLineLengthUnits, 1, 2));
    }
  } catch (NumberFormatException e) {
    println("Invalid input for radialLineLengthUnits: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("radialLineLengthUnits")).setValue(nf(radialLineLengthUnits, 1, 2));
  }
}

public void segmentsPerCurve(String theValue) {
  try {
    int newSegments = Integer.parseInt(theValue);
    segmentsPerCurve = max(1, newSegments);
    if (cp5 != null && segmentsPerCurve != newSegments) {
      ((Textfield)cp5.getController("segmentsPerCurve")).setValue(""+segmentsPerCurve);
    }
  } catch (NumberFormatException e) {
    println("Invalid input for segmentsPerCurve: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("segmentsPerCurve")).setValue(""+segmentsPerCurve);
  }
}

public void lineRotationDegrees(String theValue) {
  try {
    float newRotation = Float.parseFloat(theValue);
    lineRotationDegrees = newRotation;
    if (cp5 != null && !nf(lineRotationDegrees, 1, 1).equals(nf(newRotation, 1, 1))) {
      ((Textfield)cp5.getController("lineRotationDegrees")).setValue(nf(lineRotationDegrees, 1, 1));
    }
  } catch (NumberFormatException e) {
    println("Invalid input for lineRotationDegrees: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("lineRotationDegrees")).setValue(nf(lineRotationDegrees, 1, 1));
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    if (!recordSVG) {
      println("Setting recordSVG flag to true");
      exportSVG();
    }
  }
} 