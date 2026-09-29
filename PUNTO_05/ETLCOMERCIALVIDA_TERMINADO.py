#pip install pandas sqlalchemy pymysql #INSTALAR LIBERIAS EN CMD

#-------------------------------------------
# PROCESO ETL COMERCIAL VIDA
#-------------------------------------------

#IMPORTANDO LIBERIAS
import logging
import pandas as pd  
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from pathlib import Path

# ============================================================
# 1. CONFIGURACIÓN DEL LOG
# ============================================================
CARPETA_SCRIPT = Path(__file__).resolve().parent

# Ruta exacta del archivo log
RUTA_LOG = CARPETA_SCRIPT / "etl_comercial_vida.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(
            RUTA_LOG,
            mode="w",
            encoding="utf-8"
        ),
        logging.StreamHandler()
    ],
    force=True
)

print("El log se guardará en:")
print(RUTA_LOG)


# ============================================================
# 2. CONEXIONES
# ============================================================

USUARIO = "root"
CONTRASENA = "--"
HOST = "localhost"
PUERTO = 3306

url_origen = URL.create(
    drivername="mysql+pymysql",
    username=USUARIO,
    password=CONTRASENA,
    host=HOST,
    port=PUERTO,
    database="COMERCIAL_VIDA"
)

url_dw = URL.create(
    drivername="mysql+pymysql",
    username=USUARIO,
    password=CONTRASENA,
    host=HOST,
    port=PUERTO,
    database="DW_COMERCIAL_VIDA"
)

engine_origen = create_engine(url_origen)
engine_dw = create_engine(url_dw)
# ============================================================
# 3. EXTRACCIÓN
# ============================================================
# ----- FECHA -----

dim_fecha = pd.read_sql(
    """
    SELECT DISTINCT Fecha
    FROM VENTA;
    """,
    engine_origen
)

# ----- PRODUCTO -----

dim_producto = pd.read_sql(
    """
    SELECT
        p.IdProducto,
        p.Nombre,
        p.Marca,
        p.Modelo,
        p.IdCategoria,
        c.Nombre AS NombreCategoria,
        c.Descripcion AS DescripcionCategoria
    FROM PRODUCTO p
    INNER JOIN CATEGORIA c
        ON p.IdCategoria = c.IdCategoria;
    """,
    engine_origen
)

# ----- CLIENTE -----

dim_cliente = pd.read_sql(
    """
    SELECT
        c.IdCliente,
        c.Correo,
        c.Telefono,
        c.Direccion,

        cn.Nombre,
        cn.Apellido,
        cn.DNI,

        ce.RUC,
        ce.RazonSocial

    FROM CLIENTE c

    LEFT JOIN CLIENTE_NATURAL cn
        ON c.IdCliente = cn.IdCliente

    LEFT JOIN CLIENTE_EMPRESA ce
        ON c.IdCliente = ce.IdCliente;
    """,
    engine_origen
)

# ----- EMPLEADO -----

dim_empleado = pd.read_sql(
    """
    SELECT
        IdEmpleado,
        Nombre,
        Estado,
        Fecha_Ingreso,
        Cargo
    FROM EMPLEADO;
    """,
    engine_origen
)
# ----- VENTAS -----

ventas = pd.read_sql(
    """
    SELECT
        dv.IdDetalleVenta,
        v.IdVenta,
        v.Fecha,
        v.IdCliente,
        v.IdEmpleado,
        dv.IdProducto,
        dv.PrecioUnitario,
        dv.Cantidad
    FROM VENTA v
    INNER JOIN DETALLE_VENTA dv
        ON v.IdVenta = dv.IdVenta;
    """,
    engine_origen
)


logging.info(f"Fechas extraídas: {len(dim_fecha)}")
logging.info(f"Productos extraídos: {len(dim_producto)}")
logging.info(f"Clientes extraídos: {len(dim_cliente)}")
logging.info(f"Empleados extraídos: {len(dim_empleado)}")
logging.info(f"Detalles de venta extraídos: {len(ventas)}")

# ============================================================
# 4. TRANSFORMACIÓN
# ============================================================

# ----- Eliminación de duplicados -----

