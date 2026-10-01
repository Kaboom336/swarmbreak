"""Energy Sword (Epic melee): an ink hilt with glossy purple wraps, guard and wings (the two tones), a wide crossguard
with two prongs flanking the blade, and the blade itself: a curved single-edged plane of translucent purple energy with
three barbs on the spine and a bright core line that follows the cutting edge to an asymmetric point.
Handle at the origin, blade up +Z, edge toward +Y. Run: python3 weapons2.py Saber"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb2
import weapons2 as W
from weapons2 import STEEL, rgb

BLADE_T = 0.12
ROOT = (0, 0, 0.42)
CORE_WHITE = rgb(228, 196, 255)


def build():
    k = W.kit("Saber")
    body, cores, halos = [], [], []
    # hilt: rubber handle with purple wraps, hex pommel and a glowing pommel gem
    hd, bands = W.handle("Handle", (0, 0, 0), 1.05, radius=0.14, sides=8, wraps=3, wrap_r=0.03)
    body.append(k.grip(hd))
    body += [k.panel(b) for b in bands]
    body.append(k.base(W.pommel("Pommel", (0, 0, -1.05), radius=0.2, height=0.16)))
    cores.append(k.core(W.ball("Gem", 0.11, (0, 0, -1.26), subdiv=1)))
    halos.append(k.halo(W.ball("GemH", 0.17, (0, 0, -1.26), subdiv=1), alpha=0.5))
    # ink emitter block, a purple crossguard as wide as the blade, two swept wings under it (the Epic extra)
    body.append(k.base(W.block("Emitter", (0.42, 0.66, 0.36), (0, 0, 0.22), bevel=0.05)))
    body.append(k.panel(W.guard("Guard", (0, 0, 0.1), 1.3, depth=0.3, height=0.2, flare=0.22)))
    for sy in (-1, 1):
        w = W.fin("Wing%d" % (sy + 1), [(0.0, 0.0), (0.55, -0.1), (0.75, -0.55), (0.2, -0.3)], 0.08, (0, sy * 0.4, 0.08), (0, sy, 0), (0, 0, 1))
        body.append(k.base(w))
    # two ink prongs flanking the blade root, each with a purple slot
    for sy in (-1, 1):
        body.append(k.base(W.block("Prong%d" % (sy + 1), (0.22, 0.16, 0.8), (0, sy * 0.36, 0.4), rot_deg=(-sy * 8, 0, 0), bevel=0.03, anchor=(0, 0, -1))))
        c, h = W.glow_slot("ProngLed%d" % (sy + 1), (0.05, 0.1, 0.5), (sy * 0.12, sy * 0.4, 0.78), rot_deg=(-sy * 8, 0, 0), halo=1.5)
        cores.append(k.core(c))
        halos.append(k.halo(h))
    for sx in (-1, 1):
        body.append(k.metal(W.bolt("Bolt%d" % (sx + 1), (sx * 0.21, 0.0, 0.22), (sx, 0, 0), radius=0.06), STEEL))
    # the blade: one curved energy plane (translucent halo) with spine barbs, a bright core along the edge, a thin
    # ink spine rail so the dark + light two-tone carries up the blade
    outline, edge = W.blade_outline(3.0, 0.64, root=0.4, curve=0.2, belly=0.6, tip=0.3, clip=0.16, serrations=3, tooth=0.14, serr_span=(0.3, 0.72))
    plane = W.plate_poly("Blade", outline, BLADE_T, ROOT)
    # the energy plane is a big glow mass: full Epic glow colour at emission 1.0 (higher blows out to white)
    blade = [k.halo(plane, strength=1.0, color=k.glow, alpha=0.8)]
    c, h = W.glow_edge("Edge", edge, ROOT, BLADE_T, core_w=0.07, halo_w=0.16, proud=0.03)
    blade.append(k.core(c, strength=1.5, color=CORE_WHITE))
    blade.append(k.halo(h, strength=1.3))
    spine = [p for p in outline[len(edge):]]          # the spine side (reversed), serrations included
    spine_pts = list(reversed(spine))
    rail = W.plate_poly("Spine", W.offset_polyline([(u - 0.0, v) for u, v in spine_pts if v < 3.0 * 0.72], -0.07), BLADE_T + 0.04, ROOT)
    body.append(k.base(rail))
    return k.finish(body, cores, halos, extra={"Blade_Glow": blade})


VIEW = (62, 16)
