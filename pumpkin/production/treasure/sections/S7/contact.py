"""Reuse unchanged conservative .035 contact/support/one-stud lane checks."""
from pathlib import Path
source=Path(__file__).resolve().parent.parent/'S6/contact.py'
exec(compile(source.read_text().replace('S6','S7'),__file__,'exec'))
