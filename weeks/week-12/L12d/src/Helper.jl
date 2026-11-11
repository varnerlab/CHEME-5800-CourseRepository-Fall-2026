# =============================================================================
# CHEME 5800 | L12d lab: the helpers
# =============================================================================
# Small helper functions that the compute functions call.
#
#   isdead(...)       has the toxicity reached the lethal level?
#   iscured(...)      is the tumor small enough, with the patient alive?
#   isterminal(...)   has the treatment ended (cured or toxic death)?
#   _snap(...)        the index of the nearest grid level (private)
# =============================================================================

# --- PRIVATE METHODS BELOW HERE -------------------------------------------------------------------------------------- #
"""
    _snap(nlevels::Int64, x::Float64) -> Int64

Return the index of the grid level nearest the value `x`, on a grid of `nlevels` levels from 0 to 1.
The rounding is the same as in L12b, so a 41-level grid gives the L12b states.
"""
function _snap(nlevels::Int64, x::Float64)::Int64

    # the nearest grid index -
    step = 1.0/(nlevels - 1);
    i = round(Int64, x/step) + 1;

    # keep the index on the grid -
    if (i < 1)
        i = 1;
    elseif (i > nlevels)
        i = nlevels;
    end

    # return -
    return i;
end
# --- PRIVATE METHODS ABOVE HERE -------------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE --------------------------------------------------------------------------------------- #
"""
    isdead(model::MyPatientModel, B::Float64, Z::Float64) -> Bool

Return `true` if the toxicity `Z` has reached the lethal level, `Z ≥ Zlethal`.
"""
function isdead(model::MyPatientModel, B::Float64, Z::Float64)::Bool
    return Z ≥ model.Zlethal;
end

"""
    iscured(model::MyPatientModel, B::Float64, Z::Float64) -> Bool

Return `true` if the patient state `(B, Z)` is a cure: the tumor burden is at most `Bcure` and
the patient is alive. A state that meets both thresholds counts as a toxic death, not a cure.
"""
function iscured(model::MyPatientModel, B::Float64, Z::Float64)::Bool
    if (isdead(model, B, Z) == true)
        return false; # a toxic death is never a cure
    end
    return B ≤ model.Bcure;
end

"""
    isterminal(model::MyPatientModel, B::Float64, Z::Float64) -> Bool

Return `true` if the treatment has ended: the patient is cured or has died of toxicity.
"""
function isterminal(model::MyPatientModel, B::Float64, Z::Float64)::Bool
    if (isdead(model, B, Z) == true)
        return true;
    end
    if (iscured(model, B, Z) == true)
        return true;
    end
    return false;
end
# --- PUBLIC METHODS ABOVE HERE --------------------------------------------------------------------------------------- #
