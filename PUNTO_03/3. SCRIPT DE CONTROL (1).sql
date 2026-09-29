/* =====================================================================
   3. SCRIPT DE CONTROL - BASE DE DATOS COMERCIAL_VIDA (MySQL 8)
   ===================================================================== */

USE COMERCIAL_VIDA;


/* =====================================================================
   3.1  CREACIÓN DE ROLES
   ===================================================================== */

-- Limpieza previa
DROP ROLE IF EXISTS 'rol_admin_bd','rol_ventas','rol_almacen','rol_contabilidad','rol_auditor';
DROP USER IF EXISTS 'adm_vida'@'localhost','vendedor01'@'localhost',
                    'almacen01'@'localhost','contador01'@'localhost','auditor01'@'localhost';

-- Creación de roles
CREATE ROLE 'rol_admin_bd';
CREATE ROLE 'rol_ventas';
CREATE ROLE 'rol_almacen';
CREATE ROLE 'rol_contabilidad';
CREATE ROLE 'rol_auditor';

-- Privilegios por rol
GRANT ALL PRIVILEGES ON COMERCIAL_VIDA.* TO 'rol_admin_bd' WITH GRANT OPTION;

GRANT SELECT                 ON COMERCIAL_VIDA.PRODUCTO          TO 'rol_ventas';
GRANT SELECT                 ON COMERCIAL_VIDA.CATEGORIA         TO 'rol_ventas';
GRANT SELECT                 ON COMERCIAL_VIDA.COMPATIBILIDAD    TO 'rol_ventas';
GRANT SELECT                 ON COMERCIAL_VIDA.MARCA_VEHICULO    TO 'rol_ventas';
GRANT SELECT                 ON COMERCIAL_VIDA.MODELO_VEHICULO   TO 'rol_ventas';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.CLIENTE           TO 'rol_ventas';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.CLIENTE_NATURAL   TO 'rol_ventas';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.CLIENTE_EMPRESA   TO 'rol_ventas';
GRANT SELECT, INSERT         ON COMERCIAL_VIDA.VENTA             TO 'rol_ventas';
GRANT SELECT, INSERT         ON COMERCIAL_VIDA.DETALLE_VENTA     TO 'rol_ventas';
GRANT SELECT, INSERT         ON COMERCIAL_VIDA.PAGO              TO 'rol_ventas';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.PAGO_VENTA        TO 'rol_ventas';
GRANT SELECT (IdEmpleado, Nombre, Cargo, Estado)
                             ON COMERCIAL_VIDA.EMPLEADO          TO 'rol_ventas';

GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.PRODUCTO          TO 'rol_almacen';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.CATEGORIA         TO 'rol_almacen';
GRANT SELECT, INSERT, UPDATE, DELETE
                             ON COMERCIAL_VIDA.COMPATIBILIDAD    TO 'rol_almacen';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.MARCA_VEHICULO    TO 'rol_almacen';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.MODELO_VEHICULO   TO 'rol_almacen';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.PROVEEDOR         TO 'rol_almacen';
GRANT SELECT, INSERT         ON COMERCIAL_VIDA.COMPRA            TO 'rol_almacen';
GRANT SELECT, INSERT         ON COMERCIAL_VIDA.DETALLE_COMPRA    TO 'rol_almacen';

GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.PAGO               TO 'rol_contabilidad';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.PAGO_VENTA         TO 'rol_contabilidad';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.PAGO_COMPRA        TO 'rol_contabilidad';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.COMPROBANTE        TO 'rol_contabilidad';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.COMPROBANTE_VENTA  TO 'rol_contabilidad';
GRANT SELECT, INSERT, UPDATE ON COMERCIAL_VIDA.COMPROBANTE_COMPRA TO 'rol_contabilidad';
GRANT SELECT                 ON COMERCIAL_VIDA.VENTA              TO 'rol_contabilidad';
GRANT SELECT                 ON COMERCIAL_VIDA.DETALLE_VENTA      TO 'rol_contabilidad';
GRANT SELECT                 ON COMERCIAL_VIDA.COMPRA             TO 'rol_contabilidad';
GRANT SELECT                 ON COMERCIAL_VIDA.DETALLE_COMPRA     TO 'rol_contabilidad';

