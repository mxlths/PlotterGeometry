import controlP5.*;
import processing.svg.*;
import javax.swing.JOptionPane;
import java.io.File;
import java.util.ArrayList;

ControlP5 cp5;
PFont labelFont;

// --- Parameters ---
float noiseScale = 0.02;      // Detail level of the noise field (lower = smoother)
float noiseTimeSeed = 0;      // Seed for the 3rd dimension of noise (allows different fields)
int numParticles = 2000;     // Number of particles to trace
int particleSteps = 100;     // Max number of steps each particle takes (path length)
float stepLength = 2.0;       // How far a particle moves in each step (pixels)
float flowStrength = TWO_PI; // How strongly noise angle affects direction (range 0 to TWO_PI*2 or more)
float lineWidth = 0.5;
int lineAlpha = 50;         // Alpha for drawing paths (0-255)
boolean wrapEdges = true;     // Should particles wrap around screen edges?

// --- Data Structures ---
ArrayList<Particle> particles;
boolean needsRegen = true; // Flag to trigger regeneration

// --- SVG Export ---
boolean recordSVG = false;
String svgOutputPath = null;

// --- Particle Class ---
class Particle {
  PVector pos;
  ArrayList<PVector> path;
  boolean active;

  Particle(float x, float y) {
    pos = new PVector(x, y);
    path = new ArrayList<PVector>();
    path.add(pos.copy()); // Start path at initial position
    active = true;
  }

  void update() {
    if (!active) return;

    // Get noise angle
    float n = noise(pos.x * noiseScale, pos.y * noiseScale, noiseTimeSeed);
    float angle = map(n, 0, 1, 0, flowStrength); // Map noise to angle range

    // Calculate velocity
    PVector vel = PVector.fromAngle(angle);
    vel.setMag(stepLength);

    // Update position
    pos.add(vel);

    // Store path
    path.add(pos.copy());

    // Check bounds and steps
    if (path.size() > particleSteps) {
      active = false;
    }
    if (wrapEdges) {
      if (pos.x < 0) { pos.x = width; path = new ArrayList<PVector>(); path.add(pos.copy()); }
      if (pos.x > width) { pos.x = 0; path = new ArrayList<PVector>(); path.add(pos.copy()); }
      if (pos.y < 0) { pos.y = height; path = new ArrayList<PVector>(); path.add(pos.copy()); }
      if (pos.y > height) { pos.y = 0; path = new ArrayList<PVector>(); path.add(pos.copy()); }
    } else {
       if (pos.x < 0 || pos.x > width || pos.y < 0 || pos.y > height) {
         active = false;
       }
    }
  }

  void drawPath(PGraphics pg) {
    if (path.size() < 2) return; // Need at least 2 points to draw

    pg.beginShape();
    for (PVector p : path) {
      pg.vertex(p.x, p.y);
    }
    pg.endShape();
  }
}

