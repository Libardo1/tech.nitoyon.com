// PV3D �Ŗ^�Q�[����3D�����Ă݂�
// 
// [�V�ѕ�]
// �E�N���b�N�ŃW�����v����
// �E���ꂾ��
package {
import flash.events.Event;
import flash.text.TextField;
import org.papervision3d.view.*;
import caurina.transitions.Tweener;

[SWF(backgroundColor="#000000", width="475", height="475")]
public class MaOio3dTest extends BasicView {
    // character
    private var character:Character;

    // �W�����v���̏��
    private var jump:Boolean;
    private var prevJump:Boolean;

    // �A�j���[�V�����̐ݒ�
    private var animateIndex:int;
    private var animateParams:Array = [
        { x: -700, y: 120, z: -300, focus: 50, time: 6 },
        { x: -70, y: 220, z: -100, focus: 8, time: 4 },
        { x: 300, y: 40, z: -80, focus: 50, time: 5, transition: 'easeInOutSine' },
        { x: 0, y: 0, z: -300, focus: 10, time: 4, transition: 'easeInOutSine' }
    ];

    public function MaOio3dTest(){
        super(475, 475, false);
        stage.scaleMode = "noScale";
        stage.align = "TL";

        // �摜��ϊ�����
        Map.base64ToBitmapData(init);
    }

    private function init():void{
        // �}�b�v�ƃL�����N�^����������
        Map.createMap(scene);
        scene.addChild(character = new Character());

        // �J�����̏����ʒu��ݒ�
        camera.focus = 1000;
        camera.z = -20000;

        var tf:TextField = new TextField();
        tf.textColor = 0xffffff;
        tf.text = "CLICK TO START";
        tf.x = tf.y = 50;
        addChild(tf);

        // �A�j���[�V����
        var initialized:Boolean = false;
        stage.addEventListener("keyDown", function(event:Event):void{jump = true;});
        stage.addEventListener("click", function(event:Event):void{
            if (!initialized){
                // ������
                removeChild(tf);
                startRendering();
                animate();
                initialized = true;
            }

            jump = true;
        });
    }

    // Tweener �𗘗p�����A�j���[�V�������s��
    private function animate():void{
        var param:Object = animateParams[animateIndex];
        param.onComplete = animate;
        param.delay = 2; // �K��2�b��~����
        Tweener.addTween(camera, param);
        animateIndex = (animateIndex + 1) % animateParams.length;
    }

    // BasicView �̕`�揈��
    protected override function onRenderTick(e:Event = null):void{
        super.onRenderTick(e);

        // �L�����N�^�[�̏�Ԃ��X�V����
        if (prevJump && jump){
            jump = false;
        }
        prevJump = jump;
        character.update(jump);
    }
}
}


import flash.display.*;
import flash.events.Event;
import flash.geom.*;
import flash.utils.ByteArray;
import org.papervision3d.objects.primitives.*;
import org.papervision3d.materials.*;
import org.papervision3d.core.proto.*;
import org.papervision3d.objects.*;
import org.papervision3d.objects.primitives.*;
import org.papervision3d.materials.utils.MaterialsList;
import mx.utils.Base64Decoder;

// �L�����N�^ �N���X
class Character extends Plane{
    // �摜�ꗗ
    private var characterImages:Array;

    // �L�����N�^�p�� Sprite
    private var character:Sprite;

    // �\�����
    private var jumping:Boolean;
    private var vy:int;

    // ��l���̎���
    public function Character(){
        super(null, 17, 16);

        // �摜������
        var bmd1:BitmapData = new BitmapData(16, 16, true);
        var bmd2:BitmapData = new BitmapData(17, 16, true);
        bmd1.copyPixels(Map.bmdIcons, new Rectangle(240, 0, 16, 16), new Point());
        bmd2.copyPixels(Map.bmdIcons, new Rectangle(256, 0, 17, 16), new Point());
        bmd1.threshold(bmd1, bmd1.rect, new Point(), "==", 0xffffffff, 0, 0xffffffff); // �w�i����
        bmd2.threshold(bmd2, bmd2.rect, new Point(), "==", 0xffffffff, 0, 0xffffffff);
        characterImages = [new Bitmap(bmd1), new Bitmap(bmd2)];

        // character �ɒǉ�
        character = new Sprite();
        for each (var img:Bitmap in characterImages){
            character.addChild(img);
            img.visible = false;
        }
        setImage(0);

        // Plane �̐ݒ�
        material = new MovieMaterial(character, true, true);
        x = -64;
        y = -40;
        z = -8;
    }

    // ��Ԃ��X�V
    public function update(jump:Boolean):void{
        if (jump && !jumping){
            vy = 9;
            jumping = true;
        }

        if (jumping){
            y += vy;
            if (vy < -8){
                vy = 0;
                jumping = false;
            }
            vy--;
        }
        setImage(jumping ? 1 : 0);
    }

    // �\������摜�i�Î~�E�W�����v���j���X�V����
    private function setImage(num:int):void{
        for (var i:int = 0; i < characterImages.length; i++){
            characterImages[i].visible = (num == i);
        }
    }
}

// �}�b�v�f�[�^
class Map{
    // �}�b�v�̎�ނ��`
    private static var mapTypeIndex:int = 0;
    private static const SKY:int = 0;   // Sky
    private static const GRD:int = 1;   // Ground
    private static const BLQ:int = 2;   // Block question
    private static const MT0:int = 3;   // Mountain left
    private static const MT1:int = 4;   // Mountain top
    private static const MT2:int = 5;   // Mountain right
    private static const MT3:int = 6;   // Mountain with tree
    private static const MT4:int = 7;   // Mountain background
    private static const BU0:int = 8;   // Bush left
    private static const BU1:int = 9;   // Bush mid
    private static const BU2:int = 10;  // Bush right
    private static const CL0:int = 11;  // Cloud left top
    private static const CL1:int = 12;  // Cloud mid top
    private static const CL2:int = 13;  // Cloud right top
    private static const CL3:int = 14;  // Cloud left bottom

