// InterpolatedCircleWithOffSets P5.js Port
// A port of the Processing sketch to P5.js

// Global variables
let n = 7; // Number of points
let offset = 2.0; // Offset for the radius
let radiusScale = 50; // Scale factor for the radius units
let minPoints = 3;

// Duplication parameters
let numShrinkingDuplicates = 5; // Renamed from numDuplicates
let numGrowingDuplicates = 5;   // New parameter
let initialScaleOffset = 1.1; 
let scaleDecay = 0.9;       
let fluctuationAmount = 0.1;

// Data structures for storing random values
let points = []; // Stores calculated positions
let baseRandomDistances = []; // Stores random distance (1-7) for base shape
let fluctuationOffsets = []; // Stores random factor (-1 to 1) for fluctuation [duplicate][point]

// UI controls
let nInput, offsetInput, numShrinkingDuplicatesInput, numGrowingDuplicatesInput; 
let initialScaleOffsetInput, scaleDecayInput, fluctuationAmountInput;
let regenerateButton;

// SVG recording variables
let recordSVG = false;
let svgGraphics;

function setup() {
  createCanvas(2036, 1440);
  
  // Create UI controls
  let inputX = 160;
  let inputY = 10;
  let inputW = 60;
  let inputH = 20;
  let spacing = 30;
  let currentY = inputY;
  
  // Create label/input pairs
  createLabel("Points (N):", 10, currentY + 4);
  nInput = createInput(n.toString());
  nInput.position(inputX, currentY);
  nInput.size(inputW, inputH);
  nInput.input(updateN);
  
  currentY += spacing;
  createLabel("Radius Offset:", 10, currentY + 4);
  offsetInput = createInput(offset.toFixed(1));
  offsetInput.position(inputX, currentY);
  offsetInput.size(inputW, inputH);
  offsetInput.input(updateOffset);
  
  currentY += spacing;
  createLabel("Shrinking Duplicates:", 10, currentY + 4);
  numShrinkingDuplicatesInput = createInput(numShrinkingDuplicates.toString());
  numShrinkingDuplicatesInput.position(inputX, currentY);
  numShrinkingDuplicatesInput.size(inputW, inputH);
  numShrinkingDuplicatesInput.input(updateNumShrinkingDuplicates);
  
  currentY += spacing;
  createLabel("Growing Duplicates:", 10, currentY + 4);
  numGrowingDuplicatesInput = createInput(numGrowingDuplicates.toString());
  numGrowingDuplicatesInput.position(inputX, currentY);
  numGrowingDuplicatesInput.size(inputW, inputH);
  numGrowingDuplicatesInput.input(updateNumGrowingDuplicates);
  
  currentY += spacing;
  createLabel("Initial Scale:", 10, currentY + 4);
  initialScaleOffsetInput = createInput(initialScaleOffset.toFixed(2));
  initialScaleOffsetInput.position(inputX, currentY);
  initialScaleOffsetInput.size(inputW, inputH);
  initialScaleOffsetInput.input(updateInitialScaleOffset);
  
  currentY += spacing;
  createLabel("Scale Decay:", 10, currentY + 4);
  scaleDecayInput = createInput(scaleDecay.toFixed(2));
  scaleDecayInput.position(inputX, currentY);
  scaleDecayInput.size(inputW, inputH);
  scaleDecayInput.input(updateScaleDecay);
  
  currentY += spacing;
  createLabel("Fluctuation:", 10, currentY + 4);
  fluctuationAmountInput = createInput(fluctuationAmount.toFixed(2));
  fluctuationAmountInput.position(inputX, currentY);
  fluctuationAmountInput.size(inputW, inputH);
  fluctuationAmountInput.input(updateFluctuationAmount);
  
  // Regenerate button
  currentY += spacing + 10;
  regenerateButton = createButton("Regenerate");
  regenerateButton.position(10, currentY);
  regenerateButton.size(100, inputH + 5);
  regenerateButton.mousePressed(regeneratePattern);
  
  // Initialize data and generate pattern
  regeneratePattern();
}

// Helper function to create labels
function createLabel(text, x, y) {
  let label = createElement('div', text);
  label.position(x, y);
  label.style('color', 'black');
  label.style('font-family', 'Arial');
  label.style('font-size', '14px');
  return label;
}

// Function to generate and store all random values
function regeneratePattern() {
  console.log("Regenerating pattern...");
  baseRandomDistances = [];
  fluctuationOffsets = [];

  // Generate base distances
  for (let i = 0; i < n; i++) {
    baseRandomDistances.push(random(1, 7));
  }

  // Generate fluctuation offsets for all potential duplicates
  let totalMaxDuplicates = max(max(0, numShrinkingDuplicates), max(0, numGrowingDuplicates));
  for (let d = 0; d < totalMaxDuplicates; d++) {
    let currentDuplicateOffsets = [];
    for (let i = 0; i < n; i++) {
      currentDuplicateOffsets.push(random(-1, 1)); // Store factor -1 to 1
    }
    fluctuationOffsets.push(currentDuplicateOffsets);
  }
  
  calculatePoints(); // Calculate positions based on new random data
}

