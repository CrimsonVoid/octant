import XCTest
@testable import octant

class lexerTests: XCTestCase {
    func testProcessString() {
        let cases: [String: (input: String, expected: String?)] = [
            "simple": ("'hello'", "hello"),
            "embedded quote": ("'hello '' world'''", "hello ' world'"),
            
            // failure cases
            "no closing quote": ("'hello", nil),
            "no opening quote": ("hello", nil),
            "empty": ("", nil),
        ]
        
        runProcessTests(cases, tokenizer: { $0.processString() })
    }

    func testProcessInt() {
        let cases: [String: (input: String, expected: NumericLit?)] = [
            "int": ("123", .int(123)),
            "negative int": ("-123", .int(-123)),
            "positive int": ("+123", .int(123)),
            
            "float": (".123", .float(0.123)),
            "negative float": ("-.123", .float(-0.123)),
            "positive float": ("+.123", .float(0.123)),
            
            "zero float": ("0.123", .float(0.123)),
            "negative zero float": ("-0.123", .float(-0.123)),
            "positive zero float": ("+0.123", .float(0.123)),
            
            "whole float": ("123.45", .float(123.45)),
            "negative whole float": ("-123.45", .float(-123.45)),
            "positive whole float": ("+123.45", .float(123.45)),
            
            // failure cases
            "not a number": ("hello", nil),
            "negative NaN": ("-hello", nil),
            "positive NaN": ("+hello", nil),
            "empty string": ("", nil),
            "plus": ("+", nil),
            "minus": ("-", nil),
        ]
        
        runProcessTests(cases, tokenizer: { $0.processInt() })
    }
    
    func testProcessComment() {
        let cases: [String: (input: String, expected: Comment?)] = [
            "line": ("// this // is // a // comment", .line(" this // is // a // comment")),
            "dash line": ("-- comment -- line", .line(" comment -- line")),
            "block": ("/* hello */", .block(" hello ")),
            "nested block": ("/* hello /* world */", .block(" hello /* world ")),
            
            // failure cases
            "not a comment": ("hello", nil),
        ]
        
        runProcessTests(cases, tokenizer: { $0.processComment() })
    }
    
    func testGetIdent() {
        let cases: [String: (input: String, expected: Token?)] = [
            "select": ("select", .select),
            "from": ("from", .from),
            "where": ("where", .where),
            "as": ("as", .as),
            "and": ("and", .and),
            "or": ("or", .or),
            "true": ("true", .true),
            "false": ("false", .false),
            "case": ("case", .case),
            "when": ("when", .when),
            "then": ("then", .then),
            "else": ("else", .else),
            "end": ("end", .end),
            "is": ("is", .is),
            "not": ("not", .not),
            "null": ("null", .null),
            "group by": ("group by", .groupBy),
            
            "group": ("group", .ident("group")),
            "hello": ("hello", .ident("hello")),
            "db.table": ("db.table", .ident("db.table")),
            "id0": ("id0", .ident("id0")),
            "underscore ident": ("hello_world", .ident("hello_world"))
        ]
        runProcessTests(cases, tokenizer: { $0.getIdent() })
        
        // runProcessTests checks if the input string is empty after lexing, but these cases
        // will fail that condition
        let specialCases: [String: (input: String, expected: Token?)] = [
            "group by space": ("group by ", .groupBy),
            "group byy": ("group byy", .ident("group")),
        ]
        
        for (name, cs) in specialCases {
            let lex = Lexer(input: cs.input)
            let got = lex.getIdent()
            XCTAssertEqual(got, cs.expected, name)
        }
    }
    
    func testAdvanceToNextToken() {
        let lineComment = "this is a // line -- comment"
        let blockComment = "this\n is /* a \n\nblock comment *"
        
        let cases: [String: (input: String, expected: Token?)] = [
            "line comment slash": ("//\(lineComment)", .comment(.line(lineComment))),
            "line comment dash": ("--\(lineComment)", .comment(.line(lineComment))),
            "block comment": ("/*\(blockComment)*/", .comment(.block(blockComment))),
            ">>": (">>", .binOp(.bitRightShift)),
            "<<": ("<<", .binOp(.bitLeftShift)),
            ">=": (">=", .binOp(.gte)),
            "<=": ("<=", .binOp(.lte)),
            "!=": ("!=", .binOp(.neq)),
            "pos number": ("+123", .numLit(.int(123))),
            "neg number": ("-123.45", .numLit(.float(-123.45))),
            "dec number": (".123", .numLit(.float(0.123))),
            "number": ("0123", .numLit(.int(123))),
            "string": ("'this '' is a string'", .stringLit("this ' is a string")),
            "(": ("(", .openParen),
            ")": (")", .closeParen),
            ";": (";", .semicolon),
            ",": (",", .comma),
            "+": ("+", .binOp(.plus)),
            "-": ("-", .binOp(.minus)),
            "*": ("*", .binOp(.times)),
            "/": ("/", .binOp(.div)),
            "%": ("%", .binOp(.mod)),
            "<": ("<", .binOp(.lt)),
            ">": (">", .binOp(.gt)),
            "=": ("=", .binOp(.eq)),
            "&": ("&", .binOp(.bitAnd)),
            "|": ("|", .binOp(.bitOr)),
            "^": ("^", .binOp(.bitXor)),
            "~": ("~", .binOp(.bitNot)),
            "other": (" other", .ident("other"))
        ]
        
        runProcessTests(cases, tokenizer: { $0.advanceToNextToken() })
    }
    
    func runProcessTests<T: Equatable>(_ cases: [String: (input: String, expected: T?)], tokenizer: (Lexer) -> T?) {
        for (name, cs) in cases {
            let lex = Lexer(input: cs.input)
            let got = tokenizer(lex)

            XCTAssertEqual(got, cs.expected, name)
            if got != nil { XCTAssertEqual(lex.index, lex.input.endIndex, name) }
        }
    }
    
    static var allTests = [
        ("testProcessString", testProcessString),
        ("testProcessInt", testProcessInt),
        ("testProcessComment", testProcessComment),
        ("advanceToNextToken", testAdvanceToNextToken),
    ]
}
