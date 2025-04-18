import java.util.ArrayList;
import controlP5.*; // Import ControlP5 library
import processing.svg.*; // Import SVG library
import javax.swing.JOptionPane; // For message dialogs
import java.io.File; // Import File class

ControlP5 cp5;
boolean recordSVG = false; // Flag to trigger SVG export
String svgOutputPath = null; // Path for SVG output
PFont labelFont; // Font for the labels

// Pattern parameters
int numCircles = 4; // Number of primary circles (4-5 in reference image)
float circleRadius = 200; // Base radius for the primary circles
float circleDistanceFromCenter = 250; // Distance of circles from center
int pointsPerCircle = 24; // Number of points around each circle
int connectionsPerPoint = 8; // How many connections each point makes
float curveTension = 0.3; // How curved the connecting lines are (0 = straight, 1 = very curved)
int lineColor = 0; // Black
int backgroundColor = 255; // White
float lineWeight = 0.5; // Thickness of the lines
int density = 50; // Density of connecting lines (higher = more lines)
boolean drawPrimaryCircles = false; // Whether to draw the primary circles
boolean useAlpha = true; // Whether to use alpha (transparency) for overlapping lines
int lineAlpha = 100; // Alpha value for lines (0-255)
float connectionBias = 0.7; // Bias towards connecting points on different circles (0-1)
int lineMode = 0; // 0 = quadratic curves, 1 = straight lines, 2 = bezier curves

// Data structures for pattern
ArrayList<PVector> circlePositions; // Position of each primary circle
ArrayList<ArrayList<PVector>> pointPositions; // Points on each circle
boolean needsRedraw = true; // Flag to track if pattern needs to be regenerated
PGraphics patternBuffer; // Buffer to store the drawn pattern
ArrayList<Connection> connections; // Store all connections between points

// Connection class to store line data
class Connection {
  int sourceCircle;
  int sourcePoint;
  int targetCircle;
  int targetPoint;
  
  Connection(int sc, int sp, int tc, int tp) {
    sourceCircle = sc;
    sourcePoint = sp;
    targetCircle = tc;
    targetPoint = tp;
  }
}

