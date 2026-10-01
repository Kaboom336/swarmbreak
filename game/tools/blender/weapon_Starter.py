"""Starter Pistol (Common): a fat race pistol. Dark gunmetal frame, mustard slide + oversized mag heel, a compensator as
big as the slide, grey-white LED slots. Recipe: RECIPE.md (weapons). Run: python3 weapons2.py Starter"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapons2 as W
from weapons2 import STEEL


def build():
    k = W.kit("Starter")
    body, cores, halos = [], [], []
    # grip at the origin: short, fat, swept back
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.5, 0.56, 0.7), rake_deg=16)))
    # frame (dark) with the slide (mustard) on top: the two tones
    body.append(k.base(W.receiver("Frame", (0.54, 1.3, 0.38), (0, 0.4, 0.19), bevel=0.06)))
    body.append(k.panel(W.block("Slide", (0.52, 1.45, 0.44), (0, 0.45, 0.6), bevel=0.08)))
    # slide serrations: three dark grooves at the back
    for v in W.vents("Serr", (0, -0.12, 0.62), 3, (0.56, 0.04, 0.36), 0.11):
        body.append(k.base(v))
    # sights
    body.append(k.metal(W.sight("Rear", (0, -0.18, 0.82), kind="notch", width=0.24, height=0.14, depth=0.1), STEEL))
    body.append(k.metal(W.sight("Front", (0, 1.08, 0.82), width=0.1, height=0.16, depth=0.1), STEEL))
    # three-step barrel out of the slide, then a compensator as fat as the slide
    barrel = W.stepped_barrel("Barrel", (0, 1.175, 0.6), [(0.22, 0.18), (0.17, 0.18), (0.12, 0.14)], collar=0.04, collar_len=0.08)
    body.append(k.base(barrel))
    brake = W.muzzle_brake("Brake", barrel["muzzle"], (0.56, 0.44, 0.5), slots=2, slot_w=0.08, bore=0.1)
    body.append(k.base(brake))
    # oversized magazine heel sticking out of the grip, in the panel colour
    body.append(k.panel(W.magazine("Mag", (0, -0.2, -0.68), (0.4, 0.5, 0.3), rake_deg=16, plate=0.1)))
    # trigger guard, hex bolts on the frame
    body.append(k.base(W.trigger_guard("Guard", (0, 0.45, -0.12), radius=0.2)))
    for sx in (-1, 1):
        for b in W.bolts("Bolt%d" % (sx + 1), [(sx * 0.27, 0.15, 0.19), (sx * 0.27, 0.8, 0.19)], (sx, 0, 0), radius=0.055):
            body.append(k.metal(b, STEEL))
    # accent glow: LED slot on each side of the slide + the lit bore, each a bright core with a dim halo
    for sx in (-1, 1):
        c, h = W.glow_slot("Led%d" % (sx + 1), (0.04, 0.55, 0.11), (sx * 0.26, 0.5, 0.6))
        cores.append(k.core(c))
        halos.append(k.halo(h))
    c, h = W.glow_disc("Bore", 0.085, brake["bore"], halo=1.9)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    return k.finish(body, cores, halos)


VIEW = (62, 20)
