import java.util.ArrayList;
import java.util.Iterator;
import java.io.File;
import controlP5.*; // Import ControlP5 library for GUI
import processing.svg.*; // Import SVG library for export

// --- GUI Controls ---
ControlP5 cp5;
int guiWidth = 240;
boolean guiVisible = true;
// Toggle extendProbRangeToggle; // Replaced by RadioButton
RadioButton probScaleRange; // Radio buttons for scale selection

// --- Panning State ---
float offsetX = 0;
float offsetY = 0;
float panStartX, panStartY; // Mouse position when panning starts
float startOffsetX, startOffsetY; // Canvas offset when panning starts
boolean isPanning = false;

// --- Constants based on main_ani.py ---
int SIZE = 560;
float ONE; // Calculated in setup: 1.0 / SIZE;

float MID = 0.5;

float INIT_BRANCH; // Calculated in setup: SIZE * 0.03 * ONE;
int GRAINS; // Calculated in setup: (int)(SIZE * 0.02);

float BRANCH_DIMINISH; // Calculated in setup: ONE / 32.0;
float BRANCH_SPLIT_DIMINISH = 0.71;
float BRANCH_PROB_SCALE; // Calculated in setup: 1.0 / (INIT_BRANCH) / SIZE * 20.0;
                          // Adjusted for new default range

float BRANCH_SPLIT_ANGLE = 0.3 * PI;
float BRANCH_ANGLE_MAX; // Calculated in setup: 5.0 * PI / SIZE;
float BRANCH_ANGLE_EXP = 2.0;

// --- Safety Limit ---
final int MAX_BRANCHES = 10000; // Increased limit, as we store commands now, not just objects
final int MAX_DRAW_COMMANDS = 50000; // Safety limit for drawing commands

// --- Colors (scaled to 0-255) ---
color BACK = color(255, 255, 255, 255); // [1,1,1,1]
color FRONT = color(0, 0, 0, 128); // [0, 0, 0, 0.5]
color TRUNK_STROKE = color(0, 0, 0, 255); // [0, 0, 0, 1]
color TRUNK = color(255, 255, 255, 255); // [1, 1, 1, 1]
// TRUNK_SHADE = [0,0,0,0.5] -> Used implicitly in branch rendering alpha? Let's use FRONT for now.

// --- Animation State ---
Tree tree;
int frameCounter = 0;
boolean finished = false;
String outputDir = "output";
// ArrayList<Branch> allBranches = new ArrayList<Branch>(); // Replaced by draw commands
ArrayList<Runnable> branchDrawCommands = new ArrayList<Runnable>(); // Stores drawing commands

// --- Branch Class ---
class Branch {
  Tree treeRef; // Reference to the main tree object for accessing constants
  float x, y, r, a;
  int g; // Generation
  int i; // Internal step counter (unused in drawing, kept for parity)
  
  // Store original position/radius/angle for potential redraw/reset?
  // Not strictly needed for current plan but might be useful later.

  Branch(Tree treeRef, float x, float y, float r, float a, int g) {
    this.treeRef = treeRef;
    this.x = x;
    this.y = y;
    this.r = r;
    this.a = a; // Angle
    this.g = g;
    this.i = 0;
  }

  void step() {
    // Diminish radius
    this.r = this.r - this.treeRef.branch_diminish;

    // Update angle (random walk)
    float angle_rand = randomGaussian() * this.treeRef.branch_angle_max; // normal() -> randomGaussian()
    float scale = this.treeRef.one + this.treeRef.root_r - this.r;
    // The exponentiation term: (1 + scale / root_r)^exp
    float da_scale = pow(1.0 + scale / this.treeRef.root_r, this.treeRef.branch_angle_exp);
    this.a += da_scale * angle_rand;

    // Update position
    float dx = cos(this.a) * this.treeRef.stepsize;
    float dy = sin(this.a) * this.treeRef.stepsize;

    this.x += dx;
    this.y += dy;
    this.i += 1;
  }

