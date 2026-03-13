import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' # Limpia la consola de avisos

import tensorflow as tf
from transformers import T5Tokenizer, TFT5ForConditionalGeneration
from datasets import load_dataset

# --- CONFIGURACIÓN ---
MODEL_NAME = "t5-base"
DATASET_FILES = ["dataset_liris_v7_inteligente.jsonl"]
OUTPUT_MODEL_DIR = "./liris_ia_model"

def preprocess_data(examples):
    prefix = "extract perfume features: "
    inputs = [prefix + text for text in examples["input"]]
    targets = [str(output) for output in examples["output"]]
    model_inputs = tokenizer(inputs, max_length=128, truncation=True, padding="max_length")
    labels = tokenizer(targets, max_length=128, truncation=True, padding="max_length") 
    model_inputs["labels"] = labels["input_ids"]
    return model_inputs

# 1. CARGA DE DATOS
print("Cargando tokenizador y dataset...")
tokenizer = T5Tokenizer.from_pretrained(MODEL_NAME)
dataset = load_dataset("json", data_files=DATASET_FILES, split="train")

print("Preprocesando datos...")
tokenized_dataset = dataset.map(preprocess_data, batched=True, remove_columns=dataset.column_names)

# OPTIMIZACIÓN: Batch size de 8 para tus 32GB de RAM
tf_dataset = tokenized_dataset.to_tf_dataset(
    columns=["input_ids", "attention_mask", "labels"],
    shuffle=True,
    batch_size=8 
)

# 2. CARGA DEL MODELO
print(f"Cargando modelo base {MODEL_NAME}...")
model = TFT5ForConditionalGeneration.from_pretrained(MODEL_NAME, from_pt=True)

# Tasa de aprendizaje ideal para corrección de etiquetas
optimizer = tf.keras.optimizers.Adam(learning_rate=5e-5)
model.compile(optimizer=optimizer)

# 3. ENTRENAMIENTO
print("\n¡INICIANDO ENTRENAMIENTO EN CPU!")
print("Con 15 épocas, esto tomará unos minutos...")
model.fit(tf_dataset, epochs=15)

# 4. GUARDAR RESULTADO
if not os.path.exists(OUTPUT_MODEL_DIR):
    os.makedirs(OUTPUT_MODEL_DIR)

print(f"Guardando modelo en '{OUTPUT_MODEL_DIR}'...")
model.save_pretrained(OUTPUT_MODEL_DIR)
tokenizer.save_pretrained(OUTPUT_MODEL_DIR)
print("¡Liris ha sido reentrenada con éxito!")