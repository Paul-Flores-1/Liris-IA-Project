import os
#Compatibilidad Keras 3 con TF + Transformers
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
from transformers import T5Tokenizer, TFT5ForConditionalGeneration

#Resolver ruta del modelo de forma robusta
THIS_DIR = os.path.dirname(os.path.abspath(__file__))      # .../liris_web/ia_training
PROJECT_ROOT = os.path.dirname(THIS_DIR)                   # .../liris_web
MODEL_DIR = os.path.join(PROJECT_ROOT, "functions_python", "liris_ia_model")

print("Usando MODEL_DIR:", MODEL_DIR)

#Verificación previa (ayuda a depurar)
REQUIRED = ["spiece.model","config.json","tokenizer_config.json","special_tokens_map.json","added_tokens.json","tf_model.h5"]
for fname in REQUIRED:
    path = os.path.join(MODEL_DIR, fname)
    if not os.path.isfile(path):
        raise FileNotFoundError(f"Falta el archivo requerido: {path}")

#CARGAR EL MODELO Y TOKENIZADOR GUARDADOS
print(f"Cargando el modelo desde '{MODEL_DIR}'...")
tokenizer = T5Tokenizer.from_pretrained(MODEL_DIR)
model = TFT5ForConditionalGeneration.from_pretrained(MODEL_DIR)
print("✅ ¡Modelo cargado!")

#PREGUNTAR AQUÍ
input_text = "extract perfume features: me interesa un perfume con un aroma fresco para caballero"
print(f"\nPregunta a la IA: '{input_text}'")

#PROCESAR Y PREDECIR
inputs = tokenizer(input_text, return_tensors="tf").input_ids
outputs = model.generate(inputs, max_length=64, num_beams=4, early_stopping=True)
predicted_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

#MOSTRAR RESULTADO
print("\nRespuesta de la IA (JSON):")
print(predicted_text)

#intentar parsear a JSON
try:
    import json
    parsed = json.loads(predicted_text)
    print("\nJSON parseado:")
    print(parsed)
except Exception:
    pass
