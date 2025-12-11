import zipfile
import xml.etree.ElementTree as ET

docx_path = r"c:\Users\raulm\OneDrive - Universidad de Extremadura\TFG\Apuntes_NaricesElectronicas.docx"
out_path = r"c:\Users\raulm\OneDrive - Universidad de Extremadura\TFG\Documentaci\u00f3n\Apuntes_NaricesElectronicas.txt"
# Ruta del .docx y del archivo de salida (acepta argumentos opcionales)
import sys
docx_path = sys.argv[1] if len(sys.argv) > 1 else r"c:\Users\raulm\OneDrive - Universidad de Extremadura\TFG\Apuntes_NaricesElectronicas.docx"
out_path = sys.argv[2] if len(sys.argv) > 2 else r"c:\Users\raulm\OneDrive - Universidad de Extremadura\TFG\Documentaci\u00f3n\Apuntes_NaricesElectronicas.txt"

try:
    with zipfile.ZipFile(docx_path) as z:
        xml = z.read('word/document.xml')
except Exception as e:
    print('ERROR: no se pudo leer el .docx:', e)
    raise

root = ET.fromstring(xml)
ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
paras = []
for p in root.findall('.//w:p', ns):
    texts = [t.text for t in p.findall('.//w:t', ns) if t.text]
    if texts:
        paras.append(''.join(texts))

# Asegurar que la carpeta de salida existe
import os
out_dir = os.path.dirname(out_path)
if not os.path.exists(out_dir):
    os.makedirs(out_dir, exist_ok=True)

with open(out_path, 'w', encoding='utf-8') as f:
    for p in paras:
        f.write(p + '\n')

print('WROTE:', out_path)
