# Archivo: servidor_liris/main.py (Versión v8.0 - FIX FINAL Lógica de Búsqueda)

import os
import ast
import logging
import firebase_admin
import vertexai
import mercadopago
import time
from google.api_core import exceptions
from vertexai.generative_models import GenerativeModel
from flask import Flask, request, jsonify
from flask_cors import CORS
from firebase_admin import credentials, firestore
from google.oauth2 import service_account

# --- CONFIGURACIÓN DE LOGGING MEJORADO ---
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --- 1. CONFIGURACIÓN INICIAL ---
KEY_JSON_PATH = 'key.json'
db = None
vertex_cred = None

try:
    fb_cred = credentials.Certificate(KEY_JSON_PATH)
    firebase_admin.initialize_app(fb_cred)
    vertex_cred = service_account.Credentials.from_service_account_file(KEY_JSON_PATH)
    db = firestore.client()
    logger.info("✅ Firebase y Vertex cargados correctamente")
except Exception as e:
    logger.error(f"❌ ERROR inicializando Firebase/Vertex: {e}")
    try:
        firebase_admin.initialize_app()
        db = firestore.client()
        logger.info("✅ Firebase inicializado con credenciales por defecto")
    except Exception as e2:
        logger.error(f"❌ ERROR en fallback de Firebase: {e2}")

app = Flask(__name__)
CORS(app)

# --- CONFIGURACIÓN MERCADO PAGO ---
try:
    # (El token de MP no se muestra por seguridad)
    sdk = mercadopago.SDK("APP_USR-4222169977116231-112819-87d2bb3e72bfe55dc416a474cbcc279f-3025217311")
    logger.info("✅ Mercado Pago SDK inicializado")
except Exception as e:
    logger.error(f"❌ ERROR inicializando Mercado Pago: {e}")
    sdk = None

# --- 2. CONFIGURACIÓN DE GEMINI ---
model = None
try:
    if vertex_cred:
        vertexai.init(project="liris-s2", location="us-central1", credentials=vertex_cred)
        model = GenerativeModel("gemini-2.0-flash-exp")  
        logger.info("✅ Modelo Gemini cargado correctamente")
    else:
        logger.warning("⚠️ Vertex credentials no disponibles, intentando con credenciales por defecto")
        vertexai.init(project="liris-s2", location="us-central1")
        model = GenerativeModel("gemini-2.0-flash-exp")
        logger.info("✅ Modelo Gemini cargado con credenciales por defecto")
except Exception as e:
    logger.error(f"❌ ERROR cargando Gemini: {e}")
    try:
        model = GenerativeModel("gemini-1.5-flash")
        logger.info("✅ Cargado modelo alternativo: gemini-1.5-flash")
    except Exception as e2:
        logger.error(f"❌ ERROR con modelo alternativo: {e2}")

