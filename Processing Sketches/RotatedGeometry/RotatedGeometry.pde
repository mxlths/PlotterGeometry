// Pattern Generator with Rotated Geometry
// Inspired by geometric grid patterns with rotation flow

// Configuration parameters
int gridSizeX = 15;        // Number of elements in X direction
int gridSizeY = 15;        // Number of elements in Y direction
float cellSize = 30;       // Size of each grid cell
float shapeSize = 25;      // Size of shape within cell
String shapeType = "circle"; // Options: "circle", "square", "triangle"
float strokeWeight = 0.5;  // Outline thickness
boolean useOutline = true; // Whether shapes have outlines

// Colors (using HSB color mode)
color backgroundColor;
color shapeColor;
color shadingColor;
color outlineColor;

// HSB values for each element (hue, saturation, brightness)
float[] bgHSB = {30, 12, 100};       // Background HSB
float[] shapeHSB = {0, 0, 0};        // Shape HSB (black)
float[] shadingHSB = {10, 57, 92};   // Shading HSB (coral)
float[] outlineHSB = {0, 0, 0};      // Outline HSB (black)

// Pattern variables
float noiseScale = 0.1;    // Scale for Perlin noise (pattern generation)
float noiseStrength = 2.0; // How much the noise affects rotation

// UI variables
boolean showControls = true;
String[] colorLabels = {"Background", "Shape", "Shading", "Outline"};
int selectedColorIndex = 0;
int sliderX = 20;
int sliderY = 40;
int sliderWidth = 150;
int sliderHeight = 15;
int sliderSpacing = 25;
boolean isDraggingH = false;
boolean isDraggingS = false;
boolean isDraggingB = false;

// Text input variables
String gridXInput = str(gridSizeX);
String gridYInput = str(gridSizeY);
boolean editingGridX = false;
boolean editingGridY = false;
int textFieldX = 250;
int textFieldY = 40;
int textFieldWidth = 60;
int textFieldHeight = 25;
int textFieldSpacing = 40;

// Paper size variables
String[] paperSizes = {"Custom", "A5", "A4", "A3"};
int selectedPaperSize = 0;
boolean exportReady = false;

void setup() {
  size(600, 600);         // Canvas size
  smooth();               // Enable anti-aliasing
  colorMode(HSB, 360, 100, 100); // Use HSB color mode
  
  // Initialize colors based on HSB values
  updateColors();
  
  // Draw first frame
  redraw();
}

void draw() {
  if (!showControls) {
    // Static pattern mode
    noLoop();
  } else {
    // Interactive mode with controls
    loop();
  }
  
  // Draw the pattern
  drawPattern();
  
  // Draw the color controls if enabled
  if (showControls) {
    drawControls();
  }
}

void drawPattern() {
  background(backgroundColor);
  
  // Calculate the offset to center the grid
  float offsetX = (width - (gridSizeX * cellSize)) / 2;
  float offsetY = (height - (gridSizeY * cellSize)) / 2;
  
  // Add additional offset if controls are shown to center the pattern
  if (showControls) {
    offsetY += 110;
  }
  
  for (int x = 0; x < gridSizeX; x++) {
    for (int y = 0; y < gridSizeY; y++) {
      // Calculate center position of current cell
      float posX = offsetX + x * cellSize + cellSize/2;
      float posY = offsetY + y * cellSize + cellSize/2;
      
      // Calculate rotation angle based on Perlin noise
      // This creates a flowing wave-like pattern
      float angle = map(noise(x * noiseScale, y * noiseScale), 0, 1, 0, TWO_PI * noiseStrength);
      
      pushMatrix();
      translate(posX, posY);
      rotate(angle);
      
      if (useOutline) {
        stroke(outlineColor);
        strokeWeight(strokeWeight);
      } else {
        noStroke();
      }
      
      // Draw the appropriate shape
      if (shapeType.equals("circle")) {
        drawHalfCircle(shapeSize/2, shapeColor, shadingColor);
      } else if (shapeType.equals("square")) {
        drawSquare(shapeSize/2, shapeColor, shadingColor);
      } else if (shapeType.equals("triangle")) {
        drawTriangle(shapeSize/2, shapeColor, shadingColor);
      }
      
      popMatrix();
    }
  }
}

// Draw half-shaded circle
void drawHalfCircle(float radius, color c1, color c2) {
  // First half
  fill(c1);
  arc(0, 0, radius*2, radius*2, 0, PI);
  
  // Second half
  fill(c2);
  arc(0, 0, radius*2, radius*2, PI, TWO_PI);
}

