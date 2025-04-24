import peasy.*; // 3D Navigation
import controlP5.*; // GUI
import processing.svg.*; // SVG Export
import java.util.ArrayList;
import java.util.Iterator;
import java.io.File;
import javax.swing.JOptionPane; // For message dialogs

// --- 3D Camera ---
PeasyCam cam;

// --- GUI Controls ---
ControlP5 cp5;
int guiWidth = 260; // Width for the GUI panel
RadioButton probScaleRange; // Add radio button for probability scale range selection

// --- Constants and Parameters (Declarations Only) ---
int BASE_SIZE = 560; // This is just a number, safe to initialize
float ONE; // Calculated in setup
float INIT_BRANCH_RADIUS_FACTOR = 0.03; // Just a number, safe
float INIT_BRANCH_RADIUS; // Calculated in setup
float branchDiminishRate; // Calculated in setup
float branchSplitDiminishFactor = 0.7; // Just a number, safe
float branchProbScale = 5.0; // Just a number, safe
float branchSplitAngle = 0.4 * PI; // Just a constant, safe
float branchAngleMaxVariation; // Calculated in setup
float branchAngleExp = 2.0; // Just a number, safe

// --- Rendering Parameters ---
boolean drawLongitudinal = true; // Boolean flag, safe
boolean drawLatitudinal = true; // Boolean flag, safe
int numLongitudinalLines = 8; // Just a number, safe
int numLatitudinalRings = 5; // Just a number, safe

// --- Simulation State ---
Tree tree;
boolean finished = false;
boolean guiVisible = true; // Boolean flag, safe
ArrayList<Runnable> branchDrawCommands = new ArrayList<Runnable>();
final int MAX_DRAW_COMMANDS = 75000; // Just a number, safe

// --- Colors ---
color BACK; // Will be initialized in setup
color WIREFRAME_COLOR; // Will be initialized in setup

// --- SVG Export ---
boolean recordSVG = false; // Boolean flag, safe
String svgOutputPath = null; // Just null, safe

// =============================================================
//  SETTINGS - For size() and other environment settings
// =============================================================
void settings() {
  size(1920 + guiWidth, 1080, P3D); // Moved here from setup()
  smooth(8); // Move smooth here too
}

// =============================================================
//  SETUP
// =============================================================
void setup() {
  // Initialize Colors
  BACK = color(255);
  WIREFRAME_COLOR = color(0, 100); // Black, semi-transparent

  // Initialize PeasyCam
  cam = new PeasyCam(this, guiWidth, 0, 0, 600);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(2000);
  cam.setLeftDragHandler(cam.getRotateDragHandler());
  cam.setRightDragHandler(cam.getZoomDragHandler());
  cam.setCenterDragHandler(cam.getPanDragHandler());

  // Calculate derived constants
  ONE = 1.0 / BASE_SIZE;
  INIT_BRANCH_RADIUS = BASE_SIZE * INIT_BRANCH_RADIUS_FACTOR * ONE;
  branchDiminishRate = ONE / 32.0;
  branchAngleMaxVariation = 8.0 * PI / BASE_SIZE;

  // Setup GUI
  setupGUI();

  // Initialize Tree
  restartTree();

  println("Setup complete. Starting 3D simulation...");
}

// =============================================================
//  DRAW
// =============================================================
void draw() {
  // Handle SVG Recording First
  if (recordSVG) {
    try {
      println("Creating SVG...");
      // Create SVG graphics context WITH P3D renderer if possible,
      // otherwise P2D will be used by default for SVG output.
      // Projection happens automatically based on camera state.
      PGraphicsSVG svg = (PGraphicsSVG) createGraphics(width - guiWidth, height, SVG, svgOutputPath);
      svg.beginDraw();
      svg.background(BACK); // Clear SVG background

      // Apply PeasyCam's current state to the SVG context
      cam.getState().apply(svg); // Apply rotation, translation, distance

      drawTree(svg); // Draw the tree geometry to the SVG context
      svg.endDraw();
      svg.dispose();
      println("SVG saved to: " + svgOutputPath);

      // Confirmation Dialog
      File outputFile = new File(svgOutputPath);
      if (outputFile.exists() && outputFile.length() > 0) {
          showSuccessDialog("SVG exported successfully to:\n" + svgOutputPath);
      } else {
          showErrorDialog("Error: SVG file was not created or is empty.\nCheck console output.");
      }
    } catch (Exception e) {
      println("Error creating SVG: " + e.getMessage());
      e.printStackTrace();
      showErrorDialog("Error creating SVG: " + e.getMessage());
    } finally {
      recordSVG = false;
      svgOutputPath = null;
      System.gc();
    }
  }

  // --- Simulation Step (only if not finished) ---
  if (!finished && !recordSVG) { // Don't simulate while recording SVG
    // 1. Generate draw commands for the *current* state before stepping
    ArrayList<Runnable> commandsThisFrame = tree.getDrawCommandsForCurrentStep();
    if (branchDrawCommands.size() + commandsThisFrame.size() < MAX_DRAW_COMMANDS) {
        branchDrawCommands.addAll(commandsThisFrame);
    } else if (!finished) {
        println("Max draw commands reached: " + MAX_DRAW_COMMANDS);
        finished = true; // Stop simulation
    }

    // 2. Advance simulation state for the *next* frame
    if (!finished) {
        tree.step();
    }
  }

  // --- Rendering ---
  // 1. Clear the main background
  background(BACK);

  // 2. Draw the GUI panel background (if visible)
  if (guiVisible) {
    // Only draw the GUI background for the actual GUI panel, not the entire left side
    fill(230); // Light gray for GUI background
    noStroke();
    rect(0, 0, guiWidth, height); // Draw on main canvas (2D)
  }

  // 3. PeasyCam handles the camera transformations for the main display
  // No push/pop needed here for camera, PeasyCam does it internally

  // 4. Draw the Tree using accumulated commands (respecting GUI offset)
  // We draw the tree within the 3D world managed by PeasyCam
  // Note: PeasyCam's HUD mode could be used for GUI, but drawing directly is simpler here.
  drawTree(this.g); // Draw to the main graphics context

  // 5. Draw GUI Controls ON TOP (in 2D screen space)
  cam.beginHUD(); // Switch to 2D overlay drawing mode
  cp5.draw();
  cam.endHUD(); // Switch back to 3D world view
}

