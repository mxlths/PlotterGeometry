import controlP5.*;
import processing.svg.*;
import java.io.File;
import processing.event.MouseEvent;

ControlP5 cp5;
PFont labelFont;

// 3D View Control
float rotX = 0;
float rotY = 0;
float zoom = 1.0;
float transX = 0;
float transY = 0;
int lastMouseX = 0;
int lastMouseY = 0;
boolean isDragging = false;

// Torus Parameters
float torusRadius = 150;       // Major radius (center of tube to center of torus)
float tubeRadius = 50;         // Minor radius (radius of the tube)
int resolution = 72;           // Resolution of the torus (number of segments)
int tubeResolution = 36;       // Resolution of the tube

// Line Style Parameters
boolean showLongitudinal = true;
boolean showLatitudinal = true;
boolean showSpiral = false;
boolean showCounterSpiral = false;
int spiralTurns = 8;            // Number of spiral turns around the torus
int counterSpiralTurns = 12;    // Number of counter-spiral turns

// Line Appearance
float longitudinalWidth = 0.8;
float latitudinalWidth = 0.8;
float spiralWidth = 1.0;
float counterSpiralWidth = 1.0;

// Colors in HSB format (Hue, Saturation, Brightness)
float[] longitudinalHSB = {0, 0, 0};       // Black by default
float[] latitudinalHSB = {0, 0, 0};        // Black by default
float[] spiralHSB = {240, 70, 100};        // Blue by default
float[] counterSpiralHSB = {0, 70, 100};   // Red by default

// Color control variables
int selectedColorIndex = 0;
String[] colorLabels = {"Longitudinal", "Latitudinal", "Spiral", "Counter-Spiral"};
boolean isDraggingH = false;
boolean isDraggingS = false;
boolean isDraggingB = false;

// SVG Export
boolean recordSVG = false;
String svgOutputPath = null;

// UI Layout
int sidebarWidth = 250;
int mainCanvasWidth;
int mainCanvasHeight;

void setup() {
  size(1000, 700, P3D);
  smooth();
  colorMode(HSB, 360, 100, 100);
  
  // Calculate main canvas dimensions
  mainCanvasWidth = width - sidebarWidth;
  mainCanvasHeight = height;
  
  // Initialize controlP5
  cp5 = new ControlP5(this);
  labelFont = createFont("Arial", 12, true);
  
  setupGUI();
}

void draw() {
  background(240);
  
  // Draw sidebar background
  fill(220);
  noStroke();
  rect(mainCanvasWidth, 0, sidebarWidth, height);
  
  // Draw 3D view area border
  stroke(180);
  strokeWeight(1);
  fill(250);
  rect(0, 0, mainCanvasWidth, height);
  
  // Start SVG recording if needed
  if (recordSVG) {
    beginRecord(SVG, svgOutputPath);
    // Set line properties for SVG export
    hint(DISABLE_DEPTH_TEST);
    strokeWeight(1);
    noFill();
  }
  
  // Setup the 3D view
  pushMatrix();
  translate(mainCanvasWidth/2 + transX, height/2 + transY);
  scale(zoom);
  rotateX(rotX);
  rotateY(rotY);
  
  // Draw the torus
  drawTorus();
  
  // End SVG recording if active
  if (recordSVG) {
    endRecord();
    recordSVG = false;
    println("SVG saved to " + svgOutputPath);
  }
  
  popMatrix();
  
  // Draw selected color indicator and HSB values
  drawColorInfo();
  
  // Draw instructions
  fill(0);
  textAlign(LEFT, BOTTOM);
  textSize(12);
  text("3D Controls: Drag to rotate, Scroll to zoom, Shift+drag to pan", 10, height - 10);
}

