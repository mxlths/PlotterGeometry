import java.util.ArrayList;
import controlP5.*; 
import processing.svg.*; 
import javax.swing.JOptionPane;
import java.io.File; 
import java.awt.Component;

ControlP5 cp5;
boolean recordSVG = false; 
String svgOutputPath = null; 
PFont labelFont; 

// --- Core Parameters ---
int numCircles = 5; // Number of main circular structures
float minRadius = 100; // Minimum base radius (in pixels)
float maxRadius = 300; // Maximum base radius (in pixels)
int numPointsPerCircle = 20; // Points defining each circle's curve smoothness
float perturbationScale = 30.0; // Max random offset distance for points (pixels)
int numLinesPerCircle = 50; // Number of slightly varied lines per circle (for wispiness)
float lineAlpha = 50; // Transparency of lines (0-255)
float lineWidth = 0.5; // Thickness of lines
float noiseScale = 0.05; // Scale for Perlin noise perturbation
float noiseSpeed = 0.01; // How fast the noise pattern evolves over time (for animation)
float perturbMagnitudeVariance = 0.5; // New: How much perturbation distance varies (0-1)

// --- Data Structure ---
ArrayList<CircleDefinition> circles; 

// --- Global state for noise animation ---
float timeOffset = 0; 

// --- Class to hold circle properties ---
class CircleDefinition {
  PVector center;
  float baseRadius;
  
  CircleDefinition(PVector c, float r) {
    center = c;
    baseRadius = r;
  }
}

void setup() {
  size(1200, 900); // Canvas size
  
  cp5 = new ControlP5(this); 
  labelFont = createFont("Arial", 14, true); 
  
  // --- ControlP5 UI Setup ---
  int inputX = 160; 
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 30;
  int currentY = inputY;
  
  cp5.addLabel("Num Circles:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_numCircles")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numCircles).setId(1);

  currentY += spacing;
  cp5.addLabel("Min Radius:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_minRadius")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(minRadius, 0, 0)).setId(2);

  currentY += spacing;
  cp5.addLabel("Max Radius:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_maxRadius")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(maxRadius, 0, 0)).setId(3);
     
  currentY += spacing;
  cp5.addLabel("Points/Circle:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_numPointsPerCircle")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numPointsPerCircle).setId(4);

  currentY += spacing;
  cp5.addLabel("Perturb Scale:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_perturbationScale")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(perturbationScale, 0, 1)).setId(5);

  currentY += spacing;
  cp5.addLabel("Lines/Circle:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_numLinesPerCircle")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+numLinesPerCircle).setId(6);
     
  currentY += spacing;
  cp5.addLabel("Line Alpha:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_lineAlpha")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(lineAlpha, 0, 0)).setId(7);
     
  currentY += spacing;
  cp5.addLabel("Line Width:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_lineWidth")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(lineWidth, 0, 2)).setId(8);

  currentY += spacing;
  cp5.addLabel("Noise Scale:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_noiseScale")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(noiseScale, 0, 3)).setId(9);

  currentY += spacing;
  cp5.addLabel("Noise Speed:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_noiseSpeed")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(noiseSpeed, 0, 3)).setId(10);

  // --- New Perturb Variance Textfield ---
  currentY += spacing;
  cp5.addLabel("Perturb Variance:")
     .setPosition(10, currentY + 4).setSize(140, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("input_perturbMagnitudeVariance")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(perturbMagnitudeVariance, 0, 2)).setId(11);

  // --- Regenerate Button ---
  currentY += spacing + 10;
  cp5.addButton("regenerateCircles")
     .setLabel("Regenerate")
     .setPosition(10, currentY)
     .setSize(100, inputH + 5);

  // --- SVG Export Button ---
  cp5.addButton("exportSVG")
     .setLabel("Export SVG")
     .setPosition(120, currentY)
     .setSize(100, inputH + 5);

  // Initialize data structures and generate initial circles
  circles = new ArrayList<CircleDefinition>();
  regenerateCircles(); 
}

// Function to generate the set of base circles
void regenerateCircles() {
  println("Regenerating circles...");
  // Ensure min < max radius
  if (minRadius > maxRadius) {
      float temp = minRadius;
      minRadius = maxRadius;
      maxRadius = temp;
      // Update UI if values were swapped
       if (cp5 != null) {
         ((Textfield)cp5.getController("input_minRadius")).setValue(nf(minRadius, 0, 0));
         ((Textfield)cp5.getController("input_maxRadius")).setValue(nf(maxRadius, 0, 0));
       }
  }
  
  circles.clear();
  for (int i = 0; i < numCircles; i++) {
    // Pick center randomly, maybe biased towards center slightly
    float angle = random(TWO_PI);
    float distFromCenter = random(0, min(width, height) * 0.3); // Bias placement
    float cX = width/2.0 + cos(angle) * distFromCenter;
    float cY = height/2.0 + sin(angle) * distFromCenter;
    PVector center = new PVector(cX, cY);
    
    float radius = random(minRadius, maxRadius);
    circles.add(new CircleDefinition(center, radius));
  }
  // Reset noise time offset when regenerating positions
  timeOffset = 0; 
}