// --- Setup & UI ---
void setup() {
  size(1200, 800); // Canvas size
  labelFont = createFont("Arial", 12, true);
  cp5 = new ControlP5(this);

  int inputX = 160;
  int inputY = 10;
  int inputW = 60;
  int inputH = 20;
  int spacing = 28;
  int currentY = inputY;

  cp5.addLabel("Noise Scale:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("noiseScale").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(noiseScale, 1, 3));

  currentY += spacing;
  cp5.addLabel("Noise Seed:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("noiseTimeSeed").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(noiseTimeSeed, 1, 1));

  currentY += spacing;
  cp5.addLabel("Num Particles:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("numParticles").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+numParticles);

  currentY += spacing;
  cp5.addLabel("Particle Steps:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("particleSteps").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+particleSteps);

  currentY += spacing;
  cp5.addLabel("Step Length:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("stepLength").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(stepLength, 1, 1));

  currentY += spacing;
  cp5.addLabel("Flow Strength:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("flowStrength").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(flowStrength, 1, 2));

  currentY += spacing;
  cp5.addLabel("Line Width:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("lineWidth").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(nf(lineWidth, 1, 2));

  currentY += spacing;
  cp5.addLabel("Line Alpha:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addTextfield("lineAlpha").setPosition(inputX, currentY).setSize(inputW, inputH).setAutoClear(false).setValue(""+lineAlpha);

  currentY += spacing;
  cp5.addLabel("Wrap Edges:").setPosition(10, currentY+4).setSize(140, inputH).setFont(labelFont).setColorValue(color(0));
  cp5.addToggle("wrapEdges").setPosition(inputX, currentY).setSize(inputW, inputH).setValue(wrapEdges).setMode(ControlP5.SWITCH);

  currentY += spacing + 10;
  cp5.addButton("regenerateFlowField").setLabel("Regenerate").setPosition(10, currentY).setSize(100, inputH+5);
  cp5.addButton("exportSVG").setLabel("Export SVG").setPosition(120, currentY).setSize(100, inputH+5);

  particles = new ArrayList<Particle>();
}

// --- Regeneration Logic ---
void regenerateFlowField() {
  println("Regenerating flow field...");
  noiseSeed(millis()); // Re-seed noise for different fields each time
  particles = new ArrayList<Particle>();
  for (int i = 0; i < numParticles; i++) {
    particles.add(new Particle(random(width), random(height)));
  }

  // Simulate all steps at once
  for (int step = 0; step < particleSteps; step++) {
    for (Particle p : particles) {
      p.update();
    }
  }
  println("Regeneration complete.");
  needsRegen = false; // Mark as regenerated
}

// --- Drawing Loop ---
void draw() {
  if (recordSVG) {
    exportToSVG(); // Handle SVG export
    recordSVG = false; // Reset flag
  }
  
  if (needsRegen) {
      regenerateFlowField();
  }

  background(255); // White background

  // Draw particle paths
  stroke(0, lineAlpha); // Black with alpha
  strokeWeight(lineWidth);
  noFill();
  for (Particle p : particles) {
    p.drawPath(this.g); // Draw to the main screen buffer
  }

  // Draw GUI
  hint(DISABLE_DEPTH_TEST);
  camera();
  ortho();
  cp5.draw();
  hint(ENABLE_DEPTH_TEST);
}

// --- SVG Export Logic ---
void exportToSVG() {
  if (svgOutputPath == null) {
    println("SVG Filename not set!");
    selectOutput("Save SVG as...", "svgFileSelected", 
      new File(sketchPath(""), "FlowField_" + getTimestamp() + ".svg"), this);
    return; // Wait for file selection
  }
  
  println("Creating SVG...");
  PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width, height, SVG, svgOutputPath);
  
  svg.beginDraw();
  svg.background(255); // Ensure SVG background is white
  svg.stroke(0);       // Black lines for SVG
  svg.strokeWeight(lineWidth);
  svg.noFill();
  
  for (Particle p : particles) {
      p.drawPath(svg); // Draw the final stored path to SVG
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
public void noiseScale(String val) { try { noiseScale = max(0.001, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){println("Invalid noiseScale");} finally { if(cp5!=null)((Textfield)cp5.getController("noiseScale")).setValue(nf(noiseScale,1,3));} }
public void noiseTimeSeed(String val) { try { noiseTimeSeed = Float.parseFloat(val); needsRegen=true;} catch (NumberFormatException e){println("Invalid noiseTimeSeed");} finally { if(cp5!=null)((Textfield)cp5.getController("noiseTimeSeed")).setValue(nf(noiseTimeSeed,1,1));} }
public void numParticles(String val) { try { numParticles = max(1, Integer.parseInt(val)); needsRegen=true;} catch (NumberFormatException e){println("Invalid numParticles");} finally { if(cp5!=null)((Textfield)cp5.getController("numParticles")).setValue(""+numParticles);} }
public void particleSteps(String val) { try { particleSteps = max(1, Integer.parseInt(val)); needsRegen=true;} catch (NumberFormatException e){println("Invalid particleSteps");} finally { if(cp5!=null)((Textfield)cp5.getController("particleSteps")).setValue(""+particleSteps);} }
public void stepLength(String val) { try { stepLength = max(0.1, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){println("Invalid stepLength");} finally { if(cp5!=null)((Textfield)cp5.getController("stepLength")).setValue(nf(stepLength,1,1));} }
public void flowStrength(String val) { try { flowStrength = max(0, Float.parseFloat(val)); needsRegen=true;} catch (NumberFormatException e){println("Invalid flowStrength");} finally { if(cp5!=null)((Textfield)cp5.getController("flowStrength")).setValue(nf(flowStrength,1,2));} }
public void lineWidth(String val) { try { lineWidth = max(0.1, Float.parseFloat(val)); } catch (NumberFormatException e){println("Invalid lineWidth");} finally { if(cp5!=null)((Textfield)cp5.getController("lineWidth")).setValue(nf(lineWidth,1,2));} }
public void lineAlpha(String val) { try { lineAlpha = max(0, min(255, Integer.parseInt(val))); } catch (NumberFormatException e){println("Invalid lineAlpha");} finally { if(cp5!=null)((Textfield)cp5.getController("lineAlpha")).setValue(""+lineAlpha);} }
public void wrapEdges(boolean val) { wrapEdges = val; needsRegen=true; }

// --- Button Handlers & Helpers ---
public void regenerateFlowField(int theValue) { // Button handler
  needsRegen = true;
}

public void exportSVG(int theValue) { // Button handler
  println("SVG export requested via button");
  selectOutput("Save SVG as...", "svgFileSelected", 
    new File(sketchPath(""), "FlowField_" + getTimestamp() + ".svg"), this);
}

void svgFileSelected(File selection) {
  if (selection == null) { println("SVG export cancelled."); svgOutputPath = null; return; }
  svgOutputPath = selection.getAbsolutePath();
  println("Selected SVG path: " + svgOutputPath);
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    println("File already exists, deleting: " + svgOutputPath);
    if (!outputFile.delete()) {
        println("Warning: Could not delete existing file. SVG export might fail or overwrite.");
    }
  }
  recordSVG = true; // Set flag to trigger SVG generation in next draw()
}

String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" + 
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

// Optional: Key press for SVG export
void keyPressed() {
  if (key == 's' || key == 'S') {
      exportSVG(0); // Call the same function as the button
  }
} 