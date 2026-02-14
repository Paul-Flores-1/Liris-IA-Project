# generate_dataset.py (VERSIÓN 3.0 - FINAL)

import json
import random
from google.cloud import firestore
from google.oauth2 import service_account

KEY_PATH = "serviceAccountKey.json"
credentials = service_account.Credentials.from_service_account_file(KEY_PATH)
db = firestore.Client(credentials=credentials)

TEMPLATES = [
    "Busco un perfume para {a1}",
    "Recomiéndame una fragancia de {g} que sirva para {a1}",
    "Quiero algo para {a1} y que huela a {n1}",
    "Necesito un perfume de {g} para clima {c}",
    "¿Qué fragancia es buena para {a1} y {a2}?",
    "Una esencia con notas de {n1} para una ocasión {o1}",
    "Un aroma de {g} para {o1} que tenga {n1}",
]

def generate_examples_for_perfume(perfume_data):
    examples = []
    
    sexo = perfume_data.get("sexo", "Unisex").lower()
    ocasiones = perfume_data.get("ocasiones", [])
    clima = perfume_data.get("clima_ideal", "Ambos").lower()
    notas_dict = perfume_data.get("notas", {})
    notas = list(filter(None, [notas_dict.get(k) for k in ["salida", "corazon", "fondo"]]))

    # Generamos hasta 10 ejemplos variados por cada perfume
    for _ in range(10):
        template = random.choice(TEMPLATES)
        output_dict = {}
        
        # Atributos a usar
        chosen_ocasion1 = random.choice(ocasiones) if ocasiones else None
        chosen_ocasion2 = random.choice(ocasiones) if len(ocasiones) > 1 else None
        chosen_nota1 = random.choice(notas) if notas else None
        
        # Forzamos las reglas correctas en el output
        output_dict['sexo'] = sexo
        if chosen_ocasion1:
            output_dict['ocasiones'] = [chosen_ocasion1.lower()]
        if chosen_nota1:
            output_dict['notas'] = [chosen_nota1.lower()]
        if clima != "ambos":
            output_dict['clima_ideal'] = clima

        # Rellenamos la plantilla
        # Nos aseguramos de tener valores para evitar errores
        format_args = {
            "g": sexo,
            "c": clima,
            "a1": chosen_ocasion1.lower() if chosen_ocasion1 else "un evento",
            "a2": chosen_ocasion2.lower() if chosen_ocasion2 else "el día",
            "o1": chosen_ocasion1.lower() if chosen_ocasion1 else "salir",
            "n1": chosen_nota1.lower() if chosen_nota1 else "algo fresco",
        }
        
        input_text = template.format(**format_args)
        
        # Solo añadimos el ejemplo si el output no está vacío
        if len(output_dict) > 1:
            examples.append({"input": input_text, "output": output_dict})
            
    return examples

def main():
    print("Conectando a Firestore...")
    perfumes_ref = db.collection("perfumes")
    all_perfumes = list(perfumes_ref.stream())
    
    all_examples = []
    for perfume_doc in all_perfumes:
        perfume_dict = perfume_doc.to_dict()
        examples = generate_examples_for_perfume(perfume_dict)
        all_examples.extend(examples)
    
    # Eliminamos duplicados para tener un dataset más limpio
    unique_examples = [json.loads(t) for t in {json.dumps(d, sort_keys=True) for d in all_examples}]
    
    print(f"Se procesaron {len(all_perfumes)} perfumes.")
    print(f"Se generó un DATASET MAESTRO con {len(unique_examples)} ejemplos únicos de alta calidad.")

    output_filename = "training_data.jsonl"
    with open(output_filename, 'w', encoding='utf-8') as f:
        for example in unique_examples:
            f.write(json.dumps(example, ensure_ascii=False) + '\n')
            
    print(f"\n✅ ¡Dataset Maestro creado en '{output_filename}'!")

if __name__ == "__main__":
    main()