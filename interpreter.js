let maxtime = 5;
let dt = 0.1;
let variables = {t: 0};
let binaryOperations = ({
    "+": (a, b) => a + b,
    "-": (a, b) => a - b,
    "*": (a, b) => a * b,
    "/": (a, b) => a / b,
    "^": (a, b) => a ** b,
});
let unaryOperations = ({
    "+": a => a,
    "-": a => -a,
});
let functions = ({
    "sin": e => Math.sin(e),
    "cos": e => Math.cos(e),
    "ln": e => Math.ln(e),
    "exp": e => Math.exp(e),
});
let odes = [];


function number(fl) {
    return () => fl;
}

function binary(left, op, right) {
    return () => binaryOperations[op](left(), right());
}

function unary(op, right) {
    return () => unaryOperations[op](right());
}

function variable(sym) {
    variables[sym] = 0;
    return () => variables[sym];
}

function func(sym, ...args) {
    return () => functions[sym](...args.map(e => e()));
}

function ode(sym, eq) {
    initial(sym, 0);
    odes.push({symbol: sym, equation: eq});
}

function initial(sym, val) {
    variables[sym] = val;
}

function println(buffer, delim=" ") {
    console.log(buffer.join(delim));
    while(buffer.length > 0)
        buffer.pop();
}

function execute() {
    let buffer = [];
    buffer.push("t");
    for (let i = 0; i < odes.length; i++) { 
        buffer.push(odes[i].symbol);
    }
    println(buffer);

    buffer.push(variables.t);
    for (let i = 0; i < odes.length; i++) { 
        buffer.push(variables[odes[i].symbol]);
    }
    println(buffer);

    let res;
    for (variables.t = 0; variables.t < maxtime; variables.t += dt) {
        buffer.push(variables.t + dt);
        for (let i = 0; i < odes.length; i++) { 
            res = odes[i].equation();
            variables[odes[i].symbol] += res * dt;
            buffer.push(variables[odes[i].symbol]);
        }
        println(buffer);
    }
}
