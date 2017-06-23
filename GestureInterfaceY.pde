import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
import com.sun.jna.NativeLibrary;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Collections;
import java.util.Comparator;
import org.openkinect.processing.*;
import processing.core.PApplet;
import processing.core.PVector;
import java.io.PrintStream;
import java.io.FileOutputStream;
import java.awt.event.KeyEvent;
import java.awt.event.*;
import java.awt.Robot;
import java.awt.MouseInfo;
import java.awt.PointerInfo;
import java.awt.Point;
import processing.opengl.PSurfaceJOGL;
import com.jogamp.newt.opengl.GLWindow;
import javax.swing.JPanel;
import javax.swing.JFrame;

/** used to switch interface and handling code from the Kinect v1 to the Kinect v2. */
final int KINECT_VERSION = 2;

/** how far, in metres, a point must be from the background to be considered a moving object. */
final float MOVE_THRESHOLD = 0.05f;
/** how far, in metres, a point must be to the screen to be considered "close". */
final float CLOSE_THRESHOLD = 0.15f;
final float COLOUR_THRESHOLD = 0.2f;
/** what fraction (1/n) of moving points, sorting from distance to the plane, should be used to determine
 the hand position. */
final int HAND_POINT_FRAC = 30;
/** the minimum number of moving points that can be used to determine the hand position. */
final int MIN_SENSE_POINTS = 30;
/** how long, in frames, should the calibration period last when called. */
final int CALIBRATION_LENGTH = 30;
/** how long, in frames, should we wait before clicking? */
final float CLICK_TIMER_LIMIT = 1;
/** how close, in metres, must a hand be to trip the click limit? */
final float CLICK_DISTANCE = 0.05;
/** the mapping factor from real-world metres to Processing units. */
final float DRAW_SCALE = 300.0;
/** the radius, relative to the screen width/height, of the mouse stabiliser. */
final float STABLISER_RADIUS = 0.1;

/** the actual width of the screen to look for, in metres. */
final float TARGET_SCREEN_WIDTH = 1.06;
/** the actual height of the screen to look for, in metres. */
final float TARGET_SCREEN_HEIGHT = 0.84;

/** whether to use the 3D visualisation, or the 2D interface. */
boolean threeD = false;

/** Determines the method used for rendering points.
 0 = colour by role;
 1 = real colour (from colour camera);
 2 = colour calibration results;
 3 = depth calibration results.
 */
int drawMode = 0;
boolean showAll = false;

/** Interface object for Kinect v1 */
Kinect kinect;
/** Interface object for Kinect v2 */
Kinect2 kinect2;

/** a lookup table, translating Kinect(2) depth values to real-world metres. */
float[] depthLookUp = new float[(KINECT_VERSION == 2 ? 4501 : 2048)];
float a = 0.0f;
/** The four points in real-world space that are the corners of the frame. */
PVector planeA = new PVector(-0.5f, -0.5f, 3.0f);
PVector planeB = new PVector(0.5f, -0.5f, 3.0f);
PVector planeC = new PVector(-0.5f, 0.5f, 3.0f);
PVector planeD = new PVector(0.5f, 0.5f, 3.0f);

/** the width of the depth camera, in pixels */
int depthWidth;
/** the height of the depth camera, in pixels */
int depthHeight;

/** the set of groups that were identified during the last grouping operation. */
ArrayList<PointGroup> lastGroups = new ArrayList<PointGroup>();
/** a cache of 3D points and their closest 2D points on the screen, to speed up the closestFramePoint operation. */
HashMap<PVector, Coord> coordCache = new HashMap<PVector, Coord>();
/** if this value is >0, it counts down every frame and causes the screen to recalibrate. */
int doCalibrate = 0;
/** the depth of each pixel that is assumed to be "normal". Set during calibration. */
float[][] calibratedDepths;
/** The RGB colours that the pixels were observed to be last frame. */
color[][] lastColours;
/** the relative certainty that each pixel is part of the screen, by colour matching. */
float[][] colourMatches;
/** the number of times that each pixel has been observed during calibration. */
int[][] observedCounts;
/** the average of all the values in colourMatches; used to determine the theshold in an intelligent way, since light conditions can vary. */
float averageMatch;

