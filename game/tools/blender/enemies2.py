"""Swarm Break enemies, pass 2: the shared recipe (palette, paint rules, crests, claws) and the build loop.
One file per enemy: enemy_<Name>.py (see RECIPE.md).
Run: python3 enemies2.py [Walker ...]   env SB_NO_RENDER=1 to skip renders, SB_ASSETS=<dir> to redirect output."""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2
from sb import PAL, rgb
from sb2 import top_light, belly, height, band, stripes, spots, region, near, facing

# ---------------------------------------------------------------- palette (dark bodies, one saturated accent each)
BODY = rgb(20, 15, 32)          # near-black chitin
SHELL = rgb(104, 78, 158)       # lit shell tone (top faces)
FLESH = rgb(120, 58, 96)        # underside
BONE = rgb(228, 218, 196)
STEEL = rgb(118, 126, 140)
STEEL_DARK = rgb(52, 56, 68)
ACCENT = {
    "Walker": rgb(255, 140, 40), "Runner": rgb(40, 230, 200), "Flyer": rgb(255, 215, 60), "Tank": rgb(80, 220, 110),
    "Spitter": rgb(190, 70, 250), "Brute": rgb(240, 50, 50), "Queen": rgb(120, 230, 90), "Warden": rgb(70, 170, 255),
}


def masked(rule, mask):
    """Restrict a paint rule to faces where mask(p, n, t) -> 0..1."""
    def r(p, n, t):
        c, w = rule(p, n, t)
        return c, w * mask(p, n, t)
    return r


def paint_body(ob, acc, shell=SHELL, base=BODY, extra=(), stripe=None, roughness=0.62):
    """The standard chitin paint: dark base, lit shell on top faces, flesh underneath, optional accent stripes."""
    rules = [top_light(shell, power=0.8, amount=1.0), belly(FLESH, amount=0.7, power=1.3)]
    if stripe:
        axis, period, duty, phase = stripe
        rules.append(masked(stripes(axis, period, duty, acc, phase, amount=0.9), lambda p, n, t: 1.0 if n.z > 0.05 else 0.0))
    rules += list(extra)
    return sb2.paint_rules(ob, base, rules, roughness=roughness)


def paint_plate(ob, color=STEEL, edge=None):
    return sb2.paint_rules(ob, sb2.darken(color, 0.55), [top_light(color, 0.9, 1.0), belly(sb2.darken(color, 0.4), 0.6)], roughness=0.42, metallic=0.25)


def paint_bone(ob, color=BONE):
    return sb2.paint_rules(ob, sb2.darken(color, 0.62), [top_light(color, 0.8, 1.0)], roughness=0.35)


def crest(name, along, base, direction_up, count, length, radius, sides=4, curve=0.25, color=BONE):
    """A row of faceted spikes along `along` (vector) starting at base, leaning back as they go."""
    out = []
    a = Vector(along)
    for i in range(count):
        f = i / max(count - 1, 1)
        p = Vector(base) + a * f
        d = (Vector(direction_up) + a.normalized() * (0.35 * f)).normalized()
        L = length * (1.0 - 0.45 * abs(f - 0.5) * 2)
        h = sb2.horn("%s%d" % (name, i), p, d, L, radius * (1.0 - 0.3 * f), sides=sides, curve=curve)
        paint_bone(h, color)
        out.append(h)
    return out


def claw_fan(name, at, direction, count=3, length=0.75, radius=0.13, spread=0.22, curve=0.35, color=BONE):
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 0, 1)))
    side = side.normalized() if side.length > 1e-3 else Vector((1, 0, 0))
    out = []
    for i in range(count):
        off = side * ((i - (count - 1) / 2) * spread)
        h = sb2.horn("%s%d" % (name, i), Vector(at) + off, d, length, radius, sides=4, curve=curve)
        paint_bone(h, color)
        out.append(h)
    return out


def scale_parts(parts, s):
    for ob in parts.values():
        ob.scale = (s, s, s)
        sb.apply_transforms(ob)


ENEMIES = ["Walker", "Runner", "Flyer", "Tank", "Spitter", "Brute", "Queen", "Warden"]


def load(name):
    """Each enemy lives in enemy_<Name>.py with build() -> {part: object}, POSE (for renders), VIEW (angle, elev)."""
    import importlib
    return importlib.import_module("enemy_" + name)


def build_all(names=None, render=True, ao=True):
    names = names or [n for n in ENEMIES if os.path.exists(os.path.join(os.path.dirname(os.path.abspath(__file__)), "enemy_%s.py" % n))]
    for name in names:
        mod = load(name)
        sb.reset()
        parts = mod.build()
        objs = [o for o in parts.values() if o is not None]
        if ao:
            sb2.bake_ao(objs, strength=0.7, distance=1.4, samples=12)
        sb.export_model("enemies/%s" % name, objs, {"display": name, "recipe": "v2"})
        big = [(o.name, sb.tri_count(o)) for o in objs if sb.tri_count(o) > 3000]
        print("built", name, "parts=%d tris=%d" % (len(objs), sum(sb.tri_count(o) for o in objs)), ("WARNING big parts: %s" % big) if big else "")
        sys.stdout.flush()
        if render:
            sb2.pose(parts, getattr(mod, "POSE", {}))
            a, e = getattr(mod, "VIEW", (32, 12))
            out = sb2.render_model2(name, objs, "enemies/%s.png" % name, angle_deg=a, elev_deg=e)
            print("rendered", out)
            sys.stdout.flush()


if __name__ == "__main__":
    build_all(sys.argv[1:] or None, render=os.environ.get("SB_NO_RENDER") != "1", ao=os.environ.get("SB_NO_AO") != "1")
