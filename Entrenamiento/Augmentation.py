import pandas as pd
import numpy as np
import os

# Ruta automática al directorio del script
script_dir = os.path.dirname(os.path.abspath(__file__))

def augment_pipeline_fixed(df, window_size=100, target_files=10, iterations=2, noise_level=0.005):
    """Aumenta datos extrayendo ventanas y aplicando ruido.
    
    Divide el dataframe en ventanas y genera variaciones con ruido proporcional.
    Garantiza la generacion del numero de archivos especificado.
    """
    augmented_samples = []
    
    # Calcula cuantas ventanas se necesitan extraer
    needed_windows = target_files // iterations
    
    # Ajusta ventanas si el archivo es mas corto que window_size
    if len(df) <= window_size:
        actual_window_size = len(df)
        actual_windows = 1
        actual_iterations = target_files
        step_size = 1 
    else:
        actual_window_size = window_size
        actual_windows = needed_windows
        actual_iterations = iterations
        # Calcula el salto para distribuir ventanas uniformemente
        if actual_windows > 1:
            step_size = (len(df) - actual_window_size) // (actual_windows - 1)
        else:
            step_size = 0

    # Extrae ventanas y genera variaciones con ruido
    for w in range(actual_windows):
        start = w * step_size
        # Evita superar el final del dataframe
        if start + actual_window_size > len(df):
            start = len(df) - actual_window_size
            
        window = df.iloc[start : start + actual_window_size].copy()
        
        # Genera multiples versiones con ruido por cada ventana
        for _ in range(actual_iterations):
            # Separa caracteristicas de la etiqueta
            features = window.iloc[:, :-1].copy()
            label = window.iloc[:, -1:].copy()
            
            # Aplica ruido proporcional (Jittering) a las caracteristicas
            noise = np.random.normal(1, noise_level, features.shape)
            features_aug = features * noise
            
            # Concatena caracteristicas aumentadas con la etiqueta original
            df_aug = pd.concat([features_aug, label], axis=1)
            augmented_samples.append(df_aug)
            
    return augmented_samples[:target_files]

def process_balanced_data(input_folder_name, output_folder_name, target_per_file=10):
    """Procesa todos los archivos de una carpeta y genera datos aumentados.
    
    Lee archivos de entrada, aplica aumento de datos y guarda en carpeta de salida.
    """
    input_path = os.path.join(script_dir, input_folder_name)
    output_path = os.path.join(script_dir, output_folder_name)

    # Valida que la carpeta de entrada existe
    if not os.path.exists(input_path):
        print(f"Error: No existe {input_folder_name}")
        return

    # Crea la carpeta de salida si no existe
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # Procesa cada archivo de texto de la carpeta de entrada
    for filename in os.listdir(input_path):
        if filename.endswith(".txt"):
            try:
                # Lee el archivo CSV con separador espacio y coma decimal
                df = pd.read_csv(os.path.join(input_path, filename), sep='\s+', decimal=',')
                
                # Aplica aumento de datos
                new_samples = augment_pipeline_fixed(
                    df, 
                    window_size=100,
                    target_files=target_per_file,
                    iterations=2,
                    noise_level=0.005
                )
                
                # Guarda cada muestra aumentada con sufijo -P{numero}
                name_base = os.path.splitext(filename)[0]
                for idx, aug_df in enumerate(new_samples, 1):
                    new_name = f"{name_base}-P{idx}.txt"
                    aug_df.to_csv(os.path.join(output_path, new_name), sep=' ', decimal=',', index=False)
                
                print(f"Se generaron {len(new_samples)} archivos exactos de {filename}.")
            except Exception as error:
                print(f"Error en {filename}: {error}")

# Numero de archivos aumentados a generar por cada archivo original
OBJETIVO_POR_ARCHIVO = 10 

# Mapeo de carpetas de entrada a carpetas de salida
folders = {"BUENO": "BUENO-PLUS", "MALO": "MALO-PLUS"}

# Procesa cada categoria de datos
for ori, dest in folders.items():
    process_balanced_data(ori, dest, target_per_file=OBJETIVO_POR_ARCHIVO)

print(f"\nSe finaliza el proceso. Cada archivo original genera {OBJETIVO_POR_ARCHIVO} versiones.")