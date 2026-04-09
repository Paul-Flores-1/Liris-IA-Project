import firebase_admin
from firebase_admin import credentials, firestore
import json

def subir_catalogo_liris():
    # 1. Conexión con tu cuenta de Firebase usando tu key.json
    print("Conectando a Firebase...")
    cred = credentials.Certificate("key.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # 2. Leer el archivo JSON que acabamos de crear
    print("Leyendo dataset_liris_100.json...")
    with open('dataset_liris_100.json', 'r', encoding='utf-8') as f:
        perfumes = json.load(f)

    # 3. Subir los documentos a la colección 'productos'
    coleccion = "productos"
    print(f"🔥 Iniciando carga de {len(perfumes)} perfumes a Firestore...")

    for p in perfumes:
        try:
            # Crear un ID de documento único y limpio (ej: "versace_eros_edp")
            doc_id = f"{p['marca']}_{p['nombre']}".replace(" ", "_").lower()
            
            # Subir o actualizar el documento en Firebase
            db.collection(coleccion).document(doc_id).set(p)
            print(f"✅ Subido: {p['marca']} - {p['nombre']}")
            
        except Exception as e:
            print(f"❌ Error subiendo {p['marca']} - {p['nombre']}: {e}")

    print("\n🚀 ¡Carga completada! Revisa tu consola de Firebase.")

if __name__ == "__main__":
    subir_catalogo_liris()