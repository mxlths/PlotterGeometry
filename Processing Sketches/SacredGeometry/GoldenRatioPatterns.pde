import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean recordSVG = false;

// Pattern parameters
int patternType = 0; // 0=Golden Spiral, 1=Fibonacci Spiral, 2=Pentagram, 3=Golden Triangles, 4=Golden Rectangle Division
float PHI = (1 + sqrt(5)) / 2; // Golden ratio ~1.618
int gridSize = 500;  // Size of the drawing area
float strokeWeight = 1.0;
int spiralIterations = 12; // Number of iterations for spirals
boolean showGuideLines = true;
color strokeColor = color(0);
color backgroundColor = color(255);
color accentColor = color(30, 100, 255, 150); // For highlighting golden ratio elements

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
     .addItem("Golden Spiral", 0)
     .addItem("Fibonacci Spiral", 1)
     .addItem("Pentagram", 2)
     .addItem("Golden Triangles", 3)
     .addItem("Golden Rectangle Division", 4)
     .close();
     
  // Iterations Slider
  cp5.addSlider("spiralIterations")
     .setPosition(inputX + 170, inputY)
     .setSize(100, 20)
     .setRange(3, 20)
     .setValue(12);
     
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
     .setValue(true);
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
      drawGoldenSpiral(spiralIterations);
      break;
    case 1:
      drawFibonacciSpiral(spiralIterations);
      break;
    case 2:
      drawPentagram();
      break;
    case 3:
      drawGoldenTriangles();
      break;
    case 4:
      drawGoldenRectangleDivision(spiralIterations);
      break;
  }
  
  popMatrix();
  
  if (recordSVG) {
    endRecord();
    println("SVG saved!");
    recordSVG = false;
  }
}

// Golden Spiral drawn using precise Golden Ratio
void drawGoldenSpiral(int iterations) {
  float size = gridSize / 2;
  float rectSize = size;
  float x = 0;
  float y = 0;
  
  // Draw starting rectangle
  if (showGuideLines) {
    stroke(accentColor);
    drawRect(x, y, rectSize, rectSize);
  }
  
  // Keep track of direction
  int direction = 0; // 0 = right, 1 = down, 2 = left, 3 = up
  
  // Draw spiral with quarter circles
  beginShape();
  for (int i = 0; i < iterations; i++) {
    // Calculate next rectangle position and size
    float newSize = rectSize / PHI;
    float dx = 0;
    float dy = 0;
    
    // Determine position of new smaller rectangle
    if (direction == 0) { // Right
      dx = rectSize - newSize;
      dy = 0;
    } else if (direction == 1) { // Down
      dx = 0;
      dy = rectSize - newSize;
    } else if (direction == 2) { // Left
      dx = -newSize;
      dy = 0;
    } else if (direction == 3) { // Up
      dx = 0;
      dy = -newSize;
    }
    
    // Update position of next rectangle
    x += dx;
    y += dy;
    
    // Draw the new rectangle (guide lines)
    if (showGuideLines) {
      stroke(accentColor, 150 - i * 10);
      drawRect(x, y, newSize, newSize);
    }
    
    // Draw quarter circle (actual spiral)
    stroke(strokeColor);
    float arcX = 0;
    float arcY = 0;
    if (direction == 0) arcX = x + newSize;
    else if (direction == 1) arcY = y + newSize;
    else if (direction == 2) arcX = x;
    else if (direction == 3) arcY = y;
    
    float startAngle = HALF_PI * direction;
    float endAngle = startAngle + HALF_PI;
    float radius = rectSize;
    
    // Draw quarter arc (approximate with line segments)
    int steps = 36;
    for (int j = 0; j <= steps; j++) {
      float angle = map(j, 0, steps, startAngle, endAngle);
      float px = arcX + cos(angle) * radius;
      float py = arcY + sin(angle) * radius;
      
      if (i == 0 && j == 0) {
        // First point - move to
        vertex(px, py);
      } else {
        // Subsequent points - draw line to
        vertex(px, py);
      }
    }
    
    // Update for next iteration
    rectSize = newSize;
    direction = (direction + 1) % 4;
  }
  endShape();
}