dim_fecha = dim_fecha.drop_duplicates()
dim_producto = dim_producto.drop_duplicates(
    subset=["IdProducto"]
)
dim_cliente = dim_cliente.drop_duplicates(
    subset=["IdCliente"]
)
dim_empleado = dim_empleado.drop_duplicates(
    subset=["IdEmpleado"]
)
ventas = ventas.drop_duplicates(
    subset=["IdDetalleVenta"]
)

# ----- Normalización de fechas -----

dim_fecha["Fecha"] = pd.to_datetime(
    dim_fecha["Fecha"]
).dt.date

dim_empleado["Fecha_Ingreso"] = pd.to_datetime(
    dim_empleado["Fecha_Ingreso"]
).dt.date

ventas["Fecha"] = pd.to_datetime(
    ventas["Fecha"]
).dt.date

# ----- Limpieza de textos -----

def limpiar_textos(df):

    columnas_texto = df.select_dtypes(
        include="object"
    ).columns

    for columna in columnas_texto:

        df[columna] = df[columna].apply(
            lambda x: x.strip()
            if isinstance(x, str)
            else x
        )

    return df


dim_producto = limpiar_textos(dim_producto)
dim_cliente = limpiar_textos(dim_cliente)
dim_empleado = limpiar_textos(dim_empleado)


# ----- Validaciones básicas -----

ventas["PrecioUnitario"] = pd.to_numeric(
    ventas["PrecioUnitario"]
)

ventas["Cantidad"] = pd.to_numeric(
    ventas["Cantidad"]
)


if (ventas["PrecioUnitario"] <= 0).any():
    raise ValueError(
        "Se encontraron precios unitarios inválidos"
    )


if (ventas["Cantidad"] <= 0).any():
    raise ValueError(
        "Se encontraron cantidades inválidas"
    )


# ----- ENRIQUECIMIENTO -----
# Campo calculado para la tabla de hechos

ventas["ImporteVenta"] = (
    ventas["PrecioUnitario"]
    * ventas["Cantidad"]
).round(2)


logging.info("Transformación completada")
logging.info(f"Registros preparados para FactVenta: {len(ventas)}")

# ============================================================
# 5. LIMPIEZA DEL DW PARA PRUEBA DEL ETL
# ============================================================

with engine_dw.begin() as conexion:

    conexion.execute(
        text("DELETE FROM FactVenta")
    )

    conexion.execute(
        text("DELETE FROM DimFecha")
    )

    conexion.execute(
        text("DELETE FROM DimProducto")
    )

    conexion.execute(
        text("DELETE FROM DimCliente")
    )

    conexion.execute(
        text("DELETE FROM DimEmpleado")
    )

    conexion.execute(
        text("ALTER TABLE FactVenta AUTO_INCREMENT = 1")
    )

    conexion.execute(
        text("ALTER TABLE DimFecha AUTO_INCREMENT = 1")
    )

    conexion.execute(
        text("ALTER TABLE DimProducto AUTO_INCREMENT = 1")
    )

    conexion.execute(
        text("ALTER TABLE DimCliente AUTO_INCREMENT = 1")
    )

    conexion.execute(
        text("ALTER TABLE DimEmpleado AUTO_INCREMENT = 1")
    )

# ============================================================
# 6. CARGA DE DIMENSIONES
# ============================================================

logging.info("Iniciando carga de dimensiones")


dim_fecha.to_sql(
    "DimFecha",
    engine_dw,
    if_exists="append",
    index=False
)


dim_producto.to_sql(
    "DimProducto",
    engine_dw,
    if_exists="append",
    index=False
)


dim_cliente.to_sql(
    "DimCliente",
    engine_dw,
    if_exists="append",
    index=False
)


dim_empleado.to_sql(
    "DimEmpleado",
    engine_dw,
    if_exists="append",
    index=False
)


logging.info(f"DimFecha cargada: {len(dim_fecha)}")
logging.info(f"DimProducto cargada: {len(dim_producto)}")
logging.info(f"DimCliente cargada: {len(dim_cliente)}")
logging.info(f"DimEmpleado cargada: {len(dim_empleado)}")

# ============================================================
# 7. RECUPERAR CLAVES DEL DW
# ============================================================

