# Liris IA - Asistente Inteligente de Perfumería

**Liris IA** es una solución de E-commerce que integra Inteligencia Artificial para transformar la experiencia de compra. A diferencia de los filtros tradicionales, Liris utiliza un modelo de lenguaje (Google T5) para entender la intención del usuario y recomendar perfumes basándose en descripciones naturales.

##  Características Principales
* **Motor de NLP (Google T5):** Capacidad para interpretar consultas complejas en lenguaje natural (ej. *"Busco un aroma cítrico para usar de día en la playa"*).
* **Recomendación Generativa:** El sistema genera descripciones detalladas y sugerencias personalizadas, actuando como un asesor experto virtual.
* **Integración Móvil:** Aplicación desarrollada en **Flutter** con interfaz fluida para interactuar con el agente.
* **Backend Cloud:** Uso de **Firebase** para la gestión de datos y autenticación de usuarios.

## Stack Tecnológico
* **Frontend:** Flutter (Dart).
* **Inteligencia Artificial:** Python, Google T5 (Text-to-Text Transfer Transformer).
* **Base de Datos:** Firebase / Cloud Firestore.

## Cómo funciona
1. El usuario describe lo que busca (sentimientos, ocasiones, notas olfativas).
2. El modelo T5 procesa la entrada y extrae las características clave.
3. El sistema busca en la base de datos vectorial y devuelve las mejores coincidencias con una justificación generada por IA.

---
*Proyecto desarrollado por Alan Paul Santiago Flores.*