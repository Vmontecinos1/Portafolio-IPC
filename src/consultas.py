"""
Ejecuta las consultas de sql/03_consultas_inflacion.sql desde Python.

El archivo .sql está dividido en bloques que empiezan con "-- nombre: xxx".
  - Los bloques que crean vistas (vista_mensual, vista_cambios) se ejecutan con
    crear_vistas().
  - Los bloques SELECT se leen como DataFrame con consulta("nombre").

Así los cálculos (paso a mensual, variaciones, rezagos) quedan en SQL y Python
solo los lee para graficar.

Uso rápido (revisión de la base, Etapa 3 de la guía):
    python src/consultas.py
"""
from __future__ import annotations

import re

import pandas as pd
from sqlalchemy import create_engine, text

try:
    import config
except ImportError:
    from src import config  # type: ignore

ARCHIVO_SQL = config.RUTA_SQL / "03_consultas_inflacion.sql"
FECHA_CORTE = getattr(config, "FECHA_CORTE", "2026-09-30")
VARIABLE_OBJETIVO = getattr(config, "VARIABLE_OBJETIVO", "F074.IPC.IND.Z.EP23.C.M")
VISTAS = ["vista_mensual", "vista_cambios"]   # en este orden: la 2da usa la 1ra


def leer_bloques() -> dict[str, str]:
    """Devuelve {nombre: texto_sql} a partir de los marcadores '-- nombre: xxx'."""
    contenido = ARCHIVO_SQL.read_text(encoding="utf-8")
    partes = re.split(r"^-- nombre:\s*(\w+)\s*$", contenido, flags=re.MULTILINE)
    # partes = [encabezado, nombre1, sql1, nombre2, sql2, ...]
    return {nombre: sql.strip() for nombre, sql in zip(partes[1::2], partes[2::2])}


def obtener_engine():
    if not config.RUTA_DB.exists():
        raise FileNotFoundError(
            f"No existe {config.RUTA_DB}. Primero corran: python src/carga_db.py --hasta {FECHA_CORTE}"
        )
    return create_engine(f"sqlite:///{config.RUTA_DB}")


def sentencias(sql: str) -> list[str]:
    """Separa un bloque en sentencias y descarta las que son solo comentarios."""
    salida = []
    for s in sql.split(";"):
        codigo = "\n".join(l for l in s.splitlines() if not l.strip().startswith("--")).strip()
        if codigo:
            salida.append(codigo)
    return salida


def crear_vistas(engine=None) -> None:
    engine = engine or obtener_engine()
    bloques = leer_bloques()
    with engine.begin() as conn:
        for nombre in VISTAS:
            for s in sentencias(bloques[nombre]):
                conn.execute(text(s))


def consulta(nombre: str, engine=None, **params) -> pd.DataFrame:
    """Ejecuta un bloque SELECT del archivo .sql y lo devuelve como DataFrame."""
    engine = engine or obtener_engine()
    sql = leer_bloques()[nombre]
    params.setdefault("corte", FECHA_CORTE)
    params.setdefault("objetivo", VARIABLE_OBJETIVO)
    # Solo se pasan los parámetros que la consulta usa
    usados = {k: v for k, v in params.items() if f":{k}" in sql}
    df = pd.read_sql(text(sentencias(sql)[0]), engine, params=usados)
    for col in ("mes", "ultimo_mes"):
        if col in df.columns:
            df[col] = pd.to_datetime(df[col])
    return df


if __name__ == "__main__":
    pd.set_option("display.width", 160)
    pd.set_option("display.max_rows", 100)
    print(consulta("revision_base").to_string(index=False))
    print("\nControles de calidad (todos deben ser 0):")
    print(consulta("chequeo_integridad").to_string(index=False))
    crear_vistas()
    print("\nInflación a 12 meses, últimos 6 meses (calculada en SQL):")
    print(consulta("inflacion").tail(6).to_string(index=False))
