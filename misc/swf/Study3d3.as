package {
    import flash.display.*;
    import flash.events.Event;
    import flash.utils.Dictionary;
    import five3D.geom.Matrix3D;
    import five3D.geom.Point3D;

    [SWF(backgroundColor="0x000000")]
    public class Study3d3 extends Sprite{
        private var canvas:Sprite;
        private var cubes:Array;
        private var rad:Number;
        private var scrollBar:ScrollBar;

        public function Study3d3(){
            stage.scaleMode = "noScale";
            stage.align = "TL";

            cubes = [];
            cubes.push(new Cube(0, 0, 0, 50));
            cubes.push(new Cube(0, 100, 0, 20));
            cubes.push(new Cube(0, -100, 0, 20));
            cubes.push(new Cube(100, 0, 0, 20));
            cubes.push(new Cube(-100, 0, 0, 20));
            cubes.push(new Cube(0, 0, 100, 20));
            cubes.push(new Cube(0, 0, -100, 20));

            canvas = new Sprite();
            addChild(canvas);
            canvas.x = 200;
            canvas.y = 150;

            scrollBar = new ScrollBar();
            scrollBar.x = scrollBar.y = 30;
            addChild(scrollBar);

            rad = 0;
            addEventListener("enterFrame", changeHandler);
        }

        private function changeHandler(event:Event):void {
            canvas.graphics.clear();

            // ��]�s����쐬
            var matrix:Matrix3D = new Matrix3D();
            matrix.rotateX(Math.PI / 6);
            matrix.rotateY(rad / 180 * Math.PI * 3);
            matrix.rotateZ(rad / 180 * Math.PI);

            // �`��
            for each(var c:Cube in cubes){
                c.draw(canvas.graphics, matrix, 150 + scrollBar.value * 3);
            }

            // �p�x�X�V
            rad = (rad + 1) % 360;
        }
    }
}

import flash.display.*;
import flash.events.Event;
import flash.geom.Point;
import five3D.geom.Point3D;
import five3D.geom.Matrix3D;

class Cube {
    private var points:Array = [];

    public function Cube(x:Number, y:Number, z:Number, len:Number){
        var diff:Function = function(f:Boolean):Number{return f ? len / 2 : -len / 2;};

        // �����̂̒��_�W���쐬����
        for(var i:int = 0; i < 8; i++){
            var p:Point3D = new Point3D(x + diff(i % 4 % 3 == 0),  y + diff(i % 4 < 2), z + diff(i < 4));
            points.push(p);
        }
    }

    public function draw(g:Graphics, matrix:Matrix3D, f:Number):void {
        // ��]��̊e���_�̍��W���v�Z
        var p:Array = [];
        for(var i:int = 0; i < points.length; i++){
            var pt:Point3D = matrix.transformPoint(points[i]);

            // �_�𓧎����e����
            pt.project(pt.getPerspective(f));

            drawPoint(g, pt);
            p.push(pt);
        }

        // ���_�̊Ԃ���Ō���
        for(i = 0; i < 4; i++){
            drawLine(g, p[i], p[i + 4]);
            drawLine(g, p[i], p[(i + 1) % 4]);
            drawLine(g, p[i + 4], p[(i + 1) % 4 + 4]);
        }
    }

    private function drawPoint(g:Graphics, p:Point3D):void {
        g.beginFill(0xffffff);
        g.drawCircle(p.x, p.y, 3);
        g.endFill();
    }

    private function drawLine(g:Graphics, p1:Point3D, p2:Point3D):void {
        g.beginFill(0, 0);
        g.lineStyle(1, 0xffffff);
        g.moveTo(p1.x, p1.y);
        g.lineTo(p2.x, p2.y);
        g.lineStyle();
        g.endFill();
    }
}

class ScrollBar extends Sprite {
    public var value:int;

    public function ScrollBar():void {
        useHandCursor = buttonMode = true;
        graphics.beginFill(0xffffff);
        graphics.lineStyle(0);
        graphics.drawRect(0, -2, 8, 112);
        graphics.endFill();

        var tab:Sprite = new Sprite();
        tab.graphics.beginFill(0xffffff);
        tab.graphics.lineStyle(0);
        tab.graphics.drawRect(-8, 0, 24, 8);
        tab.graphics.endFill();
        tab.y = 0;
        addChild(tab);

        addEventListener("mouseDown", function(event:Event):void {
            stage.addEventListener("mouseMove", mouseMoveHandler);
            stage.addEventListener("mouseUp", mouseUpHandler);
            mouseMoveHandler(event);
        });

        var mouseMoveHandler:Function = function(event:Event):void {
            var p:Point = globalToLocal(new Point(stage.mouseX, stage.mouseY));
            tab.y = Math.min(Math.max(0, p.y), 100);
            value = tab.y;
        }
        var mouseUpHandler:Function = function(event:Event):void {
            value = tab.y;
            dispatchEvent(new Event("change"));
            stage.removeEventListener("mouseMove", mouseMoveHandler);
            stage.removeEventListener("mouseUp", mouseUpHandler);
        }
    }
}