struct MetaGreedy <: Policy
    m::MetaMDP
    α::Float64
end
MetaGreedy(m::MetaMDP) = MetaGreedy(m, Inf)
(pol::MetaGreedy)(b::Belief) = act(pol, b)

"Highest value in x not including x[c]"
function competing_value(x::Vector{Float64}, c::Int)
    tmp = x[c]
    x[c] = -Inf
    val = maximum(x)
    x[c] = tmp
    val
end

"Expected maximum of a distribution and and a consant."
function emax(d::Distribution, c::Float64)
    p_improve = 1 - cdf(d, c)
    p_improve < 1e-10 && return c
    (1 - p_improve)  * c + p_improve * mean(Truncated(d, c, Inf))
end
emax(x::Float64, c::Float64) = max(x, c)

"Value of knowing the value in a cell."
function voi1(b::Belief, cell::Int,
              μ = mean.(gamble_values(b)))::Float64
    observed(b, cell) && return 0.
    n_outcome, n_gamble = size(b.matrix)
    outcome, gamble = Tuple(CartesianIndices(size(b.matrix))[cell])
    new_dist = Normal(0, σ_OBS)
    for i in 1:n_outcome
        d = b.matrix[i, gamble]
        new_dist += (i == outcome ? d : d.μ)
    end
    cv = competing_value(µ, gamble)
    emax(new_dist, cv) - maximum(μ)
end
function voc1(b::Belief)
    μ = mean.(gamble_values(b))
    map(computations(b)) do c
        observed(b, c) && return -Inf
        voi1(b, c, μ) - b.s.costs[c]
    end
end

voc(pol::MetaGreedy, b::Belief) = voc1(b)

function (pol::MetaGreedy)(b::Belief)
    v, c = findmax(voc1(b))
    v > 0 ? c : ⊥
end