import controlP5.*;
import processing.svg.*;
import javax.swing.JOptionPane;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

ControlP5 cp5;
PFont labelFont;

// --- Simulation Grid ---
int gridWidth = 200; // Width of the simulation grid
int gridHeight = 200; // Height of the simulation grid
float[][] gridA, gridB; // Chemical concentrations
float[][] nextA, nextB; // Concentrations for the next step

// --- Simulation Parameters ---
float dA = 1.0;     // Diffusion rate for A
float dB = 0.5;     // Diffusion rate for B
float feed = 0.055; // Feed rate (f)
float kill = 0.062; // Kill rate (k)
float dt = 1.0;     // Time step
int totalSimulationSteps = 5000; // Total steps to run for the final pattern

// --- Contouring Parameters ---
float contourLevel = 0.5; // Concentration level to draw contour at
float lineWidth = 0.75;

// --- Data Structures ---
ArrayList<PVector[]> contourSegments; // Store pairs of points [start, end] for each line segment
boolean needsRestart = true;

// --- SVG Export ---
boolean recordSVG = false;
String svgOutputPath = null;

// --- Setup ---
void setup() {
  size(1000, 800); // Canvas size (larger than grid for UI)
  labelFont = createFont("Arial", 12, true);
  cp5 = new ControlP5(this);

  // Initialize grids
  gridA = new float[gridWidth][gridHeight];
  gridB = new float[gridWidth][gridHeight];
  nextA = new float[gridWidth][gridHeight];
  nextB = new float[gridWidth][gridHeight];
  contourSegments = new ArrayList<PVector[]>();

  // Create UI
  createUI();

  // Initial state
  regeneratePattern();
}

void createUI() {
  int inputX = 150;
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 28;
  int currentY = inputY;

  cp5.addLabel("Diffusion A (dA):").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("dA").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(dA, 1, 3));

  currentY += spacing;
  cp5.addLabel("Diffusion B (dB):").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("dB").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(dB, 1, 3));

  currentY += spacing;
  cp5.addLabel("Feed Rate (f):").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("feed").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(feed, 1, 3));

  currentY += spacing;
  cp5.addLabel("Kill Rate (k):").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("kill").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(kill, 1, 3));

  currentY += spacing;
  cp5.addLabel("Time Step (dt):").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("dt").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(dt, 1, 2));

  currentY += spacing;
  cp5.addLabel("Total Sim Steps:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("totalSimulationSteps").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+totalSimulationSteps);

  currentY += spacing;
  cp5.addLabel("Contour Level:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("contourLevel").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(contourLevel, 1, 3));
  
  currentY += spacing;
  cp5.addLabel("Line Width:").setPosition(10, currentY+4).setSize(130, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("lineWidth").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lineWidth, 1, 2));

  // Buttons
  currentY += spacing + 10;
  cp5.addButton("regeneratePatternButton").setLabel("Regenerate").setPosition(10, currentY).setSize(100, inputH+5);
  cp5.addButton("exportSVG").setLabel("Export SVG").setPosition(120, currentY).setSize(100, inputH+5);
}