# --- DICCIONARIO MAESTRO DE SINÓNIMOS ---
SINONIMOS_EXPANSION = {
    'dulce': ['vainilla', 'ambar', 'ámbar', 'haba tonka', 'chocolate', 'caramelo', 'frutal', 'gourmand', 'canela', 'miel', 'coco', 'algodon', 'algodón', 'azucar', 'azúcar'],
    'fresco': ['citrico', 'cítrico', 'limon', 'limón', 'bergamota', 'marino', 'agua', 'azul', 'menta', 'salvia', 'jengibre', 'toronja', 'mandarina'],
    'amaderado': ['madera', 'cedro', 'sandalo', 'sándalo', 'vetiver', 'patchouli', 'cipres', 'ciprés', 'roble', 'oud'],
    'elegante': ['cuero', 'madera', 'cedro', 'sandalo', 'sándalo', 'vetiver', 'incienso', 'oud', 'tabaco', 'iris', 'formal', 'traje'],
    'floral': ['rosa', 'jazmin', 'jazmín', 'lirio', 'violeta', 'gardenia', 'magnolia', 'peonia', 'peonía', 'neroli', 'ylang'],
    'especiado': ['pimienta', 'cardamomo', 'nuez moscada', 'clavo', 'jengibre', 'canela', 'azafran', 'azafrán'],
    'citrico': ['limon', 'limón', 'naranja', 'bergamota', 'mandarina', 'pomelo', 'toronja', 'lima', 'citrico', 'cítrico'],
    'frutal': ['manzana', 'pera', 'durazno', 'ciruela', 'frambuesa', 'mora', 'mango', 'piña', 'frutal'],
    'fiesta': ['menta', 'vainilla', 'cuero', 'pimienta', 'canela', 'seductor', 'noche', 'club', 'intenso'],
    'noche': ['oud', 'ambar', 'ámbar', 'almizcle', 'vainilla', 'intenso', 'sensual', 'especiado', 'nocturno'],
    'oficina': ['iris', 'citrico', 'cítrico', 'lavanda', 'limpio', 'jabon', 'jabón', 'almizcle', 'fresco', 'ligero', 'formal'],
    'dia': ['citrico', 'cítrico', 'fresco', 'ligero', 'limpio', 'verde', 'te', 'té', 'diario'],
    'deportivo': ['marino', 'agua', 'menta', 'fresco', 'citrico', 'cítrico', 'dinamico', 'dinámico', 'sport'],
    'economico': ['menos de 500', 'barato', 'accesible', 'precio bajo', 'económico'],
    'premium': ['luxury', 'exclusivo', 'nicho', 'alta gama', 'caro'],
    'lavanda': ['lavanda', 'lavender'],
    'vainilla': ['vainilla', 'vanilla'],
    'ambroxan': ['ambroxan', 'ambrox'],
    'bergamota': ['bergamota', 'bergamot'],
}

# --- PROMPT CEREBRO ---
prompt_cerebro = """
Eres el CEREBRO de un buscador de perfumes. Tu trabajo es extraer la intención del usuario.

Responde SOLAMENTE con un diccionario Python válido con estas claves:
{
    'tipo': 'busqueda' o 'chat' o 'info_perfume' o 'opinion_perfume',
    'ingredientes_clave': ['lista', 'de', 'ingredientes', 'aromas'],
    'sexo': 'Caballero' o 'Dama' o None,
    'ocasiones': ['dia', 'noche', 'oficina', 'fiesta', 'casual', 'formal'],
    'precio_min': numero o None,
    'precio_max': numero o None,
    'duracion': 'corta' o 'media' o 'larga' o None,
    'cantidad_pedida': 1,
    'perfume_especifico': 'nombre exacto del perfume' o None
}

TIPOS DE INTENCIÓN:
- 'busqueda': Usuario busca recomendaciones generales ("perfume fresco", "algo para la noche")
- 'info_perfume': Usuario pregunta sobre un perfume específico ("¿qué tal el Sauvage?", "info de Bleu de Chanel")
- 'opinion_perfume': Usuario pide opinión sobre comprar un perfume ("¿me recomiendas el Sauvage?", "¿debería comprar X?")
- 'chat': Conversación casual sin búsqueda de perfumes

EXTRACCIÓN DE DATOS:
- Ingredientes/Aromas: dulce, fresco, amaderado, cítrico, floral, especiado, frutal, marino, etc.
- Sexo: Si dice "hombre/caballero/masculino" → 'Caballero', "mujer/dama/femenino" → 'Dama', si no menciona → None
- Precio: Si dice "menos de 500" → precio_max:500, "entre 300 y 600" → precio_min:300, precio_max:600
- Duración: "que dure mucho/todo el día" → 'larga', "moderado" → 'media', "ligero" → 'corta'
- CRÍTICO - Cantidad: Ignora la cantidad pedida, siempre debe ser 1 en el diccionario.

EJEMPLOS:
- "Quiero algo dulce para fiesta" → {'tipo': 'busqueda', 'ingredientes_clave': ['dulce', 'vainilla'], 'ocasiones': ['fiesta', 'noche'], 'cantidad_pedida': 1}
- "¿Tienes el Sauvage de Dior?" → {'tipo': 'info_perfume', 'perfume_especifico': 'Sauvage', 'cantidad_pedida': 1}
- "5 perfumes frescos para hombre que duren mucho" → {'tipo': 'busqueda', 'ingredientes_clave': ['fresco', 'citrico'], 'sexo': 'Caballero', 'duracion': 'larga', 'cantidad_pedida': 1}
"""

