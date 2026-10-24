# Monitor de Coyuntura y Proyección Macroeconómica

## 1. Descripción
- **Variable objetivo:** IPC (inflación a 12 meses en Chile)
- **Pregunta de proyección:** ¿Cuál será la trayectoria de la inflación interanual en Chile durante los próximos 12 a 24 meses?
- **Integrantes:** Joaquín González, Vicente Montecinos, Benjamín Paredes y Giordano Mazzarelli

## 2. Requisitos
- Python 3.14.7
- Instalar las librerías:

      pip install -r requirements.txt

## 3. Credenciales
1. Copiar la plantilla de credenciales:

       copy .env.example .env

   (en Mac o Linux: `cp .env.example .env`)

2. Abrir el archivo `.env` y completar las claves de la API del Banco Central (usuario y contraseña, o token) y de FRED. Los nombres de las variables están en `.env.example`.
3. No subir nunca el `.env` a GitHub (ya está en `.gitignore`).

## 4. Reproducción
Fecha de corte: **2026-09-30**

1. Crear la base y cargar los datos desde las APIs:

       python src/carga_db.py --hasta 2026-09-30

2. Verificar que la carga termine con un `[OK]` por cada una de las 13 series y ningún `[ERROR]`.
3. Revisar la calidad de la base (los tres controles deben dar 0):

       python src/consultas.py

4. Abrir y ejecutar el notebook `Portafolio_CdD.ipynb` de principio a fin.

## 5. Estructura de carpetas
- `src/`
  - `config.py`: catálogo de series (Banco Central y FRED), fecha de corte y variable objetivo.
  - `extraccion.py`: descarga de las series desde las APIs.
  - `carga_db.py`: carga de las series a la base de datos.
  - `consultas.py`: ejecución de las consultas SQL desde Python.
- `sql/`
  - `01_esquema.sql`: definición de las tablas de la base.
  - `02_consultas_ejemplo.sql`: consultas de ejemplo.
  - `03_consultas_inflacion.sql`: consultas del análisis de coyuntura.
- `data/`: base de datos `coyuntura.db` (se genera con `carga_db.py`, no se sube a GitHub).
- `Portafolio_CdD.ipynb`: notebook con el análisis de coyuntura.
- `.env.example`: plantilla de credenciales (sin claves).