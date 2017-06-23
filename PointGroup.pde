/*
 * Decompiled with CFR 0_118.
 * 
 * Could not load the following classes:
 *  KinectTest2
 *  KinectTest2$Cube
 *  processing.core.PVector
 */
import java.util.HashSet;
import processing.core.PVector;

/** Represents a group of points. */
class PointGroup {
    final HashSet<PVector> points;

    PointGroup() {
        this.points = new HashSet();
    }

    public void add(PVector point) {
        this.points.add(point);
    }

    public HashSet<PVector> getPoints() {
        return this.points;
    }

    public Cube getBounds() {
        float minX = Float.MAX_VALUE;
        float minY = Float.MAX_VALUE;
        float minZ = Float.MAX_VALUE;
        float maxX = Float.MIN_VALUE;
        float maxY = Float.MIN_VALUE;
        float maxZ = Float.MIN_VALUE;
        for (PVector point : this.points) {
            if (point.x < minX) {
                minX = point.x;
            }
            if (point.y < minY) {
                minY = point.y;
            }
            if (point.z < minZ) {
                minZ = point.z;
            }
            if (point.x > maxX) {
                maxX = point.x;
            }
            if (point.y > maxY) {
                maxY = point.y;
            }
            if (point.z <= maxZ) continue;
            maxZ = point.z;
        }
        return new Cube(minX, maxX, minY, maxY, minZ, maxZ);
    }

    public PVector getCOG() {
        float xTotal = 0.0f;
        float yTotal = 0.0f;
        float zTotal = 0.0f;
        for (PVector point : this.points) {
            xTotal += point.x;
            yTotal += point.y;
            zTotal += point.z;
        }
        return new PVector(xTotal / (float)this.points.size(), yTotal / (float)this.points.size(), zTotal / (float)this.points.size());
    }

    public PointGroup rotateX(float angle, float y, float z) {
        PointGroup newGroup = new PointGroup();
        for (PVector point : this.points) {
            PVector rotated = pointRotateX(point, angle, y, z);
            newGroup.add(rotated);
        }
        return newGroup;
    }
}