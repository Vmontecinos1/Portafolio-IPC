# Portafolio-IPC

## 1. Descripción
Este proyecto es un monitor de coyuntura macroeconómica diseñado para analizar y pronosticar el comportamiento de los precios en la economía chilena, basándose en la interacción de 12 variables económicas clave.

  Variable Objetivo: La inflación, medida a través de la variación interanual del Índice de Precios al Consumidor (IPC) en Chile. Su extracción y análisis se realiza a nivel mensual, con cobertura continua desde diciembre de 2009, permitiendo estimar el ritmo de convergencia hacia la meta institucional del 3% del Banco Central de Chile.
Pregunta de Proyección: ¿Cuál será la trayectoria de la inflación interanual en Chile durante los próximos 12 a 24 meses? Y de forma paralela, ¿Cuáles son los principales riesgos que podrían desviarla de la convergencia hacia la meta del 3%?
Fundamento Económico: La proyección se sostiene en el análisis de 12 series (IMACEC, IPP, TPM, M1, Tipo de Cambio, entre otras) conectadas a la inflación mediante cuatro mecanismos de transmisión: Traspaso Cambiario y Costos de Producción, Mercado Laboral y Presiones de Demanda, Política Monetaria y Liquidez, y Expectativas e Inercia Inflacionaria.
Integrantes: Benjamín Paredes, Joaquín González, Vicente Montecinos, Giordano Mazzarelli.

## 2. Requisitos
Entorno de ejecución: Python 3.9 o superior.
Dependencias: El proyecto utiliza librerías específicas para la extracción de datos mediante APIs, conexión a bases de datos SQLite y análisis de datos. Para instalarlas todas de una vez, ejecuta:
    ```bash
    pip install -r requirements.txt
    ```

## 3. Credenciales
Para descargar las series desde las APIs (Banco Central de Chile y FRED) es estrictamente necesario configurar las variables de entorno de manera local:
1.  En la raíz del repositorio, busca el archivo de plantilla llamado `.env.example`.
2.  Haz una copia exacta de este archivo y renómbralo únicamente como `.env`.
3.  Abre `.env` y pega tus tokens o claves de API personales junto a las variables correspondientes (sin comillas).
4.  Atención de Seguridad: El archivo `.env` ya está excluido por el `.gitignore`. Nunca lo fuerces ni subas tus claves a GitHub.

## 4. Reproducción
Para garantizar que cualquier colaborador externo pueda reproducir la base de datos y el análisis de coyuntura, sigue las instrucciones en este orden exacto:

1.  Clona el repositorio en tu máquina local:
    ```bash
    git clone https://github.com/Vmontecinos1/Portafolio-IPC.git
    cd Portafolio-IPC
    ```
2.  Crea y activa un entorno virtual para aislar las dependencias:
    ```bash
    python -m venv env
    Dependiendo si es Win o Mac
    # En Windows: env\Scripts\activate
    # En macOS/Linux: source env/bin/activate
    ```
3.  Instala los requisitos del proyecto:
    ```bash
    pip install -r requiregit push origin mainments.txt
    ```
4.  Ejecuta el pipeline de extracción y carga (ETL):
    Corre el script principal fijando la fecha de corte. Reemplaza `AAAA-MM-DD` con la fecha límite de análisis acordada por el equipo  `2026-10-01`.
    ```bash
    python src/carga_db.py -hasta AAAA-MM-DD
    ```
    Nota: El comando debe finalizar devolviendo en consola un aviso `[OK]` por cada una de las 12 series del catálogo. Si observas un `[ERROR]`, revisa tu conexión o credenciales antes de continuar.

## 5. Estructura de carpetas
El flujo de trabajo modular del repositorio se organiza de la siguiente forma:
 `src/`: Contiene el código fuente de extracción. Destacan `config.py` (que alberga el catálogo cerrado con las 12 series, sus APIs y frecuencias) y el script `carga_db.py`.
  `sql/`: Almacena el archivo `.sql` de consultas de la base de datos. Aquí se incluyen los `JOIN` para unir series con temas, `GROUP BY` para colapsar datos diarios a mensuales, y las funciones de ventana (`PARTITION BY`) para calcular variaciones interanuales y promedios móviles.
  `notebooks/`: Alberga el cuaderno Jupyter de análisis de coyuntura inicial. Este archivo se alimenta directamente de la base de datos mediante `pd.read_sql()`, evitando recálculos en Pandas y centrándose en la graficación (con títulos, unidades, fechas y fuentes) y en las lecturas económicas de cada visualización.