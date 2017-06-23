
String colToString(color c)
{
  return "(R" + red(c) + " G" + green(c) + " B" + blue(c) + " A" + alpha(c) + ")";
}

float colourMatch(color a, color b)
{
  //float ha = hue(a);
  //float hb = hue(b);
  //float sa = saturation(a);
  //float sb = saturation(b);
  //println("Colour A= " + red(a) + " " + green(a) + " " + blue(a) + " S:" + sa + " H:" + ha);
  //println("Colour A= " + red(b) + " " + green(b) + " " + blue(b) + " S:" + sb + " H:" + hb);
  float ret = 0.0;
  ret += abs(red(a)-red(b))/360.0;
  ret += abs(green(a)-green(b))/255.0;
  ret += abs(blue(a)-blue(b))/255.0;
  return ret;
}

/** Given a coordinate on the plane, finds it's position in 3D space.
 @param x the X position on the frame, from 0 (left) to 1 (right)
 @param y the Y position on the frame, from 0 (top) to 1 (bottom)
 @return the vector represeting that coordinate's position in 3D space
 */
public PVector interpolateToPlane(float x, float y) {
  // work out the two points of the vertical line that runs the screen at a constant X screen coordinate
  PVector pointAB = this.threeDInterpolate(this.planeA, this.planeB, x);
  PVector pointCD = this.threeDInterpolate(this.planeC, this.planeD, x);
  // interpolate across that line by the Y screen coordinate
  return this.threeDInterpolate(pointAB, pointCD, y);
}

/** interpolates a 3D vector between two others.
 @param a the first vector, representing 0.
 @param b the second vector, represeting 1.
 @param d the delta value, representing the fraction of the "journey" to take from a to b.
 @return the 3D vector that lies d ab-lengths between a and b.
 */
public PVector threeDInterpolate(PVector a, PVector b, float d) {
  float x = this.twoDInterpolate(a.x, b.x, d);
  float y = this.twoDInterpolate(a.y, b.y, d);
  float z = this.twoDInterpolate(a.z, b.z, d);
  return new PVector(x, y, z);
}

/** the signum function, returns the sign of a number. Equivalent to a/abs(a).
 @param a the number to retreive the sign of.
 @return -1 if a is negative, 0 if it is 0, and +1 if it is positive.
 */
int signum(float a)
{
  if (a < 0)
    return -1;
  else if (a == 0)
    return 0;
  else return 1;
}

/** linearly interpolates between two numbers.
 @param a the first number, representing 0.
 @param b the second number, representing 1.
 @param d the interpolation cooefficient.
 @return the number that lies d units beween a and b.
 */

public float twoDInterpolate(float a, float b, float d) {
  return d * (b - a) + a;
}

/** converts a depth value, given by the Kinect, to a real-world depth in meters. */
public float rawDepthToMeters(int depthValue) {
  if (KINECT_VERSION == 1)
  {
    if (depthValue < 2047) {
      return (float)(1.0 / ((double)depthValue * -0.003071101615205407 + 3.330949544906616));
    }
    return 0.0f;
  }
  else
  {
    return depthValue / 1000.0;
  }
}

/** converts values from the Kinect's depth camera to points in 3D space.
 @param x the X coordinate of the pixel returned from the depth camera.
 @param y the Y coordinate of the pixel returned from the depth camera.
 @param depthValue the raw depth value returned from the depth camera.
 @return the point that the depth camera sees, in 3D space.
 */
public PVector depthToWorld(int x, int y, int depthValue) {
  PVector result = new PVector();
  double depth = this.depthLookUp[depthValue];
  result.x = (KINECT_VERSION == 2 ? 1.0 : -1.0 ) * (float)(((double)x - 339.30780029296875) * depth * 0.0016828944208100438);
  result.y = (float)(((double)y - 242.7391357421875) * depth * 0.0016919313929975033);
  result.z = (float)depth;
  return result;
}

/** rotates a point on the X axis, about a given y and z coordinate, by a given angle.
 @param point the point to rotate.
 @param angle the angle to rotate, in radians.
 @param y the Y coordinate that is the center of rotation.
 @param z the Z coordinate that is the center of rotation.
 @return the point, now rotated.
 */
public PVector pointRotateX(PVector point, float angle, float y, float z) {
  float oldAngle = atan2((float)(point.y - y), (float)(point.z - z));
  float rad = sqrt((float)(sq((float)(point.y - y)) + sq((float)(point.z - z))));
  float newY = y + sin((float)(oldAngle + angle)) * rad;
  float newZ = z + cos((float)(oldAngle + angle)) * rad;
  PVector rotated = new PVector(point.x, newY, newZ);
  return rotated;
}