// Fibonacci Spiral
void drawFibonacciSpiral(int iterations) {
  int[] fib = new int[iterations];
  fib[0] = 1;
  fib[1] = 1;
  
  // Calculate Fibonacci sequence
  for (int i = 2; i < iterations; i++) {
    fib[i] = fib[i-1] + fib[i-2];
  }
  
  // Scale factor to make it visible
  float scale = gridSize / (float)(fib[iterations-1] + fib[iterations-2]);
  
  // Draw guide rectangles
  if (showGuideLines) {
    stroke(accentColor);
    int x = 0;
    int y = 0;
    int direction = 0; // 0 = right, 1 = down, 2 = left, 3 = up
    
    for (int i = 0; i < iterations - 1; i++) {
      // Draw the rectangle
      drawRect(x * scale, y * scale, fib[i] * scale, fib[i] * scale);
      
      // Calculate next position
      if (direction == 0) { // Right
        x += fib[i];
      } else if (direction == 1) { // Down
        y += fib[i];
      } else if (direction == 2) { // Left
        x -= fib[i];
      } else if (direction == 3) { // Up
        y -= fib[i];
      }
      
      direction = (direction + 1) % 4;
    }
  }
  
  // Draw the spiral
  stroke(strokeColor);
  beginShape();
  
  int x = 0;
  int y = 0;
  int direction = 0;
  
  for (int i = 0; i < iterations - 1; i++) {
    // Draw quarter circle
    float startAngle = HALF_PI * direction;
    float endAngle = startAngle + HALF_PI;
    float radius = fib[i] * scale;
    float arcX = x * scale;
    float arcY = y * scale;
    
    // Adjust arc center
    if (direction == 0) arcX += radius;
    else if (direction == 1) arcY += radius;
    
    // Draw the arc
    int steps = 36;
    for (int j = 0; j <= steps; j++) {
      float angle = map(j, 0, steps, startAngle, endAngle);
      float px = arcX + cos(angle) * radius;
      float py = arcY + sin(angle) * radius;
      
      if (i == 0 && j == 0) {
        vertex(px, py);
      } else {
        vertex(px, py);
      }
    }
    
    // Calculate next position
    if (direction == 0) { // Right
      x += fib[i];
    } else if (direction == 1) { // Down
      y += fib[i];
    } else if (direction == 2) { // Left
      x -= fib[i];
    } else if (direction == 3) { // Up
      y -= fib[i];
    }
    
    direction = (direction + 1) % 4;
  }
  
  endShape();
}

// Pentagram (five-pointed star)
void drawPentagram() {
  float radius = gridSize / 2.5;
  float innerRadius = radius / PHI; // Golden ratio relationship
  
  // Draw regular pentagon and connecting lines
  if (showGuideLines) {
    stroke(accentColor);
    drawRegularPolygon(0, 0, radius, 5);
    
    // Draw inner pentagon
    pushMatrix();
    rotate(PI / 5); // Rotate to align with star points
    drawRegularPolygon(0, 0, innerRadius, 5);
    popMatrix();
  }
  
  // Draw the pentagram
  stroke(strokeColor);
  beginShape();
  for (int i = 0; i < 5; i++) {
    float angle = TWO_PI / 5 * i - HALF_PI; // Start at top
    float x = cos(angle) * radius;
    float y = sin(angle) * radius;
    vertex(x, y);
    
    // Connect to point 2 positions ahead (mod 5)
    angle = TWO_PI / 5 * ((i + 2) % 5) - HALF_PI;
    x = cos(angle) * radius;
    y = sin(angle) * radius;
    vertex(x, y);
  }
  endShape(CLOSE);
  
  // Draw circle
  if (showGuideLines) {
    stroke(accentColor, 80);
    drawCircle(0, 0, radius);
  }
}

// Golden Triangles
void drawGoldenTriangles() {
  float size = gridSize / 2;
  
  // Draw initial golden rectangle
  if (showGuideLines) {
    stroke(accentColor);
    drawRect(-size/2, -size/2, size, size * PHI);
    // Divide with golden ratio
    line(-size/2, size * (PHI - 1) - size/2, size/2, size * (PHI - 1) - size/2);
  }
  
  // Calculate triangle points
  float height = size * PHI;
  PVector topLeft = new PVector(-size/2, -size/2);
  PVector topRight = new PVector(size/2, -size/2);
  PVector bottomLeft = new PVector(-size/2, -size/2 + height);
  PVector bottomRight = new PVector(size/2, -size/2 + height);
  PVector divideLeft = new PVector(-size/2, -size/2 + size * (PHI - 1));
  PVector divideRight = new PVector(size/2, -size/2 + size * (PHI - 1));
  
  // Draw the two triangles
  stroke(strokeColor);
  // Triangle 1
  beginShape();
  vertex(topLeft.x, topLeft.y);
  vertex(bottomRight.x, bottomRight.y);
  vertex(divideLeft.x, divideLeft.y);
  endShape(CLOSE);
  
  // Triangle 2
  beginShape();
  vertex(topRight.x, topRight.y);
  vertex(divideRight.x, divideRight.y);
  vertex(bottomLeft.x, bottomLeft.y);
  endShape(CLOSE);
  
  // Draw recursive golden triangles
  drawGoldenTriangleRecursive(topLeft, bottomRight, divideLeft, 0, 5);
  drawGoldenTriangleRecursive(topRight, divideRight, bottomLeft, 0, 5);
}

