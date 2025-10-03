
import openfl.utils.Object;
import haxe.ds.Map;
import SymbolTable;
import sys.io.FileOutput;
import haxe.io.Input;


class Parsing {
    static var command = ["do", "let" ];
    static var st2 = ["if", "while"];
    static var st3 = ["constructor", "function", "method"];
    static var vrs = ["field", "static"];
    static var binOp = ["+", "-", "*", "/", "&", "|", "<", ">", "="];
    static var unaryOp =["~","-"];
    static var keywordConstant = ["true", "false", "null", "this"];
    static var type = ["int", "char", "boolean", "void"];
    
    static var token : Iterator<Xml>;
    static var curTok : Xml;
    static var className : String;
    static var funcType : String;
    static var symbolTable : SymbolTable;
    static var lableIndex : Map<String, Int> = ["if" => 0, "while" => 0];
    static var output : String;

    static function getNextToken() : Xml{
        var c = curTok;
        curTok = token.next();
        return c;
    }

    static function initIndexLable(){
        lableIndex["if"] = 0;
        lableIndex["while"] = 0;
    }

    static function verifyName(xml : Xml, comp : String){
        if(xml.nodeName.toLowerCase() != comp.toLowerCase())
            throw "EXPECTED: " + comp + " GOT: " + xml.firstChild().nodeValue;
    }

    static function verifyValue(xml : Xml, comp : String){
        if(xml.firstChild().nodeValue.toLowerCase() != comp.toLowerCase())
            throw "EXPECTED: " + comp + " GOT: " + xml.firstChild().nodeValue;
    }

    static function verifyBinOp(xml : Xml){
        if(binOp.indexOf(xml.firstChild().nodeValue) < 0)
            throw "EXPECTED: bin operation. GOT: " + xml.firstChild().nodeValue;
    }

    static function verifyUnaryOp(xml : Xml){
        if(unaryOp.indexOf(xml.firstChild().nodeValue) < 0)
            throw "EXPECTED: unary operation. GOT: " + xml.firstChild().nodeValue;
    }

    static function verifyKeywordConstant(xml : Xml){
        if(keywordConstant.indexOf(xml.firstChild().nodeValue) < 0)
            throw "EXPECTED: keyword constant. GOT: " + xml.firstChild().nodeValue;
    }

    public static function parsing(input : Input) : String{
        var rootXml = Xml.parse(input.readAll().toString());
        token = rootXml.firstElement().elements();
        curTok = token.next();
        output = "";
        try{
            parsingClass();
        }
        catch(e : String){
            trace(e);
        }catch(e : Any){
            trace(output);
        }        
        return output;
    }

    static function parsingClass(){
        initIndexLable();
        verifyValue(getNextToken(), "class");
        symbolTable.constructor();
        className = curTok.firstChild().nodeValue;
        verifyName(getNextToken(), "identifier");
        verifyValue(getNextToken(), "{");
        while(vrs.indexOf(curTok.firstChild().nodeValue) >= 0)
            parsingVarDec();
        while (st3.indexOf(curTok.firstChild().nodeValue) >= 0) 
            parsingSubRoutineDec();
        verifyValue(getNextToken(), "}");
    }

    static function addVar(name : String, type : String, kind : String){
        var k  = KindVar.Tfield;
        if(kind == "static") k = KindVar.Tstatic;
        else if(kind == "argument") k = KindVar.Targ;
        else if(kind == "var") k = KindVar.Tvar;
        symbolTable.define(name, type, k);
    }

    static function parsingVarDec(){
        var kind = getNextToken().firstChild().nodeValue;
        var type = getNextToken().firstChild().nodeValue;
        var name = curTok.firstChild().nodeValue;
        verifyName(getNextToken(), "identifier");  
        addVar(name, type, kind);
        while(curTok.firstChild().nodeValue == ","){
            verifyValue(getNextToken(), ",");
            name = curTok.firstChild().nodeValue;
            verifyName(getNextToken(), "identifier");
            addVar(name, type, kind);
        }
        verifyValue(getNextToken(), ";");
    }

    static function funcVar(){
        if(funcType == "method"){
            addVar("this", className, "argument");
        }
    }

    static function initFunc(){
        if(funcType == "constructor"){
            var numField = symbolTable.numOf(KindVar.Tfield);
            output += "push constant " + numField + "\n";
            output += "call Memory.alloc 1"+"\n";
            output += "pop pointer 0"+"\n";//THIS
        }else if(funcType == "method"){
            output += "push argument 0"+"\n";
            output += "pop pointer 0"+"\n";
        }
    }

    static function parsingSubRoutineDec(){
        symbolTable.startSubroutineLine();
        funcType = curTok.firstChild().nodeValue;
        getNextToken();
        funcVar();
        output += "function " + className + ".";
        var ret = curTok.firstChild().nodeValue;
        getNextToken();
        output += curTok.firstChild().nodeValue + " ";
        verifyName(getNextToken(), "identifier");
        verifyValue(getNextToken(), "(");
        var n = parsingParameterList();
        output += n + "\n";
        verifyValue(getNextToken(), ")");
        initFunc();
        parsingSubroutineBody();
    }