  // Equivalent of render.branch2
  // Now returns a Runnable containing the drawing commands for its current state
  Runnable getDrawCommand() { 
    // Optimization: Return null if branch is too small 
    if (this.r * SIZE < 0.5) { 
      return null;
    }
    
    // Capture current state for the drawing command
    final float currentX = this.x * SIZE; 
    final float currentY = this.y * SIZE;
    final float currentR = this.r * SIZE; 
    final float currentA = this.a;
    final float pixelSz = max(1, SIZE * ONE); // Use final local variable
    final int grains = GRAINS; // Capture current grains value

    // Calculate derived values needed for drawing
    final float x1 = currentX + cos(currentA - HALF_PI) * currentR;
    final float y1 = currentY + sin(currentA - HALF_PI) * currentR;
    final float x2 = currentX + cos(currentA + HALF_PI) * currentR;
    final float y2 = currentY + sin(currentA + HALF_PI) * currentR;
    
    // Calculate shading points (do this inside the Runnable to capture randomness?)
    // No, capture the points now based on current state.
    final float dd_right = dist(currentX, currentY, x2, y2);
    final float angle_right = currentA + HALF_PI;
    final ArrayList<PVector> rightShadePoints = new ArrayList<PVector>();
    for (int k = 0; k < grains; k++) {
      float scale = random(1.0) * dd_right * random(1.0); 
      float shadeX = x2 - scale * cos(angle_right);
      float shadeY = y2 - scale * sin(angle_right);
      rightShadePoints.add(new PVector(shadeX, shadeY));
    }

    final float dd_left = dist(currentX, currentY, x1, y1);
    final float angle_left = currentA - HALF_PI;
    final ArrayList<PVector> leftShadePoints = new ArrayList<PVector>();
    for (int k = 0; k < grains / 5; k++) {
      float scale = random(1.0) * dd_left * random(1.0);
      float shadeX = x1 - scale * cos(angle_left);
      float shadeY = y1 - scale * sin(angle_left);
      leftShadePoints.add(new PVector(shadeX, shadeY));
    }
    
    // Return the lambda function (Runnable) that performs the drawing
    return () -> {
      // Draw main thick line (trunk)
      stroke(TRUNK);
      strokeWeight(1); 
      for (int k = 0; k < 10; k++) {
         line(x1, y1, x2, y2);
      }

      // Draw outline dots 
      noStroke();
      fill(TRUNK_STROKE);
      rectMode(CENTER);
      rect(x1, y1, pixelSz, pixelSz);  
      rect(x2, y2, pixelSz, pixelSz);

      // Draw shade/texture dots 
      fill(FRONT); 
      noStroke();

      // Draw Right Side Shade points
      for (PVector p : rightShadePoints) {
        rect(p.x, p.y, pixelSz, pixelSz);
      }

      // Draw Left Side Shade points
      for (PVector p : leftShadePoints) {
        rect(p.x, p.y, pixelSz, pixelSz);
      }
    };
  }
}

// --- Tree Class ---
class Tree {
  // Root and simulation parameters (copied from global scope for convenience)
  float root_x, root_y, root_r, root_a;
  float one, stepsize;
  float branch_split_angle, branch_prob_scale, branch_diminish;
  float branch_split_diminish, branch_angle_max, branch_angle_exp;

  ArrayList<Branch> Q; // List of ACTIVE branches for the current step

  Tree(float root_x, float root_y, float root_r, float root_a,
       float one, float stepsize, float branch_split_angle,
       float branch_prob_scale, float branch_diminish,
       float branch_split_diminish, float branch_angle_max,
       float branch_angle_exp)
  {
    this.root_x = root_x;
    this.root_y = root_y;
    this.root_r = root_r;
    this.root_a = root_a;
    this.one = one;
    this.stepsize = stepsize;
    this.branch_split_angle = branch_split_angle;
    this.branch_prob_scale = branch_prob_scale;
    this.branch_diminish = branch_diminish;
    this.branch_split_diminish = branch_split_diminish;
    this.branch_angle_max = branch_angle_max;
    this.branch_angle_exp = branch_angle_exp;

    init();
  }

  void init() {
    Q = new ArrayList<Branch>();
    // Create the initial trunk branch
    Branch rootBranch = new Branch(this, root_x, root_y, root_r, root_a, 0);
    Q.add(rootBranch);
    // IMPORTANT: Add root branch to the master list for drawing - handled in draw() now
    // Clear previous branches before adding root for a new tree
    // allBranches.clear(); 
    // allBranches.add(rootBranch); 
  }
  
  // Method to update tree parameters from GUI
  void updateParameters(float branchProbScale, float branchSplitAngle, float branchDiminish, 
                      float branchSplitDiminish, float branchAngleMax, float branchAngleExp) {
    this.branch_prob_scale = branchProbScale;
    this.branch_split_angle = branchSplitAngle;
    this.branch_diminish = branchDiminish;
    this.branch_split_diminish = branchSplitDiminish;
    this.branch_angle_max = branchAngleMax;
    this.branch_angle_exp = branchAngleExp;
  }

