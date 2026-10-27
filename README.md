# Skybox Shader — cloud styles

The public style library for the separate `skybox_cloud.lua` client.
The Lua and native bridge are not distributed through this repository.
Only HLSL pixel shaders and declarative JSON controls are downloaded.

Included styles:

- **Lines:** Static, Scroll and Wave; speed, wave strength, line count,
  thickness, glow and three colors.
- **Galaxy:** Static, Twinkle and Rotation; speed, star density, nebula,
  star brightness and three colors.

The original Gradient is built into the Lua and remains available offline.
Successful downloads are cached when filesystem permission is enabled.
The client fetches the catalog on startup and with **Refresh cloud styles**.
New styles appear without a Lua update as long as they use contract 1.

## Add or update a style

1. Give the effect a lowercase ID such as `aurora`.
2. Add `styles/aurora/1.json` describing the controls.
3. Add `styles/aurora/1.hlsl` implementing a `main` pixel shader.
4. Add `{"id":"aurora","name":"Aurora","author":"your name","revision":1}` to
   the `effects` array in `manifest.json`.
5. Compile/test before publishing. For changes, add a new numbered pair and
   increase the catalog revision. Published numbered files are immutable.

The catalog and per-effect JSON each have `"contract": 1`.
The client accepts at most 24 cloud effects and 16 controls per effect.
Each HLSL file is limited to 64 KiB. JSON files are limited to 32 KiB.
IDs cannot contain paths or URLs. Downloads stay under this repository.
The catalog `author` field is displayed as `Aurora (by your name)` and is also
searchable. It accepts up to 32 characters. Older catalogs without this field
remain compatible and display `Unknown`; no author is inferred from shader code.

## Control schema

See the included JSON files for working layouts. Each control has a unique
`key`, a `label`, a `type`, a `default`, and either a parameter `slot` or
the special `"binding": "speed"`. `group` is `main` or `colors`.

| Type | Extra fields | GPU representation |
| --- | --- | --- |
| `slider` | `min`, `max`, `step`, optional `scale` | value × scale (default 1) |
| `select` | `options`: array of labels | zero-based selected index |
| `checkbox` | boolean default | 0 or 1 |
| `color` | RGB default, e.g. `[180,222,255]` | 3 consecutive normalized floats |

Example:

```json
{
  "key": "density",
  "label": "Density",
  "type": "slider",
  "slot": 2,
  "min": 0,
  "max": 100,
  "step": 1,
  "default": 60,
  "scale": 0.01
}
```

Slots are **1–15**, must not overlap, and colors occupy three slots.
A speed slider uses `"binding":"speed"` instead of `slot`, range 0–300,
and controls the animation clock (100 = normal speed). It consumes no GPU slot.
Slider formatting is selected locally; JSON cannot supply arbitrary printf formats.

## HLSL contract 1

The shader receives a normalized world-facing direction in `TEXCOORD0`.
Do not use screen coordinates to anchor the effect. Input/output and buffer:

```hlsl
cbuffer Custom : register(b6) {
    float4 c_params;
    float4 c_low;
    float4 c_high;
    float4 c_glow;
};
struct ps_in {
    float3 dir : TEXCOORD0;
    float4 position : SV_Position;
};
float4 main(ps_in i) : SV_Target0 {
    return float4(c_low.rgb, 1.0);
}
```

| Component | Meaning |
| --- | --- |
| `c_params.x` | animation clock in seconds, affected by the speed slider |
| `c_params.yzw` | slots 1, 2, 3 |
| `c_low.xyzw` | slots 4, 5, 6, 7 |
| `c_high.xyzw` | slots 8, 9, 10, 11 |
| `c_glow.xyzw` | slots 12, 13, 14, 15 |

Slots are general parameters; these legacy vector names do not require colors.
The clock is not automatically stopped by an animation selector: HLSL decides
which selector index means Static and ignores the clock in that mode.
Target is `ps_5_0`. No textures, external includes, extra buffers, native modules
or Lua downloads are part of contract 1. Those features require a client change.

The client compiles a downloaded shader before switching. Download, schema,
compilation or shader-creation failure keeps the current working shader.
A successful switch publishes the shader and its initial parameters under the
native binding lock. UI and compilation work run outside the HTTP callback.

## Client permissions and checks

Enable **FFI** and **HTTP**. **Filesystem** is optional for disk caching.
Disable other sky-effect scripts before loading the cloud client.
This library does not distribute the client or make guarantees about Marketplace
approval or compatibility with future CS2/Fatality changes.

Development checks in the client workspace:

```text
python tools/check_sky_cloud.py
python tools/check_sky_bridge.py skybox_cloud.lua
```

These are offline checks; in-game appearance and the actual Fatality UI still
need to be tested in Fatality.