/** */
color oldCalibColour;
color newCalibColour = color(255, 0, 0);
/** determines how many points from the Kinect2 are skipped when calculating. Decrease to increase accuracy. */
int skip = 2;
/** determines how many points are skipped for the 3D visualisation. */
int drawSkip = 6;
/** the number of the plane point that is being edited by the QWEASD keys. 1 is planeA, 4 is planeD. */
int editingPoint = 1; 

/** this value is used to introduce a delay in clicking or unclicking. */
float clickTimer = 0;
/** if true, the program wants to hold down the mouse cursor. Whether it actually does is determined by mouseControl, and stored in mouseDown. */
boolean clicking = false;

/** the identified hand position, in 3D space. Potentially null. */
PVector handPos = null;
/** the closest point on the plane to the hand position handPos. Potentially null. */
Coord handCo = new Coord(0, 0);
/** the distance from the hand position handPos to the plane, in metres. */
float handDist = 0;

/** true if a hand is identified. false otherwise. If true, handPos and handCo cannot be null. */
boolean hasHand = false;

/** AWT interface object for changing mouse position. */
Robot bot;
/** if true, the program will control the mouse pointer. */
boolean mouseControl = false;
/** if true, the program will attempt to track the user's hand and generate a cursor position. */
boolean findHand = false;
/** true if the program is holding down the mouse cursor, false otherwise. */
boolean mouseDown = false;

/** the zero (top-left) position for the mouse control, X coordinate. Set whenever mouse control is toggled. */
int mouse0X = 0;
/** the zero (top-right) position for the mouse control, X coordinate. Set whenever mouse control is toggled. */
int mouse0Y = 0;

/** graphics object, for rendering the scene. Re-created whenever the scene switches from 2D to 3D or vv. */
PGraphics g;


/** runs once on startup. */
public void setup() {


  size(1280, 1024, P2D);
  g = createGraphics(width, height, P2D);
  //fullScreen(P2D, 1);
  set3D(threeD);


  // For Linux: tell the JVM to look in /usr/local for the Kinect2 library, where it is installed.
  NativeLibrary.addSearchPath("freenect", "/home/user/sketchbook/libraries/openkinect_processing/library/v2");

  // set up the Kinect differently depending on version:
  if (KINECT_VERSION == 1)
  {
    kinect = new Kinect(this);
    kinect.initDepth();
    kinect.initVideo();
    depthWidth = kinect.width;
    depthHeight = kinect.height;
  } else
  {
    kinect2 = new Kinect2(this);
    kinect2.initDepth();
    kinect2.initVideo();
    kinect2.initDevice();
    depthWidth = kinect2.depthWidth;
    depthHeight = kinect2.depthHeight;
  }

  // make some arrays
  this.calibratedDepths = new float[depthWidth][depthHeight];
  colourMatches  = new float[depthWidth][depthHeight];
  observedCounts  = new int[depthWidth][depthHeight];
  lastColours = new color[depthWidth][depthHeight];

  for (int i = 0; i < this.depthLookUp.length; i++) // build the depth lookup table
    this.depthLookUp[i] = this.rawDepthToMeters(i);

  try
  {
    // make the robot
    bot = new Robot();
  }
  catch (Exception ex)
  {
    // we're fucked without the robot
    throw new AssertionError("Could not create the Robot object for mouse control.", ex);
  }
  setupSound();
}

public void set3D(boolean td)
{
  threeD = td;
  g = createGraphics(width, height, threeD? P3D : P2D);
  if (g == null)
    throw new AssertionError("Tried to make PGraphics but it turned out null");
}