    static function parsingParameterList() : Int{
        var n = 0;
        if(curTok.firstChild().nodeValue != ")"){
            var typ = curTok.firstChild().nodeValue;
            getNextToken();
            var nam = curTok.firstChild().nodeValue;
            verifyName(getNextToken(), "identifier");
            addVar(nam, typ, "argument");
            n++;
        }       
        while(curTok.firstChild().nodeValue == ","){
            verifyValue(getNextToken(), ",");
            var typ = curTok.firstChild().nodeValue;
            getNextToken();
            var nam = curTok.firstChild().nodeValue;
            verifyName(getNextToken(), "identifier");
            addVar(nam, typ, "argument");
            n++;
        }
        return n;
    }

    static function parsingSubroutineBody(){
        verifyValue(getNextToken(), "{");
        while(curTok.firstChild().nodeValue == "var"){
            parsingVarDec();
        }
        parsingStatements();
        verifyValue(getNextToken(), "}");
    }

    static function parsingStatements(){
        while(curTok.firstChild().nodeValue != "}"){
            switch (curTok.firstChild().nodeValue.toLowerCase()){
                case "let": parsingLetStatement();
                case "while": parsingWhileStatement();
                case "return": parsingReturnStatement();
                case "do": parsingDoStatement();
                case "if": paresingIfStatement();              
                default: break;
            }
        }
    }

    static function popVar(varName : String){
        var kind = symbolTable.kindOf(varName).getName().substring(1);
        var index = symbolTable.indexOf(varName);
        if(kind == "var") kind = "local";
        else if(kind == "field") kind = "this";
        else if(kind == "arg") kind = "argument";
        output += "pop " + kind + " " + index + "\n";
    }

    static function pushVar(varName : String){
        var kind = symbolTable.kindOf(varName).getName().substring(1);
        var index = symbolTable.indexOf(varName);
        if(kind == "var") kind = "local";
        else if(kind == "field") kind = "this";
        else if(kind == "arg") kind = "argument";
        output += "push " + kind + " " + index + "\n";
    }

    static function parsingLetStatement(){
        verifyValue(getNextToken(), "let");
        var nm = curTok.firstChild().nodeValue;
        verifyName(getNextToken(), "identifier");
        if(curTok.firstChild().nodeValue == "["){ //varName[expression]
            verifyValue(getNextToken(),"[");
            parsingExpression();
            verifyValue(getNextToken(), "]");
            pushVar(nm);
            output += "add\n";
            verifyValue(getNextToken(), "=");
            parsingExpression();
            verifyValue(getNextToken(), ";");
            output += "pop temp 0\n";
            output += "pop pointer 1\n";
            output += "push temp 0\n";
            output += "pop that 0\n";            
        }else{
            verifyValue(getNextToken(), "=");
            parsingExpression();
            verifyValue(getNextToken(), ";");

            popVar(nm);
        }

    }

    static function parsingWhileStatement(){
        verifyValue(getNextToken(), "while");
        var index = lableIndex["while"]++;
        output += "label WHILE_EXP" +  index + "\n";
        verifyValue(getNextToken(), "(");
        parsingExpression();
        verifyValue(getNextToken(), ")");
        output += "not\n";
        output += "if-goto WHILE_END" + index + "\n";
        verifyValue(getNextToken(), "{");
        parsingStatements();
        output += "goto WHILE_EXP" + index + "\n";
        verifyValue(getNextToken(), "}");
        output += "label WHILE_END" + index + "\n";
    }

    static function parsingReturnStatement(){
        verifyValue(getNextToken(), "return");
        if(curTok.firstChild().nodeValue != ";")
            parsingExpression();
        else
            output += "push constant 0\n";
        verifyValue(getNextToken(), ";");
        output += "return\n";
    }

    static function parsingDoStatement(){
        var obName = className, funcName;
        verifyValue(getNextToken(), "do");
        funcName = curTok.firstChild().nodeValue;
        verifyName(getNextToken(), "identifier");
        if(curTok.firstChild().nodeValue == "."){
            obName = funcName;
            verifyValue(getNextToken(), ".");
            funcName = curTok.firstChild().nodeValue;
            verifyName(getNextToken(), "identifier");
            if(obName.charAt(0) == obName.charAt(0).toLowerCase()){
                pushVar(obName);
                obName = symbolTable.typeOf(obName);
            }
        }else{
            output += "push pointer 0\n";
        }
        verifyValue(getNextToken(), "(");
        var n = parsingExpressionList();  
        verifyValue(getNextToken(), ")");
        verifyValue(getNextToken(), ";");
        output += "call " + obName + "." + funcName + " " + n + "\n";
        output += "pop temp 0\n";
    }

