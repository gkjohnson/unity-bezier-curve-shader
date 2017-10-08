using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class BezierSurface : MonoBehaviour {
    // Visual size of and whether to display the
    // control points
    public float _controlpointScale = 0.1f;
	public bool _showControlPoints = true;

	Transform[] _controlPoints = new Transform[16]; 
	ComputeBuffer _buffer;

	void Awake () {
		Mesh mesh = new Mesh();

		// 1----2
		// |    |
		// 4----3
		mesh.vertices = new Vector3[] {
			Vector3.zero,
			Vector3.zero,
			Vector3.zero,
			Vector3.zero
		};

		mesh.uv = new Vector2[] {
			new Vector2(1,0),
			new Vector2(0,0),
			new Vector2(0,1),
			new Vector2(1,1)
		};

		// create the control points
		for( int y = 0; y < 4; y++ )
		{
			for( int x = 0; x < 4; x++ )
			{
				Transform cp = GameObject.CreatePrimitive(PrimitiveType.Sphere).transform;
				cp.name = "control point " + (4 * y + x);
                cp.hideFlags = HideFlags.HideInHierarchy;
				Destroy(cp.GetComponent<Collider>());
                
				cp.parent = transform;
				cp.localScale *= 0.1f;
				cp.localPosition = new Vector3( -1 + 2 * x / 3.0f, 0, -1 + 2 * y / 3.0f);

				cp.GetComponent<Renderer>().material.color = Color.red;

				_controlPoints[y * 4 + x] = cp;
			}
		}

		// set the indices to quads so we our hull shader can use it
		mesh.SetIndices(new int[]{ 3, 2, 1, 0}, MeshTopology.Quads, 0);
        mesh.bounds = new Bounds(Vector3.zero, 10000 * Vector3.one);
		GetComponent<MeshFilter>().mesh = mesh;

		// initialize the buffer
		_buffer = new ComputeBuffer(16, 3 * 4);
	}

	// Update the buffer with the new control points
	void Update()
	{
		Vector3[] arr = new Vector3[16];
		for( int i = 0 ; i < arr.Length ; i ++ )
		{
			_controlPoints[i].localScale = Vector3.one * _controlpointScale;
			_controlPoints[i].GetComponent<Renderer>().enabled = _showControlPoints;
			arr[i] = _controlPoints[i].localPosition;
		}
        
		_buffer.SetData(arr);
		GetComponent<Renderer>().material.SetBuffer("_controlPoints", _buffer);
   	}

    // Draw visuals for the connectors between
    // the grab points
	void OnDrawGizmos()
	{
		Gizmos.color = new Color(1,1,1,0.25f);

		// if we're not running, then don't draw
		// the control point connectors, only the outline
		if( _buffer == null)
		{
			Gizmos.matrix = transform.localToWorldMatrix;
			Gizmos.DrawLine( new Vector3(-1,0,1), new Vector3(1,0,1));
			Gizmos.DrawLine( new Vector3(1,0,1), new Vector3(1,0,-1));
			Gizmos.DrawLine( new Vector3(1,0,-1), new Vector3(-1,0,-1));
			Gizmos.DrawLine( new Vector3(-1,0,-1), new Vector3(-1,0,1));
			return;
		}

		if(_showControlPoints)
		{
			// draw the x lines
			for( int y = 0 ; y < 4 ;y ++)
			{
				for(int x = 1 ; x < 4 ; x ++)
				{
					int index = y * 4 + x;
					
					Vector3 prevPoint = _controlPoints[index-1].position;
					Vector3 point = _controlPoints[index].position;

					Gizmos.DrawLine(prevPoint, point);
				}
			}

			// draw the y lines
			for(int x = 0 ; x < 4 ; x ++)
			{
				for( int y = 1 ; y < 4 ;y ++)
				{
					int index = y * 4 + x;
					
					Vector3 prevPoint = _controlPoints[index-4].position;
					Vector3 point = _controlPoints[index].position;
					
					Gizmos.DrawLine(prevPoint, point);
				}
			}
		}
	}
}
