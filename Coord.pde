/*
 * Decompiled with CFR 0_118.
 * 
 * Could not load the following classes:
 *  KinectTest2
 *  processing.core.PVector
 */
import processing.core.PVector;

/**
Represents a coordinate on the screen.
*/
class Coord {
    /** the relative X coordinate, from 0 (left) to 1 (right) */
    final float x;
    /** the relative Y coordinate, from 0 (top) to 1 (bottom) */
    final float y;

    public Coord(float x, float y) {
        this.x = x;
        this.y = y;
    }

    /** gets the 3D position of this plane coordinate. Not fixed if the plane moves. 
    @return the position of this screen coordinate in 3D space.
    */
    public PVector getVector() {
        return interpolateToPlane(this.x, this.y);
    }
    
    /** Determines if this coordinate is valid; that is, not off the edges of the screen. 
    @return true if the point is on the screen, false otherwise.
    */
    public boolean isOnScreen()
    {
      return x >= 0 && x <= 1 && y >= 0 && y <= 1;
    }
    
    public String toString()
    {
      return "{"+x + ", "+ y+"}";
    }
}