GRANT SELECT ON COMERCIAL_VIDA.* TO 'rol_auditor';

-- Creación de usuarios
CREATE USER 'adm_vida'@'localhost'   IDENTIFIED BY 'Adm#Vida2026$';
CREATE USER 'vendedor01'@'localhost' IDENTIFIED BY 'Vent#Vida2026$';
CREATE USER 'almacen01'@'localhost'  IDENTIFIED BY 'Alm#Vida2026$';
CREATE USER 'contador01'@'localhost' IDENTIFIED BY 'Cont#Vida2026$';
CREATE USER 'auditor01'@'localhost'  IDENTIFIED BY 'Audi#Vida2026$';

-- Asignación de roles a usuarios
GRANT 'rol_admin_bd'     TO 'adm_vida'@'localhost';
GRANT 'rol_ventas'       TO 'vendedor01'@'localhost';
GRANT 'rol_almacen'      TO 'almacen01'@'localhost';
GRANT 'rol_contabilidad' TO 'contador01'@'localhost';
GRANT 'rol_auditor'      TO 'auditor01'@'localhost';

-- Activación de roles (sin esto el usuario entra sin privilegios)
SET DEFAULT ROLE ALL TO 'adm_vida'@'localhost','vendedor01'@'localhost',
                        'almacen01'@'localhost','contador01'@'localhost',
                        'auditor01'@'localhost';

FLUSH PRIVILEGES;

-- Verificación
SELECT User AS Rol, Host FROM mysql.user WHERE User LIKE 'rol_%';

SELECT CONCAT(TO_USER,'@',TO_HOST)     AS Usuario,
       CONCAT(FROM_USER,'@',FROM_HOST) AS Rol
FROM mysql.role_edges ORDER BY Usuario;

SHOW GRANTS FOR 'rol_ventas';
SHOW GRANTS FOR 'vendedor01'@'localhost' USING 'rol_ventas';

/* Prueba de control de acceso (sesión: mysql -u vendedor01 -p COMERCIAL_VIDA)
   SELECT CURRENT_ROLE();                        -- `rol_ventas`@`%`
   SELECT IdEmpleado, Nombre FROM EMPLEADO;      -- PERMITIDO
   SELECT DNI FROM EMPLEADO;                     -- ERROR 1143
   DELETE FROM PRODUCTO WHERE IdProducto='P001'; -- ERROR 1142            */


/* =====================================================================
   3.2  COPIAS DE SEGURIDAD
   (mysqldump se ejecuta en la TERMINAL del sistema operativo)
   ===================================================================== */

/* (A) RESPALDO COMPLETO: estructura + datos + rutinas + triggers

   Windows (CMD):
     "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe" ^
        -u adm_vida -p --databases COMERCIAL_VIDA ^
        --routines --triggers --events ^
        --single-transaction --skip-lock-tables ^
        --set-gtid-purged=OFF --default-character-set=utf8mb4 ^
        --result-file="C:\backups\COMERCIAL_VIDA_FULL_20260918.sql"

   Linux / macOS:
     mysqldump -u adm_vida -p --databases COMERCIAL_VIDA \
        --routines --triggers --events \
        --single-transaction --skip-lock-tables \
        --set-gtid-purged=OFF --default-character-set=utf8mb4 \
        > /backups/COMERCIAL_VIDA_FULL_20260918.sql

   --single-transaction : respaldo consistente sin bloquear tablas (InnoDB)
   --databases          : incluye CREATE DATABASE y USE en el archivo


   (B) SOLO ESTRUCTURA
     mysqldump -u adm_vida -p --no-data --routines --triggers \
        --databases COMERCIAL_VIDA \
        --result-file=/backups/COMERCIAL_VIDA_ESTRUCTURA.sql

   (C) SOLO DATOS
     mysqldump -u adm_vida -p --no-create-info --complete-insert \
        --single-transaction COMERCIAL_VIDA \
        --result-file=/backups/COMERCIAL_VIDA_DATOS.sql

   (D) TABLAS PUNTUALES
     mysqldump -u adm_vida -p --single-transaction COMERCIAL_VIDA \
        VENTA DETALLE_VENTA PAGO PAGO_VENTA \
        --result-file=/backups/COMERCIAL_VIDA_VENTAS.sql

   (E) USUARIOS Y ROLES (no se incluyen en el respaldo del esquema)
     mysqldump -u root -p --system=users > /backups/usuarios_roles.sql
*/

