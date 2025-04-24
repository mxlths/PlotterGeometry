import java.util.ArrayList;
import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import processing.pdf.*; // Import PDF library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class

// Main UI controller
ControlP5 cp5;

// SVG export variables
boolean recordingSVG = false;
String svgOutputPath = null;
PGraphics svgOutput;

// Basic pattern parameters
float patternSize = 400;
float baseRadius = 50;

// Points for interpolated pattern
int numInterpolationPoints = 12;              // Number of points to interpolate between
int minPoints = 3;       // Minimum number of points
float offset = 0.3;      // Pattern offset
int cycleCount = 5;      // Number of duplicates per cycle
int numberOfCycles = 3;  // Number of cycles (can be 0 for single pattern)
float initialScaleOffset = 0.5; // Initial scale of the pattern
float scaleDecay = 2.0;  // How much the pattern shrinks each duplicate
float fluctuationAmount = 0.1; // Random variation amount
int drawMode = 0;        // 0 = curve, 1 = radial lines
float radiusScale = 300; // Base scale for the pattern
float radialLineLengthUnits = 0.2; // Length of radial lines (in relative units)
int segmentsPerCurve = 150; // Resolution of the curve
float lineRotationDegrees = 0; // Rotation angle for lines in degrees

// Lissajous parameters
float freqX = 3;         // X frequency
float freqY = 2;         // Y frequency
float phaseShift = PI/2; // Phase shift in radians
float lissAmpX = 250;    // X amplitude
float lissAmpY = 250;    // Y amplitude
int lissPoints = 300;    // Number of points in Lissajous curve
int lissLayers = 3;      // Number of Lissajous layers
float lissFreqStep = 0.5;// Frequency step between layers
float lissPhaseDelta = PI/4; // Phase shift between layers
int lissCycles = 1;      // Number of cycles to draw in each Lissajous curve
boolean useLissajous = true; // Whether to draw Lissajous curves
boolean useLissajousModulation = false; // Whether to use Lissajous modulation
float envelopeFreq = 1.0; // Frequency for the amplitude modulation envelope

// Data storage for the pattern
ArrayList<PVector> points = new ArrayList<PVector>();
ArrayList<Float> baseRandomDistances = new ArrayList<Float>();
ArrayList<ArrayList<Float>> fluctuationOffsets = new ArrayList<ArrayList<Float>>();
ArrayList<ArrayList<PVector>> lissajousLayers = new ArrayList<ArrayList<PVector>>();
ArrayList<PVector> lissajousPoints = new ArrayList<PVector>();
float[] angles; // Array of angles for pattern points
float[] radialLengths; // Array of radial lengths for pattern points

// Rendering options
boolean drawGridLines = true;
boolean startedRecording = false;
boolean savePDF = false;

// Pattern control
int numPoints = 100;
int numPointsToRender = 500;
float baseRadialLength = 150;
float radialVariation = 50;
float circleRadius = 200;

// Scale properties
float cycleRepeat = 3.0;
float maxScale = 0.5;
float globalScale = 1.0;
float rotationX = 0;
float rotationY = 0;
float cycleScaleFactor = 0.85;
float cycleScaleOffset = 0.0;
float fadeAmount = 0.5;
float spatialScale = 1.0;

// Fluctuation effects
boolean useFluctuation = false;
float maxFluctuation = 20;
float fluctuationSpeed = 1.0;
float fluctuationFreq = 2.0;

// Style properties
color lineColor = color(0, 0, 0);  // Black lines
color bgColor = color(255);  // White background
float lineWeight = 1.5;
int lineOpacity = 175;
boolean showUI = true;
boolean debugMode = false;  // Set debug mode to false by default

void setup() {
  size(800, 800, P3D);
  smooth(8);
  
  // Initialize UI
  initializeUI();
  
  // Generate initial pattern
  regeneratePattern();
}

