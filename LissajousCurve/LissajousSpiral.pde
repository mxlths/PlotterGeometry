import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class
import processing.event.MouseEvent; // For mouse wheel event

ControlP5 cp5;
PFont labelFont; // Font for the labels

// Lissajous Curve Parameters
float A = 200; // Amplitude X
float B = 200; // Amplitude Y
float a = 3;   // Frequency X
float b = 4;   // Frequency Y
float deltaDegrees = 90; // Phase shift in degrees

// Z Modulation Parameters (NEW)
float Az = 0.0; // Amplitude Z (default 0 for 2D compatibility)
float fz = 1.0; // Frequency Z
float pzDeg = 0.0; // Phase Z (degrees)

// 3D View Parameters (NEW)
boolean enable3DView = false;
float rotX = 0;
float rotY = 0;
float zoom = 1.0;
float transX = 0;
float transY = 0;
int lastMouseX = 0;
int lastMouseY = 0;

// Drawing Parameters
float scaleFactor = 1.0;
int numPoints = 1000;
float lineWidth = 1.0;
float tCycles = 1.0; // How many full 2*PI cycles for t

// Repetition Parameters
int numDuplicates = 10;          // Number of curves to draw
float rotationStepDegrees = 5.0; // Degrees to rotate between each duplicate
float baseRotationDegrees = 0.0; // Initial rotation for the first curve

// Spiral Repetition Parameters (NEW)
boolean useSpiralRepetition = false;
float spiralTotalDegrees = 360.0;
float spiralAmplitude = 1.0; // Factor controlling radial spread

// Wave Modulation Parameters
float waveDepth = 0.0; // Amplitude of the wave offset (pixels)
float waveFreq = 5.0;  // Frequency of the wave along the curve (cycles per 2*PI of t)

// Perpendicular Line Mode Parameters
int drawMode = 0; // 0 = Curve, 1 = Perpendicular Lines
int lineDensity = 500; // Number of perpendicular lines to draw
float perpLineLength = 10.0; // Length of each perpendicular line (pixels)

// Offset Cycle Parameters
int offsetCycleCount = 20;      // Steps per shrink/grow cycle
int numberOfOffsetCycles = 1;   // Number of times to repeat the cycle
float initialScaleOffset = 1.1; // Initial relative size factor (e.g., 1.1 = 10% larger)
float scaleDecay = 0.95;      // Decay factor for scaling per step

// SVG Export
boolean recordSVG = false; // Flag to trigger SVG export
String svgOutputPath = null; // Path for SVG output

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

