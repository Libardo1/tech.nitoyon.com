package {
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.geom.*;
	import flash.utils.setInterval;
	import com.google.maps.*;
	import com.google.maps.controls.*;
	import caurina.transitions.Tweener;

	public class GoogleMapsLayer extends Sprite {
		private const WIDTH:int = 400;
		private const HEIGHT:int = 300;
		private var maps:Array = [];

		public function GoogleMapsLayer() {
			super();
			stage.scaleMode = "noScale";
			stage.align = "TL";

			for(var i:int = 0; i < 2; i++){
				initMap(i);
			}
		}

		private function initMap(i:int):void{
			var map:Map = new Map();
			map.key = "ABQIAAAA6de2NwhEAYfH7t7oAYcX3xRWPxFShKMZYAUclLzloAj2mNQgoRQZnk8BRyG0g_m2di3bWaT-Ji54Lg";
			map.setSize(new Point(WIDTH, HEIGHT));
			map.addEventListener(MapEvent.MAP_READY, function(event:Event):void{
				map.setCenter(new LatLng(35.003759, 135.769322), 4, 
					i != 0 ? MapType.NORMAL_MAP_TYPE : MapType.SATELLITE_MAP_TYPE);
				map.addEventListener("mapevent_movestep", changeHandler);
				map.addEventListener("mapevent_moveend", changeHandler);
				map.addEventListener("mapevent_zoomend", changeHandler);

				var topRight:ControlPosition = new ControlPosition(ControlPosition.ANCHOR_TOP_LEFT, 10, 10);
				var c:ZoomControl = new ZoomControl();
				map.addControl(c);
				c.setControlPosition(topRight);

			});
			addChild(map);
			maps.push(map);

			if(i == 1){
				var m:Sprite = new Sprite();
				addChild(m);
				map.mask = m;
				map.cacheAsBitmap = m.cacheAsBitmap = true;
				startMaskAnimation(m);
			}
		}

		// sync position
		private function changeHandler(event:Event):void{
			if(maps.length != 2) return;

			var me:Map = event.target as Map;
			var other:Map = (me == maps[0] ? maps[1] : maps[0]) as Map;
			if(!me.getCenter().equals(other.getCenter())){
				other.setCenter(me.getCenter());
			}
			if(me.getZoom() != other.getZoom()){
				other.setZoom(me.getZoom());
			}
		}

		private function startMaskAnimation(m:Sprite):void{
			setInterval(function():void{
				var s:Sprite = new Sprite();
				s.x = Math.random() * WIDTH;
				s.y = Math.random() * HEIGHT;
				m.addChild(s);

				var r:int = Math.random() * 300 + 50;
				if(Math.random() < 0.5){
					s.graphics.lineStyle(20, 0, 1, false, "none");
					s.graphics.drawCircle(0, 0, 5);
				}
				else{
					s.graphics.lineStyle(20, 0, 1, false, "none", null, "miter");
					s.graphics.drawRect(-5, -5, 10, 10);
					s.graphics.endFill();
				}
				s.rotation = Math.random() * 180;

				Tweener.addTween(s, {
					time: 5,
					_scale: Math.random() * 40 + 10,
					alpha: 0,
					rotation: Math.random() * 180,
					onComplete: function():void{
						m.removeChild(s);
					}
				});
			}, 500);
		}
	}
}