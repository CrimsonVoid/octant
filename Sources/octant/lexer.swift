public enum Token {
    case select, from, `where`, groupBy, `as`, comma
    case `is`, not, null, semicolon
    case and, or, `true`, `false`, openParen, closeParen
    case `case`, when, then, `else`, end

    case binOp(BinaryOp)
    case stringLit(String)
    case numLit(NumericLit)
    case ident(String)
    case comment(Comment)
}

public enum BinaryOp: String {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case div = "/"
    case mod = "%"

    case bitAnd = "&"
    case bitOr = "|"
    case bitXor = "^"
    case bitNot = "~"
    case bitLeftShift = "<<"
    case bitRightShift = ">>"

    case gt = ">"
    case lt = "<"
    case gte = ">="
    case lte = "<="
    case eq = "="
    case neq = "!="
}

public enum NumericLit {
    case float(Float64)
    case int(Int64)
}

public enum Comment {
    case line(String)
    case block(String)
}

public class Lexer {
    let input: String
    var index: String.Index

    var currentChar: Character? {
        return charAt(index: index)
    }

    var nextChar: Character? {
        return charAt(offset: 1)
    }

    public init(input: String) {
        self.input = input
        self.index = input.startIndex
    }

    public func lex() -> [Token] {
        var toks = [Token]()

        // use currIndex to make sure we are advancing through input
        var currIndex = index
        while let tok = advanceToNextToken(), currIndex != index {
            currIndex = index
            toks.append(tok)
        }

        return toks
    }

    func advanceToNextToken() -> Token? {
        // skip whitespace
        // read tokens with significant leading characters
        // read other tokens

        while let char = currentChar, char.isWhitespace {
            advanceIndex()
        }

        // tokens with significant leading characters. we will return the first
        // valid token with a matching prefix. advIndex controls if we should
        // advance the index by prefix.count; useful for variable length 
        // tokens.
        // make sure that longer tokens are at the top, and, since we can call
        // multiple functions before a valid Token is found, be sure that fn is
        // reentrant (does not modify index unless a valid Token is returned)
        let significantChars: [(prefix: String, advIndex: Bool, fn: () -> Token?)] = [
            /* two significant leading char tokens */
            ("//", false, self.commentToken),
            ("--", false, self.commentToken),
            ("/*", false, self.commentToken),

            (">>", true, { .binOp(.bitRightShift) }),
            ("<<", true, { .binOp(.bitLeftShift) }),
            (">=", true, { .binOp(.gte) }),
            ("<=", true, { .binOp(.lte) }),
            ("!=", true, { .binOp(.neq) }),

            /* single char tokens */
            ("+", false, self.numericToken),
            ("-", false, self.numericToken),
            (".", false, self.numericToken),

            ("'", false, self.stringToken),

            ("(", true, { .openParen }),
            (")", true, { .closeParen }),
            (";", true, { .semicolon }),
            (",", true, { .comma }),

            ("+", true, { .binOp(.plus) }),
            ("-", true, { .binOp(.minus) }),
            ("*", true, { .binOp(.times) }),
            ("/", true, { .binOp(.div) }),
            ("%", true, { .binOp(.mod) }),

            ("<", true, { .binOp(.lt) }),
            (">", true, { .binOp(.gt) }),
            ("=", true, { .binOp(.eq) }),

            ("&", true, { .binOp(.bitAnd) }),
            ("|", true, { .binOp(.bitOr) }),
            ("^", true, { .binOp(.bitXor) }),
            ("~", true, { .binOp(.bitNot) }),
        ]

        for (prefix, advIndex, fn) in significantChars {
            if input[index...].hasPrefix(prefix), let tok = fn() {
                if advIndex { advanceIndex(by: prefix.count) }
                return tok
            }
        }

        if let char = currentChar, char >= "0" && char <= "9" {
            // already checked for numeric tokens with a leading +, -, or .
            return numericToken()
        }

        return getIdent()
    }

