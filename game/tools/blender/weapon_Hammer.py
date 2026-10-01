"""Shock Hammer (Rare melee): a long navy haft with a rubber grip and lime wraps, a huge boxy head whose two striking
faces are lime-green caps wider than the core (the two tones), two blue coils around the head's waist (core + halo),
a lit slot on each face, a blue cap on top, four spikes and two swept back-fins (the Rare extra geometry).
Handle at the origin, head up +Z, the faces strike toward +/-X. Run: python3 weapons2.py Hammer"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb2
import weapons2 as W
from weapons2 import STEEL

HEAD_Z = 2.05


def build():
    k = W.kit("Hammer")
    body, cores, halos = [], [], []
    # rubber handle down from the origin with lime wraps, hex pommel
    hd, bands = W.handle("Handle", (0, 0, 0), 1.1, radius=0.15, sides=8, wraps=2, wrap_r=0.03)
    body.append(k.grip(hd))
    body += [k.panel(b) for b in bands]
    body.append(k.base(W.pommel("Pommel", (0, 0, -1.1), radius=0.2, height=0.18)))
    # navy haft up to the head, a fat collar under the head
    body.append(k.base(W.tube("Haft", (0, 0, 0), 1.55, 0.16, r2=0.13, direction=(0, 0, 1), sides=8)))
    body.append(k.base(W.block("Collar", (0.56, 0.56, 0.3), (0, 0, 1.4), bevel=0.05)))
    body.append(k.panel(W.block("Collar2", (0.42, 0.42, 0.14), (0, 0, 1.62), bevel=0.03)))
    # the head: navy core block, two lime striking caps wider than the core (the two tones)
    body.append(k.base(W.block("Head", (1.3, 0.9, 0.84), (0, 0, HEAD_Z), bevel=0.08)))
    for sx in (-1, 1):
        body.append(k.panel(W.block("Face%d" % (sx + 1), (0.5, 1.16, 1.14), (sx * 0.8, 0, HEAD_Z), bevel=0.07)))
        # four steel studs on each striking face
        for b in W.bolts("Stud%d" % (sx + 1), [(sx * 1.05, y, HEAD_Z + z) for y, z in ((-0.36, 0.36), (0.36, 0.36), (-0.36, -0.36), (0.36, -0.36))],
                         (sx, 0, 0), radius=0.08, height=0.07):
            body.append(k.metal(b, STEEL))
    # dark top plate, four spikes at its corners, two swept fins hanging off the back of the head (Rare extra)
    body.append(k.base(W.block("TopPlate", (0.95, 0.7, 0.1), (0, 0, HEAD_Z + 0.42), bevel=0.03, anchor=(0, 0, -1))))
    for j, (sx, sy) in enumerate(((-1, -1), (-1, 1), (1, -1), (1, 1))):
        body.append(k.metal(sb2.horn("Spike%d" % j, (sx * 0.38, sy * 0.26, HEAD_Z + 0.5), (sx * 0.3, sy * 0.2, 1), 0.4, 0.1, sides=4), STEEL, roughness=0.4))
    for sx in (-1, 1):
        f = W.fin("Fin%d" % (sx + 1), [(0.0, 0.36), (-0.55, 0.1), (-0.2, -0.3), (0.0, -0.36)], 0.1, (sx * 0.5, -0.45, HEAD_Z), (0, 1, 0), (0, 0, 1))
        body.append(k.panel(f))
    # blue glow: two coils around the head's waist (core + halo), a slot on each face, a cap ball on top
    for x in (-0.3, 0.3):
        c, h = W.glow_ring("Coil", 0.58, 0.05, (x, 0, HEAD_Z), axis="X", halo=1.9)
        cores.append(k.core(c))
        halos.append(k.halo(h))
    for sx in (-1, 1):
        c, h = W.glow_slot("FaceLed%d" % (sx + 1), (0.05, 0.7, 0.12), (sx * 1.05, 0, HEAD_Z))
        cores.append(k.core(c))
        halos.append(k.halo(h))
    cores.append(k.core(W.ball("Cap", 0.2, (0, 0, HEAD_Z + 0.6), subdiv=1)))
    halos.append(k.halo(W.ball("CapH", 0.27, (0, 0, HEAD_Z + 0.6), subdiv=1), alpha=0.4))
    return k.finish(body, cores, halos)


VIEW = (62, 18)
