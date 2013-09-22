package {
    import flash.display.*;
    import flash.filters.*;
    import flash.geom.*;

    [SWF(width="256", height="410")]
    public class Histogram3 extends Sprite {
        [Embed(source="kunimi.jpg")]
        private var SampleImage:Class;

        private var dragging:Sprite;
        private var h2pos:Number = 0.5;
        private var h1:Sprite;
        private var h2:Sprite;
        private var h3:Sprite;

        public function Histogram3() {
            stage.scaleMode = "noScale";

            var bmd:BitmapData = Bitmap(addChild(new SampleImage())).bitmapData;

            var s:Sprite = new Sprite();
            addChild(s).y = bmd.height + 10;
            createHistogram(bmd, s);

            s = new Sprite();
            addChild(s).y = bmd.height + 140;
            createHistogram(bmd, s);

            addChild(createSlider()).y = bmd.height + 115;

            var bmdOrigin:BitmapData = bmd.clone();
            addEventListener("enterFrame", function(e:*):void {
                if(dragging) {
                    var gamma:Number = Math.log((h2.x - h1.x) / (h3.x - h1.x)) / Math.log(0.5);
                    var mapR:Array = [], mapG:Array = [], mapB:Array = [];
                    for(var i:int = 0; i < 0x100; i++) {
                        mapB[i] = i < h1.x ? 0 : i > h3.x ? 0xff : 255 * Math.pow((i - h1.x) / (h3.x - h1.x), 1 / gamma);
                        mapG[i] = mapB[i] << 8;
                        mapR[i] = mapB[i] << 16;
                    }
                    bmd.paletteMap(bmdOrigin, bmd.rect, new Point(), mapR, mapG, mapB);

                    s.graphics.clear();
                    createHistogram(bmd, s);
                }
            });
        }

        // �q�X�g�O�������쐬����
        private function createHistogram(bmd:BitmapData, s:Sprite):void {
            // �O���[�X�P�[����
            var cmf:ColorMatrixFilter = new ColorMatrixFilter(
                [1 / 3, 1 / 3, 1 / 3, 0, 0, 
                 1 / 3, 1 / 3, 1 / 3, 0, 0, 
                 1 / 3, 1 / 3, 1 / 3, 0, 0]
            );
            var bmd2:BitmapData = bmd.clone();
            bmd2.applyFilter(bmd2, bmd2.rect, new Point(), cmf);

            // threshold �ŃJ�E���g
            var values:Array = [];
            for(var i:int = 0; i < 0x100; i++) {
                values[i] = bmd2.threshold(bmd2, bmd2.rect, new Point(), "==", 
                    i + (i << 8) + (i << 16), 0, 0xffffff, false);
            }
            bmd2.dispose();

            // �`��
            var max:int = bmd.width * bmd.height / 50;
            s.graphics.lineStyle(1);
            for(i = 0; i < 0x100; i++) {
                s.graphics.moveTo(i, 100);
                s.graphics.lineTo(i, Math.max(0, 100 - values[i] / max * 100));
            }
        }

        // �X���C�_�[���쐬����
        private function createSlider():Sprite {
            // �X���C�h�\�͈͕`��
            var slider:Sprite = new Sprite();
            slider.graphics.beginFill(0xffffff);
            slider.graphics.drawRect(0, 0, 256, 10);
            slider.graphics.endFill();
            slider.graphics.lineStyle(1, 0);
            slider.graphics.lineTo(255, 0);
            slider.buttonMode = true;
            slider.useHandCursor = true;

            // �܂ݍ쐬
            h1 = Sprite(slider.addChild(createButton(0x000000))); h1.x = 0;
            h2 = Sprite(slider.addChild(createButton(0x999999))); h2.x = 128;
            h3 = Sprite(slider.addChild(createButton(0xffffff))); h3.x = 255;

            // mouseDown
            slider.addEventListener("mouseDown", function(e:*):void {
                var localX:Number = slider.globalToLocal(new Point(mouseX, mouseY)).x;

                // �h���b�O����܂݂����肷��
                var d1:Number = Math.abs(localX - h1.x);
                var d2:Number = Math.abs(localX - h2.x);
                var d3:Number = Math.abs(localX - h3.x);
                var max:Number = Math.min(d1, d2, d3);
                dragging = (max == d1 ? h1 : max == d2 ? h2 : h3);

                // �ꏊ�␳
                var bounds:Rectangle = getDraggableBounds(dragging);
                dragging.x = Math.max(Math.min(localX, bounds.right), bounds.x);
                updateH2(null);

                dragging.startDrag(false, bounds);
            });

            // mouseMove
            stage.addEventListener("mouseMove", updateH2);

            // mouseUp
            stage.addEventListener("mouseUp", function(e:*):void {
                if(dragging) {
                    dragging.stopDrag();
                    dragging = null;
                }
            });

            return slider;
        }

        // �܂݂�`�悷��
        private function createButton(color:int):Sprite {
            var s:Sprite = new Sprite();
            s.graphics.lineStyle(1, 0);
            s.graphics.beginFill(color);
            s.graphics.lineTo(5, 8.6);
            s.graphics.lineTo(-5, 8.6);
            s.graphics.endFill();
            return s;
        }

        // �܂݂̈ړ��\�͈͂��v�Z����
        private function getDraggableBounds(s:Sprite):Rectangle {
            if(s == h1) return new Rectangle(0, 0, h3.x - 4, 0);
            if(s == h2) return new Rectangle(h1.x + 2, 0, h3.x - h1.x - 4, 0);
            if(s == h3) return new Rectangle(h1.x + 4, 0, 255 - h1.x - 4, 0);
            return null;
        }

        // �^�񒆂̂܂݂̈ʒu���v�Z����
        private function updateH2(e:*):void {
            if(dragging && dragging != h2) {
                h2.x = (h3.x - h1.x) * h2pos + h1.x;
                h2.x = Math.max(Math.min(h2.x, h3.x - 2), h1.x + 2);
            }
            else if(dragging == h2){
                h2pos = (h2.x - h1.x) / (h3.x - h1.x);
            }
        }
    }
}