void drawGoldenTriangleRecursive(PVector a, PVector b, PVector c, int depth, int maxDepth) {
  if (depth >= maxDepth) return;
  
  // Calculate the golden section point that divides the triangle
  PVector d = PVector.lerp(a, b, 1/PHI);
  
  // Draw the subdividing line
  if (showGuideLines && depth < 2) {
    stroke(accentColor, 150 - depth * 30);
    line(c.x, c.y, d.x, d.y);
  }
  
  // Draw the new triangle
  stroke(strokeColor, 255 - depth * 40);
  beginShape();
  vertex(c.x, c.y);
  vertex(d.x, d.y);
  vertex(a.x, a.y);
  endShape(CLOSE);
  
  // Recursive call for the new triangle
  drawGoldenTriangleRecursive(c, d, a, depth + 1, maxDepth);
}

// Golden Rectangle Division
void drawGoldenRectangleDivision(int iterations) {
  float size = gridSize / 1.8;
  float x = -size / 2;
  float y = -size * PHI / 2;
  float rectWidth = size;
  float rectHeight = size * PHI;
  
  // Draw initial golden rectangle
  if (showGuideLines) {
    stroke(accentColor);
    drawRect(x, y, rectWidth, rectHeight);
  }
  
  stroke(strokeColor);
  
  // Start the process of dividing the rectangle
  drawGoldenRectDivision(x, y, rectWidth, rectHeight, 0, iterations);
}

void drawGoldenRectDivision(float x, float y, float w, float h, int depth, int maxDepth) {
  if (depth >= maxDepth) return;
  
  // Draw the current rectangle
  if (showGuideLines) {
    stroke(accentColor, 150 - depth * 15);
    drawRect(x, y, w, h);
  }
  
  // Determine if rectangle is "wide" or "tall"
  boolean isWide = (w > h);
  
  // Divide the rectangle
  float squareSize = isWide ? h : w;
  float remainderSize = isWide ? w - h : h - w;
  
  // Draw the dividing line
  stroke(strokeColor);
  if (isWide) {
    line(x + squareSize, y, x + squareSize, y + h);
  } else {
    line(x, y + squareSize, x + w, y + squareSize);
  }
  
  // Calculate the position of the new golden rectangle
  float newX = isWide ? x + squareSize : x;
  float newY = isWide ? y : y + squareSize;
  float newW = isWide ? remainderSize : w;
  float newH = isWide ? h : remainderSize;
  
  // Draw quarter circle to form the spiral
  float arcX = isWide ? x + squareSize : x + w;
  float arcY = isWide ? y + h : y + squareSize;
  float startAngle = isWide ? PI : HALF_PI;
  float endAngle = isWide ? PI + HALF_PI : PI;
  
  noFill();
  stroke(strokeColor);
  arc(arcX, arcY, squareSize * 2, squareSize * 2, startAngle, endAngle);
  
  // Recursive call with the smaller rectangle
  drawGoldenRectDivision(newX, newY, newW, newH, depth + 1, maxDepth);
}

// Helper function to draw a rectangle from center position
void drawRect(float x, float y, float w, float h) {
  rectMode(CENTER);
  rect(x + w/2, y + h/2, w, h);
}

// Helper function to draw a circle
void drawCircle(float x, float y, float r) {
  ellipse(x, y, r * 2, r * 2);
}

// Helper function to draw a regular polygon
void drawRegularPolygon(float x, float y, float r, int sides) {
  beginShape();
  for (int i = 0; i < sides; i++) {
    float angle = TWO_PI / sides * i - HALF_PI; // Start at top
    float px = x + cos(angle) * r;
    float py = y + sin(angle) * r;
    vertex(px, py);
  }
  endShape(CLOSE);
}

// Handle SVG recording
public void saveSVG() {
  println("Starting SVG recording...");
  beginRecord(SVG, "goldenRatio_" + patternType + "_" + nf(day(), 2) + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".svg");
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