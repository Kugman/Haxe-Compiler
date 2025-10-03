# Jack Compiler

A compiler for the **Jack programming language**, implemented in [Haxe](https://haxe.org/).  
Jack is a simple, high-level, object-based language introduced in the **nand2tetris** course, widely taught in computer science programs.  

This project translates Jack source code into VM code (intermediate representation for the Hack computer platform).

## Features
- Full implementation of the Jack compiler
- Written entirely in Haxe
- Produces VM code compatible with the nand2tetris VM
- Supports classes, methods, control flow, and expressions as defined in the Jack language

## Project Structure
- `Parser.hx` – Parses Jack source code into tokens and syntax trees
- `SymbolTable.hx` – Manages identifiers and scope
- `VMWriter.hx` – Outputs VM commands
- `CompilationEngine.hx` – Coordinates parsing and code generation

## Installation
Clone the repository:

```bash
git clone https://github.com/Kugman/Haxe-Compiler.git
cd jack-compiler-haxe
