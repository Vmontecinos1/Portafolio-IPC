# Monitor de Coyuntura y Proyección Macroeconómica

## 1. Descripción
- Variable objetivo: [ IPC ]
- Pregunta de proyección: [¿Cuál será la trayectoria de la inflación interanual en Chile durante los próximos 12 a 24 meses?] 
- Integrantes: [Joaquin Gonzalez , Vicente Montecinos , Benjamin Paredes y Giordano Mazzarelli]

## 2. Requisitos
- Python [3.14.7]
- Instalar las librerías:

      pip install -r requirements.txt

## 3. Credenciales
1. Copiar la plantilla de credenciales:

       copy .env.example .env

2. Abrir el archivo `.env` y completar las claves de la API del Banco Central y de FRED (los nombres de las variables están en `.env.example`).
3. No subir nunca el `.env` a GitHub.

## 4. Reproducción
Fecha de corte: [ 2026-09-01 ]

1. Crear la base y cargar los datos desde las APIs:

       python src/carga_db.py --hasta [2026-09-01 ]

2. Verificar que la carga termine con un `[OK]` por cada serie y ningún `[ERROR]`.
3. Abrir y ejecutar el notebook `Portafolio_CdD.ipynb` de principio a fin.

## 5. Estructura de carpetas
- `src/`
  - `config.py`: catálogo de series (Banco Central y FRED).
  - `extraccion.py`: descarga de las series desde las APIs.
  - `carga_db.py`: carga de las series a la base de datos.
  - `consultas.py`: ejecución de las consultas SQL desde Python.
- `sql/`
  - `01_esquema.sql`: definición de las tablas de la base.
  - `02_consultas_ejemplo.sql`: consultas de ejemplo.
  - `03_consultas_inflacion.sql`: consultas del análisis de coyuntura.
- `Portafolio_CdD.ipynb`: notebook con el análisis de coyuntura.
- `.env.example`: plantilla de credenciales (sin claves).