// Calculate point positions using stored random base distances
function calculatePoints() {
  n = max(minPoints, n); // Ensure n is valid
  
  // Ensure baseRandomDistances list matches current n
  while (baseRandomDistances.length < n) baseRandomDistances.push(random(1, 7));
  while (baseRandomDistances.length > n) baseRandomDistances.pop();

  // Update textfield if clamped
  if (n !== parseInt(nInput.value())) {
    nInput.value(n.toString());
  }

  points = []; // Clear previous positions
  let centerX = width / 2.0;
  let centerY = height / 2.0;
  for (let i = 0; i < n; i++) {
    let angle = map(i, 0, n, 0, TWO_PI);
    let baseDist = baseRandomDistances[i]; // Use stored random value
    let dist = (baseDist + offset) * radiusScale;
    let x = centerX + cos(angle) * dist;
    let y = centerY + sin(angle) * dist;
    points.push(createVector(x, y));
  }
}

// Use stored fluctuation offset
function getFluctuatedScaledPoint(originalPoint, center, totalScale, 
                               duplicateIndex, pointIndex, 
                               fluctAmountUnits, scaleUnits) {
  let scaledP = p5.Vector.sub(originalPoint, center);
  scaledP.mult(totalScale);
  scaledP.add(center);

  let dir = p5.Vector.sub(originalPoint, center);
  if (dir.magSq() > 1e-6) {
    dir.normalize();
    
    // Get stored fluctuation factor
    let fluctFactor = 0;
    // Check bounds before accessing fluctuationOffsets
    if (duplicateIndex >= 0 && duplicateIndex < fluctuationOffsets.length) {
       let currentDupOffsets = fluctuationOffsets[duplicateIndex];
       if (pointIndex >= 0 && pointIndex < currentDupOffsets.length) {
            fluctFactor = currentDupOffsets[pointIndex];
       }
    }

    let randFluctPixels = fluctFactor * fluctAmountUnits * scaleUnits;
    let fluctVec = p5.Vector.mult(dir, randFluctPixels);
    scaledP.add(fluctVec); 
  }
  return scaledP;
}

// Helper function to draw one curve
function drawFluctuatedCurve(totalScale, duplicateIndex) {
    if (totalScale <= 1e-6) return; // Skip if scale is too small/negative
    if (points === null || points.length < n || n < minPoints) return; // Safety checks

    let center = createVector(width / 2.0, height / 2.0);
    
    beginShape();
    // Control points (indices n-1, 0, 1)
    let fluctuatedLastP = getFluctuatedScaledPoint(points[n - 1], center, totalScale, duplicateIndex, n - 1, fluctuationAmount, radiusScale);
    curveVertex(fluctuatedLastP.x, fluctuatedLastP.y);

    // Main points (indices 0 to n-1)
    for (let i = 0; i < n; i++) {
        let fluctuatedP = getFluctuatedScaledPoint(points[i], center, totalScale, duplicateIndex, i, fluctuationAmount, radiusScale);
        curveVertex(fluctuatedP.x, fluctuatedP.y);
    }

    // Closing control points (indices 0, 1)
    let fluctuatedFirstP = getFluctuatedScaledPoint(points[0], center, totalScale, duplicateIndex, 0, fluctuationAmount, radiusScale);
    curveVertex(fluctuatedFirstP.x, fluctuatedFirstP.y);
    let fluctuatedSecondP = getFluctuatedScaledPoint(points[1], center, totalScale, duplicateIndex, 1, fluctuationAmount, radiusScale);
    curveVertex(fluctuatedSecondP.x, fluctuatedSecondP.y);

    endShape();
}

function draw() {
  // Handle SVG recording if needed
  if (recordSVG) {
    console.log("Starting SVG record...");
    svgGraphics = createGraphics(width, height, SVG);
    svgGraphics.background(255);
    drawPattern(svgGraphics);
    save(svgGraphics, "InterpolatedCircle-" + getTimestamp() + ".svg");
    console.log("SVG record finished.");
    recordSVG = false;
    if (svgGraphics) {
      svgGraphics.remove();
      svgGraphics = null;
    }
  } else {
    // Normal drawing to the screen
    background(255);
    drawPattern(this);
  }
}

