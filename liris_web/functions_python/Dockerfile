# Usa una imagen base oficial de Python
FROM python:3.11-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia los archivos de requisitos e instálalos
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia todo el código fuente y el modelo al contenedor
COPY . .

# Expone el puerto que usará Flask/Gunicorn
EXPOSE 8080

# Comando para ejecutar la aplicación cuando el contenedor inicie
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app