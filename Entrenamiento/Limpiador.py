"""
Uso típico (ejecutar desde la carpeta riz del proyecto):

- Lote por defecto (procesa Por_procesar/BUENO y MALO → BUENO y MALO):
    python Entrenamiento\Limpiador.py

- Lote explícito:
    python Entrenamiento\Limpiador.py --batch

- Un solo archivo:
    python Entrenamiento\Limpiador.py -i "Entrenamiento\Por_procesar\BUENO\{nombre del archivo}" -o "Entrenamiento\BUENO\{nombre del archivo}"

Notas:
- Los archivos de salida se sobrescriben si ya existen.
- Las rutas son relativas al directorio del TFG (este repo).
"""

import pandas as pd
import argparse
from pathlib import Path
import sys
import subprocess

def procesar_archivo(file_path: str, save_path: str) -> None:
    """Lee, limpia y guarda un archivo de datos.
    
    Elimina columnas innecesarias y filtra por muestras de aire validas.
    """
    df = _leer_csv_robusto(file_path)

    # Columnas que se descartan del dataset
    columnas_a_borrar = [
        'nº', 'temp(scd40)', 'hum(scd40)', 'temp(ens160)',
        'etoh(zmod4410)', 'temperatura(bme688)', 'humedad(bme688)', 'presion(bme688)'
    ]

    # Elimina columnas innecesarias y filtra donde Aire/muestra sea diferente de 0
    df = df.drop(columns=[c for c in columnas_a_borrar if c in df.columns])
    df = df[df['Aire/muestra'] != 0]
    
    # Elimina las 15 primeras líneas donde Aire/muestra == 1
    indices_ones = df[df['Aire/muestra'] == 1].index[:15]
    df = df.drop(indices_ones)
    
    df.to_csv(save_path, sep=' ', decimal=',', index=False)

def _leer_csv_robusto(file_path: str) -> pd.DataFrame:
    """Lee el TXT/CSV con varios encodings comunes en Windows.
    
    Intenta multiples codificaciones en orden de probabilidad.
    """
    # Encodings ordenados por frecuencia en sistemas Windows
    encodings = [
        'utf-8',        # Estandar moderno
        'utf-8-sig',    # UTF-8 con marca de orden de bytes
        'cp1252',       # Windows-1252 (comun en espanol)
        'latin-1',      # ISO-8859-1 como alternativa
    ]

    last_error = None
    # Intenta leer con cada encoding hasta encontrar uno que funcione
    for enc in encodings:
        try:
            return pd.read_csv(
                file_path,
                skiprows=1,
                skipinitialspace=True,
                encoding=enc,
            )
        except UnicodeDecodeError as e:
            last_error = e
            continue

    # Ultimo intento con motor Python (mas tolerante)
    try:
        return pd.read_csv(
            file_path,
            skiprows=1,
            skipinitialspace=True,
            encoding='latin-1',
            engine='python',
        )
    except Exception:
        if last_error:
            raise last_error
        raise

def seleccionar_y_limpiar_cli():
    """Interfaz de linea de comandos para procesar archivos.
    
    Soporta dos modos:
    - Lote: procesa carpetas automaticamente
    - Archivo individual: con --input y --output
    """
    parser = argparse.ArgumentParser(description="Limpia un dataset de sensores y guarda el resultado.")
    parser.add_argument("--input", "-i", help="Ruta del archivo de entrada (.txt)")
    parser.add_argument("--output", "-o", help="Ruta del archivo de salida (.txt)")
    parser.add_argument("--batch", action="store_true", help="Procesa por lotes Por_procesar/BUENO y MALO hacia BUENO y MALO (por defecto si no hay argumentos).")
    args = parser.parse_args()

    # Modo lote: procesa automaticamente si no hay argumentos de entrada/salida
    if args.batch or (not args.input and not args.output):
        procesar_lote()
        return

    # Valida que se proporcionen ambos argumentos para modo de archivo individual
    if not args.input or not args.output:
        parser.error("Debe indicar --batch o bien --input y --output.")

    procesar_archivo(args.input, args.output)
    print(f"Archivo procesado correctamente: {args.output}")

def procesar_lote() -> None:
    """Procesa todos los archivos en modo lote.
    
    Lee archivos de Por_procesar/BUENO y Por_procesar/MALO,
    luego guarda los resultados en BUENO y MALO respectivamente.
    """
    from pathlib import Path
    base = Path(__file__).parent
    in_root = base / "Por_procesar"
    # Pares (carpeta_entrada, carpeta_salida)
    parejas = [("BUENO", "BUENO"), ("MALO", "MALO")]

    # Contadores para estadisticas finales
    total = 0
    ok = 0
    err = 0

    # Procesa cada categoria (BUENO, MALO)
    for sub_in, sub_out in parejas:
        src_dir = in_root / sub_in
        dst_dir = base / sub_out
        dst_dir.mkdir(parents=True, exist_ok=True)

        if not src_dir.exists():
            print(f"[AVISO] Carpeta no encontrada: {src_dir}")
            continue

        # Procesa cada archivo de texto en orden alfabetico
        for txt in sorted(src_dir.glob("*.txt")):
            total += 1
            out_path = dst_dir / txt.name
            try:
                procesar_archivo(str(txt), str(out_path))
                ok += 1
                print(f"[OK] {txt.name} -> {out_path}")
            except Exception as error:
                err += 1
                print(f"[ERROR] {txt.name}: {error}")

    print(f"Resumen lote: {ok}/{total} OK, {err} errores")

if __name__ == "__main__":
    # Ejecuta el limpiador de datos
    seleccionar_y_limpiar_cli()

    # Opcion para ejecutar el script de aumento de datos
    print("\n" + "-"*40)
    ans = input("¿Desea llevar a cabo el aumento de datos? (s/n): ").strip().lower()
    if ans == 's':
        script_path = Path(__file__).parent / "Augmentation.py"
        if script_path.exists():
            print(f"Se lanza {script_path.name}...")
            subprocess.run([sys.executable, str(script_path)])
        else:
            print(f"[ERROR] No se encuentra el archivo: {script_path}")