/** runs whenever a key is pressed. */
public void keyPressed() {
  if (this.keyCode == KeyEvent.VK_H)
    findHand = !findHand;
  else if (this.keyCode == KeyEvent.VK_Z)
    set3D(!threeD);
  else if (keyCode == KeyEvent.VK_M)
  {
    mouseControl = !mouseControl;
    PointerInfo info = MouseInfo.getPointerInfo();
    if (info != null)
    {
      Point mouse = info.getLocation();
      mouse0X = mouse.x;
      mouse0Y = mouse.y;
    }
  } else if (this.keyCode == KeyEvent.VK_C)
    drawMode = (drawMode+1) % 4;
  else if (this.keyCode == KeyEvent.VK_SPACE) { // space
    startCalibration();
  } else if (this.keyCode >= KeyEvent.VK_1 && this.keyCode <= KeyEvent.VK_4) { // 1 to 4, not numpad
    this.editingPoint = this.keyCode - 48;
  } else if (this.keyCode == KeyEvent.VK_9 && drawSkip > 1) { // 9
    --this.drawSkip;
  } else if (this.keyCode == KeyEvent.VK_0) { // 0
    ++this.drawSkip;
  } else {
    PVector newPoint;
    PVector oldPoint;
    switch (this.editingPoint) { // select what point to edit
    case 1: 
      {
        oldPoint = this.planeA;
        break;
      }
    case 2: 
      {
        oldPoint = this.planeB;
        break;
      }
    case 3: 
      {
        oldPoint = this.planeC;
        break;
      }
    case 4: 
      {
        oldPoint = this.planeD;
        break;
      }
    default: 
      {
        throw new IllegalStateException("How did we get here?");
      }
    }
    switch (this.keyCode) { // depending on what key was pressed, edit it in a certain way
    case KeyEvent.VK_Q:
      {
        newPoint = new PVector(oldPoint.x + 0.01f, oldPoint.y, oldPoint.z);
        break;
      }
    case KeyEvent.VK_W:
      {
        newPoint = new PVector(oldPoint.x, oldPoint.y + 0.01f, oldPoint.z);
        break;
      }
    case KeyEvent.VK_E:
      {
        newPoint = new PVector(oldPoint.x, oldPoint.y, oldPoint.z + 0.01f);
        break;
      }
    case KeyEvent.VK_A:
      {
        newPoint = new PVector(oldPoint.x - 0.01f, oldPoint.y, oldPoint.z);
        break;
      }
    case KeyEvent.VK_S:
      {
        newPoint = new PVector(oldPoint.x, oldPoint.y - 0.01f, oldPoint.z);
        break;
      }
    case KeyEvent.VK_D:
      {
        newPoint = new PVector(oldPoint.x, oldPoint.y, oldPoint.z - 0.01f);
        break;
      }
    default: 
      {
        newPoint = oldPoint;
      }
    }
    switch (this.editingPoint) { // depending on what point we were editing, assign the result to a plane variable
    case 1: 
      {
        this.planeA = newPoint;
        break;
      }
    case 2: 
      {
        this.planeB = newPoint;
        break;
      }
    case 3: 
      {
        this.planeC = newPoint;
        break;
      }
    case 4: 
      {
        this.planeD = newPoint;
      }
    }
  }
}