  // Returns list of draw commands for the current state
  ArrayList<Runnable> getDrawCommandsForCurrentStep() {
      ArrayList<Runnable> commands = new ArrayList<Runnable>();
      if (branchDrawCommands.size() >= MAX_DRAW_COMMANDS) {
         if (!finished) println("Max draw commands reached: " + MAX_DRAW_COMMANDS);
         finished = true; // Stop simulation if too many commands
         return commands; // Return empty list
      }
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
      if (!finished) { // Only print finished message once
         println("Tree finished growing. Draw Commands: " + branchDrawCommands.size());
         finished = true; // Mark as finished
         // Do NOT call noLoop() here to keep GUI active
      }
      return;
    }

    ArrayList<Branch> nextQ = new ArrayList<Branch>();
    ArrayList<Branch> newBranches = new ArrayList<Branch>(); // Newly created branches in this step
    // Check branch object limit, not draw commands here
    boolean limitReached = (Q.size() + newBranches.size() >= MAX_BRANCHES); 

    for (Branch b : Q) { // Iterate only through currently active branches
      b.step(); // Update branch state (pos, angle, radius)

      if (b.r <= this.one) {
        // Branch is too thin, discard (it won't be added to nextQ)
        continue;
      }

      // Probability of splitting
      float branch_prob = (this.root_r - b.r + this.one) * this.branch_prob_scale;
      
      // Recalculate limit based on potential new size
      limitReached = (Q.size() + newBranches.size() >= MAX_BRANCHES);

      if (!limitReached && random(1.0) < branch_prob) {
        // Split into a new branch (only if under limit)
        
        // 1. Create the new branch segment
        float new_r = this.branch_split_diminish * b.r;
        // Randomly choose split direction (+/- angle)
        float angle_offset = (random(1.0) < 0.5 ? 1 : -1) * random(1.0) * this.branch_split_angle;
        Branch newB = new Branch(this, b.x, b.y, new_r, b.a + angle_offset, b.g + 1);
        newBranches.add(newB);
        
        // 2. Keep the original branch 'b' growing as well!
        nextQ.add(b); 

        // Check limit again after potentially adding new branch
        if (nextQ.size() + newBranches.size() >= MAX_BRANCHES) {
          limitReached = true; // Set flag to stop further branching in this step
          if (!limitReached) println("Branch limit reached: " + MAX_BRANCHES);
        }
      } else {
        // Did not split (or limit reached), keep the original branch for the next generation
        nextQ.add(b);
      }
    }

    // Update the list of ACTIVE branches for the next step
    Q = nextQ;
    Q.addAll(newBranches);
    
    // DO NOT add to master list here - drawing is handled via commands
    // allBranches.addAll(newBranches); 
  }

  // display() method is removed from Tree class, drawing handled globally
}

// --- Processing Functions ---
void settings() {
  size(SIZE + guiWidth, SIZE);
}

void setup() {
  background(BACK); // Initial background clear
  frameRate(60); // Increased frameRate for smoother GUI interaction

  // Calculate derived constants
  ONE = 1.0 / SIZE;
  INIT_BRANCH = SIZE * 0.03 * ONE;
  GRAINS = (int)(SIZE * 0.02);
  BRANCH_DIMINISH = ONE / 32.0;
  // Adjust probability scale factor for new default range (0-10)
  BRANCH_PROB_SCALE = 1.0 / (INIT_BRANCH) / SIZE * 84.0; // Factor 84 aims for ~5.0
  BRANCH_ANGLE_MAX = 5.0 * PI / SIZE;

  // Create output directory if it doesn't exist
  File outputFolder = new File(sketchPath(outputDir));
  if (!outputFolder.exists()) {
    println("Creating output directory: " + outputDir);
    outputFolder.mkdirs();
  }

  // Initialize Tree
  tree = new Tree(
    MID,              // root_x (0.5)
    0.95,             // root_y (start near bottom)
    INIT_BRANCH,      // root_r
    -HALF_PI,         // root_a (pointing upwards)
    ONE,              // one (minimum size unit)
    ONE,              // stepsize (move one unit per step)
    BRANCH_SPLIT_ANGLE,
    BRANCH_PROB_SCALE,
    BRANCH_DIMINISH,
    BRANCH_SPLIT_DIMINISH,
    BRANCH_ANGLE_MAX,
    BRANCH_ANGLE_EXP
  );
  
  // Add initial draw commands for the root branch
  branchDrawCommands.addAll(tree.getDrawCommandsForCurrentStep());

  // Setup GUI
  setupGUI();

  println("Setup complete. Starting simulation...");
}