// =============================================================
//  Tree Drawing Function (Used by draw() and SVG export)
// =============================================================
void drawTree(PGraphics pg) {
  pg.pushMatrix(); // Isolate transformations for tree drawing
  // No need to translate by guiWidth here, PeasyCam handles the viewport

  // Set drawing styles for the tree
  pg.stroke(WIREFRAME_COLOR);
  pg.strokeWeight(1); // Fine lines for wireframe
  pg.noFill();

  // Execute all stored drawing commands
  for (Runnable command : branchDrawCommands) {
    command.run(); // Assumes command operates on the active PGraphics context
  }

  pg.popMatrix(); // Restore previous drawing state
}


// =============================================================
//  Branch Class (3D Adaptation)
// =============================================================
class Branch {
  Tree treeRef;
  PVector pos; // Current position (tip of the branch)
  PVector dir; // Current direction of growth
  float r;     // Current radius
  int g;       // Generation

  PVector prevPos; // Position at the start of the last step (for segment drawing)
  float prevR;   // Radius at the start of the last step

  Branch(Tree treeRef, PVector pos, PVector dir, float r, int g) {
    this.treeRef = treeRef;
    this.pos = pos.copy();
    this.dir = dir.copy().normalize(); // Ensure direction is normalized
    this.r = r;
    this.g = g;

    this.prevPos = pos.copy(); // Initialize previous state
    this.prevR = r;
  }

  // --- Step Simulation ---
  void step() {
    // Store current state as previous state for segment drawing
    prevPos = pos.copy();
    prevR = r;

    // Diminish radius
    this.r = max(0, this.r - treeRef.branch_diminish_rate); // Prevent negative radius

    if (this.r <= 0) return; // Stop processing if branch is too thin

    // Update direction (random walk in 3D)
    applyRandomRotation();

    // Update position
    float stepsize = treeRef.stepsize; // Use tree's stepsize
    pos.add(PVector.mult(dir, stepsize));
  }

  // --- Apply Random Rotation to Direction ---
  void applyRandomRotation() {
    // Calculate scale factor based on how much the branch has thinned
    float scale = treeRef.root_r - this.r; // How much radius has been lost
    float da_scale = pow(1.0 + max(0, scale / treeRef.root_r), treeRef.branch_angle_exp);

    // Calculate rotation magnitude
    float angleMagnitude = randomGaussian() * treeRef.branch_angle_max_variation * da_scale;

    // Generate a random rotation axis perpendicular to the current direction
    PVector randomVec = PVector.random3D(); // Get a random unit vector
    PVector rotationAxis = dir.cross(randomVec); // Find a vector perpendicular to dir and randomVec
    if (rotationAxis.magSq() < 1e-8) { // If dir and randomVec are (anti)parallel
      // Pick another random vector or a default axis (e.g., world X)
       PVector altRandom = abs(dir.x) > 0.9 ? new PVector(0, 1, 0) : new PVector(1, 0, 0);
       rotationAxis = dir.cross(altRandom);
    }
    rotationAxis.normalize();

    // Apply the rotation using Rodrigues' rotation formula
    float cosTheta = cos(angleMagnitude);
    float sinTheta = sin(angleMagnitude);
    PVector crossProduct = rotationAxis.cross(dir);
    float dotProduct = rotationAxis.dot(dir);

    PVector rotatedDir = PVector.mult(dir, cosTheta);
    rotatedDir.add(PVector.mult(crossProduct, sinTheta));
    rotatedDir.add(PVector.mult(rotationAxis, dotProduct * (1 - cosTheta)));

    dir = rotatedDir; // Update the direction vector

    dir.normalize(); // Ensure it stays normalized
  }