// Draw half-shaded square
void drawSquare(float halfSize, color c1, color c2) {
  rectMode(CENTER);
  
  // Draw square with diagonal split
  beginShape();
  fill(c1);
  vertex(-halfSize, -halfSize);
  vertex(halfSize, -halfSize);
  vertex(halfSize, halfSize);
  vertex(-halfSize, halfSize);
  endShape(CLOSE);
  
  // Draw triangular half with second color
  fill(c2);
  beginShape();
  vertex(-halfSize, -halfSize);
  vertex(halfSize, -halfSize);
  vertex(-halfSize, halfSize);
  endShape(CLOSE);
}

// Draw half-shaded equilateral triangle
void drawTriangle(float radius, color c1, color c2) {
  float h = sqrt(3) * radius;
  
  // Draw full triangle
  fill(c1);
  beginShape();
  vertex(0, -h*2/3);           // Top
  vertex(-radius, h/3);        // Bottom left
  vertex(radius, h/3);         // Bottom right
  endShape(CLOSE);
  
  // Draw half of triangle with second color
  fill(c2);
  beginShape();
  vertex(0, -h*2/3);           // Top
  vertex(-radius, h/3);        // Bottom left
  vertex(0, h/3);              // Bottom middle
  endShape(CLOSE);
}

// Draw all controls
void drawControls() {
  // Draw control panel background
  fill(0, 0, 90);
  noStroke();
  rect(0, 0, width, 110, 0, 0, 10, 10);
  
  // Draw UI sections
  drawColorControls();
  drawGridControls();
  drawPaperControls();
  
  // Instructions
  fill(0, 0, 0);
  textAlign(LEFT, TOP);
  textSize(12);
  text("Press 'c' to toggle controls | '1-3' to change shapes | Click canvas to generate new pattern", 
       sliderX, 90);
}

// Draw color control sliders
void drawColorControls() {
  int headerY = sliderY - 15;
  
  // Draw color selector buttons
  for (int i = 0; i < colorLabels.length; i++) {
    float btnX = sliderX + i * 80;
    float btnY = headerY - 25;
    float btnW = 75;
    float btnH = 20;
    
    // Draw button background
    if (i == selectedColorIndex) {
      fill(40, 70, 90);
    } else {
      fill(40, 20, 80);
    }
    
    rect(btnX, btnY, btnW, btnH, 5);
    
    // Draw button label
    fill(0, 0, 100);
    textAlign(CENTER, CENTER);
    text(colorLabels[i], btnX + btnW/2, btnY + btnH/2);
  }
  
  // Get current HSB values based on selected color
  float[] currentHSB = getCurrentHSB();
  
  // Draw title
  fill(0, 0, 0);
  textAlign(LEFT, BOTTOM);
  textSize(14);
  text("Color: " + colorLabels[selectedColorIndex], sliderX, headerY);
  
  // Draw color preview
  fill(currentHSB[0], currentHSB[1], currentHSB[2]);
  rect(sliderX + sliderWidth + 20, sliderY, 30, sliderHeight * 3 + sliderSpacing * 2, 5);
  
  // Hue slider
  fill(0, 0, 0);
  textAlign(LEFT, CENTER);
  text("H:", sliderX - 15, sliderY + sliderHeight/2);
  
  // Draw hue slider background with gradient
  for (int i = 0; i < sliderWidth; i++) {
    float hue = map(i, 0, sliderWidth, 0, 360);
    stroke(hue, 100, 100);
    line(sliderX + i, sliderY, sliderX + i, sliderY + sliderHeight);
  }
  noStroke();
  
  // Saturation slider
  text("S:", sliderX - 15, sliderY + sliderSpacing + sliderHeight/2);
  
  // Draw saturation slider background with gradient
  for (int i = 0; i < sliderWidth; i++) {
    float sat = map(i, 0, sliderWidth, 0, 100);
    stroke(currentHSB[0], sat, currentHSB[2]);
    line(sliderX + i, sliderY + sliderSpacing, sliderX + i, sliderY + sliderSpacing + sliderHeight);
  }
  noStroke();
  
  // Brightness slider
  text("B:", sliderX - 15, sliderY + sliderSpacing*2 + sliderHeight/2);
  
  // Draw brightness slider background with gradient
  for (int i = 0; i < sliderWidth; i++) {
    float bri = map(i, 0, sliderWidth, 0, 100);
    stroke(currentHSB[0], currentHSB[1], bri);
    line(sliderX + i, sliderY + sliderSpacing*2, sliderX + i, sliderY + sliderSpacing*2 + sliderHeight);
  }
  noStroke();
  
  // Draw slider handles
  fill(0, 0, 100);
  stroke(0, 0, 0);
  float hPos = map(currentHSB[0], 0, 360, 0, sliderWidth);
  float sPos = map(currentHSB[1], 0, 100, 0, sliderWidth);
  float bPos = map(currentHSB[2], 0, 100, 0, sliderWidth);
  
  // Hue handle
  rect(sliderX + hPos - 5, sliderY - 2, 10, sliderHeight + 4, 2);
  
  // Saturation handle
  rect(sliderX + sPos - 5, sliderY + sliderSpacing - 2, 10, sliderHeight + 4, 2);
  
  // Brightness handle
  rect(sliderX + bPos - 5, sliderY + sliderSpacing*2 - 2, 10, sliderHeight + 4, 2);
}

