package away3d.core.raycast.colliders
{

	import away3d.core.base.SubMesh;
	import away3d.core.raycast.data.RayCollisionVO;

	import flash.geom.Point;

	import flash.geom.Vector3D;

	public class AS3TriangleRayCollider extends TriangleRayCollider
	{
		public function AS3TriangleRayCollider() {
			super();
		}

		override protected function evaluateSubMesh( subMesh:SubMesh ):Boolean {

			var i:uint;
			var t:Number;
			var numTriangles:uint;
			var indices:Vector.<uint>;
			var vertices:Vector.<Number>;
			var i0:uint, i1:uint, i2:uint;
			var rx:Number, ry:Number, rz:Number;
			var nx:Number, ny:Number, nz:Number;
			var cx:Number, cy:Number, cz:Number;
			var coeff:Number, v:Number, w:Number;
			var p0x:Number, p0y:Number, p0z:Number;
			var p1x:Number, p1y:Number, p1z:Number;
			var p2x:Number, p2y:Number, p2z:Number;
			var s0x:Number, s0y:Number, s0z:Number;
			var s1x:Number, s1y:Number, s1z:Number;
			var nl:Number, nDotV:Number, D:Number, disToPlane:Number;
			var Q1Q2:Number, Q1Q1:Number, Q2Q2:Number, RQ1:Number, RQ2:Number;

			indices = subMesh.indexData;
			vertices = subMesh.vertexData;
			numTriangles = subMesh.numTriangles;

			for( i = 0; i < numTriangles; ++i ) { // sweep all triangles

				var index:uint = i * 3;

				// evaluate triangle indices
				i0 = indices[ index ] * 3;
				i1 = indices[ index + 1 ] * 3;
				i2 = indices[ index + 2 ] * 3;

				// evaluate triangle vertices
				p0x = vertices[ i0 ];
				p0y = vertices[ i0 + 1 ];
				p0z = vertices[ i0 + 2 ];
				p1x = vertices[ i1 ];
				p1y = vertices[ i1 + 1 ];
				p1z = vertices[ i1 + 2 ];
				p2x = vertices[ i2 ];
				p2y = vertices[ i2 + 1 ];
				p2z = vertices[ i2 + 2 ];

				// evaluate sides and triangle normal
				s0x = p1x - p0x; // s0 = p1 - p0
				s0y = p1y - p0y;
				s0z = p1z - p0z;
				s1x = p2x - p0x; // s1 = p2 - p0
				s1y = p2y - p0y;
				s1z = p2z - p0z;
				nx = s0y * s1z - s0z * s1y; // n = s0 x s1
				ny = s0z * s1x - s0x * s1z;
				nz = s0x * s1y - s0y * s1x;
				nl = Math.sqrt( nx * nx + ny * ny + nz * nz ); // normalize n
				nx /= nl;
				ny /= nl;
				nz /= nl;

				// -- plane intersection test --
				nDotV = nx * localRayDirection.x + ny * + localRayDirection.y + nz * localRayDirection.z; // rayDirection . normal
				if( nDotV < 0 ) { // an intersection must exist
					// find collision t
					D = -( nx * p0x + ny * p0y + nz * p0z );
					disToPlane = -( nx * localRayPosition.x + ny * localRayPosition.y + nz * localRayPosition.z + D );
					t = disToPlane / nDotV;
					// find collision point
					cx = localRayPosition.x + t * localRayDirection.x;
					cy = localRayPosition.y + t * localRayDirection.y;
					cz = localRayPosition.z + t * localRayDirection.z;
					// collision point inside triangle? ( using barycentric coordinates )
					Q1Q2 = s0x * s1x + s0y * s1y + s0z * s1z;
					Q1Q1 = s0x * s0x + s0y * s0y + s0z * s0z;
					Q2Q2 = s1x * s1x + s1y * s1y + s1z * s1z;
					rx = cx - p0x;
					ry = cy - p0y;
					rz = cz - p0z;
					RQ1 = rx * s0x + ry * s0y + rz * s0z;
					RQ2 = rx * s1x + ry * s1y + rz * s1z;
					coeff = 1 / ( Q1Q1 * Q2Q2 - Q1Q2 * Q1Q2 );
					v = coeff * ( Q2Q2 * RQ1 - Q1Q2 * RQ2 );
					w = coeff * ( -Q1Q2 * RQ1 + Q1Q1 * RQ2 );
					if( v < 0 ) continue;
					if( w < 0 ) continue;
					if( !( 1 - v - w < 0 ) ) { // all tests passed
						var collisionVO:RayCollisionVO = new RayCollisionVO();
						collisionVO.nearT = t;
						collisionVO.localRayPosition = localRayPosition;
						collisionVO.localRayDirection = localRayDirection;
						collisionVO.position = new Vector3D( cx, cy, cz );
						setCollisionDataForItem( _targetMesh, collisionVO );
						return true; // does not search for closest collision, first found will do... // TODO: add option of finding best tri hit? on a different collider?
					}
				}
			}
			return false;
		}

		override protected function get collisionNormal():Vector3D {
			return new Vector3D(); // TODO
		}

		override protected function get collisionUV():Point {
			return new Point(); // TODO
		}

		// TODO: provide additional collision data such as UV, etc...
	}
}