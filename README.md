# diffeqnlan language

diffeqnlan is a small special purpose language made to solve ODEs numerically.

## Description

A diffeqnlan program consists in a specification of a system of ODEs. The ODEs are then solved using the Euler method. The details of the grammar and some examples are given below.

## Project structure

diffeq.awk is were the parser is written. interpreter.js is were definitions for the code generated by diffeq.awk are. diffeqnlan.sh is a script piping everything together.

## Inner workings 

Input is parsed through an AWK script, which generates Java code. The generated code can be then compiled and executed. Each row of the generated code's output is a point in state space.

## Language choice

I chose to implement the parser in AWK mainly to do some sperimentation. I found it an useful little language that can be used to prototype this sort of things. 

## Grammar
 
**program** -> (eqStat | initStat | deltaStat | maxTimeStat | constStat)\*

**constStat** -> 'const' id '=' expr';'

**deltaStat** -> 'delta' '=' expr';'

**maxTimeStat** -> 'maxtime' '=' expr';'

**initStat** -> 'init' id '=' expr';'

**eqStat** -> id''' '=' expr;

**expr** -> addExpr 

**addExpr** -> mulExpr (('+' | '-') mulExpr)\*

**mulExpr** -> powExpr (('\*' | '/') powExpr)\*

**powExpr** -> unaryExpr | unaryExpr '^' powExpr

**unaryExpr** -> primaryExpr | ('+' | '-') unaryExpr

**primaryExpr** -> functionExpr | id | num | '(' expr ')'

**functionExpr** -> id '(' argList? ')'

**argList** -> expr (',' expr)\*

**const** -> 'e' | 'pi'

**id** -> /[a-zA-Z]+/

**num** -> /[0-9]+(\.[0-9]+)?/

# Examples

Input
```
x' = x;
init x = 1;
delta = 0.01;
maxtime = 1;
```

Output (compiled)
```java
import java.util.*;
import java.util.function.*;

public class program {
    private static double maxtime = 5;
    private static double dt = 0.1;
    private static Map<String, Double> variables = new HashMap<>();
    private static Map<String, BiFunction<DoubleSupplier, DoubleSupplier, Double>> binaryOperations = new HashMap<>();
    private static Map<String, Function<DoubleSupplier, Double>> unaryOperations = new HashMap<>();
    private static Map<String, Function<List<DoubleSupplier>, Double>> functions = new HashMap<>();
    private static Map<String, DoubleSupplier> odes = new LinkedHashMap<>();


    private static void initMaps() {
        variables.put("t", 0.0);

        binaryOperations.put("+", (l, r) -> l.getAsDouble() + r.getAsDouble());
        binaryOperations.put("*", (l, r) -> l.getAsDouble() * r.getAsDouble());
        binaryOperations.put("-", (l, r) -> l.getAsDouble() - r.getAsDouble());
        binaryOperations.put("/", (l, r) -> l.getAsDouble() / r.getAsDouble());
        binaryOperations.put("^", (l, r) -> Math.pow(l.getAsDouble(), r.getAsDouble()));

        unaryOperations.put("+", (r) -> r.getAsDouble());
        unaryOperations.put("-", (r) -> -r.getAsDouble());

        functions.put("sin", (l) -> Math.sin(l.get(0).getAsDouble()));
        functions.put("cos", (l) -> Math.cos(l.get(0).getAsDouble()));
        functions.put("log", (l) -> Math.log(l.get(0).getAsDouble()));
        functions.put("exp", (l) -> Math.exp(l.get(0).getAsDouble()));
    }

    private static DoubleSupplier number(double fl) {
        return () -> fl;
    }

    private static DoubleSupplier binary(DoubleSupplier left, String op, DoubleSupplier right) {
        return () -> binaryOperations.get(op).apply(left, right);
    }

    private static DoubleSupplier unary(String op, DoubleSupplier right) {
        return () -> unaryOperations.get(op).apply(right);
        }

    private static DoubleSupplier variable(String sym) {
        variables.put(sym, 0.0);
        return () -> variables.get(sym);
    }

    private static DoubleSupplier func(String sym, DoubleSupplier ...args) {
        return () -> functions.get("sym").apply(Arrays.asList(args));
    }

    private static DoubleSupplier group(DoubleSupplier expr) {
        return expr;
    }

    private static void ode(String sym, DoubleSupplier eq) {
        initial(sym, number(0));
        odes.put(sym, eq);
    }

    private static void initial(String sym, DoubleSupplier val) {
        variables.put(sym, val.getAsDouble());
    }

    private static DoubleSupplier constant(DoubleSupplier e) {
        return number(e.getAsDouble());
    }

    private static void setMaxtime(DoubleSupplier val) {
        maxtime = val.getAsDouble();
    }

    private static void setDelta(DoubleSupplier val) {
        dt = val.getAsDouble();
    }

    private static void execute() {
        System.out.print("t ");
        for (String s : odes.keySet()) {
            System.out.print(s + " ");
        }
        System.out.println();

        System.out.print(variables.get("t") + " ");
        for (String s : odes.keySet()) {
            System.out.print(variables.get(s) + " ");
        }
        System.out.println();
        double res;
        for (variables.put("t", 0.0); variables.get("t") < maxtime; variables.put("t", variables.get("t") + dt)) {
            System.out.print((variables.get("t") + dt) + " ");
            for (String s : odes.keySet()) {
                res = odes.get(s).getAsDouble();
                variables.put(s, variables.get(s) + res * dt);
                System.out.print(variables.get(s) + " ");
            }
            System.out.println();
        }
    }

    public static void main(String ...args) {
        initMaps();
        ode("x", variable("x"));
initial("x", number(1.000000));
setMaxtime(number(1.000000));
setDelta(number(0.010000));
        execute();
    }
}
```

Output (executed)
```
t x 
0 1 
0.01 1.01 
0.02 1.0201 
0.03 1.030301 
0.04 1.0406040099999998 
0.05 1.0510100500999997 
0.060000000000000005 1.0615201506009997 
0.07 1.0721353521070096 
0.08 1.0828567056280798 
0.09 1.0936852726843607 
0.09999999999999999 1.1046221254112043 
0.10999999999999999 1.1156683466653163 
0.11999999999999998 1.1268250301319696 
0.12999999999999998 1.1380932804332893 
0.13999999999999999 1.1494742132376221 
0.15 1.1609689553699982 
0.16 1.1725786449236981 
0.17 1.1843044313729352 
0.18000000000000002 1.1961474756866646 
0.19000000000000003 1.2081089504435312 
0.20000000000000004 1.2201900399479664 
0.21000000000000005 1.2323919403474461 
0.22000000000000006 1.2447158597509207 
0.23000000000000007 1.25716301834843 
0.24000000000000007 1.2697346485319143 
0.25000000000000006 1.2824319950172334 
0.26000000000000006 1.2952563149674057 
0.2700000000000001 1.3082088781170798 
0.2800000000000001 1.3212909668982507 
0.2900000000000001 1.3345038765672332 
0.3000000000000001 1.3478489153329056 
0.3100000000000001 1.3613274044862347 
0.3200000000000001 1.3749406785310971 
0.3300000000000001 1.3886900853164081 
0.34000000000000014 1.4025769861695723 
0.35000000000000014 1.416602756031268 
0.36000000000000015 1.4307687835915806 
0.37000000000000016 1.4450764714274964 
0.38000000000000017 1.4595272361417713 
0.3900000000000002 1.474122508503189 
0.4000000000000002 1.4888637335882209 
0.4100000000000002 1.5037523709241032 
0.4200000000000002 1.5187898946333442 
0.4300000000000002 1.5339777935796777 
0.4400000000000002 1.5493175715154746 
0.45000000000000023 1.5648107472306294 
0.46000000000000024 1.5804588547029357 
0.47000000000000025 1.596263443249965 
0.48000000000000026 1.6122260776824646 
0.49000000000000027 1.6283483384592892 
0.5000000000000002 1.644631821843882 
0.5100000000000002 1.661078140062321 
0.5200000000000002 1.677688921462944 
0.5300000000000002 1.6944658106775734 
0.5400000000000003 1.7114104687843492 
0.5500000000000003 1.7285245734721928 
0.5600000000000003 1.7458098192069147 
0.5700000000000003 1.7632679173989838 
0.5800000000000003 1.7809005965729736 
0.5900000000000003 1.7987096025387033 
0.6000000000000003 1.8166966985640902 
0.6100000000000003 1.834863665549731 
0.6200000000000003 1.8532123022052283 
0.6300000000000003 1.8717444252272806 
0.6400000000000003 1.8904618694795534 
0.6500000000000004 1.9093664881743488 
0.6600000000000004 1.9284601530560923 
0.6700000000000004 1.9477447545866533 
0.6800000000000004 1.9672222021325199 
0.6900000000000004 1.986894424153845 
0.7000000000000004 2.0067633683953834 
0.7100000000000004 2.026831002079337 
0.7200000000000004 2.0470993121001304 
0.7300000000000004 2.067570305221132 
0.7400000000000004 2.088246008273343 
0.7500000000000004 2.1091284683560767 
0.7600000000000005 2.1302197530396376 
0.7700000000000005 2.151521950570034 
0.7800000000000005 2.1730371700757343 
0.7900000000000005 2.194767541776492 
0.8000000000000005 2.2167152171942566 
0.8100000000000005 2.238882369366199 
0.8200000000000005 2.2612711930598612 
0.8300000000000005 2.28388390499046 
0.8400000000000005 2.3067227440403646 
0.8500000000000005 2.329789971480768 
0.8600000000000005 2.353087871195576 
0.8700000000000006 2.3766187499075317 
0.8800000000000006 2.400384937406607 
0.8900000000000006 2.424388786780673 
0.9000000000000006 2.4486326746484797 
0.9100000000000006 2.4731190013949647 
0.9200000000000006 2.497850191408914 
0.9300000000000006 2.5228286933230035 
0.9400000000000006 2.5480569802562334 
0.9500000000000006 2.573537550058796 
0.9600000000000006 2.599272925559384 
0.9700000000000006 2.6252656548149775 
0.9800000000000006 2.651518311363127 
0.9900000000000007 2.6780334944767583 
1.0000000000000007 2.704813829421526 
```

### Sample Programs
```
x' = sin(y);
y' = cos(x);
init x = 1;
init y = 1;
```

```
x' = x - x * y;
y' = x * y - y;
init x = 2;
init y = 1;
```

```
const s = 10;
const r = 28;
const b = 8 / 3;

x' = s * (y - x);
y' = x * (r - z) - y;
z' = x * y - b * z;

init x = 1;
init y = 1;
init z = 1;

delta = 0.01;
maxtime = 10;
```
