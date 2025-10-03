import haxe.io.Input;

class Tokenizing{

    public static var symbols = ['(', ')', '{','}', '[', ']', '.', ',', ';', '+', '-', '*', '/', '&', '|', '<', '>', '=', '~'];
    public static var keywords : Array<String> = ["class", "constructor", "function", "method", "field", "static", "var", "int", "char", "boolean", "void", "true", "false", "null", "this", "let", "do", "if", "else", "while", "return"];
    static var ignored = [" ", "\n", "\t"];
    static var integerConstant = {};
    static var StringConstant = {};
    static var identifier = {};

    static var root : Xml;

    static function addXml(type: String, value: String) {
        var xmlElement = Xml.createElement(type);
        xmlElement.addChild(Xml.createPCData(value));
        root.addChild(xmlElement);
    }

    public static function tokenizing(input : Input) : Xml{

        root  = Xml.createElement('tokens');
        var all = input.readAll().toString();
        var index = 0;
        
        while(index < all.length){
            var type = "";
            var value = "";
            if(ignored.indexOf(all.charAt(index)) >= 0){
                index++;
                continue;
            }
            if(all.charAt(index) == '/'){ // comment
                if(all.charAt(index + 1) == '/'){
                    index = all.indexOf('\n', index) + 1;
                    continue;
                }
                else if(all.charAt(index + 1) == '*'){
                    index = all.indexOf("*/", index) + 2;
                    continue;
                }
            }

            if(symbols.indexOf(all.charAt(index)) >= 0){//symbols
                type = "symbol";
                value = all.charAt(index++);
            }
            else if(all.charAt(index) == '"'){//string constant
                var end = all.indexOf('"', ++index);
                value = all.substring(index, end);
                index = end+1;
                type = "StringConstant";
            }
            else if(all.charAt(index) >= "0" && all.charAt(index) <= "9"){//int constant
                do{
                    value += all.charAt(index++);
                }while(all.charAt(index) >= "0" && all.charAt(index) <= "9");
                type = "integerConstant";
            }

            else{
                do{
                    value += all.charAt(index++);
                    if(all.charAt(index) == " ") break;
                    else if(symbols.indexOf(all.charAt(index)) >= 0) break;
                }while(true);

                if(keywords.indexOf(value) >= 0){ //keyword
                    type = "keyword";
                }
                else{//id
                    type = "identifier";
                }
                
            }
            
            addXml(type, value);
        }
        
        return root;        
    }
}