prompt_personalidad = """
Eres LIRIS, una experta asesora de perfumes con 20 años de experiencia. Tu estilo es:
- Tono: Elegante pero accesible, cálida y apasionada por los aromas.
- Usas emojis ocasionalmente (✨, 🌸, 🌿, 💎, 🌊)
- Destacas las notas olfativas, durabilidad y ocasiones de uso
- SIEMPRE mencionas el precio de cada perfume
- Estilo: No pareces un robot. Hablas como una asesora experta en una tienda de lujo.

REGLAS DE ORO:
1. SENSORIALIDAD: No digas "huele a limón". Di "tiene una salida vibrante de limón que energiza".
2. HONESTIDAD: Si un perfume dura poco, di "ideal para citas cortas o reaplicar", no mientas diciendo que dura todo el día.

REGLAS SEGÚN MODO:

1. RECOMENDACIÓN SIMPLE (Todos los modos de búsqueda):
   - Siempre recomienda SOLO 1 PERFUME (el mejor match).
   - Da todos los detalles: notas, durabilidad, proyección, ocasiones, precio.
   - Preséntalo como la "joya" que encontraste para él/ella.

2. SIN RESULTADOS:
   - Disculpate amablemente
   - Pregunta por preferencias más específicas (precio, aroma, ocasión)
   - Sugiere revisar otras categorías

3. CHAT CASUAL:
   - Responde de forma amigable y breve
   - Ofrece ayuda para buscar perfumes

FORMATO DE RESPUESTA:
- NO uses asteriscos, negritas ni markdown
- Usa emojis para separar secciones
- Sé concisa pero completa
"""

