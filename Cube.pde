import processing.core.PVector;

/**
 * Represents a 3D cube.
 */
class Cube {
    final PVector cornerA;
    final PVector cornerB;
    //final /* synthetic */ KinectTest2 this$0;

    Cube(PVector a, PVector b) {
        this.cornerA = a;
        this.cornerB = b;
    }

    Cube(float minX, float maxX, float minY, float maxY, float minZ, float maxZ) {
        this.cornerA = new PVector(minX, minY, minZ);
        this.cornerB = new PVector(maxX, maxY, maxZ);
    }

    public float getMinX() {
        return min((float)this.cornerA.x, (float)this.cornerB.x);
    }

    public float getMaxX() {
        return max((float)this.cornerA.x, (float)this.cornerB.x);
    }

    public float getMinY() {
        return min((float)this.cornerA.y, (float)this.cornerB.y);
    }

    public float getMaxY() {
        return max((float)this.cornerA.y, (float)this.cornerB.y);
    }

    public float getMinZ() {
        return min((float)this.cornerA.z, (float)this.cornerB.z);
    }

    public float getMaxZ() {
        return max((float)this.cornerA.z, (float)this.cornerB.z);
    }

    public float getHeight() {
        return this.getMaxY() - this.getMinY();
    }

    public float getWidth() {
        return this.getMaxX() - this.getMinX();
    }

    public float getLength() {
        return this.getMaxZ() - this.getMinZ();
    }
    
    public String toString()
    {
      return cornerA + ":" + cornerB;
    }
    
}