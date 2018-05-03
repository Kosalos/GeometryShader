# GeometryShader
Geometry shader demonstration for IOS, Swift and Metal

Metal does not offer a geometry shader, so this class supplies one.
Given an array of seed points, this class creates the vertices and indices required to render a
multi-segmented tower based at each point.

Class Geometry offers three functions:
update() = copy the GUI control data into the control buffer and call calc..
calcGeometry() = call the geometry shader to produce the vertices & indices 
render() = draw the created geometry

GeometryPoint is provided for each seed point. 

struct GeometryPoint {
    vector_float3 pos;	 // 3D coordinate of the base of the tower
    vector_float2 angle; // initial direction as and X and Y rotation
    float stiffness;     // controls how quickly the tower responds to angle changes
};

GeometryControl provides global data that all towers share.

struct GeometryControl {
    int nSides;			// number of sides of a tower
    int nLevels;		// number of levels in a tower
    int pCount;			// number of seed points provided
    
    vector_float2 deltaAngle;	// how much the tower rotates at each level
    vector_float2 desiredAngle; // the angle all towers should be moving to (stiffness affects response time)
    float radius;		// the width of the bottom of the tower
    float deltaRadius;		// how the width is altered at each level
    float dist;			// the vertical distance between tower levels
    float deltaDist;		// amount the distance is altered at each level
};

The Geometry shader uses this data to generate the tower vertices and indices:

kernel void calcGeometryShader
(
 device TVertex *vertices       [[ buffer(0) ]], // where to store the vertices
 device ushort *indices         [[ buffer(1) ]], // where to store the indices
 device atomic_uint &vcounter   [[ buffer(2) ]], // where to store the number of vertices created
 device atomic_uint &icounter   [[ buffer(3) ]], // where to store the number of indices created
 device GeometryPoint *pnt      [[ buffer(4) ]], // the seed data for each tower
 constant GeometryControl &ctrl [[ buffer(5) ]], // the global control data shared by all towers
 uint p [[thread_position_in_grid]])
{

Note: this shader also alters the angle field of each seed point (that's why *pnt is not constant)
 
/////////////////////////

Using the GUI:
All the control widgets work the same way:
Press and hold to either side of center to affect the parameters in the specified direction and speed.

Pinch/drag the screen to control position and rotation.