function drawPattern(g) {
  let center = createVector(width / 2.0, height / 2.0);
  
  if (points !== null && points.length >= n && n >= minPoints) { 
    g.stroke(0); 
    g.strokeWeight(1); 
    g.noFill(); 

    // --- Draw Original Curve ---
    g.beginShape();
    g.curveVertex(points[n - 1].x, points[n - 1].y); 
    for (let i = 0; i < n; i++) {
      g.curveVertex(points[i].x, points[i].y);
    }
    g.curveVertex(points[0].x, points[0].y);
    g.curveVertex(points[1].x, points[1].y); 
    g.endShape();

    // --- Draw Shrinking Gap Duplicates ---
    let effectiveShrinkingDuplicates = max(0, numShrinkingDuplicates);
    let firstOffsetAmount = max(0, initialScaleOffset - 1.0); 
    let currentShrinkingScale = 1.0; 
    
    for (let d = 0; d < effectiveShrinkingDuplicates; d++) { 
      let offsetThisStep = firstOffsetAmount * Math.pow(scaleDecay, d); 
      currentShrinkingScale += offsetThisStep;
      
      // Draw curve with current scale
      g.beginShape();
      
      // Control points (indices n-1, 0, 1)
      let fluctuatedLastP = getFluctuatedScaledPoint(points[n - 1], center, currentShrinkingScale, d, n - 1, fluctuationAmount, radiusScale);
      g.curveVertex(fluctuatedLastP.x, fluctuatedLastP.y);

      // Main points (indices 0 to n-1)
      for (let i = 0; i < n; i++) {
        let fluctuatedP = getFluctuatedScaledPoint(points[i], center, currentShrinkingScale, d, i, fluctuationAmount, radiusScale);
        g.curveVertex(fluctuatedP.x, fluctuatedP.y);
      }

      // Closing control points (indices 0, 1)
      let fluctuatedFirstP = getFluctuatedScaledPoint(points[0], center, currentShrinkingScale, d, 0, fluctuationAmount, radiusScale);
      g.curveVertex(fluctuatedFirstP.x, fluctuatedFirstP.y);
      let fluctuatedSecondP = getFluctuatedScaledPoint(points[1], center, currentShrinkingScale, d, 1, fluctuationAmount, radiusScale);
      g.curveVertex(fluctuatedSecondP.x, fluctuatedSecondP.y);

      g.endShape();
    }
    
    // Capture the final scale after shrinking duplicates
    let lastShrinkingScale = currentShrinkingScale; // Will be 1.0 if loop didn't run

    // --- Draw Growing Gap Duplicates ---
    let effectiveGrowingDuplicates = max(0, numGrowingDuplicates);
    let growthFactor = (Math.abs(scaleDecay) > 1e-6) ? (1.0 / scaleDecay) : 1000.0; 
    // Initialize growing scale from the last shrinking scale
    let currentGrowingScale = lastShrinkingScale;
    
    // The duplicate index for fluctuation should continue from shrinking ones if possible,
    // but fluctuationOffsets is sized for max(shrink, grow), so using d_grow is safe
    // and ensures unique fluctuation per visual ring.
    for (let d_grow = 0; d_grow < effectiveGrowingDuplicates; d_grow++) {
      let offsetThisStep = firstOffsetAmount * Math.pow(growthFactor, d_grow); 
      currentGrowingScale += offsetThisStep;
      
      // Draw curve with current scale
      g.beginShape();
      
      // Control points (indices n-1, 0, 1)
      let fluctuatedLastP = getFluctuatedScaledPoint(points[n - 1], center, currentGrowingScale, d_grow, n - 1, fluctuationAmount, radiusScale);
      g.curveVertex(fluctuatedLastP.x, fluctuatedLastP.y);

      // Main points (indices 0 to n-1)
      for (let i = 0; i < n; i++) {
        let fluctuatedP = getFluctuatedScaledPoint(points[i], center, currentGrowingScale, d_grow, i, fluctuationAmount, radiusScale);
        g.curveVertex(fluctuatedP.x, fluctuatedP.y);
      }

      // Closing control points (indices 0, 1)
      let fluctuatedFirstP = getFluctuatedScaledPoint(points[0], center, currentGrowingScale, d_grow, 0, fluctuationAmount, radiusScale);
      g.curveVertex(fluctuatedFirstP.x, fluctuatedFirstP.y);
      let fluctuatedSecondP = getFluctuatedScaledPoint(points[1], center, currentGrowingScale, d_grow, 1, fluctuationAmount, radiusScale);
      g.curveVertex(fluctuatedSecondP.x, fluctuatedSecondP.y);

      g.endShape();
    }
  }
}

// Input update handlers
function updateN() {
  try {
    let newN = parseInt(nInput.value());
    if (newN !== n && !isNaN(newN)) {
        n = max(minPoints, newN);
        regeneratePattern(); // Regenerate random data and recalculate points
    }
  } catch (e) {
    console.log("Invalid input for n: " + nInput.value());
    nInput.value(n.toString());
  }
}

