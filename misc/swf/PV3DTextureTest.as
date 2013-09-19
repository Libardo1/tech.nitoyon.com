package {
import flash.display.*;
import flash.events.Event;
import flash.utils.ByteArray;
import org.papervision3d.objects.primitives.*;
import org.papervision3d.view.*;
import org.papervision3d.materials.*;
import org.papervision3d.materials.utils.MaterialsList;
import mx.utils.Base64Decoder;

[SWF(backgroundColor="#000000", width="475", height="475")]
public class PV3DTextureTest extends BasicView {
	// �\�����闧����
	private var cube:Cube;

	// �摜�� BASE64 �G���R�[�h��������
	private static var ImageBase64:String = "R0lGODlhEAAQAJkAAOdfEwAAAPDQsAAAACH5BAAAAAAALAAAAAAQABAAAAI2hI4XhgYPXxBxxkqhvTJ33i0fuATm4l1TsnEt8GIymZ5uCiviqFG6ictBEDGhCmeCnZKCZbIAADs=";

	public function PV3DTextureTest(){
		// �摜�����[�h���� BitmapData �ɕϊ�����
		// �ϊ���AloadComplete �֐����Ă΂��
		base64ToBitmapData(ImageBase64, loadComplete);
	}

	private function loadComplete(bmd:BitmapData):void{
		// �\������e�N�X�`�����E��ɕ\��
		addChild(new Bitmap(bmd));

		// BitmapMaterial �� BitmapData ��n��
		var m:BitmapMaterial = new BitmapMaterial(bmd, true);

		// tiled �� true �ɁAmaxU, maxV �ɕ~���l�߂鐔��n��
		m.tiled = true;
		m.maxU = 5;
		m.maxV = 5;

		// Cube �̖ʂɓ\��t����
		cube = new Cube(new MaterialsList({all:m}));
		scene.addChild(cube);

		// �`����J�n����
		startRendering();
	}

	protected override function onRenderTick(e:Event = null):void{
		cube.rotationX += 1;
		cube.rotationY += .8;
		super.onRenderTick(e);
	}

	private function base64ToBitmapData(base64:String, callback:Function):void{
		var decoder:Base64Decoder = new Base64Decoder();
		decoder.decode(base64);

		var bytes:ByteArray = decoder.toByteArray();
		bytes.position = 0;
		var loader:Loader = new Loader();
		loader.loadBytes(bytes);
		var bmd:BitmapData = new BitmapData(16, 16);
		loader.contentLoaderInfo.addEventListener("complete", function(event:Event):void{
			var bmd:BitmapData = new BitmapData(loader.width, loader.height);
			bmd.draw(loader);
			callback(bmd);
		});
	}
}
} 