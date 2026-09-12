"""Restore the shared figure's accessible description after PDF-to-SVG export."""

from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def add_description(path: Path) -> None:
    namespace = "http://www.w3.org/2000/svg"
    ET.register_namespace("", namespace)
    ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")
    tree = ET.parse(path)
    root = tree.getroot()
    if root.tag != f"{{{namespace}}}svg":
        raise ValueError(f"Expected an SVG document: {path}")

    # Keep the metadata stable if the postprocessor is run more than once.
    for tag in ("title", "desc"):
        for element in root.findall(f"{{{namespace}}}{tag}"):
            root.remove(element)
    title = ET.Element(f"{{{namespace}}}title", id="title")
    title.text = "Directed weighted graph used in the L4b traversal lab"
    description = ET.Element(f"{{{namespace}}}desc", id="description")
    description.text = (
        "A six-vertex directed acyclic graph with seven weighted edges. "
        "Vertex 1 points to vertices 2 and 3; vertex 2 points to vertices 3 and 4; "
        "vertex 3 points to vertex 5; vertex 5 points to vertex 4; "
        "and vertex 4 points to vertex 6."
    )
    root.insert(0, title)
    root.insert(1, description)
    root.set("role", "img")
    root.set("aria-labelledby", "title description")
    tree.write(path, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    add_description(Path(sys.argv[1]))