-- (F) RESPALDO INTERNO: copia de las tablas en un esquema espejo
CREATE DATABASE IF NOT EXISTS COMERCIAL_VIDA_BKP
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

CREATE TABLE COMERCIAL_VIDA_BKP.CLIENTE            AS SELECT * FROM CLIENTE;
CREATE TABLE COMERCIAL_VIDA_BKP.CLIENTE_NATURAL    AS SELECT * FROM CLIENTE_NATURAL;
CREATE TABLE COMERCIAL_VIDA_BKP.CLIENTE_EMPRESA    AS SELECT * FROM CLIENTE_EMPRESA;
CREATE TABLE COMERCIAL_VIDA_BKP.EMPLEADO           AS SELECT * FROM EMPLEADO;
CREATE TABLE COMERCIAL_VIDA_BKP.CATEGORIA          AS SELECT * FROM CATEGORIA;
CREATE TABLE COMERCIAL_VIDA_BKP.MARCA_VEHICULO     AS SELECT * FROM MARCA_VEHICULO;
CREATE TABLE COMERCIAL_VIDA_BKP.MODELO_VEHICULO    AS SELECT * FROM MODELO_VEHICULO;
CREATE TABLE COMERCIAL_VIDA_BKP.PRODUCTO           AS SELECT * FROM PRODUCTO;
CREATE TABLE COMERCIAL_VIDA_BKP.COMPATIBILIDAD     AS SELECT * FROM COMPATIBILIDAD;
CREATE TABLE COMERCIAL_VIDA_BKP.PROVEEDOR          AS SELECT * FROM PROVEEDOR;
CREATE TABLE COMERCIAL_VIDA_BKP.VENTA              AS SELECT * FROM VENTA;
CREATE TABLE COMERCIAL_VIDA_BKP.DETALLE_VENTA      AS SELECT * FROM DETALLE_VENTA;
CREATE TABLE COMERCIAL_VIDA_BKP.COMPRA             AS SELECT * FROM COMPRA;
CREATE TABLE COMERCIAL_VIDA_BKP.DETALLE_COMPRA     AS SELECT * FROM DETALLE_COMPRA;
CREATE TABLE COMERCIAL_VIDA_BKP.PAGO               AS SELECT * FROM PAGO;
CREATE TABLE COMERCIAL_VIDA_BKP.PAGO_VENTA         AS SELECT * FROM PAGO_VENTA;
CREATE TABLE COMERCIAL_VIDA_BKP.PAGO_COMPRA        AS SELECT * FROM PAGO_COMPRA;
CREATE TABLE COMERCIAL_VIDA_BKP.COMPROBANTE        AS SELECT * FROM COMPROBANTE;
CREATE TABLE COMERCIAL_VIDA_BKP.COMPROBANTE_VENTA  AS SELECT * FROM COMPROBANTE_VENTA;
CREATE TABLE COMERCIAL_VIDA_BKP.COMPROBANTE_COMPRA AS SELECT * FROM COMPROBANTE_COMPRA;

-- Verificación del respaldo interno
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'COMERCIAL_VIDA_BKP'
ORDER BY TABLE_NAME;


/* =====================================================================
   3.3  RECUPERACIÓN DE COPIAS DE SEGURIDAD
   ===================================================================== */

/* (A) RESTAURACIÓN TOTAL desde el archivo de respaldo

   Windows (CMD):
     "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p ^
        --default-character-set=utf8mb4 ^
        < "C:\backups\COMERCIAL_VIDA_FULL_20260918.sql"

   Linux / macOS:
     mysql -u root -p --default-character-set=utf8mb4 \
        < /backups/COMERCIAL_VIDA_FULL_20260918.sql

   Restauración de usuarios y roles:
     mysql -u root -p < /backups/usuarios_roles.sql
     FLUSH PRIVILEGES;


   (B) RESTAURACIÓN EN ESQUEMA ALTERNO (validar sin afectar producción)
     mysql -u root -p -e "CREATE DATABASE COMERCIAL_VIDA_REST
                          CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
     mysqldump -u adm_vida -p --single-transaction COMERCIAL_VIDA > /backups/esquema.sql
     mysql -u root -p COMERCIAL_VIDA_REST < /backups/esquema.sql
*/

