"""
Configuración central del proyecto - Hito 2

Las credenciales se leen desde el archivo .env (NUNCA subir credenciales a GitHub).
Copien .env.example a .env y completen sus claves.
"""
import os
from pathlib import Path

from dotenv import load_dotenv

# Rutas del proyecto
RAIZ = Path(__file__).resolve().parents[1]
RUTA_DATOS = RAIZ / "data"
RUTA_DB = RUTA_DATOS / "coyuntura.db"
RUTA_SQL = RAIZ / "sql"

# Cargar credenciales desde .env
load_dotenv(RAIZ / ".env")

# --- Banco Central de Chile ---
# Registro gratuito en: https://si3.bcentral.cl/Siete/es/Siete/API
BCCH_USUARIO = os.getenv("BCCH_USUARIO", "")
BCCH_PASSWORD = os.getenv("BCCH_PASSWORD", "")
BCCH_TOKEN = os.getenv("BCCH_TOKEN", "")

# --- FRED (Reserva Federal de St. Louis) ---
# API key gratuita en: https://fred.stlouisfed.org/docs/api/api_key.html
FRED_API_KEY = os.getenv("FRED_API_KEY", "")

# ============================================================
# CATÁLOGO DE SERIES DEL PROYECTO
# ============================================================
SERIES_BCCH = [
    # PRECIOS/INFLACIÓN
    # Razón economica: Variable objetivo principal para proyectar la inflacion y costo de vida.
    ("F074.IPC.IND.Z.EP23.C.M", "IPC General Empalmado", "M", "índice 2023=100", 2),
    #  Razón economica:  Mide presiones inflacionarias en el rubro de mayor volatilidad e impacto en el consumo básico
    ("F074.IPCA.IND.Z.EP23.Z.M", "IPC Alimentos", "M", "índice 2023=100", 2),
    # Razón economica: Toma la variación mensual porcentual directa del IPC
    ("F074.IPC.VAR.Z.Z.C.M", "IPC Variación Mensual", "M", "var. % mensual", 2),
    
    # Actividad económica
    # Razón economica: PRincipal indicador mensual del PIB para evaluar el movimineto de la demanda interna
    ("F032.IMC.IND.Z.Z.EP18.Z.Z.0.M", "Imacec", "M", "índice 2018=100", 1),
    # Razón economica: Aísla factores estacionales y estancamientos para medir la tendencia real del crecimiento
    ("F032.IMC.IND.Z.Z.EP18.Z.Z.1.M", "Imacec Desestacionalizado", "M", "índice 2018=100", 1),
    
    # Politica monetaria
    # Razón economica: Instrumento de politica monetaria del Banco Central que determina la tasa de interes de referencia
    ("F022.TPM.TIN.D001.NO.Z.D", "Tasa de Política Monetaria (TPM)", "D", "% anual", 4),
    
    # Sector Externo y divisas
    # Razón economica: El valor del dolar impacta directamente en los costos de importación y el IPC
    ("F073.TCO.PRE.Z.D", "Tipo de Cambio Observado (CLP/USD)", "D", "CLP/USD", 5),
    # Razón economica: Principal commodity de exportación: Variaciones impactan ingresos fiscales y tipo de cambio
    ("F072.CLP.PRE.Z.D", "Precio del Cobre", "D", "US$/lb", 5),
]

SERIES_FRED = [
    # Contexto internacional y Estados Unidos
    # Razón económica: Mide la inflación acumulada en EE.UU., afectando precios de bienes importados
    ("CPIAUCSL", "IPC Estados Unidos", "M", "índice 1982-84=100", 6),
    
    # Razón económica: Tasa de referencia de la FED que condiciona los flujos de capitales hacia economías emergentes
    ("FEDFUNDS", "Tasa Fed Funds (EE.UU.)", "M", "% anual", 6),
    
    # Razón económica: Mide la fortaleza del dólar frente a una canasta global de monedas de referencia
    ("DTWEXBGS", "Índice Dólar Global (Nominal Advanced Foreign Economies)", "M", "índice 2006=100", 6),
    
    # Razón económica: Indicador de rendimiento del bono a 10 años que refleja las expectativas macro de largo plazo
    ("GS10", "Tasa de Bonos del Tesoro EE.UU. 10 años", "M", "% anual", 6),
]
