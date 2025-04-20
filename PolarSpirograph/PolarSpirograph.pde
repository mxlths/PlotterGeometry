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

// Drawing Parameters
float thetaMaxCycles = 10.0; // How many full 2*PI cycles for theta
int numPoints = 2000;     // Resolution of the curve
float lineWidth = 1.0;
int numRepetitions = 1;   // Number of times to repeat the pattern radially

// Spiral Repetition Parameters (NEW)
boolean useSpiralRepetition = false;
float spiralTotalDegrees = 360.0;
float spiralAmplitude = 1.0; // Factor controlling radial spread relative to scaleFactor

// --- Data Structures ---
ArrayList<PVector> pathPoints; // Stores Cartesian points of the path
boolean needsRegen = true;

// --- SVG Export ---
boolean recordSVG = false;
String svgOutputPath = null;

// --- Setup & UI ---
void setup() {
  size(1000, 1000); // Canvas size
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

  // Buttons
  currentY += spacing + 10;
  cp5.addButton("regeneratePatternButton").setLabel("Regenerate").setPosition(10, currentY).setSize(100, inputH+5);
  cp5.addButton("exportSVG").setLabel("Export SVG").setPosition(120, currentY).setSize(100, inputH+5);
}

// --- Path Generation ---
void regeneratePattern() {
  println("Generating Spirograph path...");
  pathPoints = new ArrayList<PVector>();
  numPoints = max(10, numPoints); // Ensure reasonable minimum points
  
  float p1Rad = radians(p1Deg);
  float p2Rad = radians(p2Deg);
  float p3Rad = radians(p3Deg); // Convert new phase to radians
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
    
    pathPoints.add(new PVector(x, y));
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

  if (needsRegen) {
    regeneratePattern();
  }

  background(255); // White background
  translate(width / 2, height / 2); // Center the drawing

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
        vertex(p.x, p.y);
      }
      endShape();
      popMatrix(); // Restore previous transformation state
    }
  }
  
  // Draw GUI - Reset matrix first to draw in screen space
  resetMatrix(); 
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
      new File(sketchPath(""), "Spirograph_" + getTimestamp() + ".svg"), this);
    return; // Wait for file selection
  }
  
  println("Creating SVG...");
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
  
  svg.beginDraw();
  svg.background(255); 
  svg.translate(width / 2, height / 2); // Apply same translation as in draw()
  svg.stroke(0);       
  svg.strokeWeight(lineWidth);
  svg.noFill();
  
  // Draw the path to SVG
  if (pathPoints != null && pathPoints.size() > 1) {
    for (int i = 0; i < numRepetitions; i++) {
      svg.pushMatrix(); // Save SVG transformation state
      if (useSpiralRepetition && numRepetitions > 1) {
        // Spiral placement for SVG
        float spiralAngle = map(i, 0, numRepetitions, 0, radians(spiralTotalDegrees));
        float spiralRadius = map(i, 0, numRepetitions, 0, spiralAmplitude * scaleFactor);
        float tx = spiralRadius * cos(spiralAngle);
        float ty = spiralRadius * sin(spiralAngle);
        svg.translate(tx, ty); // Apply translation for this repetition
      } else if (numRepetitions > 1) {
        // Circular placement for SVG (original rotation)
        svg.rotate(TWO_PI / numRepetitions * i); // Apply rotation for this repetition
      } // else: numRepetitions is 1, no transform needed
      
      svg.beginShape();
      for (PVector p : pathPoints) {
        svg.vertex(p.x, p.y);
      }
      svg.endShape();
      svg.popMatrix(); // Restore SVG transformation state
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

// --- Button Handlers & Helpers ---
public void regeneratePatternButton(int theValue) { needsRegen = true; }

public void exportSVG(int theValue) { // Button handler
  if (needsRegen) {
      println("Regenerating before export...");
      regeneratePattern();
  }
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "Spirograph_" + getTimestamp() + ".svg"), this);
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