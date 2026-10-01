"""Burst SMG (Common): boxy machine pistol with a teal top cover and a banana mag twice real size, a stubby three-step
barrel into a fat vented brake, short skeleton stock. Run: python3 weapons2.py Burst"""
import math
import os
import sys

from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapons2 as W
from weapons2 import STEEL


def banana_mag(name, at, size, rake_deg=6, curve_deg=22, overlap=0.16, plate=0.1):
    """Oversized banana mag built here so the two halves overlap properly at the kink (W.magazine only overlaps 0.05,
    which leaves an open wedge on the outside of the bend)."""
    w, dp, L = size
    top = Vector(at)
    up_len = L * 0.55
    R1 = Matrix.Rotation(math.radians(-rake_deg), 4, "X")
    pieces = [W.block(name + "_u", (w, dp, up_len), top, rot_deg=(-rake_deg, 0, 0), bevel=0.04, anchor=(0, 0, 1))]
    bottom = top + (R1 @ Vector((0, 0, -up_len)))
    ang = -rake_deg + curve_deg
    R2 = Matrix.Rotation(math.radians(ang), 4, "X")
    lo_len = L - up_len
    start = bottom + (R2 @ Vector((0, 0, overlap)))
    pieces.append(W.block(name + "_l", (w * 0.98, dp * 0.98, lo_len + overlap), start, rot_deg=(ang, 0, 0), bevel=0.04, anchor=(0, 0, 1)))
    bottom = start + (R2 @ Vector((0, 0, -(lo_len + overlap))))
    pieces.append(W.block(name + "_p", (w + 0.06, dp + 0.06, plate), bottom, rot_deg=(ang, 0, 0), bevel=0.02, anchor=(0, 0, 1)))
    return W.join(pieces, name)


def build():
    k = W.kit("Burst")
    body, cores, halos = [], [], []
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.48, 0.52, 0.72), rake_deg=14)))
    # dark receiver, teal top cover with a rail: the two tones
    body.append(k.base(W.receiver("Receiver", (0.54, 1.7, 0.46), (0, 0.55, 0.28), bevel=0.06)))
    body.append(k.panel(W.block("Cover", (0.6, 1.55, 0.34), (0, 0.55, 0.66), bevel=0.08)))
    body.append(k.base(W.rail("Rail", (0, -0.1, 0.83), 1.2, width=0.26, height=0.06, teeth=4)))
    # cooling slats on the cover's nose, dark (unbeveled: 12 tris each)
    for i in range(3):
        body.append(k.base(W.block("Vent%d" % i, (0.44, 0.05, 0.08), (0, 0.98 + i * 0.11, 0.84), bevel=0)))
    body.append(k.metal(W.sight("Rear", (0, -0.05, 0.89), kind="notch", width=0.24, height=0.12, depth=0.1), STEEL))
    body.append(k.metal(W.sight("Front", (0, 1.25, 0.89), width=0.1, height=0.14, depth=0.1), STEEL))
    # oversized banana mag in the panel colour, hanging in front of the grip
    body.append(k.panel(banana_mag("Mag", (0, 0.95, 0.06), (0.34, 0.5, 1.05), rake_deg=6, curve_deg=22)))
    # three-step barrel into a brake as fat as the receiver
    barrel = W.stepped_barrel("Barrel", (0, 1.4, 0.42), [(0.2, 0.24), (0.15, 0.22), (0.1, 0.18)], sides=8, collar=0.04, collar_len=0.08)
    body.append(k.base(barrel))
    brake = W.muzzle_brake("Brake", barrel["muzzle"], (0.54, 0.42, 0.5), slots=2, slot_w=0.08, bore=0.09)
    body.append(k.base(brake))
    # short skeleton stock: a slanted bar and a fat butt pad, big enough to read
    body.append(k.base(W.stock("Stock", (0, -0.3, 0.3), (0.34, 0.7, 0.26), drop=0.08, pad=0.1)))
    body.append(k.base(W.trigger_guard("Guard", (0, 0.42, -0.12), radius=0.2, segs=8)))
    body.append(k.base(W.block("Charger", (0.2, 0.12, 0.1), (0.34, 0.15, 0.5), bevel=0.02)))
    for sx in (-1, 1):
        for b in W.bolts("Bolt%d" % (sx + 1), [(sx * 0.27, 0.05, 0.28), (sx * 0.27, 1.15, 0.28)], (sx, 0, 0), radius=0.055):
            body.append(k.metal(b, STEEL))
    # accent glow: a long LED slot each side of the receiver + the lit bore
    for sx in (-1, 1):
        c, h = W.glow_slot("Led%d" % (sx + 1), (0.04, 0.7, 0.09), (sx * 0.27, 0.62, 0.36))
        cores.append(k.core(c))
        halos.append(k.halo(h))
    c, h = W.glow_disc("Bore", 0.08, brake["bore"], halo=1.9, sides=8)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    return k.finish(body, cores, halos)


VIEW = (62, 20)
