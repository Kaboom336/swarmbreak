"""Laser Rifle (Epic): ink-black receiver with glossy purple panels (stock, crest, an oversized energy cell for a mag,
the muzzle fins), two split rails with a purple energy channel between them, two floating coils round the rails (the
Epic extra), a muzzle brake as fat as the receiver with a lit bore. Grip at the origin, barrel +Y.
Run: python3 weapons2.py Arc"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapons2 as W
from weapons2 import STEEL

AXIS_Z = 0.5


def lite_ring(name, major, minor, at, halo=2.0):
    """glow_ring with 10 x 4 segment tori (80 tris each instead of 120) so two coils fit the budget."""
    core = W.ring(name, major, minor, at, axis="Y", segs=10, msegs=4)
    hal = W.ring(name + "H", major, minor * halo, at, axis="Y", segs=10, msegs=4)
    return core, hal


def build():
    k = W.kit("Arc")
    body, cores, halos = [], [], []
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.46, 0.52, 0.86), rake_deg=16)))
    # ink receiver; glossy purple stock + cheek: the two tones
    body.append(k.base(W.receiver("Receiver", (0.56, 1.45, 0.6), (0, 0.5, 0.35), bevel=0.07)))
    body.append(k.panel(W.stock("Stock", (0, -0.22, 0.35), (0.42, 0.62, 0.5), drop=0.12, pad=0.1)))
    # the crest fin over the receiver (purple) and the oversized energy-cell magazine (purple, rear-raked)
    body.append(k.panel(W.fin("Crest", [(-0.3, 0.0), (0.7, 0.0), (0.5, 0.36), (0.0, 0.3)], 0.1, (0, 0.55, 0.64), (0, 1, 0), (0, 0, 1))))
    body.append(k.panel(W.magazine("Cell", (0, 0.8, 0.06), (0.36, 0.56, 0.7), rake_deg=10)))
    body.append(k.base(W.block("CellClip", (0.42, 0.62, 0.12), (0, 0.8, 0.06), bevel=0.02, anchor=(0, 0, 1))))
    # two split rails forward with the purple energy channel between (core + a wider dim halo)
    for sx in (-1, 1):
        body.append(k.base(W.block("Rail%d" % (sx + 1), (0.16, 1.15, 0.36), (sx * 0.19, 1.22, AXIS_Z), bevel=0.04, anchor=(0, -1, 0))))
    # the channel stands proud above and below the rails; its halo is thinner (x) so the core stands out of it
    cores.append(k.core(W.block("Channel", (0.1, 1.1, 0.48), (0, 1.25, AXIS_Z), bevel=0, anchor=(0, -1, 0))))
    halos.append(k.halo(W.block("ChannelH", (0.06, 1.14, 0.6), (0, 1.23, AXIS_Z), bevel=0, anchor=(0, -1, 0))))
    # two floating coils round the rails with a dark clamp between them (the Epic extra geometry)
    for y in (1.6, 2.15):
        c, h = lite_ring("Coil", 0.38, 0.04, (0, y, AXIS_Z), halo=2.0)
        cores.append(k.core(c))
        halos.append(k.halo(h))
    body.append(k.base(W.block("Clamp", (0.62, 0.16, 0.62), (0, 1.88, AXIS_Z), bevel=0.04)))
    # muzzle brake as fat as the receiver, lit bore, two swept purple fins
    brake = W.muzzle_brake("Brake", (0, 2.37, AXIS_Z), (0.6, 0.55, 0.6), slots=2, slot_w=0.07, bore=0.13)
    body.append(k.base(brake))
    c, h = W.glow_disc("Bore", 0.12, brake["bore"], halo=1.8, sides=8)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    for sx in (-1, 1):
        f = W.fin("Fin%d" % (sx + 1), [(0.0, 0.0), (0.5, 0.0), (0.25, 0.3), (-0.2, 0.34)], 0.08, (sx * 0.3, 2.4, AXIS_Z + 0.2), (0, 1, 0), (0, 0, 1))
        body.append(k.panel(f))
    # top sight, trigger guard, side bolts, side power-cell slots (purple)
    body.append(k.metal(W.sight("Sight", (0, 1.05, 0.65), kind="post", width=0.12, height=0.16, depth=0.14), STEEL))
    body.append(k.base(W.trigger_guard("Guard", (0, 0.42, -0.12), radius=0.2, segs=8)))
    for sx in (-1, 1):
        for b in W.bolts("Bolt%d" % (sx + 1), [(sx * 0.28, 0.05, 0.4), (sx * 0.28, 1.05, 0.4)], (sx, 0, 0), radius=0.06):
            body.append(k.metal(b, STEEL))
        c, h = W.glow_slot("Led%d" % (sx + 1), (0.04, 0.7, 0.1), (sx * 0.28, 0.55, 0.26))
        cores.append(k.core(c))
        halos.append(k.halo(h))
    return k.finish(body, cores, halos)


VIEW = (62, 20)