void drawTorus() {
  // Calculate points on the torus
  PVector[][] points = new PVector[resolution + 1][tubeResolution + 1];
  
  // Generate torus points
  for (int i = 0; i <= resolution; i++) {
    float phi = map(i, 0, resolution, 0, TWO_PI);
    for (int j = 0; j <= tubeResolution; j++) {
      float theta = map(j, 0, tubeResolution, 0, TWO_PI);
      
      // Standard parametric equation for torus
      float x = (torusRadius + tubeRadius * cos(theta)) * cos(phi);
      float y = (torusRadius + tubeRadius * cos(theta)) * sin(phi);
      float z = tubeRadius * sin(theta);
      
      points[i][j] = new PVector(x, y, z);
    }
  }
  
  // The torus is appearing black possibly due to too many lines, so let's skip more
  int longitudinalStep = max(1, tubeResolution / 18);
  int latitudinalStep = max(1, resolution / 18);
  
  // Draw longitudinal lines (along the tube rings)
  if (showLongitudinal) {
    stroke(longitudinalHSB[0], longitudinalHSB[1], longitudinalHSB[2]);
    strokeWeight(longitudinalWidth);
    
    for (int j = 0; j < tubeResolution; j += longitudinalStep) {
      beginShape();
      for (int i = 0; i <= resolution; i++) {
        vertex(points[i][j].x, points[i][j].y, points[i][j].z);
      }
      endShape();
    }
  }
  
  // Draw latitudinal lines (around the main circle)
  if (showLatitudinal) {
    stroke(latitudinalHSB[0], latitudinalHSB[1], latitudinalHSB[2]);
    strokeWeight(latitudinalWidth);
    
    for (int i = 0; i < resolution; i += latitudinalStep) {
      beginShape();
      for (int j = 0; j <= tubeResolution; j++) {
        vertex(points[i][j].x, points[i][j].y, points[i][j].z);
      }
      endShape();
    }
  }
  
  // Draw spiral lines
  if (showSpiral) {
    stroke(spiralHSB[0], spiralHSB[1], spiralHSB[2]);
    strokeWeight(spiralWidth);
    
    int spiralCount = 6; // Reduce the number of spiral lines
    for (int offset = 0; offset < tubeResolution; offset += tubeResolution / spiralCount) {
      beginShape();
      for (int i = 0; i <= resolution * spiralTurns; i++) {
        float phi = map(i, 0, resolution * spiralTurns, 0, TWO_PI * spiralTurns);
        int iPhi = int(map(phi, 0, TWO_PI * spiralTurns, 0, resolution)) % resolution;
        int jTheta = (offset + int(map(phi, 0, TWO_PI * spiralTurns, 0, tubeResolution * spiralTurns))) % tubeResolution;
        
        vertex(points[iPhi][jTheta].x, points[iPhi][jTheta].y, points[iPhi][jTheta].z);
      }
      endShape();
    }
  }
  
  // Draw counter-spiral lines
  if (showCounterSpiral) {
    stroke(counterSpiralHSB[0], counterSpiralHSB[1], counterSpiralHSB[2]);
    strokeWeight(counterSpiralWidth);
    
    int counterSpiralCount = 6; // Reduce the number of counter-spiral lines
    for (int offset = 0; offset < tubeResolution; offset += tubeResolution / counterSpiralCount) {
      beginShape();
      for (int i = 0; i <= resolution * counterSpiralTurns; i++) {
        float phi = map(i, 0, resolution * counterSpiralTurns, 0, TWO_PI * counterSpiralTurns);
        int iPhi = int(map(phi, 0, TWO_PI * counterSpiralTurns, 0, resolution)) % resolution;
        int jTheta = (offset - int(map(phi, 0, TWO_PI * counterSpiralTurns, 0, tubeResolution * counterSpiralTurns))) % tubeResolution;
        if (jTheta < 0) jTheta += tubeResolution;
        
        vertex(points[iPhi][jTheta].x, points[iPhi][jTheta].y, points[iPhi][jTheta].z);
      }
      endShape();
    }
  }
}