// Function to draw the pattern to a PGraphics object (screen or SVG)
void drawPattern(PGraphics g) {
  g.stroke(0, lineAlpha); 
  g.strokeWeight(lineWidth); 
  g.noFill();
  
  // timeOffset += noiseSpeed; // Evolve noise over time -- REMOVED FOR STATIC IMAGE

  for (CircleDefinition cd : circles) {
    for (int line = 0; line < numLinesPerCircle; line++) {
      
      ArrayList<PVector> perturbedPoints = new ArrayList<PVector>();
      int n = numPointsPerCircle; // Use parameter for number of points
      
      // Add seed variation per line draw
      float lineNoiseOffset = line * 100; 

      for (int i = 0; i < n; i++) {
        float angle = map(i, 0, n, 0, TWO_PI);
        
        // Base point on the perfect circle
        float baseX = cd.center.x + cos(angle) * cd.baseRadius;
        float baseY = cd.center.y + sin(angle) * cd.baseRadius;
        
        // Calculate Perlin noise for perturbation
        // Use timeOffset for animation, lineNoiseOffset for variation between lines
        float noiseVal = noise(
             (baseX + lineNoiseOffset) * noiseScale, 
             (baseY + lineNoiseOffset) * noiseScale, 
             timeOffset 
             );
             
        // Map noise (0 to 1) to an angle (-PI to PI) for perturbation direction
        float perturbAngle = map(noiseVal, 0, 1, -PI, PI);
        
        // Calculate noise for perturbation magnitude variance
        float magnitudeNoiseScale = noiseScale * 1.5; // Use a slightly different scale
        float magnitudeNoiseVal = noise(
            (baseX + lineNoiseOffset + 1000) * magnitudeNoiseScale, // Offset inputs 
            (baseY + lineNoiseOffset + 2000) * magnitudeNoiseScale,
            timeOffset
        );
        
        // Map magnitude noise (0 to 1) to a factor based on variance
        // Example: variance = 0.5 -> factor between 0.5 and 1.5
        float minFactor = 1.0 - constrain(perturbMagnitudeVariance, 0, 1);
        float maxFactor = 1.0 + constrain(perturbMagnitudeVariance, 0, 1);
        float perturbFactor = map(magnitudeNoiseVal, 0, 1, minFactor, maxFactor);

        // Calculate the varying distance
        float perturbDist = perturbationScale * perturbFactor;
        
        // Calculate perturbed position
        float pX = baseX + cos(perturbAngle) * perturbDist;
        float pY = baseY + sin(perturbAngle) * perturbDist;
        
        perturbedPoints.add(new PVector(pX, pY));
      }

      // Draw the perturbed curve
      if (perturbedPoints.size() >= 3) { // Need at least 3 points for curveVertex
          g.beginShape();
          // Use curveVertex for smooth closed shapes
          // Add control points by wrapping around
          g.curveVertex(perturbedPoints.get(n - 1).x, perturbedPoints.get(n - 1).y); // Control point before first
          for (int i = 0; i < n; i++) {
              g.curveVertex(perturbedPoints.get(i).x, perturbedPoints.get(i).y);
          }
          g.curveVertex(perturbedPoints.get(0).x, perturbedPoints.get(0).y); // First point again to close
          g.curveVertex(perturbedPoints.get(1).x, perturbedPoints.get(1).y); // Second point as control point after last
          g.endShape();
      }
    }
  }
}


