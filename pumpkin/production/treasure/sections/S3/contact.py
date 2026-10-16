"""Reuse the existing conservative OBB/contact/lane audit unchanged for S3."""
from pathlib import Path
H=Path(__file__).resolve().parent
source=H.parent/'S2/contact.py'
code=source.read_text().replace("!='S2'","!='S3'").replace("=='S2'","=='S3'").replace("S2 metadata","S3 metadata")
# Existing S2 kits are unchanged and separately audited in S2; S3 adds no imported kit.
code=code.replace("data=json.loads((H/(tag+'.json')).read_text())", "data=json.loads((H/(tag+'.json')).read_text());data['kits']=[]")
exec(compile(code,str(source),'exec'),{'__file__':str(H/'contact.py'),'__name__':'__main__'})
