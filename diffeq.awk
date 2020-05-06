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
    print program()
}

function setToken(tv) {
    oldTok = tok
    tok = tv # tok is always the current token
    # also, after calling a rule, this happens:
    # e.g.
    # 1 + 2 * 3; addExpr() returns binary("1", "+", "2") with tok = *
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
    return expr()
}

function expr() {
    return addExpr()
}

function addExpr(    first, op, second) {
    first = mulExpr()
    while (tok == "+" || tok == "-") {
        op = tok
        lexer()
        second = mulExpr()
        first = gen(sprintf("binary(%s, \"%s\", %s)", first, op, second))
    }
    return first
}


function mulExpr(    first, op, second) {
    first = powExpr()
    while (tok == "*" || tok == "/") {
        op = tok
        lexer()
        second = powExpr()
        first = gen(sprintf("binary(%s, \"%s\", %s)", first, op, second))
    }
    return first
}

function powExpr(    first, op, second) {
    first = unaryExpr()
    if (tok == "^") {
        op = tok
        lexer()
        second = powExpr()
        first = gen(sprintf("binary(%s, \"%s\", %s)", first, op, second))
    }
    return first
}

function unaryExpr(    op, second) {
    if (tok == "+" || tok == "-") {
        op = tok
        lexer()
        second = unaryExpr()
        second = gen(sprintf("unary(%s, %s)", op, second))
    } else {
        second = primaryExpr()
    }
    return second
}

function primaryExpr() {
    if (tok ~ numr) {
        return num()
    } else if (tok == "(") {
        return group()
    } else {
        error("unexpected token " tok)
    }
}

function num() {
    lexer()
    return gen(sprintf("number(%s)", oldTok))
}

function group(    e) {
    lexer()
    e = expr()
    if (tok != ")")
        error("expexted closing ), got " tok)
    lexer()
    return gen(sprintf("group(%s)", e))
}

function gen(str) {
    return str
}
