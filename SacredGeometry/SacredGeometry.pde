import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean recordSVG = false;

// Pattern parameters
int patternType = 0; // 0=Flower of Life, 1=Seed of Life, 2=Metatron's Cube, 3=Sri Yantra, 4=Vesica Piscis
int gridSize = 600;  // Size of the drawing area
float strokeWeight = 1.0;
int circleDetail = 50; // Number of segments in circles
int iterations = 7;    // Used for Flower of Life iterations
boolean showGuideLines = false;
color strokeColor = color(0);
color backgroundColor = color(255);

void setup() {
  size(800, 700);  // Extra space for controls
  smooth();
  setupControls();
}

void setupControls() {
  cp5 = new ControlP5(this);
  int inputX = 10;
  int inputY = 620;
  int inputW = 100;
  int inputH = 20;
  int spacing = 30;
  
  // Pattern Type Dropdown
  cp5.addDropdownList("patternType")
     .setPosition(inputX, inputY)
     .setSize(150, 120)
     .setItemHeight(20)
     .setBarHeight(20)
     .addItem("Flower of Life", 0)
     .addItem("Seed of Life", 1)
     .addItem("Metatron's Cube", 2)
     .addItem("Sri Yantra", 3)
     .addItem("Vesica Piscis", 4)
     .close();
     
  // Iterations Slider for Flower of Life
  cp5.addSlider("iterations")
     .setPosition(inputX + 170, inputY)
     .setSize(100, 20)
     .setRange(1, 12)
     .setValue(7);
     
  // Circle Detail Slider
  cp5.addSlider("circleDetail")
     .setPosition(inputX + 170, inputY + spacing)
     .setSize(100, 20)
     .setRange(20, 100)
     .setValue(50);
     
  // Stroke Weight Slider
  cp5.addSlider("strokeWeight")
     .setPosition(inputX + 290, inputY)
     .setSize(100, 20)
     .setRange(0.5, 3.0)
     .setValue(1.0);
     
  // Guide Lines Toggle
  cp5.addToggle("showGuideLines")
     .setPosition(inputX + 290, inputY + spacing)
     .setSize(20, 20)
     .setValue(false);
  cp5.addLabel("Show Guides")
     .setPosition(inputX + 320, inputY + spacing)
     .setSize(80, 20);
     
  // Save SVG Button
  cp5.addButton("saveSVG")
     .setPosition(inputX + 410, inputY)
     .setSize(80, 40)
     .setCaptionLabel("Save SVG");
}

void draw() {
  background(backgroundColor);
  
  // Drawing area
  pushMatrix();
  translate(width/2, height/2 - 50); // Center, but slightly higher to make room for controls
  stroke(strokeColor);
  strokeWeight(strokeWeight);
  noFill();
  
  switch(patternType) {
    case 0:
      drawFlowerOfLife(iterations);
      break;
    case 1:
      drawSeedOfLife();
      break;
    case 2:
      drawMetatronsCube();
      break;
    case 3:
      drawSriYantra();
      break;
    case 4:
      drawVesicaPiscis();
      break;
  }
  
  popMatrix();
  
  if (recordSVG) {
    endRecord();
    println("SVG saved!");
    recordSVG = false;
  }
}

// Flower of Life pattern
void drawFlowerOfLife(int iterations) {
  float radius = gridSize / 4.0;
  
  // Center circle
  drawCircle(0, 0, radius);
  
  // First ring of 6 circles
  for (int i = 0; i < 6; i++) {
    float angle = i * PI / 3.0;
    float x = cos(angle) * radius;
    float y = sin(angle) * radius;
    drawCircle(x, y, radius);
  }
  
  // Additional iterations of circles
  if (iterations > 1) {
    ArrayList<PVector> centers = new ArrayList<PVector>();
    centers.add(new PVector(0, 0));
    
    for (int i = 0; i < 6; i++) {
      float angle = i * PI / 3.0;
      float x = cos(angle) * radius;
      float y = sin(angle) * radius;
      centers.add(new PVector(x, y));
    }
    
    // Calculate additional circles
    for (int n = 1; n < iterations; n++) {
      ArrayList<PVector> newCenters = new ArrayList<PVector>();
      
      for (PVector center : centers) {
        for (int i = 0; i < 6; i++) {
          float angle = i * PI / 3.0;
          float x = center.x + cos(angle) * radius;
          float y = center.y + sin(angle) * radius;
          PVector newPoint = new PVector(x, y);
          
          // Check if this center is already in our list (within a small tolerance)
          boolean exists = false;
          for (PVector existingCenter : centers) {
            if (PVector.dist(existingCenter, newPoint) < 0.001) {
              exists = true;
              break;
            }
          }
          
          for (PVector existingCenter : newCenters) {
            if (PVector.dist(existingCenter, newPoint) < 0.001) {
              exists = true;
              break;
            }
          }
          
          if (!exists) {
            newCenters.add(newPoint);
            drawCircle(x, y, radius);
          }
        }
      }
      
      // Add new centers to the list
      centers.addAll(newCenters);
    }
  }
}

// Seed of Life pattern
void drawSeedOfLife() {
  float radius = gridSize / 4.0;
  
  // Center circle
  drawCircle(0, 0, radius);
  
  // 6 circles around
  for (int i = 0; i < 6; i++) {
    float angle = i * PI / 3.0;
    float x = cos(angle) * radius;
    float y = sin(angle) * radius;
    drawCircle(x, y, radius);
  }
}

