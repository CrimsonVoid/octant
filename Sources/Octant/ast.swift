import Foundation

struct Aliasable<T> {
    let val: T
    let alias: String?
}

class SelectQuery {
    let projections: [Aliasable<Expr>] = []
    let from: Aliasable<Table>? = nil
    let joins: [JoinExpr] = []
    let whereClause: WhereClause? = nil
}

struct Table {
    let db: String? = nil
    let table: String
}

struct JoinExpr {
    let ty: JoinType = .default
    let table: Aliasable<Table>?
    let conds: [(left: Expr, right: Expr)]
}

enum JoinType: String {
    case left = "LEFT"
    case right = "RIGHT"
    case `default` = ""
}

indirect enum WhereClause {
    // TODO - list of clauses: and([WhereClause]), or([WhereClause]); why?

    case and(lhs: WhereClause, rhs: WhereClause)
    case or(lhs: WhereClause, rhs: WhereClause)
    case term(Expr)
}

extension WhereClause: CustomStringConvertible {
    var description: String {
        switch self {
        case let .and(left, right): return "( \(left) AND \(right) )"
        case let .or(left, right): return  "( \(left) OR \(right) )"
        case let .term(e): return "\(e)"
        }
    }
}

indirect enum Expr {
    case boolLit(BoolLit)
    case intLit(Int) // re/(-|+)? \d+(.\d*)? | .\d+/  matches: x | x.y | .y | x.
    case floatLit(Float64)
    case stringLit(String)

    case not(Expr)
    case comp(Expr, Op, Expr)

    case isNull(Expr), isNotNull(Expr)
    case `in`(pred: Expr, vals: [Expr]), notIn(pred: Expr, vals: [Expr])
    case between(pred: Expr, lhs: Expr, rhs: Expr), notBetween(pred: Expr, lhs: Expr, rhs: Expr)

    case columnExpr(table: String?, column: String)
    case fnCall(name: String, args: [Expr])
    // case caseExpr
    // case rawExpr(String)
}

extension Expr: CustomStringConvertible {
    var description: String {
        switch self {
        case let .boolLit(b): return "\(b)"
        case let .intLit(i): return "\(i)"
        case let .floatLit(f): return "\(f)"
        case let .stringLit(s): return "'\(s.replacingOccurrences(of: "'", with: "''"))'"

        case let .not(e): return "not(\(e))"

        case let .comp(lhs, op, rhs):
            return "\(lhs) \(op) \(rhs)"

        case let .isNull(e): return "\(e) IS NULL"
        case let .isNotNull(e): return "\(e) IS NOT NULL"

        case let .`in`(pred, ex): return "\(pred) IN (\(ex))"
        case let .notIn(pred, ex): return "\(pred) NOT IN (\(ex))"

        case let .between(pred, lhs, rhs): return "\(pred) BETWEEN \(lhs) AND \(rhs)"
        case let .notBetween(pred, lhs, rhs): return "\(pred) NOT BETWEEN \(lhs) AND \(rhs)"

        case let .columnExpr(table, column):
            let tableName = table.map { $0 + "." } ?? ""
            return "\(tableName)" + "\(column)"

        case let .fnCall(name, args):
            let argsJoined = args.map{"\($0)"}.joined(separator: ", ")
            return "\(name)(\(argsJoined))"
        }
    }

}

enum BoolLit: String {
    case `true` = "True"
    case `false` = "False"
}

extension BoolLit: CustomStringConvertible {
    var description: String { return self.rawValue }
}

enum Op: String {
    case gt = ">", gte = ">="
    case lt = "<", lte = "<="
    case eq = "=", neq = "!=", nullSafeEq = "<=>"
    case like = "like", notLke = "not like"
}

extension Op: CustomStringConvertible {
    var description: String { return self.rawValue }
}
