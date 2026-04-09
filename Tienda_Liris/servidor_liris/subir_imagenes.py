import firebase_admin
from firebase_admin import credentials, firestore, storage
import os

# Tu bucket exacto de la captura
BUCKET_NAME = 'liris-s2.firebasestorage.app'

def subir_e_enlazar_imagenes():
    print("🔌 Conectando a Firebase...")
    
    cred = credentials.Certificate("key.json")
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred, {
            'storageBucket': BUCKET_NAME
        })
        
    db = firestore.client()
    bucket = storage.bucket()
    
    # La carpeta que me mostraste en tu captura
    carpeta = "imagenes"
    
    if not os.path.exists(carpeta):
        print(f"❌ No se encontró la carpeta '{carpeta}'.")
        return

    print(f"☁️ Subiendo fotos a Firebase Storage y actualizando Firestore...")
    
    for archivo in os.listdir(carpeta):
        if archivo.endswith('.png'):
            # Quitamos el .png para que coincida EXACTAMENTE con el ID del documento
            doc_id = archivo.replace('.png', '')
            ruta_local = os.path.join(carpeta, archivo)
            
            ruta_storage = f"perfumes/{archivo}" 
            
            try:
                # 1. Subir la imagen a Storage
                blob = bucket.blob(ruta_storage)
                blob.upload_from_filename(ruta_local)
                
                # 2. Hacerla pública
                blob.make_public()
                url_publica = blob.public_url
                
                # 3. Actualizar Firestore
                db.collection("productos").document(doc_id).update({
                    "imagen_url": url_publica
                })
                print(f"✅ Éxito: {archivo} enlazada a '{doc_id}'")
                
            except Exception as e:
                print(f"❌ Error con {archivo}: {e}")

    print("\n🚀 ¡Todas las imágenes listas en tu base de datos!")

if __name__ == "__main__":
    subir_e_enlazar_imagenes()