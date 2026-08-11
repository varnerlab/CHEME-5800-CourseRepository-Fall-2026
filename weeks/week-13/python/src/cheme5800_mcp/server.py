"""Official-SDK MCP surface for the Week 13 urea-cycle computation."""

from __future__ import annotations

import json

from mcp.server import MCPServer

from .network import (
    NETWORK_ID,
    NETWORK_URI,
    check_flux_balance as check_flux_balance_core,
    load_network,
    summarize_network as summarize_network_core,
)

mcp = MCPServer(
    "CHEME 4800/5800 Urea-Cycle Network",
    version="0.1.0",
    instructions=(
        "Read the urea-cycle network resource, inspect its reaction order, and use "
        "the tools to summarize the network or test a proposed flux vector. "
        "This server is local and read-only."
    ),
)


@mcp.resource(
    NETWORK_URI,
    name="urea-cycle-network",
    title="Urea-cycle metabolic network",
    description="Read-only JSON stoichiometric model used in CHEME 5800 Week 6 and Week 13.",
    mime_type="application/json",
)
def urea_cycle_network() -> str:
    """Return the complete, documented urea-cycle network representation."""
    return json.dumps(load_network().raw, indent=2)


@mcp.tool()
def summarize_network(network_id: str = NETWORK_ID) -> dict[str, object]:
    """Report network dimensions and the ordered species and reaction identifiers."""
    return summarize_network_core(network_id)


@mcp.tool()
def check_flux_balance(
    flux: list[float],
    tolerance: float = 1.0e-9,
    network_id: str = NETWORK_ID,
) -> dict[str, object]:
    """Compute S*v for a proposed flux vector and apply a numerical tolerance."""
    return check_flux_balance_core(flux, tolerance=tolerance, network_id=network_id)


def main() -> None:
    """Run the local server over standard input/output."""
    mcp.run()


if __name__ == "__main__":
    main()