// Draw grid control input fields
void drawGridControls() {
  // Draw header
  fill(0, 0, 0);
  textAlign(LEFT, BOTTOM);
  textSize(14);
  text("Grid Size:", textFieldX, sliderY - 15);
  
  // X dimension input field
  drawTextField(textFieldX, textFieldY, textFieldWidth, textFieldHeight, "X:", gridXInput, editingGridX);
  
  // Y dimension input field
  drawTextField(textFieldX + textFieldWidth + 20, textFieldY, textFieldWidth, textFieldHeight, "Y:", gridYInput, editingGridY);
  
  // Apply button
  float applyBtnX = textFieldX + textFieldWidth*2 + 30;
  float applyBtnY = textFieldY;
  float applyBtnW = 60;
  float applyBtnH = textFieldHeight;
  
  // Draw apply button
  fill(120, 70, 80);
  rect(applyBtnX, applyBtnY, applyBtnW, applyBtnH, 5);
  
  // Draw button text
  fill(0, 0, 100);
  textAlign(CENTER, CENTER);
  text("Apply", applyBtnX + applyBtnW/2, applyBtnY + applyBtnH/2);
}

// Draw input text field
void drawTextField(float x, float y, float w, float h, String label, String content, boolean isActive) {
  // Draw label
  fill(0, 0, 0);
  textAlign(RIGHT, CENTER);
  text(label, x - 5, y + h/2);
  
  // Draw text field background
  if (isActive) {
    fill(0, 0, 100);
    stroke(0, 0, 50);
    strokeWeight(2);
  } else {
    fill(0, 0, 95);
    stroke(0, 0, 70);
    strokeWeight(1);
  }
  
  rect(x, y, w, h, 5);
  noStroke();
  
  // Draw text content
  fill(0, 0, 0);
  textAlign(CENTER, CENTER);
  text(content, x + w/2, y + h/2);
}

// Draw paper size controls
void drawPaperControls() {
  // Draw header
  fill(0, 0, 0);
  textAlign(LEFT, BOTTOM);
  textSize(14);
  text("Paper Size:", textFieldX, textFieldY + textFieldSpacing);
  
  // Draw paper size buttons
  for (int i = 0; i < paperSizes.length; i++) {
    float btnX = textFieldX + i * 70;
    float btnY = textFieldY + textFieldSpacing + 5;
    float btnW = 60;
    float btnH = 20;
    
    // Draw button background
    if (i == selectedPaperSize) {
      fill(120, 70, 80);
    } else {
      fill(120, 20, 90);
    }
    
    rect(btnX, btnY, btnW, btnH, 5);
    
    // Draw button label
    if (i == selectedPaperSize) {
      fill(0, 0, 100);
    } else {
      fill(0, 0, 0);
    }
    textAlign(CENTER, CENTER);
    text(paperSizes[i], btnX + btnW/2, btnY + btnH/2);
  }
  
  // Draw export button (for future SVG export)
  float exportBtnX = textFieldX + 280;
  float exportBtnY = textFieldY + textFieldSpacing + 5;
  float exportBtnW = 80;
  float exportBtnH = 20;
  
  // Draw button but make it disabled for now
  if (exportReady) {
    fill(160, 70, 80);
  } else {
    fill(0, 0, 80);
  }
  rect(exportBtnX, exportBtnY, exportBtnW, exportBtnH, 5);
  
  // Draw button text
  fill(0, 0, 100);
  textAlign(CENTER, CENTER);
  text("Export SVG", exportBtnX + exportBtnW/2, exportBtnY + exportBtnH/2);
}

// Get the current HSB values based on selected color
float[] getCurrentHSB() {
  switch (selectedColorIndex) {
    case 0: return bgHSB;
    case 1: return shapeHSB;
    case 2: return shadingHSB;
    case 3: return outlineHSB;
    default: return bgHSB;
  }
}

