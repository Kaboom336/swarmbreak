"""Rebuild XML Studio package from local sources. No network or place-file mutation.
Uses stdlib only. Run with Blender's bundled Python, or any Python 3.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
import json
R=Path(__file__).resolve().parent

def item(parent,cls,name,source=None):
    it=ET.SubElement(parent,'Item',{'class':cls})
    props=ET.SubElement(it,'Properties')
    ET.SubElement(props,'string',{'name':'Name'}).text=name
    if source is not None: ET.SubElement(props,'ProtectedString',{'name':'Source'}).text=source
    return it

root=ET.Element('roblox',{'version':'4'})
folder=item(root,'Model','MeadowKeeperAnimations')
for name in ['Animator','Rig','Clips','Geometry','Skeleton','Kinematics']:
    item(folder,'ModuleScript',name,(R/f'{name}.luau').read_text())
demo=item(folder,'Script','Demo',(R/'Demo.client.luau').read_text())
ET.SubElement(demo.find('Properties'),'token',{'name':'RunContext'}).text='2'
ET.indent(root)
ET.ElementTree(root).write(R/'MeadowKeeperAnimations.rbxmx',encoding='utf-8',xml_declaration=False)
print('Built MeadowKeeperAnimations.rbxmx (isolated Studio demo)')
