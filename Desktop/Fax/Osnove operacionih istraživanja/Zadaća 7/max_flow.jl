using Pkg;
Pkg.add("JuMP");
Pkg.add("GLPK");
using JuMP;
using GLPK;

function max_flow(C)
    n = size(C, 1);
    maxProtok = Model(GLPK.Optimizer);

    # Definišemo varijable protoka samo za postojeće grane (gdje je kapacitet > 0)
    # Koristio sam Dict jer ne želim trošit memoriju na prazne varijable, a i lakše je raditi jer kasnije kad isčitavam rješenje ne moram brinuti o indeksima
    x = Dict{Tuple{Int, Int}, VariableRef}()
    for i in 1:n
        for j in 1:n
            if C[i, j] > 0
                x[(i, j)] = @variable(maxProtok, lower_bound=0, upper_bound=C[i, j], integer = true)
            end
        end
    end

    # Očuvanje protoka: suma ulaznih protoka - suma izlaznih protoka = 0 (osim za izvor i odvod)
    for i in 2:(n-1)
        @constraint(maxProtok, sum(get(x, (j, i), 0) for j in 1:n) == sum(get(x, (i, j), 0) for j in 1:n))
    end
    
    # Maksimizacija ukupnog protoka iz izvora (tj. prvog čvora)
    @objective(maxProtok, Max, sum(get(x, (1, j), 0) for j in 1:n))
    
    optimize!(maxProtok)

    # Provjera da li je rješenje optimalno
    if termination_status(maxProtok) == MOI.OPTIMAL
        X = zeros(n, n)
        for ((i, j), var) in x
            X[i, j] = value(var)
        end
        V = objective_value(maxProtok)
        return X, V
    else
        error("Optimalno rješenje nije pronađeno.")
    end
end

# Testiranje funkcije na zadanom testnom primjeru iz postavke zadatka
# Primjer korišćenja
C = [0 3 0 3 0 0 0 0;
     0 0 4 0 0 0 0 0;
     0 0 0 1 2 0 0 0;
     0 0 0 0 2 6 0 0;
     0 1 0 0 0 0 0 1;
     0 0 0 0 2 0 9 0;
     0 0 0 0 3 0 0 5;
     0 0 0 0 0 0 0 0];
X, V = max_flow(C);
println("Protok: ", V)
println("Protok po granama: ")
for i in 1:size(X,1)
    for j in 1:size(X, 2)
        print(X[i, j], " ")
    end
    println()
end