// Complex Recursive Descent Parsing
// see also: http://fxp.hp.infoseek.co.jp/arti/parser.html
// 
package{
import flash.display.*;
import flash.events.Event;
import flash.text.*;

[SWF(backgroundColor="#ffffff")]
public class ComplexRecursiveDescentParsing extends Sprite{
    public function ComplexRecursiveDescentParsing(){
        var parser:Parser = new Parser();

        var output:TextField = new TextField();
        output.x = 5; output.y = 40;
        output.autoSize = "left";
        addChild(output);

        var input:TextField = new TextField();
        input.border = true;
        input.x = input.y = 5;
        input.width = 190; input.height = 20;
        input.type = "input";
        input.text = "1 * 4 > 2 && 3 % 2 == 1 ? 100 / 3 : 3";
        input.addEventListener("change", function(event:*):void{
            try{
                output.text = parser.parse(input.text);
                output.textColor = 0x000000;
            }catch(e:Error){
                output.text = e.toString();
                output.textColor = 0xff0000;
            }
        });
        input.dispatchEvent(new Event("change"));
        addChild(input);

        scaleX = scaleY = 2;
        stage.scaleMode = "noScale";
        stage.align = "TL";
    }
}
}

class Parser{
    private var pos:int;
    private var str:String;
    private var m:Array;

    private function Is(fn:Function):Boolean{
        var old_pos:int = pos;
        fn();
        if(pos != old_pos){
            pos = old_pos;
            return true;
        }
        return false;
    }

    public function parse(s:String):String{
        str = s.replace(/ /g, "");
        trace(str);
        pos = 0;
        return ExpressionStatement().toString();
    }

    private function ExpressionStatement():Object{
        return Expression();
    }

    // Expression = AssignmentExpression { , AssignmentExpression }
    private function Expression():Object{
        var ret:Object = AssignmentExpression();
        while(str.charAt(pos) == ","){
            pos++;
            ret = AssignmentExpression();
        }
        return ret;
    }

    // TODO: assignment
    // AssignmentExpression = ConditionalExpression 
    private function AssignmentExpression():Object{
        return ConditionalExpression();
    }

    // ConditionalExpression = LogicalORExpression
    //    | LogicalORExpression ? AssignmentExpression : AssignmentExpression
    private function ConditionalExpression():Object{
        var ret:Object = LogicalORExpression();

        if(str.charAt(pos) == "?"){
            var b:Boolean = Boolean(ret);
            var tmp:Object;
            pos++;
            tmp = AssignmentExpression();
            if(b) ret = tmp;

            if(str.charAt(pos) != ":") throw new Error("Conditional Operator: no :");
            pos++;
            tmp = AssignmentExpression();
            if(!b) ret = tmp;
        }

        return ret;
    }

    // LogicalORExpression = LogicalANDExpression { || LogicalANDExpression }
    private function LogicalORExpression():Object{
        var ret:Object = LogicalANDExpression();
        while(str.substr(pos).match(/^\|\|/)){
            pos += 2;
            ret ||= LogicalANDExpression();
        }
        return ret;
    }

    // LogicalANDExpression = BitwiseORExpression { && BitwiseORExpression }
    private function LogicalANDExpression():Object{
        var ret:Object = BitwiseORExpression();
        while(str.substr(pos, 2) == "&&"){
            pos += 2;
            ret &&= BitwiseORExpression();
        }
        return ret;
    }

    // BitwiseORExpression = BitwiseANDExpression { | BitwiseANDExpression }
    private function BitwiseORExpression():Object{
        var ret:Object = BitwiseXORExpression();
        while(str.substr(pos).match(/^\|[^|]/)){
            pos += 1;
            ret = int(ret) | int(BitwiseXORExpression());
        }
        return ret;
    }

    // BitwiseXORExpression = BitwiseANDExpression { ^ BitwiseANDExpression }
    private function BitwiseXORExpression():Object{
        var ret:Object = BitwiseANDExpression();
        while(str.substr(pos).match(/^\^/)){
            pos += 1;
            ret = int(ret) ^ int(BitwiseANDExpression());
        }
        return ret;
    }

    // BitwiseANDExpression = EqualityExpression { & EqualityExpression }
    private function BitwiseANDExpression():Object{
        var ret:Object = EqualityExpression();
        while(str.substr(pos).match(/^&[^&]/)){
            pos += 1;
            ret = int(ret) & int(EqualityExpression());
        }
        return ret;
    }

    // EqualityExpression = RelationalExpression { (==|!=|===|!==) RelationalExpression }
    private function EqualityExpression():Object{
        var ret:Object = RelationalExpression();

        while((m = str.substr(pos).match(/^(===|!==|==|!=)/))){
            switch(m[1]){
                case "==":  pos += 2; ret = ret ==  RelationalExpression(); break;
                case "!=":  pos += 2; ret = ret !=  RelationalExpression(); break;
                case "===": pos += 3; ret = ret === RelationalExpression(); break;
                case "!==": pos += 3; ret = ret !== RelationalExpression(); break;
            }
        }

        return ret;
    }

