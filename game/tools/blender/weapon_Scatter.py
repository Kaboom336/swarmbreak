"""Shotgun (Rare): twin fat barrels side by side stepping into one wide vented muzzle block with two lit bores, navy
receiver, red stock and red pump, side fins (the Rare extra), blue glow. Run: python3 weapons2.py Scatter"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapons2 as W
from weapons2 import STEEL


def build():
    k = W.kit("Scatter")
    body, cores, halos = [], [], []
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.5, 0.54, 0.76), rake_deg=16)))
    # navy receiver, red stock: the two tones
    body.append(k.base(W.receiver("Receiver", (0.6, 1.3, 0.56), (0, 0.5, 0.33), bevel=0.07)))
    body.append(k.panel(W.stock("Stock", (0, -0.15, 0.33), (0.44, 0.72, 0.5), drop=0.12, pad=0.1)))
    # twin barrels, three steps each, out of the receiver's face
    muzzles = []
    for sx in (-1, 1):
        b = W.stepped_barrel("Barrel%d" % (sx + 1), (sx * 0.18, 1.15, 0.52), [(0.17, 0.45), (0.14, 0.4), (0.11, 0.3)], sides=8, collar=0.035, collar_len=0.08)
        body.append(k.base(b))
        muzzles.append(b["muzzle"])
    # one wide muzzle block for both, two bores cut into its face
    brake = W.muzzle_brake("Brake", (0, muzzles[0][1], 0.52), (0.82, 0.46, 0.56), slots=2, slot_w=0.08, bore=0)
    W.cut(brake, [W.tube("BoreCut%d" % i, (m[0], m[1] + 0.25, m[2]), 0.3, 0.1, sides=8) for i, m in enumerate(muzzles)])
    body.append(k.base(brake))
    # Rare extra geometry: swept fins on the block's sides
    for sx in (-1, 1):
        f = W.fin("Fin%d" % (sx + 1), [(0.0, -0.2), (0.45, -0.2), (0.2, 0.32), (-0.1, 0.32)], 0.08, (sx * 0.45, muzzles[0][1], 0.52), (0, 1, 0), (0, 0, 1))
        body.append(k.base(f))
    # ventilated top rib and the front bead
    body.append(k.base(W.rail("Rib", (0, 1.15, 0.7), 1.2, width=0.36, height=0.06, teeth=5)))
    body.append(k.metal(W.sight("Bead", (0, 2.2, 0.76), width=0.1, height=0.1, depth=0.1), STEEL))
    # mag tube under the barrels, then the fat red pump with dark grooves
    body.append(k.base(W.tube("MagTube", (0, 1.15, 0.16), 0.55, 0.13)))
    body.append(k.panel(W.block("Pump", (0.64, 0.62, 0.38), (0, 1.95, 0.16), bevel=0.07)))
    for i in range(3):   # dark finger grooves across the pump (unbeveled, 12 tris each)
        body.append(k.grip(W.block("Groove%d" % i, (0.68, 0.05, 0.32), (0, 1.76 + i * 0.19, 0.16), bevel=0)))
    body.append(k.base(W.trigger_guard("Guard", (0, 0.45, -0.12), radius=0.21, segs=8)))
    for sx in (-1, 1):
        for b in W.bolts("Bolt%d" % (sx + 1), [(sx * 0.3, 0.05, 0.33), (sx * 0.3, 0.95, 0.33)], (sx, 0, 0), radius=0.06):
            body.append(k.metal(b, STEEL))
    # accent glow (blue): a long slot each side of the receiver, the two lit bores
    for sx in (-1, 1):
        c, h = W.glow_slot("Led%d" % (sx + 1), (0.04, 0.7, 0.1), (sx * 0.3, 0.5, 0.48))
        cores.append(k.core(c))
        halos.append(k.halo(h))
    for i, m in enumerate(muzzles):
        c, h = W.glow_disc("Bore%d" % i, 0.085, (m[0], brake["bore"][1], m[2]), halo=1.9, sides=8)
        cores.append(k.core(c))
        halos.append(k.halo(h))
    return k.finish(body, cores, halos)


VIEW = (62, 20)
