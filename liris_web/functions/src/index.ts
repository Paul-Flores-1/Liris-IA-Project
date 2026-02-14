import {onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

// Esta es tu primera función que se puede llamar desde la app
export const getGreeting = onCall((request) => {
  // 1. Registra el texto que envía la app. Útil para depurar.
  const userInput = request.data.text;
  logger.info(`Recibido el siguiente texto: ${userInput}`);

  // 2. Prepara una respuesta simple
  const responseMessage = `Tu backend dice: recibí tu mensaje '${userInput}'`;

  // 3. Devuelve la respuesta a la aplicación de Flutter
  return {
    message: responseMessage,
  };
});