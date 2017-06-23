
/** Draws a straight line between two 3D points. Not currently used. */
public void drawLine(PVector a, PVector b, int colour) {
  g.stroke(colour);
  g.strokeWeight(1.0f);
  g.line(a.x * DRAW_SCALE, a.y * DRAW_SCALE, a.z * DRAW_SCALE, b.x * DRAW_SCALE, b.y * DRAW_SCALE, b.z * DRAW_SCALE);
}

/** Draws a dot at a given point, either in 3D or 2D space, with a given colour. 
 @param x interpreted as an X coordinate in metres.
 @param y interpreted as a Y coordinate in metres.
 @param z if in 3D, interpreted as a Z coordinate in metres. Ignored in 2D, may be used to determine size later.
 @param colour the colour of the point to draw.
 */
public void drawPoint(float x, float y, float z, int colour) {
  g.noStroke();
  g.fill(colour);
  if (threeD)
  {
    g.pushMatrix();
    
    g.translate(x * DRAW_SCALE, y * DRAW_SCALE, z * DRAW_SCALE);
    g.rotateY(0.5);
    g.ellipse(0.0f, 0.0f, (float)this.drawSkip / 2.0f, (float)this.drawSkip / 2.0f);
    g.popMatrix();
  } else
  {
    Coord co = findClosestFramePointInStupidWay(new PVector(x, y, z), 0.0, 0.0, 1.0, 1.0, 0);
    g.ellipse((1-co.x)*width, co.y*height, (float)this.drawSkip, (float)this.drawSkip);
  }
}


/** renders the points used to determine the hand position. */
public void renderHand()
{
  if (hasHand && handCo != null && handPos != null) // if we've got a hand:
  {
    // work out the sizes of the various circles.
    float distSize = 32.0f + ((handDist-CLICK_DISTANCE) * 128.0f); 
    float distTargetSize = 32;
    float timeSize = (clickTimer / CLICK_TIMER_LIMIT) * 32;
    float timeTargetSize = (clicking? 0.333 : 0.666) * 32;

    if (threeD)
    {
      g.pushMatrix();
      g.translate((handPos.x) * DRAW_SCALE, handPos.y * DRAW_SCALE, handPos.z * DRAW_SCALE);
    }

    float x = (threeD? 0 : handCo.x * width);
    float y = (threeD? 0 : handCo.y * height);

    g.noFill();
    float alpha = 0;
    //float alpha = 1-max( (CLICK_DISTANCE * 2) / dist, 1);

    g.stroke(color(255, 255, 0));
    g.ellipse(x, y, distSize, distSize);
    g.stroke(color(255, 0, 255));
    g.ellipse(x, y, distTargetSize, distTargetSize);

    g.noStroke();
    g.fill(clicking ? color(255, 0, 0) : color(0, 0, 255));
    g.ellipse(x, y, timeSize, timeSize);
    g.noFill();
    g.stroke(clicking? color(0) : color(255));
    g.ellipse(x, y, timeTargetSize, timeTargetSize);

    if (threeD)
      g.popMatrix();
  }
}