"""Reuse the inspected fitted CC0 rock renderer with S6's manifest directory."""
from pathlib import Path
exec(compile((Path(__file__).resolve().parent.parent/'S5/kit-render.py').read_text(),__file__,'exec'))