  // --- Generate Drawing Commands for the Last Segment ---
  // Returns a Runnable containing the drawing calls for the segment defined
  // by (prevPos, prevR) -> (pos, r)
  Runnable getDrawCommand() {
    if (this.r * BASE_SIZE < 0.2 || prevR * BASE_SIZE < 0.2) { // Optimization: Skip tiny segments
      return null;
    }

    // Capture state for the Runnable
    final PVector start = prevPos.copy();
    final PVector end = pos.copy();
    final float startRadius = prevR;
    final float endRadius = this.r;
    final PVector segmentDir = PVector.sub(end, start).normalize(); // Direction of this specific segment

    // Determine if drawing is needed based on global toggles
    final boolean doLong = drawLongitudinal && numLongitudinalLines > 0;
    final boolean doLat = drawLatitudinal && numLatitudinalRings > 1;
    final int nLong = numLongitudinalLines;
    final int nLat = numLatitudinalRings;

    if (!doLong && !doLat) {
        return null; // Nothing to draw
    }

    // Return the lambda function (Runnable) that performs the drawing
    return () -> {
      // Get the current graphics context (could be main screen or SVG)
      PGraphics pg = getGraphics(); // Use current context

      // Find two vectors orthogonal to the segment direction to define the plane of the rings
      PVector u, v;
      PVector helper = abs(segmentDir.y) > 0.9 ? new PVector(1, 0, 0) : new PVector(0, 1, 0);
      u = segmentDir.cross(helper).normalize();
      v = segmentDir.cross(u).normalize();

      // --- Draw Longitudinal Lines ---
      if (doLong) {
        for (int i = 0; i < nLong; i++) {
          float angle = TWO_PI * i / nLong;
          float cosA = cos(angle);
          float sinA = sin(angle);

          // Calculate offset vector from center axis
          PVector offsetU = PVector.mult(u, cosA);
          PVector offsetV = PVector.mult(v, sinA);
          PVector offsetStart = PVector.add(offsetU, offsetV).mult(startRadius);
          PVector offsetEnd = PVector.add(offsetU, offsetV).mult(endRadius);

          // Calculate start and end points of the longitudinal line
          PVector p1 = PVector.add(start, offsetStart);
          PVector p2 = PVector.add(end, offsetEnd);

          // Scale coordinates by BASE_SIZE for drawing
          pg.line(p1.x * BASE_SIZE, p1.y * BASE_SIZE, p1.z * BASE_SIZE,
                  p2.x * BASE_SIZE, p2.y * BASE_SIZE, p2.z * BASE_SIZE);
        }
      }

      // --- Draw Latitudinal Rings ---
      if (doLat) {
        int ringPoints = 12; // Number of segments per ring circle
        for (int i = 0; i < nLat; i++) {
          float t = (float)i / (nLat - 1); // Interpolation factor along the segment (0 to 1)
          PVector center = PVector.lerp(start, end, t);
          float radius = lerp(startRadius, endRadius, t);

          if (radius * BASE_SIZE < 0.1) continue; // Skip tiny rings

          // Draw the ring
          pg.beginShape();
          for (int j = 0; j <= ringPoints; j++) {
            float angle = TWO_PI * j / ringPoints;
            float cosA = cos(angle);
            float sinA = sin(angle);
            PVector offsetU = PVector.mult(u, cosA);
            PVector offsetV = PVector.mult(v, sinA);
            PVector ringPoint = PVector.add(center, PVector.add(offsetU, offsetV).mult(radius));
            pg.vertex(ringPoint.x * BASE_SIZE, ringPoint.y * BASE_SIZE, ringPoint.z * BASE_SIZE);
          }
          pg.endShape();
        }
      }
    };
  }
}


// =============================================================
//  Tree Class (3D Adaptation)
// =============================================================
class Tree {
  // Root and simulation parameters (copied or referenced)
  PVector root_pos;
  PVector root_dir;
  float root_r;

  float one; // = ONE
  float stepsize;

  // Parameters updated from GUI
  float branch_split_angle;
  float branch_prob_scale_factor; // Multiplier derived from branchProbScale and root_r
  float branch_diminish_rate;
  float branch_split_diminish_factor;
  float branch_angle_max_variation;
  float branch_angle_exp;

  ArrayList<Branch> Q; // List of ACTIVE branches for the current step

