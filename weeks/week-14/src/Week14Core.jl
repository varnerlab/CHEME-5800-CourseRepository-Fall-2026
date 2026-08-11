module Week14Core

import SHA

export DeliveryRecord, audit_delivery, fingerprint, integration_checklist

"""Minimal record for an artifact crossing a computational-system boundary."""
Base.@kwdef struct DeliveryRecord
    name::String
    path::String
    provenance::String
    expected_sha256::String
    interface::Symbol
    mutates_state::Bool = false
end

"""Return the lowercase SHA-256 fingerprint for a local file."""
function fingerprint(path::AbstractString)::String
    isfile(path) || throw(ArgumentError("artifact does not exist: $(path)"))
    return bytes2hex(SHA.sha256(read(path)))
end

"""Audit presence, provenance, integrity, interface, and side-effect policy."""
function audit_delivery(record::DeliveryRecord)
    allowed_interfaces = (:local_file, :https, :stdio)
    checks = (
        exists = isfile(record.path),
        provenance = !isempty(strip(record.provenance)),
        checksum = isfile(record.path) && fingerprint(record.path) == lowercase(record.expected_sha256),
        interface = record.interface in allowed_interfaces,
        least_privilege = !record.mutates_state,
    )
    return merge(checks, (ready = all(values(checks)),))
end

"""Reusable integration questions accumulated across the semester."""
function integration_checklist()
    return [
        (layer = "representation", question = "Are types, dimensions, units, and identifiers explicit?"),
        (layer = "computation", question = "Does the algorithm match the problem assumptions?"),
        (layer = "validation", question = "Are invariants, failure paths, and reference cases tested?"),
        (layer = "data", question = "Are provenance and integrity recorded?"),
        (layer = "interface", question = "Is the input/output contract documented and typed?"),
        (layer = "security", question = "Are side effects and authority intentionally bounded?"),
        (layer = "interpretation", question = "Can the result support the claimed engineering decision?"),
    ]
end

end
