"""Spinning Blades (Rare orbital): a navy disc-launcher emitter with an orange top cap and three orange claws cupping a
blue core (core ball + halo ball, a lit seam ring), and the orb: ONE bold three-blade pinwheel (a dark hub with three
orange scimitar blades) whose cutting edges glow blue. Emitter at the origin, orb beside it at x = 2.
Run: python3 weapons2.py Guardian"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Vector, Matrix

import sb2
import weapons2 as W

ORB_C = Vector((2.75, 0.0, 0.8))
ORB_N = Vector((0.78, 0.42, 0.62)).normalized()     # the blade plane faces the render camera (angle 62, elev 20)


def blade_with_edge(name, center, length, width, thickness, normal, spin_deg, curve=0.38):
    """weapons2.orb_blade plus the cutting-edge polyline and the plane axes, so the glow can follow the edge."""
    outline, edge = W.blade_outline(length, width, root=width * 0.55, curve=curve, belly=0.55, tip=0.3, clip=width * 0.25)
    n = Vector(normal).normalized()
    u = Vector((0, 1, 0)) if abs(n.z) > 0.9 else Vector((0, 0, 1)).cross(n).normalized()
    v = n.cross(u).normalized()
    R = Matrix.Rotation(math.radians(spin_deg), 3, n)
    u, v = R @ u, R @ v
    ob = W.plate_poly(name, outline, thickness, center, u, v, bevel=0.015)
    return ob, edge, u, v


def build():
    k = W.kit("Guardian")
    body, cores, halos = [], [], []
    # the emitter: rubber handle with an orange wrap, hex pommel, a fat navy drum head with an orange cap
    hd, bands = W.handle("Handle", (0, 0, 0), 0.95, radius=0.14, sides=8, wraps=1, wrap_r=0.03)
    body.append(k.grip(hd))
    body += [k.panel(b) for b in bands]
    body.append(k.base(W.pommel("Pommel", (0, 0, -0.95), radius=0.19, height=0.16)))
    body.append(k.base(W.tube("Neck", (0, 0, 0), 0.2, 0.2, direction=(0, 0, 1), sides=8)))
    body.append(k.base(W.tube("Drum", (0, 0, 0.18), 0.32, 0.5, direction=(0, 0, 1), sides=10)))
    body.append(k.panel(W.tube("Cap", (0, 0, 0.5), 0.1, 0.42, direction=(0, 0, 1), sides=10)))
    # three orange claws curving up and out from the rim (the Rare extra geometry)
    for i in range(3):
        a = math.radians(90 + i * 120)
        base = (math.cos(a) * 0.4, math.sin(a) * 0.4, 0.5)
        body.append(k.panel(sb2.horn("Claw%d" % i, base, (math.cos(a) * 0.55, math.sin(a) * 0.55, 1.0), 0.62, 0.11, sides=5, curve=0.0)))
    # blue glow: the core ball over the cap with a translucent halo ball, a lit seam ring round the drum
    cores.append(k.core(W.ball("Core", 0.18, (0, 0, 0.72), subdiv=2), strength=2.4))
    halos.append(k.halo(W.ball("CoreH", 0.24, (0, 0, 0.72), subdiv=1), alpha=0.3))
    c, h = W.glow_ring("Seam", 0.5, 0.03, (0, 0, 0.34), axis="Z", halo=1.8)
    cores.append(k.core(c))
    halos.append(k.halo(h))
    # the orb: one bold pinwheel - dark hub, three orange scimitar blades, blue glow along every cutting edge
    orb = [k.base(W.ball("Hub", 0.3, ORB_C, subdiv=2))]
    orb_glow = []
    for i in range(3):
        b, edge, u, v = blade_with_edge("Blade%d" % i, ORB_C, 1.25, 0.46, 0.14, ORB_N, i * 120)
        orb.append(k.panel(b))
        c, h = W.glow_edge("Edge%d" % i, edge, ORB_C, 0.14, u, v, core_w=0.045, halo_w=0.1, proud=0.02)
        orb_glow.append(k.core(c, strength=1.6))
        orb_glow.append(k.halo(h, strength=0.6))
    hubring = W.ring("HubRing", 0.34, 0.05, ORB_C, rot_deg=tuple(math.degrees(a) for a in ORB_N.to_track_quat("Z", "Y").to_euler()), segs=10, msegs=4)
    orb.append(k.base(hubring))
    return k.finish(body, cores, halos, extra={"Orb": orb, "Orb_Glow": orb_glow})


VIEW = (62, 20)