// Update colors from HSB values
void updateColors() {
  backgroundColor = color(bgHSB[0], bgHSB[1], bgHSB[2]);
  shapeColor = color(shapeHSB[0], shapeHSB[1], shapeHSB[2]);
  shadingColor = color(shadingHSB[0], shadingHSB[1], shadingHSB[2]);
  outlineColor = color(outlineHSB[0], outlineHSB[1], outlineHSB[2]);
}

// Apply the grid size changes
void applyGridChanges() {
  try {
    int newGridX = int(gridXInput);
    int newGridY = int(gridYInput);
    
    // Validate input
    if (newGridX > 0 && newGridY > 0 && newGridX <= 100 && newGridY <= 100) {
      gridSizeX = newGridX;
      gridSizeY = newGridY;
      updateCanvasSize();
    } else {
      // Reset to current values if invalid
      gridXInput = str(gridSizeX);
      gridYInput = str(gridSizeY);
    }
  } catch (Exception e) {
    // Reset to current values if error
    gridXInput = str(gridSizeX);
    gridYInput = str(gridSizeY);
  }
}

// Apply the selected paper size
void applyPaperSize(int index) {
  selectedPaperSize = index;
  
  // Set dimensions based on paper size
  switch (index) {
    case 0: // Custom - keep current settings
      break;
    case 1: // A5 (148 × 210 mm)
      resizeToAspectRatio(148, 210);
      break;
    case 2: // A4 (210 × 297 mm)
      resizeToAspectRatio(210, 297);
      break;
    case 3: // A3 (297 × 420 mm)
      resizeToAspectRatio(297, 420);
      break;
  }
  
  // Update canvas after changing paper size
  updateCanvasSize();
}

// Resize to match paper aspect ratio
void resizeToAspectRatio(float w, float h) {
  // Keep width fixed at 600px by default
  float baseWidth = 600;
  float baseHeight = (baseWidth / w) * h;
  
  // Adjust gridSizeX and gridSizeY to match the aspect ratio
  float ratio = w / h;
  
  if (ratio < 1) {
    // Portrait orientation
    gridSizeY = ceil(gridSizeX / ratio);
  } else {
    // Landscape orientation
    gridSizeX = ceil(gridSizeY * ratio);
  }
  
  // Update input fields
  gridXInput = str(gridSizeX);
  gridYInput = str(gridSizeY);
  
  // Set window size
  surface.setSize(int(baseWidth), int(baseHeight));
}

// Update canvas size based on grid dimensions
void updateCanvasSize() {
  float requiredWidth = gridSizeX * cellSize + 40;  // Add some padding
  float requiredHeight = gridSizeY * cellSize + (showControls ? 150 : 40);  // Add padding and control panel height if needed
  
  surface.setSize(int(requiredWidth), int(requiredHeight));
}

// Check if mouse is over a slider handle
boolean isOverSliderHandle(float handlePos, float sliderY) {
  return (mouseX >= sliderX + handlePos - 5 && 
          mouseX <= sliderX + handlePos + 5 &&
          mouseY >= sliderY - 2 && 
          mouseY <= sliderY + sliderHeight + 2);
}

// Check if a point is inside a rectangle
boolean isPointInRect(float px, float py, float rx, float ry, float rw, float rh) {
  return (px >= rx && px <= rx + rw && py >= ry && py <= ry + rh);
}

// Function to handle key events
void keyPressed() {
  if (key == '1') shapeType = "circle";
  if (key == '2') shapeType = "square";
  if (key == '3') shapeType = "triangle";
  
  // Toggle controls visibility
  if (key == 'c' || key == 'C') {
    showControls = !showControls;
    if (showControls) {
      loop();
    } else {
      redraw();
    }
    updateCanvasSize();
  }
  
  // Handle text input for grid size fields
  if (editingGridX || editingGridY) {
    // Store which field is being edited
    String currentField = editingGridX ? gridXInput : gridYInput;
    
    if (key == ENTER || key == RETURN || key == TAB) {
      // Apply changes when Enter or Tab is pressed
      editingGridX = false;
      editingGridY = false;
      applyGridChanges();
    } else if (key == ESC) {
      // Cancel editing when Escape is pressed
      editingGridX = false;
      editingGridY = false;
      // Reset to current values
      gridXInput = str(gridSizeX);
      gridYInput = str(gridSizeY);
    } else if (key == BACKSPACE && currentField.length() > 0) {
      // Handle backspace
      currentField = currentField.substring(0, currentField.length() - 1);
    } else if (key >= '0' && key <= '9') {
      // Only allow numeric input
      currentField += key;
    }
    
    // Update the appropriate field
    if (editingGridX) {
      gridXInput = currentField;
    } else if (editingGridY) {
      gridYInput = currentField;
    }
  } else {
    // Adjust noise parameters with arrow keys
    if (keyCode == UP) noiseScale += 0.01;
    if (keyCode == DOWN) noiseScale -= 0.01;
    if (keyCode == RIGHT) noiseStrength += 0.2;
    if (keyCode == LEFT) noiseStrength -= 0.2;
    
    // Constrain values to reasonable ranges
    noiseScale = constrain(noiseScale, 0.01, 0.5);
    noiseStrength = constrain(noiseStrength, 0.2, 5.0);
  }
  
  // Redraw with new settings
  redraw();
}