  Tree(PVector root_pos, PVector root_dir, float root_r,
       float one, float stepsize,
       // Pass GUI-controlled parameters directly
       float branchSplitAngle, float branchProbScale, float branchDiminishRate,
       float branchSplitDiminishFactor, float branchAngleMaxVariation, float branchAngleExp)
  {
    this.root_pos = root_pos.copy();
    this.root_dir = root_dir.copy().normalize();
    this.root_r = root_r;
    this.one = one;
    this.stepsize = one; // Step size relative to BASE_SIZE unit

    // Store GUI parameters
    updateParameters(branchSplitAngle, branchProbScale, branchDiminishRate,
                     branchSplitDiminishFactor, branchAngleMaxVariation, branchAngleExp);

    init();
  }

  void init() {
    Q = new ArrayList<Branch>();
    // Create the initial trunk branch
    Branch rootBranch = new Branch(this, root_pos, root_dir, root_r, 0);
    Q.add(rootBranch);
  }

  // Method to update tree parameters from GUI
  void updateParameters(float branchSplitAngle, float branchProbScale, float branchDiminishRate,
                        float branchSplitDiminishFactor, float branchAngleMaxVariation, float branchAngleExp) {
    this.branch_split_angle = branchSplitAngle;
    this.branch_diminish_rate = branchDiminishRate;
    this.branch_split_diminish_factor = branchSplitDiminishFactor;
    this.branch_angle_max_variation = branchAngleMaxVariation;
    this.branch_angle_exp = branchAngleExp;

    // Recalculate probability scale factor based on root radius and GUI scale
    // This tries to keep the effective probability somewhat consistent if root_r changes,
    // but primarily scales with the GUI slider value.
    // The division by root_r makes probability higher for thinner initial branches,
    // similar to the 2D version. The constant factor adjusts the sensitivity.
    if (this.root_r > 1e-6) {
       this.branch_prob_scale_factor = branchProbScale / (this.root_r * BASE_SIZE) * 0.5; // Adjusted multiplier
    } else {
       this.branch_prob_scale_factor = branchProbScale * 10.0; // Default if root_r is tiny
    }
    //println("Updated Prob Scale Factor: " + this.branch_prob_scale_factor);
  }

  // Returns list of draw commands for the segments generated in the *last* step
  ArrayList<Runnable> getDrawCommandsForCurrentStep() {
      ArrayList<Runnable> commands = new ArrayList<Runnable>();
      // Get commands from *all* active branches based on their last step
      for (Branch b : Q) {
          Runnable cmd = b.getDrawCommand();
          if (cmd != null) {
              commands.add(cmd);
          }
      }
      return commands;
  }

  void step() {
    if (Q.isEmpty()) {
      if (!finished) {
         println("Tree finished growing. Draw Commands: " + branchDrawCommands.size());
         finished = true;
      }
      return;
    }

    ArrayList<Branch> nextQ = new ArrayList<Branch>();
    ArrayList<Branch> newBranches = new ArrayList<Branch>();
    boolean limitReached = (branchDrawCommands.size() >= MAX_DRAW_COMMANDS); // Check draw command limit

    if (limitReached && !finished) {
        println("Draw command limit reached during step. Halting simulation.");
        finished = true;
        return;
    }

    Iterator<Branch> iterator = Q.iterator();
    while (iterator.hasNext()) {
        Branch b = iterator.next();
        b.step(); // Update branch state (pos, dir, radius)

        if (b.r <= 0) {
            iterator.remove(); // Branch died, remove from active list
            continue;
        }

        // Probability of splitting (increases as branch thins)
        float branch_prob = (this.root_r - b.r) * this.branch_prob_scale_factor;
        branch_prob = constrain(branch_prob, 0, 1); // Clamp probability

        // Check limits again before potentially adding branches
        limitReached = (branchDrawCommands.size() >= MAX_DRAW_COMMANDS || Q.size() + newBranches.size() >= MAX_DRAW_COMMANDS / 2); // Also limit active branches?

        if (!limitReached && random(1.0) < branch_prob) {
            // --- Split into a new branch ---

            // 1. Calculate new branch radius
            float new_r = this.branch_split_diminish_factor * b.r;

            // 2. Calculate new branch direction
            // Generate a random axis perpendicular to the parent's direction
            PVector randomVec = PVector.random3D();
            PVector rotationAxis = b.dir.cross(randomVec);
            if (rotationAxis.magSq() < 1e-8) {
                PVector altRandom = abs(b.dir.y) > 0.9 ? new PVector(1, 0, 0) : new PVector(0, 1, 0);
                rotationAxis = b.dir.cross(altRandom);
            }
            rotationAxis.normalize();

            // Rotate parent direction by split angle around the random axis using Rodrigues' formula
            PVector parentDir = b.dir; // Vector to rotate
            float angle = this.branch_split_angle; // Angle to rotate by
            float cosTheta = cos(angle);
            float sinTheta = sin(angle);
            PVector crossProduct = rotationAxis.cross(parentDir);
            float dotProduct = rotationAxis.dot(parentDir);

            PVector new_dir = PVector.mult(parentDir, cosTheta);
            new_dir.add(PVector.mult(crossProduct, sinTheta));
            new_dir.add(PVector.mult(rotationAxis, dotProduct * (1 - cosTheta)));

            new_dir.normalize();

            // 3. Create the new branch segment
            Branch newB = new Branch(this, b.pos, new_dir, new_r, b.g + 1);
            newBranches.add(newB);

            // Optional: Slightly alter the original branch's direction too?
            // b.dir.rotate(-this.branch_split_angle * 0.1, rotationAxis); // Give original a slight nudge away
            // b.dir.normalize();
        }
        // Original branch 'b' always continues (unless it died)
    }

    // Add the newly created branches to the main active list for the next step
    Q.addAll(newBranches);
  }
}