/** Runs every frame */
public void draw() {
  g.beginDraw();
  if (doCalibrate <= 0)
    // clear the background with a colour, what colour depends on how much we're clicking
    g.background(255*(1-(clickTimer/CLICK_TIMER_LIMIT)), 255*(1-(clickTimer/CLICK_TIMER_LIMIT)), 255);
  else
    g.background(newCalibColour);
  if (threeD) // move the camera
  {
    PVector screenCenter = interpolateToPlane(0.5, 0.5); // rotate around wherever we think the center of the screen plane is
    g.camera((float)(this.mouseX - this.width / 2) + screenCenter.x * DRAW_SCALE, screenCenter.y * DRAW_SCALE, (float)(this.mouseY - this.height / 2) + screenCenter.z * DRAW_SCALE, screenCenter.x * DRAW_SCALE, screenCenter.y * DRAW_SCALE, screenCenter.z * DRAW_SCALE, 0.0f, 1.0f, 0.0f);
  }
  int[] depth; // depth values from depth camera
  PImage image; // RGB image from colour camera
  // get data from cameras depending on What Kinect we're using
  if (KINECT_VERSION == 1)
  {
    depth = kinect.getRawDepth();
    image = kinect.getVideoImage();
  } else
  {
    depth = kinect2.getRawDepth();
    image = kinect2.getVideoImage();
  }
  //image.resize(width, height);
  //background(image);

  float totalMatch = 0.0;
  int pointCount = 0;

  //this.rotateY(this.a);
  ArrayList<PVector> normalPoints = new ArrayList<PVector>(); // will hold all the points that aren't different from calibration.
  ArrayList<PVector> movingPoints = new ArrayList<PVector>(); // holds all the points that are.

  // main loop; run through all the point data from the depth camera
  for (int x = 0; x < depthWidth; x+= skip) { 
    for (int y = 0; y < depthHeight; y+= skip) {
      int offset = x + y * depthWidth;
      int rawDepth = depth[offset];
      int colX = round((x/(float)depthWidth)*image.width);
      int colY = round((y/(float)depthHeight)*image.height);

      color col = image.get(colX, colY);
      // work out the world coordinate
      PVector v = depthToWorld(x, y, rawDepth);
      // work out how far away it really is
      float realDepth = depthLookUp[rawDepth];
      if (realDepth > 0.5f && realDepth < (KINECT_VERSION == 2 ? 10.0f : 6.0f)) { // ignore things outside of the kinect's range
        if (this.doCalibrate > 1) // if we're calibrating:
        {
          this.calibratedDepths[x][y] += (realDepth); // update the calibration data
          if (lastColours[x][y] != 0)
          {
            float match = colourMatch(col, lastColours[x][y]);
            totalMatch += match;
            colourMatches[x][y] += match;
          }
          lastColours[x][y] = col;
          observedCounts[x][y]++;
          pointCount++;
        }
        float frameDist = distanceToFrame(v); // how far this point is from the frame
        float calDiff = abs((float)(realDepth - this.calibratedDepths[x][y])); // how different this point is from the BG
        float colourMatch = colourMatches[x][y];
        boolean moving = calDiff > MOVE_THRESHOLD;
        boolean close = frameDist > CLOSE_THRESHOLD;
        boolean active = colourMatch > averageMatch;
        int g = active ? 255: 0;
        int b = moving ? 255 : 127;
        int r = close ? 0 : 255;

        if (moving) {
          movingPoints.add(v);
        }

        if (!moving && active)
          normalPoints.add(v);

        color c;
        switch(drawMode) // render points depending on render mode
        {
        case 0:
          c = color(r, g, b); // colour by role
          break;
        case 1 :
          c = col; // real colour
          break;
        case 2:
          c = color((colourMatch / COLOUR_THRESHOLD) * 127, 0, active? 255 : 0); 
          break;
        case 3:
          c = color(max(realDepth - this.calibratedDepths[x][y], 0)*-25, 127, min(0, realDepth - this.calibratedDepths[x][y])*25); 
          break;
        default:
          c = color(0);
        }

        boolean shouldDraw = (x % drawSkip == 0) && (y % drawSkip == 0) && (moving || showAll);

        if (shouldDraw)
          drawPoint(v.x, v.y, v.z, c);
      }
    }
  }
  // if the screen appears badly miscalibrated, force recalibration
  if (movingPoints.size() > normalPoints.size() && doCalibrate <= 0)
    startCalibration();
  // render the screen plane dots

  for (float x = 0.0f; x <= 1.0f; x += 0.2f) {
    for (float y = 0.0f; y <= 1.0f; y += 0.2f) {
      PVector p = this.interpolateToPlane(x, y);
      drawPoint(p.x, p.y, p.z, color(255));
    }
  }
  /*
  for (PointGroup group: lastGroups)
   {
   color col = color(random(0, 255), random(0, 255), random(0, 255));
   for (PVector point : group.getPoints())
   {
   drawPoint(point.x, point.y, point.z, col);
   }
   }
   */

  if (this.doCalibrate > 0) { // decrement calibration timer
    g.pushMatrix();
    g.translate(0, 0, 500);
    g.rotateY(radians(180));
    --this.doCalibrate;
    if (this.doCalibrate == 1)
    {
      text("Locating screen...", 0, 40);
      for (int y = 0; y < depthHeight; y+= skip)
      {
        for (int x = 0; x < depthWidth; x+= skip)
        {
          int observed = observedCounts[x][y];
          if (observed > 0)
          {          

            calibratedDepths[x][y] /= observed;
            colourMatches[x][y] /= observed;
            print(round(colourMatches[x][y]*10) + "\t");
            averageMatch += colourMatches[x][y];
          }
        }
        println();
      }
      averageMatch /= pointCount;
    }
    if (this.doCalibrate == 0) 
    { // if calibration over
      text("Probably done.", 0, 20);
      this.findScreen(normalPoints); // try to work out where the screen is
    } else
    {
      //float pointCount = (kinect.depthWidth/skip) * (kinect.depthHeight/skip);
      text("Calibrating, please wait!", 0, 20);
      text("Cycles left: " + doCalibrate, 0, 40);
      text("Match level: " + totalMatch/pointCount, 0, 60);

      //text("Completed cycle.", 0, 80);
      newCalibColour = 0;
      while (saturation(newCalibColour) < 240)
        newCalibColour = color(random(0, 255), random(0, 255), random(0, 255));

      //} else
      //{
      //  text("Can't see anything that looks." + oldCalibColour + "! Calibration blocked.", 0, 80);
      //  doCalibrate++;
      //}
    }
    g.popMatrix();
  } else {
    Collections.sort(movingPoints, new Comparator<PVector>() {
      public int compare(PVector a, PVector b) {
        return signum(distanceToFrame(a)-distanceToFrame(b));
      }
    }
    );
    ArrayList<PVector> handPoints = new ArrayList<PVector>();
    for (int i = 0; i < movingPoints.size(); i++) // take the 20% of hand points closest to the screen plane
    {
      PVector point = movingPoints.get(i);
      Coord co = findClosestFramePointInStupidWay(point, -0.1f, -0.1f, 1.1f, 1.1f, 0); // find where these points project (with a little margin around the edge)
      if (co.isOnScreen()) // ignore points that project off the screen, they're noise
        handPoints.add(point);
      if (handPoints.size() >= movingPoints.size() / HAND_POINT_FRAC) // if we've reached our quota, stop
        break;
    }
    text("Points (H/M/N): " + handPoints.size() + "/" + movingPoints.size() + "/" + normalPoints.size(), 0, 20);
    println("Hand points: " + handPoints.size());
    if (findHand)
    {
      findHand(handPoints);
      renderHand();
      soundHand();
    }
    controlPointer();
  }
  // finish drawing, and paint the graphics object to the frame
  g.endDraw();
  image(g, 0, 0);
}

