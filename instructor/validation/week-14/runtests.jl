const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-14"))
include(joinpath(WEEK_ROOT, "L14a", "Include.jl"))

const FIXTURE = normpath(joinpath(WEEK_ROOT, "..", "week-13", "data", "urea-cycle-network.json"))

@testset "L14 delivery audit" begin
    checksum = fingerprint(FIXTURE)
    record = DeliveryRecord(
        name = "urea-cycle network",
        path = FIXTURE,
        provenance = "Derived from the Fall 2025 Week 6 FBA source.",
        expected_sha256 = checksum,
        interface = :stdio,
    )
    result = audit_delivery(record)
    @test result.ready
    @test all(values(result)[1:5])

    bad_checksum = DeliveryRecord(
        name = record.name,
        path = record.path,
        provenance = record.provenance,
        expected_sha256 = repeat("0", 64),
        interface = record.interface,
    )
    @test !audit_delivery(bad_checksum).ready

    overpowered = DeliveryRecord(
        name = record.name,
        path = record.path,
        provenance = record.provenance,
        expected_sha256 = checksum,
        interface = :shell,
        mutates_state = true,
    )
    @test !audit_delivery(overpowered).interface
    @test !audit_delivery(overpowered).least_privilege
    @test_throws ArgumentError fingerprint(joinpath(WEEK_ROOT, "missing.json"))
end

@testset "L14 integration checklist" begin
    checklist = integration_checklist()
    @test length(checklist) == 7
    @test first(checklist).layer == "representation"
    @test last(checklist).layer == "interpretation"
    @test length(unique(item.layer for item in checklist)) == length(checklist)
end
