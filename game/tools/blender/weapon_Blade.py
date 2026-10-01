"""Rusty Blade (Common melee): a fat curved cleaver. Rust-orange blade with dark iron patches, four serrations on the
spine, a clipped asymmetric point, a guard wider than the blade, a thin grey-white glow along the edge.
Handle at the origin, blade up +Z, edge toward +Y. Run: python3 weapons2.py Blade"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb2
import weapons2 as W
from weapons2 import STEEL, GUNMETAL

BLADE_T = 0.13
ROOT = (0, 0, 0.22)


def build():
    k = W.kit("Blade")
    body, cores, halos = [], [], []
    # handle down from the origin, rust wraps, hex pommel
    hd, bands = W.handle("Handle", (0, 0, 0), 1.0, radius=0.15, sides=8, wraps=2, wrap_r=0.03)
    body.append(k.grip(hd))
    body += [k.panel(b) for b in bands]
    body.append(k.base(W.pommel("Pommel", (0, 0, -1.0), radius=0.2, height=0.18)))
    # guard wider than the blade, tips turned up
    body.append(k.base(W.guard("Guard", (0, 0, 0.1), 1.15, depth=0.3, height=0.2, flare=0.2)))
    # the blade: one fat plate with a curved silhouette, serrations in the outline (no floating teeth)
    outline, edge = W.blade_outline(2.7, 0.8, root=0.5, curve=0.26, belly=0.6, tip=0.28, clip=0.2, serrations=4, tooth=0.11, serr_span=(0.2, 0.58))
    blade = W.plate_poly("Blade", outline, BLADE_T, ROOT, bevel=0.02)
    # rust body with darker iron patches
    body.append(k.panel(blade, extra=[sb2.spots(3.2, 0.22, sb2.lighten(GUNMETAL, 0.15), seed=2.0, amount=0.9)]))
    # riveted tang
    for sx in (-1, 1):
        body.append(k.metal(W.bolt("Rivet%d" % (sx + 1), (sx * BLADE_T / 2, 0.02, 0.55), (sx, 0, 0), radius=0.05, height=0.04), STEEL))
    # glow that follows the cutting edge: a thin bright line + a slightly wider dim halo (wide halos bloom into a
    # white plate and swallow the rust)
    # (a 2.7-stud strip is a big glow mass: emission 0.9 / 0.35 or the bloom swallows half the blade)
    c, h = W.glow_edge("Edge", edge, ROOT, BLADE_T, core_w=0.035, halo_w=0.08, proud=0.02)
    cores.append(k.core(c, strength=0.9))
    halos.append(k.halo(h, strength=0.35))
    return k.finish(body, cores, halos, core_name="Edge_Glow")


VIEW = (62, 16)