/** convenience method to start the calibration process. */
public void startCalibration()
{
  doCalibrate = CALIBRATION_LENGTH;
  calibratedDepths = new float[depthWidth][depthHeight];
  colourMatches = new float[depthWidth][depthHeight];
  observedCounts  = new int[depthWidth][depthHeight];
  lastColours = new color[depthWidth][depthHeight];
}

/** given a point in 3D space, returns how far it is to the plane. 
 * @param point the point.
 * @return the distance, in meters, from the frame.
 */
public float distanceToFrame(PVector point) {
  PVector framePoint = this.findClosestFramePointInStupidWay(point, 0.0f, 0.0f, 1.0f, 1.0f, 0).getVector();
  return point.dist(framePoint);
}

/** Using a given array of points, attempts to find the points that represent a hand. 
 Sets handCo, handPos, handDist and hasHand using the values gained.
 @param points the points that are to be used.
 */
public void findHand(ArrayList<PVector> points) {
  if (points.size() > MIN_SENSE_POINTS) { // don't bother if the number of points is tiny
    PointGroup group = null;
    ArrayList<PointGroup> groups = groupPoints(points); // group the points
    int maxPoints = 0;
    for (PointGroup g : groups) // now try to find the group that is the largest
    {
      if (g.getPoints().size() > maxPoints)
      {
        maxPoints = g.getPoints().size();
        group = g;
      }
    }
    color groupCol = color(192);  
    for (PVector p : group.getPoints()) // render all the points we're using
    {
      drawPoint(p.x, p.y, p.z, groupCol);
    }
    PVector cog = group.getCOG(); // find the center of the group
    Coord co = this.findClosestFramePointInStupidWay(cog, 0.0f, 0.0f, 1.0f, 1.0f, 0); // project it onto the frame
    PVector pos = co.getVector();
    float dist = cog.dist(pos);
    text("Dist: " + dist + "; Co: " + co, 0, 40);

    hasHand = group.getPoints().size() > MIN_SENSE_POINTS;

    if (hasHand)
    {

      if (dist < CLICK_DISTANCE && clickTimer < CLICK_TIMER_LIMIT)
        clickTimer += (CLICK_DISTANCE - dist) * 10;
      else if (dist > CLICK_DISTANCE && clickTimer > 0)
        clickTimer -= (dist - CLICK_DISTANCE) * 10;

      if (clickTimer < 0)
        clickTimer = 0;
      else if (clickTimer > CLICK_TIMER_LIMIT)
        clickTimer = CLICK_TIMER_LIMIT;

      if (!clicking && clickTimer >= CLICK_TIMER_LIMIT * 0.666)
      {
        clicking = true;
      } else if (clicking && clickTimer <= CLICK_TIMER_LIMIT * 0.333)
      {
        clicking = false;
      }

      //handCo = co;

      float frac = (clicking? 1 : 1);

      float rawX = (handCo.x + (co.x - handCo.x)/frac);
      Coord newCo = new Coord(KINECT_VERSION == 2 ? 1-rawX:rawX, handCo.y + (co.y - handCo.y)/frac);

      if (!clicking || sqrt(sq(newCo.x - handCo.x) + sq(newCo.y - handCo.y)) > STABLISER_RADIUS)
      {

        handCo = newCo;
        handPos = handCo.getVector();

        handDist += (dist - handDist) / 2;
      }
    } else if (clickTimer > 0)
      clickTimer -= 0.5; // if we have no hand, slowly start unclicking
  }
}