-- (C) RECUPERACIÓN PARCIAL: simulacro de borrado accidental
SELECT COUNT(*) AS PagosVenta_Antes FROM PAGO_VENTA;

START TRANSACTION;
DELETE FROM PAGO_VENTA WHERE IdVenta <= 20;
SELECT COUNT(*) AS PagosVenta_TrasIncidente FROM PAGO_VENTA;
ROLLBACK;
SELECT COUNT(*) AS PagosVenta_TrasRollback FROM PAGO_VENTA;

-- Si el borrado ya fue confirmado (COMMIT), se recupera desde el respaldo:
/*
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;
DELETE FROM COMERCIAL_VIDA.PAGO_VENTA;
INSERT INTO COMERCIAL_VIDA.PAGO_VENTA (IdPago, IdVenta, Estado)
SELECT IdPago, IdVenta, Estado FROM COMERCIAL_VIDA_BKP.PAGO_VENTA;
COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
*/

-- (D) VERIFICACIÓN DE LA RECUPERACIÓN: conteo original vs. respaldo
SELECT 'CLIENTE' AS Tabla,
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.CLIENTE)     AS Original,
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.CLIENTE) AS Recuperado
UNION ALL SELECT 'PRODUCTO',
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.PRODUCTO),
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.PRODUCTO)
UNION ALL SELECT 'VENTA',
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.VENTA),
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.VENTA)
UNION ALL SELECT 'DETALLE_VENTA',
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.DETALLE_VENTA),
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.DETALLE_VENTA)
UNION ALL SELECT 'COMPRA',
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.COMPRA),
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.COMPRA)
UNION ALL SELECT 'DETALLE_COMPRA',
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.DETALLE_COMPRA),
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.DETALLE_COMPRA)
UNION ALL SELECT 'PAGO',
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.PAGO),
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.PAGO)
UNION ALL SELECT 'PAGO_VENTA',
       (SELECT COUNT(*) FROM COMERCIAL_VIDA.PAGO_VENTA),
       (SELECT COUNT(*) FROM COMERCIAL_VIDA_BKP.PAGO_VENTA);

-- Comparación byte a byte del contenido de una tabla
CHECKSUM TABLE COMERCIAL_VIDA.VENTA, COMERCIAL_VIDA_BKP.VENTA;

-- Revalidación de la regla de negocio: monto de venta = monto pagado
SELECT COUNT(*) AS VentasDescuadradas
FROM (
    SELECT V.IdVenta
    FROM VENTA V
    INNER JOIN (SELECT IdVenta, ROUND(SUM(Cantidad*PrecioUnitario),2) AS Total
                FROM DETALLE_VENTA GROUP BY IdVenta) D ON V.IdVenta = D.IdVenta
    INNER JOIN (SELECT PV.IdVenta, ROUND(SUM(P.Monto),2) AS Pagado
                FROM PAGO_VENTA PV INNER JOIN PAGO P ON PV.IdPago = P.IdPago
                GROUP BY PV.IdVenta) G ON V.IdVenta = G.IdVenta
    WHERE D.Total <> G.Pagado
) X;


/* =====================================================================
   3.4  CREACIÓN DE ÍNDICES Y COMPARACIÓN DE MÉTRICAS
   ===================================================================== */

-- Índices existentes antes del cambio (InnoDB ya indexa PK, UNIQUE y FK)
SELECT TABLE_NAME, INDEX_NAME,
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS Columnas
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'COMERCIAL_VIDA'
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;

-- Tabla para registrar las métricas
DROP TABLE IF EXISTS METRICAS_INDICES;
CREATE TABLE METRICAS_INDICES (
    IdMetrica   INT AUTO_INCREMENT PRIMARY KEY,
    Consulta    VARCHAR(10)   NOT NULL,
    Descripcion VARCHAR(150)  NOT NULL,
    Escenario   VARCHAR(12)   NOT NULL,   -- SIN_INDICE / CON_INDICE
    Milisegundos DECIMAL(12,3) NOT NULL,
    FilasLeidas BIGINT        NULL,
    TipoAcceso  VARCHAR(20)   NULL,       -- ALL / range / ref  (ver EXPLAIN)
    IndiceUsado VARCHAR(64)   NULL
);