void draw() {
  // --- Simulation Step & Capture Draw Commands (only if not finished) ---
  if (!finished) {
    // 1. Capture draw commands for the *current* state before stepping
    ArrayList<Runnable> commandsThisFrame = tree.getDrawCommandsForCurrentStep();
    branchDrawCommands.addAll(commandsThisFrame);
    
    // 2. Advance simulation state for the *next* frame
    tree.step(); 
  }

  // --- Rendering --- 
  // 1. Clear the entire background first
  background(BACK); 

  // 2. Draw the GUI panel background (if visible)
  if (guiVisible) {
    fill(230); // Slightly lighter gray for GUI background
    noStroke();
    rect(0, 0, guiWidth, height);
  }

  // 3. Prepare for drawing the tree: Apply pan offset relative to GUI width
  pushMatrix();
  translate(guiWidth + offsetX, offsetY); 
  
  // 4. Draw ALL accumulated branch commands
  for (Runnable command : branchDrawCommands) {
     command.run();   
  }
  popMatrix(); // Restore matrix before drawing GUI controls

  // 5. Draw GUI Controls ON TOP
  // Always draw GUI controls, regardless of simulation state
  cp5.draw(); 

  // --- Save Frame --- (Optional)
  // if (!finished) { // Only save frames during growth?
  //   saveFrame(outputDir + "/frame-#####.png"); 
  // }
  frameCounter++;

  // Optional: Print status less frequently or remove
  if (frameCounter % 100 == 0) {
    println("Frame:", frameCounter, " Active Branches:", tree.Q.size(), " Draw Commands:", branchDrawCommands.size());
  }
} 

// --- Mouse Handlers for Panning ---
void mousePressed() {
  // Start panning only if mouse is outside the GUI panel
  if (mouseX > guiWidth) {
    isPanning = true;
    panStartX = mouseX;
    panStartY = mouseY;
    startOffsetX = offsetX; // Store the offset at the beginning of the drag
    startOffsetY = offsetY;
  }
}

void mouseDragged() {
  if (isPanning) {
    // Calculate the difference in mouse position
    float dx = mouseX - panStartX;
    float dy = mouseY - panStartY;
    
    // Update the offset based on the initial offset and the drag distance
    offsetX = startOffsetX + dx;
    offsetY = startOffsetY + dy;
  }
}

void mouseReleased() {
  if (isPanning) {
    isPanning = false;
  }
}


