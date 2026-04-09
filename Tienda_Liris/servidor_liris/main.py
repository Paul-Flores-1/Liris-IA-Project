import firebase_admin
from firebase_admin import credentials, firestore
import json
import time

# 1. Conexión con tu nueva cuenta de Firebase
cred = credentials.Certificate("key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def subir_a_liris():
    # Cargamos el JSON que ya generaste
    with open('dataset_liris_100.json', 'r', encoding='utf-8') as f:
        perfumes = json.load(f)

    print(f"🔥 Iniciando carga masiva a la nueva cuenta de Liris...")

    collection_name = "productos" # Nombre de tu colección en Firestore

    for p in perfumes:
        try:
            # Creamos un ID único basado en marca y nombre
            doc_id = f"{p['marca']}_{p.get('nombre', p.get('coord', 'unknown'))}".replace(" ", "_").lower()
            
            # Subida a Firestore
            db.collection(collection_name).document(doc_id).set(p)
            print(f"✅ Subido: {p['marca']} - {p.get('nombre', 'Item')}")
            
        except Exception as e:
            print(f"❌ Error subiendo {p['marca']}: {e}")

    print("\n🚀 ¡Inventario completo en Firebase!")

if __name__ == "__main__":
    subir_a_liris()