    // RelationalExpression = ShiftExpression { (<|>|<=|>=) ShiftExpression }
    private function RelationalExpression():Object{
        var ret:Object = ShiftExpression();

        while((m = str.substr(pos).match(/^(<|>|<=|>=)/))){
            switch(m[1]){
                case "<":  pos += 1; ret = ret <  ShiftExpression(); break;
                case ">":  pos += 1; ret = ret >  ShiftExpression(); break;
                case "<=": pos += 2; ret = ret <= ShiftExpression(); break;
                case ">=": pos += 2; ret = ret >= ShiftExpression(); break;
            }
        }

        return ret;
    }

    // ShiftExpression = AdditiveExpression { (<<|>>|>>>) AdditiveExpression }
    private function ShiftExpression():Object{
        var ret:Object = AdditiveExpression();

        while((m = str.substr(pos).match(/^(<<|>>|>>>)/))){
            switch(m[1]){
                case "<<":  pos += 2; ret = int(ret) << uint(AdditiveExpression()); break;
                case ">>":  pos += 2; ret = int(ret) >> uint(AdditiveExpression()); break;
                case ">>>": pos += 3; ret = uint(ret) >>> uint(AdditiveExpression()); break;
            }
        }

        return ret;
    }

    // AdditiveExpression = MultiplicativeExpression { (+|-) MultiplicativeExpression}
    private function AdditiveExpression():Object{
        var ret:Object = MultiplicativeExpression();

        while((m = str.substr(pos).match(/^(\+|-)/))){
            switch(m[1]){
                case "+": pos++; ret = Number(ret) + Number(MultiplicativeExpression()); break;
                case "-": pos++; ret = Number(ret) - Number(MultiplicativeExpression()); break;
            }
        }

        return ret;
    }

    // MultiplicativeExpression = UnaryExpression { (*|/|%) UnaryExpression}
    private function MultiplicativeExpression():Object{
        var ret:Object = UnaryExpression();

        while((m = str.substr(pos).match(/^(\*|\/|%)/))){
            switch(m[1]){
                case "*": pos++; ret = Number(ret) * Number(UnaryExpression()); break;
                case "/": pos++; ret = Number(ret) / Number(UnaryExpression()); break;
                case "%": pos++; ret = Number(ret) % Number(UnaryExpression()); break;
            }
        }

        return ret;
    }

    // UnaryExpression = (delete|void|typeof|++|--|+|-|~|!) UnaryExpression 
    //   | PostfixExpression
    private function UnaryExpression():Object{
        if((m = str.substr(pos).match(/^(delete|void|typeof|\+\+|--|\+|-|~|!)/))){
            switch(m[1]){
                case "delete": throw new Error("not implemented: delete");
                case "void":   UnaryExpression(); return undefined;
                case "typeof": pos += 6; return typeof UnaryExpression();
                case "++":     throw new Error("not implemented: ++");
                case "--":     throw new Error("not implemented: --");
                case "+":      pos += 1; return Number(UnaryExpression());
                case "-":      pos += 1; return -Number(UnaryExpression());
                case "~":      pos += 1; return ~Number(UnaryExpression());
                case "!":      pos += 1; return !Number(UnaryExpression());
            }
        }
        return PostfixExpression();
    }

    // TODO: Skipped some expressions
    // PostfixExpression = PrimaryExpression 
    private function PostfixExpression():Object{
        return PrimaryExpression();
    }

    // PrimaryExpression = this | Identifier | Literal | ArrayLiteral | ObjectLiteral
    //   | ( Expression )
    private function PrimaryExpression():Object{
        var ret:Object;
        var s:String = str.substr(pos);
        if(s.substr(0, 4) == "this"){
            throw new Error("not implemented: this");
        }
        else if(s.charAt(0) == "("){
            pos++;
            ret = ExpressionStatement();
            if(str.charAt(pos) != ")") throw new Error("No match for )");
            pos++;
            return ret;
        }
        else if(s.charAt(0) == "["){
            throw new Error("not implemented: [ ]");
        }
        else if(s.charAt(0) == "{"){
            throw new Error("not implemented: { }");
        }
        else if(Is(Literal)){
            return Literal();
        }

        throw new Error("invalid format");
    }

    // Literal :: 
    //   NullLiteral 
    //   BooleanLiteral 
    //   NumericLiteral 
    //   StringLiteral 
    private function Literal():Object{
        if(Is(NullLiteral)){
            return NullLiteral();
        }
        if(Is(BooleanLiteral)){
            return BooleanLiteral();
        }
        if(Is(NumericLiteral)){
            return NumericLiteral();
        }
        return null;
    }

    // NullLiteral = null
    private function NullLiteral():Object{
        if(str.substr(pos, 4) == "null"){
            pos += 4;
            return null;
        }
        return undefined;
    }

    // BooleanLiteral = true | false
    private function BooleanLiteral():Object{
        if(str.substr(pos, 4) == "true"){
            pos += 4;
            return true;
        }else if(str.substr(pos, 5) == "false"){
            pos += 5;
            return false;
        }
        return undefined;
    }

    // TODO: HexDigit and ExponentialPart are not supported
    // NumericLiteral
    private function NumericLiteral():Object{
        if((m = str.substr(pos).match(/^([\d\.]+)/))){
            pos += m[1].length;
            return parseFloat(m[1]);
        }
        return undefined;
    }
}