import java.util.*;
import java.util.function.*;

public class <<CLASSNAME>> {
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

    private static void ode(String sym, DoubleSupplier eq) {
        initial(sym, 0);
        odes.put(sym, eq);
    }

    private static void initial(String sym, double val) {
        variables.put(sym, val);
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
        <<COMPILED>>
        execute();
    }
}
