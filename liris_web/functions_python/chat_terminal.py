import os
import json
import logging

# 1. Silenciar advertencias molestas de TensorFlow
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  
logging.getLogger('transformers').setLevel(logging.ERROR)

print("Cargando el cerebro de Liris... (esto puede tardar unos segundos)")

# 2. Cargar librerías de IA
try:
    import tensorflow as tf
    from transformers import T5Tokenizer, TFT5ForConditionalGeneration
except ImportError:
    print("\nError: Faltan librerías.")
    print("Ejecuta: pip install tensorflow transformers sentencepiece")
    exit()

# 3. Localizar el modelo
# Busca la carpeta 'liris_ia_model' en el mismo lugar donde está este script
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "liris_ia_model")

if not os.path.exists(MODEL_DIR):
    print(f"\n No encuentro la carpeta del modelo en: {MODEL_DIR}")
    print("Asegúrate de que 'liris_ia_model' esté junto a este archivo.")
    exit()

# 4. Cargar el modelo en memoria
try:
    tokenizer = T5Tokenizer.from_pretrained(MODEL_DIR)
    model = TFT5ForConditionalGeneration.from_pretrained(MODEL_DIR)
    print("¡Liris IA está lista! (Escribe 'salir' para terminar)")
    print("-" * 50)
except Exception as e:
    print(f"\nError cargando el modelo: {e}")
    exit()

# 5. Bucle de Chat (La conversación)
def interactuar():
    while True:
        # A. Recibir texto del usuario
        try:
            texto_usuario = input("\nTú: ")
        except KeyboardInterrupt:
            print("\n¡Hasta luego!")
            break

        if texto_usuario.lower() in ['salir', 'exit', 'bye']:
            print("¡Adiós!")
            break
        
        if not texto_usuario.strip():
            continue

        # B. Preparar el prompt (Prefijo mágico)
        # Es CRÍTICO poner "extract perfume features: " porque así entrenaste al modelo en train_model.py
        input_text = "extract perfume features: " + texto_usuario

        # C. Tokenizar (Convertir texto a números)
        inputs = tokenizer(input_text, return_tensors="tf").input_ids

        # D. Generar (La IA piensa)
        outputs = model.generate(
            inputs, 
            max_length=128, 
            num_beams=2,       # Usa 2 caminos para buscar la mejor respuesta
            early_stopping=True
        )

        # E. Decodificar (Convertir números a texto)
        prediccion_texto = tokenizer.decode(outputs[0], skip_special_tokens=True)

        # F. Mostrar resultado
        print(f"Liris (Raw): {prediccion_texto}")
        
        # G. Intentar mostrarlo bonito como JSON
        try:
            # Reemplazamos comillas simples por dobles por si acaso
            json_limpio = prediccion_texto.replace("'", '"')
            datos = json.loads(json_limpio)
            
            print("Interpretación:")
            if 'sexo' in datos: print(f"   - Género: {datos['sexo']}")
            if 'ocasiones' in datos: print(f"   - Ocasión: {', '.join(datos['ocasiones'])}")
            if 'notas' in datos: print(f"   - Notas: {', '.join(datos['notas'])}")
            if 'clima_ideal' in datos: print(f"   - Clima: {datos['clima_ideal']}")
            
        except json.JSONDecodeError:
            print("(La IA no generó un JSON válido, pero entendió la idea)")

# Ejecutar
if __name__ == "__main__":
    interactuar()