// Metatron's Cube
void drawMetatronsCube() {
  float radius = gridSize / 4.0;
  float smallerRadius = radius * 0.8;
  ArrayList<PVector> centers = new ArrayList<PVector>();
  
  // Draw Seed of Life first
  drawCircle(0, 0, smallerRadius);
  centers.add(new PVector(0, 0));
  
  for (int i = 0; i < 6; i++) {
    float angle = i * PI / 3.0;
    float x = cos(angle) * radius;
    float y = sin(angle) * radius;
    drawCircle(x, y, smallerRadius);
    centers.add(new PVector(x, y));
  }
  
  // Add 6 outer points
  for (int i = 0; i < 6; i++) {
    float angle = (i * PI / 3.0) + (PI / 6.0);
    float x = cos(angle) * radius * 2;
    float y = sin(angle) * radius * 2;
    drawCircle(x, y, smallerRadius);
    centers.add(new PVector(x, y));
  }
  
  // Draw lines connecting all points
  stroke(strokeColor);
  strokeWeight(strokeWeight * 0.8); // Thinner lines for the connections
  
  for (int i = 0; i < centers.size(); i++) {
    for (int j = i + 1; j < centers.size(); j++) {
      line(centers.get(i).x, centers.get(i).y, centers.get(j).x, centers.get(j).y);
    }
  }
}

// Sri Yantra pattern
void drawSriYantra() {
  float size = gridSize / 2.0;
  
  // Draw the central dot (bindu)
  ellipse(0, 0, 5, 5);
  
  // Draw the triangles
  // Downward-pointing central triangle
  drawTriangle(0, -size * 0.1, size * 0.4, size * 0.3, -size * 0.4, size * 0.3);
  
  // Upward-pointing central triangle
  drawTriangle(0, size * 0.3, -size * 0.5, -size * 0.25, size * 0.5, -size * 0.25);
  
  // 4 more pairs of interlocking triangles
  float scale = 0.65;
  for (int i = 0; i < 4; i++) {
    float factor = 0.8 + i * 0.35;
    
    // Downward-pointing triangle
    drawTriangle(0, -size * 0.1 * factor, size * 0.4 * factor, size * 0.3 * factor, -size * 0.4 * factor, size * 0.3 * factor);
    
    // Upward-pointing triangle
    drawTriangle(0, size * 0.3 * factor, -size * 0.5 * factor, -size * 0.25 * factor, size * 0.5 * factor, -size * 0.25 * factor);
  }
  
  // Draw the outer circles
  drawCircle(0, 0, size * 0.85);
  drawCircle(0, 0, size * 0.95);
}

// Vesica Piscis pattern
void drawVesicaPiscis() {
  float radius = gridSize / 4.0;
  
  // Draw two overlapping circles
  drawCircle(-radius/2, 0, radius);
  drawCircle(radius/2, 0, radius);
  
  // Draw the Vesica Piscis outline
  float h = sqrt(radius * radius - (radius/2) * (radius/2));
  beginShape();
  for (float theta = -PI/3; theta <= PI/3; theta += 0.01) {
    float x = radius/2 + radius * cos(theta);
    float y = radius * sin(theta);
    vertex(x, y);
  }
  for (float theta = 2*PI/3; theta <= 4*PI/3; theta += 0.01) {
    float x = -radius/2 + radius * cos(theta);
    float y = radius * sin(theta);
    vertex(x, y);
  }
  endShape(CLOSE);
  
  // Guide lines
  if (showGuideLines) {
    stroke(color(200, 0, 0, 150));
    line(-radius/2, -h, -radius/2, h);
    line(radius/2, -h, radius/2, h);
  }
}

// Helper function to draw a better circle
void drawCircle(float x, float y, float r) {
  pushMatrix();
  translate(x, y);
  beginShape();
  for (int i = 0; i < circleDetail; i++) {
    float angle = map(i, 0, circleDetail, 0, TWO_PI);
    vertex(cos(angle) * r, sin(angle) * r);
  }
  endShape(CLOSE);
  
  // Draw center point if guide lines are enabled
  if (showGuideLines) {
    stroke(color(200, 0, 0, 150));
    point(0, 0);
  }
  popMatrix();
}

void drawTriangle(float x1, float y1, float x2, float y2, float x3, float y3) {
  triangle(x1, y1, x2, y2, x3, y3);
  
  // Draw guide lines
  if (showGuideLines) {
    stroke(color(200, 0, 0, 150));
    point(x1, y1);
    point(x2, y2);
    point(x3, y3);
  }
}

// Handle SVG recording
public void saveSVG() {
  println("Starting SVG recording...");
  beginRecord(SVG, "sacredGeometry_" + patternType + "_" + nf(day(), 2) + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".svg");
  recordSVG = true;
}

// Optional keyboard controls
void keyPressed() {
  // Number keys to switch patterns
  if (key >= '0' && key <= '4') {
    patternType = key - '0';
  }
  
  // 's' key to save SVG
  if (key == 's' || key == 'S') {
    saveSVG();
  }
  
  // 'g' key to toggle guide lines
  if (key == 'g' || key == 'G') {
    showGuideLines = !showGuideLines;
  }
} 