    func processString() -> String? {
        if currentChar != "'" {
            return nil
        }
        advanceIndex()

        // two single quotes ('') can be used as an escape sequence for a single quote.
        // in order to avoid extra memcopies we get a list of substrings before concating
        // them

        var strIndexes: [Substring] = []
        var startIndex = index

        while let char = currentChar {
            if char == "'" && nextChar == "'" {
                // '' inside a string should be treated as a single quote. append
                // a Substring with a trailing ' for easier concatenation
                strIndexes.append(input[startIndex ... index])
                advanceIndex(by: 2)
                startIndex = index // next Substring should start after '

                continue
            } else if char == "'" {
                strIndexes.append(input[startIndex ..< index])
                // set startIndex to the current index since we need to check it later
                startIndex = index
                advanceIndex()

                break
            }

            advanceIndex()
        }

        if input[startIndex] != "'" {
            // read whole string and didn't find a closing '
            return nil
        }

        return strIndexes.joined()
    }

    func processInt() -> NumericLit? {
        func isNum(_ c: Character) -> Bool { return c >= "0" && c <= "9" }

        // numbers should be \d+(\.\d+)? | (\d+)?\.\d+ with an optional leading sign
        let startIndex = index

        // skip sign
        if let char = currentChar, char == "-" || char == "+" {
            advanceIndex()
        }

        // should start with a number or .
        if let char = currentChar, !isNum(char) && char != "." {
            return nil
        }

        while let char = currentChar, isNum(char) {
            advanceIndex()
        }

        if currentChar == "." {
            // we found some digits with a decimal point
            advanceIndex()
            while let char = currentChar, isNum(char) {
                advanceIndex()
            }

            return Float64(input[startIndex ..< index]).map { .float($0) }
        } else {
            // we found some digits without a decimal point
            return Int64(input[startIndex ..< index]).map { .int($0) }
        }
    }

    func processComment() -> Comment? {
        return nil
    }

    func getIdent() -> Token {
        func isNotTokenChar(_ c: Character) -> Bool {
            let isAlphanum = { c.isLetter || c.isNumber || c == "." }

            return !(c.isASCII && !c.isWhitespace && isAlphanum())
        }

        let endIndex = input[index...].firstIndex(where: isNotTokenChar) ?? input.endIndex
        let token = input[index..<endIndex]
        index = endIndex

        switch token.lowercased() {
        case "select": return .select
        case "from": return .from
        case "where": return .where
        case "as": return .as
        case "and": return .and
        case "or": return .or
        case "true": return .true
        case "false": return .false
        case "case": return .case
        case "when": return .when
        case "then": return .then
        case "else": return .else
        case "end": return .end
        case "is": return .is
        case "not": return .not
        case "null": return .null
        case "group":
            // TODO - can we clean this up a bit?

            guard let idx = input.index(index, offsetBy: 3, limitedBy: input.endIndex) else {
                return .ident(String(token))
            }

            if let c = charAt(index: clampedIndex(idx, offsetBy: 1)), isNotTokenChar(c) {
                return .ident(String(token))
            }

            switch input[index..<idx].lowercased() {
            case " by": index = idx; return .groupBy
            default: return .ident(String(token))
            }
        default: return .ident(String(token))
        }
    }

    // MARK: Utility Functions

    func charAt(index: String.Index) -> Character? {
        return index < input.endIndex ? input[index] : nil
    }

    func charAt(offset: Int) -> Character? {
        return input.index(index, offsetBy: offset, limitedBy: input.endIndex)
            .flatMap(charAt)
    }

    func advanceIndex() {
        input.formIndex(after: &index)
    }

    func advanceIndex(by offset: Int) {
        index = clampedIndex(index, offsetBy: offset)
    }

    func clampedIndex(_ index: String.Index, offsetBy: Int) -> String.Index {
        return input.index(index, offsetBy: offsetBy, limitedBy: input.endIndex)
            ?? input.endIndex
    }

    func numericToken() -> Token? {
        return reentrant(processInt).map { .numLit($0) }
    }

    func stringToken() -> Token? {
        return reentrant(processString).map { .stringLit($0) }
    }

    func commentToken() -> Token? {
        return reentrant(processComment).map { .comment($0) }
    }

    func reentrant<T>(_ fn: () -> T?) -> T? {
        let currIndex = index
        let tok = fn()

        if tok == nil {
            index = currIndex
        }

        return tok
    }
}