void initializeUI() {
  cp5 = new ControlP5(this);
  
  int sliderWidth = 200;
  int sliderHeight = 20;
  int startY = 20;
  int startX = 20;
  int gap = 30;
  int buttonWidth = 120;
  int buttonHeight = 25;
  
  // Main pattern controls
  cp5.addSlider("numPoints")
     .setPosition(startX, startY)
     .setSize(sliderWidth, sliderHeight)
     .setRange(10, 500)
     .setValue(numPoints);
  
  cp5.addSlider("numPointsToRender")
     .setPosition(startX, startY + gap)
     .setSize(sliderWidth, sliderHeight)
     .setRange(100, 2000)
     .setValue(numPointsToRender);
  
  cp5.addSlider("numInterpolationPoints")
     .setPosition(startX, startY + gap*2)
     .setSize(sliderWidth, sliderHeight)
     .setRange(3, 24)
     .setValue(numInterpolationPoints)
     .setCaptionLabel("Interpolation Points");
  
  cp5.addSlider("baseRadialLength")
     .setPosition(startX, startY + gap*3)
     .setSize(sliderWidth, sliderHeight)
     .setRange(50, 400)
     .setValue(baseRadialLength);
  
  cp5.addSlider("radialVariation")
     .setPosition(startX, startY + gap*4)
     .setSize(sliderWidth, sliderHeight)
     .setRange(0, 200)
     .setValue(radialVariation);
  
  // Scale controls  
  cp5.addSlider("cycleRepeat")
     .setPosition(startX, startY + gap*5)
     .setSize(sliderWidth, sliderHeight)
     .setRange(1, 10)
     .setValue(cycleRepeat);
  
  cp5.addSlider("maxScale")
     .setPosition(startX, startY + gap*6)
     .setSize(sliderWidth, sliderHeight)
     .setRange(0.1, 0.95)
     .setValue(maxScale);
  
  // Style controls
  cp5.addSlider("lineWeight")
     .setPosition(startX, startY + gap*7)
     .setSize(sliderWidth, sliderHeight)
     .setRange(0.5, 5)
     .setValue(lineWeight);
  
  cp5.addSlider("lineOpacity")
     .setPosition(startX, startY + gap*8)
     .setSize(sliderWidth, sliderHeight)
     .setRange(50, 255)
     .setValue(lineOpacity);
  
  // Action buttons
  cp5.addButton("regenerate")
     .setPosition(startX, startY + gap*9)
     .setSize(buttonWidth, buttonHeight)
     .setCaptionLabel("Regenerate Pattern");
  
  // Lissajous controls
  int lissajousStartY = startY + gap*10;
  
  cp5.addToggle("useLissajous")
     .setPosition(startX, lissajousStartY)
     .setSize(40, 20)
     .setCaptionLabel("Use Lissajous")
     .setValue(useLissajous)
     .onChange(controlEvent -> updateControlVisibility());
  
  cp5.addSlider("freqX")
     .setPosition(startX, lissajousStartY + gap)
     .setSize(sliderWidth, sliderHeight)
     .setRange(1, 10)
     .setValue(freqX);
  
  cp5.addSlider("freqY")
     .setPosition(startX, lissajousStartY + gap*2)
     .setSize(sliderWidth, sliderHeight)
     .setRange(1, 10)
     .setValue(freqY);
  
  cp5.addSlider("phaseShift")
     .setPosition(startX, lissajousStartY + gap*3)
     .setSize(sliderWidth, sliderHeight)
     .setRange(0, 2)
     .setValue(phaseShift / PI);
  
  cp5.addToggle("useLissajousModulation")
     .setPosition(startX, lissajousStartY + gap*4)
     .setSize(40, 20)
     .setCaptionLabel("Amplitude Modulation")
     .setValue(useLissajousModulation);
  
  cp5.addSlider("envelopeFreq")
     .setPosition(startX, lissajousStartY + gap*5)
     .setSize(sliderWidth, sliderHeight)
     .setRange(0.1, 10)
     .setValue(envelopeFreq);
     
  // Fluctuation controls
  int fluctStartY = lissajousStartY + gap*6;
  
  cp5.addToggle("useFluctuation")
     .setPosition(startX, fluctStartY)
     .setSize(40, 20)
     .setCaptionLabel("Use Fluctuation")
     .setValue(useFluctuation)
     .onChange(controlEvent -> {
       cp5.getController("maxFluctuation").setVisible(useFluctuation);
       cp5.getController("fluctuationSpeed").setVisible(useFluctuation);
     });
     
  cp5.addSlider("maxFluctuation")
     .setPosition(startX, fluctStartY + gap)
     .setSize(sliderWidth, sliderHeight)
     .setRange(0, 100)
     .setValue(maxFluctuation)
     .setVisible(useFluctuation);
     
  cp5.addSlider("fluctuationSpeed")
     .setPosition(startX, fluctStartY + gap*2)
     .setSize(sliderWidth, sliderHeight)
     .setRange(0.1, 5)
     .setValue(fluctuationSpeed)
     .setVisible(useFluctuation);
  
  // Do NOT move controls to the right side - keep them on the left

  // Initialize control visibility based on current settings
  try {
    updateControlVisibility();
  } catch (Exception e) {
    println("Warning: Error updating control visibility during initialization. This is not critical.");
    e.printStackTrace();
  }
}

