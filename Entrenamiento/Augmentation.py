import pandas as pd
import numpy as np
import os

# Ruta automática al directorio del script
script_dir = os.path.dirname(os.path.abspath(__file__))

def augment_pipeline_fixed(df, window_size=100, target_files=10, iterations=2, noise_level=0.005):
    """
    Calcula el desplazamiento automáticamente para generar siempre el mismo número de archivos.
    """
    augmented_samples = []
    
    # Calculamos cuántas ventanas (trozos) necesitamos extraer
    # Si iterations es 2 y queremos 10 archivos, necesitamos 5 ventanas
    needed_windows = target_files // iterations
    
    # Ajuste de seguridad: si el archivo es más corto que la ventana
    if len(df) <= window_size:
        # Solo podemos sacar una ventana (el archivo completo)
        # Para cumplir el objetivo, aumentamos las iteraciones de ruido
        actual_window_size = len(df)
        actual_windows = 1
        actual_iterations = target_files
        step_size = 1 
    else:
        actual_window_size = window_size
        actual_windows = needed_windows
        actual_iterations = iterations
        # FÓRMULA CLAVE: Calculamos el salto para repartir las ventanas
        if actual_windows > 1:
            step_size = (len(df) - actual_window_size) // (actual_windows - 1)
        else:
            step_size = 0

    # Generación de ventanas
    for w in range(actual_windows):
        start = w * step_size
        # Evitar pasarse del final por errores de redondeo
        if start + actual_window_size > len(df):
            start = len(df) - actual_window_size
            
        window = df.iloc[start : start + actual_window_size].copy()
        
        # Generación de versiones con ruido por cada ventana
        for i in range(actual_iterations):
            features = window.iloc[:, :-1].copy()
            label = window.iloc[:, -1:].copy()
            
            # Jittering Proporcional
            noise = np.random.normal(1, noise_level, features.shape)
            features_aug = features * noise
            
            df_aug = pd.concat([features_aug, label], axis=1)
            augmented_samples.append(df_aug)
            
    # Si por redondeo falta alguna, cortamos o avisamos (opcional)
    return augmented_samples[:target_files]

def process_balanced_data(input_folder_name, output_folder_name, target_per_file=10):
    input_path = os.path.join(script_dir, input_folder_name)
    output_path = os.path.join(script_dir, output_folder_name)

    if not os.path.exists(input_path):
        print(f"Error: No existe {input_folder_name}")
        return

    if not os.path.exists(output_path):
        os.makedirs(output_path)

    for filename in os.listdir(input_path):
        if filename.endswith(".txt"):
            try:
                df = pd.read_csv(os.path.join(input_path, filename), sep='\s+', decimal=',')
                
                # Ejecutamos el aumento con el objetivo fijo
                new_samples = augment_pipeline_fixed(
                    df, 
                    window_size=100,     # Tamaño de cada muestra nueva
                    target_files=target_per_file, # CUÁNTOS archivos quieres por cada original
                    iterations=2,        # Cuántas variaciones de ruido por trozo
                    noise_level=0.005
                )
                
                name_base = os.path.splitext(filename)[0]
                for idx, aug_df in enumerate(new_samples, 1):
                    new_name = f"{name_base}-P{idx}.txt"
                    aug_df.to_csv(os.path.join(output_path, new_name), sep=' ', decimal=',', index=False)
                
                print(f"Hecho: {filename} -> {len(new_samples)} archivos exactos.")
            except Exception as e:
                print(f"Error en {filename}: {e}")

# --- CONFIGURACIÓN ---
# Cambia el 10 por el número de archivos que quieras generar por cada .txt original
OBJETIVO_POR_ARCHIVO = 10 

folders = {"BUENO": "BUENO-PLUS", "MALO": "MALO-PLUS"}

for ori, dest in folders.items():
    process_balanced_data(ori, dest, target_per_file=OBJETIVO_POR_ARCHIVO)

print(f"\nProceso finalizado. Cada archivo original ha generado {OBJETIVO_POR_ARCHIVO} versiones.")