// --- Simulation Logic ---
void regeneratePattern() {
  println("Regenerating pattern...");
  // Initialize grid A to 1.0, grid B to 0.0 everywhere
  for (int x = 0; x < gridWidth; x++) {
    for (int y = 0; y < gridHeight; y++) {
      gridA[x][y] = 1.0;
      gridB[x][y] = 0.0;
      // Initialize next state as well, just in case (though overwritten)
      nextA[x][y] = 1.0; 
      nextB[x][y] = 0.0;
    }
  }
  // Add a "seed" where A=0, B=1
  int seedSize = 10;
  int startX = gridWidth / 2 - seedSize / 2;
  int startY = gridHeight / 2 - seedSize / 2;
  for (int x = startX; x < startX + seedSize; x++) {
    for (int y = startY; y < startY + seedSize; y++) {
      if (x >= 0 && x < gridWidth && y >= 0 && y < gridHeight) {
         gridA[x][y] = 0.0; // Set A to 0 in seed area
         gridB[x][y] = 1.0; // Set B to 1 in seed area
      }
    }
  }
  
  // <<< DEBUG: Verify initial state >>>
  println("DEBUG: Center A value after seed: " + gridA[gridWidth/2][gridHeight/2]);
  println("DEBUG: Center B value after seed: " + gridB[gridWidth/2][gridHeight/2]);
  println("DEBUG: Corner A value after seed: " + gridA[0][0]);
  println("DEBUG: Corner B value after seed: " + gridB[0][0]);
  // <<< END DEBUG >>>
  
  needsRestart = false;
  contourSegments.clear(); // Clear previous contours

  // --- Run the full simulation silently ---
  println("Running " + totalSimulationSteps + " simulation steps...");
  for (int i = 0; i < totalSimulationSteps; i++) {
      updateSimulation();
      if ((i + 1) % 1000 == 0) { // Progress indicator
          print("."); 
      }
      // <<< DEBUG: Print center cell values for first 10 steps >>>
      if (i < 10) {
          int cx = gridWidth / 2;
          int cy = gridHeight / 2;
          // Print values *after* updateSimulation and *before* grid swap 
          // (i.e., the values just calculated in nextA/nextB which are now in gridA/gridB)
          println("Step " + (i+1) + " | Center A: " + gridA[cx][cy] + " | Center B: " + gridB[cx][cy]); 
      }
      // <<< END DEBUG >>>
  }
  println("\nSimulation complete.");
  
  // --- Generate contours for the final state ---
  // <<< DEBUG: Check final grid B min/max >>>
  float minB = 2.0; // Start high
  float maxB = -1.0; // Start low
  for (int x = 0; x < gridWidth; x++) {
    for (int y = 0; y < gridHeight; y++) {
      if (gridB[x][y] < minB) minB = gridB[x][y];
      if (gridB[x][y] > maxB) maxB = gridB[x][y];
    }
  }
  println("DEBUG: Final gridB min = " + minB + ", max = " + maxB);
  // <<< END DEBUG >>>
  
  println("Generating contours...");
  generateContours();
  println("Contouring complete. Found " + contourSegments.size() + " segments.");
}

// Calculate Laplacian using a 3x3 kernel with wrapping edges
float laplacianA(int x, int y) {
  float sumA = 0;
  sumA += gridA[x][y] * -1.0; // Center
  sumA += gridA[(x + 1 + gridWidth) % gridWidth][y] * 0.2; // Right
  sumA += gridA[(x - 1 + gridWidth) % gridWidth][y] * 0.2; // Left
  sumA += gridA[x][(y + 1 + gridHeight) % gridHeight] * 0.2; // Down
  sumA += gridA[x][(y - 1 + gridHeight) % gridHeight] * 0.2; // Up
  sumA += gridA[(x + 1 + gridWidth) % gridWidth][(y + 1 + gridHeight) % gridHeight] * 0.05; // Down-Right
  sumA += gridA[(x - 1 + gridWidth) % gridWidth][(y + 1 + gridHeight) % gridHeight] * 0.05; // Down-Left
  sumA += gridA[(x + 1 + gridWidth) % gridWidth][(y - 1 + gridHeight) % gridHeight] * 0.05; // Up-Right
  sumA += gridA[(x - 1 + gridWidth) % gridWidth][(y - 1 + gridHeight) % gridHeight] * 0.05; // Up-Left
  return sumA;
}

float laplacianB(int x, int y) {
  float sumB = 0;
  sumB += gridB[x][y] * -1.0; // Center
  sumB += gridB[(x + 1 + gridWidth) % gridWidth][y] * 0.2; // Right
  sumB += gridB[(x - 1 + gridWidth) % gridWidth][y] * 0.2; // Left
  sumB += gridB[x][(y + 1 + gridHeight) % gridHeight] * 0.2; // Down
  sumB += gridB[x][(y - 1 + gridHeight) % gridHeight] * 0.2; // Up
  sumB += gridB[(x + 1 + gridWidth) % gridWidth][(y + 1 + gridHeight) % gridHeight] * 0.05; // Down-Right
  sumB += gridB[(x - 1 + gridWidth) % gridWidth][(y + 1 + gridHeight) % gridHeight] * 0.05; // Down-Left
  sumB += gridB[(x + 1 + gridWidth) % gridWidth][(y - 1 + gridHeight) % gridHeight] * 0.05; // Up-Right
  sumB += gridB[(x - 1 + gridWidth) % gridWidth][(y - 1 + gridHeight) % gridHeight] * 0.05; // Up-Left
  return sumB;
}

