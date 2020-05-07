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

function execute() {
    process.stdout.write("t ");
    for (let i = 0; i < odes.length; i++) { 
        process.stdout.write(odes[i].symbol + " ");
    }
    process.stdout.write("\n");

    process.stdout.write(variables.t + " ");
    for (let i = 0; i < odes.length; i++) { 
        process.stdout.write(variables[odes[i].symbol] + " ");
    
    }
    process.stdout.write("\n");

    let res;
    for (variables.t = 0; variables.t <= maxtime; variables.t += dt) {
        process.stdout.write((variables.t + dt) + " ");
        for (let i = 0; i < odes.length; i++) { 
            res = odes[i].equation();
            variables[odes[i].symbol] += res * dt;
            process.stdout.write(variables[odes[i].symbol] + " ");
        }
        process.stdout.write("\n");
    }
}
