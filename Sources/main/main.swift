import octant

let sql = [
    """
    SELECT colA, colB, +.
    FROM db.table1 t1
    WHERE c1 > t1.c2
      AND c2 is not null
       OR c3 = false
      AND c4 = 'hello '' world'
    GROUP BY 1;
    """,
    "select 2."
]

let lex = Lexer(input: sql[0])
print(lex.lex())
