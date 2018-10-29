<<<<<<< HEAD
import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0;
int trialCount = 8; //this will be set higher for the bakeoff
float border = 0; //have some padding from the sides
//float button_padding = 0; //padding for done button
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float screenTransX = 0;
float screenTransY = 0;
float screenRotation = 0;
float screenZ = 50f;

// things to keep track of for transformations
float cursor_centerX = 0;
float cursor_centerY = 0;
float onClickMouseX = 0;
float onClickMouseY = 0;
float onClickTransX = 0;
float onClickTransY = 0;
float onClickCursorScale = screenZ;
float onClickCursorRotation = screenRotation;

float onClickTargetScale = 0;
float onClickTargetX = 0;
float onClickTargetY = 0;

private class Target
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

private class CursorDot
{
  float x = 0;
  float y = 0;
  float radius = 0;
  
  CursorDot(float x, float y, float rad) {
    this.x = x;
    this.y = y;
    this.radius = rad;
  }
}

ArrayList<Target> targets = new ArrayList<Target>();

ArrayList<CursorDot> cursorDots = new ArrayList<CursorDot>();

// Operations
final int NO_OP = -1;
final int CURSOR_SCALE = 0;
final int CURSOR_TRANSLATE = 1;
final int CURSOR_ROTATE = 2;
//final int TARGET_SCALE = 3;
final int TARGET_TRANSLATE = 4;
//final int TARGET_ROTATE = 5;
int currentOp = NO_OP;

float inchesToPixels(float inch)
{
  return inch*screenPPI;
}

void setup() {
  size(800,800); 

  rectMode(CENTER);
  textFont(createFont("Arial", inchesToPixels(.2f))); //sets the font to Arial that is .3" tall
  textAlign(CENTER);

  //don't change this! 
  border = inchesToPixels(.2f); //padding of 0.2 inches

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Target t = new Target();
    t.x = random(-width/2+border, width/2-border); //set a random x with some padding
    t.y = random(-height/2+border, height/2-border); //set a random y with some padding
    t.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    t.z = ((j%20)+1)*inchesToPixels(.15f); //increasing size from .15 up to 3.0" 
    targets.add(t);
    println("created target with " + t.x + "," + t.y + "," + t.rotation + "," + t.z);
  }
  Collections.shuffle(targets); // randomize the order of the button; don't change this.
}



void draw() {

  background(60); //background is dark grey
  fill(200);
  noStroke();

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchesToPixels(.2f));
    text("User had " + errorCount + " error(s)", width/2, inchesToPixels(.2f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per target", width/2, inchesToPixels(.2f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per target inc. penalty", width/2, inchesToPixels(.2f)*4);
    return;
  }

  //===========DRAW TARGET SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  Target t = targets.get(trialIndex);
  translate(t.x, t.y); //center the drawing coordinates to the center of the screen
  rotate(radians(t.rotation));
  fill(255, 0, 0); //set color to semi translucent
  rect(0, 0, t.z, t.z);
  // target lines
  drawTargetLines(t);
  // translucent circle on the center
  drawTargetCenter(t);
  popMatrix();

  //===========DRAW CURSOR SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY);
  rotate(radians(screenRotation));
  noFill();
  strokeWeight(3f);
  boolean closeZ = abs(t.z - screenZ)<inchesToPixels(.05f);
  // change the color if scale close enough
  if (closeZ) stroke(0,255,237);
  else stroke(180);
  rect(0,0, screenZ, screenZ);
  drawCursorDots();
  // translucent circle on the center
  drawCursorLines();
  drawCursorCenter();
  popMatrix();
  
    //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  //scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchesToPixels(.5f));
  
  //===========DRAW DONE BUTTON=================
  //button_padding = inchesToPixels(1.5f);
  //rectMode(CENTER);
  //rect(width/2, button_padding, 100, 50);
  //fill(0);
  //textAlign(CENTER, CENTER);
  //text("DONE", width/2, button_padding, 100, 50);
}