def buscar_en_firestore(filtros, usar_filtros_laxos=False):
    """Busca perfumes en Firestore según los filtros"""
    if not db:
        logger.error("❌ Base de datos no disponible")
        return []
    
    candidatos = []
    try:
        logger.info(f"🔍 Buscando con filtros: {filtros}, laxos: {usar_filtros_laxos}")
        perfumes_ref = db.collection('perfumes')
        docs = perfumes_ref.stream()
        
        # Normalizar ingredientes a buscar (todo en minúsculas)
        ingredientes_a_buscar = set()
        if 'ingredientes_clave' in filtros:
            raw_ingredients = [ing.lower() for ing in filtros['ingredientes_clave']]
            ingredientes_a_buscar.update(raw_ingredients)
            
            # Expandir con sinónimos
            for cat, sinonimos in SINONIMOS_EXPANSION.items():
                if cat.lower() in raw_ingredients or any(s.lower() in raw_ingredients for s in sinonimos):
                    ingredientes_a_buscar.update([s.lower() for s in sinonimos])
        
        logger.info(f"📝 Ingredientes expandidos: {ingredientes_a_buscar}")

        perfume_count = 0
        for doc in docs:
            perfume_count += 1
            p = doc.to_dict()
            p['id'] = doc.id
            p['nombre_real'] = p.get('nombre', 'Desconocido')
            nombre_lower = p['nombre_real'].lower()
            marca_lower = p.get('marca', '').lower()
            
            # --- CORRECCIÓN CRÍTICA 1: Búsqueda específica segura ---
            if filtros.get('perfume_especifico') is not None:
                perfume_target = filtros['perfume_especifico']
                objetivo = perfume_target.lower()
                
                # Si coincide, retornamos inmediatamente
                if objetivo in nombre_lower or objetivo in marca_lower or nombre_lower in objetivo:
                    logger.info(f"✅ Perfume específico encontrado: {p['nombre_real']}")
                    return [p]
                
                # Si buscamos algo específico y este NO es, saltamos al siguiente
                continue 

            puntaje = 0
            
            # Filtro de sexo (CASE INSENSITIVE)
            sexo_p = str(p.get('sexo', '')).lower()
            sexo_f = str(filtros.get('sexo', '')).lower() if filtros.get('sexo') else None
            
            if sexo_f:
                # Normalizar "caballero" y "hombre" | "dama" y "mujer"
                if sexo_f in ['caballero', 'hombre', 'masculino']:
                    sexo_f = 'caballero'
                elif sexo_f in ['dama', 'mujer', 'femenino']:
                    sexo_f = 'dama'
                
                if sexo_p in ['caballero', 'hombre', 'masculino']:
                    sexo_p = 'caballero'
                elif sexo_p in ['dama', 'mujer', 'femenino']:
                    sexo_p = 'dama'
                elif sexo_p in ['unisex', 'unisexo']:
                    sexo_p = 'unisex'
                
                # Aplicar filtro estricto (salvo en búsqueda laxa)
                if sexo_p != sexo_f and sexo_p != 'unisex' and not usar_filtros_laxos:
                    continue

            # Filtro de precio (RANGO)
            precio_perfume = p.get('precio', 9999)
            if 'precio_min' in filtros and filtros['precio_min'] is not None and precio_perfume < filtros['precio_min']:
                continue
            if 'precio_max' in filtros and filtros['precio_max'] is not None and precio_perfume > filtros['precio_max']:
                continue

            # Filtro de duración (campo numérico en tu BD: 8 horas)
            if 'duracion' in filtros and filtros['duracion']:
                duracion_bd = p.get('duracion', 0)
                duracion_req = filtros['duracion'].lower()
                
                if duracion_req == 'larga' and duracion_bd >= 8:
                    puntaje += 5
                elif duracion_req == 'media' and 4 <= duracion_bd < 8:
                    puntaje += 3
                elif duracion_req == 'corta' and duracion_bd < 4:
                    puntaje += 3

            # Match de ingredientes (buscar en notas.salida, notas.corazon, notas.fondo)
            if ingredientes_a_buscar:
                notas_obj = p.get('notas', {})
                texto_perfume = ""
                
                if isinstance(notas_obj, dict):
                    salida = str(notas_obj.get('salida', '')).lower()
                    corazon = str(notas_obj.get('corazon', '')).lower()
                    fondo = str(notas_obj.get('fondo', '')).lower()
                    texto_perfume = f"{salida} {corazon} {fondo}"
                else:
                    texto_perfume = str(notas_obj).lower()
                
                texto_perfume += f" {str(p.get('clima_ideal', '')).lower()} {str(p.get('marca', '')).lower()}"
                
                matches_ingredientes = 0
                for ing in ingredientes_a_buscar:
                    if ing in texto_perfume:
                        matches_ingredientes += 1
                        puntaje += 5
                
                if matches_ingredientes > 2:
                    puntaje += 10
            
            # Match de ocasiones (CASE INSENSITIVE)
            if 'ocasiones' in filtros and filtros['ocasiones']:
                ocasiones_db = p.get('ocasiones', [])
                if isinstance(ocasiones_db, list):
                    ocasiones_db = [str(o).lower() for o in ocasiones_db]
                else:
                    ocasiones_db = [str(ocasiones_db).lower()]
                
                ocasiones_ia = [str(o).lower() for o in filtros['ocasiones']]
                matches_ocasion = sum(1 for item in ocasiones_ia if item in ocasiones_db)
                puntaje += matches_ocasion * 4
                
                if 'versatil' in ocasiones_db and matches_ocasion == 0:
                    puntaje += 2

            # Si es búsqueda laxa, damos un punto base para que entre a candidatos
            # si pasó los filtros duros (sexo/precio)
            if usar_filtros_laxos:
                puntaje += 1
                
            if puntaje > 0:
                p['match_score'] = puntaje
                candidatos.append(p)

        logger.info(f"📊 Procesados {perfume_count} perfumes, encontrados {len(candidatos)} candidatos")

    except Exception as e:
        logger.error(f"❌ Error en Firestore: {e}", exc_info=True)
        return []
    
    return candidatos

