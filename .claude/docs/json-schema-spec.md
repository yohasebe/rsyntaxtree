# LSIF: Linguistic Structure Interchange Format

Version: 0.2.0 (Draft)
Date: 2026-03-30

## Overview

LSIF (Linguistic Structure Interchange Format) is a JSON-based interchange format for linguistic structural data. It is designed to be:

- **Self-contained**: consumers can fully reconstruct and render structures without parsing source notation
- **Tool-agnostic**: any tool — including LLMs — can produce or consume this format
- **Extensible**: new relationship types, data layers, and metadata can be added without breaking existing consumers
- **Structure-neutral**: not limited to trees or to syntax; can represent any linguistic structure (semantic networks, discourse structures, phonological representations, dependency graphs, etc.)
- **Layer-composable**: multiple independent information layers can coexist within a single document

## File extension

`.lsif.json`

## Primary use cases

1. Multi-plane 3D visualization (shear-transformed parallel/perpendicular planes)
2. Programmatic analysis of linguistic structures
3. Interoperability between linguistic tools and LLMs
4. Multi-layer structural composition (syntax, semantics, prosody, discourse, etc.)

## Conformance levels

LSIF defines three conformance levels. Each level extends the previous one. The levels are orthogonal in the sense that **Rendered** and **Layered** can be combined independently with **Core**.

### Core

The minimal structural representation. Contains only node identities, labels, and relationships.

**Required fields**: `lsif`, `nodes` (with `id` and `label`), `edges`, `paths`

**Use cases**: LLM-generated structures, partial structure descriptions, structural exchange between tools without visual rendering.

A Core-level LSIF represents the abstract structure itself — not necessarily a tree, not necessarily syntactic. It could be a semantic network, a discourse graph, or any set of labeled nodes and typed relationships.

### Rendered

Core plus visual layout information. Adds geometry, position, style, and tree-convenience fields.

**Additional fields**: `geometry`, `nodes[].position`, `nodes[].style`, `nodes[].type`, `nodes[].level`, `nodes[].parent`, `nodes[].children`

**Use cases**: output from rendering tools (e.g. RSyntaxTree), input to visualization tools.

### Layered

Core or Rendered plus additional information layers. Each layer is an independent, self-describing data plane that adds structured information to existing nodes and edges.

**Additional fields**: `layers`

**Use cases**: multi-stratal linguistic descriptions, LLM-assisted structure enrichment, multi-plane visualization.

## Schema

### Top-level structure

```json
{
  "lsif": { ... },
  "meta": { ... },
  "geometry": { ... },
  "nodes": [ ... ],
  "edges": [ ... ],
  "paths": [ ... ],
  "layers": [ ... ]
}
```

### `lsif` (required)

Format identification and version.

