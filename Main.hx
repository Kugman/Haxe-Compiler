import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import Tokenizing;
import Parsing;

class Main {

	// function tokenizing(){

	// }

	static function compile(directory: String) {
		
		if(FileSystem.isDirectory(directory)){
			
			for (file in FileSystem.readDirectory(directory).filter(
				function (v) return StringTools.endsWith(v.toLowerCase(), ".jack")
			)){				
				var path = Path.join([directory, file]);
				var fIn = File.read(path, false);

				trace("File : " + file);
				//tokenizing
				var name = Path.withoutExtension(file) + "T.xml";
				path = Path.join([directory, name]);
				var fOut = File.write(path, false);
				trace("Tokenizing......");
				fOut.writeString(Tokenizing.tokenizing(fIn).toString());
				fOut.close();
				fIn.close();
				//parsing
				fIn = File.read(path, false);
				name = Path.withoutExtension(file) + ".vm";
				path = Path.join([directory, name]);
				fOut = File.write(path, false);
				trace("Parsing......");
				fOut.writeString(Parsing.parsing(fIn).toString());
				fOut.close();
				fIn.close();
				
			}
		}
		else trace("there is no dir:  " + directory);
		
		
	}

	static function main() {

		var directory = "../../../MyLibrary";
		compile(directory);

	}
}
