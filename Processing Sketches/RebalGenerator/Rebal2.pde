import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class
import processing.event.MouseEvent; // For mouse wheel event

ControlP5 cp5;
PFont labelFont; // Font for the labels

// HSL Color Picker Variables
String[] lineTypeLabels = {"Longitudinal", "Latitudinal", "Spiral", "Counter-Spiral", "Vertical Spiral"};
int selectedLineType = 0; // Default to Longitudinal
boolean showColorPicker = false;

// HSL slider variables
int colorPickerX = 800;
int colorPickerY = 40;
int sliderWidth = 150;
int sliderHeight = 15;
int sliderSpacing = 25;

// Slider dragging flags
boolean isDraggingH = false;
boolean isDraggingS = false;
boolean isDraggingL = false;

// Torus Parameters
float majorRadius = 150; // R: Distance from center of torus to center of tube
float minorRadius = 50;  // r: Radius of the tube

// Line Style Parameters (Defaults)
// Longitudinal
boolean drawLongitudinal = true;
int longitudinalDensity = 24; // Number of lines around the main circumference
float longitudinalWidth = 1.0;
color longitudinalColor = color(0, 0, 255); // Blue
int longitudinalDetail = 30; // Segments per longitudinal line circle
boolean longitudinalRainbow = false; // Rainbow gradient option

// Latitudinal
boolean drawLatitudinal = true;
int latitudinalDensity = 12; // Number of lines around the tube cross-section
float latitudinalWidth = 1.0;
color latitudinalColor = color(255, 0, 0); // Red
int latitudinalDetail = 60; // Segments per latitudinal line circle
boolean latitudinalRainbow = false; // Rainbow gradient option

// Spiral
boolean drawSpiral = false;
int spiralDensity = 500; // Number of points along the spiral
int spiralWindings = 5;  // How many times the spiral wraps poloidally for one toroidal revolution
float spiralWidth = 1.5;
color spiralColor = color(0, 255, 0); // Green
boolean spiralRainbow = false; // Rainbow gradient option

// Counter-Spiral (Shares density with Spiral, different winding logic)
boolean drawCounterSpiral = false;
// Uses spiralDensity, spiralWindings
float counterSpiralWidth = 1.5;
color counterSpiralColor = color(255, 165, 0); // Orange
boolean counterSpiralRainbow = false; // Rainbow gradient option

// NEW: Vertical Spiral
boolean drawVerticalSpiral = false;
int verticalSpiralDensity = 500; // Number of points along the spiral
int verticalSpiralWindings = 8; // How many times the spiral oscillates vertically (Z) per main revolution
float verticalSpiralWidth = 1.0;
color verticalSpiralColor = color(128, 0, 128); // Purple
boolean verticalSpiralRainbow = false; // Rainbow gradient option

// 3D View Parameters
float rotX = PI / 6; // Initial tilt
float rotY = PI / 4; // Initial rotation
float zoom = 1.0;
float transX = 0;
float transY = 0;
int lastMouseX = 0;
int lastMouseY = 0;

// SVG Export
boolean recordSVG = false; // Flag to trigger SVG export
String svgOutputPath = null; // Path for SVG output

