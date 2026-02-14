# Archivo: functions_python/main.py (Versión Vertex AI - Identidad Forzada)

import os
import ast
import firebase_admin
import vertexai
from vertexai.generative_models import GenerativeModel
from flask import Flask, request, jsonify
from flask_cors import CORS
from firebase_admin import credentials, firestore

# ¡NUEVO! Importamos la librería para cargar credenciales de servicio
from google.oauth2 import service_account

# --- 1. CONFIGURACIÓN INICIAL ---

KEY_JSON_PATH = 'key.json'

try:
    # 1. Credenciales para Firebase
    fb_cred = credentials.Certificate(KEY_JSON_PATH)
    firebase_admin.initialize_app(fb_cred)

    # 2. ¡NUEVO! Credenciales para Vertex AI (usando el MISMO archivo)
    vertex_cred = service_account.Credentials.from_service_account_file(KEY_JSON_PATH)

except FileNotFoundError:
    print("ERROR CRITICO: key.json no encontrado.")
    firebase_admin.initialize_app() # Fallback para Firebase
    vertex_cred = None # Vertex fallará

db = firestore.client()
app = Flask(__name__)
CORS(app)

# --- 2. CONFIGURACIÓN DE GEMINI (Vertex AI) ---

try:
    if not vertex_cred:
        raise ValueError("Las credenciales de Vertex AI (key.json) no se cargaron.")

    # ¡CAMBIO! Pasamos las credenciales explícitamente
    vertexai.init(project="liris-s2", location="us-central1", credentials=vertex_cred)

    model = GenerativeModel("gemini-1.0-pro") 
    print("Modelo Vertex AI (Gemini) cargado exitosamente con key.json.")

except Exception as e:
    print(f"ERROR AL CONFIGURAR VERTEX AI: {e}")
    model = None

# --- 3. EL "SÚPER-PROMPT" (CEREBRO DE LIRIS) ---
# (Esta parte no cambia)
prompt_plantilla = """
Eres LIRIS, un asistente experto en perfumería para la tienda 'Paul Flores'.
Tu único trabajo es analizar la petición del usuario y extraer las características clave en un formato de diccionario de Python.
Responde *solamente* con el diccionario y nada más.

Las claves válidas del diccionario deben coincidir con los campos de la base de datos:
- 'sexo': ['caballero', 'dama', 'unisex']
- 'ocasiones': ['dia', 'noche', 'oficina', 'cita', 'casual', 'fiesta', 'invierno', 'verano']
- 'notas_clave': ['citrico', 'dulce', 'amaderado', 'floral', 'fresco', 'vainilla', 'cuero', 'frutal', 'ambar', 'especiado']
- 'tipo': ['eau de parfum', 'eau de toilette', 'parfum', 'eau de cologne']
- 'clima_ideal': ['calor', 'frio', 'templado']

EJEMPLOS:
Usuario: 'un perfume de cuero para hombre'
Respuesta: {'sexo': ['caballero'], 'notas_clave': ['cuero']}
Usuario: 'algo dulce para salir de noche en invierno'
Respuesta: {'notas_clave': ['dulce', 'vainilla'], 'ocasiones': ['noche'], 'clima_ideal': ['frio']}
Usuario: 'Hola, quiero oler bien'
Respuesta: {}
Usuario: 'un perfume fresco para el calor'
Respuesta: {'notas_clave': ['fresco', 'citrico'], 'clima_ideal': ['calor']}
"""

# --- 4. LA LÓGICA DE FILTRADO (BINARIZACIÓN - ESTA NO CAMBIA) ---
def encontrar_mejor_perfume(caracteristicas_ia):
    if not caracteristicas_ia:
        return "No pude identificar características específicas en tu petición. ¿Puedes ser más detallado? (ej. 'un perfume dulce y amaderado')"
    try:
        perfumes_ref = db.collection('perfumes')
        todos_los_perfumes = perfumes_ref.stream()
    except Exception as e:
        return f"Error al conectar con la base de datos: {e}"
    puntajes = {}
    for perfume_doc in todos_los_perfumes:
        perfume = perfume_doc.to_dict()
        nombre_perfume = perfume.get('nombre', 'Nombre Desconocido')
        puntaje_actual = 0
        if 'sexo' in caracteristicas_ia and perfume.get('sexo') in caracteristicas_ia['sexo']:
            puntaje_actual += 1
        if 'tipo' in caracteristicas_ia and perfume.get('tipo') in caracteristicas_ia['tipo']:
            puntaje_actual += 1
        if 'clima_ideal' in caracteristicas_ia and perfume.get('clima_ideal') in caracteristicas_ia['clima_ideal']:
            puntaje_actual += 1
        if 'ocasiones' in caracteristicas_ia:
            ocasiones_perfume = perfume.get('ocasiones', [])
            if any(item in ocasiones_perfume for item in caracteristicas_ia['ocasiones']):
                puntaje_actual += 1
        if 'notas_clave' in caracteristicas_ia:
            notas_perfume = perfume.get('notas_clave', [])
            if any(item in notas_perfume for item in caracteristicas_ia['notas_clave']):
                puntaje_actual += 1
        if puntaje_actual > 0:
            puntajes[nombre_perfume] = puntaje_actual
    if not puntajes:
        return "No encontré un perfume en mi catálogo que coincida exactamente con esas características. Intenta ser un poco más general."
    mejor_puntaje = max(puntajes.values())
    mejores_perfumes = [nombre for nombre, puntaje in puntajes.items() if puntaje == mejor_puntaje]
    if len(mejores_perfumes) == 1:
        return f"Basado en lo que buscas, te recomiendo: {mejores_perfumes[0]}"
    else:
        return f"Encontré varias opciones excelentes: {', '.join(mejores_perfumes)}"


# --- 5. LA RUTA DE LA API (ENDPOINT) ---
@app.route('/', methods=['POST', 'GET'])
def main_route():
    if request.method == 'GET':
        return "Servidor Liris IA (con Vertex AI) está funcionando. Usa POST para enviar un prompt."

    if not model:
        # (Restauramos el código de depuración por si acaso)
        return jsonify({'recommendation': 'ERROR CRÍTICO: El modelo Vertex AI no está inicializado.'})

    try:
        data = request.json
        prompt_usuario = data.get('prompt')
        if not prompt_usuario:
            return jsonify({'error': 'No se proporcionó "prompt".'}), 400

        prompt_completo = prompt_plantilla + f"\n\nUsuario: '{prompt_usuario}'\nRespuesta:"

        response = model.generate_content(prompt_completo)

        diccionario_texto = response.text.strip().replace("```python", "").replace("```", "").strip()

        try:
            caracteristicas_ia = ast.literal_eval(diccionario_texto)
        except Exception as e:
            error_msg = f"Error al parsear: {e}. Respuesta de Gemini: {diccionario_texto}"
            print(error_msg) 
            return jsonify({'recommendation': error_msg})

        recomendacion = encontrar_mejor_perfume(caracteristicas_ia)

        return jsonify({'recommendation': recomendacion})

    except Exception as e:
        # (Restauramos el código de depuración por si acaso)
        print(f"Error en main_route: {e}")
        return jsonify({'recommendation': f"Error de servidor: {str(e)}"})

# Esto es para pruebas locales
if __name__ == '__main__':
    app.run(debug=True, port=8080)