void controlPointer()
{
  if (mouseControl)
  {
    bot.mouseMove(mouse0X + (int)(handCo.x * width), mouse0Y+ (int) (handCo.y * height));
    int mask = InputEvent.BUTTON1_DOWN_MASK;
    if (clicking && !mouseDown)
    {
      bot.mousePress(mask);
      mouseDown = true;
      delay(100);
      bot.mouseRelease(mask);
    } else if (!clicking && mouseDown)
    {
      //bot.mouseRelease(mask);
      mouseDown = false;
    }
  }
}

/** This awful method finds the closest point on the screen to a given point in 3D space.
 To accomplish this, is commits ritual genocide of your memory, the data given, and the very idea of efficient programming.
 @param point the point in 3D space that the closest screen point is to be found for.
 @param minX the lowest X coordinate to try.
 @param minY the lowest Y coordinate to try.
 @param maxX the highest X coordinate to try.
 @param maxY the highest Y coordinate to try.
 @param divisions the number of times the algorithm has recursed so far.
 @return the coordinate on the frame that is the closest to the point given.
 */
public Coord findClosestFramePointInStupidWay(PVector point, float minX, float minY, float maxX, float maxY, int divisions) {
  if (coordCache.containsKey(point))
    return coordCache.get(point);
  Coord a = new Coord(minX, minY);
  Coord b = new Coord(maxX, minY);
  Coord c = new Coord(minX, maxY);
  Coord d = new Coord(maxX, maxY);
  float aDist = point.dist(a.getVector());
  float bDist = point.dist(b.getVector());
  float cDist = point.dist(c.getVector());
  float dDist = point.dist(d.getVector());
  Coord closest = aDist < bDist && aDist < cDist && aDist < dDist ? a : (bDist < aDist && bDist < cDist && bDist < dDist ? b : (cDist < aDist && cDist < bDist && cDist < dDist ? c : d));
  if (divisions >= 16) {
    coordCache.put(point, closest);
    return closest;
  }
  float centerX = (minX + maxX) / 2;
  float centerY = (minY + maxY) / 2;
  if (closest == a) {
    return this.findClosestFramePointInStupidWay(point, minX, minY, centerX, centerY, divisions + 1);
  }
  if (closest == b) {
    return this.findClosestFramePointInStupidWay(point, centerX, minY, maxX, centerY, divisions + 1);
  }
  if (closest == c) {
    return this.findClosestFramePointInStupidWay(point, minX, centerY, centerX, maxY, divisions + 1);
  }
  return this.findClosestFramePointInStupidWay(point, centerX, centerY, maxX, maxY, divisions + 1);
}


/** attempts to locate the screen in 3D space, using a given set of points. 
 @param normalPoints the set of points to use. They are assumed to be static.
 */
