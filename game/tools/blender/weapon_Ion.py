"""Laser Beam (Epic): an ink receiver carrying a fat glossy-purple energy core tube ringed by dark collars, three swept
purple fins round the core (the Epic extra geometry), a flared ink nozzle as fat as the receiver with a glowing emitter
ball held by four prongs, a lit focus ring, side slots and a rear cap, each glow a bright core plus a dimmer halo.
Grip at the origin, beam toward +Y. Run: python3 weapons2.py Ion"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Vector

import sb2
import weapons2 as W
from weapons2 import STEEL

AXIS_Z = 0.6       # the core tube axis height
CORE_R = 0.34


def build():
    k = W.kit("Ion")
    body, cores, halos = [], [], []
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.46, 0.52, 0.86), rake_deg=16)))
    body.append(k.grip(W.grip("Fore", (0, 1.25, 0.2), (0.4, 0.42, 0.6), rake_deg=8, finger=False)))
    # ink receiver block under the core, a short ink stock with a purple pad
    body.append(k.base(W.receiver("Receiver", (0.6, 1.5, 0.5), (0, 0.55, 0.3), bevel=0.07)))
    body.append(k.base(W.stock("Stock", (0, -0.2, 0.3), (0.44, 0.5, 0.42), drop=0.08, pad=0.0)))
    body.append(k.panel(W.block("Pad", (0.5, 0.1, 0.5), (0, -0.7, 0.26), bevel=0.03, anchor=(0, 1, 0))))
    # the glossy purple energy core: a fat tube from the rear to the nozzle, dark ink collars every third
    body.append(k.panel(W.tube("Core", (0, -0.45, AXIS_Z), 2.15, CORE_R, direction=(0, 1, 0), sides=10)))
    for y in (-0.45, 0.45, 1.3):
        body.append(k.base(W.tube("Collar", (0, y, AXIS_Z), 0.22, CORE_R + 0.06, direction=(0, 1, 0), sides=10)))
    # lit windows: two purple slots down each side of the core between the collars
    for sx in (-1, 1):
        for y in (0.05, 0.9):
            c, h = W.glow_slot("Win%d" % (sx + 1), (0.06, 0.5, 0.12), (sx * (CORE_R - 0.01), y, AXIS_Z + 0.08))
            cores.append(k.core(c))
            halos.append(k.halo(h))
    # three swept glossy purple fins round the core (top and two low sides): the Epic extra geometry
    outline = [(-0.3, 0.0), (0.9, 0.0), (0.5, 0.42), (-0.1, 0.5)]
    for a_deg in (90, 215, 325):
        a = math.radians(a_deg)
        rd = Vector((math.cos(a), 0, math.sin(a)))
        at = Vector((0, 0.35, AXIS_Z)) + rd * (CORE_R - 0.05)
        body.append(k.panel(W.fin("Fin%d" % a_deg, outline, 0.09, at, (0, 1, 0), rd)))
    # the nozzle: a flared ink cone as fat as the receiver, a lit focus ring at its mouth
    body.append(k.base(W.tube("Nozzle", (0, 1.65, AXIS_Z), 0.6, CORE_R, r2=0.5, direction=(0, 1, 0), sides=10)))
    body.append(k.base(W.tube("Lip", (0, 2.2, AXIS_Z), 0.14, 0.52, direction=(0, 1, 0), sides=10)))
    c, h = W.glow_ring("Focus", 0.5, 0.035, (0, 2.36, AXIS_Z), axis="Y", halo=2.2)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    # the emitter: a bright ball in the nozzle mouth with a translucent halo ball, four ink prongs reaching past it
    cores.append(k.core(W.ball("Emitter", 0.24, (0, 2.4, AXIS_Z), subdiv=2), strength=2.2))
    halos.append(k.halo(W.ball("EmitterH", 0.34, (0, 2.4, AXIS_Z), subdiv=1), alpha=0.35))
    for i in range(4):
        a = math.radians(45 + i * 90)
        rad = Vector((math.cos(a), 0, math.sin(a)))
        base = Vector((0, 2.25, AXIS_Z)) + rad * 0.4
        body.append(k.base(sb2.horn("Prong%d" % i, base, (rad * 0.15 + Vector((0, 1, 0))).normalized(), 0.6, 0.11, sides=5)))
    # rear: a lit purple cap behind the core
    c, h = W.glow_disc("Rear", 0.2, (0, -0.45, AXIS_Z), direction=(0, -1, 0), halo=1.7, sides=10)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    # sight, trigger guard, steel bolts on the receiver
    body.append(k.metal(W.sight("Sight", (0, 1.4, AXIS_Z + 0.3), kind="notch", width=0.16, height=0.14, depth=0.12), STEEL))
    body.append(k.base(W.trigger_guard("Guard", (0, 0.42, -0.12), radius=0.2, segs=8)))
    for sx in (-1, 1):
        for b in W.bolts("Bolt%d" % (sx + 1), [(sx * 0.3, 0.0, 0.35), (sx * 0.3, 1.1, 0.35)], (sx, 0, 0), radius=0.06):
            body.append(k.metal(b, STEEL))
    return k.finish(body, cores, halos)


VIEW = (62, 20)