void mousePressed() {
  if (!showControls) {
    // If controls are hidden, generate new pattern when clicking
    noiseSeed(int(random(10000)));
    redraw();
    return;
  }
  
  // Check if user clicked on a text field
  if (isPointInRect(mouseX, mouseY, textFieldX, textFieldY, textFieldWidth, textFieldHeight)) {
    editingGridX = true;
    editingGridY = false;
    return;
  }
  
  if (isPointInRect(mouseX, mouseY, textFieldX + textFieldWidth + 20, textFieldY, textFieldWidth, textFieldHeight)) {
    editingGridX = false;
    editingGridY = true;
    return;
  }
  
  // Check if Apply button was clicked
  if (isPointInRect(mouseX, mouseY, textFieldX + textFieldWidth*2 + 30, textFieldY, 60, textFieldHeight)) {
    applyGridChanges();
    editingGridX = false;
    editingGridY = false;
    return;
  }
  
  // Check if a paper size button was clicked
  for (int i = 0; i < paperSizes.length; i++) {
    float btnX = textFieldX + i * 70;
    float btnY = textFieldY + textFieldSpacing + 5;
    float btnW = 60;
    float btnH = 20;
    
    if (isPointInRect(mouseX, mouseY, btnX, btnY, btnW, btnH)) {
      applyPaperSize(i);
      return;
    }
  }
  
  // Check if export button was clicked
  if (isPointInRect(mouseX, mouseY, textFieldX + 280, textFieldY + textFieldSpacing + 5, 80, 20)) {
    if (exportReady) {
      // Export functionality will be added later
      println("SVG export would happen here");
    }
    return;
  }
  
  // Check if a color selector button was clicked
  for (int i = 0; i < colorLabels.length; i++) {
    float btnX = sliderX + i * 80;
    float btnY = sliderY - 15 - 25;
    float btnW = 75;
    float btnH = 20;
    
    if (isPointInRect(mouseX, mouseY, btnX, btnY, btnW, btnH)) {
      selectedColorIndex = i;
      return;
    }
  }
  
  // Get current HSB values
  float[] currentHSB = getCurrentHSB();
  
  // Calculate slider handle positions
  float hPos = map(currentHSB[0], 0, 360, 0, sliderWidth);
  float sPos = map(currentHSB[1], 0, 100, 0, sliderWidth);
  float bPos = map(currentHSB[2], 0, 100, 0, sliderWidth);
  
  // Check if a slider handle is being dragged
  if (isOverSliderHandle(hPos, sliderY)) {
    isDraggingH = true;
  } else if (isOverSliderHandle(sPos, sliderY + sliderSpacing)) {
    isDraggingS = true;
  } else if (isOverSliderHandle(bPos, sliderY + sliderSpacing*2)) {
    isDraggingB = true;
  } else if (mouseY > 110) {
    // If clicked on pattern area, generate new pattern
    noiseSeed(int(random(10000)));
    redraw();
  }
}

void mouseDragged() {
  if (!showControls) return;
  
  float[] currentHSB = getCurrentHSB();
  
  // Update slider values if being dragged
  if (isDraggingH) {
    float newHue = map(constrain(mouseX, sliderX, sliderX + sliderWidth), sliderX, sliderX + sliderWidth, 0, 360);
    currentHSB[0] = newHue;
  } else if (isDraggingS) {
    float newSat = map(constrain(mouseX, sliderX, sliderX + sliderWidth), sliderX, sliderX + sliderWidth, 0, 100);
    currentHSB[1] = newSat;
  } else if (isDraggingB) {
    float newBri = map(constrain(mouseX, sliderX, sliderX + sliderWidth), sliderX, sliderX + sliderWidth, 0, 100);
    currentHSB[2] = newBri;
  }
  
  // Update colors
  updateColors();
}

void mouseReleased() {
  isDraggingH = false;
  isDraggingS = false;
  isDraggingB = false;
}
