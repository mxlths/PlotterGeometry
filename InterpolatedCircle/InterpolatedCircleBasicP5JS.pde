// InterpolatedCircleBasic P5.js Version
// A simple implementation of the interpolated circle concept

// Global variables
let n = 7; // Number of points
let offset = 2.0; // Offset for the radius
let radiusScale = 50; // Scale factor for the radius units
let points = []; // Stores calculated positions
let baseRandomDistances = []; // Stores random distance values

function setup() {
  createCanvas(800, 600);
  regeneratePattern();
}

// Function to generate the random pattern
function regeneratePattern() {
  baseRandomDistances = [];
  
  // Generate base distances
  for (let i = 0; i < n; i++) {
    baseRandomDistances.push(random(1, 7));
  }
  
  calculatePoints(); // Calculate positions based on random data
}

// Calculate point positions using stored random base distances
function calculatePoints() {
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

function draw() {
  background(255);
  
  if (points.length >= 3) { 
    // Draw the original curve
    stroke(0);
    strokeWeight(1);
    noFill();
    
    beginShape();
    // Add the last point as first control point for smooth start
    curveVertex(points[points.length - 1].x, points[points.length - 1].y);
    
    // Add all points
    for (let i = 0; i < points.length; i++) {
      curveVertex(points[i].x, points[i].y);
    }
    
    // Add first two points to close the curve smoothly
    curveVertex(points[0].x, points[0].y);
    curveVertex(points[1].x, points[1].y);
    endShape();
    
    // Draw a few scaled versions
    for (let scale = 1.1; scale < 1.6; scale += 0.1) {
      drawScaledCurve(scale);
    }
    
    // Draw points
    fill(255, 0, 0);
    noStroke();
    for (let i = 0; i < points.length; i++) {
      ellipse(points[i].x, points[i].y, 6, 6);
    }
  }
}

// Draw a scaled version of the curve
function drawScaledCurve(scale) {
  let center = createVector(width / 2.0, height / 2.0);
  
  beginShape();
  
  // Add the last point as first control point for smooth start
  let scaledLastP = getScaledPoint(points[points.length - 1], center, scale);
  curveVertex(scaledLastP.x, scaledLastP.y);
  
  // Add all points
  for (let i = 0; i < points.length; i++) {
    let scaledP = getScaledPoint(points[i], center, scale);
    curveVertex(scaledP.x, scaledP.y);
  }
  
  // Add first two points to close the curve smoothly
  let scaledFirstP = getScaledPoint(points[0], center, scale);
  curveVertex(scaledFirstP.x, scaledFirstP.y);
  let scaledSecondP = getScaledPoint(points[1], center, scale);
  curveVertex(scaledSecondP.x, scaledSecondP.y);
  
  endShape();
}

// Scale a point relative to center
function getScaledPoint(originalPoint, center, scale) {
  let scaledP = p5.Vector.sub(originalPoint, center);
  scaledP.mult(scale);
  scaledP.add(center);
  return scaledP;
}

// Regenerate the pattern when mouse is pressed
function mousePressed() {
  regeneratePattern();
} 