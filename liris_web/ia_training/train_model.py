import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
from transformers import T5Tokenizer, TFT5ForConditionalGeneration
from datasets import load_dataset

# --- CONFIGURACIÓN DEL ENTRENAMIENTO ---
MODEL_NAME = "t5-base"
DATASET_FILES = [
    "training_data.jsonl"  # <-- ¡Este es el nombre correcto!
    
]
OUTPUT_MODEL_DIR = "./liris_ia_model"

def preprocess_data(examples):
    prefix = "extract perfume features: "
    inputs = [prefix + text for text in examples["input"]]
    targets = [str(output) for output in examples["output"]]
    
    model_inputs = tokenizer(inputs, max_length=128, truncation=True, padding="max_length")
    labels = tokenizer(targets, max_length=64, truncation=True, padding="max_length")

    model_inputs["labels"] = labels["input_ids"]
    return model_inputs

# --- 1. CARGAR EL TOKENIZADOR Y EL DATASET ---
print("Cargando el tokenizador...")
tokenizer = T5Tokenizer.from_pretrained(MODEL_NAME)

print(f"Cargando el dataset desde '{DATASET_FILES}'...")
dataset = load_dataset("json", data_files=DATASET_FILES, split="train")

print("Preprocesando los datos...")
tokenized_dataset = dataset.map(preprocess_data, batched=True, remove_columns=dataset.column_names)

tf_dataset = tokenized_dataset.to_tf_dataset(
    columns=["input_ids", "attention_mask", "labels"],
    shuffle=True,
    batch_size=2
)

# --- 2. CARGAR EL MODELO BASE Y CONFIGURAR EL ENTRENAMIENTO ---
print(f"Cargando el modelo base '{MODEL_NAME}'...")
# LA SOLUCIÓN ESTÁ AQUÍ: Añadimos from_pt=True
model = TFT5ForConditionalGeneration.from_pretrained(MODEL_NAME, from_pt=True)

optimizer = tf.keras.optimizers.Adam(learning_rate=5e-6)
model.compile(optimizer=optimizer)

# --- 3. ENTRENAR EL MODELO ---
print("\n¡INICIANDO EL ENTRENAMIENTO!")
print("Esto puede tardar varios minutos...")
model.fit(tf_dataset, epochs=10)
print("✅ ¡Entrenamiento completado!")

# --- 4. GUARDAR TU MODELO PERSONALIZADO ---
if not os.path.exists(OUTPUT_MODEL_DIR):
    os.makedirs(OUTPUT_MODEL_DIR)

print(f"Guardando el modelo entrenado en '{OUTPUT_MODEL_DIR}'...")
model.save_pretrained(OUTPUT_MODEL_DIR)
tokenizer.save_pretrained(OUTPUT_MODEL_DIR)
print("✅ ¡Modelo guardado exitosamente!")