fecha_key = pd.read_sql(
    """
    SELECT FechaKey, Fecha
    FROM DimFecha
    """,
    engine_dw
)

producto_key = pd.read_sql(
    """
    SELECT ProductoKey, IdProducto
    FROM DimProducto
    """,
    engine_dw
)

cliente_key = pd.read_sql(
    """
    SELECT ClienteKey, IdCliente
    FROM DimCliente
    """,
    engine_dw
)

empleado_key = pd.read_sql(
    """
    SELECT EmpleadoKey, IdEmpleado
    FROM DimEmpleado
    """,
    engine_dw
)


fecha_key["Fecha"] = pd.to_datetime(
    fecha_key["Fecha"]
).dt.date

# ============================================================
# 8. RELACIONAR HECHOS CON LAS DIMENSIONES
# ============================================================

fact_venta = ventas.merge(
    fecha_key,
    on="Fecha",
    how="left"
)

fact_venta = fact_venta.merge(
    producto_key,
    on="IdProducto",
    how="left"
)

fact_venta = fact_venta.merge(
    cliente_key,
    on="IdCliente",
    how="left"
)

fact_venta = fact_venta.merge(
    empleado_key,
    on="IdEmpleado",
    how="left"
)


# Verificar que todas las claves fueron encontradas

claves = [
    "FechaKey",
    "ProductoKey",
    "ClienteKey",
    "EmpleadoKey"
]


if fact_venta[claves].isnull().any().any():

    raise ValueError(
        "Existen registros de venta sin dimensión relacionada"
    )

# ============================================================
# 9. PREPARAR FACTVENTA
# ============================================================

fact_venta = fact_venta[
    [
        "FechaKey",
        "ProductoKey",
        "ClienteKey",
        "EmpleadoKey",
        "IdDetalleVenta",
        "IdVenta",
        "PrecioUnitario",
        "Cantidad",
        "ImporteVenta"
    ]
]

# ============================================================
# 10. CARGAR TABLA DE HECHOS
# ============================================================

fact_venta.to_sql(
    "FactVenta",
    engine_dw,
    if_exists="append",
    index=False
)


logging.info(
    f"FactVenta cargada: {len(fact_venta)} registros"
)

# ============================================================
# 11. VALIDACIÓN FUENTE VS DW
# ============================================================

validacion_fuente = pd.read_sql(
    """
    SELECT
        COUNT(*) AS Registros,
        SUM(Cantidad) AS Unidades,
        SUM(PrecioUnitario * Cantidad) AS Total
    FROM DETALLE_VENTA;
    """,
    engine_origen
)


validacion_dw = pd.read_sql(
    """
    SELECT
        COUNT(*) AS Registros,
        SUM(Cantidad) AS Unidades,
        SUM(ImporteVenta) AS Total
    FROM FactVenta;
    """,
    engine_dw
)


registros_fuente = int(
    validacion_fuente.loc[0, "Registros"]
)

registros_dw = int(
    validacion_dw.loc[0, "Registros"]
)

unidades_fuente = int(
    validacion_fuente.loc[0, "Unidades"]
)

unidades_dw = int(
    validacion_dw.loc[0, "Unidades"]
)

total_fuente = round(
    float(validacion_fuente.loc[0, "Total"]),
    2
)

total_dw = round(
    float(validacion_dw.loc[0, "Total"]),
    2
)


logging.info(
    f"VALIDACIÓN REGISTROS: "
    f"Fuente={registros_fuente} | DW={registros_dw}"
)

logging.info(
    f"VALIDACIÓN UNIDADES: "
    f"Fuente={unidades_fuente} | DW={unidades_dw}"
)

logging.info(
    f"VALIDACIÓN TOTAL: "
    f"Fuente={total_fuente} | DW={total_dw}"
)


if (
    registros_fuente != registros_dw
    or unidades_fuente != unidades_dw
    or total_fuente != total_dw
):

    raise ValueError(
        "La validación Fuente vs DW no coincide"
    )


logging.info(
    "ETL FINALIZADO CORRECTAMENTE"
)

logging.info(ventas.head())

logging.info(
    ventas[
        [
            "IdDetalleVenta",
            "PrecioUnitario",
            "Cantidad",
            "ImporteVenta"
        ]
    ].head()
)


