// Parse Node
// see also: http://fxp.hp.infoseek.co.jp/arti/parser.html
package{
import flash.display.*;
import flash.events.Event;
import flash.text.*;

[SWF(backgroundColor="#ffffff")]
public class ParseNode extends Sprite{
    private const THETA:Number = .6;
    private const RATIO:Number = .6;
    private const SIZE:Number = 180;
    private const WIDTH:Number = 15;
    private const CIRCLE_R:Number = 10;
    private var canvas:Sprite;

    public function ParseNode(){
        var parser:Parser = new Parser();

        addChild(canvas = new Sprite());

        var input:TextField = new TextField();
        input.border = true;
        input.x = 10; input.y = 10;
        input.width = 180; input.height = 20;
        input.type = "input";
        input.text = "1*(2+3)+4/5+6+7*(-8+9)";

        input.addEventListener("change", function(event:*):void{
            while(canvas.numChildren) canvas.removeChildAt(0);
            canvas.graphics.clear();

            try{
                var result:Object = parser.parse(input.text)
                draw(result, 100, 500, -Math.PI);
            }catch(e:Error){
            }
        });
        input.dispatchEvent(new Event("change"));
        input.scaleX = input.scaleY = 2;
        addChild(input);

        stage.scaleMode = "noScale";
        stage.align = "TL";
    }

    private function draw(result:Object, x:Number, y:Number, angle:Number, ratio:Number = 1, f:Boolean = false):void{
        canvas.graphics.lineStyle(WIDTH * ratio, 0x994c00, 1, false, "normal", "none");
        canvas.graphics.moveTo(x, y);
        x += SIZE * ratio * Math.sin(angle);
        y += SIZE * ratio * Math.cos(angle);
        canvas.graphics.lineTo(x, y);

        var isBranch = result is Array;
        if(isBranch){
            angle += (Math.random() - .5) * .2;
            if(result.length > 1) draw(result[1], x, y, angle, ratio * RATIO, !f);
            angle += THETA * (f ? 1 : -1)
            if(result.length > 2) draw(result[2], x, y, angle, ratio * RATIO, !f);
        }

        ratio = Math.pow(ratio, .8);
        if(isBranch){
            canvas.graphics.lineStyle(.2 * WIDTH * ratio, 0x994c00);
            canvas.graphics.beginFill(0xffffff);
            canvas.graphics.drawCircle(x, y, CIRCLE_R * ratio);
            canvas.graphics.endFill();
        }else{
            var leaf:Leaf = new Leaf();
            leaf.x = x;
            leaf.y = y;
            leaf.rotation = -angle / Math.PI * 180;
            leaf.scaleX = leaf.scaleY = CIRCLE_R * ratio;
            canvas.addChild(leaf);
        }

        var tf:TextField = new TextField();
        tf.autoSize = "left";
        tf.text = (result is Array ? result[0] : result.toString());
        tf.scaleX = tf.scaleY = ratio * 4;
        tf.x = x;
        tf.y = y - ratio * 8;
        tf.selectable = false;
        canvas.addChild(tf);
    }
}
}

import flash.display.*;

class Leaf extends Sprite{
    public function Leaf(){
        graphics.beginFill(0x006600);
        graphics.drawEllipse(-2, -4, 4, 8);
        graphics.endFill();
    }
}

class Parser{
    private var pos:int;
    private var str:String;

    public function parse(s:String):Object{
        str = s.replace(/ /g, "");
        pos = 0;
        return expr();
    }

    // Expr = Term { (+|-) Term}
    private function expr():Object{
        var ret:Object = term();
        while(true){
            switch(str.charAt(pos)){
                case "+": pos++; ret = ["+", ret, term()]; break;
                case "-": pos++; ret = ["-", ret, term()]; break;
                default:  return ret;
            }
        }
        return 0; // never comes here
    }

    // Term = Fact { (*|/) Fact}
    private function term():Object{
        var ret:Object = fact();
        while(true){
            switch(str.charAt(pos)){
                case "*": pos++; ret = ["*", ret, fact()]; break;
                case "/": pos++; ret = ["/", ret, fact()]; break;
                default:  return ret;
            }
        }
        return 0; // never comes here
    }

    // Fact = ( Expr ) | - Fact | number
    private function fact():Object{
        var ret:Object;
        var m:Array;
        if((m = str.substr(pos).match(/^(\d+)/))){
            pos += m[1].length;
            return parseInt(m[1]);
        }
        else if(str.charAt(pos) == "-"){
            pos++;
            return ["-", fact()];
        }
        else if(str.charAt(pos) == "("){
            pos++;
            ret = ["( )", expr()];
            if(str.charAt(pos) != ")") throw new Error("No match for )");
            pos++;
            return ret;
        }
        throw new Error("invalid format");
    }
}
