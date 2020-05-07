# GRAMMAR
# 
# program -> (eqStat | initStat | deltaStat | maxTimeStat)*
# deltaStat -> delta = constVal;
# maxTimeStat -> maxtime = constVal;
# eqStat -> id' = expr;
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
# initStat -> init id = (num | const);
# const -> e | pi
# constVal -> const | nul
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
    deltar = "^delta"
    maxtimer = "^maxtime"
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
        match(line, idr) || match(line, initr) ||  match(line, deltar)||
        match(line, maxtimer) || match(line, /^./)) {
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

function program(    del, mt, el, il) {
    lexer()
    while (tok != eof) {
        if (tok ~ derivnamer)
            el = el "\n" eqStat()
        else if (tok ~ initr)
            il = il "\n" initStat()
        else if (tok ~ deltar)
            del = deltaStat()
        else if (tok ~ maxtimer) 
            mt = maxTimeStat()
        else
            error("unexpected token " tok)
    }
    return sprintf("%s%s%s%s", substr(el, 2), il, mt, del) # substr to remove \n in front
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
    return sprintf("ode(\"%s\", %s);", name, e)
} 

function initStat(    name, val) {
    lexer()
    if (tok == "t")
        error("cannot have init declaration of t")
    used[tok] = 1
    name = tok
    lexer()
    if (tok != "=")
        error("expected \"=\", got " tok)
    lexer()
    val = constVal()
    if (tok != ";")
        error("expected \";\", got " tok)
    lexer()
    return sprintf("initial(\"%s\", %f);", name, val)
}

function deltaStat() {
    if (gotDelta)
        error("cannot define time step more then once")
    gotDelta = NR
    lexer()
    if (tok != "=")
        error("expected \"=\" in delta declaration")
    lexer()
    val = constVal()
    if (tok != ";")
        error("expected \";\", got " tok)
    lexer()
    return sprintf("\ndt = %f;", val)
}

function maxTimeStat() {
    if (gotMaxTime)
        error("cannot define maxtime more then once")
    gotMaxTime = NR
    lexer()
    if (tok != "=")
        error("expected \"=\" in maxtime declaration")
    lexer()
    val = constVal()
    if (tok != ";")
        error("expected \";\", got " tok)
    lexer()
    return sprintf("\nmaxtime = %f;", val)
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
    args = argList(fname)
    return sprintf("func(\"%s\", %s)", fname, args)
}

function argList(fname   , arity, count, wrongArgs, args) {
    arity = functions[fname]  
    wrongArgs = "wrong number of arguments: " fname " requires " arity (arity == 1 ? " argument" : " arguments")
    count = 0
    if (tok == ")") {
        if (arity != 0)
            error(wrongArgs)
        lexer()
        return "null"
    }
    args = expr()
    count++
    while (tok == ",") {
        lexer()
        args = args ", " expr()
        count++
        if (count > arity) 
            error(wrongArgs)
    }
    if (count < arity)
            error(wrongArgs)
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

function constVal() {
    if (tok in constants) {
        lexer()
        return constants[oldTok]
    } else if (tok ~ numr) {
        lexer()
    	return oldTok 
	} else 
    	error("expected constant, got " tok)
}