void draw() {
  background(255); // White background
  
  if (circles != null && !circles.isEmpty()) {
    drawPattern(this.g); // Draw directly to the screen canvas
  }
  
  // Always draw the UI controls unless we're recording
  if (!recordSVG) {
    cp5.draw();
  }
  
  // Handle SVG recording if needed
  if (recordSVG) {
    try {
      println("Creating SVG...");
      PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
      svg.beginDraw();
      svg.background(255); // Ensure SVG background is white
      
      // Draw the pattern to the SVG graphics object
      if (circles != null && !circles.isEmpty()) {
        drawPattern(svg); 
      }
      
      svg.endDraw();
      svg.dispose();
      println("SVG saved to: " + svgOutputPath);
      
      File outputFile = new File(svgOutputPath);
      if (outputFile.exists() && outputFile.length() > 0) {
        println("SVG file verified: " + svgOutputPath + " (Size: " + outputFile.length() + " bytes)");
        Component parent = null;
        String message = "SVG exported successfully to:\n" + svgOutputPath;
        String title = "SVG Export";
        int messageType = JOptionPane.INFORMATION_MESSAGE;
        JOptionPane.showMessageDialog(parent, message, title, messageType);
      } else {
        println("ERROR: SVG file not found or empty after export: " + svgOutputPath);
        JOptionPane.showMessageDialog(null, "Error: SVG file was not created or is empty.\n" + 
                                            "Check permissions or try restarting Processing.", 
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
}

// --- ControlP5 Handlers (using IDs for simplicity) ---
void controlEvent(ControlEvent theEvent) {
  ControllerInterface<?> controller = theEvent.getController();
  String name = controller.getName();
  String value = "";
  
  if (controller instanceof Textfield) {
    value = ((Textfield) controller).getText();
  } else {
     return; // Ignore button events here
  }

  try {
      switch(controller.getId()) {
          case 1: // numCircles
              int newNum = Integer.parseInt(value);
              if (newNum != numCircles) {
                  numCircles = max(1, newNum);
                  if (numCircles != newNum) ((Textfield)controller).setValue(""+numCircles);
                  regenerateCircles();
              }
              break;
          case 2: // minRadius
              float newMinR = Float.parseFloat(value);
              if (newMinR != minRadius) {
                  minRadius = max(0, newMinR);
                   if (minRadius != newMinR) ((Textfield)controller).setValue(nf(minRadius,0,0));
                  regenerateCircles();
              }
              break;
          case 3: // maxRadius
              float newMaxR = Float.parseFloat(value);
              if (newMaxR != maxRadius) {
                  maxRadius = max(0, newMaxR);
                   if (maxRadius != newMaxR) ((Textfield)controller).setValue(nf(maxRadius,0,0));
                  regenerateCircles();
              }
              break;
         case 4: // numPointsPerCircle
              int newPoints = Integer.parseInt(value);
              if (newPoints != numPointsPerCircle) {
                   numPointsPerCircle = max(3, newPoints); // Need at least 3 points
                   if (numPointsPerCircle != newPoints) ((Textfield)controller).setValue(""+numPointsPerCircle);
                   // No need to regenerate positions, just redraw
              }
              break;
         case 5: // perturbationScale
              float newPerturb = Float.parseFloat(value);
              perturbationScale = max(0, newPerturb);
              if (perturbationScale != newPerturb) ((Textfield)controller).setValue(nf(perturbationScale,0,1));
              break;
         case 6: // numLinesPerCircle
              int newLines = Integer.parseInt(value);
              numLinesPerCircle = max(1, newLines);
              if (numLinesPerCircle != newLines) ((Textfield)controller).setValue(""+numLinesPerCircle);
              break;
         case 7: // lineAlpha
              float newAlpha = Float.parseFloat(value);
              lineAlpha = constrain(newAlpha, 0, 255);
              if (lineAlpha != newAlpha) ((Textfield)controller).setValue(nf(lineAlpha,0,0));
              break;
         case 8: // lineWidth
              float newWidth = Float.parseFloat(value);
              lineWidth = max(0.1, newWidth); // Ensure minimum width
              if (lineWidth != newWidth) ((Textfield)controller).setValue(nf(lineWidth,0,2));
              break;
         case 9: // noiseScale
              float newNoiseS = Float.parseFloat(value);
              noiseScale = max(0, newNoiseS);
               if (noiseScale != newNoiseS) ((Textfield)controller).setValue(nf(noiseScale,0,3));
              break;
         case 10: // noiseSpeed
              float newNoiseSp = Float.parseFloat(value);
              noiseSpeed = newNoiseSp; // Can be zero or negative
              break;
         case 11: // perturbMagnitudeVariance
              float newPerturbVar = Float.parseFloat(value);
              // Clamp variance between 0.0 and 1.0
              perturbMagnitudeVariance = constrain(newPerturbVar, 0.0, 1.0);
              if (abs(perturbMagnitudeVariance - newPerturbVar) > 1e-5) { // Update field if clamped
                  ((Textfield)controller).setValue(nf(perturbMagnitudeVariance,0,2));
              } 
              break;
      }
  } catch (NumberFormatException e) {
      println("Invalid input for " + name + ": " + value);
      // Optionally reset field to current value, but might be annoying
  }
}


// Handler for the Regenerate button
public void regenerateCircles(int theValue) { // Parameter needed for button handler
  regenerateCircles();
}

// Handler for the SVG export button
public void exportSVG(int theValue) { // Parameter needed for button handler
  println("SVG export requested via button");
  if (recordSVG) {
    println("Export already in progress.");
    return;
  }
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
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    println("File already exists, deleting: " + svgOutputPath);
    if (!outputFile.delete()) {
         println("Warning: Could not delete existing file.");
    }
  }
  recordSVG = true; // Trigger SVG rendering in draw()
}

// Helper function to generate timestamp string
String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" + 
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

// Key press for quick SVG export (optional)
void keyPressed() {
  if (key == 's' || key == 'S') {
      if (!recordSVG) { 
          exportSVG(0); // Call the same logic as the button
      }
  }
} 