// --- GUI Setup ---
void setupGUI() {
  cp5 = new ControlP5(this);
  int labelColor = color(0); // Black color for labels
  int yPos = 10; // Initial Y position for controls
  int spacing = 40; // Vertical spacing between controls
  int sliderHeight = 20;
  int groupPadding = 10;
  int controlWidth = guiWidth - 2 * groupPadding - 20; // Adjusted width for controls within group
  // int toggleSize = 20; // Size for the toggle checkbox - Removed
  int radioSize = 20; // Size for radio buttons

  // Create a group for controls
  Group g1 = cp5.addGroup("Tree Parameters")
    .setPosition(groupPadding, yPos)
    .setWidth(guiWidth - 2 * groupPadding)
    .setBackgroundHeight(410) // Adjusted height 
    .setBackgroundColor(color(200)) // Darker gray background for contrast
    .setLabel("TREE PARAMETERS"); 
  g1.getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE).setPaddingY(5);

  yPos += 30; // Space for group title
    
  // --- Branch Probability Scale Slider ---
  cp5.addSlider("branchProbScale")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, sliderHeight)
    .setRange(0.0, 10.0) // Default range
    .setValue(BRANCH_PROB_SCALE)
    .setLabel("Branch Probability Scale") // More descriptive label
    .setGroup(g1)
    .setDecimalPrecision(3) // Set precision to 3 decimal places
    .getCaptionLabel().setColor(labelColor).align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2);
    
  yPos += spacing + 5; // Move down for the radio buttons
  
  // --- Probability Scale Range Radio Buttons ---
  probScaleRange = cp5.addRadioButton("probScaleRange")
                      .setPosition(groupPadding, yPos)
                      .setSize(radioSize, radioSize)
                      .setItemsPerRow(3)
                      .setSpacingColumn(controlWidth / 3)
                      .setGroup(g1);
                      
  // Configure the label separately to avoid type mismatch
  probScaleRange.setLabel("Scale Range"); // Set the label text
  probScaleRange.getCaptionLabel()        // Get the caption label object
              .setColor(labelColor)     // Set its color
              .align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE) // Set its alignment
              .setPaddingY(-5);         // Set its padding

  probScaleRange.addItem("0-1", 0);   // Index 0
  probScaleRange.addItem("0-10", 1);  // Index 1
  probScaleRange.addItem("0-100", 2); // Index 2
  probScaleRange.activate(1); // Activate "0-10" by default
  
  // Set labels for individual radio buttons (optional, but good practice)
  // Note: Positioning individual labels precisely relative to buttons can be tricky.
  // Consider using the group label or tooltips if needed.

  yPos += spacing; // Adjust spacing after radio buttons
  
  // --- Other Sliders ---
  cp5.addSlider("branchSplitAngle")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, sliderHeight)
    .setRange(0.0, 0.5) // New Range: 0.0 to 0.5
    .setValue(BRANCH_SPLIT_ANGLE)
    .setLabel("Split Angle")
    .setGroup(g1)
    .setDecimalPrecision(3) // Display 3 decimal places
    .getCaptionLabel().setColor(labelColor).align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2);
    
  yPos += spacing;
  cp5.addSlider("branchDiminish")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, sliderHeight)
    .setRange(ONE/40, ONE/5) // Adjusted range slightly (max was ONE*2, maybe too high)
    .setValue(BRANCH_DIMINISH)
    .setLabel("Branch Thinning Rate")
    .setGroup(g1)
    .getCaptionLabel().setColor(labelColor).align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2);
    
  yPos += spacing;
  cp5.addSlider("branchSplitDiminish")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, sliderHeight)
    .setRange(0.1, 1.0)
    .setValue(BRANCH_SPLIT_DIMINISH)
    .setLabel("New Branch Thickness Factor") // Clarified label
    .setGroup(g1)
    .getCaptionLabel().setColor(labelColor).align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2);
    
  yPos += spacing;
  cp5.addSlider("branchAngleMax")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, sliderHeight)
    .setRange(0, PI/50) // Adjusted range slightly for more noticeable effect
    .setValue(BRANCH_ANGLE_MAX)
    .setLabel("Max Angle Variation")
    .setGroup(g1)
    .getCaptionLabel().setColor(labelColor).align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2);
    
  yPos += spacing;
  cp5.addSlider("branchAngleExp")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, sliderHeight)
    .setRange(0.5, 5)
    .setValue(BRANCH_ANGLE_EXP)
    .setLabel("Curve Intensity")
    .setGroup(g1)
    .getCaptionLabel().setColor(labelColor).align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2);
    
  yPos += spacing;
  cp5.addSlider("grains")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, sliderHeight)
    .setRange(1, SIZE/10)
    .setValue(GRAINS)
    .setLabel("Shading Detail (Grains)") // Clarified label
    .setGroup(g1)
    .getCaptionLabel().setColor(labelColor).align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(2);
    
  yPos += spacing + 10; // Add extra space before button
  // Add a button to restart the simulation
  cp5.addButton("restartTree")
    .setPosition(groupPadding, yPos)
    .setSize(controlWidth, 30)
    .setLabel("Restart Tree (R)") // Added (R) shortcut hint
    .setGroup(g1);
}

