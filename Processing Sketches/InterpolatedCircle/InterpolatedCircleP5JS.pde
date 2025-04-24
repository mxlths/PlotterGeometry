// InterpolatedCircle P5.js Port
// A port of the Processing sketch to P5.js

// Global variables
let n = 7; // Number of points
let offset = 2.0; // Offset for the radius
let radiusScale = 50; // Scale factor for the radius units
let minPoints = 3;

// Duplication parameters
let cycleCount = 100; // Total duplicates in one shrink-then-grow cycle
let numberOfCycles = 1; // Number of times to repeat the cycle
let initialScaleOffset = 1.1;
let scaleDecay = 0.9;
let fluctuationAmount = 0.1;
let drawMode = 0; // 0 = curves, 1 = radial lines
let radialLineLengthUnits = 0.05;
let segmentsPerCurve = 100; // Number of radial lines per curve path
let lineRotationDegrees = 15.0; // Rotation angle for each set of lines in degrees

// Data structures for storing random values
let points = []; // Stores calculated positions
let baseRandomDistances = []; // Stores random distance (1-7) for base shape
let fluctuationOffsets = []; // Stores random factor (-1 to 1) for fluctuation [duplicate][point]

// UI controls
let nInput, offsetInput, cycleCountInput, numberOfCyclesInput, initialScaleOffsetInput;
let scaleDecayInput, fluctuationAmountInput, drawModeInput, radialLengthInput;
let segmentsPerCurveInput, lineRotationDegreesInput;
let regenerateButton, exportSVGButton;

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
  createLabel("Cycle Count:", 10, currentY + 4);
  cycleCountInput = createInput(cycleCount.toString());
  cycleCountInput.position(inputX, currentY);
  cycleCountInput.size(inputW, inputH);
  cycleCountInput.input(updateCycleCount);
  
  currentY += spacing;
  createLabel("Number of Cycles:", 10, currentY + 4);
  numberOfCyclesInput = createInput(numberOfCycles.toString());
  numberOfCyclesInput.position(inputX, currentY);
  numberOfCyclesInput.size(inputW, inputH);
  numberOfCyclesInput.input(updateNumberOfCycles);
  
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
  
  currentY += spacing;
  createLabel("Draw Mode (0/1):", 10, currentY + 4);
  drawModeInput = createInput(drawMode.toString());
  drawModeInput.position(inputX, currentY);
  drawModeInput.size(inputW, inputH);
  drawModeInput.input(updateDrawMode);
  
  currentY += spacing;
  createLabel("Radial Length:", 10, currentY + 4);
  radialLengthInput = createInput(radialLineLengthUnits.toFixed(2));
  radialLengthInput.position(inputX, currentY);
  radialLengthInput.size(inputW, inputH);
  radialLengthInput.input(updateRadialLineLength);
  
  currentY += spacing;
  createLabel("Segments Per Curve:", 10, currentY + 4);
  segmentsPerCurveInput = createInput(segmentsPerCurve.toString());
  segmentsPerCurveInput.position(inputX, currentY);
  segmentsPerCurveInput.size(inputW, inputH);
  segmentsPerCurveInput.input(updateSegmentsPerCurve);
  
  currentY += spacing;
  createLabel("Line Rotation (deg):", 10, currentY + 4);
  lineRotationDegreesInput = createInput(lineRotationDegrees.toFixed(1));
  lineRotationDegreesInput.position(inputX, currentY);
  lineRotationDegreesInput.size(inputW, inputH);
  lineRotationDegreesInput.input(updateLineRotationDegrees);
  
  // Buttons
  currentY += spacing + 10;
  regenerateButton = createButton("Regenerate");
  regenerateButton.position(10, currentY);
  regenerateButton.size(100, inputH + 5);
  regenerateButton.mousePressed(regeneratePattern);
  
  exportSVGButton = createButton("Export SVG");
  exportSVGButton.position(120, currentY);
  exportSVGButton.size(100, inputH + 5);
  exportSVGButton.mousePressed(exportSVG);
  
  // Initialize data and generate pattern
  regeneratePattern();
}

// Helper function to create labels
function createLabel(text, x, y) {
  let label = createElement('div', text);
  label.position(x, y);
  label.style('color', 'red');
  label.style('font-family', 'Arial');
  label.style('font-size', '14px');
  return label;
}

