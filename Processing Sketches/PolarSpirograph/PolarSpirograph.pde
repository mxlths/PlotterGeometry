import controlP5.*;
import processing.svg.*;
import javax.swing.JOptionPane;
import java.io.File;
import java.util.ArrayList;

ControlP5 cp5;
PFont labelFont;

// --- Spirograph Parameters ---
// Equation: r = scaleFactor * (effectiveBaseR + A1*sin(f1*theta + p1) + A2*sin(f2*theta + p2) + A3*sin(f3*theta + p3))
// where effectiveBaseR = minGapRadius + abs(A1) + abs(A2) + abs(A3)

float scaleFactor = 100.0;  // Overall size scaling
float minGapRadius = 0.1;   // Minimum radius before scaling, ensuring a hole
// float baseR = 1.0;     // REMOVED - replaced by minGapRadius calculation

// Sine Term 1
float A1 = 1.0;  // Amplitude
float f1 = 5.0;  // Frequency (relative to theta)
float p1Deg = 0.0; // Phase (degrees)

// Sine Term 2
float A2 = 1.0;  // Amplitude
float f2 = 12.0; // Frequency
float p2Deg = 90.0; // Phase (degrees)

// Sine Term 3 (NEW)
float A3 = 0.0;  // Amplitude (default 0 to not affect initial state)
float f3 = 19.0; // Frequency
float p3Deg = 45.0; // Phase (degrees)

// Z Modulation Parameters (NEW)
float Az = 0.0; // Amplitude (default 0 for 2D compatibility)
float fz = 1.0; // Frequency
float pzDeg = 0.0; // Phase (degrees)

// Drawing Parameters
float thetaMaxCycles = 10.0; // How many full 2*PI cycles for theta
int numPoints = 2000;     // Resolution of the curve
float lineWidth = 1.0;
int numRepetitions = 1;   // Number of times to repeat the pattern radially

// Spiral Repetition Parameters (NEW)
boolean useSpiralRepetition = false;
float spiralTotalDegrees = 360.0;
float spiralAmplitude = 1.0; // Factor controlling radial spread relative to scaleFactor

// 3D View Parameters (NEW)
boolean enable3DView = false;
float rotX = 0;
float rotY = 0;
float zoom = 1.0;
float transX = 0;
float transY = 0;
int lastMouseX = 0;
int lastMouseY = 0;

// --- Data Structures ---
ArrayList<PVector> pathPoints; // Stores Cartesian points of the path
boolean needsRegen = true;

// --- SVG Export ---
boolean recordSVG = false;
String svgOutputPath = null;

// Multi-view SVG Export State Variables
boolean doingMultiViewExport = false;
String multiViewSvgPath = null;
int currentViewIndex = 0;
PGraphicsSVG multiViewSvg = null;
int viewWidth, viewHeight;
float[] savedViewState = new float[4]; // rotX, rotY, transX, transY
float[][] viewConfigs = {
  // rotX, rotY, position (gridX, gridY)
  {0, 0, 1, 1},                 // Current view (center)
  {0, 0, 1, 0},                 // Front (top-center)
  {0, PI, 1, 2},                // Back (bottom-center)
  {0, -HALF_PI, 0, 1},          // Left (center-left)
  {0, HALF_PI, 2, 1},           // Right (center-right)
  {-HALF_PI, 0, 0, 0},          // Top (top-left)
  {HALF_PI, 0, 2, 0},           // Bottom (top-right)
  {HALF_PI, PI, 0, 2},          // Bottom-Back (bottom-left) 
  {-HALF_PI, PI, 2, 2}          // Top-Back (bottom-right)
};
String[] viewLabels = {
  "Current View", "Front", "Back", "Left", "Right", "Top", "Bottom", "Bottom-Back", "Top-Back"
};