void setup() {
  size(1200, 800, P3D); // Set canvas size with P3D renderer
  
  cp5 = new ControlP5(this); // Initialize ControlP5
  
  // Create a font for labels
  labelFont = createFont("Arial", 12, true);
  
  // --- GUI Controls (GenerativeCycloid Style) ---
  int inputX = 170; // Start X for input fields
  int inputY = 10;  // Start Y
  int inputW = 60;  // Width of input fields
  int inputH = 20;  // Height of input fields
  int spacing = 25; // Vertical spacing between rows
  int labelW = 150; // Width allocated for labels
  int currentY = inputY; 

  // Ensure all labels use the font and black color
  cp5.setFont(labelFont);
  cp5.setColorForeground(color(0)); // Set default label color
  cp5.setColorCaptionLabel(color(0)); // Set default caption label color

  // --- Torus Parameters ---
  cp5.addLabel("Major Radius (R):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH) // Restore +4 for vertical centering
     .setColorValue(color(0)).setFont(labelFont); 
  cp5.addTextfield("majorRadius")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(majorRadius, 1, 1))
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background like GenerativeCycloid

  currentY += spacing;
  cp5.addLabel("Minor Radius (r):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("minorRadius")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(minorRadius, 1, 1))
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  // --- Longitudinal Lines ---
  currentY += spacing * 1.5; // Add a bit more space for section header
  cp5.addLabel("Longitudinal Lines:")
     .setPosition(10, currentY + 4).setSize(labelW + inputW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  // Add toggle for longitudinal lines
  cp5.addToggle("drawLongitudinal")
     .setPosition(inputX + 10, currentY)
     .setSize(40, 20)
     .setState(drawLongitudinal)
     .setMode(ControlP5.SWITCH)
     .setColorActive(color(0, 80, 160))
     .setColorBackground(color(0, 45, 90));
  currentY += spacing;

  cp5.addLabel("Density:") 
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("longitudinalDensity")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+longitudinalDensity)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  currentY += spacing;
  cp5.addLabel("Width:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("longitudinalWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(longitudinalWidth, 1, 1))
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background
     
  currentY += spacing;
  cp5.addLabel("Detail:") // Smoothing detail
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("longitudinalDetail")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+longitudinalDetail)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  // --- Latitudinal Lines ---
  currentY += spacing * 1.5;
  cp5.addLabel("Latitudinal Lines:")
     .setPosition(10, currentY + 4).setSize(labelW + inputW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  // Add toggle for latitudinal lines
  cp5.addToggle("drawLatitudinal")
     .setPosition(inputX + 10, currentY)
     .setSize(40, 20)
     .setState(drawLatitudinal)
     .setMode(ControlP5.SWITCH)
     .setColorActive(color(0, 80, 160))
     .setColorBackground(color(0, 45, 90));
  currentY += spacing;

  cp5.addLabel("Density:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("latitudinalDensity")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+latitudinalDensity)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  currentY += spacing;
  cp5.addLabel("Width:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("latitudinalWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(latitudinalWidth, 1, 1))
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background
     
  currentY += spacing;
  cp5.addLabel("Detail:") // Smoothing detail
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("latitudinalDetail")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+latitudinalDetail)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  // --- Spiral Lines ---
  currentY += spacing * 1.5;
  cp5.addLabel("Spiral Lines:")
     .setPosition(10, currentY + 4).setSize(labelW + inputW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  // Add toggle for spiral lines
  cp5.addToggle("drawSpiral")
     .setPosition(inputX + 10, currentY)
     .setSize(40, 20)
     .setState(drawSpiral)
     .setMode(ControlP5.SWITCH)
     .setColorActive(color(0, 80, 160))
     .setColorBackground(color(0, 45, 90));
  currentY += spacing;

  cp5.addLabel("Windings:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("spiralWindings")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+spiralWindings)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background
     
  currentY += spacing;
  cp5.addLabel("Density:") // Points along the spiral path
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("spiralDensity")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+spiralDensity)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  currentY += spacing;
  cp5.addLabel("Width:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("spiralWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(spiralWidth, 1, 1))
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  // --- Counter-Spiral Lines ---
  currentY += spacing * 1.5;
  cp5.addLabel("Counter-Spiral Lines:")
     .setPosition(10, currentY + 4).setSize(labelW + inputW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  // Add toggle for counter-spiral lines
  cp5.addToggle("drawCounterSpiral")
     .setPosition(inputX + 10, currentY)
     .setSize(40, 20)
     .setState(drawCounterSpiral)
     .setMode(ControlP5.SWITCH)
     .setColorActive(color(0, 80, 160))
     .setColorBackground(color(0, 45, 90));
  currentY += spacing;

  cp5.addLabel("Width:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("counterSpiralWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(counterSpiralWidth, 1, 1))
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background
     
  // --- Toroidal Spiral Lines ---
  currentY += spacing * 1.5;
  cp5.addLabel("Toroidal Spiral Lines:") // Renamed Header
     .setPosition(10, currentY + 4).setSize(labelW + inputW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  // Add toggle for vertical spiral lines
  cp5.addToggle("drawVerticalSpiral")
     .setPosition(inputX + 10, currentY)
     .setSize(40, 20)
     .setState(drawVerticalSpiral)
     .setMode(ControlP5.SWITCH)
     .setColorActive(color(0, 80, 160))
     .setColorBackground(color(0, 45, 90));
  currentY += spacing;

  cp5.addLabel("Windings:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("verticalSpiralWindings")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+verticalSpiralWindings)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background
     
  currentY += spacing;
  cp5.addLabel("Density:") // Points along the path
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("verticalSpiralDensity")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+verticalSpiralDensity)
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  currentY += spacing;
  cp5.addLabel("Width:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColorValue(color(0)).setFont(labelFont);
  cp5.addTextfield("verticalSpiralWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(verticalSpiralWidth, 1, 1))
     .setCaptionLabel("") // Hide the default caption label
     .setColor(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue background

  // --- View Buttons with GenerativeCycloid-like styling ---
  currentY += spacing * 2;
  int viewBtnW = 60; // Use standard button width
  int viewBtnH = 25; // Slightly taller buttons
  int viewBtnSpacing = 10;
  
  cp5.addButton("viewFront")
     .setLabel("FRONT")
     .setPosition(10, currentY).setSize(viewBtnW, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
  
  cp5.addButton("viewBack")
     .setLabel("BACK")
     .setPosition(10 + viewBtnW + viewBtnSpacing, currentY).setSize(viewBtnW, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
  
  cp5.addButton("viewLeft")
     .setLabel("LEFT")
     .setPosition(10, currentY + viewBtnH + 5).setSize(viewBtnW, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
  
  cp5.addButton("viewRight")
     .setLabel("RIGHT")
     .setPosition(10 + viewBtnW + viewBtnSpacing, currentY + viewBtnH + 5).setSize(viewBtnW, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
  
  cp5.addButton("viewTop")
     .setLabel("TOP")
     .setPosition(10, currentY + (viewBtnH + 5) * 2).setSize(viewBtnW, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
  
  cp5.addButton("viewBottom")
     .setLabel("BOTTOM")
     .setPosition(10 + viewBtnW + viewBtnSpacing, currentY + (viewBtnH + 5) * 2).setSize(viewBtnW, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
  
  cp5.addButton("viewReset")
     .setLabel("RESET")
     .setPosition(10, currentY + (viewBtnH + 5) * 3).setSize(2 * viewBtnW + viewBtnSpacing, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue

  // --- Export Button ---
  currentY += (viewBtnH + 5) * 4;
  cp5.addButton("exportSVG")
     .setLabel("EXPORT SVG")
     .setPosition(10, currentY).setSize(2 * viewBtnW + viewBtnSpacing, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
     
  // --- Color Picker Toggle Button ---
  cp5.addButton("toggleColorPicker")
     .setLabel("COLOR PICKER")
     .setPosition(10, currentY + viewBtnH + 10).setSize(2 * viewBtnW + viewBtnSpacing, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(0, 45, 90)); // Dark blue
     
  // --- Rainbow Diagonals Button ---
  cp5.addButton("applyRainbowDiagonals")
     .setLabel("RAINBOW DIAGONALS")
     .setPosition(10, currentY + viewBtnH * 2 + 20).setSize(2 * viewBtnW + viewBtnSpacing, viewBtnH)
     .setColorCaptionLabel(color(255)) // White text
     .setColorBackground(color(220, 0, 100)); // Magenta for rainbow button
     
  println("Setup complete using GenerativeCycloid layout style.");
}

void draw() {
  // Handle SVG recording first
  if (recordSVG) {
    try {
      println("Creating SVG...");
      // We'll use a simplified 3D export for now
      export3DSVG(); 
      println("SVG potentially saved to: " + svgOutputPath);
      
      File outputFile = new File(svgOutputPath);
      if (outputFile.exists() && outputFile.length() > 0) {
          JOptionPane.showMessageDialog(null, "SVG exported successfully to: " + svgOutputPath, 
              "SVG Export", JOptionPane.INFORMATION_MESSAGE);
      } else {
          JOptionPane.showMessageDialog(null, "Error: SVG file was not created or is empty. Check console output and export function.", 
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
  
  // --- 3D Scene --- 
  pushMatrix(); // Isolate 3D transformations
  lights();        // Add basic lighting for 3D effect
  
  // Apply 3D camera transformations
  translate(width / 2 + transX, height / 2 + transY);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoom);
  
  // Draw the torus geometry
  drawTorusGeometry(this.g); 
  popMatrix(); // Restore previous matrix state before drawing UI

  // --- Draw UI ---
  // Reset view for UI drawing (essential after popMatrix)
  hint(DISABLE_DEPTH_TEST);
  camera(); // Reset to default camera
  noLights(); // Disable lights for UI
  cp5.draw();
  
  // Draw color picker if enabled
  if (showColorPicker) {
    drawColorPicker();
  }
  
  hint(ENABLE_DEPTH_TEST);
}

// Function to draw the torus based on enabled styles
void drawTorusGeometry(PGraphics g) {
  g.pushMatrix(); // Isolate transformations for the torus
  g.noFill();

  if (drawLongitudinal) {
    drawLongitudinalLines(g);
  }
  if (drawLatitudinal) {
    drawLatitudinalLines(g);
  }
  if (drawSpiral) {
    drawSpiralLines(g, false); // false indicates forward spiral
  }
  if (drawCounterSpiral) {
    drawSpiralLines(g, true); // true indicates counter-spiral
  }
  if (drawVerticalSpiral) {
    drawVerticalSpiralLines(g);
  }
  
  g.popMatrix(); // Restore previous matrix
}

// --- Placeholder Drawing Functions (To be implemented) ---

void drawLongitudinalLines(PGraphics g) {
  // Draw lines along the major circumference (like lines of longitude on Earth)
  if (!longitudinalRainbow) {
    g.stroke(longitudinalColor);
  }
  g.strokeWeight(longitudinalWidth);
  
  for (int i = 0; i < longitudinalDensity; i++) {
    float u = map(i, 0, longitudinalDensity, 0, TWO_PI);
    
    g.beginShape();
    for (int j = 0; j <= longitudinalDetail; j++) {
      float v = map(j, 0, longitudinalDetail, 0, TWO_PI);
      
      // If rainbow enabled, set color based on position
      if (longitudinalRainbow) {
        float colorPos = map(j, 0, longitudinalDetail, 0, 1);
        g.stroke(getRainbowColor(colorPos));
      }
      
      float x = (majorRadius + minorRadius * cos(v)) * cos(u);
      float y = (majorRadius + minorRadius * cos(v)) * sin(u);
      float z = minorRadius * sin(v);
      g.vertex(x, y, z);
    }
    g.endShape();
  }
}

void drawLatitudinalLines(PGraphics g) {
  // Draw lines around the tube cross-section (like lines of latitude on Earth)
  if (!latitudinalRainbow) {
    g.stroke(latitudinalColor);
  }
  g.strokeWeight(latitudinalWidth);

  for (int i = 0; i < latitudinalDensity; i++) {
    float v = map(i, 0, latitudinalDensity, 0, TWO_PI);
    
    g.beginShape();
    for (int j = 0; j <= latitudinalDetail; j++) {
      float u = map(j, 0, latitudinalDetail, 0, TWO_PI);
      
      // If rainbow enabled, set color based on position
      if (latitudinalRainbow) {
        float colorPos = map(j, 0, latitudinalDetail, 0, 1);
        g.stroke(getRainbowColor(colorPos));
      }
      
      float x = (majorRadius + minorRadius * cos(v)) * cos(u);
      float y = (majorRadius + minorRadius * cos(v)) * sin(u);
      float z = minorRadius * sin(v);
      g.vertex(x, y, z);
    }
    g.endShape();
  }
}

void drawSpiralLines(PGraphics g, boolean counter) {
  // Draw a spiral path wrapping around the torus
  boolean useRainbow = counter ? counterSpiralRainbow : spiralRainbow;
  
  if (!useRainbow) {
    color c = counter ? counterSpiralColor : spiralColor;
    g.stroke(c);
  }
  
  float w = counter ? counterSpiralWidth : spiralWidth;
  int windings = spiralWindings;
  float direction = counter ? -1.0 : 1.0;
  
  g.strokeWeight(w);
  g.noFill(); // Ensure spirals are not filled

  g.beginShape();
  for (int i = 0; i <= spiralDensity; i++) {
    // If rainbow enabled, set color based on position
    if (useRainbow) {
      float colorPos = map(i, 0, spiralDensity, 0, 1);
      g.stroke(getRainbowColor(colorPos));
    }
    
    float u = map(i, 0, spiralDensity, 0, TWO_PI); 
    float v = direction * u * windings; // v changes 'windings' times faster than u
    
    float x = (majorRadius + minorRadius * cos(v)) * cos(u);
    float y = (majorRadius + minorRadius * cos(v)) * sin(u);
    float z = minorRadius * sin(v);
    g.vertex(x, y, z);
  }
  g.endShape();
}

void drawVerticalSpiralLines(PGraphics g) {
  // Draw a spiral that oscillates vertically (Z) as it moves around the main ring
  if (!verticalSpiralRainbow) {
    g.stroke(verticalSpiralColor);
  }
  g.strokeWeight(verticalSpiralWidth);
  g.noFill();

  g.beginShape();
  for (int i = 0; i <= verticalSpiralDensity; i++) {
    // If rainbow enabled, set color based on position
    if (verticalSpiralRainbow) {
      float colorPos = map(i, 0, verticalSpiralDensity, 0, 1);
      g.stroke(getRainbowColor(colorPos));
    }
    
    // Let parameter t go from 0 to TWO_PI * windings, driving u directly
    float t = map(i, 0, verticalSpiralDensity, 0, TWO_PI * verticalSpiralWindings);
    
    // u controls position around the main ring (toroidal angle), cycling rapidly
    float u = t;
    // v controls position around the tube (poloidal angle), cycling slowly
    float v = t / verticalSpiralWindings;
    
    float x = (majorRadius + minorRadius * cos(v)) * cos(u);
    float y = (majorRadius + minorRadius * cos(v)) * sin(u);
    float z = minorRadius * sin(v);
    g.vertex(x, y, z);
  }
  g.endShape();
}

// Helper function to generate rainbow colors
color getRainbowColor(float position) {
  // Map position to hue (0-360)
  float hue = position * 360;
  // Using HSB color space for rainbow effect
  colorMode(HSB, 360, 100, 100);
  color c = color(hue, 100, 100);
  colorMode(RGB, 255, 255, 255); // Switch back to default
  return c;
}

// Helper class to store projected points and their style for SVG export
class StyledPolyline {
  ArrayList<PVector> points;
  color strokeColor;
  float strokeWeight;
  boolean isRainbow;
  
  StyledPolyline(color c, float w, boolean rainbow) {
    points = new ArrayList<PVector>();
    strokeColor = c;
    strokeWeight = w;
    isRainbow = rainbow;
  }
  
  void addVertex(float x, float y) {
    points.add(new PVector(x, y));
  }
}

// --- 3D SVG Export ---
void export3DSVG() {
  // Create a temporary PGraphics for projection calculations
  PGraphics pg = createGraphics(width, height, P3D);
  pg.beginDraw();
  // Apply the exact same transformations as the main draw loop
  pg.translate(width / 2 + transX, height / 2 + transY);
  pg.rotateX(rotX);
  pg.rotateY(rotY);
  pg.scale(zoom);
  
  // List to hold all styled polylines to be drawn
  ArrayList<StyledPolyline> polylinesToDraw = new ArrayList<StyledPolyline>();

  // --- Generate Longitudinal Polylines ---
  if (drawLongitudinal) {
    for (int i = 0; i < longitudinalDensity; i++) {
      float u = map(i, 0, longitudinalDensity, 0, TWO_PI);
      StyledPolyline currentPolyline = new StyledPolyline(longitudinalColor, longitudinalWidth, longitudinalRainbow);
      for (int j = 0; j <= longitudinalDetail; j++) {
        float v = map(j, 0, longitudinalDetail, 0, TWO_PI);
        float x = (majorRadius + minorRadius * cos(v)) * cos(u);
        float y = (majorRadius + minorRadius * cos(v)) * sin(u);
        float z = minorRadius * sin(v);
        // Project 3D point to 2D screen coordinates using the temporary PGraphics
        float sx = pg.screenX(x, y, z);
        float sy = pg.screenY(x, y, z);
        currentPolyline.addVertex(sx, sy);
      }
      polylinesToDraw.add(currentPolyline);
    }
  }
  
  // --- Generate Latitudinal Polylines ---
  if (drawLatitudinal) {
    for (int i = 0; i < latitudinalDensity; i++) {
      float v = map(i, 0, latitudinalDensity, 0, TWO_PI);
      StyledPolyline currentPolyline = new StyledPolyline(latitudinalColor, latitudinalWidth, latitudinalRainbow);
      for (int j = 0; j <= latitudinalDetail; j++) {
        float u = map(j, 0, latitudinalDetail, 0, TWO_PI);
        float x = (majorRadius + minorRadius * cos(v)) * cos(u);
        float y = (majorRadius + minorRadius * cos(v)) * sin(u);
        float z = minorRadius * sin(v);
        float sx = pg.screenX(x, y, z);
        float sy = pg.screenY(x, y, z);
        currentPolyline.addVertex(sx, sy);
      }
      polylinesToDraw.add(currentPolyline);
    }
  }
  
  // --- Generate Spiral Polylines ---
  if (drawSpiral) {
    StyledPolyline currentPolyline = new StyledPolyline(spiralColor, spiralWidth, spiralRainbow);
    int windings = spiralWindings;
    float direction = 1.0;
    for (int i = 0; i <= spiralDensity; i++) {
      float u = map(i, 0, spiralDensity, 0, TWO_PI); 
      float v = direction * u * windings;
      float x = (majorRadius + minorRadius * cos(v)) * cos(u);
      float y = (majorRadius + minorRadius * cos(v)) * sin(u);
      float z = minorRadius * sin(v);
      float sx = pg.screenX(x, y, z);
      float sy = pg.screenY(x, y, z);
      currentPolyline.addVertex(sx, sy);
    }
     polylinesToDraw.add(currentPolyline);
  }
  
  // --- Generate Counter-Spiral Polylines ---
   if (drawCounterSpiral) {
    StyledPolyline currentPolyline = new StyledPolyline(counterSpiralColor, counterSpiralWidth, counterSpiralRainbow);
    int windings = spiralWindings;
    float direction = -1.0; // Only difference from spiral
    for (int i = 0; i <= spiralDensity; i++) {
      float u = map(i, 0, spiralDensity, 0, TWO_PI); 
      float v = direction * u * windings;
      float x = (majorRadius + minorRadius * cos(v)) * cos(u);
      float y = (majorRadius + minorRadius * cos(v)) * sin(u);
      float z = minorRadius * sin(v);
      float sx = pg.screenX(x, y, z);
      float sy = pg.screenY(x, y, z);
      currentPolyline.addVertex(sx, sy);
    }
     polylinesToDraw.add(currentPolyline);
  }

  // --- Generate Vertical Spiral Polylines ---
  if (drawVerticalSpiral) {
    StyledPolyline currentPolyline = new StyledPolyline(verticalSpiralColor, verticalSpiralWidth, verticalSpiralRainbow);
    for (int i = 0; i <= verticalSpiralDensity; i++) {
      // Let parameter t go from 0 to TWO_PI * windings, driving u directly
      float t = map(i, 0, verticalSpiralDensity, 0, TWO_PI * verticalSpiralWindings);
      
      // u controls position around the main ring (toroidal angle), cycling rapidly
      float u = t;
      // v controls position around the tube (poloidal angle), cycling slowly
      float v = t / verticalSpiralWindings;
      
      float x = (majorRadius + minorRadius * cos(v)) * cos(u);
      float y = (majorRadius + minorRadius * cos(v)) * sin(u);
      float z = minorRadius * sin(v);
      float sx = pg.screenX(x, y, z);
      float sy = pg.screenY(x, y, z);
      currentPolyline.addVertex(sx, sy);
    }
    polylinesToDraw.add(currentPolyline);
  }

  // We are done with the temporary PGraphics for projection
  pg.endDraw();
  pg.dispose();
  
  // Now create the actual SVG file
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
  println("Writing to SVG: " + svgOutputPath);
  svg.beginDraw();
  svg.background(255); // White background for SVG
  svg.noFill();
  
  // Draw all the collected polylines to the SVG
  for (StyledPolyline poly : polylinesToDraw) {
    if (poly.points.size() > 1) { // Need at least 2 points to draw a shape
      if (poly.isRainbow) {
        // For rainbow lines, draw each segment with its own color
        for (int i = 0; i < poly.points.size() - 1; i++) {
          float colorPos = map(i, 0, poly.points.size() - 1, 0, 1);
          svg.stroke(getRainbowColor(colorPos));
          svg.strokeWeight(poly.strokeWeight);
          svg.line(poly.points.get(i).x, poly.points.get(i).y, 
                   poly.points.get(i+1).x, poly.points.get(i+1).y);
        }
      } else {
        // For solid color lines
        svg.stroke(poly.strokeColor); 
        svg.strokeWeight(poly.strokeWeight); 
        svg.beginShape();
        for (PVector p : poly.points) {
          svg.vertex(p.x, p.y); // Use the pre-projected 2D coordinates
        }
        // If the shape is naturally closed (like lat/lon lines), endShape(CLOSE)
        // For spirals, just endShape()
        // For simplicity, we'll use endShape() for all now.
        svg.endShape();
      }
    }
  }
  
  svg.endDraw();
  svg.dispose();
  println("Finished writing SVG.");
}

// --- Mouse Interaction for 3D View ---
void mousePressed() {
  // First check if we're interacting with the color picker
  if (showColorPicker) {
    // Check if clicking on a line type button
    int btnY = colorPickerY - 25;
    for (int i = 0; i < lineTypeLabels.length; i++) {
      int y = btnY + i * 25;
      if (isPointInRect(mouseX, mouseY, colorPickerX, y, sliderWidth, 20)) {
        selectedLineType = i;
        return;
      }
    }
    
    // Check if clicking on rainbow toggle
    if (isPointInRect(mouseX, mouseY, colorPickerX + 60, colorPickerY + 175, 20, 20)) {
      // Toggle rainbow state
      boolean currentState = getCurrentRainbowState();
      updateRainbowState(!currentState);
      return;
    }
    
    // Only handle color sliders if not in rainbow mode
    if (!getCurrentRainbowState()) {
      // Get current HSB values
      color currentColor = getCurrentColor();
      colorMode(HSB, 360, 100, 100);
      float hue = hue(currentColor);
      float saturation = saturation(currentColor);
      float brightness = brightness(currentColor);
      
      // Check slider handles
      float hPos = map(hue, 0, 360, 0, sliderWidth);
      float sPos = map(saturation, 0, 100, 0, sliderWidth);
      float bPos = map(brightness, 0, 100, 0, sliderWidth);
      
      if (isOverSliderHandle(hPos, colorPickerY + 120)) {
        isDraggingH = true;
        return;
      } else if (isOverSliderHandle(sPos, colorPickerY + 120 + sliderSpacing)) {
        isDraggingS = true;
        return;
      } else if (isOverSliderHandle(bPos, colorPickerY + 120 + sliderSpacing*2)) {
        isDraggingL = true;
        return;
      }
      
      // Reset color mode
      colorMode(RGB, 255, 255, 255);
    }
  }
  
  // If not interacting with color picker, use the original mousePressed logic
  // Record initial mouse position only if over the sketch window and not over a GUI element
  if (mouseX >= 0 && mouseX <= width && mouseY >= 0 && mouseY <= height && !cp5.isMouseOver()) {
     lastMouseX = mouseX;
     lastMouseY = mouseY;
  }
}

void mouseDragged() {
  if (showColorPicker && (isDraggingH || isDraggingS || isDraggingL)) {
    // Get current HSB values
    color currentColor = getCurrentColor();
    colorMode(HSB, 360, 100, 100);
    float hue = hue(currentColor);
    float saturation = saturation(currentColor);
    float brightness = brightness(currentColor);
    
    // Update based on which slider is being dragged
    if (isDraggingH) {
      hue = map(constrain(mouseX, colorPickerX, colorPickerX + sliderWidth), 
                colorPickerX, colorPickerX + sliderWidth, 0, 360);
    } else if (isDraggingS) {
      saturation = map(constrain(mouseX, colorPickerX, colorPickerX + sliderWidth), 
                       colorPickerX, colorPickerX + sliderWidth, 0, 100);
    } else if (isDraggingL) {
      brightness = map(constrain(mouseX, colorPickerX, colorPickerX + sliderWidth), 
                       colorPickerX, colorPickerX + sliderWidth, 0, 100);
    }
    
    // Update the color
    color newColor = color(hue, saturation, brightness);
    updateLineColor(newColor);
    
    // Reset color mode
    colorMode(RGB, 255, 255, 255);
    return;
  }
  
  // If not dragging color picker sliders, use the original mouseDragged logic
  if (!cp5.isMouseOver()) {
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
  if (!cp5.isMouseOver()) {
    float count = event.getCount();
    zoom *= pow(0.95, count); // Adjust zoom sensitivity
    zoom = max(0.1, zoom); // Prevent zooming too far in/out
  }
}

// --- ControlP5 Handlers (called automatically) ---

// Torus parameters
public void majorRadius(String theValue) {
  try { majorRadius = max(0.1, Float.parseFloat(theValue)); } 
  catch (NumberFormatException e) { println("Invalid majorRadius"); majorRadius = max(0.1, majorRadius); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("majorRadius")).setValue(nf(majorRadius, 1, 1)); }
}
public void minorRadius(String theValue) {
  try { minorRadius = max(0.1, Float.parseFloat(theValue)); } 
  catch (NumberFormatException e) { println("Invalid minorRadius"); minorRadius = max(0.1, minorRadius); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("minorRadius")).setValue(nf(minorRadius, 1, 1)); }
}

// Longitudinal Style Handlers
public void drawLongitudinal(boolean val) { drawLongitudinal = val; }
public void longitudinalDensity(String theValue) {
  try { longitudinalDensity = max(2, Integer.parseInt(theValue)); } 
  catch (NumberFormatException e) { println("Invalid longitudinalDensity"); longitudinalDensity = max(2, longitudinalDensity); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("longitudinalDensity")).setValue(""+longitudinalDensity); }
}
public void longitudinalWidth(String theValue) {
  try { longitudinalWidth = max(0.1, Float.parseFloat(theValue)); } 
  catch (NumberFormatException e) { println("Invalid longitudinalWidth"); longitudinalWidth = max(0.1, longitudinalWidth); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("longitudinalWidth")).setValue(nf(longitudinalWidth, 1, 1)); }
}
public void longitudinalDetail(String theValue) {
  try { longitudinalDetail = max(3, Integer.parseInt(theValue)); } // Min 3 segments for a triangle
  catch (NumberFormatException e) { println("Invalid longitudinalDetail"); longitudinalDetail = max(3, longitudinalDetail); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("longitudinalDetail")).setValue(""+longitudinalDetail); }
}
public void longitudinalRainbow(boolean val) { longitudinalRainbow = val; }

// Latitudinal Style Handlers
public void drawLatitudinal(boolean val) { drawLatitudinal = val; }
public void latitudinalDensity(String theValue) {
  try { latitudinalDensity = max(2, Integer.parseInt(theValue)); } 
  catch (NumberFormatException e) { println("Invalid latitudinalDensity"); latitudinalDensity = max(2, latitudinalDensity); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("latitudinalDensity")).setValue(""+latitudinalDensity); }
}
public void latitudinalWidth(String theValue) {
  try { latitudinalWidth = max(0.1, Float.parseFloat(theValue)); } 
  catch (NumberFormatException e) { println("Invalid latitudinalWidth"); latitudinalWidth = max(0.1, latitudinalWidth); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("latitudinalWidth")).setValue(nf(latitudinalWidth, 1, 1)); }
}
public void latitudinalDetail(String theValue) {
  try { latitudinalDetail = max(3, Integer.parseInt(theValue)); } // Min 3 segments for a triangle
  catch (NumberFormatException e) { println("Invalid latitudinalDetail"); latitudinalDetail = max(3, latitudinalDetail); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("latitudinalDetail")).setValue(""+latitudinalDetail); }
}
public void latitudinalRainbow(boolean val) { latitudinalRainbow = val; }

// Spiral Style Handlers
public void drawSpiral(boolean val) { drawSpiral = val; }
public void spiralDensity(String theValue) {
  try { spiralDensity = max(10, Integer.parseInt(theValue)); } // Need more points for smooth spiral
  catch (NumberFormatException e) { println("Invalid spiralDensity"); spiralDensity = max(10, spiralDensity); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("spiralDensity")).setValue(""+spiralDensity); }
}
public void spiralWindings(String theValue) {
  try { spiralWindings = max(1, Integer.parseInt(theValue)); } 
  catch (NumberFormatException e) { println("Invalid spiralWindings"); spiralWindings = max(1, spiralWindings); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("spiralWindings")).setValue(""+spiralWindings); }
}
public void spiralWidth(String theValue) {
  try { spiralWidth = max(0.1, Float.parseFloat(theValue)); } 
  catch (NumberFormatException e) { println("Invalid spiralWidth"); spiralWidth = max(0.1, spiralWidth); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("spiralWidth")).setValue(nf(spiralWidth, 1, 1)); }
}
public void spiralRainbow(boolean val) { spiralRainbow = val; }

// Counter-Spiral Style Handlers
public void drawCounterSpiral(boolean val) { drawCounterSpiral = val; }
public void counterSpiralWidth(String theValue) {
  try { counterSpiralWidth = max(0.1, Float.parseFloat(theValue)); } 
  catch (NumberFormatException e) { println("Invalid counterSpiralWidth"); counterSpiralWidth = max(0.1, counterSpiralWidth); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("counterSpiralWidth")).setValue(nf(counterSpiralWidth, 1, 1)); }
}
public void counterSpiralRainbow(boolean val) { counterSpiralRainbow = val; }

// Vertical Spiral Style Handlers
public void drawVerticalSpiral(boolean val) { drawVerticalSpiral = val; }
public void verticalSpiralWindings(String theValue) {
  try { verticalSpiralWindings = max(1, Integer.parseInt(theValue)); } 
  catch (NumberFormatException e) { println("Invalid verticalSpiralWindings"); verticalSpiralWindings = max(1, verticalSpiralWindings); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("verticalSpiralWindings")).setValue(""+verticalSpiralWindings); }
}
public void verticalSpiralDensity(String theValue) {
  try { verticalSpiralDensity = max(10, Integer.parseInt(theValue)); } 
  catch (NumberFormatException e) { println("Invalid verticalSpiralDensity"); verticalSpiralDensity = max(10, verticalSpiralDensity); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("verticalSpiralDensity")).setValue(""+verticalSpiralDensity); }
}
public void verticalSpiralWidth(String theValue) {
  try { verticalSpiralWidth = max(0.1, Float.parseFloat(theValue)); } 
  catch (NumberFormatException e) { println("Invalid verticalSpiralWidth"); verticalSpiralWidth = max(0.1, verticalSpiralWidth); }
  finally { if (cp5 != null) ((Textfield)cp5.getController("verticalSpiralWidth")).setValue(nf(verticalSpiralWidth, 1, 1)); }
}
public void verticalSpiralRainbow(boolean val) { verticalSpiralRainbow = val; }

// --- SVG Export Logic ---
public void exportSVG() {
  println("SVG export requested via button/key");
  if (recordSVG) { println("Export already in progress."); return; }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "Torus_" + getTimestamp() + ".svg"), this);
}

void svgFileSelected(File selection) {
  if (selection == null) { println("SVG export cancelled."); return; }
  
  svgOutputPath = selection.getAbsolutePath();
  println("Selected SVG path: " + svgOutputPath);
  
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    println("File already exists, attempting to delete: " + svgOutputPath);
    if (!outputFile.delete()) {
        println("Warning: Could not delete existing file. SVG export might fail or overwrite.");
    } else {
        println("Existing file deleted.");
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

// --- View Cube Face Handlers (Copied directly, should work) ---
public void viewFront(int theValue) { rotX = 0; rotY = 0; transX = 0; transY = 0; }
public void viewBack(int theValue) { rotX = 0; rotY = PI; transX = 0; transY = 0; }
public void viewLeft(int theValue) { rotX = 0; rotY = -HALF_PI; transX = 0; transY = 0; }
public void viewRight(int theValue) { rotX = 0; rotY = HALF_PI; transX = 0; transY = 0; }
public void viewTop(int theValue) { rotX = -HALF_PI; rotY = 0; transX = 0; transY = 0; }
public void viewBottom(int theValue) { rotX = HALF_PI; rotY = 0; transX = 0; transY = 0; }
public void viewReset(int theValue) { rotX = 0; rotY = 0; transX = 0; transY = 0; zoom = 1.0; }

// --- Color Picker Functions ---

// Toggle the color picker on/off
public void toggleColorPicker() {
  showColorPicker = !showColorPicker;
}

// Draw the color picker UI
void drawColorPicker() {
  // Draw color picker panel background
  fill(240);
  stroke(180);
  strokeWeight(1);
  rect(colorPickerX - 10, colorPickerY - 30, sliderWidth + 80, 220, 5); // Make panel taller for rainbow option
  
  // Draw line type selector buttons
  int btnX = colorPickerX;
  int btnY = colorPickerY - 25;
  int btnWidth = sliderWidth;
  int btnHeight = 20;
  
  noStroke();
  fill(0);
  textAlign(LEFT, BOTTOM);
  textSize(12);
  text("Select Line Type:", btnX, btnY - 5);
  
  for (int i = 0; i < lineTypeLabels.length; i++) {
    int y = btnY + i * 25;
    
    // Draw button background
    if (i == selectedLineType) {
      fill(0, 45, 90); // Dark blue if selected
    } else {
      fill(150); // Gray if not selected
    }
    rect(btnX, y, btnWidth, btnHeight, 5);
    
    // Draw button text
    fill(255);
    textAlign(CENTER, CENTER);
    text(lineTypeLabels[i], btnX + btnWidth/2, y + btnHeight/2);
  }
  
  // Get current HSL values for selected line type and rainbow state
  color currentColor = getCurrentColor();
  boolean isRainbow = getCurrentRainbowState();
  colorMode(HSB, 360, 100, 100); // Temporarily switch to HSB mode
  float hue = hue(currentColor);
  float saturation = saturation(currentColor);
  float brightness = brightness(currentColor);
  
  // Draw title
  fill(0);
  textAlign(LEFT, BOTTOM);
  textSize(14);
  text("Adjust Color", colorPickerX, colorPickerY + 110);
  
  // Draw color preview
  colorMode(HSB, 360, 100, 100);
  
  // If rainbow mode, draw a gradient preview instead of solid color
  if (isRainbow) {
    for (int i = 0; i < 30; i++) {
      float rainbowHue = map(i, 0, 29, 0, 360);
      fill(rainbowHue, 100, 100);
      rect(colorPickerX + sliderWidth + 20, colorPickerY + 120 + i, 30, 1);
    }
  } else {
    fill(hue, saturation, brightness);
    rect(colorPickerX + sliderWidth + 20, colorPickerY + 120, 30, sliderHeight * 3 + sliderSpacing * 2, 5);
  }
  
  // Draw Rainbow toggle
  fill(0);
  textAlign(LEFT, CENTER);
  text("Rainbow:", colorPickerX, colorPickerY + 180);
  
  // Draw rainbow toggle box
  if (isRainbow) {
    fill(120, 100, 100); // Green when on
  } else {
    fill(0, 0, 80); // Gray when off
  }
  stroke(0);
  rect(colorPickerX + 60, colorPickerY + 175, 20, 20, 5);
  if (isRainbow) {
    // Draw checkmark
    stroke(255);
    strokeWeight(2);
    line(colorPickerX + 65, colorPickerY + 185, colorPickerX + 70, colorPickerY + 190);
    line(colorPickerX + 70, colorPickerY + 190, colorPickerX + 75, colorPickerY + 180);
  }
  
  // Only draw HSB sliders if not in rainbow mode
  if (!isRainbow) {
    // Hue slider
    fill(0);
    textAlign(LEFT, CENTER);
    text("H:", colorPickerX - 15, colorPickerY + 120 + sliderHeight/2);
    
    // Draw hue slider background with gradient
    for (int i = 0; i < sliderWidth; i++) {
      float h = map(i, 0, sliderWidth, 0, 360);
      stroke(h, 100, 100);
      line(colorPickerX + i, colorPickerY + 120, colorPickerX + i, colorPickerY + 120 + sliderHeight);
    }
    noStroke();
    
    // Saturation slider
    text("S:", colorPickerX - 15, colorPickerY + 120 + sliderSpacing + sliderHeight/2);
    
    // Draw saturation slider background with gradient
    for (int i = 0; i < sliderWidth; i++) {
      float sat = map(i, 0, sliderWidth, 0, 100);
      stroke(hue, sat, brightness);
      line(colorPickerX + i, colorPickerY + 120 + sliderSpacing, colorPickerX + i, colorPickerY + 120 + sliderSpacing + sliderHeight);
    }
    noStroke();
    
    // Brightness slider
    text("B:", colorPickerX - 15, colorPickerY + 120 + sliderSpacing*2 + sliderHeight/2);
    
    // Draw brightness slider background with gradient
    for (int i = 0; i < sliderWidth; i++) {
      float bri = map(i, 0, sliderWidth, 0, 100);
      stroke(hue, saturation, bri);
      line(colorPickerX + i, colorPickerY + 120 + sliderSpacing*2, colorPickerX + i, colorPickerY + 120 + sliderSpacing*2 + sliderHeight);
    }
    noStroke();
    
    // Draw slider handles
    fill(255);
    stroke(0);
    float hPos = map(hue, 0, 360, 0, sliderWidth);
    float sPos = map(saturation, 0, 100, 0, sliderWidth);
    float bPos = map(brightness, 0, 100, 0, sliderWidth);
    
    // Hue handle
    rect(colorPickerX + hPos - 5, colorPickerY + 120 - 2, 10, sliderHeight + 4, 2);
    
    // Saturation handle
    rect(colorPickerX + sPos - 5, colorPickerY + 120 + sliderSpacing - 2, 10, sliderHeight + 4, 2);
    
    // Brightness handle
    rect(colorPickerX + bPos - 5, colorPickerY + 120 + sliderSpacing*2 - 2, 10, sliderHeight + 4, 2);
  }
  
  // Reset color mode to default RGB
  colorMode(RGB, 255, 255, 255);
}

// Get the current color for the selected line type
color getCurrentColor() {
  switch (selectedLineType) {
    case 0: return longitudinalColor;
    case 1: return latitudinalColor;
    case 2: return spiralColor;
    case 3: return counterSpiralColor;
    case 4: return verticalSpiralColor;
    default: return color(0);
  }
}

// Update the current line type's color
void updateLineColor(color newColor) {
  switch (selectedLineType) {
    case 0: longitudinalColor = newColor; break;
    case 1: latitudinalColor = newColor; break;
    case 2: spiralColor = newColor; break;
    case 3: counterSpiralColor = newColor; break;
    case 4: verticalSpiralColor = newColor; break;
  }
}

// Get the current rainbow state for the selected line type
boolean getCurrentRainbowState() {
  switch (selectedLineType) {
    case 0: return longitudinalRainbow;
    case 1: return latitudinalRainbow;
    case 2: return spiralRainbow;
    case 3: return counterSpiralRainbow;
    case 4: return verticalSpiralRainbow;
    default: return false;
  }
}

// Update the current line type's rainbow state
void updateRainbowState(boolean state) {
  switch (selectedLineType) {
    case 0: longitudinalRainbow = state; break;
    case 1: latitudinalRainbow = state; break;
    case 2: spiralRainbow = state; break;
    case 3: counterSpiralRainbow = state; break;
    case 4: verticalSpiralRainbow = state; break;
  }
}

// Check if a point is inside a rectangle
boolean isPointInRect(float px, float py, float rx, float ry, float rw, float rh) {
  return (px >= rx && px <= rx + rw && py >= ry && py <= ry + rh);
}

// Check if mouse is over a slider handle
boolean isOverSliderHandle(float handlePos, float sliderY) {
  return (mouseX >= colorPickerX + handlePos - 5 && 
          mouseX <= colorPickerX + handlePos + 5 &&
          mouseY >= sliderY - 2 && 
          mouseY <= sliderY + sliderHeight + 2);
}

// Override existing mouseReleased function to handle color picker slider release
void mouseReleased() {
  isDraggingH = false;
  isDraggingS = false;
  isDraggingL = false;
}

// --- Function to apply rainbow diagonal setup like in the example image ---
public void applyRainbowDiagonals() {
  // Turn off longitudinal and latitudinal lines
  drawLongitudinal = false;
  drawLatitudinal = false;
  
  // Configure spirals
  drawSpiral = true;
  spiralRainbow = true;
  spiralWidth = 2.0;
  spiralDensity = 500;
  spiralWindings = 5;
  
  // Configure counter-spirals
  drawCounterSpiral = true;
  counterSpiralRainbow = true;
  counterSpiralWidth = 2.0;
  
  // Update UI controls to reflect these changes
  if (cp5 != null) {
    ((Toggle)cp5.getController("drawLongitudinal")).setState(drawLongitudinal);
    ((Toggle)cp5.getController("drawLatitudinal")).setState(drawLatitudinal);
    ((Toggle)cp5.getController("drawSpiral")).setState(drawSpiral);
    ((Toggle)cp5.getController("drawCounterSpiral")).setState(drawCounterSpiral);
    
    ((Textfield)cp5.getController("spiralWidth")).setValue(nf(spiralWidth, 1, 1));
    ((Textfield)cp5.getController("counterSpiralWidth")).setValue(nf(counterSpiralWidth, 1, 1));
    ((Textfield)cp5.getController("spiralDensity")).setValue(str(spiralDensity));
    ((Textfield)cp5.getController("spiralWindings")).setValue(str(spiralWindings));
  }
  
  // Reset view to a good perspective
  viewReset(0);
  rotX = PI / 6;
  rotY = PI / 4;
  
  // Make sure the color picker reflects these changes if it's open
  if (showColorPicker) {
    selectedLineType = 2; // Select spiral line type
  }
}


