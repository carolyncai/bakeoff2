import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0;
int trialCount = 8; //this will be set higher for the bakeoff
float border = 0; //have some padding from the sides
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

private class Target
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

private class Tuple
{
  float x = 0;
  float y = 0;
  
  Tuple(float x, float y) {
    this.x = x;
    this.y = y;
  }
}

ArrayList<Target> targets = new ArrayList<Target>();
ArrayList<Tuple> targetTuples = new ArrayList<Tuple>();
ArrayList<Tuple> cursorTuples = new ArrayList<Tuple>();
boolean cursorScaling = false, targetScaling = false;

// Operations
final int CURSOR_SCALE = 0;
final int CURSOR_TRANSLATE = 1;
final int CURSOR_ROTATE = 2;
final int TARGET_SCALE = 3;
final int TARGET_TRANSLATE = 4;
final int TARGET_ROTATE = 5;

int current = -1;
float prevX = mouseX, prevY = mouseY;

float inchesToPixels(float inch)
{
  return inch*screenPPI;
}

void setup() {
  size(800,800); 

  rectMode(CENTER);
  ellipseMode(CENTER);
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
  strokeWeight(3f);
  stroke(128,0,0);
  fill(255, 255, 255);
  drawTargetDots(t);
  popMatrix();

  //===========DRAW CURSOR SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY);
  rotate(radians(screenRotation));
  noFill();
  strokeWeight(3f);
  stroke(160);
  rect(0,0, screenZ, screenZ);
  fill(200);
  drawCursorDots();
  popMatrix();
  
    //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  //scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchesToPixels(.5f));
}

/*
  Logic:
  If mouse is pressed:
    If (there's no current operation or current operation is cursor scale) and (mouse is within one of the corners or scaling is already happening)
      Determine whether to scale in or out and do that operation
    Else If (similar check but for target)
      Similar operation as cursor scale
    Else if (there's no current operation or current operation is cursor translate) and (mouse is inside cursor square)
      Translate the square with the mouse
    Else if (similar check but for target)
      Similar operation as target translate
    Else
      The mouse is outside the box and we will rotate
        Determine if any rotate is already happening. If not, choose the closest square
          Rotate
*/
void controlLogic1()
{
  Target t = targets.get(trialIndex);
  
  if (mousePressed) {
    if ((current == CURSOR_SCALE || current == -1) && (checkScale(screenTransX, screenTransY, screenRotation, screenZ, cursorTuples) || cursorScaling)) {
      cursorScaling = true;
      targetScaling = false;
      current = CURSOR_SCALE;
      
      if (dist(pmouseX, pmouseY, width/2+screenTransX, height/2+screenTransY) - dist(mouseX, mouseY, width/2+screenTransX, height/2+screenTransY) > 0) {
        println("scale in");
        screenZ -= inchesToPixels(0.02f);
      } else if (dist(pmouseX, pmouseY, width/2+screenTransX, height/2+screenTransY) - dist(mouseX, mouseY, width/2+screenTransX, height/2+screenTransY) < 0) {
        println("scale out");
        screenZ += inchesToPixels(0.02f);
      } else {
        //println("scale nothing");
        cursorScaling = false;
        targetScaling = false;
      }
    } else if ((current == TARGET_SCALE || current == -1) && (checkScale(t.x, t.y, t.rotation, t.z, targetTuples) || targetScaling)) {
      targetScaling = true;
      cursorScaling = false;
      current = TARGET_SCALE;
      
      if (dist(pmouseX, pmouseY, width/2+t.x, height/2+t.y) - dist(mouseX, mouseY, width/2+t.x, height/2+t.y) > 0) {
        //println("scale in");
        t.z -= inchesToPixels(0.02f);
      } else if (dist(pmouseX, pmouseY, width/2+t.x, height/2+t.y) - dist(mouseX, mouseY, width/2+t.x, height/2+t.y) < 0) {
        //println("scale out");
        t.z += inchesToPixels(0.02f);
      } else {
        //println("scale nothing");
        targetScaling = false;
        cursorScaling = false;
      }
    } else if ((current == CURSOR_TRANSLATE || current == -1) && (isInside(screenTransX+width/2, screenTransY+height/2, screenZ))) {
      cursorScaling = false;
      targetScaling = false;
      current = CURSOR_TRANSLATE;
      
      screenTransX = mouseX-width/2;
      screenTransY = mouseY-height/2;
    } else if ((current == TARGET_TRANSLATE || current == -1) && (isInside(t.x+width/2, t.y+height/2, t.z))) {
      cursorScaling = false;
      targetScaling = false;
      current = TARGET_TRANSLATE;
      
      t.x = mouseX-width/2;
      t.y = mouseY-height/2;
    } else {
      cursorScaling = false;
      targetScaling = false;
      
      if ((current == CURSOR_ROTATE || current == -1) && (dist(mouseX, mouseY, screenTransX+width/2, screenTransY+height/2) < dist(mouseX, mouseY, t.x+width/2, t.y+height/2))) {
        current = CURSOR_ROTATE;
        
        if (((mouseX-width/2-screenTransX < 0) && pmouseY-mouseY < 0) || ((mouseX-width/2-screenTransX > 0) && pmouseY-mouseY > 0)) {
          // anti-clockwise
          screenRotation--;
        } else {
          // clockwise
          screenRotation++;
        }
      } else {
        current = TARGET_ROTATE;
        
        if (((mouseX-width/2-t.x < 0) && pmouseY-mouseY < 0) || ((mouseX-width/2-t.x > 0) && pmouseY-mouseY > 0)) {
          // anti-clockwise
          t.rotation--;
        } else {
          // clockwise
          t.rotation++;
        }
      }
    }
  }
}