function updateOffset() {
  try {
    let newOffset = parseFloat(offsetInput.value());
    if (newOffset !== offset && !isNaN(newOffset)) {
        offset = newOffset;
        calculatePoints(); // Only recalculate positions
    }
  } catch (e) {
    console.log("Invalid input for offset: " + offsetInput.value());
    offsetInput.value(offset.toFixed(1));
  }
}

function updateNumShrinkingDuplicates() {
  try {
    let newNum = parseInt(numShrinkingDuplicatesInput.value());
    if (!isNaN(newNum)) {
      numShrinkingDuplicates = max(0, newNum);
      // Check if fluctuation data needs resizing
      let totalMaxDuplicates = max(numShrinkingDuplicates, max(0, numGrowingDuplicates));
      while (fluctuationOffsets.length < totalMaxDuplicates) {
        let newDupOffsets = [];
        for(let i=0; i<n; i++) newDupOffsets.push(random(-1, 1));
        fluctuationOffsets.push(newDupOffsets);
      }
      if (numShrinkingDuplicates !== newNum) {
        numShrinkingDuplicatesInput.value(numShrinkingDuplicates.toString());
      }
    }
  } catch (e) {
    console.log("Invalid input for numShrinkingDuplicates: " + numShrinkingDuplicatesInput.value());
    numShrinkingDuplicatesInput.value(numShrinkingDuplicates.toString());
  }
}

function updateNumGrowingDuplicates() {
  try {
    let newNum = parseInt(numGrowingDuplicatesInput.value());
    if (!isNaN(newNum)) {
      numGrowingDuplicates = max(0, newNum);
      // Check if fluctuation data needs resizing
      let totalMaxDuplicates = max(max(0, numShrinkingDuplicates), numGrowingDuplicates);
      while (fluctuationOffsets.length < totalMaxDuplicates) {
        let newDupOffsets = [];
        for(let i=0; i<n; i++) newDupOffsets.push(random(-1, 1));
        fluctuationOffsets.push(newDupOffsets);
      }
      if (numGrowingDuplicates !== newNum) {
        numGrowingDuplicatesInput.value(numGrowingDuplicates.toString());
      }
    }
  } catch (e) {
    console.log("Invalid input for numGrowingDuplicates: " + numGrowingDuplicatesInput.value());
    numGrowingDuplicatesInput.value(numGrowingDuplicates.toString());
  }
}

function updateInitialScaleOffset() {
  try {
    let newScale = parseFloat(initialScaleOffsetInput.value());
    if (!isNaN(newScale)) {
      initialScaleOffset = max(0, newScale); 
      if (initialScaleOffset !== newScale) {
        initialScaleOffsetInput.value(initialScaleOffset.toFixed(2));
      }
    }
  } catch (e) {
    console.log("Invalid input for initialScaleOffset: " + initialScaleOffsetInput.value());
    initialScaleOffsetInput.value(initialScaleOffset.toFixed(2));
  }
}

function updateScaleDecay() {
  try {
    let newDecay = parseFloat(scaleDecayInput.value());
    if (!isNaN(newDecay)) {
      scaleDecay = max(0, newDecay); 
      if (scaleDecay !== newDecay) {
        scaleDecayInput.value(scaleDecay.toFixed(2));
      }
    }
  } catch (e) {
    console.log("Invalid input for scaleDecay: " + scaleDecayInput.value());
    scaleDecayInput.value(scaleDecay.toFixed(2));
  }
}

function updateFluctuationAmount() {
  try {
    let newFluct = parseFloat(fluctuationAmountInput.value());
    if (!isNaN(newFluct)) {
      fluctuationAmount = max(0, newFluct); 
      if (fluctuationAmount !== newFluct) {
        fluctuationAmountInput.value(fluctuationAmount.toFixed(2));
      }
    }
  } catch (e) {
    console.log("Invalid input for fluctuationAmount: " + fluctuationAmountInput.value());
    fluctuationAmountInput.value(fluctuationAmount.toFixed(2));
  }
}

// Helper function to generate timestamp string
function getTimestamp() {
  let now = new Date();
  return now.getFullYear().toString().padStart(4, '0') + 
         (now.getMonth() + 1).toString().padStart(2, '0') + 
         now.getDate().toString().padStart(2, '0') + "_" + 
         now.getHours().toString().padStart(2, '0') + 
         now.getMinutes().toString().padStart(2, '0') + 
         now.getSeconds().toString().padStart(2, '0');
}

// Handle key events 
function keyPressed() {
  if (key === 's' || key === 'S') {
      if (!recordSVG) { // Prevent triggering multiple saves at once
          console.log("Setting recordSVG flag to true");
          recordSVG = true;
      }
  }
} 