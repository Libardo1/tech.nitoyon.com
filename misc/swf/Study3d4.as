package {
	import flash.display.*;
	import flash.utils.Dictionary;
	import five3D.geom.Matrix3D;
	import five3D.geom.Point3D;

	[SWF(backgroundColor="0x000000")]
	public class Study3d4 extends Sprite{
		private var canvas:Sprite;
		private var cubes:Array;
        private var rad:Number;

		public function Study3d4(){
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

            rad = 0;
            changeHandler(null);
            addEventListener("enterFrame", changeHandler);
		}

		private function changeHandler(event:Object):void {
			canvas.graphics.clear();

            // ��]�s����쐬
            var matrix:Matrix3D = new Matrix3D();
            matrix.rotateX(Math.PI / 6);
            matrix.rotateY(rad / 180 * Math.PI * 3);
            matrix.rotateZ(rad / 180 * Math.PI);

			// ���ꂼ��̗����̂̒��S��Z���W���擾����
			var dic:Dictionary = new Dictionary();
			for each(var c:Cube in cubes){
				var center:Point3D = matrix.transformPoint(c.center);
				dic[c] = center.z;
			}

			// Z�\�[�g (���̂��̂��珇�Ԃɕ��ׂ�)
			cubes.sort(function(a:Cube, b:Cube):Number {
				return dic[b] - dic[a];
			});

			// ������`��
			for each(c in cubes){
				c.draw(canvas.graphics, matrix, 200);
			}

           // �p�x�X�V
            rad = (rad + 1) % 360;
 		}
	}
}

import flash.display.Graphics;
import flash.geom.Point;
import flash.utils.Dictionary;
import five3D.geom.Point3D;
import five3D.geom.Matrix3D;

class Cube {
	private var points:Array = [];
	private var _center:Point3D;

	public function get center():Point3D {
		return _center;
	}

	public function Cube(x:Number, y:Number, z:Number, len:Number){
		_center = new Point3D(x, y, z);

		var diff:Function = function(f:Boolean):Number{return f ? len / 2 : -len / 2;};

        // �����̂̒��_�W���쐬����
        for(var i:int = 0; i < 8; i++){
            var p:Point3D = new Point3D(x + diff(i % 4 % 3 == 0),  y + diff(i % 4 < 2), z + diff(i < 4));
            points.push(p);
        }
	}

	public function draw(g:Graphics, matrix:Matrix3D, f:Number):void {
		// ��]��̍��W���v�Z
		var p:Array = [];
		for(var i:int = 0; i < points.length; i++){
			var pt:Point3D = matrix.transformPoint(points[i]);
			p.push(pt);
		}

		// �ʂ̈ꗗ
		var planes:Array = [
			[p[0], p[1], p[2], p[3]],
			[p[7], p[6], p[5], p[4]],
			[p[0], p[4], p[5], p[1]],
			[p[1], p[5], p[6], p[2]],
			[p[2], p[6], p[7], p[3]],
			[p[3], p[7], p[4], p[0]]
		];

		// �ʂ̒��S��Z���W�����߂�
		var z:Dictionary = new Dictionary();
		for(i = 0; i < planes.length; i++){
			z[planes[i]] = (planes[i][0].z + planes[i][1].z + planes[i][2].z + planes[i][3].z) / 4;
		}

		// Z�\�[�g (���̂��̂��珇�Ԃɕ��ׂ�)
		planes.sort(function(a:Array, b:Array):Number {
			return z[b] - z[a];
		});

		// �����珇�Ԃɖʂ�`��
		for each(var plane:Array in planes){
			drawPlane(g, plane[0], plane[1], plane[2], plane[3]);
		}
	}

	private function drawPlane(g:Graphics, p1:Point3D, p2:Point3D, p3:Point3D, p4:Point3D):void {
		// �P�ʖ@���x�N�g��
		var v1:Point3D = p2.subtract(p1);
		var v2:Point3D = p4.subtract(p1);
		var n:Point3D = cross(v1, v2);
		n.normalize(1);

		// �����̕����x�N�g���Ƃ̓���
		var l:Point3D = new Point3D(0, 0, -1);
		var product:Number = n.dot(l);

		// �������e���ʂ�h��
		var b:int = 0x3f * product + 0xc0;
		g.beginFill(b * 0x10000 + b * 0x100 + b, 0.6);
		g.lineStyle(0, 0x666666);
		var p:Point3D;
		p = p1.clone(); p.project(p.getPerspective(500)); g.moveTo(p.x, p.y);
		p = p2.clone(); p.project(p.getPerspective(500)); g.lineTo(p.x, p.y);
		p = p3.clone(); p.project(p.getPerspective(500)); g.lineTo(p.x, p.y);
		p = p4.clone(); p.project(p.getPerspective(500)); g.lineTo(p.x, p.y);
		g.endFill();
	}
}

// �O��
function cross(p1:Point3D, p2:Point3D):Point3D {
	return new Point3D(p1.y * p2.z - p1.z * p2.y,
	                   p1.z * p2.x - p1.x * p2.z,
	                   p1.x * p2.y - p1.y * p2.x);
}