boolean isInside(float x, float y, float w) 
{
  //println(x + " " + y + " " + mouseX + " " + mouseY + " " + w/2);
  return dist(x, y, mouseX, mouseY) <= w/2;
}

boolean checkScale(float x, float y, float rotation, float z, ArrayList<Tuple> tuples)
{
  boolean check = false;
  for (Tuple tuple : tuples) {
    //println(tuple.x + " " + tuple.y + " " + mouseX + " " + mouseY);
    check = check || dist(tuple.x, tuple.y, mouseX, mouseY) <= inchesToPixels(0.05f);
  }
  return check;
}

void drawCursorDots()
{
   cursorTuples.clear();
   float newX = 0, newY = 0;
   float scale = screenZ*0.1;
   // top-left
   ellipse(-screenZ/2, -screenZ/2, scale, scale);
   newX = screenX(-screenZ/2, -screenZ/2);
   newY = screenY(-screenZ/2, -screenZ/2);
   cursorTuples.add(new Tuple(newX, newY));
   // top-mid
   //ellipse(0, -screenZ/2, scale, scale);
   // top-right
   ellipse(screenZ/2, -screenZ/2, scale, scale);
   newX = screenX(screenZ/2, -screenZ/2);
   newY = screenY(screenZ/2, -screenZ/2);
   cursorTuples.add(new Tuple(newX, newY));
   // bottom-left
   ellipse(-screenZ/2, screenZ/2, scale, scale);
   newX = screenX(-screenZ/2, screenZ/2);
   newY = screenY(-screenZ/2, screenZ/2);
   cursorTuples.add(new Tuple(newX, newY));
   // bottom-mid
   //ellipse(0, screenZ/2, scale, scale);
   // bottom-right
   ellipse(screenZ/2, screenZ/2, scale, scale);
   newX = screenX(screenZ/2, screenZ/2);
   newY = screenY(screenZ/2, screenZ/2);
   cursorTuples.add(new Tuple(newX, newY));
   
   //ellipse(-screenZ/2, 0, scale, scale);
   //ellipse(screenZ/2, 0, scale, scale);
}

void drawTargetDots(Target t)
{
   float scale = t.z*0.08;
   float newX = 0, newY = 0;
   // top-left
   ellipse(-t.z/2, -t.z/2, scale, scale);
   newX = screenX(-t.z/2, -t.z/2);
   newY = screenY(-t.z/2, -t.z/2);
   targetTuples.add(new Tuple(newX, newY));
   // top-mid
   //ellipse(0, -t.z/2, scale, scale);
   // top-right
   ellipse(t.z/2, -t.z/2, scale, scale);
   newX = screenX(t.z/2, -t.z/2);
   newY = screenY(t.z/2, -t.z/2);
   targetTuples.add(new Tuple(newX, newY));
   // bottom-left
   ellipse(-t.z/2, t.z/2, scale, scale);
   newX = screenX(-t.z/2, t.z/2);
   newY = screenY(-t.z/2, t.z/2);
   targetTuples.add(new Tuple(newX, newY));
   // bottom-mid
   //ellipse(0, t.z/2, scale, scale);
   // bottom-right
   ellipse(t.z/2, t.z/2, scale, scale);
   newX = screenX(t.z/2, t.z/2);
   newY = screenY(t.z/2, t.z/2);
   targetTuples.add(new Tuple(newX, newY));
   
   //ellipse(-t.z/2, 0, scale, scale);
   //ellipse(t.z/2, 0, scale, scale);
}

//my example design for control, which is terrible
void scaffoldControlLogic()
{
  //upper left corner, rotate counterclockwise
  text("CCW", inchesToPixels(.2f), inchesToPixels(.2f));
  if (mousePressed && dist(0, 0, mouseX, mouseY)<inchesToPixels(.5f))
    screenRotation--;

  //upper right corner, rotate clockwise
  text("CW", width-inchesToPixels(.2f), inchesToPixels(.2f));
  if (mousePressed && dist(width, 0, mouseX, mouseY)<inchesToPixels(.5f))
    screenRotation++;

  //lower left corner, decrease Z
  text("-", inchesToPixels(.2f), height-inchesToPixels(.2f));
  if (mousePressed && dist(0, height, mouseX, mouseY)<inchesToPixels(.5f))
    screenZ-=inchesToPixels(.02f);

  //lower right corner, increase Z
  text("+", width-inchesToPixels(.2f), height-inchesToPixels(.2f));
  if (mousePressed && dist(width, height, mouseX, mouseY)<inchesToPixels(.5f))
    screenZ+=inchesToPixels(.02f);

  //left middle, move left
  text("left", inchesToPixels(.2f), height/2);
  if (mousePressed && dist(0, height/2, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransX-=inchesToPixels(.02f);

  text("right", width-inchesToPixels(.2f), height/2);
  if (mousePressed && dist(width, height/2, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransX+=inchesToPixels(.02f);
  
  text("up", width/2, inchesToPixels(.2f));
  if (mousePressed && dist(width/2, 0, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransY-=inchesToPixels(.02f);
  
  text("down", width/2, height-inchesToPixels(.2f));
  if (mousePressed && dist(width/2, height, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransY+=inchesToPixels(.02f);
}


void mousePressed()
{
    if (startTime == 0) //start time on the instant of the first user click
    {
      startTime = millis();
      println("time started!");
    }
}

void mouseDragged()
{
  controlLogic1();
}


void mouseReleased()
{
  //check to see if user clicked middle of screen within 3 inches
  if (dist(width/2, height/2, mouseX, mouseY)<inchesToPixels(3f))
  {
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
  
  current = -1;
  cursorScaling = false;
  targetScaling = false;
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