void updateSimulation() {
  // Calculate next state based on current state
  for (int x = 0; x < gridWidth; x++) {
    for (int y = 0; y < gridHeight; y++) {
      float a = gridA[x][y];
      float b = gridB[x][y];
      float lapA = laplacianA(x, y);
      float lapB = laplacianB(x, y);
      float reaction = a * b * b;

      nextA[x][y] = a + (dA * lapA - reaction + feed * (1 - a)) * dt;
      nextB[x][y] = b + (dB * lapB + reaction - (kill + feed) * b) * dt;
      
      // Clamp values (optional but often needed)
      nextA[x][y] = constrain(nextA[x][y], 0, 1);
      nextB[x][y] = constrain(nextB[x][y], 0, 1);
    }
  }

  // Swap grids
  float[][] tempA = gridA;
  gridA = nextA;
  nextA = tempA;

  float[][] tempB = gridB;
  gridB = nextB;
  nextB = tempB;
}

// --- Contouring Logic (Basic Marching Squares adaptation) ---
void generateContours() {
  contourSegments.clear();
  float scaleX = (float)width / gridWidth;
  float scaleY = (float)height / gridHeight;

  for (int x = 0; x < gridWidth - 1; x++) {
    for (int y = 0; y < gridHeight - 1; y++) {
      // Get values at the 4 corners of the cell
      float val00 = gridB[x][y];         // Top-left
      float val10 = gridB[x+1][y];       // Top-right
      float val11 = gridB[x+1][y+1];     // Bottom-right
      float val01 = gridB[x][y+1];       // Bottom-left
      
      // Determine which corners are above the contour level
      int squareIndex = 0;
      if (val00 > contourLevel) squareIndex |= 1;
      if (val10 > contourLevel) squareIndex |= 2;
      if (val11 > contourLevel) squareIndex |= 4;
      if (val01 > contourLevel) squareIndex |= 8;

      // Get pixel coordinates of corners
      PVector p00 = new PVector(x * scaleX, y * scaleY);
      PVector p10 = new PVector((x + 1) * scaleX, y * scaleY);
      PVector p11 = new PVector((x + 1) * scaleX, (y + 1) * scaleY);
      PVector p01 = new PVector(x * scaleX, (y + 1) * scaleY);

      // <<< DEBUG: Print when a line should be drawn >>>
      if (squareIndex > 0 && squareIndex < 15) { 
          println("DEBUG: Found non-trivial squareIndex " + squareIndex + " at ("+x+","+y+") | Values: " + nf(val00,1,2)+","+nf(val10,1,2)+","+nf(val11,1,2)+","+nf(val01,1,2) + " | Level: " + contourLevel);
      } // <<< END DEBUG >>>

      // --- Look up segments based on index (Marching Squares cases) ---
      // This is simplified; doesn't handle ambiguous cases perfectly or join segments.
      switch (squareIndex) {
          case 1: case 14: addSegment(p00, p01, val00, val01, p00, p10, val00, val10); break;
          case 2: case 13: addSegment(p00, p10, val00, val10, p10, p11, val10, val11); break;
          case 3: case 12: addSegment(p00, p01, val00, val01, p10, p11, val10, val11); break;
          case 4: case 11: addSegment(p10, p11, val10, val11, p01, p11, val01, val11); break;
          case 5:          addSegment(p00, p01, val00, val01, p01, p11, val01, val11); 
                           addSegment(p00, p10, val00, val10, p10, p11, val10, val11); break; // Ambiguous, simple split
          case 6: case 9:  addSegment(p00, p10, val00, val10, p01, p11, val01, val11); break;
          case 7: case 8:  addSegment(p00, p01, val00, val01, p01, p11, val01, val11); break;
          // case 10: see case 5 (ambiguous)
          case 10:         addSegment(p00, p10, val00, val10, p00, p01, val00, val01); 
                           addSegment(p10, p11, val10, val11, p01, p11, val01, val11); break; // Ambiguous, simple split
          // Cases 0 and 15 produce no lines
      }
    }
  }
}

// Helper to add a line segment, interpolating position along edge
PVector interpolate(PVector p1, PVector p2, float val1, float val2) {
    if (abs(val1 - val2) < 1e-6) return PVector.lerp(p1, p2, 0.5); // Avoid division by zero if values are equal
    float t = (contourLevel - val1) / (val2 - val1);
    return PVector.lerp(p1, p2, t);
}

void addSegment(PVector e1p1, PVector e1p2, float e1v1, float e1v2, 
                  PVector e2p1, PVector e2p2, float e2v1, float e2v2) {
    PVector start = interpolate(e1p1, e1p2, e1v1, e1v2);
    PVector end = interpolate(e2p1, e2p2, e2v1, e2v2);
    contourSegments.add(new PVector[]{start, end});
}


