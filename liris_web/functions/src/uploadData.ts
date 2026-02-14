// Importa las herramientas de Firebase Admin
import {initializeApp, cert} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import * as fs from "fs";
import * as path from "path";

// --- CONFIGURACIÓN ---
const serviceAccount = require("../serviceAccountKey.json");

// Inicializa la app de Firebase Admin
initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();
const perfumesCollection = db.collection("perfumes");

async function uploadPerfumes() {
  console.log("--- INICIANDO SCRIPT DE SUBIDA ---");

  // 1. VERIFICAR LECTURA DE ARCHIVO
  const dataPath = path.join(__dirname, "catalogo.json");
  let perfumesData;
  try {
    const fileContent = fs.readFileSync(dataPath, "utf-8");
    perfumesData = JSON.parse(fileContent);
    console.log(`✅ Archivo 'catalogo.json' leído. Se encontraron ${perfumesData.length} registros.`);
  } catch (error) {
    console.error("❌ ERROR: No se pudo leer el archivo 'catalogo.json'.", error);
    return; // Detiene el script si no se puede leer el archivo
  }

  if (!perfumesData || perfumesData.length === 0) {
    console.error("❌ ERROR: El archivo 'catalogo.json' está vacío. No hay datos para subir.");
    return;
  }

  // 2. PROCESAR Y SUBIR DATOS
  console.log(`\nIniciando subida de ${perfumesData.length} perfumes...`);
  let subidos = 0;
  let errores = 0;

  for (const perfume of perfumesData) {
    const nuevoPerfume = {
      nombre: perfume["Nombre del Perfume"] || "Sin nombre",
      marca: perfume["Marca"] || "Sin marca",
      precio: parseInt(perfume["Precio"]) || 0,
      tamaño: parseInt(perfume["Tamaño(ml)"]) || 0,
      ocasiones: [perfume["Ocasión"], perfume["Ocasión_1"]].filter(Boolean),
      clima_ideal: perfume["Clima_R"] || "Ambos",
      duracion: parseInt(perfume["Duracion (h)"]) || 0,
      sexo: perfume["Sexo"] || "Unisex",
      notas: {
        salida: perfume["Salida"] || "",
        corazon: perfume["Corazon"] || "",
        fondo: perfume["Fondo"] || "",
      },
    };

    try {
      await perfumesCollection.add(nuevoPerfume);
      subidos++;
    } catch (error) {
      console.error(`❌ Error al subir "${nuevoPerfume.nombre}":`, error);
      errores++;
    }
  }
  console.log(`\n--- REPORTE DE SUBIDA ---`);
  console.log(`✅ Perfumes procesados y subidos: ${subidos}`);
  console.log(`❌ Errores encontrados: ${errores}`);


  // 3. VERIFICACIÓN FINAL
  console.log("\nVerificando el número de documentos en Firestore...");
  try {
    const snapshot = await perfumesCollection.get();
    console.log(`✅ ¡Verificación exitosa! La colección 'perfumes' ahora contiene ${snapshot.size} documentos.`);
  } catch (error) {
    console.error("❌ Error al verificar la colección en Firestore.", error);
  }

  console.log("\n--- SCRIPT FINALIZADO ---");
}

// Llama a la función para que se ejecute
uploadPerfumes();