// =============================================================
//  GUI SETUP & HANDLERS
// =============================================================
void setupGUI() {
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false); // We'll draw manually with HUD
  
  // Set global color scheme for text labels
  int labelColor = color(0); // Black for labels
  int textColor = color(0); // Black for input text
  int valueColor = color(255); // White for slider values
  
  // Apply text color to all controllers
  cp5.setColorActive(color(0, 0, 140)); // Dark blue for active controls
  cp5.setColorForeground(color(0, 0, 100)); // Blue for foreground/hover
  cp5.setColorCaptionLabel(labelColor); // Black for captions
  cp5.setColorValueLabel(valueColor); // White for value display on sliders
  
  int xPos = 10;
  int yPos = 10;
  int spacing = 30;
  int controlW = guiWidth - 2 * xPos;
  int inputW = 60;
  int inputH = 18;
  int labelW = controlW - inputW - 10;
  int radioSize = 14; // Size for radio buttons

  // --- Simulation Parameters Group ---
  Group simGroup = cp5.addGroup("Simulation Parameters")
    .setPosition(xPos, yPos)
    .setWidth(controlW)
    .setBackgroundHeight(250) // Increased height for radio buttons
    .setBackgroundColor(color(200, 180)) // Semi-transparent background
    .setLabel("SIMULATION");
  simGroup.getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE).setPaddingY(5);

  yPos += 25; // Space for group title

  // Branch Probability Scale
  cp5.addSlider("branchProbScale")
    .setPosition(xPos, yPos).setSize(controlW, inputH).setRange(0.0, 20.0).setValue(branchProbScale)
    .setLabel("Branch Probability Scale").setGroup(simGroup).setDecimalPrecision(2)
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2).setColor(labelColor);
  yPos += spacing;
  
  // Probability Scale Range Radio Buttons
  // Add caption for the radio buttons
  cp5.addTextlabel("probScaleRangeLabel")
     .setText("Probability Scale Range:")
     .setPosition(xPos, yPos + 3)
     .setColor(labelColor)
     .setGroup(simGroup);
  yPos += 18; // Space after label
  
  // Create the radio button group
  probScaleRange = cp5.addRadioButton("probScaleRange")
                     .setPosition(xPos, yPos)
                     .setSize(radioSize, radioSize)
                     .setItemsPerRow(3)
                     .setSpacingColumn(controlW / 3)
                     .setGroup(simGroup)
                     .setNoneSelectedAllowed(false);
                     
  probScaleRange.addItem("0-20", 0);
  probScaleRange.addItem("0-100", 1);
  probScaleRange.addItem("0-500", 2);
  probScaleRange.activate(0); // Activate 0-20 by default (current setting)
  
  // Set color for the radio button labels
  for (Toggle t : probScaleRange.getItems()) {
    t.getCaptionLabel().setColor(labelColor);
  }
  
  // Force initial range setup by directly calling the handler
  updateProbabilityRange(0);
  
  yPos += spacing + 5; // Extra space after radio buttons

  // Branch Split Angle
  cp5.addSlider("branchSplitAngleRad") // Use Radians internally
    .setPosition(xPos, yPos).setSize(controlW, inputH).setRange(0.0, PI * 0.8).setValue(branchSplitAngle)
    .setLabel("Split Angle (Radians)").setGroup(simGroup).setDecimalPrecision(2)
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2).setColor(labelColor);
  yPos += spacing + 5;

  // Branch Thinning Rate
  cp5.addSlider("branchDiminishRate")
    .setPosition(xPos, yPos).setSize(controlW, inputH).setRange(ONE / 100.0, ONE / 10.0).setValue(branchDiminishRate)
    .setLabel("Branch Thinning Rate").setGroup(simGroup).setDecimalPrecision(5) // Needs high precision
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2).setColor(labelColor);
  yPos += spacing + 5;

  // New Branch Thickness Factor
  cp5.addSlider("branchSplitDiminishFactor")
    .setPosition(xPos, yPos).setSize(controlW, inputH).setRange(0.3, 0.95).setValue(branchSplitDiminishFactor)
    .setLabel("New Branch Thickness Factor").setGroup(simGroup).setDecimalPrecision(2)
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2).setColor(labelColor);
  yPos += spacing + 5;

  // Max Angle Variation
   cp5.addSlider("branchAngleMaxVariationRad") // Use Radians internally
    .setPosition(xPos, yPos).setSize(controlW, inputH).setRange(0, PI / 10.0).setValue(branchAngleMaxVariation)
    .setLabel("Max Angle Variation (Rad)").setGroup(simGroup).setDecimalPrecision(3)
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2).setColor(labelColor);
  yPos += spacing + 5;

  // Curve Intensity (Angle Exponent)
  cp5.addSlider("branchAngleExp")
    .setPosition(xPos, yPos).setSize(controlW, inputH).setRange(0.5, 5.0).setValue(branchAngleExp)
    .setLabel("Curve Intensity").setGroup(simGroup).setDecimalPrecision(1)
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2).setColor(labelColor);
  yPos += spacing + 15; // Extra space before next group


  // --- Rendering Parameters Group ---
  Group renderGroup = cp5.addGroup("Rendering Parameters")
    .setPosition(xPos, yPos)
    .setWidth(controlW)
    .setBackgroundHeight(150) // Adjust height
    .setBackgroundColor(color(200, 180))
    .setLabel("RENDERING");
  renderGroup.getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE).setPaddingY(5);

  yPos += 25;

  // Longitudinal Lines Toggle
  cp5.addToggle("drawLongitudinal")
    .setPosition(xPos, yPos).setSize(inputH * 2, inputH).setValue(drawLongitudinal)
    .setLabel("Longitudinal").setGroup(renderGroup)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(5);
  // Longitudinal Lines Count Textfield
  cp5.addTextfield("numLongitudinalLinesInput")
     .setPosition(xPos + controlW - inputW, yPos).setSize(inputW, inputH).setAutoClear(false)
     .setValue(""+numLongitudinalLines).setLabel("").setGroup(renderGroup)
     .setColorValue(textColor) // Set text color explicitly
     .getCaptionLabel().setColor(labelColor);
  yPos += spacing;

  // Latitudinal Lines Toggle
  cp5.addToggle("drawLatitudinal")
    .setPosition(xPos, yPos).setSize(inputH * 2, inputH).setValue(drawLatitudinal)
    .setLabel("Latitudinal").setGroup(renderGroup)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(5);
  // Latitudinal Lines Count Textfield
  cp5.addTextfield("numLatitudinalRingsInput")
     .setPosition(xPos + controlW - inputW, yPos).setSize(inputW, inputH).setAutoClear(false)
     .setValue(""+numLatitudinalRings).setLabel("").setGroup(renderGroup)
     .setColorValue(textColor) // Set text color explicitly
     .getCaptionLabel().setColor(labelColor);
  yPos += spacing + 10;

  // --- Actions Group ---
   Group actionGroup = cp5.addGroup("Actions")
    .setPosition(xPos, yPos)
    .setWidth(controlW)
    .setBackgroundHeight(80) // Adjust height
    .setBackgroundColor(color(200, 180))
    .setLabel("ACTIONS");
  actionGroup.getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE).setPaddingY(5);
   yPos += 25;

  // Restart Button
  cp5.addButton("restartTree")
    .setPosition(xPos, yPos).setSize((controlW / 2) - 5, inputH + 5)
    .setLabel("Restart Tree (R)").setGroup(actionGroup);
  // Export SVG Button
  cp5.addButton("exportSVG")
    .setPosition(xPos + (controlW / 2) + 5, yPos).setSize((controlW / 2) - 5, inputH + 5)
    .setLabel("Export SVG (S)").setGroup(actionGroup);

}