// --- Setup & UI ---
void setup() {
  size(1000, 1000, P3D); // Use P3D renderer
  labelFont = createFont("Arial", 12, true);
  cp5 = new ControlP5(this);
  pathPoints = new ArrayList<PVector>();

  int inputX = 150;
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 28;
  int currentY = inputY;
  int labelW = 130;

  cp5.addLabel("Scale Factor:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("scaleFactor").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(scaleFactor, 1, 1));

  currentY += spacing;
  cp5.addLabel("Min Gap Radius:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("minGapRadius").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(minGapRadius, 1, 2));

  // Term 1
  currentY += spacing;
  cp5.addLabel("Amplitude 1 (A1):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("A1").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(A1, 1, 2));

  currentY += spacing;
  cp5.addLabel("Frequency 1 (f1):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("f1").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(f1, 1, 2));

  currentY += spacing;
  cp5.addLabel("Phase 1 (deg):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("p1Deg").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(p1Deg, 1, 1));

  // Term 2
  currentY += spacing;
  cp5.addLabel("Amplitude 2 (A2):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("A2").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(A2, 1, 2));

  currentY += spacing;
  cp5.addLabel("Frequency 2 (f2):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("f2").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(f2, 1, 2));

  currentY += spacing;
  cp5.addLabel("Phase 2 (deg):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("p2Deg").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(p2Deg, 1, 1));

  // Term 3 (NEW)
  currentY += spacing;
  cp5.addLabel("Amplitude 3 (A3):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("A3").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(A3, 1, 2));

  currentY += spacing;
  cp5.addLabel("Frequency 3 (f3):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("f3").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(f3, 1, 2));

  currentY += spacing;
  cp5.addLabel("Phase 3 (deg):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("p3Deg").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(p3Deg, 1, 1));

  // Z Modulation Params (NEW)
  currentY += spacing;
  cp5.addLabel("Amplitude Z (Az):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("Az").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(Az, 1, 2));

  currentY += spacing;
  cp5.addLabel("Frequency Z (fz):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("fz").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(fz, 1, 2));

  currentY += spacing;
  cp5.addLabel("Phase Z (deg):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("pzDeg").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(pzDeg, 1, 1));

  // Drawing Params
  currentY += spacing;
  cp5.addLabel("Theta Cycles:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("thetaMaxCycles").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(thetaMaxCycles, 1, 1));

  currentY += spacing;
  cp5.addLabel("Num Points:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("numPoints").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+numPoints);

  currentY += spacing;
  cp5.addLabel("Line Width:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("lineWidth").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lineWidth, 1, 2));

  // Repetitions (NEW)
  currentY += spacing;
  cp5.addLabel("Repetitions:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("numRepetitions").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+numRepetitions);

  // Spiral Repetition Controls (NEW)
  currentY += spacing;
  cp5.addToggle("useSpiralRepetition")
     .setLabel("Use Spiral Repetition")
     .setPosition(10, currentY)
     .setSize(inputW+labelW+10, inputH) // Wider toggle
     .setValue(useSpiralRepetition)
     .setMode(ControlP5.SWITCH);

  currentY += spacing;
  cp5.addLabel("Spiral Total Deg:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("spiralTotalDegrees").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(spiralTotalDegrees, 1, 1));

  currentY += spacing;
  cp5.addLabel("Spiral Amplitude:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("spiralAmplitude").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(spiralAmplitude, 1, 2));

  // 3D View Toggle (NEW)
  currentY += spacing;
  cp5.addToggle("enable3DView")
     .setLabel("Enable 3D View")
     .setPosition(10, currentY)
     .setSize(inputW+labelW+10, inputH)
     .setValue(enable3DView)
     .setMode(ControlP5.SWITCH);

  // Buttons
  currentY += spacing + 10;
  cp5.addButton("regeneratePatternButton").setLabel("Regenerate").setPosition(10, currentY).setSize(100, inputH+5);
  cp5.addButton("exportSVG").setLabel("Export SVG").setPosition(120, currentY).setSize(100, inputH+5);
  cp5.addButton("exportMultiViewSVG").setLabel("Export Grid View").setPosition(230, currentY).setSize(110, inputH+5);
}

// --- Path Generation ---
void regeneratePattern() {
  println("Generating Spirograph path...");
  pathPoints = new ArrayList<PVector>();
  numPoints = max(10, numPoints); // Ensure reasonable minimum points
  
  float p1Rad = radians(p1Deg);
  float p2Rad = radians(p2Deg);
  float p3Rad = radians(p3Deg); // Convert new phase to radians
  float pzRad = radians(pzDeg); // Convert Z phase to radians (NEW)
  float thetaMax = TWO_PI * thetaMaxCycles;
  
  // Calculate the effective base radius to ensure the minimum gap
  float effectiveBaseR = max(0, minGapRadius) + abs(A1) + abs(A2) + abs(A3);
  println("DEBUG: Effective Base R = " + effectiveBaseR + " (MinGap=" + minGapRadius + ", |A1|="+abs(A1)+", |A2|="+abs(A2)+", |A3|="+abs(A3)+")");

  for (int i = 0; i <= numPoints; i++) {
    float theta = map(i, 0, numPoints, 0, thetaMax);
    
    // Calculate radius based on the formula using effectiveBaseR and term 3
    float r = effectiveBaseR + 
              A1 * sin(f1 * theta + p1Rad) + 
              A2 * sin(f2 * theta + p2Rad) + 
              A3 * sin(f3 * theta + p3Rad); // Added term 3
              
    r *= scaleFactor; // Apply overall scaling
    
    // Convert polar (r, theta) to Cartesian (x, y)
    float x = r * cos(theta);
    float y = r * sin(theta);
    
    // Calculate Z coordinate (NEW)
    float z = Az * sin(fz * theta + pzRad);
    z *= scaleFactor; // Apply scaling consistent with x, y

    pathPoints.add(new PVector(x, y, z)); // Store 3D points
  }
  
  needsRegen = false;
  println("Path generated with " + pathPoints.size() + " points.");
}

// --- Drawing Loop ---
void draw() {
  if (recordSVG) {
    exportToSVG();
    recordSVG = false;
  }

  // Handle multi-view export
  if (doingMultiViewExport) {
    handleMultiViewExport();
    return; // Skip regular drawing during export
  }

  if (needsRegen) {
    regeneratePattern();
  }

  background(255); // White background

  if (enable3DView) {
    // Apply 3D camera transformations
    translate(width / 2 + transX, height / 2 + transY); // Apply translation first
    rotateX(rotX);
    rotateY(rotY);
    scale(zoom);
  } else {
    // Original 2D centering
    translate(width / 2, height / 2);
  }

  // Draw the generated path
  if (pathPoints != null && pathPoints.size() > 1) {
    stroke(0);
    strokeWeight(lineWidth);
    noFill();
    for (int i = 0; i < numRepetitions; i++) {
      pushMatrix(); // Save current transformation state
      if (useSpiralRepetition && numRepetitions > 1) {
        // Spiral placement
        float spiralAngle = map(i, 0, numRepetitions, 0, radians(spiralTotalDegrees));
        float spiralRadius = map(i, 0, numRepetitions, 0, spiralAmplitude * scaleFactor);
        float tx = spiralRadius * cos(spiralAngle);
        float ty = spiralRadius * sin(spiralAngle);
        translate(tx, ty); // Apply translation for this repetition
      } else if (numRepetitions > 1) {
        // Circular placement (original rotation)
        rotate(TWO_PI / numRepetitions * i); // Apply rotation for this repetition
      } // else: numRepetitions is 1, no transform needed

      beginShape();
      for (PVector p : pathPoints) {
        if (enable3DView) {
          vertex(p.x, p.y, p.z); // Use 3D vertices
        } else {
          vertex(p.x, p.y);      // Use 2D vertices
        }
      }
      endShape();
      popMatrix(); // Restore previous transformation state
    }
  }
  
  // Draw GUI - Reset matrix first to draw in screen space
  hint(DISABLE_DEPTH_TEST);
  camera(); // Resets camera to default for screen-space drawing
  noLights(); // Ensure GUI isn't affected by 3D lighting
  cp5.draw();
  hint(ENABLE_DEPTH_TEST);
}

// New function to handle multi-view export state machine
void handleMultiViewExport() {
  if (currentViewIndex == 0) {
    // Starting the multi-view export
    println("Starting multi-view SVG export process...");
    
    // Save current view state
    savedViewState[0] = rotX;
    savedViewState[1] = rotY;
    savedViewState[2] = transX;
    savedViewState[3] = transY;
    
    // Update the first view config (center position) to use current view
    viewConfigs[0][0] = savedViewState[0]; // rotX
    viewConfigs[0][1] = savedViewState[1]; // rotY
    
    // Initialize drawing area
    int gridWidth = 3;
    int gridHeight = 3;
    viewWidth = width / gridWidth;
    viewHeight = height / gridHeight;
    int svgWidth = viewWidth * gridWidth;
    int svgHeight = viewHeight * gridHeight;
    
    // Create the SVG
    multiViewSvg = (PGraphicsSVG) createGraphics(svgWidth, svgHeight, SVG, multiViewSvgPath);
    multiViewSvg.beginDraw();
    multiViewSvg.background(255);
    
    // Force 3D mode for rendering
    if (!enable3DView) {
      enable3DView = true;
      if (cp5 != null) ((Toggle)cp5.getController("enable3DView")).setValue(true);
    }
    
    currentViewIndex++; // Move to first view
  } 
  else if (currentViewIndex <= viewConfigs.length) {
    // Process current view
    int viewIdx = currentViewIndex - 1;
    println("Processing view " + viewIdx + ": " + viewLabels[viewIdx]);
    
    // Set view parameters for this view
    rotX = viewConfigs[viewIdx][0];
    rotY = viewConfigs[viewIdx][1];
    
    // Position in the grid
    int gridX = (int)viewConfigs[viewIdx][2];
    int gridY = (int)viewConfigs[viewIdx][3];
    int posX = gridX * viewWidth;
    int posY = gridY * viewHeight;
    
    // Draw this view to the screen first
    background(255);
    translate(width / 2, height / 2);
    rotateX(rotX);
    rotateY(rotY);
    scale(zoom);
    
    // Draw the generated path
    if (pathPoints != null && pathPoints.size() > 1) {
      stroke(0);
      strokeWeight(lineWidth);
      noFill();
      for (int i = 0; i < numRepetitions; i++) {
        pushMatrix(); // Save current transformation state
        if (useSpiralRepetition && numRepetitions > 1) {
          // Spiral placement
          float spiralAngle = map(i, 0, numRepetitions, 0, radians(spiralTotalDegrees));
          float spiralRadius = map(i, 0, numRepetitions, 0, spiralAmplitude * scaleFactor);
          float tx = spiralRadius * cos(spiralAngle);
          float ty = spiralRadius * sin(spiralAngle);
          translate(tx, ty); // Apply translation for this repetition
        } else if (numRepetitions > 1) {
          // Circular placement (original rotation)
          rotate(TWO_PI / numRepetitions * i); // Apply rotation for this repetition
        } // else: numRepetitions is 1, no transform needed

        beginShape();
        for (PVector p : pathPoints) {
          if (enable3DView) {
            vertex(p.x, p.y, p.z); // Use 3D vertices
          } else {
            vertex(p.x, p.y);      // Use 2D vertices
          }
        }
        endShape();
        popMatrix(); // Restore previous transformation state
      }
    }
    
    // Now capture it for the SVG
    multiViewSvg.pushMatrix();
    multiViewSvg.translate(posX, posY);
    
    // Draw frame and label
    multiViewSvg.stroke(200);
    multiViewSvg.strokeWeight(1);
    multiViewSvg.noFill();
    multiViewSvg.rect(0, 0, viewWidth, viewHeight);
    
    multiViewSvg.fill(0);
    multiViewSvg.textSize(12);
    multiViewSvg.text(viewLabels[viewIdx], 10, 20);
    
    // Create a temporary PGraphics to calculate screen coordinates
    PGraphics pg = createGraphics(viewWidth, viewHeight, P3D);
    pg.beginDraw();
    pg.translate(viewWidth / 2, viewHeight / 2);
    pg.rotateX(rotX);
    pg.rotateY(rotY);
    pg.scale(zoom);
    
    // Transform the coordinates of all our points for all repetitions
    ArrayList<ArrayList<PVector>> screenPointSets = new ArrayList<ArrayList<PVector>>();
    
    for (int i = 0; i < numRepetitions; i++) {
      pg.pushMatrix();
      
      if (useSpiralRepetition && numRepetitions > 1) {
        float spiralAngle = map(i, 0, numRepetitions, 0, radians(spiralTotalDegrees));
        float spiralRadius = map(i, 0, numRepetitions, 0, spiralAmplitude * scaleFactor);
        float tx = spiralRadius * cos(spiralAngle);
        float ty = spiralRadius * sin(spiralAngle);
        pg.translate(tx, ty);
      } else if (numRepetitions > 1) {
        pg.rotate(TWO_PI / numRepetitions * i);
      }
      
      // Transform each point and store in a new list
      ArrayList<PVector> screenPoints = new ArrayList<PVector>();
      for (PVector p : pathPoints) {
        // Calculate screen coordinates (project 3D to 2D)
        float sx = pg.modelX(p.x, p.y, p.z);
        float sy = pg.modelY(p.x, p.y, p.z);
        // Scale to fit the cell
        sx = map(sx, 0, width, 0, viewWidth);
        sy = map(sy, 0, height, 0, viewHeight);
        screenPoints.add(new PVector(sx, sy));
      }
      screenPointSets.add(screenPoints);
      
      pg.popMatrix();
    }
    pg.endDraw();
    pg.dispose();
    
    // Draw the projected paths to the SVG
    multiViewSvg.stroke(0);
    multiViewSvg.strokeWeight(lineWidth);
    multiViewSvg.noFill();
    
    for (ArrayList<PVector> pointSet : screenPointSets) {
      multiViewSvg.beginShape();
      for (PVector p : pointSet) {
        multiViewSvg.vertex(p.x, p.y);
      }
      multiViewSvg.endShape();
    }
    
    multiViewSvg.popMatrix();
    
    currentViewIndex++;
  } 
  else {
    // Finalize export
    println("Finalizing multi-view SVG export...");
    
    // Restore original view settings
    rotX = savedViewState[0];
    rotY = savedViewState[1];
    transX = savedViewState[2];
    transY = savedViewState[3];
    
    multiViewSvg.endDraw();
    multiViewSvg.dispose();
    
    println("Multi-view SVG saved to: " + multiViewSvgPath);
    
    File outputFile = new File(multiViewSvgPath);
    if (outputFile.exists() && outputFile.length() > 0) {
      JOptionPane.showMessageDialog(null, "Multi-view SVG exported successfully to:\n" + multiViewSvgPath, 
          "Multi-view SVG Export", JOptionPane.INFORMATION_MESSAGE);
    } else {
      JOptionPane.showMessageDialog(null, "Error: Multi-view SVG file was not created or is empty.\nCheck console output.", 
          "Multi-view SVG Export Error", JOptionPane.ERROR_MESSAGE);
    }
    
    // Reset state
    doingMultiViewExport = false;
    multiViewSvgPath = null;
    currentViewIndex = 0;
    multiViewSvg = null;
    System.gc();
  }
}

// --- SVG Export Logic ---
void exportToSVG() {
   if (needsRegen) {
      println("Regenerating before export...");
      regeneratePattern();
   }
   if (svgOutputPath == null) {
    selectOutput("Save SVG as...", "svgFileSelected",
      new File(sketchPath(""), "Spirograph_" + getTimestamp() + ".svg"), this);
    return; // Wait for file selection
  }

  println("Creating SVG...");
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);

  svg.beginDraw();
  svg.background(255);
  
  if (enable3DView) {
    // For 3D export: we need to manually transform all points to their screen positions
    println("SVG Export: 3D mode - projecting points to 2D");
    
    // Create a temporary PGraphics to calculate screen coordinates
    PGraphics pg = createGraphics(width, height, P3D);
    pg.beginDraw();
    pg.translate(width / 2 + transX, height / 2 + transY);
    pg.rotateX(rotX);
    pg.rotateY(rotY);
    pg.scale(zoom);
    
    // Transform the coordinates of all our points for all repetitions
    // and store in a temporary list of PVector arrays
    ArrayList<ArrayList<PVector>> screenPointSets = new ArrayList<ArrayList<PVector>>();
    
    for (int i = 0; i < numRepetitions; i++) {
      pg.pushMatrix();
      
      if (useSpiralRepetition && numRepetitions > 1) {
        float spiralAngle = map(i, 0, numRepetitions, 0, radians(spiralTotalDegrees));
        float spiralRadius = map(i, 0, numRepetitions, 0, spiralAmplitude * scaleFactor);
        float tx = spiralRadius * cos(spiralAngle);
        float ty = spiralRadius * sin(spiralAngle);
        pg.translate(tx, ty);
      } else if (numRepetitions > 1) {
        pg.rotate(TWO_PI / numRepetitions * i);
      }
      
      // Transform each point and store in a new list
      ArrayList<PVector> screenPoints = new ArrayList<PVector>();
      for (PVector p : pathPoints) {
        // Calculate screen coordinates (project 3D to 2D)
        float sx = pg.modelX(p.x, p.y, p.z);
        float sy = pg.modelY(p.x, p.y, p.z);
        screenPoints.add(new PVector(sx, sy));
      }
      screenPointSets.add(screenPoints);
      
      pg.popMatrix();
    }
    pg.endDraw();
    pg.dispose();
    
    // Now draw the projected 2D paths to the SVG
    svg.stroke(0);
    svg.strokeWeight(lineWidth);
    svg.noFill();
    
    for (ArrayList<PVector> pointSet : screenPointSets) {
      svg.beginShape();
      for (PVector p : pointSet) {
        svg.vertex(p.x, p.y); // Draw projected 2D points
      }
      svg.endShape();
    }
  } else {
    // 2D Export mode - original approach
    println("SVG Export: 2D mode");
    svg.translate(width / 2, height / 2);
    svg.stroke(0);
    svg.strokeWeight(lineWidth);
    svg.noFill();
    
    // Draw the path repetitions to SVG
    if (pathPoints != null && pathPoints.size() > 1) {
      for (int i = 0; i < numRepetitions; i++) {
        svg.pushMatrix();
        if (useSpiralRepetition && numRepetitions > 1) {
          float spiralAngle = map(i, 0, numRepetitions, 0, radians(spiralTotalDegrees));
          float spiralRadius = map(i, 0, numRepetitions, 0, spiralAmplitude * scaleFactor);
          float tx = spiralRadius * cos(spiralAngle);
          float ty = spiralRadius * sin(spiralAngle);
          svg.translate(tx, ty);
        } else if (numRepetitions > 1) {
          svg.rotate(TWO_PI / numRepetitions * i);
        }
        
        svg.beginShape();
        for (PVector p : pathPoints) {
          svg.vertex(p.x, p.y); // 2D vertex
        }
        svg.endShape();
        svg.popMatrix();
      }
    }
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
public void scaleFactor(String val) { try { scaleFactor = max(0.1, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("scaleFactor")).setValue(nf(scaleFactor,1,1));} }
public void minGapRadius(String val) { try { minGapRadius = max(0, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("minGapRadius")).setValue(nf(minGapRadius,1,2));} }
public void A1(String val) { try { A1 = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("A1")).setValue(nf(A1,1,2));} }
public void f1(String val) { try { f1 = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("f1")).setValue(nf(f1,1,2));} }
public void p1Deg(String val) { try { p1Deg = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("p1Deg")).setValue(nf(p1Deg,1,1));} }
public void A2(String val) { try { A2 = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("A2")).setValue(nf(A2,1,2));} }
public void f2(String val) { try { f2 = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("f2")).setValue(nf(f2,1,2));} }
public void p2Deg(String val) { try { p2Deg = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("p2Deg")).setValue(nf(p2Deg,1,1));} }
public void A3(String val) { try { A3 = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("A3")).setValue(nf(A3,1,2));} }
public void f3(String val) { try { f3 = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("f3")).setValue(nf(f3,1,2));} }
public void p3Deg(String val) { try { p3Deg = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("p3Deg")).setValue(nf(p3Deg,1,1));} }
public void thetaMaxCycles(String val) { try { thetaMaxCycles = max(0.1, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("thetaMaxCycles")).setValue(nf(thetaMaxCycles,1,1));} }
public void numPoints(String val) { try { numPoints = max(10, Integer.parseInt(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("numPoints")).setValue(""+numPoints);} }
public void lineWidth(String val) { try { lineWidth = max(0.1, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("lineWidth")).setValue(nf(lineWidth,1,2));} } // Line width change needs regen
public void numRepetitions(String val) { try { numRepetitions = max(1, Integer.parseInt(val)); } catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("numRepetitions")).setValue(""+numRepetitions);} } // Repetition change doesn't need path regen

// Spiral Handlers (NEW)
public void useSpiralRepetition(boolean val) { useSpiralRepetition = val; } // No regen needed
public void spiralTotalDegrees(String val) { try { spiralTotalDegrees = Float.parseFloat(val); } catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("spiralTotalDegrees")).setValue(nf(spiralTotalDegrees,1,1));} } // No regen needed
public void spiralAmplitude(String val) { try { spiralAmplitude = Float.parseFloat(val); } catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("spiralAmplitude")).setValue(nf(spiralAmplitude,1,2));} } // No regen needed

// Z Handlers (NEW)
public void Az(String val) { try { Az = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("Az")).setValue(nf(Az,1,2));} }
public void fz(String val) { try { fz = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("fz")).setValue(nf(fz,1,2));} }
public void pzDeg(String val) { try { pzDeg = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("pzDeg")).setValue(nf(pzDeg,1,1));} }

// 3D View Handler (NEW)
public void enable3DView(boolean val) { enable3DView = val; } // No regen needed

// --- Button Handlers & Helpers ---
public void regeneratePatternButton(int theValue) { needsRegen = true; }

// Export SVG handler
public void exportSVG(int theValue) { // Button handler
  if (needsRegen) {
      println("Regenerating before export...");
      regeneratePattern();
  }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "Spirograph_" + getTimestamp() + ".svg"), this);
}

// Multi-view SVG export handler
public void exportMultiViewSVG(int theValue) {
  println("Multi-view SVG export requested");
  if (recordSVG || doingMultiViewExport) { 
    println("Export already in progress."); 
    return; 
  }
  if (needsRegen) {
    println("Regenerating before export...");
    regeneratePattern();
  }
  selectOutput("Save multi-view SVG as...", "multiViewSvgFileSelected", 
    new File(sketchPath(""), "Spirograph_MultiView_" + getTimestamp() + ".svg"), this);
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

void multiViewSvgFileSelected(File selection) {
  if (selection == null) { 
    println("Multi-view SVG export cancelled."); 
    return; 
  }
  
  multiViewSvgPath = selection.getAbsolutePath();
  println("Selected multi-view SVG path: " + multiViewSvgPath);
  
  // Delete existing file if it exists
  File outputFile = new File(multiViewSvgPath);
  if (outputFile.exists()) {
    println("File already exists, deleting: " + multiViewSvgPath);
    if (!outputFile.delete()) {
      println("Warning: Could not delete existing file. SVG export might fail or overwrite.");
    }
  }
  
  // Start the export process - will be handled in draw()
  doingMultiViewExport = true;
  currentViewIndex = 0;
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

// --- Mouse Interaction for 3D View (NEW) ---
void mousePressed() {
  if (enable3DView) {
    // Record initial mouse position only if over the sketch window and not over a GUI element
    if (mouseX >= 0 && mouseX <= width && mouseY >= 0 && mouseY <= height && !cp5.isMouseOver()) {
       lastMouseX = mouseX;
       lastMouseY = mouseY;
    }
  }
}

void mouseDragged() {
  if (enable3DView && !cp5.isMouseOver()) {
     int dx = mouseX - lastMouseX;
     int dy = mouseY - lastMouseY;

     if (mouseButton == LEFT) { // Rotation
       rotY += dx * 0.01; // Adjust sensitivity as needed
       rotX -= dy * 0.01;
     } else if (mouseButton == RIGHT) { // Translation (Pan)
       transX += dx;
       transY += dy;
     }
     lastMouseX = mouseX;
     lastMouseY = mouseY;
  }
}

// Use processing.event.MouseEvent for wheel details
import processing.event.MouseEvent;

void mouseWheel(MouseEvent event) {
  if (enable3DView && !cp5.isMouseOver()) {
    float count = event.getCount();
    zoom *= pow(0.95, count); // Adjust zoom sensitivity
    zoom = max(0.1, zoom); // Prevent zooming too far in/out
  }
} 