// --- Drawing Loop ---
void draw() {
  if (recordSVG) {
    exportToSVG();
    recordSVG = false;
  }

  if (needsRestart) {
    regeneratePattern();
  }
  
  background(255);

  // Optional: Draw the raw grid for debugging
  loadPixels();
  float scaleX = (float)width / gridWidth;
  float scaleY = (float)height / gridHeight;
  for (int x = 0; x < gridWidth; x++) {
    for (int y = 0; y < gridHeight; y++) {
      // Map chemical B concentration to color (e.g., grayscale)
      int c = color(gridB[x][y] * 255);
      // Fill rectangle corresponding to grid cell
      fill(c); 
      noStroke();
      rect(x * scaleX, y * scaleY, scaleX, scaleY);
    }
  }
  updatePixels();
  

  // Draw contour lines
  stroke(0);
  strokeWeight(lineWidth);
  for (PVector[] segment : contourSegments) {
    line(segment[0].x, segment[0].y, segment[1].x, segment[1].y);
  }
  
  // Draw GUI (No need for camera/ortho/hints in 2D renderer)
  cp5.draw();
}

// --- SVG Export Logic ---
void exportToSVG() {
  if (svgOutputPath == null) {
    selectOutput("Save SVG as...", "svgFileSelected", 
      new File(sketchPath(""), "ReactionDiffusion_" + getTimestamp() + ".svg"), this);
    return; // Wait for file selection
  }
  
  println("Creating SVG...");
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
  
  svg.beginDraw();
  svg.background(255); // Ensure SVG background is white
  svg.stroke(0);       // Black lines for SVG
  svg.strokeWeight(lineWidth);
  svg.noFill();
  
  // Draw the contour segments to SVG
  for (PVector[] segment : contourSegments) {
    svg.line(segment[0].x, segment[0].y, segment[1].x, segment[1].y);
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
public void dA(String val) { try { dA = Float.parseFloat(val); needsRestart=true;} catch (NumberFormatException e){println("Invalid dA");} finally { if(cp5!=null)((Textfield)cp5.getController("dA")).setValue(nf(dA,1,3));} }
public void dB(String val) { try { dB = Float.parseFloat(val); needsRestart=true;} catch (NumberFormatException e){println("Invalid dB");} finally { if(cp5!=null)((Textfield)cp5.getController("dB")).setValue(nf(dB,1,3));} }
public void feed(String val) { try { feed = Float.parseFloat(val); needsRestart=true;} catch (NumberFormatException e){println("Invalid feed");} finally { if(cp5!=null)((Textfield)cp5.getController("feed")).setValue(nf(feed,1,3));} }
public void kill(String val) { try { kill = Float.parseFloat(val); needsRestart=true;} catch (NumberFormatException e){println("Invalid kill");} finally { if(cp5!=null)((Textfield)cp5.getController("kill")).setValue(nf(kill,1,3));} }
public void dt(String val) { try { dt = Float.parseFloat(val); needsRestart=true;} catch (NumberFormatException e){println("Invalid dt");} finally { if(cp5!=null)((Textfield)cp5.getController("dt")).setValue(nf(dt,1,2));} }
public void totalSimulationSteps(String val) { try { totalSimulationSteps = max(1, Integer.parseInt(val)); needsRestart=true;} catch (NumberFormatException e){println("Invalid steps");} finally { if(cp5!=null)((Textfield)cp5.getController("totalSimulationSteps")).setValue(""+totalSimulationSteps);} }
public void contourLevel(String val) { try { contourLevel = Float.parseFloat(val); needsRestart=true;} catch (NumberFormatException e){println("Invalid level");} finally { if(cp5!=null)((Textfield)cp5.getController("contourLevel")).setValue(nf(contourLevel,1,3));} }
public void lineWidth(String val) { try { lineWidth = max(0.1, Float.parseFloat(val)); } catch (NumberFormatException e){println("Invalid width");} finally { if(cp5!=null)((Textfield)cp5.getController("lineWidth")).setValue(nf(lineWidth,1,2));} }

// --- Button Handlers & Helpers ---
public void regeneratePatternButton(int theValue) { needsRestart = true; }

public void exportSVG(int theValue) {
  if (needsRestart) {
      println("Regenerating before export...");
      regeneratePattern();
  }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "ReactionDiffusion_" + getTimestamp() + ".svg"), this);
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

String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" + 
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

void keyPressed() {
  if (key == 's' || key == 'S') {
      exportSVG(0); 
  }
} 