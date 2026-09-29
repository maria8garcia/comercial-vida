-- ====================================================================
-- PUNTO 2 - COMERCIAL_VIDA
-- PROCEDIMIENTOS, FUNCIONES, TRIGGERS, TRANSACCIONES,
-- AUDITORIA Y CONTROL DE EXCEPCIONES
--
-- IMPORTANTE:
-- Este script esta adaptado al esquema original de COMERCIAL_VIDA.
-- Debe ejecutarse DESPUES de crear las tablas de la base de datos.
-- No crea roles, permisos, backups ni indices.
-- ====================================================================

USE COMERCIAL_VIDA;

-- ====================================================================
-- PARTE A: FUNCIONES
-- ====================================================================

DELIMITER $$

-- RF6: Calcula el total actual de una venta.
DROP FUNCTION IF EXISTS fn_total_venta$$
CREATE FUNCTION fn_total_venta(p_IdVenta INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_Total DECIMAL(12,2) DEFAULT 0.00;

    SELECT COALESCE(SUM(Cantidad * PrecioUnitario), 0)
      INTO v_Total
      FROM DETALLE_VENTA
     WHERE IdVenta = p_IdVenta;

    RETURN v_Total;
END$$


-- RF11 / RN09: Calcula cuanto se ha pagado de una venta.
DROP FUNCTION IF EXISTS fn_total_pagado_venta$$
CREATE FUNCTION fn_total_pagado_venta(p_IdVenta INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_TotalPagado DECIMAL(12,2) DEFAULT 0.00;

    SELECT COALESCE(SUM(p.Monto), 0)
      INTO v_TotalPagado
      FROM PAGO p
      INNER JOIN PAGO_VENTA pv
              ON pv.IdPago = p.IdPago
     WHERE pv.IdVenta = p_IdVenta;

    RETURN v_TotalPagado;
END$$


-- RF11 / RN09: Calcula el saldo pendiente de una venta.
DROP FUNCTION IF EXISTS fn_saldo_venta$$
CREATE FUNCTION fn_saldo_venta(p_IdVenta INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    RETURN fn_total_venta(p_IdVenta) - fn_total_pagado_venta(p_IdVenta);
END$$


-- RF13 / RN04: Informa si el producto necesita reposicion.
DROP FUNCTION IF EXISTS fn_estado_stock$$
CREATE FUNCTION fn_estado_stock(p_IdProducto VARCHAR(10))
RETURNS VARCHAR(40)
READS SQL DATA
BEGIN
    DECLARE v_Stock INT DEFAULT NULL;

    SELECT Stock
      INTO v_Stock
      FROM PRODUCTO
     WHERE IdProducto = p_IdProducto
     LIMIT 1;

    IF v_Stock IS NULL THEN
        RETURN 'PRODUCTO NO EXISTE';
    ELSEIF v_Stock <= 3 THEN
        RETURN 'REQUIERE REPOSICION';
    ELSE
        RETURN 'STOCK DISPONIBLE';
    END IF;
END$$


-- RN06 / RF14: Valida precio de venta contra el ultimo costo de compra.
DROP FUNCTION IF EXISTS fn_validar_precio_venta$$
CREATE FUNCTION fn_validar_precio_venta(
    p_IdProducto VARCHAR(10),
    p_PrecioVenta DECIMAL(10,2),
    p_AutorizacionAdmin BOOLEAN
)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_UltimoCosto DECIMAL(10,2) DEFAULT NULL;

    SELECT dc.PrecioCompra
      INTO v_UltimoCosto
      FROM DETALLE_COMPRA dc
      INNER JOIN COMPRA c
              ON c.IdCompra = dc.IdCompra
     WHERE dc.IdProducto = p_IdProducto
     ORDER BY c.Fecha DESC, c.IdCompra DESC
     LIMIT 1;

    IF v_UltimoCosto IS NOT NULL
       AND p_PrecioVenta < v_UltimoCosto
       AND COALESCE(p_AutorizacionAdmin, 0) = 0 THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END$$

DELIMITER ;


-- ====================================================================
-- PARTE B: AUDITORIA
-- ====================================================================

-- RN12: Cambios importantes sobre productos, precios y stock.
CREATE TABLE IF NOT EXISTS AUDITORIA_PRODUCTO (
    IdAuditoria INT AUTO_INCREMENT PRIMARY KEY,
    IdProducto VARCHAR(10) NOT NULL,
    CampoModificado VARCHAR(45) NOT NULL,
    ValorAnterior VARCHAR(180),
    ValorNuevo VARCHAR(180),
    Usuario VARCHAR(100) NOT NULL,
    FechaCambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- RF20: Registro sencillo de operaciones relevantes.
CREATE TABLE IF NOT EXISTS AUDITORIA_OPERACION (
    IdAuditoria INT AUTO_INCREMENT PRIMARY KEY,
    TipoOperacion VARCHAR(45) NOT NULL,
    TablaAfectada VARCHAR(45) NOT NULL,
    IdReferencia VARCHAR(45) NOT NULL,
    Usuario VARCHAR(100) NOT NULL,
    Detalle VARCHAR(180),
    FechaOperacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ====================================================================
-- PARTE C: TRIGGERS
-- ====================================================================

DELIMITER $$

-- Se eliminan los triggers anteriores del script original para reemplazarlos
-- por la version completa de este Punto 2.
DROP TRIGGER IF EXISTS trg_validar_stock_venta$$
DROP TRIGGER IF EXISTS trg_disminuir_stock_venta$$
DROP TRIGGER IF EXISTS trg_aumentar_stock_compra$$

DROP TRIGGER IF EXISTS trg_validar_producto_insert$$
DROP TRIGGER IF EXISTS trg_validar_producto_update$$
DROP TRIGGER IF EXISTS trg_auditar_producto$$
DROP TRIGGER IF EXISTS trg_validar_stock_venta_update$$
DROP TRIGGER IF EXISTS trg_actualizar_stock_venta$$
DROP TRIGGER IF EXISTS trg_restaurar_stock_venta_delete$$
DROP TRIGGER IF EXISTS trg_validar_compra_insert$$
DROP TRIGGER IF EXISTS trg_validar_stock_compra_update$$
DROP TRIGGER IF EXISTS trg_actualizar_stock_compra$$
DROP TRIGGER IF EXISTS trg_validar_eliminar_detalle_compra$$
DROP TRIGGER IF EXISTS trg_restaurar_stock_compra_delete$$
DROP TRIGGER IF EXISTS trg_validar_unico_pago_compra$$


-- RN01, RN02 y RN03: Validaciones basicas al registrar un producto.
CREATE TRIGGER trg_validar_producto_insert
BEFORE INSERT ON PRODUCTO
FOR EACH ROW
BEGIN
    IF NEW.IdProducto IS NULL OR TRIM(NEW.IdProducto) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto debe tener un codigo';
    END IF;

    IF NEW.Nombre IS NULL OR TRIM(NEW.Nombre) = ''
       OR NEW.Modelo IS NULL OR TRIM(NEW.Modelo) = ''
       OR NEW.IdCategoria IS NULL
       OR NEW.Stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID, nombre, modelo, categoria y stock son obligatorios';
    END IF;

    IF UPPER(LEFT(NEW.IdProducto, 3))
       <> UPPER(LEFT(TRIM(NEW.Nombre), 3)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El codigo debe iniciar con las 3 primeras letras del nombre';
    END IF;

    IF NEW.Precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor que cero';
    END IF;

    IF NEW.Stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El stock no puede ser negativo';
    END IF;
END$$


-- RN03 / RF14: Validaciones numericas al actualizar un producto.
-- RN01 y RN02 se exigen en nuevas altas. El script original contiene
-- productos historicos con codigos PR### y algunos modelos NULL, por eso
-- no se bloquean las actualizaciones automaticas de stock de esos registros.
CREATE TRIGGER trg_validar_producto_update
BEFORE UPDATE ON PRODUCTO
FOR EACH ROW
BEGIN
    IF NEW.Precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor que cero';
    END IF;

    IF NEW.Stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El stock no puede ser negativo';
    END IF;
END$$


-- RN12 / RF20: Auditoria automatica de nombre, precio y stock.
CREATE TRIGGER trg_auditar_producto
AFTER UPDATE ON PRODUCTO
FOR EACH ROW
BEGIN
    DECLARE v_Usuario VARCHAR(100);

    SET v_Usuario = USER();

    IF NOT (OLD.Nombre <=> NEW.Nombre) THEN
        INSERT INTO AUDITORIA_PRODUCTO (
            IdProducto, CampoModificado,
            ValorAnterior, ValorNuevo, Usuario
        )
        VALUES (
            NEW.IdProducto, 'Nombre',
            OLD.Nombre, NEW.Nombre, v_Usuario
        );
    END IF;

    IF NOT (OLD.Precio <=> NEW.Precio) THEN
        INSERT INTO AUDITORIA_PRODUCTO (
            IdProducto, CampoModificado,
            ValorAnterior, ValorNuevo, Usuario
        )
        VALUES (
            NEW.IdProducto, 'Precio',
            CAST(OLD.Precio AS CHAR),
            CAST(NEW.Precio AS CHAR),
            v_Usuario
        );
    END IF;

    IF NOT (OLD.Stock <=> NEW.Stock) THEN
        INSERT INTO AUDITORIA_PRODUCTO (
            IdProducto, CampoModificado,
            ValorAnterior, ValorNuevo, Usuario
        )
        VALUES (
            NEW.IdProducto, 'Stock',
            CAST(OLD.Stock AS CHAR),
            CAST(NEW.Stock AS CHAR),
            v_Usuario
        );
    END IF;
END$$


-- RF4 / RNF12: Validar stock antes de registrar un detalle de venta.
CREATE TRIGGER trg_validar_stock_venta
BEFORE INSERT ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    DECLARE v_Stock INT DEFAULT NULL;

    IF NEW.Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad de venta debe ser mayor que cero';
    END IF;

    SELECT Stock
      INTO v_Stock
      FROM PRODUCTO
     WHERE IdProducto = NEW.IdProducto
     LIMIT 1;

    IF v_Stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede vender: producto inexistente';
    END IF;

    IF v_Stock < NEW.Cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede vender: stock insuficiente';
    END IF;
END$$


-- RF4: Descontar stock automaticamente despues de una venta.
CREATE TRIGGER trg_disminuir_stock_venta
AFTER INSERT ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
       SET Stock = Stock - NEW.Cantidad
     WHERE IdProducto = NEW.IdProducto;
END$$


-- RF4: Validar cambios de cantidad/producto en un detalle de venta.
CREATE TRIGGER trg_validar_stock_venta_update
BEFORE UPDATE ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    DECLARE v_StockNuevo INT DEFAULT NULL;

    IF NEW.Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad de venta debe ser mayor que cero';
    END IF;

    SELECT Stock
      INTO v_StockNuevo
      FROM PRODUCTO
     WHERE IdProducto = NEW.IdProducto
     LIMIT 1;

    IF v_StockNuevo IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto indicado no existe';
    END IF;

    IF OLD.IdProducto = NEW.IdProducto THEN
        IF (v_StockNuevo + OLD.Cantidad) < NEW.Cantidad THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para actualizar la venta';
        END IF;
    ELSE
        IF v_StockNuevo < NEW.Cantidad THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para cambiar el producto';
        END IF;
    END IF;
END$$


-- RF4: Ajustar stock al modificar un detalle de venta.
CREATE TRIGGER trg_actualizar_stock_venta
AFTER UPDATE ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    IF OLD.IdProducto = NEW.IdProducto THEN
        UPDATE PRODUCTO
           SET Stock = Stock + OLD.Cantidad - NEW.Cantidad
         WHERE IdProducto = NEW.IdProducto;
    ELSE
        UPDATE PRODUCTO
           SET Stock = Stock + OLD.Cantidad
         WHERE IdProducto = OLD.IdProducto;

        UPDATE PRODUCTO
           SET Stock = Stock - NEW.Cantidad
         WHERE IdProducto = NEW.IdProducto;
    END IF;
END$$


-- RF4: Restaurar stock al eliminar un detalle de venta.
CREATE TRIGGER trg_restaurar_stock_venta_delete
AFTER DELETE ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
       SET Stock = Stock + OLD.Cantidad
     WHERE IdProducto = OLD.IdProducto;
END$$


-- RF9 / RN08: Validar cantidades y precios antes de una compra.
CREATE TRIGGER trg_validar_compra_insert
BEFORE INSERT ON DETALLE_COMPRA
FOR EACH ROW
BEGIN
    IF NEW.Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad de compra debe ser mayor que cero';
    END IF;

    IF NEW.PrecioCompra <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio de compra debe ser mayor que cero';
    END IF;
END$$


-- RF9 / RN08: Aumentar stock automaticamente despues de una compra.
CREATE TRIGGER trg_aumentar_stock_compra
AFTER INSERT ON DETALLE_COMPRA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
       SET Stock = Stock + NEW.Cantidad
     WHERE IdProducto = NEW.IdProducto;
END$$


-- RF9: Validar cambios sobre un detalle de compra.
CREATE TRIGGER trg_validar_stock_compra_update
BEFORE UPDATE ON DETALLE_COMPRA
FOR EACH ROW
BEGIN
    DECLARE v_StockActual INT DEFAULT NULL;

    IF NEW.Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad de compra debe ser mayor que cero';
    END IF;

    IF NEW.PrecioCompra <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio de compra debe ser mayor que cero';
    END IF;

    SELECT Stock
      INTO v_StockActual
      FROM PRODUCTO
     WHERE IdProducto = OLD.IdProducto
     LIMIT 1;

    IF v_StockActual IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto original no existe';
    END IF;

    IF OLD.IdProducto = NEW.IdProducto THEN
        IF (v_StockActual - OLD.Cantidad + NEW.Cantidad) < 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El stock quedaria negativo';
        END IF;
    ELSE
        IF v_StockActual < OLD.Cantidad THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede cambiar el producto: stock insuficiente';
        END IF;
    END IF;
END$$


-- RF9: Ajustar stock al modificar un detalle de compra.
CREATE TRIGGER trg_actualizar_stock_compra
AFTER UPDATE ON DETALLE_COMPRA
FOR EACH ROW
BEGIN
    IF OLD.IdProducto = NEW.IdProducto THEN
        UPDATE PRODUCTO
           SET Stock = Stock - OLD.Cantidad + NEW.Cantidad
         WHERE IdProducto = NEW.IdProducto;
    ELSE
        UPDATE PRODUCTO
           SET Stock = Stock - OLD.Cantidad
         WHERE IdProducto = OLD.IdProducto;

        UPDATE PRODUCTO
           SET Stock = Stock + NEW.Cantidad
         WHERE IdProducto = NEW.IdProducto;
    END IF;
END$$


-- RF9: Evitar eliminar una compra si deja stock negativo.
CREATE TRIGGER trg_validar_eliminar_detalle_compra
BEFORE DELETE ON DETALLE_COMPRA
FOR EACH ROW
BEGIN
    DECLARE v_StockActual INT DEFAULT NULL;

    SELECT Stock
      INTO v_StockActual
      FROM PRODUCTO
     WHERE IdProducto = OLD.IdProducto
     LIMIT 1;

    IF v_StockActual < OLD.Cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar: el stock quedaria negativo';
    END IF;
END$$


-- RF9: Descontar del stock lo ingresado por una compra eliminada.
CREATE TRIGGER trg_restaurar_stock_compra_delete
AFTER DELETE ON DETALLE_COMPRA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
       SET Stock = Stock - OLD.Cantidad
     WHERE IdProducto = OLD.IdProducto;
END$$


-- RN09: Cada compra puede tener solamente un pago.
-- La tabla original ya tiene UNIQUE(IdCompra); este trigger agrega un mensaje claro.
CREATE TRIGGER trg_validar_unico_pago_compra
BEFORE INSERT ON PAGO_COMPRA
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
          FROM PAGO_COMPRA
         WHERE IdCompra = NEW.IdCompra
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La compra ya posee un pago registrado';
    END IF;
END$$

DELIMITER ;


-- ====================================================================
-- PARTE D: PROCEDIMIENTOS DE CONSULTA Y MANTENIMIENTO
-- ====================================================================

DELIMITER $$

-- RF5: Buscar productos por nombre, categoria o marca.
DROP PROCEDURE IF EXISTS sp_buscar_productos$$
CREATE PROCEDURE sp_buscar_productos(IN p_Busqueda VARCHAR(120))
BEGIN
    SELECT
        p.IdProducto,
        p.Nombre,
        p.Marca,
        p.Modelo,
        c.Nombre AS Categoria,
        p.Precio,
        p.Stock,
        fn_estado_stock(p.IdProducto) AS EstadoStock,
        p.Ubicacion
    FROM PRODUCTO p
    INNER JOIN CATEGORIA c
            ON c.IdCategoria = p.IdCategoria
    WHERE p.Nombre LIKE CONCAT('%', p_Busqueda, '%')
       OR p.Marca LIKE CONCAT('%', p_Busqueda, '%')
       OR c.Nombre LIKE CONCAT('%', p_Busqueda, '%')
    ORDER BY p.Nombre;
END$$


-- RF2: Consultar clientes naturales y empresas.
DROP PROCEDURE IF EXISTS sp_buscar_clientes$$
CREATE PROCEDURE sp_buscar_clientes(IN p_Busqueda VARCHAR(120))
BEGIN
    SELECT
        c.IdCliente,
        COALESCE(
            CONCAT(cn.Nombre, ' ', cn.Apellido),
            ce.RazonSocial
        ) AS Cliente,
        cn.DNI,
        ce.RUC,
        c.Correo,
        c.Telefono,
        c.Direccion
    FROM CLIENTE c
    LEFT JOIN CLIENTE_NATURAL cn
           ON cn.IdCliente = c.IdCliente
    LEFT JOIN CLIENTE_EMPRESA ce
           ON ce.IdCliente = c.IdCliente
    WHERE c.IdCliente LIKE CONCAT('%', p_Busqueda, '%')
       OR cn.Nombre LIKE CONCAT('%', p_Busqueda, '%')
       OR cn.Apellido LIKE CONCAT('%', p_Busqueda, '%')
       OR ce.RazonSocial LIKE CONCAT('%', p_Busqueda, '%')
    ORDER BY c.IdCliente;
END$$


-- RF10: Consultar proveedores.
DROP PROCEDURE IF EXISTS sp_buscar_proveedores$$
CREATE PROCEDURE sp_buscar_proveedores(IN p_Busqueda VARCHAR(120))
BEGIN
    SELECT
        IdProveedor,
        Nombre,
        RUC,
        Telefono,
        Direccion,
        Correo
    FROM PROVEEDOR
    WHERE IdProveedor LIKE CONCAT('%', p_Busqueda, '%')
       OR Nombre LIKE CONCAT('%', p_Busqueda, '%')
       OR RUC LIKE CONCAT('%', p_Busqueda, '%')
    ORDER BY Nombre;
END$$


-- RF7: Consultar historial de ventas por rango de fechas.
DROP PROCEDURE IF EXISTS sp_historial_ventas$$
CREATE PROCEDURE sp_historial_ventas(
    IN p_FechaInicio DATE,
    IN p_FechaFin DATE
)
BEGIN
    IF p_FechaInicio IS NULL OR p_FechaFin IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Debe indicar fecha inicial y fecha final';
    END IF;

    IF p_FechaInicio > p_FechaFin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha inicial no puede ser mayor que la final';
    END IF;

    SELECT
        v.IdVenta,
        v.Fecha,
        v.IdCliente,
        COALESCE(
            CONCAT(cn.Nombre, ' ', cn.Apellido),
            ce.RazonSocial
        ) AS Cliente,
        v.IdEmpleado,
        e.Nombre AS Empleado,
        fn_total_venta(v.IdVenta) AS TotalVenta,
        fn_total_pagado_venta(v.IdVenta) AS TotalPagado,
        fn_saldo_venta(v.IdVenta) AS Saldo
    FROM VENTA v
    INNER JOIN CLIENTE c
            ON c.IdCliente = v.IdCliente
    LEFT JOIN CLIENTE_NATURAL cn
           ON cn.IdCliente = c.IdCliente
    LEFT JOIN CLIENTE_EMPRESA ce
           ON ce.IdCliente = c.IdCliente
    INNER JOIN EMPLEADO e
            ON e.IdEmpleado = v.IdEmpleado
    WHERE v.Fecha BETWEEN p_FechaInicio AND p_FechaFin
    ORDER BY v.Fecha DESC, v.IdVenta DESC;
END$$


-- RF13 / RN04: Listar productos que necesitan reposicion.
DROP PROCEDURE IF EXISTS sp_productos_reposicion$$
CREATE PROCEDURE sp_productos_reposicion()
BEGIN
    SELECT
        IdProducto,
        Nombre,
        Marca,
        Stock,
        fn_estado_stock(IdProducto) AS EstadoStock
    FROM PRODUCTO
    WHERE Stock <= 3
    ORDER BY Stock ASC, Nombre;
END$$


-- RN13: Cierre diario.
-- El dinero fisicamente contado se compara con los pagos en efectivo.
-- Tambien muestra el resumen de todos los metodos de pago.
DROP PROCEDURE IF EXISTS sp_cierre_diario$$
CREATE PROCEDURE sp_cierre_diario(
    IN p_Fecha DATE,
    IN p_MontoContado DECIMAL(12,2)
)
BEGIN
    DECLARE v_EfectivoEsperado DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_TotalRecaudado DECIMAL(12,2) DEFAULT 0.00;

    IF p_Fecha IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Debe indicar la fecha del cierre';
    END IF;

    IF p_MontoContado < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El monto contado no puede ser negativo';
    END IF;

    SELECT COALESCE(SUM(p.Monto), 0)
      INTO v_TotalRecaudado
      FROM PAGO p
      INNER JOIN PAGO_VENTA pv
              ON pv.IdPago = p.IdPago
     WHERE p.Fecha = p_Fecha;

    SELECT COALESCE(SUM(p.Monto), 0)
      INTO v_EfectivoEsperado
      FROM PAGO p
      INNER JOIN PAGO_VENTA pv
              ON pv.IdPago = p.IdPago
     WHERE p.Fecha = p_Fecha
       AND p.MetodoPago = 'Efectivo';

    SELECT
        p.MetodoPago,
        COUNT(*) AS CantidadPagos,
        SUM(p.Monto) AS TotalRecaudado
    FROM PAGO p
    INNER JOIN PAGO_VENTA pv
            ON pv.IdPago = p.IdPago
    WHERE p.Fecha = p_Fecha
    GROUP BY p.MetodoPago
    ORDER BY p.MetodoPago;

    SELECT
        v_TotalRecaudado AS TotalRecaudadoDia,
        v_EfectivoEsperado AS EfectivoEsperado,
        p_MontoContado AS EfectivoContado,
        (p_MontoContado - v_EfectivoEsperado) AS DiferenciaCaja;
END$$


-- RF1: Registrar cliente natural.
DROP PROCEDURE IF EXISTS sp_registrar_cliente_natural$$
CREATE PROCEDURE sp_registrar_cliente_natural(
    IN p_IdCliente VARCHAR(45),
    IN p_Nombre VARCHAR(45),
    IN p_Apellido VARCHAR(80),
    IN p_DNI CHAR(8),
    IN p_Correo VARCHAR(100),
    IN p_Telefono VARCHAR(15),
    IN p_Direccion VARCHAR(120)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_DNI IS NULL OR CHAR_LENGTH(p_DNI) <> 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El DNI debe tener 8 digitos';
    END IF;

    INSERT INTO CLIENTE (
        IdCliente, Correo, Telefono,
        Direccion, IdCliente_Recomienda
    )
    VALUES (
        p_IdCliente, p_Correo, p_Telefono,
        p_Direccion, NULL
    );

    INSERT INTO CLIENTE_NATURAL (
        IdCliente, Nombre, Apellido, DNI
    )
    VALUES (
        p_IdCliente, p_Nombre, p_Apellido, p_DNI
    );

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'CLIENTE',
        p_IdCliente, USER(), 'Cliente natural registrado'
    );

    COMMIT;
END$$


-- RF1: Registrar cliente empresa.
DROP PROCEDURE IF EXISTS sp_registrar_cliente_empresa$$
CREATE PROCEDURE sp_registrar_cliente_empresa(
    IN p_IdCliente VARCHAR(45),
    IN p_RUC CHAR(11),
    IN p_RazonSocial VARCHAR(120),
    IN p_Correo VARCHAR(100),
    IN p_Telefono VARCHAR(15),
    IN p_Direccion VARCHAR(120)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_RUC IS NULL OR CHAR_LENGTH(p_RUC) <> 11 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El RUC debe tener 11 digitos';
    END IF;

    INSERT INTO CLIENTE (
        IdCliente, Correo, Telefono,
        Direccion, IdCliente_Recomienda
    )
    VALUES (
        p_IdCliente, p_Correo, p_Telefono,
        p_Direccion, NULL
    );

    INSERT INTO CLIENTE_EMPRESA (
        IdCliente, RUC, RazonSocial
    )
    VALUES (
        p_IdCliente, p_RUC, p_RazonSocial
    );

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'CLIENTE',
        p_IdCliente, USER(), 'Cliente empresa registrado'
    );

    COMMIT;
END$$


-- RF1: Actualizar datos comunes del cliente.
DROP PROCEDURE IF EXISTS sp_actualizar_cliente$$
CREATE PROCEDURE sp_actualizar_cliente(
    IN p_IdCliente VARCHAR(45),
    IN p_Correo VARCHAR(100),
    IN p_Telefono VARCHAR(15),
    IN p_Direccion VARCHAR(120)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM CLIENTE
         WHERE IdCliente = p_IdCliente
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente indicado no existe';
    END IF;

    UPDATE CLIENTE
       SET Correo = p_Correo,
           Telefono = p_Telefono,
           Direccion = p_Direccion
     WHERE IdCliente = p_IdCliente;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'UPDATE', 'CLIENTE',
        p_IdCliente, USER(), 'Datos generales del cliente actualizados'
    );
END$$


-- RF1: Actualizar datos propios de un cliente natural.
DROP PROCEDURE IF EXISTS sp_actualizar_cliente_natural$$
CREATE PROCEDURE sp_actualizar_cliente_natural(
    IN p_IdCliente VARCHAR(45),
    IN p_Nombre VARCHAR(45),
    IN p_Apellido VARCHAR(80),
    IN p_DNI CHAR(8)
)
BEGIN
    IF p_DNI IS NULL OR CHAR_LENGTH(p_DNI) <> 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El DNI debe tener 8 digitos';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM CLIENTE_NATURAL
         WHERE IdCliente = p_IdCliente
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente natural no existe';
    END IF;

    UPDATE CLIENTE_NATURAL
       SET Nombre = p_Nombre,
           Apellido = p_Apellido,
           DNI = p_DNI
     WHERE IdCliente = p_IdCliente;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'UPDATE', 'CLIENTE_NATURAL',
        p_IdCliente, USER(), 'Cliente natural actualizado'
    );
END$$


-- RF1: Actualizar datos propios de un cliente empresa.
DROP PROCEDURE IF EXISTS sp_actualizar_cliente_empresa$$
CREATE PROCEDURE sp_actualizar_cliente_empresa(
    IN p_IdCliente VARCHAR(45),
    IN p_RUC CHAR(11),
    IN p_RazonSocial VARCHAR(120)
)
BEGIN
    IF p_RUC IS NULL OR CHAR_LENGTH(p_RUC) <> 11 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El RUC debe tener 11 digitos';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM CLIENTE_EMPRESA
         WHERE IdCliente = p_IdCliente
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente empresa no existe';
    END IF;

    UPDATE CLIENTE_EMPRESA
       SET RUC = p_RUC,
           RazonSocial = p_RazonSocial
     WHERE IdCliente = p_IdCliente;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'UPDATE', 'CLIENTE_EMPRESA',
        p_IdCliente, USER(), 'Cliente empresa actualizado'
    );
END$$


-- RF3: Registrar producto.
DROP PROCEDURE IF EXISTS sp_registrar_producto$$
CREATE PROCEDURE sp_registrar_producto(
    IN p_IdProducto VARCHAR(10),
    IN p_Nombre VARCHAR(120),
    IN p_Marca VARCHAR(60),
    IN p_Modelo VARCHAR(80),
    IN p_Precio DECIMAL(10,2),
    IN p_Stock INT,
    IN p_Ubicacion VARCHAR(80),
    IN p_Especificaciones VARCHAR(180),
    IN p_IdCategoria INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO PRODUCTO (
        IdProducto, Nombre, Marca, Modelo,
        Precio, Stock, Ubicacion,
        Especificaciones, IdCategoria
    )
    VALUES (
        TRIM(p_IdProducto), TRIM(p_Nombre), p_Marca, p_Modelo,
        p_Precio, p_Stock, p_Ubicacion,
        p_Especificaciones, p_IdCategoria
    );

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'PRODUCTO',
        p_IdProducto, USER(), 'Producto registrado'
    );

    COMMIT;
END$$


-- RF3 / RF14 / RN06: Actualizar producto y validar precio contra costo.
DROP PROCEDURE IF EXISTS sp_actualizar_producto$$
CREATE PROCEDURE sp_actualizar_producto(
    IN p_IdProducto VARCHAR(10),
    IN p_Nombre VARCHAR(120),
    IN p_Marca VARCHAR(60),
    IN p_Modelo VARCHAR(80),
    IN p_Precio DECIMAL(10,2),
    IN p_Stock INT,
    IN p_Ubicacion VARCHAR(80),
    IN p_Especificaciones VARCHAR(180),
    IN p_IdCategoria INT,
    IN p_AutorizacionAdmin BOOLEAN
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
          FROM PRODUCTO
         WHERE IdProducto = p_IdProducto
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto indicado no existe';
    END IF;

    IF NOT fn_validar_precio_venta(
        p_IdProducto,
        p_Precio,
        p_AutorizacionAdmin
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Precio menor al costo: requiere autorizacion administrativa';
    END IF;

    UPDATE PRODUCTO
       SET Nombre = p_Nombre,
           Marca = p_Marca,
           Modelo = p_Modelo,
           Precio = p_Precio,
           Stock = p_Stock,
           Ubicacion = p_Ubicacion,
           Especificaciones = p_Especificaciones,
           IdCategoria = p_IdCategoria
     WHERE IdProducto = p_IdProducto;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'UPDATE', 'PRODUCTO',
        p_IdProducto, USER(), 'Producto actualizado'
    );

    COMMIT;
END$$


-- RF10: Registrar proveedor.
DROP PROCEDURE IF EXISTS sp_registrar_proveedor$$
CREATE PROCEDURE sp_registrar_proveedor(
    IN p_IdProveedor VARCHAR(10),
    IN p_Nombre VARCHAR(120),
    IN p_Telefono VARCHAR(15),
    IN p_Direccion VARCHAR(120),
    IN p_Correo VARCHAR(100),
    IN p_RUC CHAR(11)
)
BEGIN
    IF p_RUC IS NULL OR CHAR_LENGTH(p_RUC) <> 11 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El RUC debe tener 11 digitos';
    END IF;

    INSERT INTO PROVEEDOR (
        IdProveedor, Nombre, Telefono,
        Direccion, Correo, RUC
    )
    VALUES (
        p_IdProveedor, p_Nombre, p_Telefono,
        p_Direccion, p_Correo, p_RUC
    );

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'PROVEEDOR',
        p_IdProveedor, USER(), 'Proveedor registrado'
    );
END$$


-- RF10: Actualizar proveedor.
DROP PROCEDURE IF EXISTS sp_actualizar_proveedor$$
CREATE PROCEDURE sp_actualizar_proveedor(
    IN p_IdProveedor VARCHAR(10),
    IN p_Nombre VARCHAR(120),
    IN p_Telefono VARCHAR(15),
    IN p_Direccion VARCHAR(120),
    IN p_Correo VARCHAR(100),
    IN p_RUC CHAR(11)
)
BEGIN
    IF p_RUC IS NULL OR CHAR_LENGTH(p_RUC) <> 11 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El RUC debe tener 11 digitos';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM PROVEEDOR
         WHERE IdProveedor = p_IdProveedor
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El proveedor indicado no existe';
    END IF;

    UPDATE PROVEEDOR
       SET Nombre = p_Nombre,
           Telefono = p_Telefono,
           Direccion = p_Direccion,
           Correo = p_Correo,
           RUC = p_RUC
     WHERE IdProveedor = p_IdProveedor;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'UPDATE', 'PROVEEDOR',
        p_IdProveedor, USER(), 'Proveedor actualizado'
    );
END$$


-- RF12: Consultar comprobantes de ventas y compras.
DROP PROCEDURE IF EXISTS sp_consultar_comprobantes$$
CREATE PROCEDURE sp_consultar_comprobantes()
BEGIN
    SELECT
        c.IdComprobante,
        c.TipoComprobante,
        c.Serie,
        c.Correlativo,
        'VENTA' AS Origen,
        CAST(cv.IdVenta AS CHAR) AS IdOperacion,
        cv.Estado
    FROM COMPROBANTE c
    INNER JOIN COMPROBANTE_VENTA cv
            ON cv.IdComprobante = c.IdComprobante

    UNION ALL

    SELECT
        c.IdComprobante,
        c.TipoComprobante,
        c.Serie,
        c.Correlativo,
        'COMPRA' AS Origen,
        CAST(cc.IdCompra AS CHAR) AS IdOperacion,
        'REGISTRADO' AS Estado
    FROM COMPROBANTE c
    INNER JOIN COMPROBANTE_COMPRA cc
            ON cc.IdComprobante = c.IdComprobante

    ORDER BY IdComprobante;
END$$


-- RF19: Consultar auditoria de productos.
DROP PROCEDURE IF EXISTS sp_consultar_auditoria_producto$$
CREATE PROCEDURE sp_consultar_auditoria_producto(
    IN p_IdProducto VARCHAR(10)
)
BEGIN
    SELECT
        IdAuditoria,
        IdProducto,
        CampoModificado,
        ValorAnterior,
        ValorNuevo,
        Usuario,
        FechaCambio
    FROM AUDITORIA_PRODUCTO
    WHERE p_IdProducto IS NULL
       OR IdProducto = p_IdProducto
    ORDER BY FechaCambio DESC, IdAuditoria DESC;
END$$


-- RF19 / RF20: Consultar operaciones relevantes auditadas.
DROP PROCEDURE IF EXISTS sp_consultar_auditoria_operaciones$$
CREATE PROCEDURE sp_consultar_auditoria_operaciones()
BEGIN
    SELECT
        IdAuditoria,
        TipoOperacion,
        TablaAfectada,
        IdReferencia,
        Usuario,
        Detalle,
        FechaOperacion
    FROM AUDITORIA_OPERACION
    ORDER BY FechaOperacion DESC, IdAuditoria DESC;
END$$

DELIMITER ;


-- ====================================================================
-- PARTE E: TRANSACCIONES COMPLEJAS Y CONTROL DE EXCEPCIONES
-- ====================================================================

DELIMITER $$

-- RF6 / RF11 / RF12 / RN06 / RN09 / RN10 / RN11
-- Registrar una venta con un producto, comprobante y pago inicial opcional.
DROP PROCEDURE IF EXISTS sp_registrar_venta_segura$$
CREATE PROCEDURE sp_registrar_venta_segura(
    IN p_IdCliente VARCHAR(45),
    IN p_IdEmpleado INT,
    IN p_IdProducto VARCHAR(10),
    IN p_Cantidad INT,
    IN p_MontoPagoInicial DECIMAL(10,2),
    IN p_MetodoPago VARCHAR(45),
    IN p_TipoComprobante VARCHAR(45),
    IN p_Serie VARCHAR(10),
    IN p_Correlativo VARCHAR(10),
    IN p_AutorizacionAdmin BOOLEAN
)
BEGIN
    DECLARE v_IdVenta INT;
    DECLARE v_IdDetalleVenta INT;
    DECLARE v_IdPago INT;
    DECLARE v_IdComprobante INT;
    DECLARE v_PrecioVenta DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_Total DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_EstadoEmpleado VARCHAR(20) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
          FROM CLIENTE
         WHERE IdCliente = p_IdCliente
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente indicado no existe';
    END IF;

    SELECT Estado
      INTO v_EstadoEmpleado
      FROM EMPLEADO
     WHERE IdEmpleado = p_IdEmpleado
     LIMIT 1;

    IF v_EstadoEmpleado IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado indicado no existe';
    END IF;

    IF v_EstadoEmpleado <> 'Activo' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado no se encuentra activo';
    END IF;

    IF p_Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad debe ser mayor que cero';
    END IF;

    SELECT Precio
      INTO v_PrecioVenta
      FROM PRODUCTO
     WHERE IdProducto = p_IdProducto
     LIMIT 1;

    IF v_PrecioVenta IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto indicado no existe';
    END IF;

    IF NOT fn_validar_precio_venta(
        p_IdProducto,
        v_PrecioVenta,
        p_AutorizacionAdmin
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Precio menor al costo: requiere autorizacion administrativa';
    END IF;

    SET v_Total = v_PrecioVenta * p_Cantidad;

    IF p_MontoPagoInicial < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El pago inicial no puede ser negativo';
    END IF;

    IF p_MontoPagoInicial > v_Total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El pago inicial no puede superar el total de la venta';
    END IF;

    SELECT COALESCE(MAX(IdVenta), 0) + 1
      INTO v_IdVenta
      FROM VENTA;

    SELECT COALESCE(MAX(IdDetalleVenta), 0) + 1
      INTO v_IdDetalleVenta
      FROM DETALLE_VENTA;

    SELECT COALESCE(MAX(IdComprobante), 0) + 1
      INTO v_IdComprobante
      FROM COMPROBANTE;

    INSERT INTO VENTA (
        IdVenta, Fecha, IdCliente, IdEmpleado
    )
    VALUES (
        v_IdVenta, CURDATE(), p_IdCliente, p_IdEmpleado
    );

    INSERT INTO DETALLE_VENTA (
        IdDetalleVenta, IdVenta,
        IdProducto, PrecioUnitario, Cantidad
    )
    VALUES (
        v_IdDetalleVenta, v_IdVenta,
        p_IdProducto, v_PrecioVenta, p_Cantidad
    );

    INSERT INTO COMPROBANTE (
        IdComprobante, Correlativo,
        Serie, TipoComprobante
    )
    VALUES (
        v_IdComprobante, p_Correlativo,
        p_Serie, p_TipoComprobante
    );

    INSERT INTO COMPROBANTE_VENTA (
        IdComprobante, IdVenta, Estado
    )
    VALUES (
        v_IdComprobante,
        v_IdVenta,
        CASE
            WHEN p_MontoPagoInicial = v_Total THEN 'Pagado'
            ELSE 'Pendiente'
        END
    );

    IF p_MontoPagoInicial > 0 THEN
        SELECT COALESCE(MAX(IdPago), 0) + 1
          INTO v_IdPago
          FROM PAGO;

        INSERT INTO PAGO (
            IdPago, Fecha, Monto, MetodoPago
        )
        VALUES (
            v_IdPago, CURDATE(),
            p_MontoPagoInicial, p_MetodoPago
        );

        INSERT INTO PAGO_VENTA (
            IdPago, IdVenta, Estado
        )
        VALUES (
            v_IdPago,
            v_IdVenta,
            CASE
                WHEN p_MontoPagoInicial = v_Total THEN 'Pagado'
                ELSE 'Parcial'
            END
        );
    END IF;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'VENTA',
        CAST(v_IdVenta AS CHAR),
        USER(),
        CONCAT('Venta registrada. Total: ', v_Total)
    );

    COMMIT;

    SELECT
        v_IdVenta AS IdVenta,
        v_Total AS TotalVenta,
        fn_total_pagado_venta(v_IdVenta) AS TotalPagado,
        fn_saldo_venta(v_IdVenta) AS SaldoPendiente,
        'VENTA REGISTRADA CORRECTAMENTE' AS Resultado;
END$$


-- RF6: Agregar otro producto a una venta existente.
DROP PROCEDURE IF EXISTS sp_agregar_producto_venta$$
CREATE PROCEDURE sp_agregar_producto_venta(
    IN p_IdVenta INT,
    IN p_IdProducto VARCHAR(10),
    IN p_Cantidad INT,
    IN p_AutorizacionAdmin BOOLEAN
)
BEGIN
    DECLARE v_IdDetalleVenta INT;
    DECLARE v_PrecioVenta DECIMAL(10,2) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
          FROM VENTA
         WHERE IdVenta = p_IdVenta
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La venta indicada no existe';
    END IF;

    IF p_Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad debe ser mayor que cero';
    END IF;

    SELECT Precio
      INTO v_PrecioVenta
      FROM PRODUCTO
     WHERE IdProducto = p_IdProducto
     LIMIT 1;

    IF v_PrecioVenta IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto indicado no existe';
    END IF;

    IF NOT fn_validar_precio_venta(
        p_IdProducto,
        v_PrecioVenta,
        p_AutorizacionAdmin
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Precio menor al costo: requiere autorizacion administrativa';
    END IF;

    SELECT COALESCE(MAX(IdDetalleVenta), 0) + 1
      INTO v_IdDetalleVenta
      FROM DETALLE_VENTA;

    INSERT INTO DETALLE_VENTA (
        IdDetalleVenta, IdVenta,
        IdProducto, PrecioUnitario, Cantidad
    )
    VALUES (
        v_IdDetalleVenta, p_IdVenta,
        p_IdProducto, v_PrecioVenta, p_Cantidad
    );

    UPDATE COMPROBANTE_VENTA
       SET Estado = CASE
           WHEN fn_saldo_venta(p_IdVenta) <= 0 THEN 'Pagado'
           ELSE 'Pendiente'
       END
     WHERE IdVenta = p_IdVenta;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'DETALLE_VENTA',
        CAST(v_IdDetalleVenta AS CHAR),
        USER(),
        CONCAT('Producto ', p_IdProducto, ' agregado a venta ', p_IdVenta)
    );

    COMMIT;

    SELECT
        p_IdVenta AS IdVenta,
        fn_total_venta(p_IdVenta) AS NuevoTotal,
        fn_saldo_venta(p_IdVenta) AS SaldoPendiente,
        'PRODUCTO AGREGADO A LA VENTA' AS Resultado;
END$$


-- RF11 / RN09: Registrar pagos adicionales de una venta.
DROP PROCEDURE IF EXISTS sp_agregar_pago_venta$$
CREATE PROCEDURE sp_agregar_pago_venta(
    IN p_IdVenta INT,
    IN p_Monto DECIMAL(10,2),
    IN p_MetodoPago VARCHAR(45)
)
BEGIN
    DECLARE v_IdPago INT;
    DECLARE v_Saldo DECIMAL(12,2) DEFAULT 0.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
          FROM VENTA
         WHERE IdVenta = p_IdVenta
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La venta indicada no existe';
    END IF;

    IF p_Monto <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El monto del pago debe ser mayor que cero';
    END IF;

    SET v_Saldo = fn_saldo_venta(p_IdVenta);

    IF v_Saldo <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La venta ya se encuentra pagada';
    END IF;

    IF p_Monto > v_Saldo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El pago supera el saldo pendiente';
    END IF;

    SELECT COALESCE(MAX(IdPago), 0) + 1
      INTO v_IdPago
      FROM PAGO;

    INSERT INTO PAGO (
        IdPago, Fecha, Monto, MetodoPago
    )
    VALUES (
        v_IdPago, CURDATE(), p_Monto, p_MetodoPago
    );

    INSERT INTO PAGO_VENTA (
        IdPago, IdVenta, Estado
    )
    VALUES (
        v_IdPago,
        p_IdVenta,
        CASE
            WHEN p_Monto = v_Saldo THEN 'Pagado'
            ELSE 'Parcial'
        END
    );

    UPDATE COMPROBANTE_VENTA
       SET Estado = CASE
           WHEN fn_saldo_venta(p_IdVenta) = 0 THEN 'Pagado'
           ELSE 'Pendiente'
       END
     WHERE IdVenta = p_IdVenta;

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'PAGO_VENTA',
        CAST(v_IdPago AS CHAR),
        USER(),
        CONCAT('Pago registrado para venta ', p_IdVenta)
    );

    COMMIT;

    SELECT
        p_IdVenta AS IdVenta,
        fn_total_pagado_venta(p_IdVenta) AS TotalPagado,
        fn_saldo_venta(p_IdVenta) AS SaldoPendiente,
        'PAGO REGISTRADO CORRECTAMENTE' AS Resultado;
END$$


-- RF8 / RF9 / RF11 / RF12 / RN05 / RN07 / RN08 / RN09
-- Registrar compra con proveedor, stock, pago unico y comprobante.
DROP PROCEDURE IF EXISTS sp_registrar_compra_segura$$
CREATE PROCEDURE sp_registrar_compra_segura(
    IN p_IdProveedor VARCHAR(10),
    IN p_IdProducto VARCHAR(10),
    IN p_Cantidad INT,
    IN p_PrecioCompra DECIMAL(10,2),
    IN p_MetodoPago VARCHAR(45),
    IN p_TipoComprobante VARCHAR(45),
    IN p_Serie VARCHAR(10),
    IN p_Correlativo VARCHAR(10)
)
BEGIN
    DECLARE v_IdCompra INT;
    DECLARE v_IdDetalleCompra INT;
    DECLARE v_IdPago INT;
    DECLARE v_IdComprobante INT;
    DECLARE v_Total DECIMAL(12,2) DEFAULT 0.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
          FROM PROVEEDOR
         WHERE IdProveedor = p_IdProveedor
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La compra debe tener un proveedor existente';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM PRODUCTO
         WHERE IdProducto = p_IdProducto
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto indicado no existe';
    END IF;

    IF p_Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad de compra debe ser mayor que cero';
    END IF;

    IF p_PrecioCompra <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio de compra debe ser mayor que cero';
    END IF;

    SET v_Total = p_Cantidad * p_PrecioCompra;

    SELECT COALESCE(MAX(IdCompra), 0) + 1
      INTO v_IdCompra
      FROM COMPRA;

    SELECT COALESCE(MAX(IdDetalleCompra), 0) + 1
      INTO v_IdDetalleCompra
      FROM DETALLE_COMPRA;

    SELECT COALESCE(MAX(IdPago), 0) + 1
      INTO v_IdPago
      FROM PAGO;

    SELECT COALESCE(MAX(IdComprobante), 0) + 1
      INTO v_IdComprobante
      FROM COMPROBANTE;

    INSERT INTO COMPRA (
        IdCompra, Fecha, MontoTotal, IdProveedor
    )
    VALUES (
        v_IdCompra, CURDATE(), v_Total, p_IdProveedor
    );

    INSERT INTO DETALLE_COMPRA (
        IdDetalleCompra, IdCompra,
        IdProducto, PrecioCompra, Cantidad
    )
    VALUES (
        v_IdDetalleCompra, v_IdCompra,
        p_IdProducto, p_PrecioCompra, p_Cantidad
    );

    -- RN09: La compra queda asociada a un unico pago por el total.
    INSERT INTO PAGO (
        IdPago, Fecha, Monto, MetodoPago
    )
    VALUES (
        v_IdPago, CURDATE(), v_Total, p_MetodoPago
    );

    INSERT INTO PAGO_COMPRA (
        IdPago, IdCompra
    )
    VALUES (
        v_IdPago, v_IdCompra
    );

    INSERT INTO COMPROBANTE (
        IdComprobante, Correlativo,
        Serie, TipoComprobante
    )
    VALUES (
        v_IdComprobante, p_Correlativo,
        p_Serie, p_TipoComprobante
    );

    INSERT INTO COMPROBANTE_COMPRA (
        IdComprobante, IdCompra
    )
    VALUES (
        v_IdComprobante, v_IdCompra
    );

    INSERT INTO AUDITORIA_OPERACION (
        TipoOperacion, TablaAfectada,
        IdReferencia, Usuario, Detalle
    )
    VALUES (
        'INSERT', 'COMPRA',
        CAST(v_IdCompra AS CHAR),
        USER(),
        CONCAT('Compra registrada. Total: ', v_Total)
    );

    COMMIT;

    SELECT
        v_IdCompra AS IdCompra,
        v_Total AS MontoTotal,
        'COMPRA REGISTRADA CORRECTAMENTE' AS Resultado;
END$$

DELIMITER ;


-- ====================================================================
-- PARTE F: VERIFICACION DEL PUNTO 2
-- ====================================================================

-- Objetos creados: funciones y procedimientos.
SELECT
    ROUTINE_TYPE,
    ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'COMERCIAL_VIDA'
  AND (
      ROUTINE_NAME LIKE 'fn_%'
      OR ROUTINE_NAME LIKE 'sp_%'
  )
ORDER BY ROUTINE_TYPE, ROUTINE_NAME;

-- Triggers creados.
SELECT
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'COMERCIAL_VIDA'
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;

-- Tablas de auditoria.
SELECT
    TABLE_NAME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'COMERCIAL_VIDA'
  AND TABLE_NAME IN ('AUDITORIA_PRODUCTO', 'AUDITORIA_OPERACION')
ORDER BY TABLE_NAME;

-- ====================================================================
-- FIN DEL PUNTO 2
-- ====================================================================
