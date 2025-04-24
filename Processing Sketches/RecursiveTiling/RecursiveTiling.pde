import controlP5.*;
import processing.svg.*;
import javax.swing.JOptionPane;
import java.io.File;
import java.util.ArrayList;

ControlP5 cp5;
PFont labelFont;

// --- Tiling Parameters ---
int initialGridCols = 4; // Initial number of columns (Used for Square mode)
int initialGridRows = 4; // Initial number of rows (Used for Square mode)
int recursionDepth = 3;  // How many levels of subdivision
boolean randomOrientation = true; // Choose tile orientation randomly? (Used for Square mode)
int arcResolution = 10; // Number of line segments per quarter-circle arc (Used for Square mode)
float lineWidth = 1.0;
int tilingMode = 0; // 0 = Square (Truchet), 1 = Triangle (Midpoint Connect)

// --- Rotation Parameters ---
int numCopies = 1;
float rotationDegrees = 0.0;

// --- Data Structures ---
ArrayList<PVector[]> pathSegments; // Store line segments [start, end]
boolean needsRegen = true;

// --- SVG Export ---
boolean recordSVG = false;
String svgOutputPath = null;

// --- Setup & UI ---
void setup() {
  size(1000, 1000); // Canvas size
  labelFont = createFont("Arial", 12, true);
  cp5 = new ControlP5(this);
  pathSegments = new ArrayList<PVector[]>();

  int inputX = 150;
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 28;
  int currentY = inputY;
  int labelW = 130;

  cp5.addLabel("Grid Columns:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("initialGridCols").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+initialGridCols);

  currentY += spacing;
  cp5.addLabel("Grid Rows:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("initialGridRows").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+initialGridRows);

  currentY += spacing;
  cp5.addLabel("Recursion Depth:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("recursionDepth").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+recursionDepth);

  currentY += spacing;
  cp5.addLabel("Arc Resolution:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("arcResolution").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+arcResolution);
  
  currentY += spacing;
  cp5.addLabel("Line Width:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("lineWidth").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lineWidth, 1, 2));

  currentY += spacing;
  cp5.addLabel("Random Orient.:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addToggle("randomOrientation").setPosition(inputX, currentY).setSize(inputW, inputH).setValue(randomOrientation).setMode(ControlP5.SWITCH);

  // Tiling Mode Selection
  currentY += spacing;
  cp5.addLabel("Tiling Mode:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  RadioButton r = cp5.addRadioButton("tilingMode")
                     .setPosition(inputX, currentY)
                     .setSize(inputW + 20, inputH) // Wider for two buttons
                     .setItemsPerRow(2)
                     .setSpacingColumn(25) 
                     .addItem("Square", 0)
                     .addItem("Triangle", 1);
  if (tilingMode == 0) r.activate(0); else r.activate(1);

  // Rotation Parameters
  currentY += spacing;
  cp5.addLabel("Num Rot. Copies:").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("numCopies").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+numCopies);
  
  currentY += spacing;
  cp5.addLabel("Rotation (Deg):").setPosition(10, currentY+4).setSize(labelW, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("rotationDegrees").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(rotationDegrees, 1, 1));

  // Buttons
  currentY += spacing + 10;
  cp5.addButton("regeneratePatternButton").setLabel("Regenerate").setPosition(10, currentY).setSize(100, inputH+5);
  cp5.addButton("exportSVG").setLabel("Export SVG").setPosition(120, currentY).setSize(100, inputH+5);
}

// --- Pattern Generation ---
void regeneratePattern() {
  println("Generating Tiling... Mode: " + (tilingMode == 0 ? "Square" : "Triangle"));
  pathSegments = new ArrayList<PVector[]>();
  initialGridCols = max(1, initialGridCols);
  initialGridRows = max(1, initialGridRows);
  recursionDepth = max(0, recursionDepth);
  arcResolution = max(2, arcResolution); // Used in Square mode

  if (tilingMode == 0) { // Square Mode
    float tileWidth = (float)width / initialGridCols;
    float tileHeight = (float)height / initialGridRows;
    for (int r = 0; r < initialGridRows; r++) {
      for (int c = 0; c < initialGridCols; c++) {
        subdivideAndDrawRect(c * tileWidth, r * tileHeight, tileWidth, tileHeight, recursionDepth);
      }
    }
  } else { // Triangle Mode
    // Calculate vertices for one large equilateral triangle centered
    float side = min(width, height) * 0.95; // Size based on canvas dimensions
    float triHeight = side * sqrt(3.0) / 2.0;
    float centerX = width / 2.0;
    float centerY = height / 2.0;
    
    PVector top = new PVector(centerX, centerY - triHeight / 2.0 + triHeight * 0.1); // Shift up slightly
    PVector bottomLeft = new PVector(centerX - side / 2.0, centerY + triHeight / 2.0 + triHeight * 0.1);
    PVector bottomRight = new PVector(centerX + side / 2.0, centerY + triHeight / 2.0 + triHeight * 0.1);

    subdivideAndDrawTriangle(top, bottomLeft, bottomRight, recursionDepth);
  }

  needsRegen = false;
  println("Tiling generated with " + pathSegments.size() + " segments.");
}

// Recursive subdivision function for RECTANGLES
void subdivideAndDrawRect(float x, float y, float w, float h, int depth) {
  if (depth <= 0) {
    // Base case: draw the Truchet tile pattern
    drawRectTile(x, y, w, h);
  } else {
    // Recursive step: divide into four quadrants
    float w2 = w / 2.0;
    float h2 = h / 2.0;
    subdivideAndDrawRect(x,    y,    w2, h2, depth - 1); // Top-left
    subdivideAndDrawRect(x + w2, y,    w2, h2, depth - 1); // Top-right
    subdivideAndDrawRect(x,    y + h2, w2, h2, depth - 1); // Bottom-left
    subdivideAndDrawRect(x + w2, y + h2, w2, h2, depth - 1); // Bottom-right
  }
}

// Draws one of two Truchet patterns in the given RECTANGLE
void drawRectTile(float x, float y, float w, float h) {
  float midX = x + w / 2.0;
  float midY = y + h / 2.0;
  float radius = min(w, h) / 2.0; // Use min radius for non-square rects

  boolean typeA; // Determines which orientation
  if (randomOrientation) {
    typeA = random(1) < 0.5;
  } else {
    // Simple deterministic pattern based on grid position (can be made more complex)
    typeA = ((int)(x / w + y / h)) % 2 == 0;
  }

  if (typeA) {
    // Type A: Top-Left corner arc & Bottom-Right corner arc
    // Arc from top-mid (x+w/2, y) to left-mid (x, y+h/2) centered at (x, y)
    addArc(x, y, radius, radians(90), radians(180)); // Top-Left corner center
    // Arc from right-mid (x+w, y+h/2) to bottom-mid (x+w/2, y+h) centered at (x+w, y+h)
    addArc(x + w, y + h, radius, radians(270), radians(360)); // Bottom-Right corner center
  } else {
    // Type B: Top-Right corner arc & Bottom-Left corner arc
    // Arc from top-mid (x+w/2, y) to right-mid (x+w, y+h/2) centered at (x+w, y)
    addArc(x + w, y, radius, radians(0), radians(90)); // Top-Right corner center
    // Arc from left-mid (x, y+h/2) to bottom-mid (x+w/2, y+h) centered at (x, y+h)
    addArc(x, y + h, radius, radians(180), radians(270)); // Bottom-Left corner center
  }
}

// Recursive subdivision function for TRIANGLES
void subdivideAndDrawTriangle(PVector v1, PVector v2, PVector v3, int depth) {
  if (depth <= 0) {
    // Base case: draw the triangle pattern
    drawTriangleTile(v1, v2, v3);
  } else {
    // Recursive step: Calculate midpoints and divide into four triangles
    PVector m1 = PVector.lerp(v1, v2, 0.5);
    PVector m2 = PVector.lerp(v2, v3, 0.5);
    PVector m3 = PVector.lerp(v3, v1, 0.5);
    
    // Recursively subdivide the four new triangles
    subdivideAndDrawTriangle(v1, m1, m3, depth - 1); // Corner 1
    subdivideAndDrawTriangle(m1, v2, m2, depth - 1); // Corner 2
    subdivideAndDrawTriangle(m3, m2, v3, depth - 1); // Corner 3
    subdivideAndDrawTriangle(m1, m2, m3, depth - 1); // Center triangle
  }
}

// Draws the pattern within the smallest TRIANGLE (connects midpoints)
void drawTriangleTile(PVector v1, PVector v2, PVector v3) {
  // Calculate midpoints
  PVector m1 = PVector.lerp(v1, v2, 0.5);
  PVector m2 = PVector.lerp(v2, v3, 0.5);
  PVector m3 = PVector.lerp(v3, v1, 0.5);
  
  // Add line segments connecting the midpoints to the path list
  addSegment(m1, m2);
  addSegment(m2, m3);
  addSegment(m3, m1);
}

// Helper to add a line segment to the main list
void addSegment(PVector p1, PVector p2) {
  pathSegments.add(new PVector[]{p1.copy(), p2.copy()});
}

// Helper to generate line segments for an arc and add them
void addArc(float centerX, float centerY, float radius, float startAngleRad, float endAngleRad) {
  PVector p1 = null, p2 = null;
  for (int i = 0; i <= arcResolution; i++) {
    float angle = lerp(startAngleRad, endAngleRad, (float)i / arcResolution);
    p2 = new PVector(centerX + radius * cos(angle), centerY + radius * sin(angle));
    if (p1 != null) {
      // Add segment to the list
      addSegment(p1, p2);
    }
    p1 = p2;
  }
}

// --- Drawing Loop ---
void draw() {
  if (recordSVG) {
    exportToSVG();
    recordSVG = false;
  }

  if (needsRegen) {
    regeneratePattern();
  }

  background(255); // White background

  // Draw the generated path segments (potentially multiple rotated copies)
  if (pathSegments != null) {
    stroke(0);
    strokeWeight(lineWidth);
    noFill(); // Important for line art
    
    float centerX = width / 2.0;
    float centerY = height / 2.0;

    for (int i = 0; i < numCopies; i++) {
        pushMatrix(); // Isolate transformations for this copy
        translate(centerX, centerY); // Move origin to center
        rotate(radians(i * rotationDegrees)); // Rotate
        translate(-centerX, -centerY); // Move origin back
        
        // Draw all segments for this transformed copy
        for (PVector[] segment : pathSegments) {
          line(segment[0].x, segment[0].y, segment[1].x, segment[1].y);
        }
        
        popMatrix(); // Restore previous matrix state
    }
  }
  
  // Draw GUI
  resetMatrix(); // Draw GUI in screen space
  cp5.draw();
}

// --- SVG Export Logic ---
void exportToSVG() {
   if (needsRegen) {
      println("Regenerating before export...");
      regeneratePattern();
   }
   if (svgOutputPath == null) {
    selectOutput("Save SVG as...", "svgFileSelected", 
      new File(sketchPath(""), "Tiling_" + getTimestamp() + ".svg"), this);
    return; // Wait for file selection
  }
  
  println("Creating SVG...");
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
  
  svg.beginDraw();
  svg.background(255); 
  svg.stroke(0);       
  svg.strokeWeight(lineWidth);
  svg.noFill();
  
  // Draw the path segments to SVG with rotations
  if (pathSegments != null) {
    float centerX = width / 2.0;
    float centerY = height / 2.0;

    for (int i = 0; i < numCopies; i++) {
        svg.pushMatrix(); // Isolate transformations for this copy
        svg.translate(centerX, centerY); // Move origin to center
        svg.rotate(radians(i * rotationDegrees)); // Rotate
        svg.translate(-centerX, -centerY); // Move origin back
        
        // Draw all segments for this transformed copy
        for (PVector[] segment : pathSegments) {
          svg.line(segment[0].x, segment[0].y, segment[1].x, segment[1].y);
        }
        
        svg.popMatrix(); // Restore previous matrix state
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
public void initialGridCols(String val) { try { initialGridCols = max(1, Integer.parseInt(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("initialGridCols")).setValue(""+initialGridCols);} }
public void initialGridRows(String val) { try { initialGridRows = max(1, Integer.parseInt(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("initialGridRows")).setValue(""+initialGridRows);} }
public void recursionDepth(String val) { try { recursionDepth = max(0, Integer.parseInt(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("recursionDepth")).setValue(""+recursionDepth);} }
public void arcResolution(String val) { try { arcResolution = max(2, Integer.parseInt(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("arcResolution")).setValue(""+arcResolution);} }
public void lineWidth(String val) { try { lineWidth = max(0.1, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("lineWidth")).setValue(nf(lineWidth,1,2));} }
public void randomOrientation(boolean val) { randomOrientation = val; needsRegen=true;}

// Handler for the RadioButton
public void tilingMode(int val) {
    tilingMode = val;
    needsRegen = true;
    println("Tiling mode set to: " + (val == 0 ? "Square" : "Triangle"));
}

// Handlers for Rotation Parameters (Don't trigger regen)
public void numCopies(String val) { try { numCopies = max(1, Integer.parseInt(val)); } catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("numCopies")).setValue(""+numCopies);} }
public void rotationDegrees(String val) { try { rotationDegrees = Float.parseFloat(val); } catch (NumberFormatException e){} finally { if(cp5!=null)((Textfield)cp5.getController("rotationDegrees")).setValue(nf(rotationDegrees,1,1));} }

// --- Button Handlers & Helpers ---
public void regeneratePatternButton(int theValue) { needsRegen = true; }

public void exportSVG(int theValue) { // Button handler
  if (needsRegen) {
      println("Regenerating before export...");
      regeneratePattern();
  }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "Tiling_" + getTimestamp() + ".svg"), this);
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