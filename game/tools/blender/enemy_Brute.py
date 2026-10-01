"""Brute: the wave-5 boss. First version = the Walker at 2.2x with a crown of light and a taller hump.
TODO (judges, round 2): a boss must be its own shape, not a scaled regular. Redesign here."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemy_Walker import build_walker, WALKER_POSE


def build():
    return build_walker(2.2, boss=True)


POSE = {k: ((v[0][0] * 2.2, v[0][1] * 2.2, v[0][2] * 2.2), v[1]) for k, v in WALKER_POSE.items()}
VIEW = (33, 12)