// --- ControlP5 Event Handler ---
void controlEvent(ControlEvent event) {
  // Safely get name and value first - these seem reliable
  String name = event.getName();
  float value = event.getValue();
  
  // Print minimal debug info initially
  println("DEBUG: Control Event Received. Name: \"" + name + "\", Value: " + value);

  // --- Handle RadioButton by NAME first --- 
  // Check ONLY the name before calling any other event methods
  if (name != null && name.equals("probScaleRange")) {
    int rangeIndex = (int)value;
    println("DEBUG: Radio group 'probScaleRange' event detected by NAME. Index: " + rangeIndex);
    updateProbabilityRange(rangeIndex);
    return; // Handled, exit function immediately
  }

  // --- If NOT the RadioButton, proceed with handling other controllers ---
  // It should now be safe to call other event methods
  println("DEBUG: Event is NOT from RadioButton, proceeding with full handling...");
  Controller controller = null;
  String stringValue = ""; // Initialize default
  
  try {
    // Now it should be safe to get the controller and string value
    if(event.isController()) { 
        controller = event.getController();
        stringValue = event.getStringValue(); // Get string value only if it's a controller
        println("DEBUG: Controller obtained: " + controller + ", StringValue: \"" + stringValue + "\"");
    } else {
         println("DEBUG: Event ignored - event.isController() returned false. Name: " + name);
         return;
    }
    
    if (controller == null) {
        println("DEBUG: Event from controller, but getController() returned null. Name: " + name);
        return; 
    }
    
  } catch (ClassCastException e) {
    // Catch potential issues even with the delayed access
    println("ERROR: ClassCastException accessing controller/stringValue for event name: \"" + name + "\". ControlP5 Bug?");
    e.printStackTrace();
    return; // Cannot proceed safely
  } catch (Exception e) {
    // Catch any other unexpected errors
     println("ERROR: Unexpected exception accessing controller/stringValue for event name: \"" + name + "\"");
     e.printStackTrace();
     return;
  }
  
  // --- Now handle known controller types using the 'controller' object --- 
  println("DEBUG: Processing event for Controller: " + controller + " (Name: " + name + ")");

  if (controller instanceof Textfield) {
    Textfield tf = (Textfield) controller;
    if (name.equals("numLongitudinalLinesInput")) {
      try { numLongitudinalLines = max(0, Integer.parseInt(stringValue)); }
      catch (NumberFormatException e) { /* Ignore invalid input */ }
      tf.setValue(""+numLongitudinalLines);
      clearAndRestartDrawing();
    } else if (name.equals("numLatitudinalRingsInput")) {
      try { numLatitudinalRings = max(0, Integer.parseInt(stringValue)); }
      catch (NumberFormatException e) { /* Ignore invalid input */ }
      tf.setValue(""+numLatitudinalRings);
      clearAndRestartDrawing();
    }
  } else if (controller instanceof Toggle) {
    // Handle standard toggles (excluding radio button internals, handled above by name)
    if (name.equals("drawLongitudinal")) {
      drawLongitudinal = value > 0;
      clearAndRestartDrawing();
    } else if (name.equals("drawLatitudinal")) {
      drawLatitudinal = value > 0;
      clearAndRestartDrawing();
    } else {
       println("DEBUG: Unhandled Toggle event for controller: " + name);
    }
  } else if (controller instanceof Button) {
    if (name.equals("restartTree")) {
      restartTree();
    } else if (name.equals("exportSVG")) {
      requestSVGExport();
    }
  } else if (controller instanceof Slider) {
    if (name.equals("branchProbScale") || name.equals("branchSplitAngleRad") ||
        name.equals("branchDiminishRate") || name.equals("branchSplitDiminishFactor") ||
        name.equals("branchAngleMaxVariationRad") || name.equals("branchAngleExp"))
    {
      updateTreeParameters();
    }
  } else {
    println("DEBUG: Unhandled controller type: " + controller.getClass().getName() + " for event name: " + name);
  }
}