/* ---------- MEDICIÓN SIN ÍNDICES (línea base) ---------- */

-- C1: ventas por rango de fechas
EXPLAIN SELECT IdVenta, Fecha, IdCliente FROM VENTA
        WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30';
EXPLAIN ANALYZE SELECT IdVenta, Fecha, IdCliente FROM VENTA
        WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30';

SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdVenta, Fecha, IdCliente FROM VENTA
    WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30') X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C1','Ventas por rango de fechas','SIN_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'ALL', NULL);

-- C2: historial de un cliente
SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdVenta, Fecha FROM VENTA WHERE IdCliente = 'CLN010') X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C2','Historial de ventas de un cliente','SIN_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'ref', 'FK IdCliente');

-- C3: productos por categoría y rango de precio
EXPLAIN SELECT IdProducto, Nombre, Precio FROM PRODUCTO
        WHERE IdCategoria = 3 AND Precio BETWEEN 100 AND 500;

SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdProducto, Nombre, Precio FROM PRODUCTO
    WHERE IdCategoria = 3 AND Precio BETWEEN 100 AND 500) X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C3','Productos por categoria y rango de precio','SIN_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'ALL', NULL);

-- C4: unidades vendidas por producto
SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdProducto, SUM(Cantidad) AS Unidades
    FROM DETALLE_VENTA GROUP BY IdProducto) X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C4','Unidades vendidas por producto','SIN_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'ALL', NULL);

-- C5: pagos por método y fecha
SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdPago, Monto FROM PAGO
    WHERE MetodoPago = 'Yape' AND Fecha >= '2024-01-01') X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C5','Pagos por metodo y fecha','SIN_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'ALL', NULL);


/* ---------- CREACIÓN DE ÍNDICES ---------- */

-- Índices simples (columnas de filtro frecuente)
CREATE INDEX idx_venta_fecha       ON VENTA (Fecha);
CREATE INDEX idx_compra_fecha      ON COMPRA (Fecha);
CREATE INDEX idx_pago_fecha        ON PAGO (Fecha);
CREATE INDEX idx_producto_stock    ON PRODUCTO (Stock);
CREATE INDEX idx_cliente_telefono  ON CLIENTE (Telefono);

-- Índices compuestos (igualdad primero, rango después)
CREATE INDEX idx_venta_cliente_fecha       ON VENTA (IdCliente, Fecha);
CREATE INDEX idx_venta_empleado_fecha      ON VENTA (IdEmpleado, Fecha);
CREATE INDEX idx_producto_categoria_precio ON PRODUCTO (IdCategoria, Precio);
CREATE INDEX idx_producto_marca_modelo     ON PRODUCTO (Marca, Modelo);
CREATE INDEX idx_compra_proveedor_fecha    ON COMPRA (IdProveedor, Fecha);
CREATE INDEX idx_pago_metodo_fecha         ON PAGO (MetodoPago, Fecha);
CREATE INDEX idx_empleado_estado_cargo     ON EMPLEADO (Estado, Cargo);
CREATE INDEX idx_compatibilidad_modelo     ON COMPATIBILIDAD (IdModeloVehiculo, Año);

-- Índices de cobertura (el índice contiene todas las columnas: Using index)
CREATE INDEX idx_dv_producto_cob ON DETALLE_VENTA (IdProducto, Cantidad, PrecioUnitario);
CREATE INDEX idx_dc_producto_cob ON DETALLE_COMPRA (IdProducto, Cantidad, PrecioCompra);

-- Actualización de estadísticas del optimizador
ANALYZE TABLE VENTA, DETALLE_VENTA, PRODUCTO, COMPRA, DETALLE_COMPRA,
              PAGO, CLIENTE, EMPLEADO, COMPATIBILIDAD;


/* ---------- MEDICIÓN CON ÍNDICES ---------- */

