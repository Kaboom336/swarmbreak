"""Heavy Cannon (Legendary): a GOLD metal body (the Legendary material, not trim) with dark bronze second-tone panels
(rear core housing, top cover, the giant drum magazine), a fat drum receiver, a three-step barrel with two floating
gold rings round it, a muzzle brake as fat as the receiver crowned with six gold spikes (the Legendary extra geometry),
a carry handle, and orange glow: lit bore, rear reactor disc, side slots, each a bright core with a dimmer halo.
Grip at the origin, barrel toward +Y. Run: python3 weapons2.py Nova"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Vector

import sb2
import weapons2 as W
from weapons2 import STEEL

AXIS_Z = 0.55       # the barrel axis height


def gold_ring(name, major, minor, at, segs=10, msegs=4):
    return W.ring(name, major, minor, at, axis="Y", segs=segs, msegs=msegs)


def build():
    k = W.kit("Nova")
    body, cores, halos = [], [], []
    # fat rubber grip at the origin, raked back; a bronze trigger guard
    body.append(k.grip(W.grip("Grip", (0, 0, 0), (0.5, 0.56, 0.9), rake_deg=18)))
    body.append(k.panel(W.trigger_guard("Guard", (0, 0.44, -0.14), radius=0.22, segs=6)))
    # the receiver: a gold drum (10 sides) on a gold block that carries the grip; the drum is the biggest mass
    body.append(k.base(W.tube("Drum", (0, -0.35, AXIS_Z), 1.25, 0.5, direction=(0, 1, 0), sides=10)))
    body.append(k.base(W.block("Under", (0.72, 1.3, 0.5), (0, 0.42, 0.3), bevel=0.05)))
    # dark bronze second tone: the rear reactor housing (short stock), a top cover plate, the drum magazine
    body.append(k.panel(W.stock("Housing", (0, -0.35, AXIS_Z), (0.8, 0.55, 0.8), drop=0.0, bevel=0.06, pad=0.1)))
    body.append(k.panel(W.block("Cover", (0.6, 1.0, 0.16), (0, 0.15, AXIS_Z + 0.46), bevel=0.03)))
    # drum magazine twice real size, hung under the receiver in front of the grip, axis across (X)
    body.append(k.panel(W.tube("Mag", (-0.4, 0.95, 0.0), 0.8, 0.42, direction=(1, 0, 0), sides=10)))
    # rear reactor glow: lit disc on the back of the housing (orange core + wider halo)
    c, h = W.glow_disc("Reactor", 0.26, (0, -1.0, AXIS_Z), direction=(0, -1, 0), halo=1.6, sides=10)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    # three-step gold barrel out of the drum, two floating gold rings round it with lit halos (the Legendary extra)
    barrel = W.stepped_barrel("Barrel", (0, 0.9, AXIS_Z), [(0.3, 0.55), (0.22, 0.55), (0.15, 0.45)], sides=8, collar=0.06, collar_len=0.12)
    body.append(k.base(barrel))
    for i, y in enumerate((1.35, 1.85)):
        body.append(k.base(gold_ring("Ring%d" % i, 0.5, 0.07, (0, y, AXIS_Z), segs=8)))
    # the muzzle brake: a gold block as fat as the receiver with vent slots and a lit bore
    brake = W.muzzle_brake("Brake", barrel["muzzle"], (0.95, 0.6, 0.95), slots=2, slot_w=0.09, bore=0.17, top_slots=True)
    body.append(k.base(brake))
    c, h = W.glow_disc("Bore", 0.16, brake["bore"], halo=1.9, sides=10)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    # six gold spikes crowning the brake, swept forward and outward
    bore = Vector(brake["bore"])
    for i in range(6):
        a = math.radians(30 + i * 60)
        rad = Vector((math.cos(a), 0, math.sin(a)))
        base = bore + rad * 0.42 + Vector((0, -0.25, 0))
        body.append(k.base(sb2.horn("Spike%d" % i, base, (rad + Vector((0, 1.1, 0))).normalized(), 0.5, 0.11, sides=5)))
    # gold carry handle on two posts, a steel post sight in front of it
    body.append(k.base(W.block("Handle", (0.22, 0.9, 0.14), (0, 0.15, AXIS_Z + 0.9), bevel=0.03)))
    for y in (-0.2, 0.5):
        body.append(k.base(W.block("Post", (0.16, 0.16, 0.3), (0, y, AXIS_Z + 0.68), bevel=0)))
    body.append(k.metal(W.sight("Sight", (0, 0.9, AXIS_Z + 0.5), kind="post", width=0.12, height=0.18, depth=0.14), STEEL))
    # side glow slots on the drum, steel bolts on the housing
    for sx in (-1, 1):
        c, h = W.glow_slot("Led%d" % (sx + 1), (0.05, 0.8, 0.12), (sx * 0.49, 0.25, AXIS_Z))
        cores.append(k.core(c))
        halos.append(k.halo(h))
        body.append(k.metal(W.bolt("Bolt%d" % (sx + 1), (sx * 0.4, -0.55, AXIS_Z + 0.2), (sx, 0, 0), radius=0.07), STEEL))
    return k.finish(body, cores, halos)


VIEW = (62, 20)