// Separate function to update probability slider range
void updateProbabilityRange(int rangeIndex) {
  println("DEBUG: updateProbabilityRange called with index: " + rangeIndex);
  Slider probSlider = (Slider)cp5.getController("branchProbScale");
  if (probSlider == null) {
    println("ERROR: Could not find branchProbScale slider!");
    return;
  }
  
  float currentValue = probSlider.getValue();
  float currentMin = probSlider.getMin();
  float currentMax = probSlider.getMax();
  println("DEBUG: Slider range BEFORE update: [" + currentMin + ", " + currentMax + "]");
  
  float newMax = 20.0; // Default range
  
  switch (rangeIndex) {
    case 0: // 0-20
      newMax = 20.0;
      break;
    case 1: // 0-100
      newMax = 100.0;
      break;
    case 2: // 0-500
      newMax = 500.0;
      break;
  }
  
  println("DEBUG: Calculated newMax: " + newMax);
  
  // Update slider range
  probSlider.setRange(0.0, newMax);
  
  // Check range immediately after setting
  float updatedMin = probSlider.getMin();
  float updatedMax = probSlider.getMax();
  println("DEBUG: Slider range AFTER update: [" + updatedMin + ", " + updatedMax + "]");

  // Clamp current value if it exceeds the new range
  if (currentValue > newMax) {
    println("DEBUG: Clamping slider value from " + currentValue + " to " + newMax);
    probSlider.setValue(newMax);
  } else {
    // Even if not clamping, setting the value might be necessary to refresh the display?
    // probSlider.setValue(currentValue); // Let's not add this yet
  }
  
  // Update the tree with current parameters
  println("DEBUG: Calling updateTreeParameters after range change.");
  updateTreeParameters();
}