    // �摜�� BASE64 ����������
    private static const Icons:String = "R0lGODlhEQEQALMLAP/////Mmf+ZM/9mAP8zAMz/AJlmAGaZ/zPM/wCZAAAAAP///wAAAAAAAAAAAAAAACH5BAEAAAsALAAAAAARARAAAAT/8MhJ6xkh66ywHtcgjuRonZOCoupaJXAsx8ps325+KHyr/0BXD0AsGo+Alm+1aDoJ0KhzSqUKroLgIVAaKbjeAXZMvi6FCW3ivLrNeu64tqIo2AvsuZ6F7CNVCkk5VFGFUlWGBAtjWmBdXyQdAgplY5R5FjVpQTCYL3GdPKA4ejx3d557e4F+rUWsqQdUBrQGV7ZVTYmFV41dIpBhYyVksTsxap06o2uizDKlp6eAqtUUrthG1ChTtAK2t1hVteC25L6/Xx3AYlfAPCKWOZowycoucaJwz8hzddKo8FhTxSObwSSCTnQzB+6bOCfeGpajhe7RgB7rsABzdxFLKnr1/zjJSJVPE0h+0aQlkGZsIJ2DMBNaWNjwW61ZDLFIrFjiywZJHCkJ2GhmxclNQGx4KsmPVJB/BWDcWYnKpRZWMbNhqlJJwDhvOskt4BnJ0cV2Zih58cjC6Y8bmJg2nXF1KsBpVq9mxeYJpwECN3M16WqgCVkvZoEOu8iDbSY39t6cmDv3R4+7mAXuKNVDL4AD2BDwdUHzLy3AtCCSM326sOEgZstGQquxozw6ckTCtUC5qQ6ome8C0gwEq0zLREADEH2E+WhuTVYXEru6Fuq/Cyg+XSd7dqXGt1OAiqz0U29m84Kr/9dyh3Ei7SWwOoCgfpH69u/72Tr4FgEBUABYk/hN5BiSnQGNBAAPYj3RxlEZSxxFl25uLHHeMzmop6Ed2xi132bIGYEffsuN2AoT/V2RSCVR/PVfgKj5wkEPsZ1VBlGOHTMKebtJcCF6LAC3YWZ1fNRKIO0NcZ9zJTKpTV8p7vKfV7e4KKV2QDiiQTDeCeWRl5fIhyEFGPFgHigt/LjjCUIOuZ4QSDgZ3w5/7AdfLIRIUUhpUsYI2yOxwdMVhDoCuc9IZh7Ajwpqjsemm256glV+y2njD1aAGGdmooOollp0gRWYCBVaMIYRBmV2kOqqGDXlDJoSVthobo9C+iYfRDh5xJwpcOqer0B4+umBN6VmYC4RAAA7";
    public static var bmdIcons:BitmapData;

    // �}�b�v�z�u
    private static const map:Array = [
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, MT0, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, MT0, MT3, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, MT1, MT3, MT4, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, MT2, MT3, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, MT2, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, GRD, GRD],
        [SKY, SKY, SKY, CL1, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, GRD, GRD],
        [SKY, SKY, CL0, CL2, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, GRD, GRD],
        [SKY, SKY, SKY, CL3, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, BU0, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, BU1, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, BU1, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, BU2, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, BLQ, SKY, SKY, MT0, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, MT1, MT3, GRD, GRD],
        [SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, SKY, MT2, GRD, GRD]
    ];

    private static var materialCache:Object = {};

    // �w�肵���^�C�v�̃}�e���A�����擾����B
    public static function getMaterial(mapType:int):MaterialObject3D{
        if (materialCache[mapType]) return materialCache[mapType];

        var bmd:BitmapData = new BitmapData(16, 16);
        bmd.copyPixels(bmdIcons, new Rectangle(mapType * 16, 0, 16, 16), new Point());
        materialCache[mapType] = new BitmapMaterial(bmd);
        return materialCache[mapType];
    }

    // scene �Ƀ}�b�v��ǉ�����
    public static function createMap(scene:DisplayObjectContainer3D):void{
        for (var xx:int = 0; xx < map.length; xx++){
            for (var yy:int = 0; yy < map[yy].length; yy++){
                var material:MaterialObject3D = getMaterial(map[xx][yy]);

                var obj:DisplayObject3D;
                if (map[xx][yy] == GRD || map[xx][yy] == BLQ){
                    obj = new Cube(new MaterialsList({all: material}), 16, 16, 16);
                    obj.z = -8;
                } else {
                    obj = new Plane(material, 16, 16);
                    obj.z = 0;
                }
                obj.x = xx * 16 - 8 - 128;
                obj.y = -yy * 16 + 8 + 128;
                scene.addChild(obj);
            }
        }
    }

    // BASE64 ������
    public static function base64ToBitmapData(callback:Function):void{
        var decoder:Base64Decoder = new Base64Decoder();
        decoder.decode(Icons);

        var bytes:ByteArray = decoder.toByteArray();
        bytes.position = 0;
        var loader:Loader = new Loader();
        loader.loadBytes(bytes);
        loader.contentLoaderInfo.addEventListener("complete", function(event:Event):void{
            bmdIcons = new BitmapData(loader.width, loader.height);
            bmdIcons.draw(loader);
            callback();
        });
    }
}