// Function to regenerate the pattern with current parameters
void regeneratePattern() {
  // Generate points with variation in radial length
  angles = new float[numPoints];
  radialLengths = new float[numPoints];
  
  for (int i = 0; i < numPoints; i++) {
    angles[i] = map(i, 0, numPoints, 0, TWO_PI);
    radialLengths[i] = baseRadialLength + random(-radialVariation, radialVariation);
  }
  
  // Initialize baseRandomDistances for interpolation
  baseRandomDistances.clear();
  for (int i = 0; i < numInterpolationPoints; i++) {
    baseRandomDistances.add(random(1, 7));
  }
  
  // Initialize fluctuation offsets if needed
  fluctuationOffsets.clear();
  for (int i = 0; i < numInterpolationPoints; i++) {
    ArrayList<Float> pointOffsets = new ArrayList<Float>();
    pointOffsets.add(random(-1, 1)); // Add one random offset per point
    fluctuationOffsets.add(pointOffsets);
  }
  
  // Generate Lissajous curves if needed
  generateLissajousCurves();
}

// Generate Lissajous curves for all layers
void generateLissajousCurves() {
  lissajousLayers.clear();
  
  for (int layer = 0; layer < lissLayers; layer++) {
    ArrayList<PVector> layerPoints = new ArrayList<PVector>();
    
    // Calculate parameters for this layer
    float currentFreqX = freqX + (layer * lissFreqStep);
    float currentFreqY = freqY + (layer * lissFreqStep);
    float currentPhase = phaseShift + (layer * lissPhaseDelta);
    
    // Create the Lissajous curve for this layer
    for (int i = 0; i < lissPoints; i++) {
      float t = map(i, 0, lissPoints - 1, 0, TWO_PI * lissCycles);
      float x = lissAmpX * sin(currentFreqX * t + currentPhase);
      float y = lissAmpY * sin(currentFreqY * t);
      layerPoints.add(new PVector(x, y));
    }
    
    lissajousLayers.add(layerPoints);
  }
}

// Get a modulated radius based on Lissajous pattern
float getLissajousModulation(float angle, float defaultRadius, int layer) {
  if (!useLissajousModulation || lissajousLayers.isEmpty() || layer >= lissajousLayers.size()) {
    return defaultRadius;
  }
  
  ArrayList<PVector> layerPoints = lissajousLayers.get(layer % lissajousLayers.size());
  if (layerPoints.isEmpty()) return defaultRadius;
  
  // Map the angle to an index in the Lissajous points
  int index = floor(map(angle, 0, TWO_PI, 0, layerPoints.size()));
  index = constrain(index, 0, layerPoints.size() - 1);
  
  // Calculate modulation factor
  PVector point = layerPoints.get(index);
  float modDistance = dist(0, 0, point.x, point.y);
  float normFactor = dist(0, 0, lissAmpX, lissAmpY);
  float modulationFactor = map(modDistance, 0, normFactor, 0.5, 1.5);
  
  return defaultRadius * modulationFactor;
}

// Draw the Lissajous curves directly
void drawLissajousCurves(PGraphics g) {
  // Only draw if enabled
  if (!useLissajous) return;
  
  g.strokeWeight(1);
  
  for (int layer = 0; layer < lissajousLayers.size(); layer++) {
    ArrayList<PVector> points = lissajousLayers.get(layer);
    
    // Set color based on layer
    float hue = map(layer, 0, lissajousLayers.size(), 0, 255);
    g.stroke(hue, 200, 255, 150);
    
    g.beginShape();
    for (PVector p : points) {
      g.vertex(width/2 + p.x, height/2 + p.y);
    }
    g.endShape();
  }
}

// Draw a line with rotation around its center
void drawRotatedLine(PGraphics g, float x1, float y1, float x2, float y2, float rotation) {
  if (rotation == 0) {
    g.line(x1, y1, x2, y2);
    return;
  }
  
  // Find midpoint of line
  float midX = (x1 + x2) / 2;
  float midY = (y1 + y2) / 2;
  
  // Calculate vector from midpoint to endpoint
  float dx = x2 - midX;
  float dy = y2 - midY;
  
  // Calculate length and angle of the vector
  float length = sqrt(dx*dx + dy*dy);
  float angle = atan2(dy, dx);
  
  // Apply rotation
  angle += radians(rotation);
  
  // Calculate new endpoints
  float newX1 = midX - length * cos(angle);
  float newY1 = midY - length * sin(angle);
  float newX2 = midX + length * cos(angle);
  float newY2 = midY + length * sin(angle);
  
  // Draw rotated line
  g.line(newX1, newY1, newX2, newY2);
}