// Helper function to update tree parameters from the GUI
void updateTreeParameters() {
  println("DEBUG: updateTreeParameters called.");
  // Update tree parameters immediately using current slider values
  if (tree != null) {
    tree.updateParameters(
      cp5.getController("branchSplitAngleRad").getValue(),
      cp5.getController("branchProbScale").getValue(),
      cp5.getController("branchDiminishRate").getValue(),
      cp5.getController("branchSplitDiminishFactor").getValue(),
      cp5.getController("branchAngleMaxVariationRad").getValue(),
      cp5.getController("branchAngleExp").getValue()
    );
  }
}

// =============================================================
//  KEY & MOUSE HANDLERS
// =============================================================

// PeasyCam handles mouse dragging for camera control.
// We only need keyPressed for shortcuts.

void keyPressed() {
  if (key == 'r' || key == 'R') {
     restartTree();
  } else if (key == 's' || key == 'S') {
     requestSVGExport();
  } else if (key == 'h' || key == 'H') {
      guiVisible = !guiVisible;
      // Adjust PeasyCam's viewport offset if GUI visibility changes
      cam.setViewport(guiVisible ? guiWidth : 0, 0, width - (guiVisible ? guiWidth : 0), height);
  }
}

// =============================================================
//  HELPER FUNCTIONS
// =============================================================

void restartTree() {
  println("Restarting tree...");

  // Reset state variables
  finished = false;
  branchDrawCommands.clear(); // Clear the stored drawing commands
  System.gc(); // Hint for garbage collection

  // Re-calculate initial radius based on BASE_SIZE
  INIT_BRANCH_RADIUS = BASE_SIZE * INIT_BRANCH_RADIUS_FACTOR * ONE;

  // Create new tree with current GUI parameters
  PVector startPos = new PVector(0, height * 0.4 / BASE_SIZE, 0); // Start near bottom-center (in world units)
  PVector startDir = new PVector(0, -1, 0); // Grow upwards initially

  // Ensure GUI controllers exist before accessing their values
  if (cp5 != null && cp5.getController("branchSplitAngleRad") != null) {
      tree = new Tree(
        startPos, startDir, INIT_BRANCH_RADIUS,
        ONE, ONE, // stepsize = ONE
        cp5.getController("branchSplitAngleRad").getValue(),
        cp5.getController("branchProbScale").getValue(),
        cp5.getController("branchDiminishRate").getValue(),
        cp5.getController("branchSplitDiminishFactor").getValue(),
        cp5.getController("branchAngleMaxVariationRad").getValue(),
        cp5.getController("branchAngleExp").getValue()
      );
  } else {
      // Fallback if GUI isn't ready yet (e.g., initial setup call)
      tree = new Tree(
        startPos, startDir, INIT_BRANCH_RADIUS,
        ONE, ONE,
        branchSplitAngle, branchProbScale, branchDiminishRate,
        branchSplitDiminishFactor, branchAngleMaxVariation, branchAngleExp
      );
  }

  // Add initial draw commands for the new tree's root "segment" (optional, or let first step handle)
  // ArrayList<Runnable> initialCommands = tree.getDrawCommandsForCurrentStep();
  // branchDrawCommands.addAll(initialCommands);
}

// Helper to clear draw commands and mark as unfinished (used when render params change)
void clearAndRestartDrawing() {
    branchDrawCommands.clear();
    finished = false; // Allow simulation to continue if it was finished due to draw limits
    // No need to create a new Tree object, just redraw existing geometry with new render settings
    // The drawTree function will now use the updated global toggle/count variables.
}


// --- SVG Export Logic ---
void requestSVGExport() {
  println("SVG export requested...");
  if (recordSVG) {
    println("Export already in progress.");
    return;
  }
  // Use Processing's selectOutput to get file path
  selectOutput("Save SVG as...", "svgFileSelected",
    new File(sketchPath(""), "Tree3D_" + getTimestamp() + ".svg"), this);
}

void svgFileSelected(File selection) {
  if (selection == null) {
    println("SVG export cancelled.");
    return;
  }
  svgOutputPath = selection.getAbsolutePath();
  println("Selected SVG path: " + svgOutputPath);

  // Check and delete existing file (optional, Processing might handle overwrite)
  File outputFile = new File(svgOutputPath);
  if (outputFile.exists()) {
    println("File already exists, attempting to delete: " + svgOutputPath);
    if (!outputFile.delete()) {
        println("Warning: Could not delete existing file. SVG export might fail or overwrite.");
    }
  }
  recordSVG = true; // Set flag to trigger SVG generation in the *next* draw() cycle
}

String getTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" +
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

// --- Dialog Boxes ---
void showSuccessDialog(String message) {
    JOptionPane.showMessageDialog(null, message, "Success", JOptionPane.INFORMATION_MESSAGE);
}

void showErrorDialog(String message) {
    JOptionPane.showMessageDialog(null, message, "Error", JOptionPane.ERROR_MESSAGE);
}