// Function to generate and store all random values
function regeneratePattern() {
  console.log("Regenerating pattern...");
  cycleCount = max(2, cycleCount);
  numberOfCycles = max(1, numberOfCycles);
  let totalDuplicates = cycleCount * numberOfCycles;
  
  baseRandomDistances = [];
  fluctuationOffsets = [];

  // Generate base distances
  for (let i = 0; i < n; i++) {
    baseRandomDistances.push(random(1, 7));
  }

  // Generate fluctuation offsets for all potential duplicates
  for (let d = 0; d < totalDuplicates; d++) {
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
function drawFluctuatedCurve(g, center, totalScale, duplicateIndex) {
    if (totalScale <= 1e-6) return; // Skip if scale is too small/negative
    if (points === null || points.length < n || n < minPoints) return; // Safety checks

    g.beginShape();
    // Control points (indices n-1, 0, 1)
    let fluctuatedLastP = getFluctuatedScaledPoint(points[n - 1], center, totalScale, duplicateIndex, n - 1, fluctuationAmount, radiusScale);
    g.curveVertex(fluctuatedLastP.x, fluctuatedLastP.y);

    // Main points (indices 0 to n-1)
    for (let i = 0; i < n; i++) {
        let fluctuatedP = getFluctuatedScaledPoint(points[i], center, totalScale, duplicateIndex, i, fluctuationAmount, radiusScale);
        g.curveVertex(fluctuatedP.x, fluctuatedP.y);
    }

    // Closing control points (indices 0, 1)
    let fluctuatedFirstP = getFluctuatedScaledPoint(points[0], center, totalScale, duplicateIndex, 0, fluctuationAmount, radiusScale);
    g.curveVertex(fluctuatedFirstP.x, fluctuatedFirstP.y);
    let fluctuatedSecondP = getFluctuatedScaledPoint(points[1], center, totalScale, duplicateIndex, 1, fluctuationAmount, radiusScale);
    g.curveVertex(fluctuatedSecondP.x, fluctuatedSecondP.y);

    g.endShape();
}

// Helper function to draw a short radial line *inward* from a point towards the center
function drawInwardRadialLine(g, point, center, lengthPixels) {
    let dirToCenter = p5.Vector.sub(center, point);
    if (dirToCenter.magSq() < 1e-6) return; // Avoid drawing for points at the center
    dirToCenter.normalize();
    let endPoint = p5.Vector.add(point, p5.Vector.mult(dirToCenter, lengthPixels)); // Move towards center
    g.line(point.x, point.y, endPoint.x, endPoint.y);
}

// Helper function to draw a rotated radial line
function drawRotatedRadialLine(g, point, center, lengthPixels, rotationAngleRadians) {
    let dirToCenter = p5.Vector.sub(center, point);
    if (dirToCenter.magSq() < 1e-6) return; // Avoid drawing for points at the center
    dirToCenter.normalize();
    
    // Calculate rotated direction
    let rotatedDir = createVector();
    rotatedDir.x = dirToCenter.x * cos(rotationAngleRadians) - dirToCenter.y * sin(rotationAngleRadians);
    rotatedDir.y = dirToCenter.x * sin(rotationAngleRadians) + dirToCenter.y * cos(rotationAngleRadians);
    
    // Calculate the line end point
    let endPoint = p5.Vector.add(point, p5.Vector.mult(rotatedDir, lengthPixels));
    
    g.line(point.x, point.y, endPoint.x, endPoint.y);
}

function draw() {
  // Main drawing to the screen
  background(255);
  let center = createVector(width / 2.0, height / 2.0);
  
  if (points !== null && points.length >= n && n >= minPoints) { 
    stroke(0); 
    strokeWeight(1); 
    noFill();
    
    // Draw the pattern to the screen
    drawPattern(window, center);
  }
  
  // Handle SVG recording if needed
  if (recordSVG) {
    try {
      console.log("Creating SVG...");
      
      // Create a new SVG renderer
      svgGraphics = createGraphics(width, height, SVG);
      
      // Draw the pattern to the SVG graphics object
      if (points !== null && points.length >= n && n >= minPoints) {
        svgGraphics.stroke(0);
        svgGraphics.strokeWeight(1);
        svgGraphics.noFill();
        drawPattern(svgGraphics, center);
      }
      
      // Save the SVG file
      save(svgGraphics, "InterpolatedCircle_" + getTimestamp() + ".svg");
      
      console.log("SVG saved");
      alert("SVG exported successfully!");
      
    } catch (e) {
      console.error("Error creating SVG: " + e.message);
      alert("Error creating SVG: " + e.message);
    } finally {
      recordSVG = false;
      if (svgGraphics) {
        svgGraphics.remove();
        svgGraphics = null;
      }
    }
  }
}

// Method to encapsulate all pattern drawing logic
function drawPattern(g, center) {
  // Variables needed by both draw modes
  let radialLengthPixels = radialLineLengthUnits * radiusScale;
  let numSegments = max(1, segmentsPerCurve);

  // Draw Original Curve (or its radial lines)
  if (drawMode == 0) {
      // Draw CURVES Mode - Original curve
      g.beginShape();
      g.curveVertex(points[n - 1].x, points[n - 1].y); 
      for (let i = 0; i < n; i++) {
        g.curveVertex(points[i].x, points[i].y);
      }
      g.curveVertex(points[0].x, points[0].y);
      g.curveVertex(points[1].x, points[1].y); 
      g.endShape();
  } else {
      // Draw INTERPOLATED INWARD RADIAL LINES Mode - Original curve
      for (let j = 0; j < numSegments; j++) {
          let t_global = map(j, 0, numSegments, 0, n);
          let segIndex = floor(t_global) % n;
          let t_segment = t_global - floor(t_global);
          
          let p0 = points[(segIndex - 1 + n) % n];
          let p1 = points[segIndex];
          let p2 = points[(segIndex + 1) % n];
          let p3 = points[(segIndex + 2) % n];
          
          let interpX = curvePoint(p0.x, p1.x, p2.x, p3.x, t_segment);
          let interpY = curvePoint(p0.y, p1.y, p2.y, p3.y, t_segment);
          drawInwardRadialLine(g, createVector(interpX, interpY), center, radialLengthPixels);
      }
  }

  // --- Draw Duplicate Cycles (Multiplicative Scaling) --- 
  let effectiveCycleCount = max(2, cycleCount);
  let effectiveNumCycles = max(1, numberOfCycles);
  let debugScaling = false;
  
  if (debugScaling) {
    console.log("--- Starting Duplicates --- Cycles:", effectiveNumCycles, " Steps/Cycle:", effectiveCycleCount);
  }
  
  let halfCycle = Math.floor(effectiveCycleCount / 2);
  let firstRelativeOffset = max(0.01, initialScaleOffset - 1.0); // Ensure at least small positive value
  if (debugScaling) {
    console.log("  firstRelativeOffset:", firstRelativeOffset);
  }
  
  // For each cycle, start with the scale from the end of the previous cycle
  // or 1.0 for the first cycle
  let currentTotalScale = 1.0;

  // Outer loop for cycles
  for (let cycleNum = 0; cycleNum < effectiveNumCycles; cycleNum++) {
      if (debugScaling) {
        console.log("  Entering Cycle:", cycleNum);
      }
      
      // Inner loop for steps within a cycle
      for (let d = 0; d < effectiveCycleCount; d++) { 
          let exponentIndex = (d < halfCycle) ? d : (effectiveCycleCount - 1 - d);
          let stepScaleFactor = 1.0 + firstRelativeOffset * Math.pow(scaleDecay, exponentIndex); 
          currentTotalScale *= stepScaleFactor; 

          if (debugScaling) {
            console.log("    d:", d, " expIdx:", exponentIndex, " stepFactor:", 
                       stepScaleFactor.toFixed(4), " totalScale:", currentTotalScale.toFixed(4));
          }

          if (currentTotalScale <= 1e-6) {
               if (debugScaling) {
                 console.log("      Scale too small, skipping rest.");
               }
               continue; 
          }

          let totalDuplicateIndex = cycleNum * effectiveCycleCount + d;

          if (drawMode == 0) {
              // Draw curve with current scale
              drawFluctuatedCurve(g, center, currentTotalScale, totalDuplicateIndex);
          } else {
              // Draw radial lines with current scale
              let currentAnchorPoints = [];
              for(let i = 0; i < n; i++) {
                   currentAnchorPoints.push(getFluctuatedScaledPoint(points[i], center, currentTotalScale, totalDuplicateIndex, i, fluctuationAmount, radiusScale));
              }
              
              // Calculate rotation for this set of lines
              let rotationAngle = radians(lineRotationDegrees * totalDuplicateIndex);
              
              for (let j = 0; j < numSegments; j++) {
                  let t_global = map(j, 0, numSegments, 0, n);
                  let segIndex = floor(t_global) % n;
                  let t_segment = t_global - floor(t_global);
                  let p0 = currentAnchorPoints[(segIndex - 1 + n) % n];
                  let p1 = currentAnchorPoints[segIndex];
                  let p2 = currentAnchorPoints[(segIndex + 1) % n];
                  let p3 = currentAnchorPoints[(segIndex + 2) % n];
                  let interpX = curvePoint(p0.x, p1.x, p2.x, p3.x, t_segment);
                  let interpY = curvePoint(p0.y, p1.y, p2.y, p3.y, t_segment);
                  // Use the rotated line drawing function
                  drawRotatedRadialLine(g, createVector(interpX, interpY), center, radialLengthPixels, rotationAngle);
              }
          }
      }
  }
  if (debugScaling) {
    console.log("--- Finished Duplicates ---");
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

function updateCycleCount() {
  try {
    let currentTotalDuplicates = max(2, cycleCount) * max(1, numberOfCycles);
    let newCount = parseInt(cycleCountInput.value());
    if (!isNaN(newCount)) {
      newCount = max(2, newCount);
      let newTotalDuplicates = newCount * max(1, numberOfCycles);
      
      if (newCount !== cycleCount) {
          cycleCount = newCount;
          // Regenerate only if total number of duplicates changes
          if (newTotalDuplicates !== currentTotalDuplicates) {
               regeneratePattern(); 
          }
      }
      // Update text field if clamped
      if (cycleCountInput.value() !== cycleCount.toString()) {
         cycleCountInput.value(cycleCount.toString());
      }
    }
  } catch (e) {
    console.log("Invalid input for cycleCount: " + cycleCountInput.value());
    cycleCountInput.value(cycleCount.toString());
  }
}

function updateNumberOfCycles() {
  try {
    let currentTotalDuplicates = max(2, cycleCount) * max(1, numberOfCycles);
    let newNumCycles = parseInt(numberOfCyclesInput.value());
    if (!isNaN(newNumCycles)) {
      newNumCycles = max(1, newNumCycles); 
      let newTotalDuplicates = max(2, cycleCount) * newNumCycles;

      if (newNumCycles !== numberOfCycles) {
          numberOfCycles = newNumCycles;
           // Regenerate only if total number of duplicates changes
          if (newTotalDuplicates !== currentTotalDuplicates) {
              regeneratePattern(); 
          }
      }
      // Update text field if clamped
      if (numberOfCyclesInput.value() !== numberOfCycles.toString()) {
        numberOfCyclesInput.value(numberOfCycles.toString());
      }
    }
  } catch (e) {
    console.log("Invalid input for numberOfCycles: " + numberOfCyclesInput.value());
    numberOfCyclesInput.value(numberOfCycles.toString());
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

function updateDrawMode() {
  try {
    let newMode = parseInt(drawModeInput.value());
    if (!isNaN(newMode)) {
      drawMode = (newMode == 1) ? 1 : 0; // Clamp to 0 or 1
      if (drawMode !== newMode) { 
        drawModeInput.value(drawMode.toString());
      }
    }
  } catch (e) {
    console.log("Invalid input for drawMode: " + drawModeInput.value());
    drawModeInput.value(drawMode.toString());
  }
}

function updateRadialLineLength() {
  try {
    let newLength = parseFloat(radialLengthInput.value());
    if (!isNaN(newLength)) {
      radialLineLengthUnits = max(0, newLength); // Ensure non-negative length
      if (radialLineLengthUnits !== newLength) {
        radialLengthInput.value(radialLineLengthUnits.toFixed(2));
      }
    }
  } catch (e) {
    console.log("Invalid input for radialLineLengthUnits: " + radialLengthInput.value());
    radialLengthInput.value(radialLineLengthUnits.toFixed(2));
  }
}

function updateSegmentsPerCurve() {
  try {
    let newSegments = parseInt(segmentsPerCurveInput.value());
    if (!isNaN(newSegments)) {
      segmentsPerCurve = max(1, newSegments); // Ensure at least 1 segment
      if (segmentsPerCurve !== newSegments) { 
        segmentsPerCurveInput.value(segmentsPerCurve.toString());
      }
    }
  } catch (e) {
    console.log("Invalid input for segmentsPerCurve: " + segmentsPerCurveInput.value());
    segmentsPerCurveInput.value(segmentsPerCurve.toString());
  }
}

function updateLineRotationDegrees() {
  try {
    let newRotation = parseFloat(lineRotationDegreesInput.value());
    if (!isNaN(newRotation)) {
      lineRotationDegrees = newRotation; // Allow any value including negative
      if (lineRotationDegrees.toFixed(1) !== newRotation.toFixed(1)) { 
        lineRotationDegreesInput.value(lineRotationDegrees.toFixed(1));
      }
    }
  } catch (e) {
    console.log("Invalid input for lineRotationDegrees: " + lineRotationDegreesInput.value());
    lineRotationDegreesInput.value(lineRotationDegrees.toFixed(1));
  }
}

// SVG export function
function exportSVG() {
  console.log("SVG export requested via button");
  
  // Make sure we're not already in the middle of an export
  if (recordSVG) {
    console.log("Export already in progress, ignoring request");
    return;
  }
  
  recordSVG = true;
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