void controlLogic() {
  Target t = targets.get(trialIndex);
  
  switch (currentOp) {
    case CURSOR_TRANSLATE:
      float dx = mouseX - onClickMouseX; 
      float dy = mouseY - onClickMouseY; 
      screenTransX = onClickTransX + dx;
      screenTransY = onClickTransY + dy;
      break;
      
    case CURSOR_SCALE:
      float init_dist_to_cursor = dist(cursor_centerX, cursor_centerY, onClickMouseX, onClickMouseY);
      float curr_dist_to_cursor = dist(cursor_centerX, cursor_centerY, mouseX, mouseY);
      float scaleAmt = curr_dist_to_cursor - init_dist_to_cursor;
      screenZ = onClickCursorScale + scaleAmt;
      t.z = onClickTargetScale - scaleAmt/2; // hmm
      break;
      
    case CURSOR_ROTATE:
      PVector init_vect = new PVector(onClickMouseX - cursor_centerX, onClickMouseY - cursor_centerY); // vector from cursor center to initial mouse position
      PVector curr_vect = new PVector(mouseX - cursor_centerX, mouseY - cursor_centerY); // vector from cursor center to current mouse position
      
      float angle = PVector.angleBetween(init_vect, curr_vect);
      
      // oh my god.... math..... i hate it
      PVector crossProd = curr_vect.cross(init_vect);
      
      if (crossProd.z < 0) screenRotation = onClickCursorRotation + degrees(angle);
      else screenRotation = onClickCursorRotation - degrees(angle);
      break;
     
     case TARGET_TRANSLATE:
       dx = mouseX - onClickMouseX;
       dy = mouseY - onClickMouseY;
       t.x = onClickTargetX + dx;
       t.y = onClickTargetY + dy;
       break;
    
    default:
      break;
  }
}

void drawCursorDots()
{
   cursorDots.clear();
   float newX = 0, newY = 0;
   float diam = max(18, screenZ*0.1); // default size, sometimes it's too small otherwise
   fill(240);
   // top-left
   ellipse(-screenZ/2, -screenZ/2, diam, diam);
   newX = screenX(-screenZ/2, -screenZ/2);
   newY = screenY(-screenZ/2, -screenZ/2);
   cursorDots.add(new CursorDot(newX, newY, diam/2));

   // top-right
   ellipse(screenZ/2, -screenZ/2, diam, diam);
   newX = screenX(screenZ/2, -screenZ/2);
   newY = screenY(screenZ/2, -screenZ/2);
   cursorDots.add(new CursorDot(newX, newY, diam/2));
   
   // bottom-left
   ellipse(-screenZ/2, screenZ/2, diam, diam);
   newX = screenX(-screenZ/2, screenZ/2);
   newY = screenY(-screenZ/2, screenZ/2);
   cursorDots.add(new CursorDot(newX, newY, diam/2));

   // bottom-right
   ellipse(screenZ/2, screenZ/2, diam, diam);
   newX = screenX(screenZ/2, screenZ/2);
   newY = screenY(screenZ/2, screenZ/2);
   cursorDots.add(new CursorDot(newX, newY, diam/2));
}

void drawCursorLines()
{
  Target t = targets.get(trialIndex);  
  boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation,screenRotation)<=5;
  strokeWeight(2f);
  if (closeRotation) stroke(0,255,237);
  else stroke(255,255,255,100);
  float offset = min(30, screenZ*0.3);
  float coord = screenZ/2 + offset;
  line(0, -coord, 0, coord);
  line(-coord, 0, coord, 0);
}

void drawCursorCenter()
{
  Target t = targets.get(trialIndex);
  boolean closeDist = dist(t.x,t.y,screenTransX,screenTransY)<inchesToPixels(.05f);
  if (closeDist) {
    fill(0,255,237);
    noStroke();
    ellipse(0, 0, 15, 15);
  }
  else {
    fill(255,255,255,100);
    strokeWeight(1);
    stroke(255);
    ellipse(0, 0, 15, 15);
  }
}

void drawTargetLines(Target t)
{
  boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation,screenRotation)<=5;
  strokeWeight(2f);
  if (closeRotation) stroke(0,255,237);
  else stroke(255,255,255,100);
  float offset = min(40, t.z*0.4);
  float coord = t.z/2 + offset;
  line(0, -coord, 0, coord);
  line(-coord, 0, coord, 0);
}

void drawTargetCenter(Target t)
{
  boolean closeDist = dist(t.x,t.y,screenTransX,screenTransY)<inchesToPixels(.05f);
  if (closeDist) {
    fill(0,255,237);
    noStroke();
    ellipse(0, 0, 15, 15);
  }
  else {
    fill(0,0,0,100);
    strokeWeight(1);
    stroke(0);
    ellipse(0, 0, 15, 15);
  }
}