void draw() {
  background(bgColor);
  
  // Start PDF recording if requested
  if (savePDF) {
    beginRecord(PDF, "output/lissajous-" + timestamp() + ".pdf");
    // Ensure directory exists
    File dir = new File(sketchPath("output"));
    dir.mkdir();
  }
  
  // Center the drawing
  pushMatrix();
  translate(width/2, height/2);
  
  // Apply global scale and rotation
  scale(globalScale);
  rotateY(radians(rotationY));
  rotateX(radians(rotationX));
  
  // Set style properties
  strokeWeight(lineWeight);
  noFill();
  
  // Draw multiple cycles with reducing scale
  float currentTotalScale = 1.0;
  int effectiveNumCycles = (int)cycleRepeat;
  
  for (int cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
    float cycleFactor = (float)cycleNum / max(1, effectiveNumCycles - 1);
    float stepScaleFactor = cycleScaleFactor + cycleFactor * cycleScaleOffset;
    
    // Set color with alpha for cycle
    float alpha = lineOpacity * (1.0 - cycleFactor * fadeAmount);
    stroke(red(lineColor), green(lineColor), blue(lineColor), alpha);
    
    pushMatrix();
    scale(currentTotalScale);
    
    // Draw the pattern
    beginShape();
    for (int i = 0; i <= numPoints; i++) {
      // Use modulo to wrap around to the first point to close the shape
      int idx = i % numPoints;
      float angle = angles[idx];
      float radialLengthPixels = radialLengths[idx];
      
      // Get point from the interpolated Lissajous function
      PVector point = getInterpolatedLissajousPoint(angle, radialLengthPixels);
      vertex(point.x, point.y, 0);
    }
    endShape(CLOSE);
    
    popMatrix();
    
    // Update the total scale for the next cycle
    currentTotalScale *= stepScaleFactor;
  }
  
  popMatrix();
  
  // End PDF recording if active
  if (savePDF) {
    endRecord();
    savePDF = false;
    println("PDF saved to output directory!");
  }
  
  // Draw UI
  if (showUI) {
    cp5.draw();
  }
}

void drawGrid() {
  // Draw reference grid lines
  stroke(50);
  strokeWeight(1);
  
  // Draw horizontal and vertical lines
  for (int i = 0; i <= width; i += 50) {
    line(i, 0, i, height);
    line(0, i, width, i);
  }
  
  // Draw center reference
  stroke(100);
  line(width/2, 0, width/2, height);
  line(0, height/2, width, height/2);
}

void keyPressed() {
  // Handle keyboard input
  if (key == 's' || key == 'S') {
    // Save a screenshot
    save("output/InterpolatedLissajous-" + timestamp() + ".png");
    println("Screenshot saved to output directory!");
  } else if (key == 'p' || key == 'P') {
    // Trigger PDF export
    savePDF = true;
  } else if (key == 'r' || key == 'R') {
    // Regenerate pattern
    regeneratePattern();
  } else if (key == 'h' || key == 'H') {
    // Toggle UI visibility
    showUI = !showUI;
  } else if (key == 'l' || key == 'L') {
    // Toggle between Lissajous and interpolated circle
    useLissajous = !useLissajous;
    updateControlVisibility();
  } else if (key == 'm' || key == 'M') {
    // Toggle modulation for Lissajous
    useLissajousModulation = !useLissajousModulation;
    updateControlVisibility();
  }
}

// Button callbacks
void regenerate() {
  regeneratePattern();
}

// Function to get a timestamp string for filenames
String timestamp() {
  return String.format("%d%02d%02d_%02d%02d%02d", 
    year(), month(), day(), hour(), minute(), second());
}

void updateControlVisibility() {
  // Show/hide Lissajous specific controls based on toggle
  boolean showLissajous = useLissajous;
  boolean showModulation = useLissajous && useLissajousModulation;
  
  // Lissajous parameters
  Controller c;
  
  c = cp5.getController("freqX");
  if (c != null) c.setVisible(showLissajous);
  
  c = cp5.getController("freqY");
  if (c != null) c.setVisible(showLissajous);
  
  c = cp5.getController("phaseShift");
  if (c != null) c.setVisible(showLissajous);
  
  c = cp5.getController("useLissajousModulation");
  if (c != null) c.setVisible(showLissajous);
  
  // Modulation parameters
  c = cp5.getController("envelopeFreq");
  if (c != null) c.setVisible(showModulation);
  
  // Hide fluctuation controls when in Lissajous mode
  boolean showFluctuation = !useLissajous && useFluctuation;
  
  c = cp5.getController("maxFluctuation");
  if (c != null) c.setVisible(showFluctuation);
  
  c = cp5.getController("fluctuationSpeed");
  if (c != null) c.setVisible(showFluctuation);
}