def encontrar_mejor_perfume(caracteristicas_ia, perfil_sexo):
    """Encuentra los mejores perfumes según características"""
    logger.info(f"🎯 Buscando perfumes con: {caracteristicas_ia}, perfil_sexo: {perfil_sexo}")
    
    # --- CORRECCIÓN CRÍTICA 2: Inyección segura de perfil ---
    if caracteristicas_ia.get('sexo') is None and caracteristicas_ia.get('perfume_especifico') is None and perfil_sexo:
        caracteristicas_ia['sexo'] = perfil_sexo
        logger.info(f"👤 Usando sexo del perfil: {perfil_sexo}")
    
    # La cantidad siempre será 1 por la lógica de main_route
    cantidad_a_buscar = 1

    resultados = buscar_en_firestore(caracteristicas_ia, usar_filtros_laxos=False)
    
    # Fallback si no hay resultados exactos
    # --- CORRECCIÓN CRÍTICA 3: Trigger seguro de búsqueda laxa ---
    if not resultados and caracteristicas_ia.get('perfume_especifico') is None:
        logger.info("⚠️ Sin resultados exactos. Intentando búsqueda laxa (quitando sexo, manteniendo aroma)...")
        # Quitar el filtro de sexo para buscar en Unisex/Opuesto (fallback)
        filtros_lax = caracteristicas_ia.copy()
        if 'sexo' in filtros_lax:
            del filtros_lax['sexo']
        
        resultados = buscar_en_firestore(filtros_lax, usar_filtros_laxos=True)
    
    if not resultados:
        logger.warning("❌ No se encontraron perfumes")
        return []
    
    # Si es búsqueda de perfume específico, retornar completo
    if caracteristicas_ia.get('perfume_especifico') is not None:
        return resultados
    
    # Ordenar por puntaje
    resultados.sort(key=lambda x: x.get('match_score', 0), reverse=True)
    
    # Obtener solo la cantidad solicitada (que siempre es 1 en esta versión)
    top = resultados[:cantidad_a_buscar]
    
    logger.info(f"✅ Retornando {len(top)} perfumes de {len(resultados)} encontrados (Cantidad forzada: 1)")
    
    return top


# --- RUTA DE HEALTH CHECK ---
@app.route('/health', methods=['GET'])
def health_check():
    """Verifica el estado del sistema"""
    status = {
        'status': 'ok',
        'version': '8.0 (FIX COMPLETE)',
        'firebase': db is not None,
        'gemini': model is not None,
        'mercadopago': sdk is not None
    }
    logger.info(f"🏥 Health check: {status}")
    return jsonify(status), 200