    static function paresingIfStatement(){
        var index = lableIndex["if"]++;
        verifyValue(getNextToken(), "if");
        verifyValue(getNextToken(), "(");
        parsingExpression();  
        verifyValue(getNextToken(), ")");
        output += "if-goto IF_TRUE" + index + "\n";
        output += "goto IF_FALSE" + index + "\n";
        output += "label IF_TRUE" + index + "\n";
        verifyValue(getNextToken(), "{");
        parsingStatements();
        verifyValue(getNextToken(), "}");
        if(curTok.firstChild().nodeValue == "else"){
            verifyValue(getNextToken(), "else");
            output += "goto IF_END"+ index + "\n";
            output += "label IF_FALSE" + index + "\n";
            verifyValue(getNextToken(), "{");
            parsingStatements();
            verifyValue(getNextToken(), "}");
            output += "label IF_END" + index + "\n";
        }else{
            output += "label IF_FALSE" + index + "\n";
        }
    }

    static function parsingExpression(){
        parsingTerm();
        while(binOp.indexOf(curTok.firstChild().nodeValue) >= 0){
            var op = curTok.firstChild().nodeValue;
            verifyBinOp(getNextToken());
            if(op == "*"){
                parsingTerm();
                output += "call Math.multiply 2\n";
            }else if(op == "/"){
                parsingTerm();
                output += "call Math.divide 2\n";
            }else if(op == "+"){
                parsingTerm();
                output += "add\n";
            }else if(op == "-"){
                parsingTerm();
                output += "sub\n";
            }else if(op == "&"){
                parsingTerm();
                output += "and\n";
            }else if(op == "|"){
                parsingTerm();
                output += "or\n";
            }else if(op == "<"){
                parsingExpression();
                output += "lt\n";
            }else if(op == ">"){
                parsingExpression();
                output += "gt\n";
            }else if(op == "="){
                parsingExpression();
                output += "eq\n";
            }
            
        }
    }

    static function parsingExpressionList() : Int{
        var n = 0;
        if(curTok.firstChild().nodeValue != ")"){
            parsingExpression();
            n ++;
        }
        while(curTok.firstChild().nodeValue != ")"){
            verifyValue(getNextToken(), ",");
            parsingExpression();
            n++;
        }
        return n;
    }

    static function parsingTerm(){
        if(curTok.nodeName == "StringConstant"){
            var sVal = curTok.firstChild().nodeValue;
            verifyName(getNextToken(), "stringconstant");
            var l = sVal.length;
            output += "push constant " + l + "\n";
            output += "call String.new 1\n";
            for (i in 0...l){
                output += "push constant " + StringTools.fastCodeAt(sVal, i) + "\n";
                output += "call String.appendChar 2\n";
            }
        }
        else if(curTok.nodeName == "integerConstant"){
            var varInt = curTok.firstChild().nodeValue;
            verifyName(getNextToken(), "integerconstant");
            output += "push constant "+ varInt +"\n";
        }
        else if(curTok.nodeName == "keyword"){
            var val = curTok.firstChild().nodeValue;
            verifyKeywordConstant(getNextToken());
            if(val == "true"){
                output += "push constant 0\n";
                output += "not\n";
            }else if(val == "false" || val == "null"){
                output += "push constant 0\n";
            }else if(val == "this"){
                output += "push pointer 0\n";
            }
        }
        else if(curTok.firstChild().nodeValue == "("){
            verifyValue(getNextToken(), "(");
            parsingExpression();
            verifyValue(getNextToken(), ")");
        }else if(curTok.nodeName == "symbol"){//UnaryOp term
            var op = curTok.firstChild().nodeValue;
            verifyUnaryOp(getNextToken());
            parsingTerm();
            if(op == "-"){
                output += "neg\n";
            }else if(op == "~"){
                output += "not\n";
            }
        }else{
            var obName = className, iden = "";
            if(curTok.nodeName == "identifier"){
                iden = curTok.firstChild().nodeValue;
                verifyName(getNextToken(), "identifier");
                if(curTok.firstChild().nodeValue == "["){
                    verifyValue(getNextToken(),"[");
                    parsingExpression();
                    verifyValue(getNextToken(), "]");
                    pushVar(iden);
                    output += "add\n";
                    output += "pop pointer 1\n";
                    output += "push that 0\n";
                    return;
                }else if(curTok.firstChild().nodeValue == "."){
                    verifyValue(getNextToken(), ".");
                    obName = iden;
                    iden = curTok.firstChild().nodeValue;
                    verifyName(getNextToken(), "identifier");
                    if(obName.charAt(0) == obName.charAt(0).toLowerCase()){
                        pushVar(obName);
                        obName = symbolTable.typeOf(obName);
                    }
                }
                else if(curTok.firstChild().nodeValue != "("){
                    pushVar(iden);
                    return;
                }
            }
            verifyValue(getNextToken(), "(");
            var n = parsingExpressionList();
            verifyValue(getNextToken(), ")");
            output += "call " + obName + "." + iden + " " + n + "\n";
        }
    }
}