// Handle control event callbacks
void controlEvent(ControlEvent event) {
  if (event.isController()) {
    String name = event.getController().getName();
    
    // Update values from UI
    if (name.equals("phaseShift")) {
      phaseShift = event.getController().getValue() * PI;
    }
    else if (name.equals("useFluctuation")) {
      useFluctuation = event.getController().getValue() > 0.5;
      Controller c1 = cp5.getController("maxFluctuation");
      Controller c2 = cp5.getController("fluctuationSpeed");
      if (c1 != null) c1.setVisible(useFluctuation && !useLissajous);
      if (c2 != null) c2.setVisible(useFluctuation && !useLissajous);
    }
    else if (name.equals("useLissajous") || name.equals("useLissajousModulation")) {
      Controller c = cp5.getController("useLissajous");
      if (c != null) useLissajous = c.getValue() > 0.5;
      
      c = cp5.getController("useLissajousModulation");
      if (c != null) useLissajousModulation = c.getValue() > 0.5;
      
      updateControlVisibility();
    }
    else if (name.equals("numInterpolationPoints")) {
      // Regenerate points when the number of interpolation points changes
      numInterpolationPoints = (int)event.getController().getValue();
      regeneratePattern();
    }
  }
}

void drawLissajous(float centerX, float centerY, float radius, float curScale) {
  // Draw a Lissajous curve
  stroke(255);
  noFill();
  
  beginShape();
  for (float t = 0; t < TWO_PI; t += 0.01) {
    float envelope = 1.0;
    if (useLissajousModulation) {
      // Apply amplitude modulation with an envelope curve
      envelope = 0.5 + 0.5 * sin(envelopeFreq * t);
    }
    
    float x = radius * curScale * envelope * sin(freqX * t + phaseShift);
    float y = radius * curScale * envelope * sin(freqY * t);
    
    vertex(centerX + x, centerY + y);
  }
  endShape(CLOSE);
}

void drawInterpolatedPattern(float centerX, float centerY, float curScale) {
  // Draw the interpolated curve based on the generated points
  stroke(255);
  noFill();
  
  beginShape();
  for (float t = 0; t <= TWO_PI; t += 0.01) {
    PVector pos = getInterpolatedPosition(t, curScale);
    vertex(centerX + pos.x, centerY + pos.y);
  }
  endShape(CLOSE);
}

PVector getInterpolatedPosition(float t, float curScale) {
  float x = 0;
  float y = 0;
  
  for (int i = 0; i < numInterpolationPoints; i++) {
    float angle = TWO_PI * i / numInterpolationPoints;
    float pointRadius = baseRadius + baseRandomDistances.get(i % baseRandomDistances.size());
    
    if (useFluctuation) {
      // Add time-based fluctuation
      float fluctOffset = 0;
      if (i < fluctuationOffsets.size() && fluctuationOffsets.get(i).size() > 0) {
        fluctOffset = fluctuationOffsets.get(i).get(0);
      }
      pointRadius += sin(millis() * fluctuationSpeed * 0.001 + fluctOffset) * maxFluctuation;
    }
    
    pointRadius *= curScale;  // Apply scaling factor
    
    x += pointRadius * cos(angle) * cos(t - angle);
    y += pointRadius * sin(angle) * cos(t - angle);
  }
  
  return new PVector(x, y);
}

void oscEvent(float time, float value) {
  // This would respond to music or other OSC events if implemented
}

PVector getInterpolatedLissajousPoint(float t, float radialLength) {
  float x, y;
  
  if (useLissajous) {
    // Apply phase shift to x component
    float modFactor = 1.0;
    
    // Apply amplitude modulation if enabled
    if (useLissajousModulation) {
      modFactor = 0.5 + 0.5 * sin(t * envelopeFreq);
    }
    
    // Calculate Lissajous curve point with appropriate scaling
    x = modFactor * sin(t * freqX + phaseShift) * radialLength * 0.5;
    y = modFactor * sin(t * freqY) * radialLength * 0.5;
  } else {
    // Standard circle/ellipse point
    x = cos(t) * radialLength * 0.5;
    y = sin(t) * radialLength * 0.5;
    
    // Apply fluctuation if enabled
    if (useFluctuation) {
      float fluctuation = maxFluctuation * sin(t * fluctuationFreq + millis() * 0.001 * fluctuationSpeed);
      x += fluctuation;
      y += fluctuation;
    }
  }
  
  return new PVector(x, y);
}