# --- RUTA: CREAR PAGO MERCADO PAGO ---
@app.route('/crear-pago', methods=['POST'])
def crear_pago():
    """Crea una preferencia de pago en Mercado Pago"""
    try:
        if not sdk:
            return jsonify({"error": "Mercado Pago no disponible"}), 503
            
        data = request.json
        logger.info(f"💰 Solicitud de pago recibida: {data}")

        preference_data = {
            "items": [
                {
                    "title": data.get('title', 'Perfume Paul Flores'),
                    "quantity": int(data.get('quantity', 1)),
                    "unit_price": float(data.get('unit_price', 100.0)),
                    "currency_id": "MXN"
                }
            ],
            "back_urls": {
                "success": "https://www.paulflores.com/success",
                "failure": "https://www.paulflores.com/failure",
                "pending": "https://www.paulflores.com/pending"
            },
            "auto_return": "approved",
        }

        preference_response = sdk.preference().create(preference_data)
        preference = preference_response["response"]
        checkout_url = preference["init_point"]

        logger.info(f"✅ Link de pago generado: {checkout_url}")
        
        return jsonify({
            "status": "success",
            "checkout_url": checkout_url
        }), 200

    except Exception as e:
        logger.error(f"❌ Error creando pago: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


# --- RUTA PRINCIPAL (CHAT) ---
@app.route('/', methods=['POST', 'GET'])
def main_route():
    """Ruta principal del chatbot"""
    if request.method == 'GET':
        return jsonify({
            'status': 'Liris v8.0 Activo (FIX COMPLETE)',
            'gemini': model is not None,
            'firebase': db is not None
        })
    
    if not model:
        logger.error("❌ Modelo Gemini no disponible")
        return jsonify({
            'recommendation': 'El sistema está experimentando problemas. Por favor intenta más tarde.',
            'error': 'model_unavailable'
        }), 503

    try:
        data = request.json
        prompt_u = data.get('prompt', '').strip()
        uid = data.get('userId')
        
        logger.info(f"📩 Mensaje recibido: '{prompt_u}' de usuario: {uid}")
        
        if not prompt_u:
            return jsonify({'recommendation': '¿Qué tipo de perfume buscas hoy? 🌸'}), 400
        
        # PASO 1: Análisis con el CEREBRO (AHORA CON RETRIES)
        logger.info("🧠 Analizando intención del usuario con reintentos...")
        texto_crudo = None
        
        # Bucle de 3 reintentos (1er intento + 2 reintentos)
        for i in range(3):
            try:
                resp_cerebro = model.generate_content(
                    f"{prompt_cerebro}\n\nUsuario dijo: '{prompt_u}'\n\nRespuesta:",
                    generation_config={
                        "temperature": 0.3,
                        "max_output_tokens": 500
                    }
                )
                texto_crudo = resp_cerebro.text
                logger.info(f"✅ Respuesta del cerebro en intento {i+1}.")
                break # Si tiene éxito, sale del bucle
                
            except exceptions.ResourceExhausted as e: # Captura específica del error 429
                logger.warning(f"⚠️ Intento {i+1} falló (429/Cuota). Reintentando en {2**(i+1)} segundos...")
                if i < 2:
                    time.sleep(2**(i+1)) # Espera 2s, 4s
                else:
                    logger.error("❌ Todos los reintentos fallaron.")
                    raise e # Lanza el error para ser capturado por el bloque externo
            
            except Exception as e:
                logger.error(f"❌ Error desconocido en intento {i+1}: {e}", exc_info=True)
                raise e # Lanza otros errores para ser capturados por el bloque externo
        
        if not texto_crudo:
             raise Exception("Análisis del Cerebro falló después de múltiples intentos.")

        # PASO 2: Extraer diccionario
        dicc = {'tipo': 'chat'}
        try:
            texto_crudo = texto_crudo.replace('```json', '').replace('```python', '').replace('```', '').strip()
            inicio = texto_crudo.find('{')
            fin = texto_crudo.rfind('}') + 1
            if inicio != -1 and fin > inicio:
                dicc = ast.literal_eval(texto_crudo[inicio:fin])
                logger.info(f"✅ Diccionario extraído: {dicc}")
        except Exception as e:
            logger.warning(f"⚠️ No se pudo extraer diccionario: {e}")

        # PASO 3: Forzar Cantidad a 1 (FIX V7.8)
        if dicc.get('tipo') in ['busqueda', 'info_perfume', 'opinion_perfume']:
            dicc['cantidad_pedida'] = 1
            logger.info("✅ FIX V7.8: Cantidad forzada a 1.")


        # PASO 4: Forzar búsqueda si hay palabras clave
        palabras_clave_busqueda = [
            'recomienda', 'recomiendame', 'busco', 'quiero', 'perfume', 
            'hablame', 'dime de', 'tienes el', 'para hombre', 'para mujer',
            'necesito', 'algo', 'alguno', 'dame', 'muestrame', 'que', 'cual',
            'precio', 'barato', 'economico', 'caro', 'premium',
            'dure', 'duracion', 'duradero', 'projection',
            'fresco', 'dulce', 'amaderado', 'floral', 'citrico'
        ]
        mensaje_lower = prompt_u.lower()
        
        if dicc.get('tipo') == 'chat':
            if any(palabra in mensaje_lower for palabra in palabras_clave_busqueda):
                logger.info("🔄 Forzando modo búsqueda por palabra clave")
                dicc['tipo'] = 'busqueda'
                if 'ingredientes_clave' not in dicc:
                    dicc['ingredientes_clave'] = []
                    for palabra in mensaje_lower.split():
                        if palabra in SINONIMOS_EXPANSION:
                            dicc['ingredientes_clave'].append(palabra)

        # PASO 5: Obtener perfil del usuario y normalizar sexo
        perfil_usuario = {}
        perfil_sexo_normalizado = None 
        info_perfumes = []
        
        try:
            if uid and db:
                doc = db.collection('usuarios').document(uid).get()
                if doc.exists:
                    data = doc.to_dict()
                    raw_sexo = data.get('genero', '').lower()
                    
                    # Normalización del sexo del perfil (FIX "OTRO" -> NO PREFERENCE)
                    if raw_sexo in ['masculino', 'hombre', 'caballero']:
                        perfil_sexo_normalizado = 'Caballero'
                    elif raw_sexo in ['femenino', 'mujer', 'dama']:
                        perfil_sexo_normalizado = 'Dama'
                    elif raw_sexo == 'otro': 
                        perfil_sexo_normalizado = None 
                        logger.info("✅ FIX V7.8: Género 'otro' detectado, forzando a NO PREFERENCE (None).")
                        
                    perfil_usuario = {
                        'nombre': data.get('nombre', 'Amigo/a'),
                        'sexo_bd': perfil_sexo_normalizado, 
                        'preferencias': data.get('preferencias', []), 
                        'ocasiones': data.get('ocasion', []), 
                        'clima': data.get('clima', '') 
                    }
                    logger.info(f"👤 Perfil cargado para {perfil_usuario['nombre']}: {perfil_usuario}")
        except Exception as e:
            logger.warning(f"⚠️ No se pudo obtener perfil: {e}")

        # PASO 6: Buscar perfumes si es necesario
        if dicc.get('tipo') in ['busqueda', 'info_perfume', 'opinion_perfume']:
            logger.info("🔍 Iniciando búsqueda de perfumes...")
            
            lista_objs = encontrar_mejor_perfume(dicc, perfil_sexo_normalizado) # Enviamos el sexo normalizado
            
            # Construir información detallada de cada perfume
            for item in lista_objs:
                if isinstance(item, dict):
                    # Extraer notas de forma segura
                    notas_obj = item.get('notas', {})
                    notas_texto = "N/A"
                    if isinstance(notas_obj, dict):
                        salida = notas_obj.get('salida', '-')
                        corazon = notas_obj.get('corazon', '-')
                        fondo = notas_obj.get('fondo', '-')
                        notas_texto = f"Salida: {salida}, Corazón: {corazon}, Fondo: {fondo}"
                    
                    duracion_str = f"{item.get('duracion', 'N/A')} horas" if isinstance(item.get('duracion'), (int, float)) else 'N/A'
                    tam_str = f"{item.get('tamaño', 'N/A')}ml" if isinstance(item.get('tamaño'), (int, float)) else str(item.get('tamaño', 'N/A'))
                    
                    info_perfumes.append({
                        'id': item.get('id', ''),
                        'nombre': item['nombre_real'],
                        'marca': item.get('marca', 'N/A'),
                        'precio': item.get('precio', 'N/A'),
                        'notas': notas_texto,
                        'duracion': duracion_str,
                        'clima_ideal': item.get('clima_ideal', 'N/A'),
                        'ocasiones': item.get('ocasiones', []),
                        'sexo': item.get('sexo', 'N/A'),
                        'tamaño': tam_str,
                        'imagen_url': item.get('imagen_url', ''),
                        'match_score': item.get('match_score', 0)
                    })
            
            logger.info(f"📦 Perfumes preparados: {len(info_perfumes)}")

        # PASO 7: Determinar contexto
        ctx_modo = 'chat'
        if dicc.get('tipo') == 'info_perfume':
            ctx_modo = 'info_perfume' if info_perfumes else 'perfume_no_encontrado'
        elif dicc.get('tipo') == 'opinion_perfume':
            ctx_modo = 'opinion_perfume' if info_perfumes else 'perfume_no_encontrado'
        elif dicc.get('tipo') == 'busqueda':
            # Todos los modos de búsqueda ahora son recomendación simple (1 perfume)
            ctx_modo = 'recomendacion_simple' if info_perfumes else 'sin_resultados'
        
        logger.info(f"🎭 Modo de respuesta: {ctx_modo}")

        # PASO 8: Generar respuesta final
        
        # Formatear perfumes para el prompt
        perfumes_texto = ""
        if info_perfumes:
            # Aunque info_perfumes solo debe tener 1, el bucle asegura el formato
            for idx, p in enumerate(info_perfumes, 1):
                perfumes_texto += f"\n{idx}. {p['nombre']} - {p['marca']}"
                perfumes_texto += f"\n   Precio: ${p['precio']} MXN"
                perfumes_texto += f"\n   Sexo: {p['sexo']}"
                perfumes_texto += f"\n   Tamaño: {p['tamaño']}"
                perfumes_texto += f"\n   Notas: {p['notas']}"
                perfumes_texto += f"\n   Duración: {p['duracion']}"
                perfumes_texto += f"\n   Ocasiones: {', '.join(p['ocasiones']) if p['ocasiones'] else 'Versátil'}"
                perfumes_texto += f"\n"
        else:
            perfumes_texto = "No se encontraron perfumes que coincidan con los criterios."

        # PASO 9: Prompt Final
        nombre_usuario = perfil_usuario.get('nombre', '')
        
        prompt_final = f"""
{prompt_personalidad}

CONTEXTO ACTUAL:
- Modo de respuesta: {ctx_modo}
- Usuario dijo: "{prompt_u}"
- Perfume recomendado: {info_perfumes[0]['nombre'] if info_perfumes else 'N/A'}

INFORMACIÓN DEL PERFUME DISPONIBLE:
{perfumes_texto} 

INSTRUCCIONES FINALES:
- CRÍTICO: SÓLO UTILIZA LA INFORMACIÓN DE LA SECCIÓN "INFORMACIÓN DEL PERFUME DISPONIBLE" para construir tu respuesta. NUNCA INVENTES NADA.
- { '- Presenta este perfume como la joya perfecta que encontraste para el usuario. Sé elegante y persuasiva.' if ctx_modo in ['recomendacion_simple', 'info_perfume', 'opinion_perfume'] else ''}
- { '- Si no hay resultados, disculpate amablemente y pregunta más detalles o sugiere otras opciones.' if ctx_modo in ['sin_resultados', 'perfume_no_encontrado'] else ''}
- { '- Responde de forma amigable y breve, e invita a descubrir un aroma.' if ctx_modo == 'chat' else ''}
- NO uses asteriscos, ni markdown, ni negritas.
"""
        
        try:
            logger.info("💬 Generando respuesta final...")
            resp_final = model.generate_content(
                prompt_final,
                generation_config={
                    "temperature": 0.7,
                    "max_output_tokens": 800
                }
            )
            respuesta = resp_final.text.strip().replace('*', '')
            logger.info(f"✅ Respuesta generada: {respuesta[:100]}...")
            
            return jsonify({'recommendation': respuesta})
            
        except Exception as e:
            logger.error(f"❌ Error generando respuesta final: {e}", exc_info=True)
            return jsonify({
                'recommendation': 'Ups, tuve un problema técnico. ¿Podrías intentar de nuevo?',
                'error': 'generation_failed'
            }), 500

    except Exception as e:
        logger.error(f"❌ Error fatal en main_route: {e}", exc_info=True)
        return jsonify({
            'recommendation': "Lo siento, ocurrió un error. Por favor contacta a soporte.",
            'error': 'fatal_error'
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    logger.info(f"🚀 Iniciando servidor en puerto {port}")
    app.run(debug=False, host='0.0.0.0', port=port)