boolean isMouseInsideCursorDot() 
{
  //println(x + " " + y + " " + mouseX + " " + mouseY + " " + w/2);
  for (CursorDot dot : cursorDots) {
    float distToCenter = dist(mouseX, mouseY, dot.x, dot.y);
    if (distToCenter <= dot.radius) {
      return true;
    }
  }
  return false;
}

// hmm this does not quite work with rotations haha....someone pls help
boolean isMouseInsideSquare(float x, float y, float z, float rotation)
{
  float centerX = x+width/2;
  float centerY = y+height/2;
  float w = z;
  boolean result = false;
  
  pushMatrix();
  translate(centerX, centerY);
  rotate(radians(rotation));
  
  result = (mouseX > (centerX - w/2)) && (mouseX < (centerX + w/2)) && 
           (mouseX > (centerY - w/2)) && (mouseY < (centerY + w/2));
  
  popMatrix();
  
  // sanity check since sometimes it bugs out lololol (cry)
  if (!result)
    result = dist(centerX, centerY, mouseX, mouseY) <= w/2;
  
  return result;
}

void mousePressed()
{
    if (startTime == 0) //start time on the instant of the first user click
    {
      startTime = millis();
      println("time started!");
    }
    
    cursor_centerX = screenTransX+width/2;
    cursor_centerY = screenTransY+height/2;
    //println("cursor center x = " + cursor_centerX + ", center y = " + cursor_centerY);
    onClickMouseX = mouseX;
    onClickMouseY = mouseY;
    //println("mouse x = " + onClickMouseX + ", mouse y = " + onClickMouseY);
    onClickTransX = screenTransX;
    onClickTransY = screenTransY;
    onClickCursorScale = screenZ;
    onClickCursorRotation = screenRotation;
    
    Target t = targets.get(trialIndex);
    onClickTargetX = t.x;
    onClickTargetY = t.y;
    onClickTargetScale = t.z;
    
    // uhh reset this just in case
    currentOp = NO_OP;
    if (isMouseInsideCursorDot())
      currentOp = CURSOR_SCALE;
    else if (isMouseInsideSquare(screenTransX, screenTransY, screenZ, screenRotation))
      currentOp = CURSOR_TRANSLATE;
    else if (isMouseInsideSquare(t.x, t.y, t.z, t.rotation))
      currentOp = TARGET_TRANSLATE;
    else
      currentOp = CURSOR_ROTATE;
}

void mouseDragged() {
  controlLogic();
}

void mouseReleased()
{ 
  currentOp = NO_OP;
  
  //check to see if user clicked done button
  //if ((width/2 + 50 >= mouseX) && (mouseX >= width/2 - 50) 
  //&& (button_padding - 25 <= mouseY) && (mouseY <= button_padding + 25))
  //{
  //  completeRound();
  //}
    
}

void completeRound() {
  if (userDone==false && !checkForSuccess())
      errorCount++;

    //and move on to next trial
    trialIndex++;
    
    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
}

// processing has no double click function, so wrote a custom one here
int lastClick;
void mouseClicked() {
  if ((millis()-lastClick) > 500) {
    lastClick = millis();
  } else { //((millis()-lastClick) <= 500){
    doubleClicked();
    lastClick=millis();
  } 
}

void doubleClicked(){
  completeRound();
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
	Target t = targets.get(trialIndex);	
	boolean closeDist = dist(t.x,t.y,screenTransX,screenTransY)<inchesToPixels(.05f); //has to be within .1"
  boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation,screenRotation)<=5;
	boolean closeZ = abs(t.z - screenZ)<inchesToPixels(.05f); //has to be within .1"	
	
  println("Close Enough Distance: " + closeDist + " (cursor X/Y = " + t.x + "/" + t.y + ", target X/Y = " + screenTransX + "/" + screenTransY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(t.rotation,screenRotation)+")");
 	println("Close Enough Z: " +  closeZ + " (cursor Z = " + t.z + ", target Z = " + screenZ +")");
	
	return closeDist && closeRotation && closeZ;	
}

//utility function I include
double calculateDifferenceBetweenAngles(float a1, float a2)
  {
     double diff=abs(a1-a2);
      diff%=90;
      if (diff>45)
        return 90-diff;
      else
        return diff;
 }
