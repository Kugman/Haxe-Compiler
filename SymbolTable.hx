import flixel.system.replay.FrameRecord;
import haxe.display.Display.MetadataTarget;
import haxe.macro.Type.TVar;
import haxe.ds.Map;

enum KindVar{ 
    Tfield; 
    Tstatic;
    Tvar;
    Targ;
}


typedef Record = {_name : String, _type : String, _kind : KindVar, ?_index : Int}

class SymbolTable{

    static var classScopeTable : Array<Record>;
    static var methodScopeTable : Array<Record>;// = [];
    static var indexes : Map<KindVar, Int> = [KindVar.Targ => 0, KindVar.Tvar=> 0, KindVar.Tstatic=> 0, KindVar.Tfield=>0];
    
    function getNextIndex(kind : KindVar) : Int{
        return indexes[kind]++;
    }

    public function define(name : String, type : String, kind : KindVar){
        var rec : Record = {_name: name, _type: type, _kind: kind, _index : 0};
        rec._index = getNextIndex(kind);

        if(kind == KindVar.Tfield || kind == KindVar.Tstatic)
            classScopeTable.push(rec);
        else
            methodScopeTable.push(rec);
    }

    public function constructor(){
        indexes[KindVar.Tfield] = 0;
        classScopeTable = [];
        try{
            while (classScopeTable.length > 0) classScopeTable.pop();
        }catch(e : Any){
            classScopeTable = [];
        }
    }
    
    public function startSubroutineLine(){
        indexes[KindVar.Tvar] = 0;
        indexes[KindVar.Targ] = 0;
        methodScopeTable = [];
        try{
            while (methodScopeTable.length > 0) methodScopeTable.pop();
        }catch(e : Any){
            methodScopeTable = [];
        }
    }

    public function kindOf(name : String) : KindVar{
        for (it in methodScopeTable){
            if(it._name == name)
                return it._kind;
        }
        for (it in classScopeTable){
            if(it._name == name)
                return it._kind;
        }
        return null;
    }

    public function typeOf(name : String) : String{
        for (it in methodScopeTable){
            if(it._name == name)
                return it._type;
        }
        for (it in classScopeTable){
            if(it._name == name)
                return it._type;
        }
        return null;
    }

    public function indexOf(name : String) : Int{
        for (it in methodScopeTable){
            if(it._name == name)
                return it._index;
        }
        for (it in classScopeTable){
            if(it._name == name)
                return it._index;
        }
        return -1;
    }

    public function numOf(kind : KindVar){
        var ret = 0;
        for (it in methodScopeTable){
            if(it._kind == kind)
                ret ++;
        }
        for (it in classScopeTable){
            if(it._kind == kind)
                ret ++;
        }
        return ret;
    }
}
