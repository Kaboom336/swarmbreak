"""Triple Rocket (Epic): an ink launcher block with three fat glossy magenta tubes (two low, one high), each tube ringed
dark and ending in a glowing warhead cone with a lit rim, flared exhausts at the back with lit throats, a carry handle,
two swept rear wings and a top fin (the Epic extra). Grip at the origin, tubes toward +Y.
Run: python3 weapons2.py Hornet"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb2
import weapons2 as W
from weapons2 import STEEL

TUBES = ((-0.27, 0.3), (0.27, 0.3), (0.0, 0.68))     # (x, z) of the three tubes
TUBE_Y0, TUBE_L, TUBE_R = 1.05, 1.3, 0.21


def build():
    k = W.kit("Hornet")
    body, cores, halos = [], [], []
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.46, 0.52, 0.86), rake_deg=14)))
    # ink launcher block, a magenta rear cover and a magenta band across the middle: the two tones
    body.append(k.base(W.receiver("Launcher", (0.86, 1.3, 0.78), (0, 0.5, 0.42), bevel=0.07)))
    body.append(k.panel(W.block("Rear", (0.9, 0.34, 0.82), (0, -0.15, 0.42), bevel=0.06, anchor=(0, 1, 0))))
    body.append(k.panel(W.block("Band", (0.92, 0.18, 0.84), (0, 0.75, 0.42), bevel=0.02)))
    # three fat magenta tubes out of the front, each with a dark collar and a lit rim; warheads poke out
    for i, (x, z) in enumerate(TUBES):
        body.append(k.panel(W.tube("Tube%d" % i, (x, TUBE_Y0, z), TUBE_L, TUBE_R, sides=8)))
        body.append(k.base(W.tube("Collar%d" % i, (x, TUBE_Y0 + 0.55, z), 0.16, TUBE_R + 0.04, sides=8)))
        body.append(k.base(W.tube("Mouth%d" % i, (x, TUBE_Y0 + TUBE_L - 0.14, z), 0.16, TUBE_R + 0.04, sides=8)))
        # lit rim: a light 8 x 4 torus core and a disc halo behind the warhead (tori cost 120 tris each)
        cores.append(k.core(W.ring("Rim%d" % i, TUBE_R + 0.02, 0.035, (x, TUBE_Y0 + TUBE_L + 0.02, z), axis="Y", segs=8, msegs=4)))
        halos.append(k.halo(W.disc("RimH%d" % i, TUBE_R + 0.1, (x, TUBE_Y0 + TUBE_L - 0.02, z), thickness=0.04, sides=8)))
        cores.append(k.core(sb2.horn("Head%d" % i, (x, TUBE_Y0 + TUBE_L - 0.1, z), (0, 1, 0), 0.52, 0.15, sides=6)))
        # flared exhaust nozzle at the back with a lit throat
        body.append(k.base(W.tube("Exhaust%d" % i, (x, -0.32, z), 0.32, 0.13, r2=0.2, direction=(0, -1, 0), sides=8)))
        c, h = W.glow_disc("Throat%d" % i, 0.14, (x, -0.64, z), direction=(0, -1, 0), halo=1.6, sides=8)
        cores.append(k.core(c))
        halos.append(k.halo(h))
    # carry handle on two posts, a top fin behind it, two swept rear wings (the Epic extra)
    body.append(k.base(W.block("Handle", (0.2, 0.7, 0.12), (0, 0.5, 1.12), bevel=0.03)))
    for y in (0.22, 0.78):
        body.append(k.base(W.block("Post", (0.14, 0.14, 0.26), (0, y, 0.95), bevel=0)))
    body.append(k.panel(W.fin("TopFin", [(0.0, 0.0), (0.0, 0.42), (0.35, 0.1), (0.5, 0.0)], 0.08, (0, -0.4, 0.83), (0, -1, 0), (0, 0, 1))))
    for sx in (-1, 1):
        w = W.fin("Wing%d" % (sx + 1), [(0.0, 0.0), (0.0, -0.4), (0.55, -0.45), (0.65, 0.0)], 0.08, (sx * 0.44, -0.15, 0.5), (0, -1, 0), (sx, 0, 0))
        body.append(k.panel(w))
    # side slots, bolts, trigger guard
    for sx in (-1, 1):
        c, h = W.glow_slot("Led%d" % (sx + 1), (0.04, 0.5, 0.1), (sx * 0.43, 0.35, 0.42))
        cores.append(k.core(c))
        halos.append(k.halo(h))
        for b in W.bolts("Bolt%d" % (sx + 1), [(sx * 0.43, 0.1, 0.72), (sx * 0.43, 0.6, 0.72)], (sx, 0, 0), radius=0.06):
            body.append(k.metal(b, STEEL))
    body.append(k.base(W.trigger_guard("Guard", (0, 0.4, -0.12), radius=0.2, segs=8)))
    return k.finish(body, cores, halos)


VIEW = (62, 20)