// --- GUI Event Handlers ---
void controlEvent(ControlEvent event) {
  if (event.isController()) {
    String name = event.getName();

    // Handle Probability Scale Range Radio Buttons
    if (event.isFrom(probScaleRange)) {
       int rangeIndex = (int)probScaleRange.getValue();
       Slider probSlider = (Slider)cp5.getController("branchProbScale");
       float currentValue = probSlider.getValue();
       float newMax = 10.0;
       
       switch (rangeIndex) {
         case 0: // 0-1
           newMax = 1.0;
           probSlider.setRange(0.0, newMax);
           break;
         case 1: // 0-10
           newMax = 10.0;
           probSlider.setRange(0.0, newMax);
           break;
         case 2: // 0-100
           newMax = 100.0;
           probSlider.setRange(0.0, newMax);
           break;
       }
       
       // Clamp current value to the new range
       if (currentValue > newMax) {
         probSlider.setValue(newMax);
         currentValue = newMax; // Use clamped value for immediate update
       }
       
       // Update the tree immediately with the new (potentially clamped) value
       tree.updateParameters(
           currentValue, 
           cp5.getController("branchSplitAngle").getValue(),
           cp5.getController("branchDiminish").getValue(),
           cp5.getController("branchSplitDiminish").getValue(),
           cp5.getController("branchAngleMax").getValue(),
           cp5.getController("branchAngleExp").getValue()
       );
       
    } else if (name.equals("restartTree")) {
       // Handle Restart Button
       restartTree();
       
    } else if (!name.equals("probScaleRange")) { // Handle Sliders (ignore radio button group itself)
       // Update tree parameters with current GUI values
       tree.updateParameters(
         cp5.getController("branchProbScale").getValue(),
         cp5.getController("branchSplitAngle").getValue(),
         cp5.getController("branchDiminish").getValue(),
         cp5.getController("branchSplitDiminish").getValue(),
         cp5.getController("branchAngleMax").getValue(),
         cp5.getController("branchAngleExp").getValue()
       );
       // Update global GRAINS value (affecting subsequent drawing)
       GRAINS = (int)cp5.getController("grains").getValue();
    }
  }
}

// --- Key Press Handler (for SVG export and Restart shortcut) ---
void keyPressed() {
  if (key == 's' || key == 'S') {
    // SVG Export
    String timestamp = year() + nf(month(),2) + nf(day(),2) + "_" + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
    String filename = outputDir + "/tree_" + timestamp + ".svg";
    println("Saving SVG to: " + filename);
    
    beginRecord(SVG, filename);
    // Redraw the scene completely for SVG capture
    // 1. Clear background for SVG
    background(BACK); // Use global background color
    // 2. Apply pan transform
    pushMatrix();
    translate(offsetX, offsetY); // Apply pan (No GUI offset needed for SVG)
    // 3. Execute all stored drawing commands
    for (Runnable command : branchDrawCommands) {
      command.run(); 
    }
    popMatrix();
    endRecord();
    println("SVG export complete.");
    
  } else if (key == 'r' || key == 'R') {
     // Restart Shortcut
     restartTree();
  }
}

void restartTree() {
  println("Restarting tree...");
  
  // Explicitly clear background immediately for visual feedback - Removed as draw() handles it
  // background(BACK); // Clear whole window <- REMOVE
  // fill(230);        // Redraw GUI panel background immediately <- REMOVE
  // noStroke();
  // rect(0, 0, guiWidth, height); // <- REMOVE
  // Note: GUI controls themselves are drawn by cp5.draw() in the main draw loop

  // Reset state variables
  frameCounter = 0;
  finished = false;
  isPanning = false; // Ensure panning stops on restart
  offsetX = 0; // Reset pan
  offsetY = 0;
  branchDrawCommands.clear(); // Clear the stored drawing commands
  
  // Re-calculate derived constants that might depend on SIZE (though SIZE is fixed here)
  ONE = 1.0 / SIZE;
  INIT_BRANCH = SIZE * 0.03 * ONE;
  // Note: We keep the GRAINS value from the slider, don't reset it here.
  BRANCH_DIMINISH = cp5.getController("branchDiminish").getValue(); // Use current slider value
  BRANCH_ANGLE_MAX = cp5.getController("branchAngleMax").getValue(); // Use current slider value
  // BRANCH_PROB_SCALE will be taken from slider value in new Tree()
  
  // Create new tree with current GUI parameters
  tree = new Tree(
    MID,              // root_x (0.5)
    0.95,             // root_y (start near bottom)
    INIT_BRANCH,      // root_r
    -HALF_PI,         // root_a (pointing upwards)
    ONE,              // one (minimum size unit)
    ONE,              // stepsize (move one unit per step)
    cp5.getController("branchSplitAngle").getValue(),
    cp5.getController("branchProbScale").getValue(),
    cp5.getController("branchDiminish").getValue(),
    cp5.getController("branchSplitDiminish").getValue(),
    cp5.getController("branchAngleMax").getValue(),
    cp5.getController("branchAngleExp").getValue()
  );
  
  // Add initial draw commands for the new tree's root branch
  branchDrawCommands.addAll(tree.getDrawCommandsForCurrentStep());
  
  // Restart drawing loop (Processing automatically handles loop() status)
  // loop(); // Explicit loop() call usually not needed if draw() is running
} 