# ailo-interface
The gestural interface and touchscreen alternative used for Team KLM's project at MediaLAB Amsterdam, "Ailo"

# Summary
The Ailo Interface is a simple gestural interface using a Kinect (v1 or v2) camera, implimented in Processing. 
Using simply a Kinect and a projector (ultra-short-range reccomended), you can turn any surface into a psuedo-touchscreen!

# You will need...
Processing to run this program. In the future I might fork it and port it to standard Java.

For hardware, you will also need a Kinect (of either type) and a projector or a large screen. Or a small screen, or an LED display, or literally anything that can display video signals from a computer. It's a Processing sketch, not the police.

Processing will need the OpenKinect for Processing library, and the Minim sound library. You can install both from Processing's library manager; ignore the fact that the OpenKinect library says it's only for MacOS, it works on everything.

The sketch will run on Linux, Windows, or MacOS. Sadly, due to a lack of support in the OpenKinect-for-Processing library, Only the Kinect v1 works on Linux.

# Setup
Connect both the Kinect and the projector to your computer, and ensure that they are both mounted in a position where line-of-sight to the screen won't be blocked by a user standing in front of the screen. The Kinect needs to be horizontally aligned with the center of the screen, but can be in any position vertically. It's optimum angle relative to the screen is 45 degrees above and below.

The projector can be placed anywhere, but keep in mind the effect of shadows from the user and the maximum keystoning setting of the the projector.

# Usage
- Run the Processing sketch. You should see lots of dots on the screen; that means it's receiving input from the Kinect. 
- Press the spacebar to begin calibration. For a short moment, the screen should flash lots of bright colours. It does this to learn the position of the projection.
- Now that the screen is calibrated, you can use H to toggle hand tracking, and visually check that the calibration is correct. 
- If calibration is correct, move your mouse pointer to the top-left of the screen and press M to start control of the mouse pointer. Then, somehow switch to the window that shows whatever you want without using the mouse. Good luck!
