from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import unittest

from mcp import Client, StdioServerParameters
from mcp.client.stdio import stdio_client

from cheme5800_mcp.network import DATA_PATH, NETWORK_URI
from cheme5800_mcp.server import mcp


class MCPServerTests(unittest.IsolatedAsyncioTestCase):
    async def test_discovery_resource_and_tools_in_memory(self) -> None:
        payload = json.loads(DATA_PATH.read_text(encoding="utf-8"))

        async with Client(mcp) as client:
            self.assertEqual(client.protocol_version, "2026-07-28")

            tools = await client.list_tools()
            self.assertEqual(
                sorted(tool.name for tool in tools.tools),
                ["check_flux_balance", "summarize_network"],
            )

            resources = await client.list_resources()
            self.assertEqual([str(resource.uri) for resource in resources.resources], [NETWORK_URI])

            resource = await client.read_resource(NETWORK_URI)
            resource_payload = json.loads(resource.contents[0].text)
            self.assertEqual(resource_payload["network_id"], "urea-cycle")

            summary_result = await client.call_tool("summarize_network", {})
            self.assertFalse(summary_result.is_error)
            self.assertEqual(summary_result.structured_content["number_of_reactions"], 19)

            balance_result = await client.call_tool(
                "check_flux_balance",
                {"flux": payload["reference_fluxes"]["balanced"]},
            )
            self.assertFalse(balance_result.is_error)
            self.assertTrue(balance_result.structured_content["is_balanced"])

            malformed_result = await client.call_tool(
                "check_flux_balance", {"flux": [0.0, 1.0]}
            )
            self.assertTrue(malformed_result.is_error)

            unknown_network_result = await client.call_tool(
                "summarize_network", {"network_id": "genome-scale-model"}
            )
            self.assertTrue(unknown_network_result.is_error)

            unsupported_result = await client.call_tool("delete_network", {})
            self.assertTrue(unsupported_result.is_error)
            self.assertIn("Unknown tool", unsupported_result.content[0].text)

    async def test_real_stdio_subprocess(self) -> None:
        python_dir = Path(__file__).resolve().parents[1]
        environment = dict(os.environ)
        source_dir = str(python_dir / "src")
        existing_path = environment.get("PYTHONPATH")
        environment["PYTHONPATH"] = (
            f"{source_dir}{os.pathsep}{existing_path}" if existing_path else source_dir
        )
        parameters = StdioServerParameters(
            command=sys.executable,
            args=["-m", "cheme5800_mcp.server"],
            env=environment,
            cwd=python_dir,
        )

        async with Client(stdio_client(parameters)) as client:
            self.assertEqual(client.protocol_version, "2026-07-28")
            result = await client.call_tool("summarize_network", {})
            self.assertFalse(result.is_error)
            self.assertEqual(result.structured_content["number_of_species"], 18)


if __name__ == "__main__":
    unittest.main()
