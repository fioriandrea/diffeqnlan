# GRAMMAR
# 
# program -> eqList optInitList
# eqList -> id' = expr;
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
# optInitList -> init id = (num | const);
# const -> e | pi
# EXAMPLE
# 
# x' = x^2 + t;
# y' = x + sin(y);
# init x = 10;
# init y = 3;

BEGIN {
    eof = "{EOF}"
    idr = "^[a-zA-Z][a-zA-Z0-9]*"
    funnamer = idr "\\("
    derivnamer = idr "'"
    initr = "^init"
    numr = "^[0-9]+(\\.[0-9]+)?"
    n = split("sin cos ln exp", nfunctions, " ")
    split("1 1 1 1", nargs, " ") # arities
    for (i = 1; i <= n; i++) 
        functions[nfunctions[i]] = nargs[i]
    constants["e"] = 2.71828183
    constants["pi"] = 3.14159265
    variables["t"] = 1

    result = program()

    for (u in used) { # check for never defined variables
        if (!(u in variables)) 
            error("undefined variable " u, used[u])
    }

    print result
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

    if (match(line, numr) || match(line, funnamer) || match(line, derivnamer) ||
        match(line, initr) || match(line, idr) || match(line, /^./)) {
            setToken(substr(line, 1, RLENGTH))
            line = substr(line, RLENGTH + 1)
            return tok
        }

        error("unrecognizable character after " tok)
}

function error(msg, row) {
    printf("At line %d: %s\n", row == 0 ? NR : row, msg)
    exit 1
}

function program(    el, il) {
    lexer()
    el = eqList()
    if (tok !~ initr && tok != eof)
        error("expected init declarations, got " tok)
    if (tok != eof) {
        il = initList()
        if (tok != eof) {
            error("expected EOF, got " tok)
        }
    }
    return sprintf("%s%s", el, il)
}

function eqList(    eqs) {
    while (tok ~ derivnamer) {
        eqs = eqs "\n" eqStat()
    }
    return substr(eqs, 2) # removes \n in front
}

function eqStat(    name, e) {
    if (tok !~ derivnamer) 
        error("expected derivative name, got " tok)
    name = substr(tok, 1, length(tok) - 1) 
    if (name == "t")
        error("cannot define a time differential equation")
    if (name in constants) 
        error(name " is a constant")
    if (name in variables) 
        error(name " variable already defined")
    variables[name] = 1
    lexer()
    if (tok != "=")
        error("expected \"=\" after derivative name, got " tok)
    lexer()
    e = expr()
    if (tok != ";")
        error("expected \";\" after equation, got " tok)
    lexer()
    return sprintf("ode(\"%s\", %s)", name, e)
} 

function initList(    inits) {
    while (tok ~ initr) {
        inits = inits "\n" initStat()
    }
    return inits 
}

function initStat(    name, val) {
    lexer()
    if (tok == "t")
        error("cannot have init declaration of t")
    if (!(tok in variables))
        error("undefined variable " tok)
    name = tok
    lexer()
    if (tok != "=")
        error("expected \"=\", got " tok)
    lexer()
    val = initVal()
    if (tok != ";")
        error("expected \";\", got " tok)
    lexer()
    return sprintf("initial(\"%s\", %f)", name, val)
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
        first = sprintf("binary(%s, \"%s\", %s)", first, op, second)
    }
    return first
}

function mulExpr(    first, op, second) {
    first = powExpr()
    while (tok == "*" || tok == "/") {
        op = tok
        lexer()
        second = powExpr()
        first = sprintf("binary(%s, \"%s\", %s)", first, op, second)
    }
    return first
}

function powExpr(    first, op, second) {
    first = unaryExpr()
    if (tok == "^") {
        op = tok
        lexer()
        second = powExpr()
        first = sprintf("binary(%s, \"%s\", %s)", first, op, second)
    }
    return first
}

function unaryExpr(    op, second) {
    if (tok == "+" || tok == "-") {
        op = tok
        lexer()
        second = unaryExpr()
        second = sprintf("unary(%s, %s)", op, second)
    } else 
	    second = primaryExpr()
	
	return second
}

function primaryExpr() {
    if (tok ~ numr) 
        return num()
    else if (tok == "(") 
        return group()
    else if (tok ~ funnamer)
        return funCall()
    else if (tok ~ idr) 
        return id()
    else 
        error("unexpected token " tok)
}

function num() {
    lexer()
    return sprintf("number(%f)", oldTok)
}

function group(    e) {
    lexer()
    e = expr()
    if (tok != ")")
        error("expexted closing ), got " tok)
	lexer()
	return sprintf("group(%s)", e)
}

function funCall(    fname, args) {
    fname = substr(tok, 1, length(tok) - 1) # remove (
    if (!(fname in functions)) 
        error("function " fname " doesn't exist")
    lexer()
    args = argList(functions[fname])
    return sprintf("func(\"%s\", %s)", fname, args)
}

function argList(arity    , count, args) {
    if (tok == ")") {
        lexer()
        return "null"
    }
    args = expr()
    while (tok == ",") {
        lexer()
        args = args ", " expr()
    }
    if (tok != ")")
        error("expected ) after function argument list, got " tok)
    lexer()

    return args 
}

function id() {
    if (tok in constants) {
        lexer()
        return sprintf("number(%f)", constants[oldTok])
    }

    used[tok] = NR

    lexer() 
    return sprintf("variable(\"%s\")", oldTok)
}

function initVal() {
    if (tok in constants) {
        lexer()
        return constants[oldTok]
    } else if (tok ~ numr) {
        lexer()
    	return oldTok 
	} else 
    	error("expected constant, got " tok)
}