void setup() {
  size(1200, 800); // Set canvas size
  
  patternBuffer = createGraphics(width, height); // Create buffer for the pattern
  cp5 = new ControlP5(this); // Initialize ControlP5
  
  // Create a larger font for labels
  labelFont = createFont("Arial", 14, true);
  
  // Create Textfields and link them to variables
  int inputX = 180; // Increased X for longer labels
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 30;
  int currentY = inputY; // Use a separate variable for layout
  
  // Number of primary circles
  cp5.addLabel("Number of Circles:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("numCircles")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+numCircles);

  currentY += spacing;
  cp5.addLabel("Circle Radius:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("circleRadius")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(circleRadius, 1, 0));
     
  currentY += spacing;
  cp5.addLabel("Distance from Center:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("circleDistanceFromCenter")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(circleDistanceFromCenter, 1, 0));

  currentY += spacing;
  cp5.addLabel("Points per Circle:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("pointsPerCircle")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+pointsPerCircle);

  currentY += spacing;
  cp5.addLabel("Connections per Point:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("connectionsPerPoint")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+connectionsPerPoint);

  currentY += spacing;
  cp5.addLabel("Curve Tension:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("curveTension")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(curveTension, 1, 1));

  currentY += spacing;
  cp5.addLabel("Line Weight:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("lineWeight")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(lineWeight, 1, 1));

  currentY += spacing;
  cp5.addLabel("Density:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("density")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+density);

  currentY += spacing;
  cp5.addToggle("drawPrimaryCircles")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setValue(drawPrimaryCircles)
     .setMode(ControlP5.SWITCH);
     
  cp5.addLabel("Draw Primary Circles:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);

  // Line Alpha
  currentY += spacing;
  cp5.addLabel("Line Alpha (0-255):")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("lineAlpha")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+lineAlpha);

  // Use Alpha toggle  
  currentY += spacing;
  cp5.addToggle("useAlpha")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setValue(useAlpha)
     .setMode(ControlP5.SWITCH);
     
  cp5.addLabel("Use Transparency:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);

  // Connection Bias  
  currentY += spacing;
  cp5.addLabel("Connection Bias:")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("connectionBias")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(nf(connectionBias, 1, 1));

  // Line Mode
  currentY += spacing;
  cp5.addLabel("Line Mode (0-2):")
     .setPosition(10, currentY + 4)
     .setSize(160, inputH)
     .setColor(color(0))
     .setFont(labelFont);
     
  cp5.addTextfield("lineMode")
     .setPosition(inputX, currentY)
     .setSize(inputW, inputH)
     .setAutoClear(false)
     .setValue(""+lineMode);

  // --- Regenerate Button ---
  currentY += spacing + 10; // Add extra space before button
  cp5.addButton("regenerateButton")
     .setLabel("Regenerate")
     .setPosition(10, currentY)
     .setSize(100, inputH + 5);

  // --- SVG Export Button ---
  cp5.addButton("exportSVG")
     .setLabel("Export SVG")
     .setPosition(120, currentY)
     .setSize(100, inputH + 5);

  // Initialize data structures and generate initial pattern
  circlePositions = new ArrayList<PVector>();
  pointPositions = new ArrayList<ArrayList<PVector>>();
  connections = new ArrayList<Connection>();
  regeneratePattern(); 
}

void regeneratePattern() {
  println("Regenerating pattern...");
  
  // Clear existing data
  circlePositions.clear();
  pointPositions.clear();
  
  // Initialize connections list
  connections = new ArrayList<Connection>();
  
  // Validate parameters
  numCircles = max(1, numCircles);
  pointsPerCircle = max(3, pointsPerCircle);
  connectionsPerPoint = max(1, min(connectionsPerPoint, numCircles * pointsPerCircle - 1));
  
  // Position primary circles around the center
  float centerX = width / 2.0;
  float centerY = height / 2.0;
  
  for (int i = 0; i < numCircles; i++) {
    float angle = map(i, 0, numCircles, 0, TWO_PI);
    float x = centerX + cos(angle) * circleDistanceFromCenter;
    float y = centerY + sin(angle) * circleDistanceFromCenter;
    circlePositions.add(new PVector(x, y));
    
    // Create points around this circle
    ArrayList<PVector> points = new ArrayList<PVector>();
    for (int j = 0; j < pointsPerCircle; j++) {
      float pointAngle = map(j, 0, pointsPerCircle, 0, TWO_PI);
      float pointX = x + cos(pointAngle) * circleRadius;
      float pointY = y + sin(pointAngle) * circleRadius;
      points.add(new PVector(pointX, pointY));
    }
    pointPositions.add(points);
  }
  
  // Generate connections between points
  generateConnections();
  
  // Set flag to indicate pattern needs to be redrawn
  needsRedraw = true;
}

// New method to generate connections once
void generateConnections() {
  connections.clear();
  boolean[][] connectionMap = new boolean[numCircles * pointsPerCircle][numCircles * pointsPerCircle];
  
  for (int i = 0; i < numCircles; i++) {
    for (int j = 0; j < pointsPerCircle; j++) {
      int p1Index = i * pointsPerCircle + j;
      
      // Determine how many connections this point should make
      int actualConnections = floor(connectionsPerPoint * density / 50.0);
      actualConnections = max(1, actualConnections);
      
      // Create a list of potential target points weighted by connection bias
      ArrayList<Integer> potentialTargets = new ArrayList<Integer>();
      
      for (int tc = 0; tc < numCircles; tc++) {
        // Weight based on whether this is the same circle or different
        float weight = (tc == i) ? (1.0 - connectionBias) : connectionBias;
        
        // Add weighted entries to the potential targets list
        int numEntries = ceil(weight * pointsPerCircle * 10);
        for (int w = 0; w < numEntries; w++) {
          potentialTargets.add(tc);
        }
      }
      
      // Create connections from this point to other points
      int attemptedConnections = 0;
      int successfulConnections = 0;
      
      while (successfulConnections < actualConnections && attemptedConnections < actualConnections * 5) {
        attemptedConnections++;
        
        // Select another circle based on weighted distribution
        int targetCircleIndex = potentialTargets.get(floor(random(potentialTargets.size())));
        
        // Select a random point on that circle
        int targetPoint = floor(random(pointsPerCircle));
        int p2Index = targetCircleIndex * pointsPerCircle + targetPoint;
        
        // Skip if connecting to itself or already connected
        if (p1Index == p2Index || connectionMap[p1Index][p2Index]) {
          continue;
        }
        
        // Mark connection as used
        connectionMap[p1Index][p2Index] = true;
        connectionMap[p2Index][p1Index] = true; // Symmetrical
        
        successfulConnections++;
        
        // Store the connection
        connections.add(new Connection(i, j, targetCircleIndex, targetPoint));
      }
    }
  }
}

void draw() {
  // Main drawing
  background(backgroundColor);
  
  if (!recordSVG) {
    // Only redraw the pattern when needed
    if (needsRedraw) {
      patternBuffer.beginDraw();
      patternBuffer.background(backgroundColor);
      drawPattern(patternBuffer);
      patternBuffer.endDraw();
      needsRedraw = false;
    }
    
    // Always display the pattern buffer
    image(patternBuffer, 0, 0);
    
    // Draw UI controls on top
    cp5.draw();
  } else {
    try {
      println("Creating SVG...");
      
      // Create a new PGraphicsSVG object
      PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
      
      // Begin drawing to the SVG
      svg.beginDraw();
      svg.background(backgroundColor);
      
      // Draw the pattern to the SVG
      drawPattern(svg);
      
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

void drawPattern(PGraphics g) {
  // Set stroke properties based on settings
  g.strokeWeight(lineWeight);
  
  if (useAlpha) {
    g.stroke(lineColor, lineAlpha);
  } else {
    g.stroke(lineColor);
  }
  
  g.noFill();
  
  // Draw primary circles if enabled
  if (drawPrimaryCircles) {
    for (int i = 0; i < numCircles; i++) {
      PVector center = circlePositions.get(i);
      g.ellipse(center.x, center.y, circleRadius * 2, circleRadius * 2);
    }
  }
  
  // Center point for bezier control points
  PVector center = new PVector(width / 2.0, height / 2.0);
  
  // Draw all stored connections
  for (Connection conn : connections) {
    PVector p1 = pointPositions.get(conn.sourceCircle).get(conn.sourcePoint);
    PVector p2 = pointPositions.get(conn.targetCircle).get(conn.targetPoint);
    
    // Draw the line according to the selected mode
    switch (lineMode) {
      case 0: // Quadratic curve
        drawQuadraticCurve(g, p1, p2, center, curveTension);
        break;
      case 1: // Straight line
        g.line(p1.x, p1.y, p2.x, p2.y);
        break;
      case 2: // Bezier curve
        drawBezierCurve(g, p1, p2, center, curveTension);
        break;
    }
  }
}

// Helper methods for different curve types
void drawQuadraticCurve(PGraphics g, PVector p1, PVector p2, PVector centerRef, float tension) {
  // Calculate midpoint
  PVector mid = PVector.add(p1, p2).mult(0.5);
  
  // Calculate offset from center, controlled by tension
  PVector centerOffset = PVector.sub(centerRef, mid).mult(tension);
  
  // Draw curve
  g.beginShape();
  g.vertex(p1.x, p1.y);
  g.quadraticVertex(
    mid.x + centerOffset.x, 
    mid.y + centerOffset.y, 
    p2.x, p2.y
  );
  g.endShape();
}

void drawBezierCurve(PGraphics g, PVector p1, PVector p2, PVector centerRef, float tension) {
  // Calculate distance and perpendicular vectors for control points
  PVector diff = PVector.sub(p2, p1);
  float len = diff.mag() * 0.3 * tension;
  
  // Create perpendicular vector
  PVector perp = new PVector(-diff.y, diff.x).normalize().mult(len);
  
  // Direction of bend based on position relative to center
  PVector toCenter1 = PVector.sub(centerRef, p1);
  PVector toCenter2 = PVector.sub(centerRef, p2);
  float dot1 = perp.dot(toCenter1);
  float dot2 = perp.dot(toCenter2);
  
  // Use dot products to determine which direction the curve should bend
  if ((dot1 < 0 && dot2 < 0) || (dot1 > 0 && dot2 > 0)) {
    perp.mult(-1);
  }
  
  // Calculate control points
  PVector ctrl1 = PVector.add(p1, PVector.add(diff.copy().normalize().mult(len), perp));
  PVector ctrl2 = PVector.add(p2, PVector.sub(diff.copy().normalize().mult(-len), perp));
  
  // Draw curve
  g.beginShape();
  g.vertex(p1.x, p1.y);
  g.bezierVertex(
    ctrl1.x, ctrl1.y,
    ctrl2.x, ctrl2.y,
    p2.x, p2.y
  );
  g.endShape();
}

// Event handlers for UI elements
public void numCircles(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    if (newValue != numCircles) {
      numCircles = max(1, newValue);
      regeneratePattern();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for numCircles: " + theValue);
    ((Textfield)cp5.getController("numCircles")).setValue(""+numCircles);
  }
}

public void circleRadius(String theValue) {
  try {
    float newValue = Float.parseFloat(theValue);
    if (newValue != circleRadius) {
      circleRadius = max(10, newValue);
      regeneratePattern();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for circleRadius: " + theValue);
    ((Textfield)cp5.getController("circleRadius")).setValue(nf(circleRadius, 1, 0));
  }
}

public void circleDistanceFromCenter(String theValue) {
  try {
    float newValue = Float.parseFloat(theValue);
    if (newValue != circleDistanceFromCenter) {
      circleDistanceFromCenter = max(0, newValue);
      regeneratePattern();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for circleDistanceFromCenter: " + theValue);
    ((Textfield)cp5.getController("circleDistanceFromCenter")).setValue(nf(circleDistanceFromCenter, 1, 0));
  }
}

public void pointsPerCircle(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    if (newValue != pointsPerCircle) {
      pointsPerCircle = max(3, newValue);
      regeneratePattern();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for pointsPerCircle: " + theValue);
    ((Textfield)cp5.getController("pointsPerCircle")).setValue(""+pointsPerCircle);
  }
}

public void connectionsPerPoint(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    if (newValue != connectionsPerPoint) {
      connectionsPerPoint = max(1, newValue);
      ((Textfield)cp5.getController("connectionsPerPoint")).setValue(""+connectionsPerPoint);
      regeneratePattern(); // Regenerate pattern when connection count changes
    }
  } catch (NumberFormatException e) {
    println("Invalid input for connectionsPerPoint: " + theValue);
    ((Textfield)cp5.getController("connectionsPerPoint")).setValue(""+connectionsPerPoint);
  }
}

public void curveTension(String theValue) {
  try {
    float newValue = Float.parseFloat(theValue);
    curveTension = constrain(newValue, 0, 2);
    ((Textfield)cp5.getController("curveTension")).setValue(nf(curveTension, 1, 1));
    needsRedraw = true; // Set the flag to redraw the pattern
  } catch (NumberFormatException e) {
    println("Invalid input for curveTension: " + theValue);
    ((Textfield)cp5.getController("curveTension")).setValue(nf(curveTension, 1, 1));
  }
}

public void lineWeight(String theValue) {
  try {
    float newValue = Float.parseFloat(theValue);
    lineWeight = max(0.1, newValue);
    ((Textfield)cp5.getController("lineWeight")).setValue(nf(lineWeight, 1, 1));
    needsRedraw = true; // Set the flag to redraw the pattern
  } catch (NumberFormatException e) {
    println("Invalid input for lineWeight: " + theValue);
    ((Textfield)cp5.getController("lineWeight")).setValue(nf(lineWeight, 1, 1));
  }
}

public void density(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    density = constrain(newValue, 1, 200);
    ((Textfield)cp5.getController("density")).setValue(""+density);
    regeneratePattern(); // This changes connection counts, so regenerate
  } catch (NumberFormatException e) {
    println("Invalid input for density: " + theValue);
    ((Textfield)cp5.getController("density")).setValue(""+density);
  }
}

public void drawPrimaryCircles(boolean theValue) {
  drawPrimaryCircles = theValue;
  needsRedraw = true; // Set the flag to redraw the pattern
}

public void lineAlpha(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    lineAlpha = constrain(newValue, 1, 255);
    ((Textfield)cp5.getController("lineAlpha")).setValue(""+lineAlpha);
    needsRedraw = true; // Set the flag to redraw the pattern
  } catch (NumberFormatException e) {
    println("Invalid input for lineAlpha: " + theValue);
    ((Textfield)cp5.getController("lineAlpha")).setValue(""+lineAlpha);
  }
}

public void useAlpha(boolean theValue) {
  useAlpha = theValue;
  needsRedraw = true; // Set the flag to redraw the pattern
}

public void connectionBias(String theValue) {
  try {
    float newValue = Float.parseFloat(theValue);
    connectionBias = constrain(newValue, 0, 1);
    ((Textfield)cp5.getController("connectionBias")).setValue(nf(connectionBias, 1, 1));
    regeneratePattern(); // This affects connections, so regenerate
  } catch (NumberFormatException e) {
    println("Invalid input for connectionBias: " + theValue);
    ((Textfield)cp5.getController("connectionBias")).setValue(nf(connectionBias, 1, 1));
  }
}

public void lineMode(String theValue) {
  try {
    int newValue = Integer.parseInt(theValue);
    lineMode = constrain(newValue, 0, 2);
    ((Textfield)cp5.getController("lineMode")).setValue(""+lineMode);
    needsRedraw = true; // Set the flag to redraw the pattern
  } catch (NumberFormatException e) {
    println("Invalid input for lineMode: " + theValue);
    ((Textfield)cp5.getController("lineMode")).setValue(""+lineMode);
  }
}

// Regenerate button handler
public void regenerateButton() {
  regeneratePattern();
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
    new File(sketchPath(""), "CircleWeb_" + getTimestamp() + ".svg"), 
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

// Key pressed function for keyboard shortcuts
void keyPressed() {
  if (key == 's' || key == 'S') {
    if (!recordSVG) {
      println("Setting recordSVG flag to true");
      
      // Auto-generate a filename
      String filename = "CircleWeb_" + getTimestamp() + ".svg";
      svgOutputPath = sketchPath(filename);
      recordSVG = true;
    }
  } else if (key == 'r' || key == 'R') {
    regeneratePattern();
  }
} 