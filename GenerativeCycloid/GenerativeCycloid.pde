// Global Variables for Cycloid Machine Parameters
import processing.svg.*; // Ensure SVG library is imported
import controlP5.*;      // Import ControlP5 library
import java.io.File;     // Import File class for file selection

ControlP5 cp5;          // Declare ControlP5 object
PFont labelFont;        // Font for labels

// Speeds (radians per time step)
float wheel1Speed = 0.02;
float wheel2Speed = 0.05;
float canvasWheelSpeed = 0.005; // Used for 2D rotation OR 3D rotation speed

// Radii and Attachment Points (Visual guides & calculation inputs)
float wheel1Radius = 100;
float wheel2Radius = 80;
float wheel1AttachmentDist = 60;
float wheel2AttachmentDist = 50;

// Wheel Positions (for 2D guides)
float wheel1CenterX = -150;
float wheel1CenterY = 0;
float wheel2CenterX = 150;
float wheel2CenterY = 0;

// Linkage Parameters
float rod1Length = 250;
float rod2Length = 250;
float penRodRatio = 1.3;

// Simulation Control
float simulationTime = 0;
int maxSteps = 2000;
int currentStep = 0;
boolean instantRender = false;
boolean use3DCanvasRotation = false; // New: Toggle for 3D canvas rotation mode

// Calculated Points
PVector jointPosD = new PVector(0, 0); // 2D calculation result
PVector penPos = new PVector(0, 0);    // 2D calculation result

// Storing the path (will store PVectors, Z=0 in 2D mode, Z!=0 in 3D mode)
ArrayList<PVector> path = new ArrayList<PVector>();

// SVG Output
boolean recordSVG = false;
String svgFilename = "";
boolean awaitingFileSelection = false; // New flag for file dialog state

// Mouse Rotation Variables
float mouseRotX = 0.3; // Initial tilt
float mouseRotY = -0.4; // Initial rotation
float prevMouseX = 0;
float prevMouseY = 0;
boolean mouseDragging = false;
int guiWidth = 240; // Width of the GUI panel + buffer

void setup() {
  size(1000, 800, P3D); // Use P3D renderer
  smooth(8);
  frameRate(60);

  // --- Initialize ControlP5 ---
  cp5 = new ControlP5(this);
  labelFont = createFont("Arial", 12, true);

  int inputX = 170; int inputY = 10; int inputW = 60; int inputH = 20;
  int spacing = 25; int labelW = 150; int currentY = inputY;

  // Max Steps
  cp5.addLabel("Sim Steps:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("maxSteps")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(""+maxSteps);

  // Wheel 1 Attachment Distance (Replaces Diameter)
  currentY += spacing;
  cp5.addLabel("Wheel 1 Attach Dist:") // Renamed Label
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("wheel1AttachmentDist") // Renamed textfield/handler link
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(wheel1AttachmentDist, 0, 1)); // Show current attach dist

  // Wheel 2 Attachment Distance (Replaces Diameter)
  currentY += spacing;
  cp5.addLabel("Wheel 2 Attach Dist:") // Renamed Label
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("wheel2AttachmentDist") // Renamed textfield/handler link
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(wheel2AttachmentDist, 0, 1)); // Show current attach dist

  // Wheel 1 Speed
  currentY += spacing;
  cp5.addLabel("Wheel 1 Speed (rad/s):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("wheel1Speed")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(wheel1Speed, 1, 3));

  // Wheel 2 Speed
  currentY += spacing;
  cp5.addLabel("Wheel 2 Speed (rad/s):")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("wheel2Speed")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(wheel2Speed, 1, 3));

  // Canvas Rot Speed
  currentY += spacing;
  cp5.addLabel("Canvas Rot Speed (rad/s):") // Label applies to 2D or 3D rotation
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addTextfield("canvasWheelSpeed")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setAutoClear(false).setValue(nf(canvasWheelSpeed, 1, 3));

  // 3D Rotation Toggle
  currentY += spacing;
  cp5.addLabel("3D Canvas Rotation:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addToggle("use3DCanvasRotation")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setValue(use3DCanvasRotation)
     .setMode(ControlP5.SWITCH);

  // Instant Render Toggle
  currentY += spacing;
  cp5.addLabel("Instant Render:")
     .setPosition(10, currentY + 4).setSize(labelW, inputH)
     .setColor(color(0)).setFont(labelFont);
  cp5.addToggle("instantRender")
     .setPosition(inputX, currentY).setSize(inputW, inputH)
     .setValue(instantRender)
     .setMode(ControlP5.SWITCH);

  // Restart Button (useful since handlers call setup)
  currentY += spacing + 10;
  cp5.addButton("restartSimulation")
     .setLabel("Restart Sim")
     .setPosition(10, currentY)
     .setSize(100, inputH + 5);

  // SVG Export Button
  cp5.addButton("exportSVG")
     .setLabel("Export SVG") // Remove (2D) clarification for now
     .setPosition(120, currentY)
     .setSize(100, inputH + 5);
  // --- End ControlP5 Setup ---


  // Initialize simulation state
  simulationTime = 0;
  currentStep = 0;
  path.clear();
  recordSVG = false; // Ensure SVG recording is off on setup/restart
  awaitingFileSelection = false; // Ensure flag is reset

  // Calculate initial OR full path
  if (instantRender) {
    println("Calculating full path instantly (" + (use3DCanvasRotation ? "3D" : "2D") + " mode)...");
    calculateFullPath();
    println("Calculation complete. Path points: " + path.size());
  } else {
    // Calculate just the initial position for step-by-step
    calculateJointAndPenPosition(); // Calculates 2D penPos
    if (penPos != null) {
        addCurrentPointToPath(); // Adds point respecting 2D/3D mode
    } else {
      println("Error: Initial configuration is invalid.");
    }
  }

  println("Setup complete. Parameters set.");
  loop(); // Ensure draw loop is definitely running after setup
}

