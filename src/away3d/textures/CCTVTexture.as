package away3d.textures
{
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.View3D;
	import away3d.core.base.Object3D;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	
	public class CCTVTexture extends BitmapTexture
	{
		
		/**
		 * @author desaturate code from Ralph Hauwert
		 */
		private static const ORIGIN : Point = new Point();
		
		/**
		 * Desaturate color vector, by Paul Haeberli
		 *      
		 * http://www.graficaobscura.com/matrix/index.html
		 */
		private static var rl:Number = 0.3086;
		private static var gl:Number = 0.6094;
		private static var bl:Number = 0.0820;
		
		private static var cmf:ColorMatrixFilter = new ColorMatrixFilter([rl,gl,bl,0,0,rl,gl,bl,0, 0,rl,gl,bl,0,0,0,0,0,1,0]);
		
		
		
		private var _matrix:Matrix;
		private var _materialSize:int;
		private var _view:View3D;
		private var _camera:Camera3D;
		private var _cameraTarget:Object3D
		private var _container:Sprite;
		private var _bmd:BitmapData;
		private var _stage3D:Stage3D;
		private var _greyscale:Boolean;
		private var _border:uint;
		private var _clippingRect:Rectangle;
		
		
		public function CCTVTexture(view:View3D, w:int, h:int, container:Sprite, cctvCamera:Camera3D = null, materialSize:int = 256, backgroundColor:uint = 0x000000)
		{
			
			super(new BitmapData(materialSize, materialSize, false, 0));
			
			_border = 0;
			
			_container = container;
			
			_materialSize = materialSize || 128;
			
			_matrix = new Matrix;
			_matrix.scale( materialSize / w, materialSize / h );
			
			_camera = cctvCamera || new Camera3D();
			
			if( !cctvCamera ) PerspectiveLens( _camera.lens ).fieldOfView = 100;
			
			_view = new View3D( view.scene, _camera );
			_view.backgroundColor = backgroundColor;
			_view.x = -w;
			_view.width = w;
			_view.height = h;
			
			_bmd = new BitmapData(w, h, false, 0x000000);
			
			// hack! This only works if the view is added to the display list
			_container.addChild( _view );
			_view.visible = false;
			
			// clipping rect used for border drawing
			_clippingRect = new Rectangle();
			
		}
		
		
		
		public function update():void
		{
			// no context? Bolt!
			if(!_view || !_view.stage3DProxy || !_view.stage3DProxy.context3D) return;
			
			// update the camera target
			if(_cameraTarget) camera.lookAt( _cameraTarget.position );
			
			// render the CCTV view
			_view.renderer.swapBackBuffer = false;
			_view.render();
			
			// Lock and Draw
			// TODO: Access the context3D w/o this ghetto hack!
			bitmapData.lock();
			
			// clear bitmap
			bitmapData.fillRect(bitmapData.rect, 0);
			
			// draw view to temporary bitmap
			_view.stage3DProxy.context3D.drawToBitmapData(_bmd);
			_view.renderer.swapBackBuffer = true;
			
			// update clipping rect to draw borders
			_clippingRect.x = _clippingRect.y = _border;
			_clippingRect.width = bitmapData.width-_border*2;
			_clippingRect.height = bitmapData.height - _border*2;
			
			// draw 
			bitmapData.draw( _bmd, _matrix, null, null, _clippingRect, false );
			
			// apply greyscale
			if(_greyscale) bitmapData.applyFilter(bitmapData, bitmapData.rect, ORIGIN, cmf );
			
			// unlock and invalidate
			bitmapData.unlock();
			invalidateContent();
			
		}
		
		
		override public function dispose():void
		{
			
			_matrix = null;
			_container.removeChild( _view );
			_container.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
			_view.dispose();
			_camera = null;
			_cameraTarget = null
			_bmd.dispose();
			
		}
		
		
		/**
		 * Start auto updates
		 */
		public function start():void
		{
			_container.addEventListener(Event.ENTER_FRAME, autoUpdateHandler, false, 0, true);
		}
		
		/**
		 * Stop auto updates
		 */
		public function stop():void
		{
			_container.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
		}
		
		
		public function get camera():Camera3D
		{
			return _camera;
		}
		
		public function set camera(value:Camera3D):void
		{
			_camera = value;
		}
		
		public function get view():View3D
		{
			return _view;
		}
		
		public function set view(value:View3D):void
		{
			_view = value;
		}
		
		public function get greyscale():Boolean
		{
			return _greyscale;
		}
		
		public function set greyscale(value:Boolean):void
		{
			_greyscale = value;
		}
		
		public function get cameraTarget():Object3D
		{
			return _cameraTarget;
		}
		
		public function set cameraTarget(value:Object3D):void
		{
			_cameraTarget = value;
		}
		
		public function get border():uint
		{
			return _border;
		}
		
		public function set border(value:uint):void
		{
			_border = value;
		}
		
		private function autoUpdateHandler(event : Event) : void
		{
			update();
		}
		
		private function validateMaterialSize( size:uint ):int
		{
			if (!TextureUtils.isDimensionValid(size)) {
				var oldSize : uint = size;
				size = TextureUtils.getBestPowerOf2(size);
				trace("Warning: "+ oldSize + " is not a valid material size. Updating to the closest supported resolution: " + size);
			}
			
			return size;
		}
		
	}
}