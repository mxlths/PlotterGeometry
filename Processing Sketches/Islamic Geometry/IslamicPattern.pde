import processing.svg.*;

boolean saved = false; // Flag to ensure we only save once

float patternSize = 200; // Size of the basic repeating unit
float strokeW = 2;      // Stroke weight

void setup() {
  size(600, 600); // Canvas size
  background(255); // White background
  strokeWeight(strokeW);
  stroke(0);       // Black lines
  noFill();        // No fill for shapes, suitable for plotters
  smooth();

  // Start recording SVG output
  // NOTE: Ensure the sketch folder exists before running!
  beginRecord(SVG, "islamic_pattern_######.svg");
}

void draw() {
  translate(width / 2, height / 2); // Center the pattern

  // Tiling: Draw the motif repeatedly across the canvas
  // Calculate how many tiles fit horizontally and vertically, add 1 for buffer
  int numTilesX = ceil(width / patternSize) + 1;
  int numTilesY = ceil(height / patternSize) + 1;

  // Loop through grid positions, centering the grid
  for (int i = -numTilesX / 2; i <= numTilesX / 2; i++) {
    for (int j = -numTilesY / 2; j <= numTilesY / 2; j++) {
      pushMatrix();
      // Translate to the position for this tile
      translate(i * patternSize, j * patternSize);
      // Draw the motif at this position
      drawStarMotif(0, 0, patternSize);
      popMatrix();
    }
  }

  // --- End Tiling ---

  // End recording and save the SVG file
  endRecord();
  println("SVG saved!");
  saved = true; // Mark as saved
  noLoop();     // Stop draw() from looping further
}

// Function to draw the basic 8-pointed star motif
void drawStarMotif(float x, float y, float size) {
  float halfSize = size / 2.0;

  pushMatrix(); // Isolate transformations for this motif
  translate(x, y);

  // Draw the first square
  rectMode(CENTER); // Draw rectangles from their center
  rect(0, 0, size, size);

  // Draw the second square, rotated 45 degrees
  rotate(radians(45));
  rect(0, 0, size, size);

  // Add inner connecting lines for more detail
  // Calculate the radius for the inner vertices based on the geometry
  float innerRadius = size / (2.0 * (1 + sqrt(2)));
  pushStyle(); // Save current style
  // You might want a different stroke for these inner lines
  // stroke(150); // Example: Lighter gray stroke
  // strokeWeight(strokeW / 2.0);
  beginShape();
  for (int i = 0; i < 8; i++) {
     // Calculate vertex positions around a circle
     float angle = radians(45 * i);
     vertex(cos(angle) * innerRadius, sin(angle) * innerRadius);
  }
  endShape(CLOSE);
  popStyle(); // Restore previous style

  popMatrix(); // Restore previous transformation state
}

// Optional: Key press to save a new SVG if needed during interaction
/*
void keyPressed() {
  if (key == 's' || key == 'S') {
     // Ensure we are not already recording
     endRecord(); // End any previous recording just in case

     beginRecord(SVG, "islamic_pattern_######.svg");
     // Redraw everything needed for the new SVG
     background(255); // Clear background for new save
     // Call drawing functions again here... e.g., redraw the pattern
     translate(width / 2, height / 2);
     drawStarMotif(0, 0, patternSize);
     endRecord();
     println("New SVG saved on key press!");
  }
}
*/ 