public void findScreen(ArrayList<PVector> normalPoints) {
  ArrayList<PointGroup> groups = this.groupPoints(normalPoints); // divide the points into groups.
  lastGroups = groups;
  float bestRot = 0.0f; // the best rotation so far.
  Cube bestBounds = null; // the bounds of the best rotated group so far.
  float bestDistance = Float.MAX_VALUE; // how "far" the best rotated group so far was from a perfect solution.
  PVector bestCOG = null; // the center-of-gravity of the best group so far.
  println((String)"Searching for best group...");
  for (PointGroup group : groups) { // for every point group visible:
    if (group.getPoints().size() < 1000) // ignore groups that are too small
      continue;
    PVector cog = group.getCOG();
    println((String)("Group COG is " + (Object)cog));
    float i = radians((float)-90.0f);
    while (i < radians((float)90.0f)) { // loop from -90 degrees to +90 degrees
      //println((String)("Considering rotated by " + i + "r"));
      PointGroup rotated = group.rotateX(i, cog.y, cog.z); // rotate the group on the X axis about it's COG, by i radians.
      Cube bounds = rotated.getBounds();
      //println((String)("\tDims in this orientation: " + bounds.getWidth() + "*" + bounds.getHeight() + "*" + bounds.getLength() + " [X*Y*Z]"));
      float boundsDistance = abs((float)(bounds.getWidth() - TARGET_SCREEN_WIDTH)) + abs((float)(bounds.getHeight() - TARGET_SCREEN_HEIGHT)) + bounds.getLength();
      //println((String)("\tBounds score: " + boundsDistance));
      if (boundsDistance < bestDistance) { // if it's the new best:
        //println((String)"\tNew best candidate.");
        // record that
        bestDistance = boundsDistance;
        bestRot = i;
        bestBounds = bounds;
        bestCOG = cog;
      }
      i += radians((float)1.0f);
    }
  }
  if (bestBounds != null) { // if we found something:
    println((String)"New plane bounds found!");
    println((String)("\tDims: " + bestBounds.getWidth() + "*" + bestBounds.getHeight() + "*" + bestBounds.getLength() + " [X*Y*Z]"));
    println((String)("\tCOG: " + (Object)bestCOG));
    // set the plane points by using the bounding cube of the best rotated group
    this.planeA = this.pointRotateX(bestBounds.cornerA, - bestRot, bestCOG.y, bestCOG.z);
    this.planeD = this.pointRotateX(bestBounds.cornerB, - bestRot, bestCOG.y, bestCOG.z);
    this.planeB = new PVector(this.planeD.x, this.planeA.y, this.planeA.z);
    this.planeC = new PVector(this.planeA.x, this.planeD.y, this.planeD.z);
    println((String)("\tA: " + (Object)this.planeA));
    println((String)("\tB: " + (Object)this.planeB));
    println((String)("\tC: " + (Object)this.planeC));
    println((String)("\tD: " + (Object)this.planeD));
    // since the plane has moved, revoke the coordinate cache
    coordCache.clear();
  }
}



/** collects a given set of points into groups, by proximity, using a horrible algorithm.
 @param points the points to be grouped.
 @return a list of groups generated. Every point given in points will be included.
 */
public ArrayList<PointGroup> groupPoints(ArrayList<PVector> points) {
  println((String)("Grouping " + points.size() + " points..."));
  ArrayList<PVector> ungrouped = new ArrayList<PVector>(points);
  ArrayList<PointGroup> groups = new ArrayList<PointGroup>();
  while (!ungrouped.isEmpty()) { // while there are still points not in a group:
    final PVector selected = ungrouped.get(0);
    // put the first point we find into it's own group
    PointGroup group = new PointGroup();
    groups.add(group);
    group.add(selected);
    Cube bounds = group.getBounds();
    // now go looking for other points to add to our group
    // sort the ungrouped points by distance ascending from the point selected
    ArrayList<PVector> candidates = new ArrayList<PVector>(ungrouped);
    Collections.sort(candidates, new Comparator<PVector>() {
      public int compare(PVector a, PVector b)
      {
        return signum(selected.dist(a)-selected.dist(b));
      };
    }
    );
    for (PVector candidate : candidates) // loop through the candiate points
    {
      if ( // if it's within the bounds of the current group:
        (candidate.x >= bounds.getMinX() - 0.03) &&
        (candidate.y >= bounds.getMinY() - 0.03) &&
        (candidate.z >= bounds.getMinZ() - 0.03) &&

        (candidate.x <= bounds.getMaxX() + 0.03) &&
        (candidate.y <= bounds.getMaxY() + 0.03) &&
        (candidate.z <= bounds.getMaxZ() + 0.03)
        )
      {
        // it potentially might be close enough to a point in the group to be included, test it
        //println("\t" + candidate + " may be close to group, testing...");
        for (PVector point : group.getPoints()) { // for every OTHER point in the group:
          float dist = candidate.dist(point);

          if (dist <= 0.03) // if the candidate for the group is close enough to an existing member:
          {
            group.add(candidate); // add it to the group
            bounds = group.getBounds(); // recalcluate the group bounds
            //println("\tAccepted, new bounds " + bounds);
            break;
          }
        }
      }
    }
    ungrouped.removeAll(group.getPoints()); // all the points that got added to the group as a result are no longer ungrouped
  }
  println((String)("Points were divided into " + groups.size() + " groups."));
  return groups; // fukken done
}