void setup() {
  size(2036, 1440, P3D); // Set canvas size with P3D renderer
  
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
  int labelW = 130;
  
  // Amplitude X (A)
  cp5.addLabel("Amplitude X (A):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("A")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(A, 1, 1));

  // Amplitude Y (B)
  currentY += spacing;
  cp5.addLabel("Amplitude Y (B):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("B")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(B, 1, 1));

  // Frequency X (a)
  currentY += spacing;
  cp5.addLabel("Frequency X (a):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("a")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(a, 1, 1));
     
  // Frequency Y (b)
  currentY += spacing;
  cp5.addLabel("Frequency Y (b):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("b")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(b, 1, 1));

  // Phase Shift (delta)
  currentY += spacing;
  cp5.addLabel("Phase Shift (deg):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("deltaDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(deltaDegrees, 1, 1));
     
  // NEW: Z Modulation Parameters
  currentY += spacing;
  cp5.addLabel("Amplitude Z (Az):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("Az")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(Az, 1, 2));

  currentY += spacing;
  cp5.addLabel("Frequency Z (fz):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("fz")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(fz, 1, 2));

  currentY += spacing;
  cp5.addLabel("Phase Z (deg):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("pzDeg")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(pzDeg, 1, 1));

  // Scale Factor
  currentY += spacing;
  cp5.addLabel("Scale Factor:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("scaleFactor")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(scaleFactor, 1, 2));

  // Number of Points
  currentY += spacing;
  cp5.addLabel("Points (Resolution):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("numPoints")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numPoints);

  // Line Width
  currentY += spacing;
  cp5.addLabel("Line Width:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("lineWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(lineWidth, 1, 1));
     
  // Number of Duplicates
  currentY += spacing;
  cp5.addLabel("Duplicates:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("numDuplicates")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numDuplicates);
      
  // Base Rotation
  currentY += spacing;
  cp5.addLabel("Base Rotation (deg):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("baseRotationDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(baseRotationDegrees, 1, 1));
      
  // Rotation Step
  currentY += spacing;
  cp5.addLabel("Rotation Step (deg):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("rotationStepDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(rotationStepDegrees, 1, 1));
     
  // NEW: Spiral Repetition Controls
  currentY += spacing;
  cp5.addToggle("useSpiralRepetition")
     .setLabel("Use Spiral Repetition")
     .setPosition(10, currentY)
     .setSize(inputW+labelW+10, inputH)
     .setValue(useSpiralRepetition)
     .setMode(ControlP5.SWITCH);

  currentY += spacing;
  cp5.addLabel("Spiral Total Deg:")
     .setPosition(10, currentY+4).setSize(labelW, inputH)
     .setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("spiralTotalDegrees")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(spiralTotalDegrees, 1, 1));

  currentY += spacing;
  cp5.addLabel("Spiral Amplitude:")
     .setPosition(10, currentY+4).setSize(labelW, inputH)
     .setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("spiralAmplitude")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(spiralAmplitude, 1, 2));
      
  // T Cycles
  currentY += spacing;
  cp5.addLabel("T Cycles (x 2*PI):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("tCycles")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(tCycles, 1, 2));

  // Wave Depth
  currentY += spacing;
  cp5.addLabel("Wave Depth (px):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("waveDepth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(waveDepth, 1, 1));
      
  // Wave Frequency
  currentY += spacing;
  cp5.addLabel("Wave Freq:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("waveFreq")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(waveFreq, 1, 1));

  // Draw Mode
  currentY += spacing;
  cp5.addLabel("Draw Mode (0/1):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("drawMode")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+drawMode);
      
  // Line Density
  currentY += spacing;
  cp5.addLabel("Line Density:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("lineDensity")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+lineDensity);

  // Perpendicular Line Length
  currentY += spacing;
  cp5.addLabel("Perp Line Len:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("perpLineLength")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(perpLineLength, 1, 1));

  // Offset Cycle Count
  currentY += spacing;
  cp5.addLabel("Offset Cycle Count:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("offsetCycleCount")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+offsetCycleCount);
     
  // Number of Offset Cycles
  currentY += spacing;
  cp5.addLabel("Num Offset Cycles:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("numberOfOffsetCycles")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numberOfOffsetCycles);
     
  // Initial Scale Offset
  currentY += spacing;
  cp5.addLabel("Initial Scale Off:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("initialScaleOffset")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(initialScaleOffset, 1, 2));
     
  // Scale Decay
  currentY += spacing;
  cp5.addLabel("Scale Decay:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("scaleDecay")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(scaleDecay, 1, 2));
     
  // NEW: 3D View Toggle
  currentY += spacing;
  cp5.addToggle("enable3DView")
     .setLabel("Enable 3D View")
     .setPosition(10, currentY)
     .setSize(inputW+labelW+10, inputH)
     .setValue(enable3DView)
     .setMode(ControlP5.SWITCH);

  // NEW: View Cube Faces Buttons
  currentY += spacing + 5;
  int viewBtnW = 40;
  int viewBtnH = 20;
  int viewBtnSpacing = 5;
  
  cp5.addButton("viewFront")
     .setLabel("Front")
     .setPosition(10, currentY)
     .setSize(viewBtnW, viewBtnH);
     
  cp5.addButton("viewBack")
     .setLabel("Back")
     .setPosition(10 + viewBtnW + viewBtnSpacing, currentY)
     .setSize(viewBtnW, viewBtnH);
     
  cp5.addButton("viewLeft")
     .setLabel("Left")
     .setPosition(10 + (viewBtnW + viewBtnSpacing) * 2, currentY)
     .setSize(viewBtnW, viewBtnH);
     
  cp5.addButton("viewRight")
     .setLabel("Right")
     .setPosition(10 + (viewBtnW + viewBtnSpacing) * 3, currentY)
     .setSize(viewBtnW, viewBtnH);
  
  currentY += viewBtnH + 5;
  
  cp5.addButton("viewTop")
     .setLabel("Top")
     .setPosition(10, currentY)
     .setSize(viewBtnW, viewBtnH);
     
  cp5.addButton("viewBottom")
     .setLabel("Bottom")
     .setPosition(10 + viewBtnW + viewBtnSpacing, currentY)
     .setSize(viewBtnW, viewBtnH);
     
  cp5.addButton("viewReset")
     .setLabel("Reset")
     .setPosition(10 + (viewBtnW + viewBtnSpacing) * 2, currentY)
     .setSize(viewBtnW * 2 + viewBtnSpacing, viewBtnH);

  // Buttons
  currentY += viewBtnH + 10; // Add extra space before export button
  cp5.addButton("exportSVG")
     .setLabel("Export SVG")
     .setPosition(10, currentY)
     .setSize(100, inputH + 5);
   
  // Multi-view export button
  cp5.addButton("exportMultiViewSVG")
     .setLabel("Export Grid View")
     .setPosition(120, currentY)
     .setSize(110, inputH + 5);
}

void draw() {
  // Handle SVG recording first
  if (recordSVG) {
    try {
      println("Creating SVG...");
      
      if (enable3DView) {
        // For 3D export, we need to manually transform all points to their screen positions
        println("SVG Export: 3D mode - projecting points to 2D");
        export3DSVG();
      } else {
        // Standard 2D export
        PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
        svg.beginDraw();
        drawPattern(svg); // Draw pattern to SVG
        svg.endDraw();
        svg.dispose();
      }
      
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

  // Handle multi-view export
  if (doingMultiViewExport) {
    handleMultiViewExport();
    return; // Skip regular drawing during export
  }

  // --- Main Screen Drawing ---
  background(255); // White background
  
  if (enable3DView) {
    // Apply 3D camera transformations
    translate(width / 2 + transX, height / 2 + transY);
    rotateX(rotX);
    rotateY(rotY);
    scale(zoom);
  } else {
    // Standard 2D centering
    translate(width / 2, height / 2);
  }
  
  // Draw the pattern with duplicates and rotation
  drawPattern(this.g); 

  // --- Draw UI ---
  // Reset view for UI drawing
  hint(DISABLE_DEPTH_TEST);
  camera(); // Reset to default camera
  noLights(); // Disable any lights that might affect UI
  cp5.draw();
  hint(ENABLE_DEPTH_TEST);
}

// New function to draw the complete pattern with duplicates
void drawPattern(PGraphics g) {
  // Base scale 
  float currentTotalScale = scaleFactor;
  
  // Only apply offset cycles if numberOfOffsetCycles > 0
  if (numberOfOffsetCycles > 0) {
    // --- Use Offset Cycle Logic --- 
    int effectiveCycleCount = max(2, offsetCycleCount);
    int effectiveNumCycles = numberOfOffsetCycles; // Already checked to be >= 0
    int halfCycle = effectiveCycleCount / 2;
    // Ensure the relative offset is positive for calculation
    float firstRelativeOffset = max(1e-6, initialScaleOffset - 1.0); 
    
    // Base scale for the innermost curve (can be modified by UI)
    currentTotalScale = scaleFactor; 
  
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
            
            // Apply either spiral or rotation pattern
            if (useSpiralRepetition) {
              // Use spiral placement
              float spiralAngle = map(totalDuplicateIndex, 0, numDuplicates, 0, radians(spiralTotalDegrees));
              float spiralRadius = map(totalDuplicateIndex, 0, numDuplicates, 0, spiralAmplitude * max(A, B));
              
              g.pushMatrix();
              g.translate(spiralRadius * cos(spiralAngle), spiralRadius * sin(spiralAngle));
              // Still apply base rotation 
              g.rotate(radians(baseRotationDegrees));
              drawLissajous(g, currentTotalScale);
              g.popMatrix();
            } else {
              // Use original rotation pattern
              float currentRotationDegrees = baseRotationDegrees + (totalDuplicateIndex * rotationStepDegrees);
              g.pushMatrix();
              g.rotate(radians(currentRotationDegrees));
              drawLissajous(g, currentTotalScale);
              g.popMatrix();
            }
        }
        // Reset the scale for the next cycle to start from the base scale again
        currentTotalScale = scaleFactor; 
    }
  }
  
  // --- Draw regular duplicates without offset scaling ---
  // This ensures we still draw the duplicates even if offset cycles are disabled
  if (numDuplicates > 1) {
    for (int i = 0; i < numDuplicates; i++) {
      if (useSpiralRepetition) {
        float spiralAngle = map(i, 0, numDuplicates, 0, radians(spiralTotalDegrees));
        float spiralRadius = map(i, 0, numDuplicates, 0, spiralAmplitude * max(A, B));
        
        g.pushMatrix();
        g.translate(spiralRadius * cos(spiralAngle), spiralRadius * sin(spiralAngle));
        g.rotate(radians(baseRotationDegrees));
        drawLissajous(g, scaleFactor);
        g.popMatrix();
      } else {
        float currentRotationDegrees = baseRotationDegrees + (i * rotationStepDegrees);
        g.pushMatrix();
        g.rotate(radians(currentRotationDegrees));
        drawLissajous(g, scaleFactor);
        g.popMatrix();
      }
    }
  } else {
    // --- Draw the original base curve (scale = scaleFactor) --- 
    g.pushMatrix();
    g.rotate(radians(baseRotationDegrees));
    drawLissajous(g, scaleFactor);
    g.popMatrix();
  }
}

// Modified function to draw ONE Lissajous curve with specified scale
void drawLissajous(PGraphics g, float totalScale) { 
  g.pushMatrix(); // Isolate transformations
  g.scale(totalScale); // Apply the calculated total scale for THIS curve

  g.stroke(0); // Black lines
  g.strokeWeight(lineWidth / totalScale); // Adjust line width for scaling
  g.noFill(); // No fill

  // Calculate common values
  float delta = radians(deltaDegrees); // Convert phase shift to radians
  float pzRad = radians(pzDeg); // Convert Z phase to radians
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
        
        // Z modulation (NEW)
        float z = Az * sin(fz * t + pzRad);
        
        // Apply wave modulation if depth is significant
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
        
        // Use 3D or 2D vertex based on mode
        if (enable3DView) {
          g.vertex(x, y, z);
        } else {
          g.vertex(x, y);
        }
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
         float cz = Az * sin(fz * t + pzRad); // Z coordinate
         
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
            
            // Draw the line segment in 2D or 3D
            if (enable3DView) {
              g.line(x1, y1, cz, x2, y2, cz); // Z is same for both endpoints
            } else {
              g.line(x1, y1, x2, y2);
            }
         } 
         // Else: if mag is near zero, tangent is undefined/zero, skip drawing line for this point
      }
  }
  
  g.popMatrix(); // Restore previous transformation state
}

// 3D SVG export function based on PolarSpirograph's implementation
void export3DSVG() {
  // Create a temporary PGraphics to calculate screen coordinates
  PGraphics pg = createGraphics(width, height, P3D);
  pg.beginDraw();
  pg.translate(width / 2 + transX, height / 2 + transY);
  pg.rotateX(rotX);
  pg.rotateY(rotY);
  pg.scale(zoom);
  
  // Create an ArrayList to store all the polylines in screen coordinates
  ArrayList<ArrayList<PVector>> allScreenPolylines = new ArrayList<ArrayList<PVector>>();
  
  // Use Offset Cycle Logic
  int effectiveCycleCount = max(2, offsetCycleCount);
  int effectiveNumCycles = max(1, numberOfOffsetCycles);
  int halfCycle = effectiveCycleCount / 2;
  float firstRelativeOffset = max(1e-6, initialScaleOffset - 1.0);
  float currentTotalScale = scaleFactor;
  
  // Process all curves for offset cycles
  for (int cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
    for (int d = 0; d < effectiveCycleCount; d++) {
      int exponentIndex = (d < halfCycle) ? d : (effectiveCycleCount - 1 - d);
      float stepScaleFactor = 1.0 + firstRelativeOffset * pow(scaleDecay, exponentIndex);
      currentTotalScale *= stepScaleFactor;
      
      if (currentTotalScale <= 1e-6) continue;
      
      int totalDuplicateIndex = cycleNum * effectiveCycleCount + d;
      
      // Process this curve instance
      pg.pushMatrix();
      
      // Apply either spiral or rotation pattern
      if (useSpiralRepetition) {
        float spiralAngle = map(totalDuplicateIndex, 0, numDuplicates, 0, radians(spiralTotalDegrees));
        float spiralRadius = map(totalDuplicateIndex, 0, numDuplicates, 0, spiralAmplitude * max(A, B));
        pg.translate(spiralRadius * cos(spiralAngle), spiralRadius * sin(spiralAngle));
        pg.rotate(radians(baseRotationDegrees));
      } else {
        float currentRotationDegrees = baseRotationDegrees + (totalDuplicateIndex * rotationStepDegrees);
        pg.rotate(radians(currentRotationDegrees));
      }
      
      pg.scale(currentTotalScale);
      
      // Generate the points for this curve
      ArrayList<PVector> screenPoints = projectLissajousCurve(pg, currentTotalScale);
      allScreenPolylines.add(screenPoints);
      
      pg.popMatrix();
    }
    currentTotalScale = scaleFactor;
  }
  
  // Add the base curve
  if (!useSpiralRepetition) {
    pg.pushMatrix();
    pg.rotate(radians(baseRotationDegrees));
    pg.scale(scaleFactor);
    ArrayList<PVector> screenPoints = projectLissajousCurve(pg, scaleFactor);
    allScreenPolylines.add(screenPoints);
    pg.popMatrix();
  }
  
  pg.endDraw();
  pg.dispose();
  
  // Now create the SVG with the projected 2D points
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
  svg.beginDraw();
  svg.background(255);
  svg.stroke(0);
  svg.strokeWeight(lineWidth);
  svg.noFill();
  
  // Draw all projected polylines to SVG
  for (ArrayList<PVector> pointSet : allScreenPolylines) {
    svg.beginShape();
    for (PVector p : pointSet) {
      svg.vertex(p.x, p.y);
    }
    svg.endShape();
  }
  
  svg.endDraw();
  svg.dispose();
}

// Helper method to generate and project a Lissajous curve's points
ArrayList<PVector> projectLissajousCurve(PGraphics pg, float scale) {
  ArrayList<PVector> screenPoints = new ArrayList<PVector>();
  
  float delta = radians(deltaDegrees);
  float pzRad = radians(pzDeg);
  float tMax = TWO_PI * tCycles;
  
  if (drawMode == 0) { // Curve mode
    int steps = max(2, numPoints);
    
    for (int i = 0; i <= steps; i++) {
      float t = map(i, 0, steps, 0, tMax);
      
      // Calculate the 3D point
      float x = A * sin(a * t + delta);
      float y = B * sin(b * t);
      float z = Az * sin(fz * t + pzRad);
      
      // Apply wave modulation
      if (abs(waveDepth) > 1e-3) {
        float tx = A * a * cos(a * t + delta);
        float ty = B * b * cos(b * t);
        float nx = -ty;
        float ny = tx;
        float mag = sqrt(nx*nx + ny*ny);
        
        if (mag > 1e-6) {
          nx /= mag;
          ny /= mag;
          float waveOffset = waveDepth * sin(waveFreq * t);
          x += nx * waveOffset;
          y += ny * waveOffset;
        }
      }
      
      // Project the 3D point to screen coordinates
      float sx = pg.modelX(x, y, z);
      float sy = pg.modelY(x, y, z);
      screenPoints.add(new PVector(sx, sy));
    }
  } else { // Perpendicular lines mode
    int numLines = max(1, lineDensity);
    float halfLineLen = perpLineLength / 2.0;
    
    for (int i = 0; i < numLines; i++) {
      float t = map(i, 0, numLines, 0, tMax);
      
      float cx = A * sin(a * t + delta);
      float cy = B * sin(b * t);
      float cz = Az * sin(fz * t + pzRad);
      
      float tx = A * a * cos(a * t + delta);
      float ty = B * b * cos(b * t);
      float nx = -ty;
      float ny = tx;
      
      float mag = sqrt(nx*nx + ny*ny);
      if (mag > 1e-6) {
        nx /= mag;
        ny /= mag;
        
        float x1 = cx + nx * halfLineLen;
        float y1 = cy + ny * halfLineLen;
        float x2 = cx - nx * halfLineLen;
        float y2 = cy - ny * halfLineLen;
        
        // Add both endpoints for the line
        float sx1 = pg.modelX(x1, y1, cz);
        float sy1 = pg.modelY(x1, y1, cz);
        float sx2 = pg.modelX(x2, y2, cz);
        float sy2 = pg.modelY(x2, y2, cz);
        
        // Add as separate points for a line segment
        screenPoints.add(new PVector(sx1, sy1));
        screenPoints.add(new PVector(sx2, sy2));
      }
    }
  }
  
  return screenPoints;
}

// --- Mouse Interaction for 3D View ---
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

void mouseWheel(MouseEvent event) {
  if (enable3DView && !cp5.isMouseOver()) {
    float count = event.getCount();
    zoom *= pow(0.95, count); // Adjust zoom sensitivity
    zoom = max(0.1, zoom); // Prevent zooming too far in/out
  }
}

// --- ControlP5 Handlers (called automatically) ---

// Base Lissajous parameters
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

// Z parameters
public void Az(String theValue) {
  try { Az = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid Az"); if (cp5 != null) ((Textfield)cp5.getController("Az")).setValue(nf(Az, 1, 2)); }
}
public void fz(String theValue) {
  try { fz = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid fz"); if (cp5 != null) ((Textfield)cp5.getController("fz")).setValue(nf(fz, 1, 2)); }
}
public void pzDeg(String theValue) {
  try { pzDeg = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid pzDeg"); if (cp5 != null) ((Textfield)cp5.getController("pzDeg")).setValue(nf(pzDeg, 1, 1)); }
}

// Spiral Repetition parameters
public void useSpiralRepetition(boolean val) { 
  useSpiralRepetition = val; 
}
public void spiralTotalDegrees(String theValue) {
  try { spiralTotalDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid spiralTotalDegrees"); if (cp5 != null) ((Textfield)cp5.getController("spiralTotalDegrees")).setValue(nf(spiralTotalDegrees, 1, 1)); }
}
public void spiralAmplitude(String theValue) {
  try { spiralAmplitude = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid spiralAmplitude"); if (cp5 != null) ((Textfield)cp5.getController("spiralAmplitude")).setValue(nf(spiralAmplitude, 1, 2)); }
}

// 3D View Toggle
public void enable3DView(boolean val) { 
  enable3DView = val; 
}

// Drawing parameters
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
public void numDuplicates(String theValue) {
  try { numDuplicates = max(1, Integer.parseInt(theValue)); } 
  catch (NumberFormatException e) { println("Invalid numDuplicates"); numDuplicates = max(1, numDuplicates); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("numDuplicates")).setValue(""+numDuplicates); }
}

// Base rotation and step parameters
public void baseRotationDegrees(String theValue) {
  try { baseRotationDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid baseRotationDegrees"); if (cp5 != null) ((Textfield)cp5.getController("baseRotationDegrees")).setValue(nf(baseRotationDegrees, 1, 1)); }
}
public void rotationStepDegrees(String theValue) {
  try { rotationStepDegrees = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid rotationStepDegrees"); if (cp5 != null) ((Textfield)cp5.getController("rotationStepDegrees")).setValue(nf(rotationStepDegrees, 1, 1)); }
}

// T Cycles parameter
public void tCycles(String theValue) {
  try { tCycles = max(0.01, Float.parseFloat(theValue)); } // Ensure positive cycles
  catch (NumberFormatException e) { println("Invalid tCycles"); tCycles = max(0.01, tCycles); } // Keep last valid value or 0.01
  finally { if (cp5 != null) ((Textfield)cp5.getController("tCycles")).setValue(nf(tCycles, 1, 2)); } // Update field if clamped
}

// Wave modulation parameters
public void waveDepth(String theValue) {
  try { waveDepth = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid waveDepth"); if (cp5 != null) ((Textfield)cp5.getController("waveDepth")).setValue(nf(waveDepth, 1, 1)); }
}
public void waveFreq(String theValue) {
  try { waveFreq = Float.parseFloat(theValue); } 
  catch (NumberFormatException e) { println("Invalid waveFreq"); if (cp5 != null) ((Textfield)cp5.getController("waveFreq")).setValue(nf(waveFreq, 1, 1)); }
}

// Draw mode and line parameters
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

// Offset cycle parameters
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
    numberOfOffsetCycles = max(0, numberOfOffsetCycles); // Allow 0 to disable offset cycles
  } catch (NumberFormatException e) { 
    println("Invalid numberOfOffsetCycles"); 
    numberOfOffsetCycles = max(0, numberOfOffsetCycles);
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

// --- SVG Export Logic ---
public void exportSVG() {
  println("SVG export requested via button");
  if (recordSVG) { println("Export already in progress."); return; }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "LissajousSpiral_" + getTimestamp() + ".svg"), this);
}

// Multi-view SVG export
public void exportMultiViewSVG() {
  println("Multi-view SVG export requested");
  if (recordSVG || doingMultiViewExport) { 
    println("Export already in progress."); 
    return; 
  }
  selectOutput("Save multi-view SVG as...", "multiViewSvgFileSelected", 
    new File(sketchPath(""), "LissajousSpiral_MultiView_" + getTimestamp() + ".svg"), this);
}

// File selected handler for multi-view export
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
    drawPattern(g);
    
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
    
    // Capture the current screen content for this view
    PImage viewImg = get();
    
    // Convert screen to SVG-friendly paths
    multiViewSvg.stroke(0);
    multiViewSvg.strokeWeight(lineWidth);
    multiViewSvg.noFill();
    
    // Project the current pattern to the SVG
    ArrayList<ArrayList<PVector>> allPolylines = new ArrayList<ArrayList<PVector>>();
    PGraphics pg = createGraphics(viewWidth, viewHeight, P3D);
    pg.beginDraw();
    pg.translate(viewWidth / 2, viewHeight / 2);
    pg.rotateX(rotX);
    pg.rotateY(rotY);
    pg.scale(zoom);
    
    // Get projected curves
    ArrayList<ArrayList<PVector>> viewPolylines = generateViewProjections(pg, viewWidth, viewHeight);
    
    // Draw the polylines to the SVG
    for (ArrayList<PVector> pointSet : viewPolylines) {
      multiViewSvg.beginShape();
      for (PVector p : pointSet) {
        multiViewSvg.vertex(p.x, p.y);
      }
      multiViewSvg.endShape();
    }
    
    multiViewSvg.popMatrix();
    pg.endDraw();
    pg.dispose();
    
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

// Helper method to generate projections for a specific view
ArrayList<ArrayList<PVector>> generateViewProjections(PGraphics pg, int viewWidth, int viewHeight) {
  ArrayList<ArrayList<PVector>> allScreenPolylines = new ArrayList<ArrayList<PVector>>();
  
  // Base scale 
  float currentTotalScale = scaleFactor;
  
  // Apply offset cycles if enabled
  if (numberOfOffsetCycles > 0) {
    int effectiveCycleCount = max(2, offsetCycleCount);
    int effectiveNumCycles = numberOfOffsetCycles;
    int halfCycle = effectiveCycleCount / 2;
    float firstRelativeOffset = max(1e-6, initialScaleOffset - 1.0);
    
    for (int cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
      for (int d = 0; d < effectiveCycleCount; d++) {
        int exponentIndex = (d < halfCycle) ? d : (effectiveCycleCount - 1 - d);
        float stepScaleFactor = 1.0 + firstRelativeOffset * pow(scaleDecay, exponentIndex);
        currentTotalScale *= stepScaleFactor;
        
        if (currentTotalScale <= 1e-6) continue;
        
        int totalDuplicateIndex = cycleNum * effectiveCycleCount + d;
        
        // Process this curve instance
        pg.pushMatrix();
        
        // Apply either spiral or rotation pattern
        if (useSpiralRepetition) {
          float spiralAngle = map(totalDuplicateIndex, 0, numDuplicates, 0, radians(spiralTotalDegrees));
          float spiralRadius = map(totalDuplicateIndex, 0, numDuplicates, 0, spiralAmplitude * max(A, B));
          pg.translate(spiralRadius * cos(spiralAngle), spiralRadius * sin(spiralAngle));
          pg.rotate(radians(baseRotationDegrees));
        } else {
          float currentRotationDegrees = baseRotationDegrees + (totalDuplicateIndex * rotationStepDegrees);
          pg.rotate(radians(currentRotationDegrees));
        }
        
        pg.scale(currentTotalScale);
        
        // Generate the points for this curve
        ArrayList<PVector> screenPoints = projectLissajousCurve(pg, currentTotalScale);
        
        // Scale points to fit the viewWidth/viewHeight
        for (PVector p : screenPoints) {
          p.x = map(p.x, 0, width, 0, viewWidth);
          p.y = map(p.y, 0, height, 0, viewHeight);
        }
        
        allScreenPolylines.add(screenPoints);
        
        pg.popMatrix();
      }
      currentTotalScale = scaleFactor;
    }
  }
  
  // Draw regular duplicates without offset scaling
  if (numDuplicates > 1) {
    for (int i = 0; i < numDuplicates; i++) {
      pg.pushMatrix();
      
      if (useSpiralRepetition) {
        float spiralAngle = map(i, 0, numDuplicates, 0, radians(spiralTotalDegrees));
        float spiralRadius = map(i, 0, numDuplicates, 0, spiralAmplitude * max(A, B));
        pg.translate(spiralRadius * cos(spiralAngle), spiralRadius * sin(spiralAngle));
        pg.rotate(radians(baseRotationDegrees));
      } else {
        float currentRotationDegrees = baseRotationDegrees + (i * rotationStepDegrees);
        pg.rotate(radians(currentRotationDegrees));
      }
      
      pg.scale(scaleFactor);
      
      ArrayList<PVector> screenPoints = projectLissajousCurve(pg, scaleFactor);
      
      // Scale points to fit the viewWidth/viewHeight
      for (PVector p : screenPoints) {
        p.x = map(p.x, 0, width, 0, viewWidth);
        p.y = map(p.y, 0, height, 0, viewHeight);
      }
      
      allScreenPolylines.add(screenPoints);
      
      pg.popMatrix();
    }
  } else {
    // Base curve
    pg.pushMatrix();
    pg.rotate(radians(baseRotationDegrees));
    pg.scale(scaleFactor);
    
    ArrayList<PVector> screenPoints = projectLissajousCurve(pg, scaleFactor);
    
    // Scale points to fit the viewWidth/viewHeight
    for (PVector p : screenPoints) {
      p.x = map(p.x, 0, width, 0, viewWidth);
      p.y = map(p.y, 0, height, 0, viewHeight);
    }
    
    allScreenPolylines.add(screenPoints);
    
    pg.popMatrix();
  }
  
  return allScreenPolylines;
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

// Key press for SVG export
void keyPressed() {
  if (key == 's' || key == 'S') {
      exportSVG(); // Call the same function as the button
  }
}

// --- View Cube Face Handlers ---
public void viewFront(int theValue) {
  if (!enable3DView) {
    enable3DView = true;
    if (cp5 != null) ((Toggle)cp5.getController("enable3DView")).setValue(true);
  }
  
  // Front view (default)
  rotX = 0;
  rotY = 0;
  transX = 0;
  transY = 0;
  // Maintain current zoom level
}

public void viewBack(int theValue) {
  if (!enable3DView) {
    enable3DView = true;
    if (cp5 != null) ((Toggle)cp5.getController("enable3DView")).setValue(true);
  }
  
  // Back view (180° rotation around Y)
  rotX = 0;
  rotY = PI;
  transX = 0;
  transY = 0;
  // Maintain current zoom level
}

public void viewLeft(int theValue) {
  if (!enable3DView) {
    enable3DView = true;
    if (cp5 != null) ((Toggle)cp5.getController("enable3DView")).setValue(true);
  }
  
  // Left view (-90° around Y)
  rotX = 0;
  rotY = -HALF_PI;
  transX = 0;
  transY = 0;
  // Maintain current zoom level
}

public void viewRight(int theValue) {
  if (!enable3DView) {
    enable3DView = true;
    if (cp5 != null) ((Toggle)cp5.getController("enable3DView")).setValue(true);
  }
  
  // Right view (90° around Y)
  rotX = 0;
  rotY = HALF_PI;
  transX = 0;
  transY = 0;
  // Maintain current zoom level
}

public void viewTop(int theValue) {
  if (!enable3DView) {
    enable3DView = true;
    if (cp5 != null) ((Toggle)cp5.getController("enable3DView")).setValue(true);
  }
  
  // Top view (-90° around X)
  rotX = -HALF_PI;
  rotY = 0;
  transX = 0;
  transY = 0;
  // Maintain current zoom level
}

public void viewBottom(int theValue) {
  if (!enable3DView) {
    enable3DView = true;
    if (cp5 != null) ((Toggle)cp5.getController("enable3DView")).setValue(true);
  }
  
  // Bottom view (90° around X)
  rotX = HALF_PI;
  rotY = 0;
  transX = 0;
  transY = 0;
  // Maintain current zoom level
}

public void viewReset(int theValue) {
  // Reset all view parameters
  rotX = 0;
  rotY = 0;
  transX = 0;
  transY = 0;
  zoom = 1.0;
}