```json
{
  "version": "0.2.0",
  "generator": "rsyntaxtree 1.4.0",
  "level": "rendered"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | LSIF schema version (semver) |
| `generator` | string or null | Yes | Tool/agent that produced this file. `null` if hand-authored |
| `level` | string | No | Conformance level: `"core"`, `"rendered"`, or `"layered"`. Defaults to `"core"` if omitted |

### `meta` (optional)

Provenance information. Consumers MUST NOT depend on this section for rendering or analysis. It exists solely for round-trip editing and debugging.

```json
{
  "source": {
    "format": "rsyntaxtree-bracket",
    "input": "[TP [DP_i_ John] [T' [T__0__ pres] [VP ...]]]",
    "params": {
      "font_style": "serif",
      "font_size": 16,
      "color": "modern",
      "connector": "auto",
      "connector_height": 2.0,
      "line_width": 1,
      "symmetrize": false,
      "polyline": false,
      "hide_default_connectors": false,
      "transparent": false
    }
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `source` | object or null | Original input data. `null` if not from a specific tool |
| `source.format` | string | Input format identifier (e.g. `"rsyntaxtree-bracket"`, `"penn-treebank"`, `"llm-generated"`) |
| `source.input` | string | Raw input text |
| `source.params` | object | Rendering parameters as passed to the generator |

### `geometry` (Rendered level)

Bounding box of the rendered structure. Required at Rendered level; absent at Core level.

```json
{
  "width": 540.0,
  "height": 480.0,
  "direction": "ttb"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `width` | number | Total width of the rendered structure (px) |
| `height` | number | Total height of the rendered structure (px) |
| `direction` | string | Layout direction: `"ttb"` (top-to-bottom, default), `"ltr"` (left-to-right). Future: `"rtl"`, `"btt"`. Omit or `"ttb"` for default |

### `nodes` (required)

Array of all nodes. At minimum, each node must have `id` and `label`.

#### Core-level node (minimal)

```json
{
  "id": 1,
  "label": {
    "raw": "VP",
    "lines": [
      { "segments": [{ "text": "VP", "decorations": [] }] }
    ]
  }
}
```

#### Rendered-level node (full)

```json
{
  "id": 1,
  "type": "node",
  "level": 0,
  "label": {
    "raw": "DP_i_",
    "lines": [
      {
        "segments": [
          { "text": "DP", "decorations": [] },
          { "text": "i", "decorations": ["subscript"] }
        ]
      }
    ]
  },
  "position": {
    "x": 50.0,
    "y": 80.0,
    "content_width": 35.0,
    "content_height": 22.0,
    "subtree_width": 100.0
  },
  "style": {
    "color": "#0072B2",
    "enclosure": "none",
    "triangle": false
  },
  "parent": null,
  "children": [2, 3]
}
```

#### Node fields

| Field | Type | Level | Description |
|-------|------|-------|-------------|
| `id` | integer | Core | Unique node identifier (1-based) |
| `label` | object | Core | Node label content |
| `type` | string | Rendered | `"node"` (internal) or `"leaf"` (terminal). Tree-specific |
| `level` | integer | Rendered | Depth in structure (0 = root). Tree-specific |
| `position` | object | Rendered | Layout coordinates and dimensions |
| `style` | object | Rendered | Resolved visual properties |
| `parent` | integer or null | Rendered | Parent node ID. Convenience field derived from `edges` |
| `children` | array of integer | Rendered | Child node IDs. Convenience field derived from `edges` |

#### `label` object

| Field | Type | Description |
|-------|------|-------------|
| `raw` | string | Original markup text (e.g. `"DP_i_"`) |
| `lines` | array | Array of line objects (for multi-line labels) |

#### `label.lines[]` element

| Field | Type | Description |
|-------|------|-------------|
| `segments` | array | Array of text segments within a single line |

#### `label.lines[].segments[]` element

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | Plain text content |
| `decorations` | array of string | Applied decorations (see below) |

**Decoration values:**

| Value | Description |
|-------|-------------|
| `"bold"` | Bold text |
| `"italic"` | Italic text |
| `"bolditalic"` | Bold + italic |
| `"subscript"` | Subscript (smaller, lowered) |
| `"superscript"` | Superscript (smaller, raised) |
| `"small"` | Small text |
| `"overline"` | Line above text |
| `"underline"` | Line below text |
| `"linethrough"` | Strikethrough |
| `"box"` | Rectangular border around text |
| `"circle"` | Circular border around text |
| `"hatched"` | Hatched fill (combined with box/circle) |
| `"bar"` | Horizontal bar |
| `"bstroke"` | Bold stroke variant |
| `"arrow_to_l"` | Left-pointing arrow |
| `"arrow_to_r"` | Right-pointing arrow |

Multiple decorations can be combined (e.g. `["bold", "subscript"]`).

#### `position` object (Rendered level)

All coordinates are in the rendering coordinate space (origin at top-left, y increases downward).

| Field | Type | Description |
|-------|------|-------------|
| `x` | number | Horizontal position of the node label (left edge) |
| `y` | number | Vertical position of the node label (top edge) |
| `content_width` | number | Width of the label text/enclosure |
| `content_height` | number | Height of the label text/enclosure |
| `subtree_width` | number | Width of the subtree rooted at this node |

#### `style` object (Rendered level)

All values are resolved (not symbolic). Colors are hex strings or named CSS colors.

| Field | Type | Description |
|-------|------|-------------|
| `color` | string or null | Resolved node color (e.g. `"#0072B2"`, `"red"`). `null` for default |
| `enclosure` | string | `"none"`, `"brackets"`, `"rectangle"`, `"bold_rectangle"` |
| `triangle` | boolean | Whether this node uses a triangle connector to its parent |

### `edges` (required)

Array of structural relationships. One entry per relationship. May be empty.

```json
{
  "from": 1,
  "to": 2,
  "type": "dominance",
  "connector": "line"
}
```

| Field | Type | Level | Description |
|-------|------|-------|-------------|
| `from` | integer | Core | Source node ID |
| `to` | integer | Core | Target node ID |
| `type` | string | Core | Relationship type |
| `connector` | string or null | Rendered | Visual connector type. `null` or absent at Core level |

**Edge type values (current and planned):**

| Value | Description |
|-------|-------------|
| `"dominance"` | Tree edge (parent governs child) |
| `"dependency"` | Dependency relation |
| `"correspondence"` | Inter-layer mapping |
| `"binding"` | Binding/coreference relation |
| `"agreement"` | Agreement relation |
| `"semantic_role"` | Semantic role assignment |
| `"discourse"` | Discourse relation |

The `type` field is open-ended: any string value is valid. The values above are conventionally defined; tools should use them where applicable.

### `paths` (required)

Array of non-structural, directional relationships (movement arrows, etc.). May be empty.

```json
{
  "from": 5,
  "to": 2,
  "direction": "forward",
  "type": "movement"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `from` | integer | Source node ID |
| `to` | integer | Target node ID |
| `direction` | string | `"forward"` (->), `"backward"` (<-), or `"bidirectional"` (<->) |
| `type` | string | Relationship type (open-ended) |

### `layers` (Layered level)

Array of independent information layers. Each layer adds structured data to existing nodes and/or edges without modifying the Core structure. Absent at Core and Rendered levels.

```json
{
  "layers": [
    {
      "id": "semantics",
      "label": "Semantic roles",
      "description": "Thematic role assignments for each predicate-argument relation",
      "node_data": {
        "3": { "theta_role": "agent", "animacy": "animate" },
        "9": { "theta_role": "theme", "animacy": "inanimate" }
      },
      "edge_data": {
        "0": { "semantic_type": "predication" }
      }
    },
    {
      "id": "prosody",
      "label": "Prosodic structure",
      "description": "Prosodic phrasing and prominence",
      "node_data": {
        "3": { "prosodic_word": "PWd1", "prominence": "primary" }
      }
    }
  ]
}
```

#### Layer fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique layer identifier |
| `label` | string | Human-readable layer name |
| `description` | string or null | Optional description of the layer's content and purpose |
| `node_data` | object or null | Keyed by node ID (as string). Values are arbitrary objects |
| `edge_data` | object or null | Keyed by edge index (as string). Values are arbitrary objects |

**Design notes:**

- Layer data is keyed by node/edge ID, not embedded within node/edge objects, to preserve the Core structure untouched.
- The value objects within `node_data` and `edge_data` are schema-free; each layer defines its own semantics.
- Layers can reference each other via edge `type: "correspondence"` in the main `edges` array, or via shared node IDs.
- A layer can also introduce its own nodes and edges (e.g., a semantic structure with different topology), stored in separate `nodes` and `edges` fields within the layer. This is reserved for future specification.

## Design principles

### Self-containedness

The `nodes`, `edges`, and `paths` sections contain all information needed to render or analyze the structure. No consumer should need to parse `meta.source.input` or understand any source notation.

### Resolved values

Style properties (Rendered level) are stored as resolved values, not symbolic references:
- Colors: `"#0072B2"` not `"modern"`
- Enclosures: `"brackets"` not `"#"`
- Decorations: `["bold", "subscript"]` not `"**_text_**"`

### Extensibility

- New fields can be added to any object without breaking existing consumers
- New `type` values for `edges` and `paths` can be introduced freely
- The `layers` mechanism provides open-ended data composition without schema changes
- The `lsif.version` field tracks breaking changes

### Graceful degradation

Consumers should process only the fields and levels they understand, and ignore the rest. A Rendered-level consumer receiving a Core-level document should be able to compute its own layout. A Core-level consumer receiving a Rendered-level document should ignore `position`, `style`, and other Rendered fields.

### Versioning policy

- **Patch** (0.x.y): documentation clarifications, new optional fields
- **Minor** (0.x.0): new conformance-level features, new conventional type values
- **Major** (x.0.0): breaking changes to existing field semantics or removal of fields

## RSyntaxTree output

RSyntaxTree always produces **Rendered**-level LSIF with `lsif.level` set to `"rendered"`. All Core and Rendered fields are populated. The `layers` section is not included.

## Complete example (Rendered level)

```json
{
  "lsif": {
    "version": "0.2.0",
    "generator": "rsyntaxtree 1.4.0",
    "level": "rendered"
  },
  "meta": {
    "source": {
      "format": "rsyntaxtree-bracket",
      "input": "[TP [DP_i_ John] [VP [V sleeps]]]",
      "params": {
        "font_style": "sans",
        "font_size": 16,
        "color": "modern"
      }
    }
  },
  "geometry": {
    "width": 280.0,
    "height": 240.0
  },
  "nodes": [
    {
      "id": 1,
      "type": "node",
      "level": 0,
      "label": {
        "raw": "TP",
        "lines": [{ "segments": [{ "text": "TP", "decorations": [] }] }]
      },
      "position": { "x": 100.0, "y": 20.0, "content_width": 30.0, "content_height": 22.0, "subtree_width": 280.0 },
      "style": { "color": "#0072B2", "enclosure": "none", "triangle": false },
      "parent": null,
      "children": [2, 4]
    },
    {
      "id": 2,
      "type": "node",
      "level": 1,
      "label": {
        "raw": "DP_i_",
        "lines": [{ "segments": [{ "text": "DP", "decorations": [] }, { "text": "i", "decorations": ["subscript"] }] }]
      },
      "position": { "x": 30.0, "y": 80.0, "content_width": 35.0, "content_height": 22.0, "subtree_width": 100.0 },
      "style": { "color": "#0072B2", "enclosure": "none", "triangle": false },
      "parent": 1,
      "children": [3]
    },
    {
      "id": 3,
      "type": "leaf",
      "level": 2,
      "label": {
        "raw": "John",
        "lines": [{ "segments": [{ "text": "John", "decorations": [] }] }]
      },
      "position": { "x": 30.0, "y": 140.0, "content_width": 40.0, "content_height": 22.0, "subtree_width": 100.0 },
      "style": { "color": "#009E73", "enclosure": "none", "triangle": false },
      "parent": 2,
      "children": []
    },
    {
      "id": 4,
      "type": "node",
      "level": 1,
      "label": {
        "raw": "VP",
        "lines": [{ "segments": [{ "text": "VP", "decorations": [] }] }]
      },
      "position": { "x": 170.0, "y": 80.0, "content_width": 30.0, "content_height": 22.0, "subtree_width": 180.0 },
      "style": { "color": "#0072B2", "enclosure": "none", "triangle": false },
      "parent": 1,
      "children": [5]
    },
    {
      "id": 5,
      "type": "node",
      "level": 2,
      "label": {
        "raw": "V",
        "lines": [{ "segments": [{ "text": "V", "decorations": [] }] }]
      },
      "position": { "x": 175.0, "y": 140.0, "content_width": 20.0, "content_height": 22.0, "subtree_width": 100.0 },
      "style": { "color": "#0072B2", "enclosure": "none", "triangle": false },
      "parent": 4,
      "children": [6]
    },
    {
      "id": 6,
      "type": "leaf",
      "level": 3,
      "label": {
        "raw": "sleeps",
        "lines": [{ "segments": [{ "text": "sleeps", "decorations": [] }] }]
      },
      "position": { "x": 155.0, "y": 200.0, "content_width": 60.0, "content_height": 22.0, "subtree_width": 100.0 },
      "style": { "color": "#009E73", "enclosure": "none", "triangle": false },
      "parent": 5,
      "children": []
    }
  ],
  "edges": [
    { "from": 1, "to": 2, "type": "dominance", "connector": "line" },
    { "from": 1, "to": 4, "type": "dominance", "connector": "line" },
    { "from": 2, "to": 3, "type": "dominance", "connector": "line" },
    { "from": 4, "to": 5, "type": "dominance", "connector": "line" },
    { "from": 5, "to": 6, "type": "dominance", "connector": "line" }
  ],
  "paths": []
}
```
