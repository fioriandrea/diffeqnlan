# GRAMMAR
# 
# program -> eqList optInitList
# eqList -> id' = expr
# expr -> addExpr 
# addExpr -> mulExpr ((+ | -) mulExpr)*
# mulExpr -> powExpr ((* | /) powExpr)*
# powExpr -> unaryExpr | unaryExpr ^ powExpr
# unaryExpr -> primaryExpr | (+ | -) unaryExpr
# primaryExpr -> functionExpr | id | num | \( expr \)
# functionExpr -> id \( argList? \)
# argList -> expr (, expr)*
# id -> /[a-zA-Z]+/
# num -> /[0-9]+(\.[0-9]+)?/
# optInitList -> id \( num \) = num
# EXAMPLE
# 
# x' = x^2 + t
# y' = x + sin(y)
# x(0) = 10
# y(0) = 3

BEGIN {
    eof = "{EOF}"
    idr = "^[a-zA-Z]+"
    numr = "^[0-9]+(\\.[0-9]+)?"
    program()
}

function setToken(tv) {
    oldTok = tok
    tok = tv
}

function lexer() {
    sub(/^[ \t]+/, "", line)
    while (length(line) == 0) {
        if (getline line <= 0) {
            setToken(eof)
            return tok
        }
        sub(/^[ \t]+/, "", line)
    }


    if (match(line, idr) || match(line, numr) || match(line, /^./)) {
        setToken(substr(line, 1, RLENGTH))
        line = substr(line, RLENGTH + 1)
        return tok
    }

    error("unrecognizable character after " tok)
}

function error(msg) {
    printf("At line %d: %s\n", NR, msg)
    exit 1
}

function program() {
    lexer()
    while (tok != eof) {
        print tok
        lexer()
    }
}