// --- ControlP5 Handler Functions ---

public void maxSteps(String theValue) {
  try {
    int newSteps = Integer.parseInt(theValue);
    newSteps = max(10, newSteps); // Ensure a minimum number of steps
    if (newSteps != maxSteps) {
      maxSteps = newSteps;
      println("Max steps set to: " + maxSteps);
      // Changing steps might warrant a restart if not instant mode
      if (!instantRender) {
          restartSimulation();
      } else {
          // In instant mode, we might want to recalculate immediately
          // Or just let the next manual restart pick it up.
          // Let's restart for consistency.
          restartSimulation();
      }
    }
  } catch (NumberFormatException e) {
    println("Invalid input for maxSteps: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("maxSteps")).setValue(""+maxSteps);
  }
}

public void wheel1AttachmentDist(String theValue) {
  try {
    float newDist = Float.parseFloat(theValue);
    newDist = max(0, newDist); // Attachment distance can be 0, but not negative
    if (abs(newDist - wheel1AttachmentDist) > 1e-4) {
      wheel1AttachmentDist = newDist;
      println("Wheel 1 Attachment Dist set to: " + wheel1AttachmentDist);
      restartSimulation();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for Wheel 1 Attachment Dist: " + theValue);
    // Restore text field to reflect current internal value on error
    if (cp5 != null) ((Textfield)cp5.getController("wheel1AttachmentDist")).setValue(nf(wheel1AttachmentDist, 0, 1));
  }
}

public void wheel2AttachmentDist(String theValue) {
  try {
    float newDist = Float.parseFloat(theValue);
     newDist = max(0, newDist); // Attachment distance can be 0, but not negative
    if (abs(newDist - wheel2AttachmentDist) > 1e-4) {
      wheel2AttachmentDist = newDist;
      println("Wheel 2 Attachment Dist set to: " + wheel2AttachmentDist);
      restartSimulation();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for Wheel 2 Attachment Dist: " + theValue);
    // Restore text field to reflect current internal value on error
    if (cp5 != null) ((Textfield)cp5.getController("wheel2AttachmentDist")).setValue(nf(wheel2AttachmentDist, 0, 1));
  }
}

public void wheel1Speed(String theValue) {
  try {
    float newSpeed = Float.parseFloat(theValue);
    if (abs(newSpeed - wheel1Speed) > 1e-6) {
      wheel1Speed = newSpeed;
      println("Wheel 1 Speed set to: " + wheel1Speed);
      restartSimulation();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for Wheel 1 Speed: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("wheel1Speed")).setValue(nf(wheel1Speed, 1, 3));
  }
}

public void wheel2Speed(String theValue) {
  try {
    float newSpeed = Float.parseFloat(theValue);
    if (abs(newSpeed - wheel2Speed) > 1e-6) {
      wheel2Speed = newSpeed;
      println("Wheel 2 Speed set to: " + wheel2Speed);
      restartSimulation();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for Wheel 2 Speed: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("wheel2Speed")).setValue(nf(wheel2Speed, 1, 3));
  }
}

public void canvasWheelSpeed(String theValue) {
  try {
    float newSpeed = Float.parseFloat(theValue);
    if (abs(newSpeed - canvasWheelSpeed) > 1e-6) {
      canvasWheelSpeed = newSpeed;
      println("Canvas Rot Speed set to: " + canvasWheelSpeed);
      restartSimulation();
    }
  } catch (NumberFormatException e) {
    println("Invalid input for Canvas Rot Speed: " + theValue);
    if (cp5 != null) ((Textfield)cp5.getController("canvasWheelSpeed")).setValue(nf(canvasWheelSpeed, 1, 3));
  }
}

public void instantRender(boolean theValue) {
  if (theValue != instantRender) {
    instantRender = theValue;
    println("Instant Render set to: " + instantRender);
    restartSimulation(); // Restart to apply mode change
  }
}

// New Handler for 3D Rotation Toggle
public void use3DCanvasRotation(boolean theValue) {
  if (theValue != use3DCanvasRotation) {
    use3DCanvasRotation = theValue;
    println("3D Canvas Rotation set to: " + use3DCanvasRotation);
    
    // --- Reset view rotation if switching back to 2D ---
    if (!use3DCanvasRotation) {
        println("Resetting view rotation to default.");
        mouseRotX = 0.0; // Reset X rotation
        mouseRotY = 0.0; // Reset Y rotation
    }
    // --------------------------------------------------

    restartSimulation(); // Restart to apply mode change
  }
}

// Handler for the restart button
public void restartSimulation() {
    println("Restarting simulation...");
    setup(); // Call setup to reset everything
}

// Updated SVG export handler
public void exportSVG() {
    // --- Use awaitingFileSelection flag to prevent re-entry ---
    if (awaitingFileSelection) {
        println("Already waiting for file selection.");
        return;
    }
    if (recordSVG) { // Keep this check too, just in case
        println("SVG export already initiated, please wait.");
        return;
    }
    // --------------------------------------------------------

    println("SVG export button pressed.");
    if (path != null && path.size() > 1) {
        String defaultFilename = "GenerativeCycloidOutput_";
        defaultFilename += "w1s" + nf(wheel1Speed, 1, 3) + "_w2s" + nf(wheel2Speed, 1, 3) + "_";
        defaultFilename += "r1d" + nf(wheel1AttachmentDist, 0, 1) + "_r2d" + nf(wheel2AttachmentDist, 0, 1) + "_";
        defaultFilename += "L1_" + nf(rod1Length) + "_L2_" + nf(rod2Length) + "_";
        defaultFilename += "pen" + nf(penRodRatio, 1, 2) + "_";
        defaultFilename += "mode" + (use3DCanvasRotation ? "3D" : "2D") + "_";
        defaultFilename += "steps" + path.size() + ".svg";
        defaultFilename = defaultFilename.replace('.', '_');

        awaitingFileSelection = true; // Set flag before calling dialog
        selectOutput("Save SVG As...", "svgFileSelected", new File(defaultFilename), this);

    } else if (path == null || path.size() <= 1){
        println("Cannot export: Path is too short or calculation failed.");
    }
}

// Updated Callback function for SVG file selection
void svgFileSelected(File selection) {
  awaitingFileSelection = false; // Reset flag now that dialog is closed
  if (selection == null) {
    println("SVG export cancelled.");
    recordSVG = false; // Ensure recording flag is false if cancelled
  } else {
    svgFilename = selection.getAbsolutePath();
    
    // Ensure the filename ends with .svg
    if (!svgFilename.toLowerCase().endsWith(".svg")) {
      svgFilename += ".svg";
      println("Added .svg extension to filename");
    }
    
    println("SVG will be saved to: " + svgFilename);
    
    // Check if file exists and delete if necessary - added safety
    File outputFile = new File(svgFilename);
    if (outputFile.exists()) {
        println("Warning: File already exists. Deleting: " + svgFilename);
        if (!outputFile.delete()) {
            println("Error: Could not delete existing file. Export might fail or overwrite.");
            // Optionally, cancel export here if deletion fails
            // recordSVG = false;
            // return;
        }
    }
    
    recordSVG = true; // Set flag to trigger actual saving in draw()
  }
}

// --- End ControlP5 Handlers ---


// Function to calculate the intersection of two circles (for joint D)
// Returns one of the two intersection points based on the 'preferPositiveY' hint
// or null if no intersection or circles are coincident.
PVector calculateCircleIntersection(PVector p1, float r1, PVector p2, float r2, boolean preferPositiveCrossProduct) {
    float dSq = PVector.sub(p1, p2).magSq();
    float d = sqrt(dSq);

    if (d > r1 + r2 || d < abs(r1 - r2) || d == 0) {
        float tolerance = 1e-4;
        if (abs(d - (r1 + r2)) < tolerance || abs(d - abs(r1 - r2)) < tolerance) {
           if (abs(d - (r1 + r2)) < tolerance) {
               PVector vec_p1_p2 = PVector.sub(p2, p1);
               if (vec_p1_p2.magSq() > 1e-9) {
                  return PVector.add(p1, vec_p1_p2.normalize().mult(r1));
               } else { return null; }
           } else if (abs(d - abs(r1 - r2)) < tolerance) {
               PVector vec_p1_p2 = PVector.sub(p2, p1);
               if (vec_p1_p2.magSq() > 1e-9) {
                   return PVector.add(p1, vec_p1_p2.normalize().mult(r1));
               } else { return null; }
           }
        }
        return null;
    }

    float a = (r1*r1 - r2*r2 + dSq) / (2*d);
    float hSq = r1*r1 - a*a;
    float h = (hSq > 1e-6) ? sqrt(hSq) : 0;

    PVector vec_p1_p2 = PVector.sub(p2, p1);
    if (d < 1e-9) return null;
    PVector p_mid = PVector.add(p1, vec_p1_p2.copy().mult(a/d));

    PVector perpVec = new PVector(-(p2.y - p1.y), p2.x - p1.x);
    if (perpVec.magSq() < 1e-9) return null;
    perpVec.normalize();

    PVector offset = perpVec.mult(h);
    PVector intersection1 = PVector.add(p_mid, offset);
    PVector intersection2 = PVector.sub(p_mid, offset);

    PVector vec_p1_i1 = PVector.sub(intersection1, p1);
    PVector p1p2_immutable = PVector.sub(p2, p1);
    float crossZ1 = p1p2_immutable.x * vec_p1_i1.y - p1p2_immutable.y * vec_p1_i1.x;

    if (preferPositiveCrossProduct) {
       return (crossZ1 >= 0) ? intersection1 : intersection2;
    } else {
       return (crossZ1 < 0) ? intersection1 : intersection2;
    }
}


// Calculate current joint and pen positions
void calculateJointAndPenPosition() {
    float angle1 = simulationTime * wheel1Speed;
    float angle2 = simulationTime * wheel2Speed;
    PVector wheel1Center = new PVector(wheel1CenterX, wheel1CenterY);
    PVector wheel2Center = new PVector(wheel2CenterX, wheel2CenterY);
    PVector attachmentA = PVector.add(wheel1Center, PVector.fromAngle(angle1).mult(wheel1AttachmentDist));
    PVector attachmentB = PVector.add(wheel2Center, PVector.fromAngle(angle2).mult(wheel2AttachmentDist));
    boolean preferPositiveCross = true;
    PVector calculatedD = calculateCircleIntersection(attachmentA, rod1Length, attachmentB, rod2Length, preferPositiveCross);

    if (calculatedD != null) {
        jointPosD = calculatedD;
        PVector vec_B_D = PVector.sub(jointPosD, attachmentB);
        penPos = PVector.add(attachmentB, vec_B_D.mult(penRodRatio));
    } else {
        if (isLooping() && !instantRender) {
           println("Error: Rods cannot connect at step " + currentStep + ". A=" + attachmentA + ", B=" + attachmentB + ", Dist=" + PVector.dist(attachmentA, attachmentB));
           println("Stopping simulation due to linkage error.");
           // Don't call noLoop() here either, let draw handle loop state
        }
        penPos = null;
    }
}


void draw() {

  // --- SVG Recording Trigger ---
  if (recordSVG) {
      println("Begin SVG record: " + svgFilename);
      try {
          PGraphics svg = createGraphics(width, height, SVG, svgFilename);
          svg.beginDraw();
          svg.background(255); // Add background for SVG

          if (use3DCanvasRotation) {
              // --- Export 3D Perspective View ---
              export3DViewToSVG(svg);
          } else {
              // --- Export Flat 2D View ---
              println("Exporting flat 2D view to SVG...");
              svg.pushMatrix();
              svg.translate(width / 2, height / 2); // Center in SVG
              svg.stroke(0); svg.strokeWeight(1); svg.noFill();
              if (path.size() > 1) {
                  svg.beginShape();
                  // Draw using only X, Y from the path (Z is 0 anyway in 2D mode)
                  svg.curveVertex(path.get(0).x, path.get(0).y); // First control point
                  for (PVector p : path) {
                      svg.curveVertex(p.x, p.y);
                  }
                  svg.curveVertex(path.get(path.size()-1).x, path.get(path.size()-1).y); // Last control point
                  svg.endShape();
              }
              svg.popMatrix();
              println("Finished flat 2D SVG export calculation.");
          }

          svg.endDraw();
          svg.dispose(); // Release resources
          println("SVG finished and saved: " + svgFilename);
      } catch (Exception e) {
          println("Error during SVG export: " + e.getMessage());
          e.printStackTrace();
      } finally {
          recordSVG = false; // Ensure flag is reset even on error
          svgFilename = "";
      }
  }

  // --- Standard Screen Drawing ---
  background(255);

  // --- Simulation Logic (Only if NOT instant render) ---
  if (!instantRender && currentStep < maxSteps) {
    // Check penPos validity from previous frame BEFORE calculating next step
    if (penPos == null && currentStep > 0) {
         // If linkage failed previously, stop further simulation steps
         // (This prevents runaway errors if noLoop isn't called)
         // We could display an error message state here if desired
    } else {
        calculateJointAndPenPosition(); // Calculate next step

        if (penPos != null) { // If calculation successful
            addCurrentPointToPath(); // Adds point respecting 2D/3D mode
            simulationTime += 1.0;
            currentStep++;
        } else {
             // Linkage calculation failed for this step
             println("Simulation stopped at step " + currentStep + " due to linkage error.");
             // Do not increment currentStep or simulationTime
             // The UI will remain responsive, but the animation stops.
        }
    }

  } else if (!instantRender && currentStep >= maxSteps) {
    // Animated simulation finished normally - just print message once maybe?
    // (No action needed here now, draw continues)
    // println("Simulation complete."); // Can get repetitive
  }

  // --- 3D Drawing Logic ---
  hint(ENABLE_DEPTH_TEST); // Ensure depth testing is on for 3D scene
  // Set up camera view
  translate(width / 2.0, height / 2.0, 0); // Center view
  // Apply mouse rotations
  rotateX(mouseRotX);
  rotateY(mouseRotY);
  // Optional: Add zoom control later if needed (e.g., using translate Z)


  // Draw mechanism guides only if NOT instant render AND in 2D mode
  if (!instantRender && !use3DCanvasRotation) {
      pushMatrix(); // Isolate 2D guide drawing
      // No extra rotation needed as guides are drawn relative to the base XY plane
      float displayTime = simulationTime > 0 ? simulationTime -1.0 : simulationTime;
      if (displayTime < 0) displayTime = 0;
      float currentAngle1 = displayTime * wheel1Speed;
      float currentAngle2 = displayTime * wheel2Speed;
      PVector wheel1Center = new PVector(wheel1CenterX, wheel1CenterY);
      PVector wheel2Center = new PVector(wheel2CenterX, wheel2CenterY);
      PVector currentA = PVector.add(wheel1Center, PVector.fromAngle(currentAngle1).mult(wheel1AttachmentDist));
      PVector currentB = PVector.add(wheel2Center, PVector.fromAngle(currentAngle2).mult(wheel2AttachmentDist));

      noFill(); stroke(180); strokeWeight(1);
      // Draw visual wheels using wheelRadius (on XY plane)
      pushMatrix(); translate(wheel1CenterX, wheel1CenterY, 0); ellipse(0, 0, wheel1Radius * 2, wheel1Radius * 2); popMatrix();
      pushMatrix(); translate(wheel2CenterX, wheel2CenterY, 0); ellipse(0, 0, wheel2Radius * 2, wheel2Radius * 2); popMatrix();

      // Draw attachment points using spheres
      noStroke();
      // Point A
      pushMatrix();
      translate(currentA.x, currentA.y, 0); // Translate to point A location (Z=0)
      fill(255, 0, 0, 150); // Semi-transparent Red A
      sphere(5); // Draw a small sphere (radius 5)
      popMatrix();

      // Point B
      pushMatrix();
      translate(currentB.x, currentB.y, 0); // Translate to point B location (Z=0)
      fill(0, 255, 0, 150); // Semi-transparent Green B
      sphere(5); // Draw a small sphere (radius 5)
      popMatrix();

      PVector drawJointD = (penPos != null) ? jointPosD : null;
      PVector drawPenP = (penPos != null) ? penPos : null;

      if (drawJointD != null && drawPenP != null) {
          stroke(150, 150); strokeWeight(2);
          line(currentA.x, currentA.y, 0, drawJointD.x, drawJointD.y, 0); // Z=0 for lines
          line(currentB.x, currentB.y, 0, drawJointD.x, drawJointD.y, 0);
          if (penRodRatio > 1.0 || penRodRatio < 0.0) {
              stroke(100, 150); line(drawJointD.x, drawJointD.y, 0, drawPenP.x, drawPenP.y, 0);
          }
          // Need to draw points in 3D space too
          pushMatrix(); translate(drawJointD.x, drawJointD.y, 0); fill(0, 255, 255, 150); noStroke(); sphere(4); popMatrix();
          pushMatrix(); translate(drawPenP.x, drawPenP.y, 0); fill(255, 0, 255, 150); sphere(3.5); popMatrix();
      }
       popMatrix(); // Restore matrix after drawing 2D guides
  }


  // Draw the generated path (works for 2D or 3D path data)
  stroke(0); strokeWeight(1); noFill();
  if (path.size() > 1) {
      beginShape();
      // Use first point as control point
      curveVertex(path.get(0).x, path.get(0).y, path.get(0).z);
      // Draw actual points using Z coordinate
      for (PVector p : path) {
          curveVertex(p.x, p.y, p.z);
      }
      // Use last point as control point
      curveVertex(path.get(path.size()-1).x, path.get(path.size()-1).y, path.get(path.size()-1).z);
      endShape();
  }

  // --- Draw GUI ---
  // Reset transformations to draw GUI in 2D overlay
  hint(DISABLE_DEPTH_TEST);
  camera(); // Reset camera to default 2D view
  ortho();  // Use orthographic projection for UI
  cp5.draw(); // Draw ControlP5 GUI elements
}

// --- Mouse Interaction for Rotation ---
void mousePressed() {
  // Only start dragging if the mouse is outside the GUI area
  if (mouseX > guiWidth) {
    mouseDragging = true;
    prevMouseX = mouseX;
    prevMouseY = mouseY;
  } else {
    mouseDragging = false;
  }
}

void mouseDragged() {
  if (mouseDragging) {
    float dx = mouseX - prevMouseX;
    float dy = mouseY - prevMouseY;
    // Adjust mouse rotation based on drag (adjust sensitivity as needed)
    mouseRotY += dx * 0.01;
    mouseRotX -= dy * 0.01;
    prevMouseX = mouseX;
    prevMouseY = mouseY;
  }
}

void mouseReleased() {
  mouseDragging = false;
}

// Key press handler (Keep 'r' for restart, 's' can now be handled by button)
void keyPressed() {
   if (key == 'r' || key == 'R') {
      restartSimulation();
  }
  // Remove 's' keypress for saving, use the button instead
  /*
  if (key == 's' || key == 'S') {
     // ... old svg saving logic ...
  }
  */
}

// --- New Function to Calculate Full Path ---
void calculateFullPath() {
  path.clear(); // Start with a clean path
  simulationTime = 0;
  currentStep = 0;

  while(currentStep < maxSteps) {
      calculateJointAndPenPosition();
      if (penPos != null) {
          addCurrentPointToPath();
          simulationTime += 1.0;
          currentStep++;
      } else {
          println("Linkage error during instant calculation at step: " + currentStep);
          break; // Stop calculation on error
      }
  }
   // No need to duplicate points here anymore
}

// --- New function to handle adding point based on mode ---
void addCurrentPointToPath() {
    if (penPos == null) return; // Nothing to add

    PVector pointToAdd;
    float canvasAngle = simulationTime * canvasWheelSpeed;

    if (use3DCanvasRotation) {
        // Rotate the 2D pen position around the X-axis
        // Treat penPos as (x, y, 0)
        float cosTheta = cos(canvasAngle);
        float sinTheta = sin(canvasAngle);
        float x_prime = penPos.x; // x remains the same for X-axis rotation
        float y_prime = penPos.y * cosTheta; // y' = y*cos(angle) - z*sin(angle) where z=0
        float z_prime = penPos.y * sinTheta; // z' = y*sin(angle) + z*cos(angle) where z=0
        pointToAdd = new PVector(x_prime, y_prime, z_prime);
    } else {
        // Regular 2D rotation in XY plane
        PVector penOnCanvas = penPos.copy();
        penOnCanvas.rotate(-canvasAngle); // Use negative angle for standard 2D canvas rotation
        pointToAdd = new PVector(penOnCanvas.x, penOnCanvas.y, 0); // Store with Z=0
    }

    // Add point if moved sufficiently (or if it's the very first point)
    if (path.isEmpty() || PVector.sub(pointToAdd, path.get(path.size()-1)).magSq() > 0.01) {
       path.add(pointToAdd);
    }
}

// --- New function to export 3D perspective view to SVG ---
void export3DViewToSVG(PGraphics svg) {
    println("Exporting 3D perspective view to SVG...");

    // Use global matrix operations on the main context, just like Lissajous3D does
    pushMatrix(); 
    
    // Center the view (matching what we do in draw())
    translate(width / 2.0, height / 2.0, 0);
    
    // Apply the mouse rotations exactly as they would appear on screen
    rotateX(mouseRotX);
    rotateY(mouseRotY);
    
    // Note: No explicit perspective call needed - P3D renderer already sets this up
    
    // Calculate projected points from the 3D path
    ArrayList<PVector> projectedPoints = new ArrayList<PVector>();
    
    if (path.size() > 1) {
        // First control point
        PVector p0 = path.get(0);
        projectedPoints.add(new PVector(screenX(p0.x, p0.y, p0.z), screenY(p0.x, p0.y, p0.z)));
        
        // All path points
        for (PVector p : path) {
            float sx = screenX(p.x, p.y, p.z);
            float sy = screenY(p.x, p.y, p.z);
            projectedPoints.add(new PVector(sx, sy));
        }
        
        // Last control point (same as last point, for closing the curve properly)
        PVector pLast = path.get(path.size()-1);
        projectedPoints.add(new PVector(screenX(pLast.x, pLast.y, pLast.z), screenY(pLast.x, pLast.y, pLast.z)));
    }
    
    // Restore main context's matrix state
    popMatrix();
    
    // Now draw the projected 2D points to the SVG
    svg.stroke(0);
    svg.strokeWeight(1);
    svg.noFill();
    
    if (projectedPoints.size() > 2) {
        svg.beginShape();
        
        // Add first point as control point
        svg.curveVertex(projectedPoints.get(0).x, projectedPoints.get(0).y);
        
        // Add all points including first and last
        for (PVector p : projectedPoints) {
            svg.curveVertex(p.x, p.y);
        }
        
        // Add last point as control point
        svg.curveVertex(projectedPoints.get(projectedPoints.size()-1).x, 
                         projectedPoints.get(projectedPoints.size()-1).y);
        
        svg.endShape();
    }
    
    println("Finished 3D SVG export calculation.");
}