void setupGUI() {
  // All GUI elements will be in the sidebar
  int panelX = mainCanvasWidth + 10;
  int currentY = 20;
  int inputW = sidebarWidth - 30;
  int inputH = 20;
  int spacing = 28;
  int groupSpacing = 40;
  
  // Section title style
  CColor sectionTitleColor = new CColor();
  sectionTitleColor.setBackground(color(210));
  sectionTitleColor.setForeground(color(0));
  sectionTitleColor.setCaptionLabel(color(0));
  
  // ------ TORUS DIMENSIONS SECTION ------
  cp5.addTextlabel("dimensionsLabel")
     .setText("TORUS DIMENSIONS")
     .setPosition(panelX, currentY)
     .setColorValue(color(0))
     .setFont(createFont("Arial Bold", 14));
     
  currentY += 25;
  
  // Torus Major Radius
  cp5.addTextlabel("torusRadiusLabel")
     .setText("Torus Radius:")
     .setPosition(panelX, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("torusRadius")
     .setPosition(panelX, currentY + 20)
     .setSize(inputW, inputH)
     .setRange(50, 300)
     .setValue(torusRadius)
     .setCaptionLabel("");
     
  currentY += spacing + 20;
  
  // Tube Radius
  cp5.addTextlabel("tubeRadiusLabel")
     .setText("Tube Radius:")
     .setPosition(panelX, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("tubeRadius")
     .setPosition(panelX, currentY + 20)
     .setSize(inputW, inputH)
     .setRange(10, 100)
     .setValue(tubeRadius)
     .setCaptionLabel("");
  
  currentY += spacing + 20;
  
  // Resolution
  cp5.addTextlabel("resolutionLabel")
     .setText("Resolution:")
     .setPosition(panelX, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("resolution")
     .setPosition(panelX, currentY + 20)
     .setSize(inputW, inputH)
     .setRange(12, 120)
     .setValue(resolution)
     .setCaptionLabel("");
  
  currentY += spacing + 20;
  
  // Tube Resolution
  cp5.addTextlabel("tubeResolutionLabel")
     .setText("Tube Resolution:")
     .setPosition(panelX, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("tubeResolution")
     .setPosition(panelX, currentY + 20)
     .setSize(inputW, inputH)
     .setRange(8, 72)
     .setValue(tubeResolution)
     .setCaptionLabel("");
     
  currentY += groupSpacing + 10;
  
  // ------ LINE STYLES SECTION ------
  cp5.addTextlabel("lineStylesLabel")
     .setText("LINE STYLES")
     .setPosition(panelX, currentY)
     .setColorValue(color(0))
     .setFont(createFont("Arial Bold", 14));
     
  currentY += 25;
  
  // Longitudinal lines
  cp5.addToggle("showLongitudinal")
     .setPosition(panelX, currentY)
     .setSize(25, inputH)
     .setMode(ControlP5.SWITCH)
     .setValue(showLongitudinal)
     .setCaptionLabel("");
     
  cp5.addTextlabel("longitudinalLabel")
     .setText("Longitudinal")
     .setPosition(panelX + 35, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
  
  cp5.addTextlabel("longitudinalWidthLabel")
     .setText("Width:")
     .setPosition(panelX + 130, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("longitudinalWidth")
     .setPosition(panelX + 170, currentY)
     .setSize(60, inputH)
     .setRange(0.1, 3.0)
     .setValue(longitudinalWidth)
     .setCaptionLabel("");
  
  currentY += spacing;
  
  // Latitudinal lines
  cp5.addToggle("showLatitudinal")
     .setPosition(panelX, currentY)
     .setSize(25, inputH)
     .setMode(ControlP5.SWITCH)
     .setValue(showLatitudinal)
     .setCaptionLabel("");
     
  cp5.addTextlabel("latitudinalLabel")
     .setText("Latitudinal")
     .setPosition(panelX + 35, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
  
  cp5.addTextlabel("latitudinalWidthLabel")
     .setText("Width:")
     .setPosition(panelX + 130, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("latitudinalWidth")
     .setPosition(panelX + 170, currentY)
     .setSize(60, inputH)
     .setRange(0.1, 3.0)
     .setValue(latitudinalWidth)
     .setCaptionLabel("");
  
  currentY += spacing;
  
  // Spiral lines
  cp5.addToggle("showSpiral")
     .setPosition(panelX, currentY)
     .setSize(25, inputH)
     .setMode(ControlP5.SWITCH)
     .setValue(showSpiral)
     .setCaptionLabel("");
     
  cp5.addTextlabel("spiralLabel")
     .setText("Spiral")
     .setPosition(panelX + 35, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
  
  cp5.addTextlabel("spiralWidthLabel")
     .setText("Width:")
     .setPosition(panelX + 130, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("spiralWidth")
     .setPosition(panelX + 170, currentY)
     .setSize(60, inputH)
     .setRange(0.1, 3.0)
     .setValue(spiralWidth)
     .setCaptionLabel("");
  
  currentY += spacing;
  
  // Spiral turns
  cp5.addTextlabel("spiralTurnsLabel")
     .setText("Spiral Turns:")
     .setPosition(panelX, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("spiralTurns")
     .setPosition(panelX + 100, currentY)
     .setSize(inputW - 110, inputH)
     .setRange(1, 20)
     .setValue(spiralTurns)
     .setCaptionLabel("");
  
  currentY += spacing;
  
  // Counter-Spiral lines
  cp5.addToggle("showCounterSpiral")
     .setPosition(panelX, currentY)
     .setSize(25, inputH)
     .setMode(ControlP5.SWITCH)
     .setValue(showCounterSpiral)
     .setCaptionLabel("");
     
  cp5.addTextlabel("counterSpiralLabel")
     .setText("Counter-Spiral")
     .setPosition(panelX + 35, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
  
  cp5.addTextlabel("counterSpiralWidthLabel")
     .setText("Width:")
     .setPosition(panelX + 130, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("counterSpiralWidth")
     .setPosition(panelX + 170, currentY)
     .setSize(60, inputH)
     .setRange(0.1, 3.0)
     .setValue(counterSpiralWidth)
     .setCaptionLabel("");
  
  currentY += spacing;
  
  // Counter-Spiral turns
  cp5.addTextlabel("counterSpiralTurnsLabel")
     .setText("Counter-Spiral Turns:")
     .setPosition(panelX, currentY + 3)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  cp5.addSlider("counterSpiralTurns")
     .setPosition(panelX + 140, currentY)
     .setSize(inputW - 150, inputH)
     .setRange(1, 20)
     .setValue(counterSpiralTurns)
     .setCaptionLabel("");
     
  currentY += groupSpacing;
  
  // ------ COLOR CONTROLS SECTION ------
  cp5.addTextlabel("colorControlsLabel")
     .setText("COLOR CONTROLS")
     .setPosition(panelX, currentY)
     .setColorValue(color(0))
     .setFont(createFont("Arial Bold", 14));
     
  currentY += 30;
  
  // Color selector buttons are drawn manually in drawColorInfo()
  // But we add the label here
  cp5.addTextlabel("selectColorLabel")
     .setText("Select Line Type to Color:")
     .setPosition(panelX, currentY)
     .setColorValue(color(0))
     .setFont(labelFont);
     
  currentY += 85; // Space for the color buttons drawn in drawColorInfo()
  
  // ------ ACTIONS SECTION ------
  cp5.addTextlabel("actionsLabel")
     .setText("ACTIONS")
     .setPosition(panelX, currentY)
     .setColorValue(color(0))
     .setFont(createFont("Arial Bold", 14));
     
  currentY += 25;
  
  // Export Button
  cp5.addButton("exportSVG")
     .setPosition(panelX, currentY)
     .setSize(inputW / 2 - 5, 30)
     .setCaptionLabel("Export SVG")
     .setColorCaptionLabel(color(0));
  
  // Reset View Button
  cp5.addButton("resetView")
     .setPosition(panelX + inputW / 2 + 5, currentY)
     .setSize(inputW / 2 - 5, 30)
     .setCaptionLabel("Reset View")
     .setColorCaptionLabel(color(0));
}

void drawColorInfo() {
  int panelX = mainCanvasWidth + 10;
  int colorBtnY = 270;
  int buttonSpacing = 25;
  int btnW = (sidebarWidth - 30) / 2;
  int btnH = 25;
  
  // Draw the color selector buttons in a 2x2 grid
  for (int i = 0; i < colorLabels.length; i++) {
    int row = i / 2;
    int col = i % 2;
    
    float btnX = panelX + col * (btnW + 10);
    float btnY = colorBtnY + row * buttonSpacing;
    
    // Draw button background
    if (i == selectedColorIndex) {
      fill(40, 60, 90);
    } else {
      fill(40, 20, 80);
    }
    
    rect(btnX, btnY, btnW, btnH, 5);
    
    // Draw button label - changed to black for better readability
    fill(0);
    textAlign(CENTER, CENTER);
    textFont(labelFont);
    text(colorLabels[i], btnX + btnW/2, btnY + btnH/2);
  }
  
  // Color preview and HSB display
  float[] currentHSB = getCurrentHSB();
  
  float previewX = panelX;
  float previewY = colorBtnY + 60;
  
  // Label
  fill(0);
  textAlign(LEFT, CENTER);
  text("Color Preview:", previewX, previewY - 15);
  
  // Preview box
  fill(currentHSB[0], currentHSB[1], currentHSB[2]);
  rect(previewX, previewY, 50, 30, 5);
  
  // HSB values
  fill(0);
  textAlign(LEFT, CENTER);
  text("H: " + nf(currentHSB[0], 0, 0) + 
       "  S: " + nf(currentHSB[1], 0, 0) + 
       "  B: " + nf(currentHSB[2], 0, 0), 
       previewX + 60, previewY + 15);
}

// Get the current HSB values based on selected color
float[] getCurrentHSB() {
  switch (selectedColorIndex) {
    case 0: return longitudinalHSB;
    case 1: return latitudinalHSB;
    case 2: return spiralHSB;
    case 3: return counterSpiralHSB;
    default: return longitudinalHSB;
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    exportSVG();
  }
  
  if (key == 'r' || key == 'R') {
    resetView();
  }
  
  if (key == '1') selectedColorIndex = 0;
  if (key == '2') selectedColorIndex = 1;
  if (key == '3') selectedColorIndex = 2;
  if (key == '4') selectedColorIndex = 3;
}

void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  
  // Only start dragging if mouse is in the canvas area
  if (mouseX < mainCanvasWidth) {
    isDragging = true;
  }
  
  // Check if a color selector button was clicked
  int panelX = mainCanvasWidth + 10;
  int colorBtnY = 270;
  int buttonSpacing = 25;
  int btnW = (sidebarWidth - 30) / 2;
  int btnH = 25;
  
  for (int i = 0; i < colorLabels.length; i++) {
    int row = i / 2;
    int col = i % 2;
    
    float btnX = panelX + col * (btnW + 10);
    float btnY = colorBtnY + row * buttonSpacing;
    
    if (mouseX >= btnX && mouseX <= btnX + btnW && 
        mouseY >= btnY && mouseY <= btnY + btnH) {
      selectedColorIndex = i;
      return;
    }
  }
}

void mouseDragged() {
  if (isDragging) {
    if (mouseButton == LEFT && !keyPressed) {
      // Rotate view
      rotY += (mouseX - lastMouseX) * 0.01;
      rotX += (mouseY - lastMouseY) * 0.01;
    } else if (keyPressed && keyCode == SHIFT) {
      // Pan view
      transX += (mouseX - lastMouseX);
      transY += (mouseY - lastMouseY);
    }
    
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
}

void mouseReleased() {
  isDragging = false;
}

void mouseWheel(MouseEvent event) {
  // Only zoom if mouse is in the canvas area
  if (mouseX < mainCanvasWidth) {
    // Zoom in/out with mouse wheel
    float e = event.getCount();
    zoom *= (e > 0) ? 0.95 : 1.05;
  }
}

public void resetView() {
  rotX = 0;
  rotY = 0;
  zoom = 1.0;
  transX = 0;
  transY = 0;
}

public void exportSVG() {
  // Create an SVG file name with timestamp
  String timestamp = year() + nf(month(), 2) + nf(day(), 2) + "_" + 
                    nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
  svgOutputPath = sketchPath("exports/torus_" + timestamp + ".svg");
  
  // Ensure exports directory exists
  File dir = new File(sketchPath("exports"));
  if (!dir.exists()) {
    dir.mkdir();
  }
  
  // Set flag to start recording SVG
  recordSVG = true;
}

// These functions are called by ControlP5 when sliders change
public void torusRadius(float value) { torusRadius = value; }
public void tubeRadius(float value) { tubeRadius = value; }
public void resolution(float value) { resolution = int(value); }
public void tubeResolution(float value) { tubeResolution = int(value); }
public void longitudinalWidth(float value) { longitudinalWidth = value; }
public void latitudinalWidth(float value) { latitudinalWidth = value; }
public void spiralWidth(float value) { spiralWidth = value; }
public void counterSpiralWidth(float value) { counterSpiralWidth = value; }
public void spiralTurns(float value) { spiralTurns = int(value); }
public void counterSpiralTurns(float value) { counterSpiralTurns = int(value); }
public void showLongitudinal(boolean value) { showLongitudinal = value; }
public void showLatitudinal(boolean value) { showLatitudinal = value; }
public void showSpiral(boolean value) { showSpiral = value; }
public void showCounterSpiral(boolean value) { showCounterSpiral = value; }
