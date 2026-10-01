"""Sniper Rifle (Rare): the long one. Navy receiver and barrel, bone-white stock + handguard, a big scope with a lit
lens, a three-step barrel into a slotted brake with fins (the Rare extra), oversized mag, blue glow.
Run: python3 weapons2.py Marksman"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapons2 as W
from weapons2 import STEEL


def build():
    k = W.kit("Marksman")
    body, cores, halos = [], [], []
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.48, 0.52, 0.76), rake_deg=15)))
    # navy receiver; white stock with a cheek riser and a white handguard: the two tones
    body.append(k.base(W.receiver("Receiver", (0.54, 1.4, 0.56), (0, 0.5, 0.35), bevel=0.07)))
    body.append(k.panel(W.stock("Stock", (0, -0.2, 0.35), (0.44, 0.7, 0.54), drop=0.14, pad=0.1)))
    body.append(k.panel(W.block("Cheek", (0.34, 0.45, 0.12), (0, -0.55, 0.62), bevel=0.03, anchor=(0, 0, -1))))
    body.append(k.panel(W.block("Handguard", (0.52, 0.85, 0.46), (0, 1.2, 0.47), bevel=0.07, anchor=(0, -1, 0))))
    for sx in (-1, 1):   # two dark vent slats a side (unbeveled, 12 tris each)
        for i in range(2):
            body.append(k.base(W.block("Slat%d%d" % (sx + 1, i), (0.04, 0.1, 0.28), (sx * 0.27, 1.35 + i * 0.26, 0.5), bevel=0)))
    # oversized mag, dark
    body.append(k.base(W.magazine("Mag", (0, 0.85, 0.08), (0.32, 0.55, 0.7), rake_deg=8)))
    # three-step barrel into a slotted brake as fat as the handguard, with two fins on top
    barrel = W.stepped_barrel("Barrel", (0, 2.05, 0.52), [(0.2, 0.38), (0.15, 0.32), (0.11, 0.25)], sides=8, collar=0.04, collar_len=0.09)
    body.append(k.base(barrel))
    brake = W.muzzle_brake("Brake", barrel["muzzle"], (0.5, 0.44, 0.5), slots=3, slot_w=0.06, bore=0.09)
    body.append(k.base(brake))
    for sx in (-1, 1):
        f = W.fin("Fin%d" % (sx + 1), [(0.0, 0.0), (0.42, 0.0), (0.3, 0.3), (0.05, 0.36)], 0.07, (sx * 0.12, barrel["muzzle"][1], 0.75), (0, 1, 0), (0, 0, 1))
        body.append(k.base(f))
    # big scope: tube, objective bell, ocular, two mounts on a rail
    body.append(k.base(W.rail("Rail", (0, -0.1, 0.63), 1.3, width=0.24, height=0.07, teeth=4)))
    for y in (0.25, 1.0):
        body.append(k.base(W.block("Mount", (0.2, 0.18, 0.22), (0, y, 0.7), bevel=0, anchor=(0, 0, -1))))
    body.append(k.base(W.tube("Scope", (0, 0.0, 1.0), 1.3, 0.2, sides=8)))
    body.append(k.base(W.tube("Bell", (0, 1.3, 1.0), 0.3, 0.24, r2=0.28, sides=8)))
    body.append(k.base(W.tube("Ocular", (0, 0.0, 1.0), 0.22, 0.24, direction=(0, -1, 0), sides=8)))
    body.append(k.base(W.trigger_guard("Guard", (0, 0.45, -0.12), radius=0.2, segs=8)))
    for sx in (-1, 1):
        for b in W.bolts("Bolt%d" % (sx + 1), [(sx * 0.27, 0.05, 0.35)], (sx, 0, 0), radius=0.06):
            body.append(k.metal(b, STEEL))
    # accent glow (blue): the objective lens, the bore, a slot each side of the receiver
    c, h = W.glow_disc("Lens", 0.2, (0, 1.6, 1.0), halo=1.5, sides=8)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    c, h = W.glow_disc("Bore", 0.08, brake["bore"], halo=1.9, sides=8)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    for sx in (-1, 1):
        c, h = W.glow_slot("Led%d" % (sx + 1), (0.04, 0.75, 0.1), (sx * 0.27, 0.55, 0.4))
        cores.append(k.core(c))
        halos.append(k.halo(h))
    return k.finish(body, cores, halos)


VIEW = (62, 18)
