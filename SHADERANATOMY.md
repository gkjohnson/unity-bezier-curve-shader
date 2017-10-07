# Anatomy of a Shader
## Pipeline
### Vertex Shader
Called once per attribute structure in the vertex array.

### Hull Shader
An interpolated result from the vertex shader over a particular "patch" with the whole set of interpolated patch data. More data can be produced here as control point inputs to the Domain Shader.

### Tesselation / Hull Constant Shader
A shader run in parallel with the Hull Shader that defines the edge and internal patch tesselation for the non-programmable tesselation stage.

### Domain Shader
Run once for every vertex produced by the tesselation stage along with the whole set of control points for the patch, and the uv location for the point relative to the patch. This can be thought of as the Vertex Shader for the tesselation output.

### Fragment Shader
Run once for every rasterized pixel in the projected resultant triangle from the domain shader.
