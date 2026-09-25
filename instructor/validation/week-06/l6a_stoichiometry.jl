# Regression checks for net coefficients, repeated terms, and signed exchanges.
# Loaded after L6a/Include.jl by the Week 6 validation entry point.
@testset "L6a net stoichiometry" begin
    records = [
        "catalyst,A+B,A+C,false",
        "net,2*A+B,A+3*C,false",
        "repeated,A+2*A,B+B,false",
        "uptake,[],A,true",
        "spaced,2* A,3* B,false",
    ]
    original = copy(records)
    S, species, reactions, equations = build_stoichiometric_matrix(records)
    @test species == ["A", "B", "C"]
    @test reactions == ["catalyst", "net", "repeated", "uptake", "spaced"]
    @test S == [0.0 -1.0 -3.0 1.0 -2.0; -1.0 -1.0 2.0 0.0 3.0; 1.0 3.0 0.0 0.0 0.0]
    @test records == original
    @test equations["uptake"] == "[] = A"

    reversible = ["r,2*A+B,A+C,true"]
    expanded = _expand_reversible_reactions(reversible)
    S2, species2, names2, _ = build_stoichiometric_matrix(reversible; expand=true)
    @test species2 == ["A", "B", "C"]
    @test names2 == ["Fr", "Rr"]
    @test S2 == [-1.0 1.0; -1.0 1.0; 1.0 -1.0]
    @test build_default_bounds_array(expanded) == [0.0 1000.0; 0.0 1000.0]
    @test build_default_bounds_array(reversible) == [-1000.0 1000.0]
end