-- Nuevo plan: debe mostrar type=range y key=idx_venta_fecha
EXPLAIN SELECT IdVenta, Fecha, IdCliente FROM VENTA
        WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30';
EXPLAIN ANALYZE SELECT IdVenta, Fecha, IdCliente FROM VENTA
        WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30';

SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdVenta, Fecha, IdCliente FROM VENTA
    WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30') X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C1','Ventas por rango de fechas','CON_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'range', 'idx_venta_fecha');

SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdVenta, Fecha FROM VENTA WHERE IdCliente = 'CLN010') X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C2','Historial de ventas de un cliente','CON_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'ref', 'idx_venta_cliente_fecha');

EXPLAIN SELECT IdProducto, Nombre, Precio FROM PRODUCTO
        WHERE IdCategoria = 3 AND Precio BETWEEN 100 AND 500;

SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdProducto, Nombre, Precio FROM PRODUCTO
    WHERE IdCategoria = 3 AND Precio BETWEEN 100 AND 500) X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C3','Productos por categoria y rango de precio','CON_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'range', 'idx_producto_categoria_precio');

-- Debe mostrar Extra = Using index (índice de cobertura)
EXPLAIN SELECT IdProducto, SUM(Cantidad) FROM DETALLE_VENTA GROUP BY IdProducto;

SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdProducto, SUM(Cantidad) AS Unidades
    FROM DETALLE_VENTA GROUP BY IdProducto) X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C4','Unidades vendidas por producto','CON_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'index', 'idx_dv_producto_cob');

SET @t = NOW(6);
SELECT COUNT(*) INTO @f FROM (
    SELECT IdPago, Monto FROM PAGO
    WHERE MetodoPago = 'Yape' AND Fecha >= '2024-01-01') X;
INSERT INTO METRICAS_INDICES (Consulta,Descripcion,Escenario,Milisegundos,FilasLeidas,TipoAcceso,IndiceUsado)
VALUES ('C5','Pagos por metodo y fecha','CON_INDICE',
        TIMESTAMPDIFF(MICROSECOND,@t,NOW(6))/1000, @f, 'range', 'idx_pago_metodo_fecha');


/* ---------- COMPARACIÓN DE MÉTRICAS ---------- */

SELECT  S.Consulta,
        S.Descripcion,
        S.Milisegundos                          AS Ms_SinIndice,
        C.Milisegundos                          AS Ms_ConIndice,
        ROUND(S.Milisegundos - C.Milisegundos,3) AS Ms_Ahorrados,
        ROUND((S.Milisegundos - C.Milisegundos)
              / NULLIF(S.Milisegundos,0) * 100, 2) AS Mejora_Porcentaje,
        S.TipoAcceso  AS Acceso_Sin,
        C.TipoAcceso  AS Acceso_Con,
        C.IndiceUsado AS Indice_Aplicado
FROM METRICAS_INDICES S
INNER JOIN METRICAS_INDICES C ON S.Consulta = C.Consulta
WHERE S.Escenario = 'SIN_INDICE' AND C.Escenario = 'CON_INDICE'
ORDER BY S.Consulta;

-- Espacio ocupado por los índices (contrapartida del rendimiento)
SELECT TABLE_NAME,
       ROUND(DATA_LENGTH /1024, 2) AS KB_Datos,
       ROUND(INDEX_LENGTH/1024, 2) AS KB_Indices,
       ROUND(INDEX_LENGTH / NULLIF(DATA_LENGTH,0) * 100, 1) AS Pct_Indices
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'COMERCIAL_VIDA' AND TABLE_TYPE = 'BASE TABLE'
ORDER BY INDEX_LENGTH DESC;

-- Cardinalidad de los índices creados
SELECT TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX, COLUMN_NAME, CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'COMERCIAL_VIDA' AND INDEX_NAME LIKE 'idx_%'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- Comparación de planes sin borrar el índice
EXPLAIN ANALYZE SELECT IdVenta, Fecha FROM VENTA IGNORE INDEX (idx_venta_fecha)
        WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30';
EXPLAIN ANALYZE SELECT IdVenta, Fecha FROM VENTA FORCE INDEX (idx_venta_fecha)
        WHERE Fecha BETWEEN '2024-01-01' AND '2024-06-30';
