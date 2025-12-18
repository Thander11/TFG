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

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox
    HAS_TK = True
except Exception:
    HAS_TK = False

def procesar_archivo(file_path: str, save_path: str) -> None:
    df = _leer_csv_robusto(file_path)

    columnas_a_borrar = [
        'nº', 'temp(scd40)', 'hum(scd40)', 'temp(ens160)',
        'etoh(zmod4410)', 'temperatura(bme688)', 'humedad(bme688)', 'presion(bme688)'
    ]

    df = df.drop(columns=[c for c in columnas_a_borrar if c in df.columns])
    df = df[df['Aire/muestra'] != 0]
    df.to_csv(save_path, sep=' ', decimal=',', index=False)

def _leer_csv_robusto(file_path: str) -> pd.DataFrame:
    """Intenta leer el TXT/CSV con varios encodings comunes en Windows.
    Evita errores como: "'utf-8' codec can't decode byte 0xBA ...".
    """
    encodings = [
        'utf-8',        # estándar
        'utf-8-sig',    # UTF-8 con BOM
        'cp1252',       # Windows-1252 (muy común en ES)
        'latin-1',      # ISO-8859-1 como red de seguridad
    ]

    last_error = None
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

    # Último intento: engine='python' puede ser más tolerante en casos raros
    try:
        return pd.read_csv(
            file_path,
            skiprows=1,
            skipinitialspace=True,
            encoding='latin-1',
            engine='python',
        )
    except Exception:
        # Re-lanzar el error original para contexto
        if last_error:
            raise last_error
        raise

def seleccionar_y_limpiar():
    root = tk.Tk()
    root.withdraw()

    file_path = filedialog.askopenfilename(
        title="Selecciona el archivo a limpiar",
        filetypes=[("Archivos de texto", "*.txt"), ("Todos los archivos", "*.*")]
    )
    if not file_path:
        return

    save_path = filedialog.asksaveasfilename(
        title="Guardar dataset limpio como...",
        defaultextension=".txt",
        filetypes=[("Archivos de texto", "*.txt")]
    )
    if not save_path:
        return

    try:
        procesar_archivo(file_path, save_path)
        messagebox.showinfo("Éxito", f"Archivo procesado correctamente:\n{save_path}")
    except Exception as e:
        messagebox.showerror("Error", f"Ocurrió un error al procesar el archivo:\n{e}")

def seleccionar_y_limpiar_cli():
    import argparse
    from pathlib import Path
    parser = argparse.ArgumentParser(description="Limpia un dataset de sensores y guarda el resultado.")
    parser.add_argument("--input", "-i", help="Ruta del archivo de entrada (.txt)")
    parser.add_argument("--output", "-o", help="Ruta del archivo de salida (.txt)")
    parser.add_argument("--batch", action="store_true", help="Procesa por lotes Por_procesar/BUENO y MALO hacia BUENO y MALO (por defecto si no hay argumentos).")
    args = parser.parse_args()

    # Sin argumentos => modo lote por defecto
    if args.batch or (not args.input and not args.output):
        procesar_lote()
        return

    if not args.input or not args.output:
        parser.error("Debe indicar --batch o bien --input y --output.")

    procesar_archivo(args.input, args.output)
    print(f"Archivo procesado correctamente: {args.output}")

def procesar_lote() -> None:
    from pathlib import Path
    base = Path(__file__).parent
    in_root = base / "Por_procesar"
    parejas = [("BUENO", "BUENO"), ("MALO", "MALO")]

    total = 0
    ok = 0
    err = 0

    for sub_in, sub_out in parejas:
        src_dir = in_root / sub_in
        dst_dir = base / sub_out
        dst_dir.mkdir(parents=True, exist_ok=True)

        if not src_dir.exists():
            print(f"[AVISO] Carpeta no encontrada: {src_dir}")
            continue

        for txt in sorted(src_dir.glob("*.txt")):
            total += 1
            out_path = dst_dir / txt.name
            try:
                procesar_archivo(str(txt), str(out_path))
                ok += 1
                print(f"[OK] {txt.name} -> {out_path}")
            except Exception as e:
                err += 1
                print(f"[ERROR] {txt.name}: {e}")

    print(f"Resumen lote: {ok}/{total} OK, {err} errores")

if __name__ == "__main__":
    # Ejecuta siempre la versión CLI (por defecto, lote si no hay argumentos)
    seleccionar_y_limpiar_cli()
