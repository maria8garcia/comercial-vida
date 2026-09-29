DROP DATABASE IF EXISTS COMERCIAL_VIDA;
CREATE DATABASE COMERCIAL_VIDA
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE COMERCIAL_VIDA;

CREATE TABLE CLIENTE (
    IdCliente VARCHAR(45) PRIMARY KEY,
    Correo VARCHAR(100),
    Telefono VARCHAR(15) NOT NULL,
    Direccion VARCHAR(120),
    IdCliente_Recomienda VARCHAR(45),
    FOREIGN KEY (IdCliente_Recomienda) REFERENCES CLIENTE(IdCliente)
);

ALTER TABLE CLIENTE
ADD CONSTRAINT chk_cliente_telefono
CHECK (LENGTH(Telefono)=9 AND Telefono LIKE '9%');

CREATE TABLE CLIENTE_NATURAL (
    IdCliente VARCHAR(45) PRIMARY KEY,
    Nombre VARCHAR(45) NOT NULL,
    Apellido VARCHAR(80) NOT NULL,
    DNI CHAR(8) NOT NULL UNIQUE,
    FOREIGN KEY (IdCliente) REFERENCES CLIENTE(IdCliente)
);

ALTER TABLE CLIENTE_NATURAL
ADD CONSTRAINT chk_cliente_natural_dni
CHECK (LENGTH(DNI)=8);

CREATE TABLE CLIENTE_EMPRESA (
    IdCliente VARCHAR(45) PRIMARY KEY,
    RUC CHAR(11) NOT NULL UNIQUE,
    RazonSocial VARCHAR(120) NOT NULL,
    FOREIGN KEY (IdCliente) REFERENCES CLIENTE(IdCliente)
);

ALTER TABLE CLIENTE_EMPRESA
ADD CONSTRAINT chk_cliente_empresa_ruc
CHECK (LENGTH(RUC)=11);

CREATE TABLE EMPLEADO (
    IdEmpleado INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    DNI CHAR(8) NOT NULL UNIQUE,
    Correo VARCHAR(100),
    Telefono VARCHAR(15),
    Estado VARCHAR(20) NOT NULL,
    Fecha_Ingreso DATE NOT NULL,
    Cargo VARCHAR(45) NOT NULL
);

CREATE TABLE CATEGORIA (
    IdCategoria INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL UNIQUE,
    Descripcion VARCHAR(180)
);

CREATE TABLE MARCA_VEHICULO (
    IdMarcaVehiculo INT PRIMARY KEY,
    NombreMarca VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE MODELO_VEHICULO (
    IdModeloVehiculo INT PRIMARY KEY,
    NombreModelo VARCHAR(100) NOT NULL,
    IdMarcaVehiculo INT NOT NULL,
    FOREIGN KEY (IdMarcaVehiculo) REFERENCES MARCA_VEHICULO(IdMarcaVehiculo),
    UNIQUE (IdMarcaVehiculo,NombreModelo)
);

CREATE TABLE PRODUCTO (
    IdProducto VARCHAR(10) PRIMARY KEY,
    Nombre VARCHAR(120) NOT NULL,
    Marca VARCHAR(60) NOT NULL,
    Modelo VARCHAR(80),
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL,
    Ubicacion VARCHAR(80),
    Especificaciones VARCHAR(180),
    IdCategoria INT NOT NULL,
    FOREIGN KEY (IdCategoria) REFERENCES CATEGORIA(IdCategoria)
);

ALTER TABLE PRODUCTO ADD CONSTRAINT chk_producto_precio CHECK (Precio>0);
ALTER TABLE PRODUCTO ADD CONSTRAINT chk_producto_stock CHECK (Stock>=0);

CREATE TABLE COMPATIBILIDAD (
    IdCompatibilidad INT PRIMARY KEY,
    IdProducto VARCHAR(10) NOT NULL,
    Año INT NULL,
    IdModeloVehiculo INT NOT NULL,
    FOREIGN KEY (IdProducto) REFERENCES PRODUCTO(IdProducto),
    FOREIGN KEY (IdModeloVehiculo) REFERENCES MODELO_VEHICULO(IdModeloVehiculo),
    UNIQUE (IdProducto,IdModeloVehiculo, Año)
);


CREATE TABLE PROVEEDOR (
    IdProveedor VARCHAR(10) PRIMARY KEY,
    Nombre VARCHAR(120) NOT NULL,
    Telefono VARCHAR(15) NOT NULL,
    Direccion VARCHAR(120) NOT NULL,
    Correo VARCHAR(100) NOT NULL,
    RUC CHAR(11) NOT NULL UNIQUE
);

-- VALIDANDO RUC --
ALTER TABLE PROVEEDOR
ADD CONSTRAINT chk_proveedor_ruc
CHECK (LENGTH(RUC) = 11);

CREATE TABLE VENTA (
    IdVenta INT PRIMARY KEY,
    Fecha DATE NOT NULL,
    IdCliente VARCHAR(45) NOT NULL,
    IdEmpleado INT NOT NULL,
    FOREIGN KEY (IdCliente) REFERENCES CLIENTE(IdCliente),
    FOREIGN KEY (IdEmpleado) REFERENCES EMPLEADO(IdEmpleado)
);

CREATE TABLE DETALLE_VENTA (
    IdDetalleVenta INT PRIMARY KEY,
    IdVenta INT NOT NULL,
    IdProducto VARCHAR(10) NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Cantidad INT NOT NULL,
    FOREIGN KEY (IdVenta) REFERENCES VENTA(IdVenta),
    FOREIGN KEY (IdProducto) REFERENCES PRODUCTO(IdProducto),
    UNIQUE (IdVenta,IdProducto)
);

ALTER TABLE DETALLE_VENTA ADD CONSTRAINT chk_dv_precio CHECK (PrecioUnitario>0);
ALTER TABLE DETALLE_VENTA ADD CONSTRAINT chk_dv_cantidad CHECK (Cantidad>0);

CREATE TABLE COMPRA (
    IdCompra INT PRIMARY KEY,
    Fecha DATE NOT NULL,
    MontoTotal DECIMAL(10,2) NOT NULL,
    IdProveedor VARCHAR(10) NOT NULL,
    FOREIGN KEY (IdProveedor) REFERENCES PROVEEDOR(IdProveedor)
);

ALTER TABLE COMPRA ADD CONSTRAINT chk_compra_total CHECK (MontoTotal>0);

CREATE TABLE DETALLE_COMPRA (
    IdDetalleCompra INT PRIMARY KEY,
    IdCompra INT NOT NULL,
    IdProducto VARCHAR(10) NOT NULL,
    PrecioCompra DECIMAL(10,2) NOT NULL,
    Cantidad INT NOT NULL,
    FOREIGN KEY (IdCompra) REFERENCES COMPRA(IdCompra),
    FOREIGN KEY (IdProducto) REFERENCES PRODUCTO(IdProducto),
    UNIQUE (IdCompra,IdProducto)
);

ALTER TABLE DETALLE_COMPRA ADD CONSTRAINT chk_dc_precio CHECK (PrecioCompra>0);
ALTER TABLE DETALLE_COMPRA ADD CONSTRAINT chk_dc_cantidad CHECK (Cantidad>0);

CREATE TABLE PAGO (
    IdPago INT PRIMARY KEY,
    Fecha DATE NOT NULL,
    Monto DECIMAL(10,2) NOT NULL,
    MetodoPago VARCHAR(45) NOT NULL
);

ALTER TABLE PAGO ADD CONSTRAINT chk_pago_monto CHECK (Monto>0);
ALTER TABLE PAGO ADD CONSTRAINT chk_pago_metodo CHECK (
 MetodoPago IN ('Efectivo','Yape','Plin','Transferencia','Tarjeta Crédito','Tarjeta Débito')
);

CREATE TABLE PAGO_VENTA (
    IdPago INT PRIMARY KEY,
    IdVenta INT NOT NULL,
    Estado VARCHAR(20) NOT NULL,
    FOREIGN KEY (IdPago) REFERENCES PAGO(IdPago),
    FOREIGN KEY (IdVenta) REFERENCES VENTA(IdVenta)
);

CREATE TABLE PAGO_COMPRA (
    IdPago INT PRIMARY KEY,
    IdCompra INT NOT NULL,
    FOREIGN KEY (IdPago) REFERENCES PAGO(IdPago),
    FOREIGN KEY (IdCompra) REFERENCES COMPRA(IdCompra)
);
ALTER TABLE PAGO_COMPRA
ADD CONSTRAINT uq_pago_compra_idcompra
UNIQUE (IdCompra);

CREATE TABLE COMPROBANTE (
    IdComprobante INT PRIMARY KEY,
    Correlativo VARCHAR(10) NOT NULL,
    Serie VARCHAR(10) NOT NULL,
    TipoComprobante VARCHAR(45) NOT NULL,
    UNIQUE (Serie,Correlativo)
);

CREATE TABLE COMPROBANTE_VENTA (
    IdComprobante INT PRIMARY KEY,
    IdVenta INT NOT NULL UNIQUE,
    Estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    FOREIGN KEY (IdComprobante) REFERENCES COMPROBANTE(IdComprobante),
    FOREIGN KEY (IdVenta) REFERENCES VENTA(IdVenta)
);

CREATE TABLE COMPROBANTE_COMPRA (
    IdComprobante INT PRIMARY KEY,
    IdCompra INT NOT NULL UNIQUE,
    FOREIGN KEY (IdComprobante) REFERENCES COMPROBANTE(IdComprobante),
    FOREIGN KEY (IdCompra) REFERENCES COMPRA(IdCompra)
);
-- VALIDANDO COMPROBANTE --
ALTER TABLE COMPROBANTE
ADD CONSTRAINT chk_comprobante_tipo
CHECK (TipoComprobante IN ('Boleta','Factura'));

INSERT INTO CLIENTE (IdCliente,Correo,Telefono,Direccion,IdCliente_Recomienda) VALUES
('CLN001','ricardosalazar545@gmail.com','985716766','Av. Abancay 3906, Lima',NULL),
('CLN002','dianavega817@hotmail.com','939448532','Av. Trapiche 2545, Comas',NULL),
('CLN003','carloshuaman782@gmail.com','999961432','Av. Grau 2625, Lima',NULL),
('CLN004','monicareyes704@hotmail.com','907456274','Av. Argentina 3680, Callao',NULL),
('CLN005','victorsalazar775@gmail.com','979828612','Av. Carlos Izaguirre 2232, Los Olivos',NULL),
('CLN006','cynthiapalacios918@hotmail.com','996525480','Av. Canadá 3604, La Victoria',NULL),
('CLN007','miguelrojas221@gmail.com','926999135','Av. Canadá 4874, La Victoria',NULL),
('CLN008','andreaortega14@hotmail.com','975355193','Av. Próceres de Huandoy 888, Los Olivos',NULL),
('CLN009','pedrotorres521@gmail.com','957094967','Av. Guardia Civil 1321, San Borja',NULL),
('CLN010','dianamolina260@hotmail.com','996951575','Av. Naranjal 3946, Los Olivos','CLN005'),
('CLN011','ricardocastillo582@gmail.com','947504124','Av. Colonial 4846, Lima',NULL),
('CLN012','adrianavaldivia980@hotmail.com','953879675','Av. La Molina 3175, La Molina',NULL),
('CLN013','jorgesalazar857@gmail.com','986600825','Av. Venezuela 4311, Breña',NULL),
('CLN014','andrealeon391@hotmail.com','986594441','Av. Nicolás Ayllón 4154, Ate',NULL),
('CLN015','marcosoto389@gmail.com','991472843','Av. Separadora Industrial 1544, Ate','CLN006'),
('CLN016','lorenacabrera289@hotmail.com','978875854','Av. Javier Prado 2196, San Isidro',NULL),
('CLN017','victorarias865@gmail.com','924629059','Av. Nicolás Ayllón 443, Ate',NULL),
('CLN018','claudiaespinoza505@hotmail.com','933515538','Av. Arequipa 1471, Lince',NULL),
('CLN019','cesarhuaman829@gmail.com','994485698','Av. La Marina 274, San Miguel',NULL),
('CLN020','dianaramirez728@hotmail.com','962415888','Av. Próceres de Huandoy 4589, Los Olivos','CLN008'),
('CLN021','hugonavarro871@gmail.com','973040270','Av. Próceres de Huandoy 4870, Los Olivos',NULL),
('CLN022','fiorellatapia99@hotmail.com','934157546','Av. Aviación 199, San Borja',NULL),
('CLN023','diegoramos444@gmail.com','917439291','Av. Canadá 4307, La Victoria',NULL),
('CLN024','dianarojas227@hotmail.com','960203637','Av. Aviación 3357, San Borja',NULL),
('CLN025','joseherrera460@gmail.com','936549950','Av. Grau 3280, Lima','CLN012'),
('CLN026','rosatapia949@hotmail.com','960851261','Av. Guardia Civil 1230, San Borja',NULL),
('CLN027','brunoreyes537@gmail.com','945739820','Av. Javier Prado 804, San Isidro',NULL),
('CLN028','veronicagarcia485@hotmail.com','932292299','Av. Colonial 1633, Lima',NULL),
('CLN029','eduardoarias959@gmail.com','988365837','Av. Aviación 2508, San Borja',NULL),
('CLN030','milagrosramos580@hotmail.com','980259928','Av. Trapiche 3585, Comas','CLN015'),
('CLN031','andresrojas63@gmail.com','912262930','Av. Canadá 1015, La Victoria',NULL),
('CLN032','anareyes592@hotmail.com','908737165','Av. Colonial 2836, Lima',NULL),
('CLN033','martinparedes815@gmail.com','934393429','Av. La Molina 480, La Molina',NULL),
('CLN034','dianaortega196@hotmail.com','962571911','Av. México 907, La Victoria',NULL),
('CLN035','renzoreyes277@gmail.com','914419609','Av. Universitaria 518, Los Olivos','CLN034'),
('CLN036','luciavega262@hotmail.com','904880010','Av. Separadora Industrial 3904, Ate',NULL),
('CLN037','jorgeleon445@gmail.com','911176673','Av. Guardia Civil 4889, San Borja',NULL),
('CLN038','rosaparedes554@hotmail.com','991409544','Av. Carlos Izaguirre 2734, Los Olivos',NULL),
('CLN039','jorgereyes971@gmail.com','988746123','Av. Tomás Valle 4129, San Martín de Porres',NULL),
('CLN040','anaespinoza526@hotmail.com','940718460','Av. Abancay 3882, Lima','CLN028'),
('CLN041','luisfuentes992@gmail.com','939328151','Av. Caminos del Inca 3086, Santiago de Surco',NULL),
('CLN042','danielaespinoza480@hotmail.com','984097830','Av. Los Alisos 2655, Los Olivos',NULL),
('CLN043','marcorojas822@gmail.com','925552967','Av. Carlos Izaguirre 2253, Los Olivos',NULL),
('CLN044','claudianunez611@hotmail.com','972663829','Av. Carlos Izaguirre 4452, Los Olivos',NULL),
('CLN045','renzoquispe446@gmail.com','969652650','Av. La Molina 4741, La Molina','CLN009'),
('CLN046','lorenanunez97@hotmail.com','990408254','Av. Arequipa 2172, Lince',NULL),
('CLN047','andrescruz36@gmail.com','918811010','Av. La Marina 575, San Miguel',NULL),
('CLN048','fiorellarojas842@hotmail.com','981161303','Av. Benavides 1484, Miraflores',NULL),
('CLN049','alvaroramirez160@gmail.com','948677555','Av. Canadá 2072, La Victoria',NULL),
('CLN050','fiorellareyes798@hotmail.com','959297548','Av. Separadora Industrial 2557, Ate','CLN009'),
('CLN051','manuelhuaman651@gmail.com','930078287','Av. Guardia Civil 3864, San Borja',NULL),
('CLN052','luciahuaman904@hotmail.com','909225085','Av. Túpac Amaru 1588, Comas',NULL),
('CLN053','hugocardenas126@gmail.com','948998184','Av. Tomás Valle 867, San Martín de Porres',NULL),
('CLN054','veronicatapia550@hotmail.com','934044390','Av. Naranjal 525, Los Olivos',NULL),
('CLN055','jorgeespinoza151@gmail.com','909449566','Av. Nicolás Ayllón 4551, Ate','CLN039'),
('CLN056','dianatapia267@hotmail.com','964589570','Av. Venezuela 2333, Breña',NULL),
('CLN057','cesarmedina521@gmail.com','902307790','Av. Benavides 1731, Miraflores',NULL),
('CLN058','gabrielacabrera837@hotmail.com','969759303','Av. México 2589, La Victoria',NULL),
('CLN059','victorcastillo13@gmail.com','998837943','Av. Caminos del Inca 4285, Santiago de Surco',NULL),
('CLN060','andreacruz91@hotmail.com','916321658','Av. Alfredo Mendiola 3431, San Martín de Porres','CLN049'),
('CLN061','martinflores916@gmail.com','945970079','Av. Nicolás Ayllón 4625, Ate',NULL),
('CLN062','claudiasoto612@hotmail.com','925265702','Av. Trapiche 4174, Comas',NULL),
('CLN063','diegoparedes234@gmail.com','955636756','Av. Aviación 572, San Borja',NULL),
('CLN064','claudiatapia717@hotmail.com','985129359','Av. La Marina 2301, San Miguel',NULL),
('CLN065','brunotorres565@gmail.com','957533897','Av. Caminos del Inca 4758, Santiago de Surco','CLN024'),
('CLN066','lorenasoto285@hotmail.com','978176454','Av. Túpac Amaru 4282, Comas',NULL),
('CLN067','andressanchez796@gmail.com','918160267','Av. Iquitos 3236, La Victoria',NULL),
('CLN068','paolaparedes757@hotmail.com','962537666','Av. Los Alisos 2733, Los Olivos',NULL),
('CLN069','manuelarias180@gmail.com','931512806','Av. La Marina 810, San Miguel',NULL),
('CLN070','mariasoto49@hotmail.com','960230630','Av. Guardia Civil 4654, San Borja','CLN025'),
('CLN071','eduardocastillo181@gmail.com','951172111','Av. México 526, La Victoria',NULL),
('CLN072','patriciaramos704@hotmail.com','915347060','Av. Canadá 3420, La Victoria',NULL),
('CLN073','carlosquispe21@gmail.com','964416565','Av. Benavides 2484, Miraflores',NULL),
('CLN074','alejandranavarro819@hotmail.com','948386712','Av. Benavides 1347, Miraflores',NULL),
('CLN075','andressalazar949@gmail.com','925082259','Av. México 3671, La Victoria','CLN017'),
('CLN076','gabrielachavez686@hotmail.com','996193934','Av. Abancay 1203, Lima',NULL),
('CLN077','gonzalosoto939@gmail.com','951845250','Av. Caminos del Inca 959, Santiago de Surco',NULL),
('CLN078','veronicavaldivia481@hotmail.com','963138066','Av. Próceres de Huandoy 3217, Los Olivos',NULL),
('CLN079','josecampos779@gmail.com','986586356','Av. Carlos Izaguirre 1852, Los Olivos',NULL),
('CLN080','rosaaguilar255@hotmail.com','921695136','Av. Brasil 280, Jesús María','CLN009'),
('CLN081','martinmolina872@gmail.com','925502201','Av. La Molina 1236, La Molina',NULL),
('CLN082','katherinefuentes464@hotmail.com','974318633','Av. Tomás Valle 2021, San Martín de Porres',NULL),
('CLN083','miguelespinoza381@gmail.com','950659168','Av. México 3539, La Victoria',NULL),
('CLN084','milagrosvargas148@hotmail.com','996996139','Av. Carlos Izaguirre 893, Los Olivos',NULL),
('CLN085','joseaguilar873@gmail.com','905037651','Av. Guardia Civil 988, San Borja','CLN008'),
('CLN086','alejandranunez863@hotmail.com','981056886','Av. La Molina 346, La Molina',NULL),
('CLN087','andresramos336@gmail.com','980292798','Av. Universitaria 1209, Los Olivos',NULL),
('CLN088','mariaarias49@hotmail.com','936278126','Av. Colonial 191, Lima',NULL),
('CLN089','luisherrera143@gmail.com','900149862','Av. Grau 567, Lima',NULL),
('CLN090','nataliavaldivia653@hotmail.com','950446321','Av. Brasil 4318, Jesús María','CLN081'),
('CLN091','sergiosanchez226@gmail.com','908388986','Av. Colonial 1798, Lima',NULL),
('CLN092','fiorellacardenas688@hotmail.com','905262613','Av. Brasil 2218, Jesús María',NULL),
('CLN093','joselozano933@gmail.com','922519466','Av. Nicolás Ayllón 2013, Ate',NULL),
('CLN094','veronicalozano873@hotmail.com','951103888','Av. Guardia Civil 4517, San Borja',NULL),
('CLN095','marcomendoza617@gmail.com','999906353','Av. Benavides 601, Miraflores','CLN031'),
('CLN096','valeriacruz295@hotmail.com','935601557','Av. La Molina 4721, La Molina',NULL),
('CLN097','jorgetorres954@gmail.com','924634877','Av. Benavides 3875, Miraflores',NULL),
('CLN098','carolinaquispe14@hotmail.com','932167130','Av. La Molina 810, La Molina',NULL),
('CLN099','alvaronunez342@gmail.com','925304529','Av. Tomás Valle 1009, San Martín de Porres',NULL),
('CLN100','sofiamolina517@hotmail.com','999724066','Av. Nicolás Ayllón 892, Ate','CLN009'),
('CLE001','ventas.autopartespremiums78@gmail.com','972909820','Av. Tomás Valle 3210, San Martín de Porres',NULL),
('CLE002','ventas.suspensioneslimasa66@hotmail.com','925719128','Av. Grau 620, Lima',NULL),
('CLE003','ventas.comercialandinasac12@gmail.com','920856241','Av. Tomás Valle 2109, San Martín de Porres',NULL),
('CLE004','ventas.rodamientospacific68@hotmail.com','999553610','Av. Túpac Amaru 4338, Comas',NULL),
('CLE005','ventas.importacionespacif53@gmail.com','934860450','Av. Aviación 2024, San Borja','CLN090'),
('CLE006','ventas.autopartespremiums50@hotmail.com','931477338','Av. Trapiche 2653, Comas',NULL),
('CLE007','ventas.repuestosexpresssa39@gmail.com','947171043','Av. Colonial 3303, Lima',NULL),
('CLE008','ventas.frenosnorteeirl35@hotmail.com','942038794','Av. Arequipa 4174, Lince',NULL),
('CLE009','ventas.rodamientoslimasac86@gmail.com','998378838','Av. Abancay 4555, Lima',NULL),
('CLE010','ventas.serviciosautomotri35@hotmail.com','966600259','Av. Iquitos 1961, La Victoria','CLN084'),
('CLE011','ventas.autoparteslosolivo91@gmail.com','949993675','Av. La Molina 1757, La Molina',NULL),
('CLE012','ventas.autopartesdelpacif27@hotmail.com','936102229','Av. La Molina 642, La Molina',NULL),
('CLE013','ventas.serviciosautomotri47@gmail.com','983627530','Av. Universitaria 546, Los Olivos',NULL),
('CLE014','ventas.distribuidorapremi70@hotmail.com','976388345','Av. Grau 2431, Lima',NULL),
('CLE015','ventas.transmisionesmetro22@gmail.com','957287464','Av. Argentina 2581, Callao','CLN080'),
('CLE016','ventas.lubricantescentral36@hotmail.com','953429851','Av. Brasil 2382, Jesús María',NULL),
('CLE017','ventas.rodamientoslimasac59@gmail.com','906619977','Av. Próceres de Huandoy 4813, Los Olivos',NULL),
('CLE018','ventas.transmisionespremi69@hotmail.com','987975637','Av. Separadora Industrial 2008, Ate',NULL),
('CLE019','ventas.comercialperueirl44@gmail.com','969948810','Av. Universitaria 320, Los Olivos',NULL),
('CLE020','ventas.repuestosdelpacifi77@hotmail.com','992733119','Av. La Molina 3502, La Molina','CLE014'),
('CLE021','ventas.distribuidorapacif51@gmail.com','924322314','Av. Benavides 1978, Miraflores',NULL),
('CLE022','ventas.rodamientoscentral91@hotmail.com','906509608','Av. Universitaria 4858, Los Olivos',NULL),
('CLE023','ventas.serviciosautomotri91@gmail.com','956074581','Av. Aviación 3430, San Borja',NULL),
('CLE024','ventas.accesoriosdelpacif94@hotmail.com','917249206','Av. Universitaria 3880, Los Olivos',NULL),
('CLE025','ventas.frenoscentralsac15@gmail.com','918523520','Av. Iquitos 1523, La Victoria','CLN098'),
('CLE026','ventas.suspensionespacifi69@hotmail.com','902508417','Av. Naranjal 1501, Los Olivos',NULL),
('CLE027','ventas.motoresmotorssac85@gmail.com','984312404','Av. Naranjal 781, Los Olivos',NULL),
('CLE028','ventas.comercialindustria74@hotmail.com','933129777','Av. Argentina 1770, Callao',NULL),
('CLE029','ventas.serviciosautomotri20@gmail.com','996013169','Av. Caminos del Inca 3337, Santiago de Surco',NULL),
('CLE030','ventas.motoresdelnortesac91@hotmail.com','924771554','Av. Primavera 662, Santiago de Surco','CLN021'),
('CLE031','ventas.accesoriossanmarti72@gmail.com','928778179','Av. Brasil 1056, Jesús María',NULL),
('CLE032','ventas.accesoriossanmarti87@hotmail.com','920468269','Av. Separadora Industrial 829, Ate',NULL),
('CLE033','ventas.suspensioneslosoli11@gmail.com','983419640','Av. Nicolás Ayllón 3276, Ate',NULL),
('CLE034','ventas.motoresdelpacifico74@hotmail.com','943209256','Av. Túpac Amaru 300, Comas',NULL),
('CLE035','ventas.lubricantespacific36@gmail.com','956702696','Av. Nicolás Ayllón 2139, Ate','CLN045'),
('CLE036','ventas.transmisionespacif54@hotmail.com','952353795','Av. Abancay 2299, Lima',NULL),
('CLE037','ventas.comercialsanmartin69@gmail.com','971002142','Av. Carlos Izaguirre 3904, Los Olivos',NULL),
('CLE038','ventas.comercialandinasac18@hotmail.com','948404659','Av. Próceres de Huandoy 4660, Los Olivos',NULL),
('CLE039','ventas.transmisionesandin65@gmail.com','920762266','Av. Venezuela 1897, Breña',NULL),
('CLE040','ventas.accesoriosnortesac13@hotmail.com','919620129','Av. Benavides 4283, Miraflores','CLE029'),
('CLE041','ventas.importacionesmetro15@gmail.com','995828464','Av. Iquitos 4576, La Victoria',NULL),
('CLE042','ventas.autopartessanmarti30@hotmail.com','986623900','Av. Nicolás Ayllón 3769, Ate',NULL),
('CLE043','ventas.suspensionesdelnor56@gmail.com','928639020','Av. Brasil 2539, Jesús María',NULL),
('CLE044','ventas.importacionesmotor18@hotmail.com','961210487','Av. Trapiche 2930, Comas',NULL),
('CLE045','ventas.accesorioslosolivo75@gmail.com','940093011','Av. Túpac Amaru 1418, Comas','CLN017'),
('CLE046','ventas.rodamientosindustr47@hotmail.com','964806566','Av. Grau 2345, Lima',NULL),
('CLE047','ventas.serviciosautomotri93@gmail.com','909349537','Av. Tomás Valle 2500, San Martín de Porres',NULL),
('CLE048','ventas.rodamientossanmart14@hotmail.com','922283277','Av. Túpac Amaru 686, Comas',NULL),
('CLE049','ventas.transmisionesdelpa70@gmail.com','938305288','Av. Alfredo Mendiola 1888, San Martín de Porres',NULL),
('CLE050','ventas.comerciallimasac54@hotmail.com','969539424','Av. Brasil 1552, Jesús María','CLE040'),
('CLE051','ventas.frenospremiumsac12@gmail.com','924039799','Av. Abancay 4382, Lima',NULL),
('CLE052','ventas.autopartesnortesrl77@hotmail.com','918866091','Av. Próceres de Huandoy 4054, Los Olivos',NULL),
('CLE053','ventas.transmisionesperus89@gmail.com','926131060','Av. Aviación 1297, San Borja',NULL),
('CLE054','ventas.comercialcentralsa83@hotmail.com','956463465','Av. Próceres de Huandoy 4409, Los Olivos',NULL),
('CLE055','ventas.lubricanteslimaeir98@gmail.com','996225653','Av. Argentina 1283, Callao','CLN076'),
('CLE056','ventas.serviciosautomotri55@hotmail.com','933055540','Av. Canadá 1793, La Victoria',NULL),
('CLE057','ventas.serviciosautomotri37@gmail.com','947147188','Av. Separadora Industrial 231, Ate',NULL),
('CLE058','ventas.frenosmetropolitan87@hotmail.com','997397623','Av. Primavera 815, Santiago de Surco',NULL),
('CLE059','ventas.comercialdelnortes94@gmail.com','946639304','Av. Próceres de Huandoy 4053, Los Olivos',NULL),
('CLE060','ventas.rodamientoslosoliv88@hotmail.com','998272936','Av. Próceres de Huandoy 329, Los Olivos','CLN032'),
('CLE061','ventas.accesoriospacifico39@gmail.com','933710741','Av. Túpac Amaru 4888, Comas',NULL),
('CLE062','ventas.filtrospacificosrl29@hotmail.com','901805231','Av. Arequipa 4135, Lince',NULL),
('CLE063','ventas.accesoriosmetropol59@gmail.com','974167803','Av. Separadora Industrial 2106, Ate',NULL),
('CLE064','ventas.importacionespremi76@hotmail.com','986143066','Av. Túpac Amaru 4364, Comas',NULL),
('CLE065','ventas.frenossanmartineir49@gmail.com','983347006','Av. Arequipa 4355, Lince','CLN037'),
('CLE066','ventas.rodamientosnortesa76@hotmail.com','909656375','Av. Canadá 3903, La Victoria',NULL),
('CLE067','ventas.lubricanteslosoliv78@gmail.com','964576770','Av. Guardia Civil 228, San Borja',NULL),
('CLE068','ventas.filtrospremiumsac82@hotmail.com','918475641','Av. Colonial 921, Lima',NULL),
('CLE069','ventas.importacionesmetro77@gmail.com','991310528','Av. Trapiche 434, Comas',NULL),
('CLE070','ventas.rodamientoslimasrl47@hotmail.com','925824920','Av. Próceres de Huandoy 350, Los Olivos','CLE003'),
('CLE071','ventas.serviciosautomotri94@gmail.com','936847472','Av. La Molina 401, La Molina',NULL),
('CLE072','ventas.autopartespacifico99@hotmail.com','981780842','Av. Próceres de Huandoy 3026, Los Olivos',NULL),
('CLE073','ventas.frenosindustrialei42@gmail.com','964051625','Av. Aviación 1774, San Borja',NULL),
('CLE074','ventas.autopartesdelpacif63@hotmail.com','938925396','Av. Próceres de Huandoy 3969, Los Olivos',NULL),
('CLE075','ventas.serviciosautomotri66@gmail.com','923379836','Av. Arequipa 3008, Lince','CLN013'),
('CLE076','ventas.accesoriosindustri94@hotmail.com','931677053','Av. Caminos del Inca 1673, Santiago de Surco',NULL),
('CLE077','ventas.repuestospremiumsa20@gmail.com','929416840','Av. México 4540, La Victoria',NULL),
('CLE078','ventas.rodamientospremium75@hotmail.com','989529529','Av. Canadá 4877, La Victoria',NULL),
('CLE079','ventas.transmisionesmetro31@gmail.com','945204394','Av. Naranjal 2953, Los Olivos',NULL),
('CLE080','ventas.frenosdelnortesac58@hotmail.com','964105413','Av. Próceres de Huandoy 879, Los Olivos','CLE019'),
('CLE081','ventas.frenosmotorssac67@gmail.com','956738764','Av. Naranjal 2135, Los Olivos',NULL),
('CLE082','ventas.serviciosautomotri82@hotmail.com','997084457','Av. La Molina 3606, La Molina',NULL),
('CLE083','ventas.serviciosautomotri44@gmail.com','987856387','Av. Alfredo Mendiola 1424, San Martín de Porres',NULL),
('CLE084','ventas.frenosperusac95@hotmail.com','923834690','Av. La Molina 4346, La Molina',NULL),
('CLE085','ventas.serviciosautomotri39@gmail.com','928326780','Av. Nicolás Ayllón 3853, Ate','CLE050'),
('CLE086','ventas.filtrosexpresssrl22@hotmail.com','905481010','Av. Benavides 158, Miraflores',NULL),
('CLE087','ventas.comercialindustria33@gmail.com','972054457','Av. Aviación 970, San Borja',NULL),
('CLE088','ventas.rodamientosperusac38@hotmail.com','996325626','Av. Angélica Gamarra 1943, Los Olivos',NULL),
('CLE089','ventas.distribuidoralosol36@gmail.com','967349647','Av. Separadora Industrial 1096, Ate',NULL),
('CLE090','ventas.suspensionesandina92@hotmail.com','948336257','Av. Nicolás Ayllón 4785, Ate','CLN055'),
('CLE091','ventas.autopartespacifico13@gmail.com','917706489','Av. Venezuela 4075, Breña',NULL),
('CLE092','ventas.frenosdelnorteeirl22@hotmail.com','923188727','Av. Angélica Gamarra 4815, Los Olivos',NULL),
('CLE093','ventas.importacionesexpre46@gmail.com','963327369','Av. La Marina 2594, San Miguel',NULL),
('CLE094','ventas.distribuidorametro75@hotmail.com','980395183','Av. Abancay 3692, Lima',NULL),
('CLE095','ventas.frenosindustrialsr73@gmail.com','957204147','Av. La Molina 3205, La Molina','CLN025'),
('CLE096','ventas.comercialsanmartin12@hotmail.com','922884129','Av. Los Alisos 1740, Los Olivos',NULL),
('CLE097','ventas.transmisionesindus74@gmail.com','916498879','Av. Universitaria 2965, Los Olivos',NULL),
('CLE098','ventas.accesoriospacifico93@hotmail.com','951724001','Av. Naranjal 1698, Los Olivos',NULL),
('CLE099','ventas.motoresdelnortesac46@gmail.com','967712951','Av. Carlos Izaguirre 1762, Los Olivos',NULL),
('CLE100','ventas.autopartesdelpacif35@hotmail.com','910238197','Av. Canadá 1801, La Victoria','CLE052');


INSERT INTO CLIENTE_NATURAL (IdCliente,Nombre,Apellido,DNI) VALUES
('CLN001','Ricardo','Salazar Molina','26900668'),
('CLN002','Diana','Vega Cárdenas','43570050'),
('CLN003','Carlos','Huamán Ortega','24999622'),
('CLN004','Mónica','Reyes Herrera','68211191'),
('CLN005','Víctor','Salazar Chávez','64737065'),
('CLN006','Cynthia','Palacios Medina','63035786'),
('CLN007','Miguel','Rojas Herrera','20107806'),
('CLN008','Andrea','Ortega Huamán','77501933'),
('CLN009','Pedro','Torres Mendoza','25886442'),
('CLN010','Diana','Molina Campos','59002198'),
('CLN011','Ricardo','Castillo Molina','55912266'),
('CLN012','Adriana','Valdivia Molina','12937492'),
('CLN013','Jorge','Salazar Quispe','40380306'),
('CLN014','Andrea','León Rojas','72307693'),
('CLN015','Marco','Soto Vega','49856482'),
('CLN016','Lorena','Cabrera Molina','79138309'),
('CLN017','Víctor','Arias Palacios','36432549'),
('CLN018','Claudia','Espinoza Rojas','67667666'),
('CLN019','César','Huamán Rojas','75057506'),
('CLN020','Diana','Ramírez Molina','67529662'),
('CLN021','Hugo','Navarro Palacios','26228096'),
('CLN022','Fiorella','Tapia Arias','50102773'),
('CLN023','Diego','Ramos Soto','27818484'),
('CLN024','Diana','Rojas Sánchez','13106737'),
('CLN025','José','Herrera Mejía','47293371'),
('CLN026','Rosa','Tapia Lozano','13296552'),
('CLN027','Bruno','Reyes Delgado','24405737'),
('CLN028','Verónica','García Vargas','28338385'),
('CLN029','Eduardo','Arias Molina','66386042'),
('CLN030','Milagros','Ramos Delgado','67956111'),
('CLN031','Andrés','Rojas Molina','41897488'),
('CLN032','Ana','Reyes Arias','56379660'),
('CLN033','Martín','Paredes Castillo','62704635'),
('CLN034','Diana','Ortega Huamán','54265341'),
('CLN035','Renzo','Reyes Campos','34691023'),
('CLN036','Lucía','Vega Chávez','66062618'),
('CLN037','Jorge','León Vargas','73515627'),
('CLN038','Rosa','Paredes Salazar','27497051'),
('CLN039','Jorge','Reyes Palacios','51761970'),
('CLN040','Ana','Espinoza Medina','16838573'),
('CLN041','Luis','Fuentes Flores','62573179'),
('CLN042','Daniela','Espinoza Flores','48629056'),
('CLN043','Marco','Rojas Ramírez','65728413'),
('CLN044','Claudia','Núñez Vargas','79218019'),
('CLN045','Renzo','Quispe Medina','17299742'),
('CLN046','Lorena','Núñez Vega','63134329'),
('CLN047','Andrés','Cruz Sánchez','32858035'),
('CLN048','Fiorella','Rojas Castillo','45170295'),
('CLN049','Álvaro','Ramírez Rojas','57761793'),
('CLN050','Fiorella','Reyes Aguilar','44452031'),
('CLN051','Manuel','Huamán Tapia','13263433'),
('CLN052','Lucía','Huamán Peña','12887400'),
('CLN053','Hugo','Cárdenas Ortega','75816647'),
('CLN054','Verónica','Tapia Cruz','43040239'),
('CLN055','Jorge','Espinoza Herrera','50807551'),
('CLN056','Diana','Tapia Vega','67711085'),
('CLN057','César','Medina Fuentes','40473678'),
('CLN058','Gabriela','Cabrera Lozano','71434447'),
('CLN059','Víctor','Castillo Huamán','78538849'),
('CLN060','Andrea','Cruz Quispe','39778084'),
('CLN061','Martín','Flores Rojas','71703439'),
('CLN062','Claudia','Soto Espinoza','18798033'),
('CLN063','Diego','Paredes Lozano','42749301'),
('CLN064','Claudia','Tapia Salazar','39816678'),
('CLN065','Bruno','Torres Paredes','72166226'),
('CLN066','Lorena','Soto Vega','23839290'),
('CLN067','Andrés','Sánchez Cabrera','25558752'),
('CLN068','Paola','Paredes Peña','61710767'),
('CLN069','Manuel','Arias Vargas','56366133'),
('CLN070','María','Soto Cabrera','19324388'),
('CLN071','Eduardo','Castillo Cabrera','60973075'),
('CLN072','Patricia','Ramos García','71945602'),
('CLN073','Carlos','Quispe Navarro','68777405'),
('CLN074','Alejandra','Navarro Cruz','29223113'),
('CLN075','Andrés','Salazar Molina','19120030'),
('CLN076','Gabriela','Chávez Castillo','38234690'),
('CLN077','Gonzalo','Soto Vega','17013525'),
('CLN078','Verónica','Valdivia Arias','10756912'),
('CLN079','José','Campos Medina','59999967'),
('CLN080','Rosa','Aguilar Salazar','16095337'),
('CLN081','Martín','Molina Ramos','15613992'),
('CLN082','Katherine','Fuentes Valdivia','63777528'),
('CLN083','Miguel','Espinoza Castillo','70763834'),
('CLN084','Milagros','Vargas Molina','13539575'),
('CLN085','José','Aguilar Ortega','37712324'),
('CLN086','Alejandra','Núñez Vargas','58600230'),
('CLN087','Andrés','Ramos Ortega','21560545'),
('CLN088','María','Arias Castillo','23262568'),
('CLN089','Luis','Herrera Huamán','50061742'),
('CLN090','Natalia','Valdivia Arias','78921968'),
('CLN091','Sergio','Sánchez Núñez','36565666'),
('CLN092','Fiorella','Cárdenas Campos','58753029'),
('CLN093','José','Lozano Peña','53367726'),
('CLN094','Verónica','Lozano Ramírez','69458462'),
('CLN095','Marco','Mendoza Campos','27709749'),
('CLN096','Valeria','Cruz Molina','31207929'),
('CLN097','Jorge','Torres Fuentes','34813007'),
('CLN098','Carolina','Quispe Navarro','14829967'),
('CLN099','Álvaro','Núñez Molina','29291867'),
('CLN100','Sofía','Molina Núñez','65243025');


INSERT INTO CLIENTE_EMPRESA (IdCliente,RUC,RazonSocial) VALUES
('CLE001','20887210447','Autopartes Premium SAC'),
('CLE002','20866880221','Suspensiones Lima S.A.C.'),
('CLE003','20952821874','Comercial Andina SAC'),
('CLE004','20202271805','Rodamientos Pacífico S.A.C.'),
('CLE005','20231166077','Importaciones Pacífico S.A.C.'),
('CLE006','20438008862','Autopartes Premium S.A.C.'),
('CLE007','20466607399','Repuestos Express S.A.C.'),
('CLE008','20792586636','Frenos Norte EIRL'),
('CLE009','20855163111','Rodamientos Lima SAC'),
('CLE010','20403897508','Servicios Automotrices Pacífico SRL'),
('CLE011','20826328534','Autopartes Los Olivos EIRL'),
('CLE012','20453059686','Autopartes del Pacífico S.A.C.'),
('CLE013','20251070513','Servicios Automotrices del Pacífico SRL'),
('CLE014','20863599696','Distribuidora Premium SRL'),
('CLE015','20744015015','Transmisiones Metropolitana SAC'),
('CLE016','20301308826','Lubricantes Central SAC'),
('CLE017','20989335520','Rodamientos Lima S.A.C.'),
('CLE018','20329586490','Transmisiones Premium S.A.C.'),
('CLE019','20235645611','Comercial Perú EIRL'),
('CLE020','20273594559','Repuestos del Pacífico EIRL'),
('CLE021','20855018943','Distribuidora Pacífico SRL'),
('CLE022','20587562406','Rodamientos Central S.A.C.'),
('CLE023','20970474863','Servicios Automotrices Norte SRL'),
('CLE024','20372308967','Accesorios del Pacífico S.A.C.'),
('CLE025','20202609075','Frenos Central S.A.C.'),
('CLE026','20450959376','Suspensiones Pacífico S.A.C.'),
('CLE027','20528784616','Motores Motors SAC'),
('CLE028','20191468024','Comercial Industrial SRL'),
('CLE029','20587923344','Servicios Automotrices Premium S.A.C.'),
('CLE030','20358655786','Motores del Norte SAC'),
('CLE031','20928167390','Accesorios San Martín SAC'),
('CLE032','20829337381','Accesorios San Martín S.A.C.'),
('CLE033','20691823173','Suspensiones Los Olivos S.A.C.'),
('CLE034','20605934278','Motores del Pacífico SRL'),
('CLE035','20660406264','Lubricantes Pacífico EIRL'),
('CLE036','20158940575','Transmisiones Pacífico S.A.C.'),
('CLE037','20596334521','Comercial San Martín S.A.C.'),
('CLE038','20677082527','Comercial Andina S.A.C.'),
('CLE039','20413081875','Transmisiones Andina S.A.C.'),
('CLE040','20427501371','Accesorios Norte S.A.C.'),
('CLE041','20375652995','Importaciones Metropolitana S.A.C.'),
('CLE042','20231875680','Autopartes San Martín SAC'),
('CLE043','20418204185','Suspensiones del Norte S.A.C.'),
('CLE044','20308852629','Importaciones Motors S.A.C.'),
('CLE045','20826005956','Accesorios Los Olivos SAC'),
('CLE046','20637814878','Rodamientos Industrial SAC'),
('CLE047','20316181326','Servicios Automotrices del Pacífico S.A.C.'),
('CLE048','20914742022','Rodamientos San Martín SRL'),
('CLE049','20825599658','Transmisiones del Pacífico S.A.C.'),
('CLE050','20843015515','Comercial Lima SAC'),
('CLE051','20451289111','Frenos Premium S.A.C.'),
('CLE052','20662728315','Autopartes Norte SRL'),
('CLE053','20266322471','Transmisiones Perú S.A.C.'),
('CLE054','20803809250','Comercial Central S.A.C.'),
('CLE055','20496794932','Lubricantes Lima EIRL'),
('CLE056','20740879325','Servicios Automotrices Lima S.A.C.'),
('CLE057','20255510356','Servicios Automotrices San Martín EIRL'),
('CLE058','20402445964','Frenos Metropolitana SRL'),
('CLE059','20534781289','Comercial del Norte S.A.C.'),
('CLE060','20122215611','Rodamientos Los Olivos S.A.C.'),
('CLE061','20885655913','Accesorios Pacífico SAC'),
('CLE062','20651965609','Filtros Pacífico SRL'),
('CLE063','20793561831','Accesorios Metropolitana S.A.C.'),
('CLE064','20731632449','Importaciones Premium S.A.C.'),
('CLE065','20891707801','Frenos San Martín EIRL'),
('CLE066','20479754005','Rodamientos Norte S.A.C.'),
('CLE067','20721810390','Lubricantes Los Olivos S.A.C.'),
('CLE068','20901629251','Filtros Premium S.A.C.'),
('CLE069','20802207850','Importaciones Metropolitana EIRL'),
('CLE070','20302076198','Rodamientos Lima SRL'),
('CLE071','20714317572','Servicios Automotrices Metropolitana S.A.C.'),
('CLE072','20854535260','Autopartes Pacífico S.A.C.'),
('CLE073','20546567282','Frenos Industrial EIRL'),
('CLE074','20484248631','Autopartes del Pacífico EIRL'),
('CLE075','20848837599','Servicios Automotrices del Pacífico EIRL'),
('CLE076','20228446239','Accesorios Industrial S.A.C.'),
('CLE077','20974694795','Repuestos Premium S.A.C.'),
('CLE078','20653650346','Rodamientos Premium S.A.C.'),
('CLE079','20417729021','Transmisiones Metropolitana S.A.C.'),
('CLE080','20694293248','Frenos del Norte S.A.C.'),
('CLE081','20659975000','Frenos Motors S.A.C.'),
('CLE082','20974982286','Servicios Automotrices San Martín SAC'),
('CLE083','20852493659','Servicios Automotrices Los Olivos EIRL'),
('CLE084','20949133908','Frenos Perú S.A.C.'),
('CLE085','20418767015','Servicios Automotrices Norte EIRL'),
('CLE086','20804233092','Filtros Express SRL'),
('CLE087','20956592144','Comercial Industrial EIRL'),
('CLE088','20500991136','Rodamientos Perú SAC'),
('CLE089','20600379683','Distribuidora Los Olivos EIRL'),
('CLE090','20906050162','Suspensiones Andina SRL'),
('CLE091','20575552197','Autopartes Pacífico SRL'),
('CLE092','20827724611','Frenos del Norte EIRL'),
('CLE093','20933657893','Importaciones Express S.A.C.'),
('CLE094','20712543168','Distribuidora Metropolitana S.A.C.'),
('CLE095','20382724250','Frenos Industrial SRL'),
('CLE096','20550644372','Comercial San Martín SRL'),
('CLE097','20643312256','Transmisiones Industrial S.A.C.'),
('CLE098','20741103096','Accesorios Pacífico S.A.C.'),
('CLE099','20197642743','Motores del Norte S.A.C.'),
('CLE100','20276031512','Autopartes del Pacífico SAC');


INSERT INTO EMPLEADO (IdEmpleado,Nombre,DNI,Correo,Telefono,Estado,Fecha_Ingreso,Cargo) VALUES
(1,'Jorge Medina Palacios','49486131','jorgemedina837@gmail.com','939234576','Activo','2025-05-28','Almacenero'),
(2,'Mónica Ramos Lozano','24341454','monicaramos633@hotmail.com','962126797','Activo','2023-01-22','Administrador'),
(3,'Hugo Soto Ramos','52740109','hugosoto517@gmail.com','948875513','Activo','2021-09-27','Contador'),
(4,'Mónica Lozano García','48807235','monicalozano567@hotmail.com','900511821','Activo','2024-04-23','Vendedor'),
(5,'Carlos Salazar Torres','44972547','carlossalazar925@gmail.com','985149286','Activo','2025-10-08','Almacenero'),
(6,'Fiorella Vargas Delgado','48731663','fiorellavargas857@hotmail.com','949670885','Activo','2022-12-19','Administrador'),
(7,'José Vega León','24956388','josevega771@gmail.com','985963024','Activo','2021-10-04','Contador'),
(8,'Carolina Cabrera Medina','21322052','carolinacabrera902@hotmail.com','974738715','Activo','2025-06-24','Vendedor'),
(9,'Diego Fuentes Vargas','41357761','diegofuentes327@gmail.com','942885029','Activo','2025-09-19','Almacenero'),
(10,'Ana Flores Herrera','17700833','anaflores274@hotmail.com','937952204','Activo','2023-11-20','Administrador'),
(11,'Sergio Vega Palacios','71039037','sergiovega442@gmail.com','931337736','Activo','2022-01-29','Contador'),
(12,'Verónica Mendoza Vega','55186856','veronicamendoza959@hotmail.com','917641656','Activo','2021-12-10','Vendedor'),
(13,'Martín Paredes Cárdenas','13108612','martinparedes153@gmail.com','953654074','Activo','2025-03-23','Almacenero'),
(14,'Lorena Vargas Salazar','74499029','lorenavargas243@hotmail.com','926650365','Activo','2024-09-29','Administrador'),
(15,'Fernando Sánchez Cruz','11604466','fernandosanchez841@gmail.com','978579128','Activo','2025-08-30','Contador'),
(16,'Claudia Núñez García','36054179','claudianunez733@hotmail.com','957171618','Activo','2022-09-27','Vendedor'),
(17,'Pedro Peña Cabrera','54524439','pedropena312@gmail.com','943729061','Activo','2021-12-29','Almacenero'),
(18,'Adriana Rojas Vargas','54958796','adrianarojas110@hotmail.com','910509083','Activo','2022-08-27','Administrador'),
(19,'Pedro Torres Quispe','60961664','pedrotorres382@gmail.com','927663591','Activo','2023-06-08','Contador'),
(20,'Alejandra Salazar Lozano','13863593','alejandrasalazar471@hotmail.com','975947484','Activo','2024-03-30','Vendedor'),
(21,'Eduardo Campos Salazar','37261440','eduardocampos779@gmail.com','988871556','Activo','2022-07-15','Almacenero'),
(22,'Ana Ramírez Herrera','24923066','anaramirez157@hotmail.com','940168822','Activo','2023-02-14','Administrador'),
(23,'Gonzalo Delgado Sánchez','52253245','gonzalodelgado450@gmail.com','940077178','Activo','2022-07-02','Contador'),
(24,'Adriana García Mendoza','29094125','adrianagarcia812@hotmail.com','969286378','Activo','2024-08-03','Vendedor'),
(25,'Carlos Lozano Medina','32931721','carloslozano230@gmail.com','991078880','Activo','2022-09-29','Almacenero'),
(26,'María León Fuentes','65164324','marialeon832@hotmail.com','999201610','Activo','2022-09-19','Administrador'),
(27,'Eduardo León Reyes','66497508','eduardoleon421@gmail.com','946956156','Activo','2024-07-23','Contador'),
(28,'Verónica Valdivia Tapia','35102646','veronicavaldivia948@hotmail.com','966791400','Activo','2024-02-16','Vendedor'),
(29,'Hugo Quispe Reyes','22676444','hugoquispe131@gmail.com','938624592','Activo','2024-07-20','Almacenero'),
(30,'Alejandra Vargas León','26893521','alejandravargas930@hotmail.com','916782959','Activo','2024-06-27','Administrador'),
(31,'Renzo Navarro Quispe','70217877','renzonavarro130@gmail.com','995020141','Activo','2022-01-12','Contador'),
(32,'Paola García Molina','46751165','paolagarcia449@hotmail.com','978818775','Activo','2023-08-12','Vendedor'),
(33,'Martín Campos Aguilar','48268156','martincampos563@gmail.com','997433948','Activo','2022-04-02','Almacenero'),
(34,'Paola Mendoza Campos','75212496','paolamendoza716@hotmail.com','981620610','Activo','2021-10-24','Administrador'),
(35,'Pedro Mendoza Quispe','26938665','pedromendoza431@gmail.com','918348025','Activo','2024-02-14','Contador'),
(36,'Diana Flores Vargas','60328202','dianaflores858@hotmail.com','901047114','Activo','2024-05-05','Vendedor'),
(37,'César Mendoza Delgado','31391065','cesarmendoza544@gmail.com','969084547','Activo','2025-11-30','Almacenero'),
(38,'Paola Castillo Ramírez','72503950','paolacastillo826@hotmail.com','912743098','Activo','2023-06-27','Administrador'),
(39,'Víctor Torres Sánchez','53796842','victortorres123@gmail.com','900853804','Activo','2022-06-14','Contador'),
(40,'Natalia Palacios Salazar','45256490','nataliapalacios534@hotmail.com','934182527','Activo','2024-07-28','Vendedor'),
(41,'Carlos Mejía Sánchez','16074667','carlosmejia271@gmail.com','900642065','Activo','2023-02-23','Almacenero'),
(42,'Natalia Paredes Sánchez','58136804','nataliaparedes360@hotmail.com','977772690','Activo','2025-10-29','Administrador'),
(43,'Gonzalo Cabrera Núñez','31673046','gonzalocabrera887@gmail.com','928260043','Activo','2023-07-24','Contador'),
(44,'Rosa Torres Salazar','38843624','rosatorres821@hotmail.com','991389062','Activo','2023-10-18','Vendedor'),
(45,'Alonso Castillo Tapia','59088214','alonsocastillo135@gmail.com','919456688','Activo','2025-11-08','Almacenero'),
(46,'Milagros Núñez Medina','32883934','milagrosnunez851@hotmail.com','976319867','Activo','2023-10-09','Administrador'),
(47,'Raúl Ramos Campos','18572891','raulramos613@gmail.com','987719959','Activo','2021-10-01','Contador'),
(48,'Alejandra García Salazar','73464583','alejandragarcia119@hotmail.com','971708158','Activo','2024-04-21','Vendedor'),
(49,'Sergio Delgado Espinoza','78806629','sergiodelgado448@gmail.com','947338907','Activo','2022-01-11','Almacenero'),
(50,'Valeria Molina Palacios','55701762','valeriamolina908@hotmail.com','960266660','Activo','2021-03-02','Administrador'),
(51,'Jorge Paredes Fuentes','48590553','jorgeparedes336@gmail.com','916126510','Activo','2021-10-17','Contador'),
(52,'Adriana Ortega Valdivia','32484389','adrianaortega683@hotmail.com','941818414','Activo','2025-09-02','Vendedor'),
(53,'Jorge Lozano Torres','79245558','jorgelozano168@gmail.com','990086156','Activo','2025-04-13','Almacenero'),
(54,'Natalia Reyes Campos','30465835','nataliareyes650@hotmail.com','929110874','Activo','2024-06-27','Administrador'),
(55,'Martín Chávez Palacios','53699222','martinchavez422@gmail.com','991467344','Activo','2021-06-06','Contador'),
(56,'Gabriela Espinoza Mendoza','17501057','gabrielaespinoza680@hotmail.com','944079217','Activo','2021-12-26','Vendedor'),
(57,'José Ramírez León','15023826','joseramirez243@gmail.com','954997651','Activo','2025-11-22','Almacenero'),
(58,'Lorena Salazar Paredes','19154173','lorenasalazar104@hotmail.com','971372138','Activo','2021-04-06','Administrador'),
(59,'Ricardo Herrera Castillo','23267661','ricardoherrera116@gmail.com','938608955','Activo','2024-11-24','Contador'),
(60,'Patricia Vargas Campos','52193188','patriciavargas764@hotmail.com','913831645','Activo','2021-05-22','Vendedor'),
(61,'Sergio Sánchez Herrera','63305618','sergiosanchez389@gmail.com','988986654','Activo','2025-09-28','Almacenero'),
(62,'Adriana Cárdenas Tapia','78071034','adrianacardenas428@hotmail.com','953196677','Activo','2021-11-27','Administrador'),
(63,'Martín Ramos Aguilar','46977400','martinramos311@gmail.com','996334631','Activo','2025-01-05','Contador'),
(64,'Katherine Valdivia Paredes','36805491','katherinevaldivia850@hotmail.com','983259915','Activo','2024-03-16','Vendedor'),
(65,'Luis Campos Paredes','66745545','luiscampos991@gmail.com','904321614','Activo','2025-05-05','Almacenero'),
(66,'Katherine Lozano Paredes','62022403','katherinelozano915@hotmail.com','921739615','Activo','2022-12-28','Administrador'),
(67,'Andrés Ramírez Mejía','23394327','andresramirez245@gmail.com','914316781','Activo','2021-03-18','Contador'),
(68,'Mónica Núñez Quispe','64216236','monicanunez846@hotmail.com','920086295','Activo','2024-09-12','Vendedor'),
(69,'Andrés Quispe Arias','18433469','andresquispe417@gmail.com','993976284','Activo','2025-11-12','Almacenero'),
(70,'Alejandra Núñez Salazar','67248749','alejandranunez267@hotmail.com','913573175','Activo','2025-07-19','Administrador'),
(71,'Gonzalo Cabrera Herrera','41000562','gonzalocabrera737@gmail.com','998048126','Activo','2023-03-15','Contador'),
(72,'Diana Huamán Quispe','42873932','dianahuaman520@hotmail.com','926595398','Activo','2025-04-16','Vendedor'),
(73,'Eduardo Lozano Vargas','27302831','eduardolozano934@gmail.com','915540112','Activo','2024-09-25','Almacenero'),
(74,'Adriana Cruz Vargas','20429249','adrianacruz292@hotmail.com','916655193','Activo','2022-10-19','Administrador'),
(75,'Eduardo Ortega Campos','69328632','eduardoortega706@gmail.com','914479955','Activo','2024-01-21','Contador'),
(76,'Sofía Paredes Rojas','25936414','sofiaparedes107@hotmail.com','956781691','Activo','2021-11-28','Vendedor'),
(77,'Gonzalo Fuentes Quispe','53051652','gonzalofuentes980@gmail.com','904343570','Activo','2021-01-17','Almacenero'),
(78,'Natalia Núñez Quispe','11870586','natalianunez113@hotmail.com','998287326','Activo','2023-04-14','Administrador'),
(79,'Víctor Ortega Castillo','69885330','victorortega392@gmail.com','913305704','Activo','2023-03-21','Contador'),
(80,'Fiorella Cruz Medina','21347621','fiorellacruz686@hotmail.com','997513707','Activo','2024-11-14','Vendedor'),
(81,'Alonso Soto Paredes','44443547','alonsosoto718@gmail.com','993665064','Activo','2023-12-10','Almacenero'),
(82,'Lorena García Ortega','56556123','lorenagarcia615@hotmail.com','963728692','Activo','2021-02-27','Administrador'),
(83,'Jorge Delgado Paredes','77835948','jorgedelgado556@gmail.com','904305428','Activo','2022-07-18','Contador'),
(84,'Verónica Tapia Arias','34712171','veronicatapia643@hotmail.com','988418895','Activo','2024-06-06','Vendedor'),
(85,'Daniel Torres Delgado','26461685','danieltorres672@gmail.com','998216623','Activo','2023-08-29','Almacenero'),
(86,'Andrea Soto Torres','42328906','andreasoto945@hotmail.com','935271260','Activo','2024-08-11','Administrador'),
(87,'Carlos Vega Valdivia','66851652','carlosvega258@gmail.com','947341583','Activo','2021-06-28','Contador'),
(88,'María Mendoza Herrera','47378122','mariamendoza802@hotmail.com','945052183','Activo','2021-08-11','Vendedor'),
(89,'Fernando Fuentes Ramos','23545421','fernandofuentes724@gmail.com','976700803','Activo','2022-10-11','Almacenero'),
(90,'Diana Navarro Núñez','22967861','diananavarro290@hotmail.com','954713480','Activo','2023-05-05','Administrador'),
(91,'José Ramos Tapia','47161327','joseramos930@gmail.com','913356247','Activo','2023-02-01','Contador'),
(92,'Cynthia Chávez Flores','19782305','cynthiachavez948@hotmail.com','964566066','Activo','2023-01-24','Vendedor'),
(93,'Víctor Mejía Sánchez','62117969','victormejia351@gmail.com','905924992','Activo','2024-12-18','Almacenero'),
(94,'Cynthia Peña Soto','22325625','cynthiapena919@hotmail.com','927957474','Activo','2023-09-29','Administrador'),
(95,'Gonzalo León Peña','29904515','gonzaloleon112@gmail.com','921107553','Activo','2025-02-11','Contador'),
(96,'Lorena Tapia Mendoza','28992631','lorenatapia630@hotmail.com','951074843','Activo','2022-06-12','Vendedor'),
(97,'Diego Núñez Delgado','29253194','diegonunez248@gmail.com','979698063','Activo','2022-04-20','Almacenero'),
(98,'Gabriela Vega Núñez','71008239','gabrielavega882@hotmail.com','922628898','Activo','2021-11-11','Administrador'),
(99,'Eduardo Soto Sánchez','25776088','eduardosoto372@gmail.com','936512169','Activo','2025-07-23','Contador'),
(100,'Gabriela Soto Torres','73332050','gabrielasoto441@hotmail.com','905675746','Activo','2022-04-08','Vendedor');


INSERT INTO CATEGORIA (IdCategoria,Nombre,Descripcion) VALUES
(1,'Filtro de aceite','Repuestos y componentes de la línea filtro de aceite.'),
(2,'Filtro de aire','Repuestos y componentes de la línea filtro de aire.'),
(3,'Filtro de combustible','Repuestos y componentes de la línea filtro de combustible.'),
(4,'Filtro de cabina','Repuestos y componentes de la línea filtro de cabina.'),
(5,'Pastillas de freno','Repuestos y componentes de la línea pastillas de freno.'),
(6,'Disco de freno','Repuestos y componentes de la línea disco de freno.'),
(7,'Zapatas de freno','Repuestos y componentes de la línea zapatas de freno.'),
(8,'Líquido de frenos','Repuestos y componentes de la línea líquido de frenos.'),
(9,'Cáliper','Repuestos y componentes de la línea cáliper.'),
(10,'Bujía','Repuestos y componentes de la línea bujía.'),
(11,'Bobina de encendido','Repuestos y componentes de la línea bobina de encendido.'),
(12,'Cable de bujía','Repuestos y componentes de la línea cable de bujía.'),
(13,'Sensor de oxígeno','Repuestos y componentes de la línea sensor de oxígeno.'),
(14,'Sensor MAP','Repuestos y componentes de la línea sensor map.'),
(15,'Sensor MAF','Repuestos y componentes de la línea sensor maf.'),
(16,'Sensor CKP','Repuestos y componentes de la línea sensor ckp.'),
(17,'Sensor CMP','Repuestos y componentes de la línea sensor cmp.'),
(18,'Correa de distribución','Repuestos y componentes de la línea correa de distribución.'),
(19,'Correa auxiliar','Repuestos y componentes de la línea correa auxiliar.'),
(20,'Tensor de correa','Repuestos y componentes de la línea tensor de correa.'),
(21,'Polea tensora','Repuestos y componentes de la línea polea tensora.'),
(22,'Bomba de agua','Repuestos y componentes de la línea bomba de agua.'),
(23,'Radiador','Repuestos y componentes de la línea radiador.'),
(24,'Termostato','Repuestos y componentes de la línea termostato.'),
(25,'Manguera de radiador','Repuestos y componentes de la línea manguera de radiador.'),
(26,'Refrigerante','Repuestos y componentes de la línea refrigerante.'),
(27,'Electroventilador','Repuestos y componentes de la línea electroventilador.'),
(28,'Alternador','Repuestos y componentes de la línea alternador.'),
(29,'Motor de arranque','Repuestos y componentes de la línea motor de arranque.'),
(30,'Batería','Repuestos y componentes de la línea batería.'),
(31,'Fusible','Repuestos y componentes de la línea fusible.'),
(32,'Relé','Repuestos y componentes de la línea relé.'),
(33,'Faro delantero','Repuestos y componentes de la línea faro delantero.'),
(34,'Faro posterior','Repuestos y componentes de la línea faro posterior.'),
(35,'Bombilla halógena','Repuestos y componentes de la línea bombilla halógena.'),
(36,'Amortiguador delantero','Repuestos y componentes de la línea amortiguador delantero.'),
(37,'Amortiguador posterior','Repuestos y componentes de la línea amortiguador posterior.'),
(38,'Resorte helicoidal','Repuestos y componentes de la línea resorte helicoidal.'),
(39,'Buje de suspensión','Repuestos y componentes de la línea buje de suspensión.'),
(40,'Rótula','Repuestos y componentes de la línea rótula.'),
(41,'Terminal de dirección','Repuestos y componentes de la línea terminal de dirección.'),
(42,'Barra estabilizadora','Repuestos y componentes de la línea barra estabilizadora.'),
(43,'Brazo de suspensión','Repuestos y componentes de la línea brazo de suspensión.'),
(44,'Rodamiento de rueda','Repuestos y componentes de la línea rodamiento de rueda.'),
(45,'Maza de rueda','Repuestos y componentes de la línea maza de rueda.'),
(46,'Junta homocinética','Repuestos y componentes de la línea junta homocinética.'),
(47,'Semieje','Repuestos y componentes de la línea semieje.'),
(48,'Kit de embrague','Repuestos y componentes de la línea kit de embrague.'),
(49,'Disco de embrague','Repuestos y componentes de la línea disco de embrague.'),
(50,'Prensa de embrague','Repuestos y componentes de la línea prensa de embrague.'),
(51,'Collarín de embrague','Repuestos y componentes de la línea collarín de embrague.'),
(52,'Bomba de embrague','Repuestos y componentes de la línea bomba de embrague.'),
(53,'Aceite de motor','Repuestos y componentes de la línea aceite de motor.'),
(54,'Aceite de transmisión','Repuestos y componentes de la línea aceite de transmisión.'),
(55,'Filtro de transmisión','Repuestos y componentes de la línea filtro de transmisión.'),
(56,'Junta de culata','Repuestos y componentes de la línea junta de culata.'),
(57,'Retén de cigüeñal','Repuestos y componentes de la línea retén de cigüeñal.'),
(58,'Pistón','Repuestos y componentes de la línea pistón.'),
(59,'Anillo de pistón','Repuestos y componentes de la línea anillo de pistón.'),
(60,'Válvula de admisión','Repuestos y componentes de la línea válvula de admisión.'),
(61,'Guía de válvula','Repuestos y componentes de la línea guía de válvula.'),
(62,'Bomba de aceite','Repuestos y componentes de la línea bomba de aceite.'),
(63,'Cárter','Repuestos y componentes de la línea cárter.'),
(64,'Soporte de motor','Repuestos y componentes de la línea soporte de motor.'),
(65,'Silenciador','Repuestos y componentes de la línea silenciador.'),
(66,'Catalizador','Repuestos y componentes de la línea catalizador.'),
(67,'Tubo de escape','Repuestos y componentes de la línea tubo de escape.'),
(68,'Empaque de escape','Repuestos y componentes de la línea empaque de escape.'),
(69,'Inyector','Repuestos y componentes de la línea inyector.'),
(70,'Bomba de combustible','Repuestos y componentes de la línea bomba de combustible.'),
(71,'Regulador de presión','Repuestos y componentes de la línea regulador de presión.'),
(72,'Cuerpo de aceleración','Repuestos y componentes de la línea cuerpo de aceleración.'),
(73,'Sensor TPS','Repuestos y componentes de la línea sensor tps.'),
(74,'Plumilla limpiaparabrisas','Repuestos y componentes de la línea plumilla limpiaparabrisas.'),
(75,'Motor limpiaparabrisas','Repuestos y componentes de la línea motor limpiaparabrisas.'),
(76,'Depósito limpiaparabrisas','Repuestos y componentes de la línea depósito limpiaparabrisas.'),
(77,'Espejo lateral','Repuestos y componentes de la línea espejo lateral.'),
(78,'Manija de puerta','Repuestos y componentes de la línea manija de puerta.'),
(79,'Cerradura de puerta','Repuestos y componentes de la línea cerradura de puerta.'),
(80,'Elevavidrio','Repuestos y componentes de la línea elevavidrio.'),
(81,'Parachoques','Repuestos y componentes de la línea parachoques.'),
(82,'Guardafango','Repuestos y componentes de la línea guardafango.'),
(83,'Capó','Repuestos y componentes de la línea capó.'),
(84,'Parrilla frontal','Repuestos y componentes de la línea parrilla frontal.'),
(85,'Neumático','Repuestos y componentes de la línea neumático.'),
(86,'Válvula de neumático','Repuestos y componentes de la línea válvula de neumático.'),
(87,'Sensor TPMS','Repuestos y componentes de la línea sensor tpms.'),
(88,'Aro de rueda','Repuestos y componentes de la línea aro de rueda.'),
(89,'Tapacubo','Repuestos y componentes de la línea tapacubo.'),
(90,'Bomba de dirección','Repuestos y componentes de la línea bomba de dirección.'),
(91,'Cremallera de dirección','Repuestos y componentes de la línea cremallera de dirección.'),
(92,'Manguera hidráulica','Repuestos y componentes de la línea manguera hidráulica.'),
(93,'Compresor A/C','Repuestos y componentes de la línea compresor a/c.'),
(94,'Condensador A/C','Repuestos y componentes de la línea condensador a/c.'),
(95,'Evaporador A/C','Repuestos y componentes de la línea evaporador a/c.'),
(96,'Filtro secador','Repuestos y componentes de la línea filtro secador.'),
(97,'Correa A/C','Repuestos y componentes de la línea correa a/c.'),
(98,'Soporte de caja','Repuestos y componentes de la línea soporte de caja.'),
(99,'Sensor ABS','Repuestos y componentes de la línea sensor abs.'),
(100,'Pastilla de freno cerámica','Repuestos y componentes de la línea pastilla de freno cerámica.');


INSERT INTO MARCA_VEHICULO (IdMarcaVehiculo,NombreMarca) VALUES
(1,'Toyota'),
(2,'Nissan'),
(3,'Honda'),
(4,'Hyundai'),
(5,'Kia'),
(6,'Chevrolet'),
(7,'Ford'),
(8,'Volkswagen'),
(9,'Mazda'),
(10,'Subaru'),
(11,'Mitsubishi'),
(12,'Suzuki'),
(13,'Renault'),
(14,'Peugeot'),
(15,'Citroën'),
(16,'Fiat'),
(17,'Jeep'),
(18,'Ram'),
(19,'Dodge'),
(20,'Chrysler'),
(21,'Mercedes-Benz'),
(22,'BMW'),
(23,'Audi'),
(24,'Volvo'),
(25,'Lexus'),
(26,'Infiniti'),
(27,'Acura'),
(28,'Porsche'),
(29,'Land Rover'),
(30,'Jaguar'),
(31,'Mini'),
(32,'Seat'),
(33,'Skoda'),
(34,'Opel'),
(35,'GMC'),
(36,'Cadillac'),
(37,'Buick'),
(38,'Lincoln'),
(39,'Genesis'),
(40,'Tesla'),
(41,'BYD'),
(42,'Geely'),
(43,'Chery'),
(44,'JAC'),
(45,'Great Wall'),
(46,'Haval'),
(47,'MG'),
(48,'Dongfeng'),
(49,'FAW'),
(50,'Changan'),
(51,'Isuzu'),
(52,'SsangYong'),
(53,'Mahindra'),
(54,'Tata'),
(55,'Daewoo'),
(56,'Daihatsu'),
(57,'Pontiac'),
(58,'Oldsmobile'),
(59,'Saab'),
(60,'Alfa Romeo'),
(61,'Maserati'),
(62,'Ferrari'),
(63,'Lamborghini'),
(64,'Bentley'),
(65,'Rolls-Royce'),
(66,'Aston Martin'),
(67,'McLaren'),
(68,'Lotus'),
(69,'Bugatti'),
(70,'Maybach'),
(71,'Scion'),
(72,'Rivian'),
(73,'Lucid'),
(74,'Polestar'),
(75,'Nio'),
(76,'XPeng'),
(77,'Zeekr'),
(78,'Lynk & Co'),
(79,'Proton'),
(80,'Perodua'),
(81,'Holden'),
(82,'Mercury'),
(83,'Saturn'),
(84,'Hummer'),
(85,'Smart'),
(86,'Lancia'),
(87,'Abarth'),
(88,'Cupra'),
(89,'Dacia'),
(90,'DS Automobiles'),
(91,'Foton'),
(92,'BAIC'),
(93,'Jetour'),
(94,'Exeed'),
(95,'Omoda'),
(96,'Jaecoo'),
(97,'Maxus'),
(98,'Dongfeng Forthing'),
(99,'Hongqi'),
(100,'GAC');


INSERT INTO MODELO_VEHICULO (IdModeloVehiculo,NombreModelo,IdMarcaVehiculo) VALUES
(1,'Corolla',1),
(2,'Yaris',1),
(3,'Hilux',1),
(4,'RAV4',1),
(5,'Fortuner',1),
(6,'Sentra',2),
(7,'Versa',2),
(8,'Frontier',2),
(9,'X-Trail',2),
(10,'Kicks',2),
(11,'Civic',3),
(12,'Accord',3),
(13,'CR-V',3),
(14,'HR-V',3),
(15,'Fit',3),
(16,'Accent',4),
(17,'Elantra',4),
(18,'Tucson',4),
(19,'Santa Fe',4),
(20,'Creta',4),
(21,'Rio',5),
(22,'Cerato',5),
(23,'Sportage',5),
(24,'Sorento',5),
(25,'Seltos',5),
(26,'Sail',6),
(27,'Onix',6),
(28,'Tracker',6),
(29,'Captiva',6),
(30,'Colorado',6),
(31,'Fiesta',7),
(32,'Focus',7),
(33,'Ranger',7),
(34,'Escape',7),
(35,'Explorer',7),
(36,'Gol',8),
(37,'Polo',8),
(38,'Jetta',8),
(39,'Tiguan',8),
(40,'Amarok',8),
(41,'Mazda2',9),
(42,'Mazda3',9),
(43,'CX-3',9),
(44,'CX-5',9),
(45,'BT-50',9),
(46,'Impreza',10),
(47,'Forester',10),
(48,'Outback',10),
(49,'XV',10),
(50,'WRX',10),
(51,'Lancer',11),
(52,'Outlander',11),
(53,'ASX',11),
(54,'Montero Sport',11),
(55,'L200',11),
(56,'Swift',12),
(57,'Vitara',12),
(58,'Jimny',12),
(59,'S-Cross',12),
(60,'Ertiga',12),
(61,'Logan',13),
(62,'Sandero',13),
(63,'Duster',13),
(64,'Koleos',13),
(65,'Captur',13),
(66,'208',14),
(67,'301',14),
(68,'2008',14),
(69,'3008',14),
(70,'Partner',14),
(71,'C3',15),
(72,'C4 Cactus',15),
(73,'C-Elysée',15),
(74,'Berlingo',15),
(75,'C5 Aircross',15),
(76,'Uno',16),
(77,'Palio',16),
(78,'Strada',16),
(79,'Toro',16),
(80,'500',16),
(81,'Renegade',17),
(82,'Compass',17),
(83,'Wrangler',17),
(84,'Cherokee',17),
(85,'Grand Cherokee',17),
(86,'C-Class',21),
(87,'E-Class',21),
(88,'3 Series',22),
(89,'X3',22),
(90,'A3',23),
(91,'Q5',23),
(92,'XC40',24),
(93,'XC60',24),
(94,'NX',25),
(95,'RX',25),
(96,'Range Rover Evoque',29),
(97,'Macan',28),
(98,'Model 3',40),
(99,'Dolphin',41),
(100,'Tiggo 7',43);


INSERT INTO PRODUCTO (IdProducto,Nombre,Marca,Modelo,Precio,Stock,Ubicacion,Especificaciones,IdCategoria) VALUES
('PR001','Filtro de aceite','Bosch',NULL,28.7,4,'Pasillo 6, estante A-14','Filtro de aceite Bosch; uso automotriz; presentación estándar de catálogo.',1),
('PR002','Filtro de aire','Denso',NULL,42.4,124,'Pasillo 1, estante A-09','Filtro de aire Denso; uso automotriz; presentación estándar de catálogo.',2),
('PR003','Filtro de combustible','NGK',NULL,56.1,48,'Pasillo 5, estante E-19','Filtro de combustible NGK; uso automotriz; presentación estándar de catálogo.',3),
('PR004','Filtro de cabina','Brembo','RAV4',69.8,138,'Pasillo 6, estante A-10','Filtro de cabina Brembo; uso automotriz; presentación estándar de catálogo.',4),
('PR005','Pastillas de freno','Monroe',NULL,83.5,3,'Pasillo 4, estante A-12','Pastillas de freno Monroe; uso automotriz; presentación estándar de catálogo.',5),
('PR006','Disco de freno','Gates',NULL,97.2,30,'Pasillo 8, estante A-02','Disco de freno Gates; uso automotriz; presentación estándar de catálogo.',6),
('PR007','Zapatas de freno','Aisin',NULL,110.9,116,'Pasillo 7, estante C-04','Zapatas de freno Aisin; uso automotriz; presentación estándar de catálogo.',7),
('PR008','Líquido de frenos','SKF','Frontier',124.6,80,'Pasillo 5, estante B-09','Líquido de frenos SKF; uso automotriz; presentación estándar de catálogo.',8),
('PR009','Cáliper','Hella',NULL,138.3,37,'Pasillo 1, estante E-16','Cáliper Hella; uso automotriz; presentación estándar de catálogo.',9),
('PR010','Bujía','MANN-FILTER',NULL,152.0,107,'Pasillo 1, estante C-08','Bujía MANN-FILTER; uso automotriz; presentación estándar de catálogo.',10),
('PR011','Bobina de encendido','Mahle',NULL,165.7,124,'Pasillo 2, estante C-06','Bobina de encendido Mahle; uso automotriz; presentación estándar de catálogo.',11),
('PR012','Cable de bujía','Sachs','Accord',179.4,130,'Pasillo 5, estante C-19','Cable de bujía Sachs; uso automotriz; presentación estándar de catálogo.',12),
('PR013','Sensor de oxígeno','Valeo',NULL,193.1,57,'Pasillo 6, estante E-02','Sensor de oxígeno Valeo; uso automotriz; presentación estándar de catálogo.',13),
('PR014','Sensor MAP','TRW',NULL,206.8,133,'Pasillo 7, estante B-05','Sensor MAP TRW; uso automotriz; presentación estándar de catálogo.',14),
('PR015','Sensor MAF','KYB',NULL,220.5,5,'Pasillo 4, estante B-13','Sensor MAF KYB; uso automotriz; presentación estándar de catálogo.',15),
('PR016','Sensor CKP','Delphi','Accent',234.2,135,'Pasillo 4, estante A-08','Sensor CKP Delphi; uso automotriz; presentación estándar de catálogo.',16),
('PR017','Sensor CMP','Continental',NULL,247.9,32,'Pasillo 8, estante A-03','Sensor CMP Continental; uso automotriz; presentación estándar de catálogo.',17),
('PR018','Correa de distribución','Dayco',NULL,261.6,127,'Pasillo 1, estante B-11','Correa de distribución Dayco; uso automotriz; presentación estándar de catálogo.',18),
('PR019','Correa auxiliar','Febi Bilstein',NULL,275.3,85,'Pasillo 5, estante C-17','Correa auxiliar Febi Bilstein; uso automotriz; presentación estándar de catálogo.',19),
('PR020','Tensor de correa','Mobil','Creta',289.0,89,'Pasillo 2, estante E-03','Tensor de correa Mobil; uso automotriz; presentación estándar de catálogo.',20),
('PR021','Polea tensora','Castrol',NULL,302.7,51,'Pasillo 3, estante D-01','Polea tensora Castrol; uso automotriz; presentación estándar de catálogo.',21),
('PR022','Bomba de agua','Shell',NULL,316.4,140,'Pasillo 5, estante D-19','Bomba de agua Shell; uso automotriz; presentación estándar de catálogo.',22),
('PR023','Radiador','Motul',NULL,330.1,2,'Pasillo 2, estante A-10','Radiador Motul; uso automotriz; presentación estándar de catálogo.',23),
('PR024','Termostato','TotalEnergies','Sorento',343.8,29,'Pasillo 1, estante B-09','Termostato TotalEnergies; uso automotriz; presentación estándar de catálogo.',24),
('PR025','Manguera de radiador','ACDelco',NULL,357.5,64,'Pasillo 2, estante C-16','Manguera de radiador ACDelco; uso automotriz; presentación estándar de catálogo.',25),
('PR026','Refrigerante','Bosch',NULL,371.2,134,'Pasillo 3, estante D-05','Refrigerante Bosch; uso automotriz; presentación estándar de catálogo.',26),
('PR027','Electroventilador','Denso',NULL,384.9,1,'Pasillo 6, estante E-15','Electroventilador Denso; uso automotriz; presentación estándar de catálogo.',27),
('PR028','Alternador','NGK','Tracker',398.6,143,'Pasillo 8, estante D-03','Alternador NGK; uso automotriz; presentación estándar de catálogo.',28),
('PR029','Motor de arranque','Brembo',NULL,412.3,53,'Pasillo 1, estante B-10','Motor de arranque Brembo; uso automotriz; presentación estándar de catálogo.',29),
('PR030','Batería','Monroe',NULL,426.0,142,'Pasillo 1, estante E-12','Batería Monroe; uso automotriz; presentación estándar de catálogo.',30),
('PR031','Fusible','Gates',NULL,439.7,78,'Pasillo 3, estante B-03','Fusible Gates; uso automotriz; presentación estándar de catálogo.',31),
('PR032','Relé','Aisin','Focus',453.4,67,'Pasillo 4, estante E-18','Relé Aisin; uso automotriz; presentación estándar de catálogo.',32),
('PR033','Faro delantero','SKF',NULL,467.1,117,'Pasillo 7, estante D-12','Faro delantero SKF; uso automotriz; presentación estándar de catálogo.',33),
('PR034','Faro posterior','Hella',NULL,480.8,89,'Pasillo 2, estante B-05','Faro posterior Hella; uso automotriz; presentación estándar de catálogo.',34),
('PR035','Bombilla halógena','MANN-FILTER',NULL,494.5,35,'Pasillo 4, estante D-07','Bombilla halógena MANN-FILTER; uso automotriz; presentación estándar de catálogo.',35),
('PR036','Amortiguador delantero','Mahle','Gol',508.2,39,'Pasillo 2, estante D-06','Amortiguador delantero Mahle; uso automotriz; presentación estándar de catálogo.',36),
('PR037','Amortiguador posterior','Sachs',NULL,521.9,102,'Pasillo 3, estante A-07','Amortiguador posterior Sachs; uso automotriz; presentación estándar de catálogo.',37),
('PR038','Resorte helicoidal','Valeo',NULL,15.6,101,'Pasillo 6, estante B-06','Resorte helicoidal Valeo; uso automotriz; presentación estándar de catálogo.',38),
('PR039','Buje de suspensión','TRW',NULL,29.3,103,'Pasillo 1, estante A-12','Buje de suspensión TRW; uso automotriz; presentación estándar de catálogo.',39),
('PR040','Rótula','KYB','Amarok',43.0,129,'Pasillo 3, estante A-06','Rótula KYB; uso automotriz; presentación estándar de catálogo.',40),
('PR041','Terminal de dirección','Delphi',NULL,56.7,94,'Pasillo 3, estante A-05','Terminal de dirección Delphi; uso automotriz; presentación estándar de catálogo.',41),
('PR042','Barra estabilizadora','Continental',NULL,70.4,137,'Pasillo 8, estante C-17','Barra estabilizadora Continental; uso automotriz; presentación estándar de catálogo.',42),
('PR043','Brazo de suspensión','Dayco',NULL,84.1,24,'Pasillo 6, estante A-02','Brazo de suspensión Dayco; uso automotriz; presentación estándar de catálogo.',43),
('PR044','Rodamiento de rueda','Febi Bilstein','CX-5',97.8,141,'Pasillo 7, estante E-17','Rodamiento de rueda Febi Bilstein; uso automotriz; presentación estándar de catálogo.',44),
('PR045','Maza de rueda','Mobil',NULL,111.5,73,'Pasillo 8, estante E-01','Maza de rueda Mobil; uso automotriz; presentación estándar de catálogo.',45),
('PR046','Junta homocinética','Castrol',NULL,125.2,30,'Pasillo 1, estante B-07','Junta homocinética Castrol; uso automotriz; presentación estándar de catálogo.',46),
('PR047','Semieje','Shell',NULL,138.9,30,'Pasillo 2, estante D-18','Semieje Shell; uso automotriz; presentación estándar de catálogo.',47),
('PR048','Kit de embrague','Motul','Outback',152.6,73,'Pasillo 4, estante C-12','Kit de embrague Motul; uso automotriz; presentación estándar de catálogo.',48),
('PR049','Disco de embrague','TotalEnergies',NULL,166.3,119,'Pasillo 5, estante C-09','Disco de embrague TotalEnergies; uso automotriz; presentación estándar de catálogo.',49),
('PR050','Prensa de embrague','ACDelco',NULL,180.0,25,'Pasillo 8, estante B-13','Prensa de embrague ACDelco; uso automotriz; presentación estándar de catálogo.',50),
('PR051','Collarín de embrague','Bosch',NULL,193.7,102,'Pasillo 1, estante C-11','Collarín de embrague Bosch; uso automotriz; presentación estándar de catálogo.',51),
('PR052','Bomba de embrague','Denso','Outlander',207.4,91,'Pasillo 8, estante C-07','Bomba de embrague Denso; uso automotriz; presentación estándar de catálogo.',52),
('PR053','Aceite de motor','NGK',NULL,221.1,118,'Pasillo 5, estante D-04','Aceite de motor NGK; uso automotriz; presentación estándar de catálogo.',53),
('PR054','Aceite de transmisión','Brembo',NULL,234.8,115,'Pasillo 4, estante E-12','Aceite de transmisión Brembo; uso automotriz; presentación estándar de catálogo.',54),
('PR055','Filtro de transmisión','Monroe',NULL,248.5,108,'Pasillo 8, estante A-08','Filtro de transmisión Monroe; uso automotriz; presentación estándar de catálogo.',55),
('PR056','Junta de culata','Gates','Swift',262.2,143,'Pasillo 8, estante E-12','Junta de culata Gates; uso automotriz; presentación estándar de catálogo.',56),
('PR057','Retén de cigüeñal','Aisin',NULL,275.9,63,'Pasillo 3, estante B-05','Retén de cigüeñal Aisin; uso automotriz; presentación estándar de catálogo.',57),
('PR058','Pistón','SKF',NULL,289.6,111,'Pasillo 3, estante E-10','Pistón SKF; uso automotriz; presentación estándar de catálogo.',58),
('PR059','Anillo de pistón','Hella',NULL,303.3,86,'Pasillo 2, estante A-20','Anillo de pistón Hella; uso automotriz; presentación estándar de catálogo.',59),
('PR060','Válvula de admisión','MANN-FILTER','Ertiga',317.0,53,'Pasillo 1, estante A-02','Válvula de admisión MANN-FILTER; uso automotriz; presentación estándar de catálogo.',60),
('PR061','Guía de válvula','Mahle',NULL,330.7,31,'Pasillo 3, estante D-01','Guía de válvula Mahle; uso automotriz; presentación estándar de catálogo.',61),
('PR062','Bomba de aceite','Sachs',NULL,344.4,86,'Pasillo 1, estante D-08','Bomba de aceite Sachs; uso automotriz; presentación estándar de catálogo.',62),
('PR063','Cárter','Valeo',NULL,358.1,21,'Pasillo 6, estante E-02','Cárter Valeo; uso automotriz; presentación estándar de catálogo.',63),
('PR064','Soporte de motor','TRW','Koleos',371.8,48,'Pasillo 2, estante E-13','Soporte de motor TRW; uso automotriz; presentación estándar de catálogo.',64),
('PR065','Silenciador','KYB',NULL,385.5,102,'Pasillo 5, estante B-10','Silenciador KYB; uso automotriz; presentación estándar de catálogo.',65),
('PR066','Catalizador','Delphi',NULL,399.2,134,'Pasillo 2, estante C-11','Catalizador Delphi; uso automotriz; presentación estándar de catálogo.',66),
('PR067','Tubo de escape','Continental',NULL,412.9,136,'Pasillo 7, estante C-07','Tubo de escape Continental; uso automotriz; presentación estándar de catálogo.',67),
('PR068','Empaque de escape','Dayco','2008',426.6,28,'Pasillo 6, estante E-01','Empaque de escape Dayco; uso automotriz; presentación estándar de catálogo.',68),
('PR069','Inyector','Febi Bilstein',NULL,440.3,32,'Pasillo 5, estante B-17','Inyector Febi Bilstein; uso automotriz; presentación estándar de catálogo.',69),
('PR070','Bomba de combustible','Mobil',NULL,454.0,52,'Pasillo 6, estante B-04','Bomba de combustible Mobil; uso automotriz; presentación estándar de catálogo.',70),
('PR071','Regulador de presión','Castrol',NULL,467.7,60,'Pasillo 8, estante B-13','Regulador de presión Castrol; uso automotriz; presentación estándar de catálogo.',71),
('PR072','Cuerpo de aceleración','Shell','C4 Cactus',481.4,34,'Pasillo 1, estante B-04','Cuerpo de aceleración Shell; uso automotriz; presentación estándar de catálogo.',72),
('PR073','Sensor TPS','Motul',NULL,495.1,40,'Pasillo 1, estante E-08','Sensor TPS Motul; uso automotriz; presentación estándar de catálogo.',73),
('PR074','Plumilla limpiaparabrisas','TotalEnergies',NULL,508.8,31,'Pasillo 3, estante D-10','Plumilla limpiaparabrisas TotalEnergies; uso automotriz; presentación estándar de catálogo.',74),
('PR075','Motor limpiaparabrisas','ACDelco',NULL,522.5,106,'Pasillo 4, estante B-12','Motor limpiaparabrisas ACDelco; uso automotriz; presentación estándar de catálogo.',75),
('PR076','Depósito limpiaparabrisas','Bosch','Uno',16.2,145,'Pasillo 8, estante D-16','Depósito limpiaparabrisas Bosch; uso automotriz; presentación estándar de catálogo.',76),
('PR077','Espejo lateral','Denso',NULL,29.9,52,'Pasillo 8, estante B-11','Espejo lateral Denso; uso automotriz; presentación estándar de catálogo.',77),
('PR078','Manija de puerta','NGK',NULL,43.6,18,'Pasillo 8, estante C-08','Manija de puerta NGK; uso automotriz; presentación estándar de catálogo.',78),
('PR079','Cerradura de puerta','Brembo',NULL,57.3,112,'Pasillo 7, estante C-17','Cerradura de puerta Brembo; uso automotriz; presentación estándar de catálogo.',79),
('PR080','Elevavidrio','Monroe','500',71.0,32,'Pasillo 8, estante E-07','Elevavidrio Monroe; uso automotriz; presentación estándar de catálogo.',80),
('PR081','Parachoques','Gates',NULL,84.7,38,'Pasillo 1, estante E-07','Parachoques Gates; uso automotriz; presentación estándar de catálogo.',81),
('PR082','Guardafango','Aisin',NULL,98.4,68,'Pasillo 7, estante B-20','Guardafango Aisin; uso automotriz; presentación estándar de catálogo.',82),
('PR083','Capó','SKF',NULL,112.1,17,'Pasillo 3, estante E-03','Capó SKF; uso automotriz; presentación estándar de catálogo.',83),
('PR084','Parrilla frontal','Hella','Cherokee',125.8,30,'Pasillo 3, estante B-16','Parrilla frontal Hella; uso automotriz; presentación estándar de catálogo.',84),
('PR085','Neumático','MANN-FILTER',NULL,139.5,115,'Pasillo 3, estante D-03','Neumático MANN-FILTER; uso automotriz; presentación estándar de catálogo.',85),
('PR086','Válvula de neumático','Mahle',NULL,153.2,35,'Pasillo 3, estante C-11','Válvula de neumático Mahle; uso automotriz; presentación estándar de catálogo.',86),
('PR087','Sensor TPMS','Sachs',NULL,166.9,33,'Pasillo 1, estante A-16','Sensor TPMS Sachs; uso automotriz; presentación estándar de catálogo.',87),
('PR088','Aro de rueda','Valeo','3 Series',180.6,120,'Pasillo 2, estante B-12','Aro de rueda Valeo; uso automotriz; presentación estándar de catálogo.',88),
('PR089','Tapacubo','TRW',NULL,194.3,127,'Pasillo 3, estante D-03','Tapacubo TRW; uso automotriz; presentación estándar de catálogo.',89),
('PR090','Bomba de dirección','KYB',NULL,208.0,27,'Pasillo 4, estante E-09','Bomba de dirección KYB; uso automotriz; presentación estándar de catálogo.',90),
('PR091','Cremallera de dirección','Delphi',NULL,221.7,122,'Pasillo 8, estante C-08','Cremallera de dirección Delphi; uso automotriz; presentación estándar de catálogo.',91),
('PR092','Manguera hidráulica','Continental','XC40',235.4,14,'Pasillo 5, estante E-13','Manguera hidráulica Continental; uso automotriz; presentación estándar de catálogo.',92),
('PR093','Compresor A/C','Dayco',NULL,249.1,86,'Pasillo 2, estante D-18','Compresor A/C Dayco; uso automotriz; presentación estándar de catálogo.',93),
('PR094','Condensador A/C','Febi Bilstein',NULL,262.8,105,'Pasillo 2, estante B-04','Condensador A/C Febi Bilstein; uso automotriz; presentación estándar de catálogo.',94),
('PR095','Evaporador A/C','Mobil',NULL,276.5,67,'Pasillo 2, estante D-01','Evaporador A/C Mobil; uso automotriz; presentación estándar de catálogo.',95),
('PR096','Filtro secador','Castrol','Range Rover Evoque',290.2,132,'Pasillo 2, estante C-05','Filtro secador Castrol; uso automotriz; presentación estándar de catálogo.',96),
('PR097','Correa A/C','Shell',NULL,303.9,65,'Pasillo 4, estante C-11','Correa A/C Shell; uso automotriz; presentación estándar de catálogo.',97),
('PR098','Soporte de caja','Motul',NULL,317.6,28,'Pasillo 4, estante A-19','Soporte de caja Motul; uso automotriz; presentación estándar de catálogo.',98),
('PR099','Sensor ABS','TotalEnergies',NULL,331.3,61,'Pasillo 5, estante C-07','Sensor ABS TotalEnergies; uso automotriz; presentación estándar de catálogo.',99),
('PR100','Pastilla de freno cerámica','ACDelco','Tiggo 7',345.0,101,'Pasillo 7, estante A-01','Pastilla de freno cerámica ACDelco; uso automotriz; presentación estándar de catálogo.',100);


INSERT INTO COMPATIBILIDAD
(IdCompatibilidad, IdProducto, IdModeloVehiculo, Año) VALUES
(1,  'PR001',  1, 2020),   -- Corolla
(2,  'PR002',  6, 2021),   -- Sentra
(3,  'PR003', 21, 2019),   -- Rio
(4,  'PR004',  4, 2022),   -- RAV4
(5,  'PR005', 11, 2020),   -- Civic
(6,  'PR006', 17, 2021),   -- Elantra
(7,  'PR007', 26, 2018),   -- Sail
(8,  'PR008',  8, 2022),   -- Frontier
(9,  'PR009', 23, 2021),   -- Sportage
(10, 'PR010',  2, 2019),   -- Yaris
(11, 'PR011', 27, 2022),   -- Onix
(12, 'PR012', 12, 2020),   -- Accord
(13, 'PR013', 18, 2021),   -- Tucson
(14, 'PR014',  9, 2019),   -- X-Trail
(15, 'PR015', 13, 2022),   -- CR-V
(16, 'PR016', 16, 2020),   -- Accent
(17, 'PR017', 22, 2021),   -- Cerato
(18, 'PR018',  3, 2019),   -- Hilux
(19, 'PR019', 31, 2017),   -- Fiesta
(20, 'PR020', 20, 2022),   -- Creta
(21, 'PR021', 25, 2021),   -- Seltos
(22, 'PR022', 29, 2020),   -- Captiva
(23, 'PR023', 19, 2019),   -- Santa Fe
(24, 'PR024', 24, 2022),   -- Sorento
(25, 'PR025', 10, 2021),   -- Kicks
(26, 'PR026',  5, 2020),   -- Fortuner
(27, 'PR027', 30, 2022),   -- Colorado
(28, 'PR028', 28, 2021),   -- Tracker
(29, 'PR029', 33, 2019),   -- Ranger
(30, 'PR030', 35, 2020),   -- Explorer
(31, 'PR031', 37, 2018),   -- Polo
(32, 'PR032', 32, 2017),   -- Focus
(33, 'PR033', 34, 2020),   -- Escape
(34, 'PR034', 39, 2021),   -- Tiguan
(35, 'PR035', 41, 2022),   -- Mazda2
(36, 'PR036', 36, 2018),   -- Gol
(37, 'PR037', 38, 2019),   -- Jetta
(38, 'PR038', 42, 2021),   -- Mazda3
(39, 'PR039', 43, 2020),   -- CX-3
(40, 'PR040', 40, 2022),   -- Amarok
(41, 'PR041', 45, 2021),   -- BT-50
(42, 'PR042', 46, 2019),   -- Impreza
(43, 'PR043', 47, 2020),   -- Forester
(44, 'PR044', 44, 2022),   -- CX-5
(45, 'PR045', 49, 2021),   -- XV
(46, 'PR046', 51, 2018),   -- Lancer
(47, 'PR047', 50, 2020),   -- WRX
(48, 'PR048', 48, 2021),   -- Outback
(49, 'PR049', 53, 2019),   -- ASX
(50, 'PR050', 55, 2022),   -- L200
(51, 'PR051', 54, 2020),   -- Montero Sport
(52, 'PR052', 52, 2021),   -- Outlander
(53, 'PR053', 57, 2019),   -- Vitara
(54, 'PR054', 58, 2020),   -- Jimny
(55, 'PR055', 59, 2021),   -- S-Cross
(56, 'PR056', 56, 2022),   -- Swift
(57, 'PR057', 61, 2018),   -- Logan
(58, 'PR058', 62, 2019),   -- Sandero
(59, 'PR059', 63, 2021),   -- Duster
(60, 'PR060', 60, 2022),   -- Ertiga
(61, 'PR061', 65, 2020),   -- Captur
(62, 'PR062', 66, 2021),   -- Peugeot 208
(63, 'PR063', 69, 2022),   -- Peugeot 3008
(64, 'PR064', 64, 2020),   -- Koleos
(65, 'PR065', 70, 2019),   -- Partner
(66, 'PR066', 67, 2018),   -- Peugeot 301
(67, 'PR067', 71, 2021),   -- C3
(68, 'PR068', 68, 2022),   -- Peugeot 2008
(69, 'PR069', 75, 2021),   -- C5 Aircross
(70, 'PR070', 73, 2019),   -- C-Elysée
(71, 'PR071', 74, 2020),   -- Berlingo
(72, 'PR072', 72, 2022),   -- C4 Cactus
(73, 'PR073', 77, 2018),   -- Palio
(74, 'PR074', 78, 2021),   -- Strada
(75, 'PR075', 79, 2022),   -- Toro
(76, 'PR076', 76, 2019),   -- Uno
(77, 'PR077', 81, 2021),   -- Renegade
(78, 'PR078', 82, 2022),   -- Compass
(79, 'PR079', 83, 2020),   -- Wrangler
(80, 'PR080', 80, 2018),   -- Fiat 500
(81, 'PR081', 85, 2021),   -- Grand Cherokee
(82, 'PR082', 84, 2019),   -- Cherokee
(83, 'PR083', 86, 2022),   -- Mercedes C-Class
(84, 'PR084', 88, 2020),   -- BMW 3 Series
(85, 'PR085', 90, 2021),   -- Audi A3
(86, 'PR086', 87, 2019),   -- Mercedes E-Class
(87, 'PR087', 89, 2022),   -- BMW X3
(88, 'PR088', 92, 2021),   -- Volvo XC40
(89, 'PR089', 94, 2020),   -- Lexus NX
(90, 'PR090', 91, 2022),   -- Audi Q5
(91, 'PR091', 93, 2021),   -- Volvo XC60
(92, 'PR092', 95, 2020),   -- Lexus RX
(93, 'PR093', 97, 2022),   -- Porsche Macan
(94, 'PR094', 96, 2021),   -- Range Rover Evoque
(95, 'PR095', 98, 2023),   -- Tesla Model 3
(96, 'PR096', 96, 2022),   -- Range Rover Evoque
(97, 'PR097', 99, 2024),   -- BYD Dolphin
(98, 'PR098', 86, 2021),   -- Mercedes C-Class
(99, 'PR099', 89, 2020),   -- BMW X3
(100,'PR100',100, 2023),   -- Chery Tiggo 7


-- COMPATIBILIDADES ADICIONALES
-- Un producto puede ser compatible con varios años del mismo modelo.

(101, 'PR001',  1, 2019),  -- Corolla
(102, 'PR001',  1, 2021),  -- Corolla
(103, 'PR001',  1, 2022),  -- Corolla
(104, 'PR002',  6, 2020),  -- Sentra
(105, 'PR002',  6, 2022),  -- Sentra
(106, 'PR004',  4, 2020),  -- RAV4
(107, 'PR004',  4, 2021),  -- RAV4
(108, 'PR004',  4, 2023),  -- RAV4
(109, 'PR008',  8, 2020),  -- Frontier
(110, 'PR008',  8, 2021),  -- Frontier
(111, 'PR008',  8, 2023),  -- Frontier
(112, 'PR018',  3, 2018),  -- Hilux
(113, 'PR018',  3, 2020),  -- Hilux
(114, 'PR018',  3, 2021),  -- Hilux
(115, 'PR024', 24, 2020),  -- Sorento
(116, 'PR024', 24, 2021),  -- Sorento
(117, 'PR028', 28, 2020),  -- Tracker
(118, 'PR028', 28, 2022),  -- Tracker
(119, 'PR040', 40, 2020),  -- Amarok
(120, 'PR040', 40, 2021),  -- Amarok
(121, 'PR044', 44, 2020),  -- CX-5
(122, 'PR044', 44, 2021),  -- CX-5
(123, 'PR048', 48, 2020),  -- Outback
(124, 'PR048', 48, 2022),  -- Outback
(125, 'PR052', 52, 2020),  -- Outlander
(126, 'PR052', 52, 2022),  -- Outlander
(127, 'PR056', 56, 2020),  -- Swift
(128, 'PR056', 56, 2021),  -- Swift
(129, 'PR060', 60, 2020),  -- Ertiga
(130, 'PR060', 60, 2021),  -- Ertiga
(131, 'PR064', 64, 2019),  -- Koleos
(132, 'PR064', 64, 2021),  -- Koleos
(133, 'PR068', 68, 2020),  -- Peugeot 2008
(134, 'PR068', 68, 2021),  -- Peugeot 2008
(135, 'PR072', 72, 2020),  -- C4 Cactus
(136, 'PR072', 72, 2021),  -- C4 Cactus
(137, 'PR076', 76, 2018),  -- Uno
(138, 'PR076', 76, 2020),  -- Uno
(139, 'PR080', 80, 2019),  -- Fiat 500
(140, 'PR080', 80, 2020),  -- Fiat 500
(141, 'PR084', 88, 2019),  -- BMW 3 Series
(142, 'PR084', 88, 2021),  -- BMW 3 Series
(143, 'PR088', 92, 2020),  -- Volvo XC40
(144, 'PR088', 92, 2022),  -- Volvo XC40
(145, 'PR092', 95, 2019),  -- Lexus RX
(146, 'PR092', 95, 2021),  -- Lexus RX
(147, 'PR096', 96, 2020),  -- Range Rover Evoque
(148, 'PR096', 96, 2021),  -- Range Rover Evoque
(149, 'PR100',100, 2022),  -- Chery Tiggo 7
(150, 'PR100',100, 2024);  -- Chery Tiggo 7

INSERT INTO PROVEEDOR (IdProveedor,Nombre,Telefono,Direccion,Correo,RUC) VALUES
('PV001','Comercial Perú SRL','929245189','Av. Los Alisos 4230, Los Olivos','ventas892@gmail.com','20415053542'),
('PV002','Comercial Premium SAC','978360704','Av. Próceres de Huandoy 3083, Los Olivos','ventas880@hotmail.com','20784254721'),
('PV003','Servicios Automotrices Motors SRL','974264328','Av. Venezuela 4116, Breña','ventas337@gmail.com','20899725175'),
('PV004','Frenos Perú SAC','993711739','Av. Abancay 2733, Lima','ventas588@hotmail.com','20718127166'),
('PV005','Repuestos Lima EIRL','996376278','Av. Abancay 4294, Lima','ventas737@gmail.com','20134805511'),
('PV006','Motores San Martín EIRL','979851371','Av. Javier Prado 3910, San Isidro','ventas548@hotmail.com','20885473394'),
('PV007','Rodamientos Industrial SRL','926386311','Av. Caminos del Inca 3322, Santiago de Surco','ventas824@gmail.com','20560516941'),
('PV008','Autopartes Los Olivos SRL','902193893','Av. Abancay 3835, Lima','ventas315@hotmail.com','20845216640'),
('PV009','Filtros Motors EIRL','962740037','Av. Naranjal 508, Los Olivos','ventas938@gmail.com','20927072042'),
('PV010','Servicios Automotrices Premium EIRL','917190734','Av. Primavera 2555, Santiago de Surco','ventas363@hotmail.com','20257632351'),
('PV011','Transmisiones Los Olivos SRL','922511062','Av. Alfredo Mendiola 836, San Martín de Porres','ventas581@gmail.com','20305015611'),
('PV012','Suspensiones del Norte SAC','908488248','Av. Tomás Valle 4323, San Martín de Porres','ventas427@hotmail.com','20179532370'),
('PV013','Transmisiones Norte SRL','910465141','Av. México 3342, La Victoria','ventas275@gmail.com','20837831335'),
('PV014','Importaciones Norte SAC','941135125','Av. Los Alisos 1712, Los Olivos','ventas607@hotmail.com','20412362838'),
('PV015','Lubricantes Central SAC','904627196','Av. Primavera 1805, Santiago de Surco','ventas289@gmail.com','20231058908'),
('PV016','Transmisiones Andina EIRL','941884961','Av. Brasil 3191, Jesús María','ventas769@hotmail.com','20337326391'),
('PV017','Filtros Norte SAC','903945331','Av. Arequipa 1214, Lince','ventas165@gmail.com','20195242993'),
('PV018','Suspensiones San Martín SRL','988984089','Av. Túpac Amaru 328, Comas','ventas695@hotmail.com','20216885385'),
('PV019','Accesorios Pacífico SRL','925028275','Av. Universitaria 4797, Los Olivos','ventas572@gmail.com','20565865600'),
('PV020','Accesorios Express SRL','910957652','Av. Aviación 3900, San Borja','ventas347@hotmail.com','20646506060'),
('PV021','Importaciones Pacífico SAC','951295276','Av. Tomás Valle 3600, San Martín de Porres','ventas381@gmail.com','20911884551'),
('PV022','Autopartes San Martín SAC','985984202','Av. La Molina 1379, La Molina','ventas415@hotmail.com','20143933327'),
('PV023','Servicios Automotrices Perú SRL','910361570','Av. Aviación 793, San Borja','ventas354@gmail.com','20887282278'),
('PV024','Motores Norte SAC','901576718','Av. Nicolás Ayllón 481, Ate','ventas983@hotmail.com','20468689601'),
('PV025','Rodamientos Express EIRL','995868682','Av. Carlos Izaguirre 4828, Los Olivos','ventas578@gmail.com','20489210381'),
('PV026','Comercial Los Olivos SAC','988726156','Av. Túpac Amaru 2512, Comas','ventas952@hotmail.com','20739061891'),
('PV027','Filtros San Martín SRL','920644974','Av. Canadá 219, La Victoria','ventas570@gmail.com','20287530847'),
('PV028','Filtros Los Olivos SAC','943065433','Av. México 455, La Victoria','ventas656@hotmail.com','20811833500'),
('PV029','Servicios Automotrices Norte EIRL','985657301','Av. Argentina 3330, Callao','ventas230@gmail.com','20108167875'),
('PV030','Distribuidora Premium EIRL','975998178','Av. Brasil 2627, Jesús María','ventas256@hotmail.com','20593005411'),
('PV031','Repuestos del Norte EIRL','918054092','Av. Abancay 3368, Lima','ventas715@gmail.com','20125857907'),
('PV032','Filtros Motors EIRL','935852199','Av. Venezuela 4312, Breña','ventas710@hotmail.com','20709195108'),
('PV033','Servicios Automotrices Pacífico SRL','969485336','Av. Guardia Civil 2853, San Borja','ventas371@gmail.com','20898307159'),
('PV034','Distribuidora Metropolitana SAC','970959420','Av. Trapiche 3400, Comas','ventas528@hotmail.com','20664934214'),
('PV035','Importaciones Andina EIRL','936384143','Av. Canadá 1028, La Victoria','ventas548@gmail.com','20467138414'),
('PV036','Importaciones del Norte SAC','930545132','Av. Brasil 399, Jesús María','ventas172@hotmail.com','20116576393'),
('PV037','Filtros del Norte EIRL','903210206','Av. Los Alisos 1134, Los Olivos','ventas883@gmail.com','20859286870'),
('PV038','Motores Los Olivos SAC','921437500','Av. Alfredo Mendiola 566, San Martín de Porres','ventas729@hotmail.com','20328121841'),
('PV039','Filtros Norte SRL','969473124','Av. La Molina 3689, La Molina','ventas195@gmail.com','20298905907'),
('PV040','Lubricantes Los Olivos SAC','967413008','Av. Grau 2103, Lima','ventas859@hotmail.com','20689146440'),
('PV041','Lubricantes Andina SAC','962987119','Av. Caminos del Inca 3926, Santiago de Surco','ventas912@gmail.com','20401369644'),
('PV042','Autopartes Premium SAC','977661475','Av. México 340, La Victoria','ventas459@hotmail.com','20325409844'),
('PV043','Accesorios Industrial SRL','945580515','Av. Trapiche 4528, Comas','ventas208@gmail.com','20433107552'),
('PV044','Autopartes Los Olivos EIRL','974374018','Av. Canadá 4199, La Victoria','ventas212@hotmail.com','20543084779'),
('PV045','Lubricantes Motors SRL','967872553','Av. Trapiche 1369, Comas','ventas360@gmail.com','20693010005'),
('PV046','Transmisiones Pacífico SAC','934640741','Av. Naranjal 1388, Los Olivos','ventas312@hotmail.com','20113224879'),
('PV047','Frenos Express EIRL','924609712','Av. Caminos del Inca 993, Santiago de Surco','ventas726@gmail.com','20771561803'),
('PV048','Filtros Perú SAC','907314056','Av. Angélica Gamarra 811, Los Olivos','ventas280@hotmail.com','20379967265'),
('PV049','Transmisiones Pacífico SAC','929561678','Av. Naranjal 2519, Los Olivos','ventas896@gmail.com','20729805948'),
('PV050','Distribuidora Central SRL','996662480','Av. Iquitos 2702, La Victoria','ventas184@hotmail.com','20375115663'),
('PV051','Distribuidora Industrial SAC','904731457','Av. Trapiche 2322, Comas','ventas397@gmail.com','20752781410'),
('PV052','Distribuidora San Martín SRL','945613610','Av. Angélica Gamarra 1665, Los Olivos','ventas989@hotmail.com','20685620121'),
('PV053','Lubricantes Central SAC','978122925','Av. Trapiche 1094, Comas','ventas729@gmail.com','20535144908'),
('PV054','Distribuidora Express SAC','905903376','Av. Benavides 316, Miraflores','ventas910@hotmail.com','20444399172'),
('PV055','Rodamientos Premium SRL','966060294','Av. Aviación 437, San Borja','ventas183@gmail.com','20982320101'),
('PV056','Lubricantes Pacífico SAC','923396785','Av. Universitaria 2360, Los Olivos','ventas813@hotmail.com','20726385301'),
('PV057','Autopartes Express EIRL','983577560','Av. México 3911, La Victoria','ventas135@gmail.com','20547389876'),
('PV058','Repuestos Metropolitana EIRL','965222333','Av. México 4424, La Victoria','ventas208@hotmail.com','20161797562'),
('PV059','Motores Industrial EIRL','995695733','Av. La Molina 1492, La Molina','ventas934@gmail.com','20235380766'),
('PV060','Rodamientos Metropolitana EIRL','951516186','Av. Túpac Amaru 4719, Comas','ventas367@hotmail.com','20540558559'),
('PV061','Transmisiones del Norte EIRL','901262438','Av. La Molina 3587, La Molina','ventas816@gmail.com','20734457907'),
('PV062','Comercial Perú EIRL','934189037','Av. Carlos Izaguirre 2340, Los Olivos','ventas306@hotmail.com','20777651472'),
('PV063','Frenos Norte SRL','910952532','Av. Grau 3668, Lima','ventas883@gmail.com','20180389785'),
('PV064','Lubricantes Los Olivos SRL','956534744','Av. Abancay 3515, Lima','ventas774@hotmail.com','20699112578'),
('PV065','Comercial Express SAC','950565303','Av. México 1144, La Victoria','ventas775@gmail.com','20378234736'),
('PV066','Motores del Norte SRL','971951685','Av. Abancay 4035, Lima','ventas800@hotmail.com','20641481204'),
('PV067','Importaciones Central SRL','914705694','Av. Separadora Industrial 4653, Ate','ventas735@gmail.com','20739065128'),
('PV068','Accesorios Perú SAC','973842647','Av. Guardia Civil 4825, San Borja','ventas674@hotmail.com','20699440729'),
('PV069','Importaciones Perú SAC','944248955','Av. Guardia Civil 452, San Borja','ventas354@gmail.com','20679848187'),
('PV070','Motores Perú SRL','924372552','Av. Alfredo Mendiola 276, San Martín de Porres','ventas628@hotmail.com','20734061124'),
('PV071','Autopartes Norte EIRL','998263945','Av. Brasil 2181, Jesús María','ventas975@gmail.com','20778646421'),
('PV072','Accesorios del Pacífico SAC','995279036','Av. Colonial 2488, Lima','ventas440@hotmail.com','20418722372'),
('PV073','Motores San Martín EIRL','994015728','Av. Grau 3374, Lima','ventas988@gmail.com','20139601581'),
('PV074','Motores Pacífico EIRL','976963621','Av. Angélica Gamarra 1168, Los Olivos','ventas218@hotmail.com','20315696675'),
('PV075','Distribuidora Premium SRL','935716972','Av. Angélica Gamarra 1582, Los Olivos','ventas906@gmail.com','20283025901'),
('PV076','Accesorios Perú EIRL','964354895','Av. Tomás Valle 4806, San Martín de Porres','ventas360@hotmail.com','20738642237'),
('PV077','Frenos Express SAC','930931227','Av. Primavera 1158, Santiago de Surco','ventas718@gmail.com','20246355313'),
('PV078','Servicios Automotrices Pacífico SRL','987670521','Av. Iquitos 1137, La Victoria','ventas582@hotmail.com','20315427453'),
('PV079','Accesorios Pacífico SAC','996637804','Av. Angélica Gamarra 1093, Los Olivos','ventas371@gmail.com','20965017276'),
('PV080','Lubricantes Norte SRL','930275001','Av. Angélica Gamarra 419, Los Olivos','ventas469@hotmail.com','20888394312'),
('PV081','Servicios Automotrices Premium SAC','934865316','Av. Guardia Civil 3235, San Borja','ventas256@gmail.com','20729192032'),
('PV082','Rodamientos del Pacífico EIRL','910026295','Av. Colonial 3809, Lima','ventas962@hotmail.com','20666559348'),
('PV083','Comercial Andina SRL','957699034','Av. Angélica Gamarra 2870, Los Olivos','ventas326@gmail.com','20654903809'),
('PV084','Repuestos del Norte EIRL','922397229','Av. Venezuela 2209, Breña','ventas720@hotmail.com','20851388380'),
('PV085','Comercial Central SAC','922543636','Av. Primavera 4569, Santiago de Surco','ventas227@gmail.com','20746461667'),
('PV086','Repuestos Pacífico SAC','900112371','Av. Colonial 364, Lima','ventas959@hotmail.com','20962115781'),
('PV087','Filtros Industrial EIRL','913240928','Av. Iquitos 2951, La Victoria','ventas635@gmail.com','20166614067'),
('PV088','Transmisiones Los Olivos EIRL','998784665','Av. Aviación 525, San Borja','ventas124@hotmail.com','20670785310'),
('PV089','Servicios Automotrices Metropolitana EIRL','940970840','Av. Guardia Civil 3003, San Borja','ventas609@gmail.com','20222505985'),
('PV090','Accesorios Metropolitana SRL','936152793','Av. Javier Prado 476, San Isidro','ventas933@hotmail.com','20328082650'),
('PV091','Lubricantes Express SRL','912226165','Av. La Molina 1224, La Molina','ventas990@gmail.com','20537719096'),
('PV092','Accesorios del Pacífico EIRL','952648298','Av. Caminos del Inca 4534, Santiago de Surco','ventas881@hotmail.com','20184620104'),
('PV093','Importaciones Premium SRL','958103916','Av. México 2430, La Victoria','ventas784@gmail.com','20589429428'),
('PV094','Filtros Industrial SAC','915165464','Av. Grau 4284, Lima','ventas209@hotmail.com','20273579690'),
('PV095','Filtros Andina SRL','903220304','Av. Los Alisos 3858, Los Olivos','ventas782@gmail.com','20651504890'),
('PV096','Servicios Automotrices Lima EIRL','994064335','Av. Iquitos 3044, La Victoria','ventas990@hotmail.com','20900975920'),
('PV097','Repuestos Metropolitana SRL','980109767','Av. Brasil 1677, Jesús María','ventas509@gmail.com','20446029429'),
('PV098','Suspensiones del Norte SAC','961894379','Av. Aviación 4251, San Borja','ventas636@hotmail.com','20647123873'),
('PV099','Transmisiones Lima SAC','948549151','Av. Brasil 2908, Jesús María','ventas620@gmail.com','20661664810'),
('PV100','Accesorios Metropolitana SAC','999149000','Av. Abancay 251, Lima','ventas413@hotmail.com','20531030509');


INSERT INTO VENTA (IdVenta,Fecha,IdCliente,IdEmpleado) VALUES
(1,'2026-08-22','CLE087',33),
(2,'2026-05-31','CLE059',39),
(3,'2026-08-20','CLE062',13),
(4,'2026-04-20','CLN076',18),
(5,'2026-04-18','CLN039',93),
(6,'2026-05-11','CLN041',7),
(7,'2026-03-30','CLN016',79),
(8,'2026-01-31','CLN022',85),
(9,'2026-02-27','CLN084',16),
(10,'2026-07-21','CLE094',66),
(11,'2026-07-05','CLN032',4),
(12,'2026-08-04','CLE053',50),
(13,'2026-03-26','CLN071',18),
(14,'2026-06-24','CLN018',19),
(15,'2026-04-25','CLN003',10),
(16,'2026-06-11','CLE059',99),
(17,'2026-02-14','CLE015',47),
(18,'2026-01-16','CLN027',22),
(19,'2026-05-22','CLN035',63),
(20,'2026-01-18','CLE035',27),
(21,'2026-03-12','CLN011',24),
(22,'2026-06-07','CLN068',63),
(23,'2026-01-09','CLN037',53),
(24,'2026-05-11','CLN004',66),
(25,'2026-03-04','CLE041',5),
(26,'2026-08-26','CLE035',56),
(27,'2026-04-12','CLE069',56),
(28,'2026-05-20','CLE065',75),
(29,'2026-01-12','CLE046',91),
(30,'2026-02-18','CLE056',62),
(31,'2026-01-25','CLN058',8),
(32,'2026-02-21','CLE010',89),
(33,'2026-05-14','CLE036',85),
(34,'2026-03-06','CLE022',100),
(35,'2026-04-17','CLE093',12),
(36,'2026-02-16','CLN070',40),
(37,'2026-08-13','CLE034',19),
(38,'2026-01-11','CLN044',58),
(39,'2026-04-27','CLE053',77),
(40,'2026-02-16','CLE036',47),
(41,'2026-03-03','CLN081',5),
(42,'2026-01-31','CLE042',68),
(43,'2026-02-13','CLN069',92),
(44,'2026-07-12','CLE032',28),
(45,'2026-04-30','CLE012',42),
(46,'2026-03-16','CLE005',22),
(47,'2026-02-14','CLN098',59),
(48,'2026-02-15','CLE023',5),
(49,'2026-08-19','CLE043',19),
(50,'2026-06-04','CLN088',63),
(51,'2026-01-26','CLE073',12),
(52,'2026-08-30','CLE041',74),
(53,'2026-07-05','CLE081',47),
(54,'2026-05-31','CLE053',48),
(55,'2026-05-14','CLE050',42),
(56,'2026-02-11','CLN005',100),
(57,'2026-06-10','CLN046',96),
(58,'2026-08-25','CLE052',54),
(59,'2026-01-26','CLN087',17),
(60,'2026-02-05','CLE093',92),
(61,'2026-03-14','CLE065',91),
(62,'2026-04-16','CLN050',82),
(63,'2026-06-08','CLN039',14),
(64,'2026-03-10','CLN097',96),
(65,'2026-03-29','CLN009',9),
(66,'2026-04-13','CLN016',5),
(67,'2026-05-15','CLN072',81),
(68,'2026-06-02','CLE022',86),
(69,'2026-02-02','CLN013',42),
(70,'2026-03-20','CLN026',42),
(71,'2026-06-27','CLE040',57),
(72,'2026-05-21','CLE039',68),
(73,'2026-08-05','CLE039',1),
(74,'2026-03-17','CLN020',32),
(75,'2026-05-28','CLE010',93),
(76,'2026-05-13','CLN040',26),
(77,'2026-06-29','CLE058',76),
(78,'2026-06-25','CLN026',59),
(79,'2026-08-13','CLE068',83),
(80,'2026-04-15','CLN099',84),
(81,'2026-04-21','CLE011',58),
(82,'2026-05-17','CLE065',48),
(83,'2026-05-01','CLE005',49),
(84,'2026-07-20','CLE016',57),
(85,'2026-06-19','CLE076',35),
(86,'2026-03-04','CLN015',62),
(87,'2026-07-07','CLN079',10),
(88,'2026-02-24','CLN094',6),
(89,'2026-01-21','CLN048',34),
(90,'2026-03-17','CLN007',92),
(91,'2026-08-05','CLN011',73),
(92,'2026-08-11','CLE034',79),
(93,'2026-02-07','CLN001',1),
(94,'2026-05-15','CLN088',19),
(95,'2026-02-10','CLN061',34),
(96,'2026-06-29','CLE035',79),
(97,'2026-02-10','CLN004',17),
(98,'2026-03-06','CLE100',90),
(99,'2026-08-16','CLE081',64),
(100,'2026-08-29','CLE016',47);


INSERT INTO DETALLE_VENTA (IdDetalleVenta,IdVenta,IdProducto,PrecioUnitario,Cantidad) VALUES
(1,1,'PR001',28.7,3),
(2,2,'PR002',42.4,3),
(3,3,'PR003',56.1,5),
(4,4,'PR004',69.8,5),
(5,5,'PR005',83.5,5),
(6,6,'PR006',97.2,4),
(7,7,'PR007',110.9,3),
(8,8,'PR008',124.6,5),
(9,9,'PR009',138.3,4),
(10,10,'PR010',152.0,4),
(11,11,'PR011',165.7,1),
(12,12,'PR012',179.4,2),
(13,13,'PR013',193.1,5),
(14,14,'PR014',206.8,4),
(15,15,'PR015',220.5,3),
(16,16,'PR016',234.2,5),
(17,17,'PR017',247.9,2),
(18,18,'PR018',261.6,4),
(19,19,'PR019',275.3,4),
(20,20,'PR020',289.0,4),
(21,21,'PR021',302.7,2),
(22,22,'PR022',316.4,4),
(23,23,'PR023',330.1,2),
(24,24,'PR024',343.8,5),
(25,25,'PR025',357.5,5),
(26,26,'PR026',371.2,1),
(27,27,'PR027',384.9,1),
(28,28,'PR028',398.6,5),
(29,29,'PR029',412.3,5),
(30,30,'PR030',426.0,5),
(31,31,'PR031',439.7,1),
(32,32,'PR032',453.4,4),
(33,33,'PR033',467.1,5),
(34,34,'PR034',480.8,5),
(35,35,'PR035',494.5,1),
(36,36,'PR036',508.2,1),
(37,37,'PR037',521.9,1),
(38,38,'PR038',15.6,1),
(39,39,'PR039',29.3,2),
(40,40,'PR040',43.0,1),
(41,41,'PR041',56.7,1),
(42,42,'PR042',70.4,4),
(43,43,'PR043',84.1,4),
(44,44,'PR044',97.8,3),
(45,45,'PR045',111.5,2),
(46,46,'PR046',125.2,3),
(47,47,'PR047',138.9,2),
(48,48,'PR048',152.6,4),
(49,49,'PR049',166.3,2),
(50,50,'PR050',180.0,3),
(51,51,'PR051',193.7,2),
(52,52,'PR052',207.4,3),
(53,53,'PR053',221.1,4),
(54,54,'PR054',234.8,1),
(55,55,'PR055',248.5,5),
(56,56,'PR056',262.2,1),
(57,57,'PR057',275.9,4),
(58,58,'PR058',289.6,5),
(59,59,'PR059',303.3,4),
(60,60,'PR060',317.0,5),
(61,61,'PR061',330.7,2),
(62,62,'PR062',344.4,3),
(63,63,'PR063',358.1,4),
(64,64,'PR064',371.8,2),
(65,65,'PR065',385.5,5),
(66,66,'PR066',399.2,4),
(67,67,'PR067',412.9,1),
(68,68,'PR068',426.6,1),
(69,69,'PR069',440.3,4),
(70,70,'PR070',454.0,3),
(71,71,'PR071',467.7,1),
(72,72,'PR072',481.4,5),
(73,73,'PR073',495.1,5),
(74,74,'PR074',508.8,1),
(75,75,'PR075',522.5,1),
(76,76,'PR076',16.2,3),
(77,77,'PR077',29.9,4),
(78,78,'PR078',43.6,3),
(79,79,'PR079',57.3,2),
(80,80,'PR080',71.0,3),
(81,81,'PR081',84.7,1),
(82,82,'PR082',98.4,3),
(83,83,'PR083',112.1,1),
(84,84,'PR084',125.8,3),
(85,85,'PR085',139.5,4),
(86,86,'PR086',153.2,3),
(87,87,'PR087',166.9,4),
(88,88,'PR088',180.6,2),
(89,89,'PR089',194.3,5),
(90,90,'PR090',208.0,5),
(91,91,'PR091',221.7,1),
(92,92,'PR092',235.4,5),
(93,93,'PR093',249.1,2),
(94,94,'PR094',262.8,3),
(95,95,'PR095',276.5,3),
(96,96,'PR096',290.2,1),
(97,97,'PR097',303.9,4),
(98,98,'PR098',317.6,1),
(99,99,'PR099',331.3,3),
(100,100,'PR100',345.0,2);


INSERT INTO COMPRA (IdCompra,Fecha,MontoTotal,IdProveedor) VALUES
(1,'2026-02-05',287.68,'PV001'),
(2,'2026-06-01',387.24,'PV002'),
(3,'2026-03-25',541.2,'PV003'),
(4,'2026-07-10',848.7,'PV004'),
(5,'2026-05-27',604.0,'PV005'),
(6,'2025-11-25',866.74,'PV006'),
(7,'2025-12-03',1605.12,'PV007'),
(8,'2026-02-20',723.44,'PV008'),
(9,'2025-12-25',1582.2,'PV009'),
(10,'2026-06-15',1912.84,'PV010'),
(11,'2026-06-05',1102.4,'PV011'),
(12,'2026-07-24',1764.62,'PV012'),
(13,'2025-11-25',1697.64,'PV013'),
(14,'2026-04-16',1862.98,'PV014'),
(15,'2026-05-03',1911.65,'PV015'),
(16,'2026-02-26',2605.08,'PV016'),
(17,'2026-05-26',1752.2,'PV017'),
(18,'2026-02-27',2319.48,'PV018'),
(19,'2025-12-28',3211.36,'PV019'),
(20,'2025-12-07',4121.86,'PV020'),
(21,'2026-05-29',2086.2,'PV021'),
(22,'2026-01-23',1657.81,'PV022'),
(23,'2026-07-07',1330.8,'PV023'),
(24,'2026-04-10',1480.56,'PV024'),
(25,'2026-04-05',3789.3,'PV025'),
(26,'2026-05-16',5282.19,'PV026'),
(27,'2025-11-12',4416.32,'PV027'),
(28,'2026-03-25',5244.66,'PV028'),
(29,'2026-01-06',1892.22,'PV029'),
(30,'2026-03-04',5555.0,'PV030'),
(31,'2026-06-10',5486.8,'PV031'),
(32,'2026-04-04',4233.96,'PV032'),
(33,'2025-11-18',4067.28,'PV033'),
(34,'2026-02-02',5414.4,'PV034'),
(35,'2026-01-21',3218.31,'PV035'),
(36,'2026-06-30',4989.88,'PV036'),
(37,'2026-06-20',4417.56,'PV037'),
(38,'2026-04-14',159.45,'PV038'),
(39,'2026-02-20',435.8,'PV039'),
(40,'2026-03-02',360.12,'PV040'),
(41,'2026-05-25',609.0,'PV041'),
(42,'2026-01-09',271.56,'PV042'),
(43,'2026-02-10',508.95,'PV043'),
(44,'2026-05-16',1122.24,'PV044'),
(45,'2026-01-22',1495.87,'PV045'),
(46,'2026-03-06',1250.4,'PV046'),
(47,'2026-04-23',1405.6,'PV047'),
(48,'2026-04-18',1418.04,'PV048'),
(49,'2026-07-23',2171.07,'PV049'),
(50,'2026-01-19',1266.4,'PV050'),
(51,'2025-12-18',1206.96,'PV051'),
(52,'2026-03-27',1578.61,'PV052'),
(53,'2026-01-21',1605.45,'PV053'),
(54,'2025-12-17',1068.06,'PV054'),
(55,'2026-02-02',2410.24,'PV055'),
(56,'2026-01-12',1078.62,'PV056'),
(57,'2025-11-29',3012.16,'PV057'),
(58,'2026-03-28',1595.52,'PV058'),
(59,'2026-07-26',2001.15,'PV059'),
(60,'2026-03-23',2359.08,'PV060'),
(61,'2025-12-05',3380.02,'PV061'),
(62,'2026-03-13',3194.88,'PV062'),
(63,'2026-05-19',4144.43,'PV063'),
(64,'2025-12-11',3164.37,'PV064'),
(65,'2026-06-23',1615.56,'PV065'),
(66,'2026-02-24',2390.32,'PV066'),
(67,'2026-04-18',3560.44,'PV067'),
(68,'2025-11-08',2748.96,'PV068'),
(69,'2026-05-27',3843.56,'PV069'),
(70,'2025-11-17',1759.02,'PV070'),
(71,'2026-01-01',2506.07,'PV071'),
(72,'2026-04-30',4063.95,'PV072'),
(73,'2025-11-15',4868.89,'PV073'),
(74,'2026-05-21',5322.08,'PV074'),
(75,'2026-03-14',4910.22,'PV075'),
(76,'2025-12-19',92.0,'PV076'),
(77,'2025-11-06',407.74,'PV077'),
(78,'2026-03-12',653.0,'PV078'),
(79,'2025-11-05',577.28,'PV079'),
(80,'2026-06-19',833.44,'PV080'),
(81,'2026-06-02',913.28,'PV081'),
(82,'2026-04-01',726.6,'PV082'),
(83,'2026-06-05',905.85,'PV083'),
(84,'2026-02-09',1656.36,'PV084'),
(85,'2026-05-13',616.56,'PV085'),
(86,'2026-01-19',2280.6,'PV086'),
(87,'2026-01-02',990.27,'PV087'),
(88,'2026-07-19',2619.8,'PV088'),
(89,'2026-05-14',1486.8,'PV089'),
(90,'2026-04-29',1845.76,'PV090'),
(91,'2025-11-07',2107.98,'PV091'),
(92,'2026-01-17',3200.0,'PV092'),
(93,'2025-11-22',1554.9,'PV093'),
(94,'2026-02-11',2557.36,'PV094'),
(95,'2025-12-24',1519.36,'PV095'),
(96,'2026-07-16',3732.93,'PV096'),
(97,'2025-11-14',3061.38,'PV097'),
(98,'2026-02-03',1617.92,'PV098'),
(99,'2026-05-08',3581.76,'PV099'),
(100,'2026-05-30',4293.92,'PV100');


INSERT INTO DETALLE_COMPRA (IdDetalleCompra,IdCompra,IdProducto,PrecioCompra,Cantidad) VALUES
(1,1,'PR001',17.98,16),
(2,2,'PR002',32.27,12),
(3,3,'PR003',36.08,15),
(4,4,'PR004',47.15,18),
(5,5,'PR005',60.4,10),
(6,6,'PR006',61.91,14),
(7,7,'PR007',84.48,19),
(8,8,'PR008',90.43,8),
(9,9,'PR009',105.48,15),
(10,10,'PR010',112.52,17),
(11,11,'PR011',110.24,10),
(12,12,'PR012',135.74,13),
(13,13,'PR013',141.47,12),
(14,14,'PR014',133.07,14),
(15,15,'PR015',147.05,13),
(16,16,'PR016',153.24,17),
(17,17,'PR017',175.22,10),
(18,18,'PR018',193.29,12),
(19,19,'PR019',200.71,16),
(20,20,'PR020',216.94,19),
(21,21,'PR021',231.8,9),
(22,22,'PR022',236.83,7),
(23,23,'PR023',221.8,6),
(24,24,'PR024',246.76,6),
(25,25,'PR025',222.9,17),
(26,26,'PR026',278.01,19),
(27,27,'PR027',276.02,16),
(28,28,'PR028',291.37,18),
(29,29,'PR029',315.37,6),
(30,30,'PR030',277.75,20),
(31,31,'PR031',274.34,20),
(32,32,'PR032',352.83,12),
(33,33,'PR033',338.94,12),
(34,34,'PR034',300.8,18),
(35,35,'PR035',357.59,9),
(36,36,'PR036',356.42,14),
(37,37,'PR037',368.13,12),
(38,38,'PR038',10.63,15),
(39,39,'PR039',21.79,20),
(40,40,'PR040',30.01,12),
(41,41,'PR041',40.6,15),
(42,42,'PR042',45.26,6),
(43,43,'PR043',56.55,9),
(44,44,'PR044',70.14,16),
(45,45,'PR045',78.73,19),
(46,46,'PR046',78.15,16),
(47,47,'PR047',100.4,14),
(48,48,'PR048',109.08,13),
(49,49,'PR049',127.71,17),
(50,50,'PR050',126.64,10),
(51,51,'PR051',150.87,8),
(52,52,'PR052',143.51,11),
(53,53,'PR053',145.95,11),
(54,54,'PR054',152.58,7),
(55,55,'PR055',172.16,14),
(56,56,'PR056',179.77,6),
(57,57,'PR057',188.26,16),
(58,58,'PR058',199.44,8),
(59,59,'PR059',222.35,9),
(60,60,'PR060',196.59,12),
(61,61,'PR061',241.43,14),
(62,62,'PR062',266.24,12),
(63,63,'PR063',243.79,17),
(64,64,'PR064',287.67,11),
(65,65,'PR065',269.26,6),
(66,66,'PR066',298.79,8),
(67,67,'PR067',273.88,13),
(68,68,'PR068',305.44,9),
(69,69,'PR069',274.54,14),
(70,70,'PR070',293.17,6),
(71,71,'PR071',358.01,7),
(72,72,'PR072',369.45,11),
(73,73,'PR073',374.53,13),
(74,74,'PR074',332.63,16),
(75,75,'PR075',350.73,14),
(76,76,'PR076',11.5,8),
(77,77,'PR077',21.46,19),
(78,78,'PR078',32.65,20),
(79,79,'PR079',36.08,16),
(80,80,'PR080',52.09,16),
(81,81,'PR081',57.08,16),
(82,82,'PR082',72.66,10),
(83,83,'PR083',82.35,11),
(84,84,'PR084',92.02,18),
(85,85,'PR085',88.08,7),
(86,86,'PR086',114.03,20),
(87,87,'PR087',110.03,9),
(88,88,'PR088',130.99,20),
(89,89,'PR089',148.68,10),
(90,90,'PR090',131.84,14),
(91,91,'PR091',150.57,14),
(92,92,'PR092',160.0,20),
(93,93,'PR093',155.49,10),
(94,94,'PR094',196.72,13),
(95,95,'PR095',189.92,8),
(96,96,'PR096',196.47,19),
(97,97,'PR097',218.67,14),
(98,98,'PR098',202.24,8),
(99,99,'PR099',223.86,16),
(100,100,'PR100',268.37,16);


INSERT INTO PAGO (IdPago,Fecha,Monto,MetodoPago) VALUES
(1,'2026-08-22',86.1,'Plin'),
(2,'2026-05-31',127.2,'Efectivo'),
(3,'2026-08-20',280.5,'Efectivo'),
(4,'2026-04-20',349.0,'Plin'),
(5,'2026-04-18',417.5,'Yape'),
(6,'2026-05-11',388.8,'Plin'),
(7,'2026-03-30',332.7,'Tarjeta Crédito'),
(8,'2026-01-31',623.0,'Transferencia'),
(9,'2026-02-27',553.2,'Tarjeta Crédito'),
(10,'2026-07-21',608.0,'Tarjeta Débito'),
(11,'2026-07-05',165.7,'Tarjeta Crédito'),
(12,'2026-08-04',358.8,'Efectivo'),
(13,'2026-03-26',965.5,'Yape'),
(14,'2026-06-24',827.2,'Plin'),
(15,'2026-04-25',661.5,'Transferencia'),
(16,'2026-06-11',1171.0,'Yape'),
(17,'2026-02-14',495.8,'Efectivo'),
(18,'2026-01-16',1046.4,'Tarjeta Débito'),
(19,'2026-05-22',1101.2,'Tarjeta Crédito'),
(20,'2026-01-18',1156.0,'Tarjeta Débito'),
(21,'2026-03-12',605.4,'Yape'),
(22,'2026-06-07',1265.6,'Transferencia'),
(23,'2026-01-09',660.2,'Transferencia'),
(24,'2026-05-11',1719.0,'Efectivo'),
(25,'2026-03-04',1787.5,'Tarjeta Crédito'),
(26,'2026-08-26',371.2,'Transferencia'),
(27,'2026-04-12',384.9,'Efectivo'),
(28,'2026-05-20',1993.0,'Transferencia'),
(29,'2026-01-12',2061.5,'Efectivo'),
(30,'2026-02-18',2130.0,'Efectivo'),
(31,'2026-01-25',439.7,'Tarjeta Débito'),
(32,'2026-02-21',1813.6,'Plin'),
(33,'2026-05-14',2335.5,'Yape'),
(34,'2026-03-06',2404.0,'Tarjeta Crédito'),
(35,'2026-04-17',494.5,'Tarjeta Crédito'),
(36,'2026-02-16',508.2,'Yape'),
(37,'2026-08-13',521.9,'Tarjeta Crédito'),
(38,'2026-01-11',15.6,'Tarjeta Débito'),
(39,'2026-04-27',58.6,'Yape'),
(40,'2026-02-16',43.0,'Plin'),
(41,'2026-03-03',56.7,'Tarjeta Débito'),
(42,'2026-01-31',281.6,'Plin'),
(43,'2026-02-13',336.4,'Tarjeta Crédito'),
(44,'2026-07-12',293.4,'Plin'),
(45,'2026-04-30',223.0,'Plin'),
(46,'2026-03-16',375.6,'Transferencia'),
(47,'2026-02-14',277.8,'Transferencia'),
(48,'2026-02-15',610.4,'Transferencia'),
(49,'2026-08-19',332.6,'Tarjeta Débito'),
(50,'2026-06-04',540.0,'Tarjeta Crédito'),
(51,'2026-01-26',387.4,'Transferencia'),
(52,'2026-08-30',622.2,'Transferencia'),
(53,'2026-07-05',884.4,'Transferencia'),
(54,'2026-05-31',234.8,'Efectivo'),
(55,'2026-05-14',1242.5,'Efectivo'),
(56,'2026-02-11',262.2,'Plin'),
(57,'2026-06-10',1103.6,'Yape'),
(58,'2026-08-25',1448.0,'Tarjeta Crédito'),
(59,'2026-01-26',1213.2,'Efectivo'),
(60,'2026-02-05',1585.0,'Efectivo'),
(61,'2026-03-14',661.4,'Efectivo'),
(62,'2026-04-16',1033.2,'Transferencia'),
(63,'2026-06-08',1432.4,'Transferencia'),
(64,'2026-03-10',743.6,'Plin'),
(65,'2026-03-29',1927.5,'Efectivo'),
(66,'2026-04-13',1596.8,'Tarjeta Débito'),
(67,'2026-05-15',412.9,'Tarjeta Débito'),
(68,'2026-06-02',426.6,'Transferencia'),
(69,'2026-02-02',1761.2,'Efectivo'),
(70,'2026-03-20',1362.0,'Tarjeta Débito'),
(71,'2026-06-27',467.7,'Yape'),
(72,'2026-05-21',2407.0,'Yape'),
(73,'2026-08-05',2475.5,'Efectivo'),
(74,'2026-03-17',508.8,'Plin'),
(75,'2026-05-28',522.5,'Tarjeta Crédito'),
(76,'2026-05-13',48.6,'Transferencia'),
(77,'2026-06-29',119.6,'Tarjeta Débito'),
(78,'2026-06-25',130.8,'Tarjeta Crédito'),
(79,'2026-08-13',114.6,'Plin'),
(80,'2026-04-15',213.0,'Plin'),
(81,'2026-04-21',84.7,'Tarjeta Débito'),
(82,'2026-05-17',295.2,'Plin'),
(83,'2026-05-01',112.1,'Tarjeta Crédito'),
(84,'2026-07-20',377.4,'Tarjeta Crédito'),
(85,'2026-06-19',558.0,'Tarjeta Débito'),
(86,'2026-03-04',459.6,'Transferencia'),
(87,'2026-07-07',667.6,'Efectivo'),
(88,'2026-02-24',361.2,'Tarjeta Crédito'),
(89,'2026-01-21',971.5,'Yape'),
(90,'2026-03-17',1040.0,'Plin'),
(91,'2026-08-05',221.7,'Yape'),
(92,'2026-08-11',1177.0,'Yape'),
(93,'2026-02-07',498.2,'Tarjeta Débito'),
(94,'2026-05-15',788.4,'Tarjeta Crédito'),
(95,'2026-02-10',829.5,'Efectivo'),
(96,'2026-06-29',290.2,'Tarjeta Débito'),
(97,'2026-02-10',1215.6,'Yape'),
(98,'2026-03-06',317.6,'Tarjeta Débito'),
(99,'2026-08-16',993.9,'Yape'),
(100,'2026-08-29',690.0,'Tarjeta Crédito'),
(101,'2026-02-05',287.68,'Tarjeta Crédito'),
(102,'2026-06-01',387.24,'Plin'),
(103,'2026-03-25',541.2,'Efectivo'),
(104,'2026-07-10',848.7,'Transferencia'),
(105,'2026-05-27',604.0,'Transferencia'),
(106,'2025-11-25',866.74,'Transferencia'),
(107,'2025-12-03',1605.12,'Tarjeta Crédito'),
(108,'2026-02-20',723.44,'Tarjeta Crédito'),
(109,'2025-12-25',1582.2,'Tarjeta Débito'),
(110,'2026-06-15',1912.84,'Tarjeta Débito'),
(111,'2026-06-05',1102.4,'Yape'),
(112,'2026-07-24',1764.62,'Tarjeta Débito'),
(113,'2025-11-25',1697.64,'Transferencia'),
(114,'2026-04-16',1862.98,'Plin'),
(115,'2026-05-03',1911.65,'Tarjeta Débito'),
(116,'2026-02-26',2605.08,'Plin'),
(117,'2026-05-26',1752.2,'Plin'),
(118,'2026-02-27',2319.48,'Plin'),
(119,'2025-12-28',3211.36,'Tarjeta Crédito'),
(120,'2025-12-07',4121.86,'Efectivo'),
(121,'2026-05-29',2086.2,'Tarjeta Débito'),
(122,'2026-01-23',1657.81,'Plin'),
(123,'2026-07-07',1330.8,'Efectivo'),
(124,'2026-04-10',1480.56,'Efectivo'),
(125,'2026-04-05',3789.3,'Efectivo'),
(126,'2026-05-16',5282.19,'Efectivo'),
(127,'2025-11-12',4416.32,'Plin'),
(128,'2026-03-25',5244.66,'Tarjeta Crédito'),
(129,'2026-01-06',1892.22,'Tarjeta Débito'),
(130,'2026-03-04',5555.0,'Tarjeta Crédito'),
(131,'2026-06-10',5486.8,'Transferencia'),
(132,'2026-04-04',4233.96,'Plin'),
(133,'2025-11-18',4067.28,'Yape'),
(134,'2026-02-02',5414.4,'Efectivo'),
(135,'2026-01-21',3218.31,'Yape'),
(136,'2026-06-30',4989.88,'Plin'),
(137,'2026-06-20',4417.56,'Yape'),
(138,'2026-04-14',159.45,'Transferencia'),
(139,'2026-02-20',435.8,'Transferencia'),
(140,'2026-03-02',360.12,'Efectivo'),
(141,'2026-05-25',609.0,'Plin'),
(142,'2026-01-09',271.56,'Tarjeta Débito'),
(143,'2026-02-10',508.95,'Tarjeta Crédito'),
(144,'2026-05-16',1122.24,'Plin'),
(145,'2026-01-22',1495.87,'Plin'),
(146,'2026-03-06',1250.4,'Yape'),
(147,'2026-04-23',1405.6,'Efectivo'),
(148,'2026-04-18',1418.04,'Tarjeta Débito'),
(149,'2026-07-23',2171.07,'Tarjeta Débito'),
(150,'2026-01-19',1266.4,'Tarjeta Crédito'),
(151,'2025-12-18',1206.96,'Efectivo'),
(152,'2026-03-27',1578.61,'Efectivo'),
(153,'2026-01-21',1605.45,'Tarjeta Crédito'),
(154,'2025-12-17',1068.06,'Yape'),
(155,'2026-02-02',2410.24,'Tarjeta Débito'),
(156,'2026-01-12',1078.62,'Yape'),
(157,'2025-11-29',3012.16,'Efectivo'),
(158,'2026-03-28',1595.52,'Tarjeta Crédito'),
(159,'2026-07-26',2001.15,'Transferencia'),
(160,'2026-03-23',2359.08,'Tarjeta Crédito'),
(161,'2025-12-05',3380.02,'Plin'),
(162,'2026-03-13',3194.88,'Tarjeta Débito'),
(163,'2026-05-19',4144.43,'Tarjeta Crédito'),
(164,'2025-12-11',3164.37,'Transferencia'),
(165,'2026-06-23',1615.56,'Yape'),
(166,'2026-02-24',2390.32,'Tarjeta Débito'),
(167,'2026-04-18',3560.44,'Plin'),
(168,'2025-11-08',2748.96,'Plin'),
(169,'2026-05-27',3843.56,'Plin'),
(170,'2025-11-17',1759.02,'Yape'),
(171,'2026-01-01',2506.07,'Tarjeta Débito'),
(172,'2026-04-30',4063.95,'Tarjeta Débito'),
(173,'2025-11-15',4868.89,'Efectivo'),
(174,'2026-05-21',5322.08,'Transferencia'),
(175,'2026-03-14',4910.22,'Yape'),
(176,'2025-12-19',92.0,'Tarjeta Crédito'),
(177,'2025-11-06',407.74,'Efectivo'),
(178,'2026-03-12',653.0,'Efectivo'),
(179,'2025-11-05',577.28,'Tarjeta Débito'),
(180,'2026-06-19',833.44,'Tarjeta Débito'),
(181,'2026-06-02',913.28,'Plin'),
(182,'2026-04-01',726.6,'Plin'),
(183,'2026-06-05',905.85,'Yape'),
(184,'2026-02-09',1656.36,'Yape'),
(185,'2026-05-13',616.56,'Tarjeta Débito'),
(186,'2026-01-19',2280.6,'Transferencia'),
(187,'2026-01-02',990.27,'Transferencia'),
(188,'2026-07-19',2619.8,'Yape'),
(189,'2026-05-14',1486.8,'Tarjeta Crédito'),
(190,'2026-04-29',1845.76,'Plin'),
(191,'2025-11-07',2107.98,'Yape'),
(192,'2026-01-17',3200.0,'Transferencia'),
(193,'2025-11-22',1554.9,'Efectivo'),
(194,'2026-02-11',2557.36,'Yape'),
(195,'2025-12-24',1519.36,'Transferencia'),
(196,'2026-07-16',3732.93,'Tarjeta Crédito'),
(197,'2025-11-14',3061.38,'Plin'),
(198,'2026-02-03',1617.92,'Yape'),
(199,'2026-05-08',3581.76,'Plin'),
(200,'2026-05-30',4293.92,'Yape');


INSERT INTO PAGO_VENTA (IdPago,IdVenta,Estado) VALUES
(1,1,'Pagado'),
(2,2,'Pagado'),
(3,3,'Pagado'),
(4,4,'Pagado'),
(5,5,'Pagado'),
(6,6,'Pagado'),
(7,7,'Pagado'),
(8,8,'Pagado'),
(9,9,'Pagado'),
(10,10,'Pagado'),
(11,11,'Pagado'),
(12,12,'Pagado'),
(13,13,'Pagado'),
(14,14,'Pagado'),
(15,15,'Pagado'),
(16,16,'Pagado'),
(17,17,'Pagado'),
(18,18,'Pagado'),
(19,19,'Pagado'),
(20,20,'Pagado'),
(21,21,'Pagado'),
(22,22,'Pagado'),
(23,23,'Pagado'),
(24,24,'Pagado'),
(25,25,'Pagado'),
(26,26,'Pagado'),
(27,27,'Pagado'),
(28,28,'Pagado'),
(29,29,'Pagado'),
(30,30,'Pagado'),
(31,31,'Pagado'),
(32,32,'Pagado'),
(33,33,'Pagado'),
(34,34,'Pagado'),
(35,35,'Pagado'),
(36,36,'Pagado'),
(37,37,'Pagado'),
(38,38,'Pagado'),
(39,39,'Pagado'),
(40,40,'Pagado'),
(41,41,'Pagado'),
(42,42,'Pagado'),
(43,43,'Pagado'),
(44,44,'Pagado'),
(45,45,'Pagado'),
(46,46,'Pagado'),
(47,47,'Pagado'),
(48,48,'Pagado'),
(49,49,'Pagado'),
(50,50,'Pagado'),
(51,51,'Pagado'),
(52,52,'Pagado'),
(53,53,'Pagado'),
(54,54,'Pagado'),
(55,55,'Pagado'),
(56,56,'Pagado'),
(57,57,'Pagado'),
(58,58,'Pagado'),
(59,59,'Pagado'),
(60,60,'Pagado'),
(61,61,'Pagado'),
(62,62,'Pagado'),
(63,63,'Pagado'),
(64,64,'Pagado'),
(65,65,'Pagado'),
(66,66,'Pagado'),
(67,67,'Pagado'),
(68,68,'Pagado'),
(69,69,'Pagado'),
(70,70,'Pagado'),
(71,71,'Pagado'),
(72,72,'Pagado'),
(73,73,'Pagado'),
(74,74,'Pagado'),
(75,75,'Pagado'),
(76,76,'Pagado'),
(77,77,'Pagado'),
(78,78,'Pagado'),
(79,79,'Pagado'),
(80,80,'Pagado'),
(81,81,'Pagado'),
(82,82,'Pagado'),
(83,83,'Pagado'),
(84,84,'Pagado'),
(85,85,'Pagado'),
(86,86,'Pagado'),
(87,87,'Pagado'),
(88,88,'Pagado'),
(89,89,'Pagado'),
(90,90,'Pagado'),
(91,91,'Pagado'),
(92,92,'Pagado'),
(93,93,'Pagado'),
(94,94,'Pagado'),
(95,95,'Pagado'),
(96,96,'Pagado'),
(97,97,'Pagado'),
(98,98,'Pagado'),
(99,99,'Pagado'),
(100,100,'Pagado');


INSERT INTO PAGO_COMPRA (IdPago,IdCompra) VALUES
(101,1),
(102,2),
(103,3),
(104,4),
(105,5),
(106,6),
(107,7),
(108,8),
(109,9),
(110,10),
(111,11),
(112,12),
(113,13),
(114,14),
(115,15),
(116,16),
(117,17),
(118,18),
(119,19),
(120,20),
(121,21),
(122,22),
(123,23),
(124,24),
(125,25),
(126,26),
(127,27),
(128,28),
(129,29),
(130,30),
(131,31),
(132,32),
(133,33),
(134,34),
(135,35),
(136,36),
(137,37),
(138,38),
(139,39),
(140,40),
(141,41),
(142,42),
(143,43),
(144,44),
(145,45),
(146,46),
(147,47),
(148,48),
(149,49),
(150,50),
(151,51),
(152,52),
(153,53),
(154,54),
(155,55),
(156,56),
(157,57),
(158,58),
(159,59),
(160,60),
(161,61),
(162,62),
(163,63),
(164,64),
(165,65),
(166,66),
(167,67),
(168,68),
(169,69),
(170,70),
(171,71),
(172,72),
(173,73),
(174,74),
(175,75),
(176,76),
(177,77),
(178,78),
(179,79),
(180,80),
(181,81),
(182,82),
(183,83),
(184,84),
(185,85),
(186,86),
(187,87),
(188,88),
(189,89),
(190,90),
(191,91),
(192,92),
(193,93),
(194,94),
(195,95),
(196,96),
(197,97),
(198,98),
(199,99),
(200,100);


INSERT INTO COMPROBANTE (IdComprobante,Correlativo,Serie,TipoComprobante) VALUES
(1,'000001','B001','Boleta'),
(2,'000002','F001','Factura'),
(3,'000003','B001','Boleta'),
(4,'000004','F001','Factura'),
(5,'000005','B001','Boleta'),
(6,'000006','F001','Factura'),
(7,'000007','B001','Boleta'),
(8,'000008','F001','Factura'),
(9,'000009','B001','Boleta'),
(10,'000010','F001','Factura'),
(11,'000011','B001','Boleta'),
(12,'000012','F001','Factura'),
(13,'000013','B001','Boleta'),
(14,'000014','F001','Factura'),
(15,'000015','B001','Boleta'),
(16,'000016','F001','Factura'),
(17,'000017','B001','Boleta'),
(18,'000018','F001','Factura'),
(19,'000019','B001','Boleta'),
(20,'000020','F001','Factura'),
(21,'000021','B001','Boleta'),
(22,'000022','F001','Factura'),
(23,'000023','B001','Boleta'),
(24,'000024','F001','Factura'),
(25,'000025','B001','Boleta'),
(26,'000026','F001','Factura'),
(27,'000027','B001','Boleta'),
(28,'000028','F001','Factura'),
(29,'000029','B001','Boleta'),
(30,'000030','F001','Factura'),
(31,'000031','B001','Boleta'),
(32,'000032','F001','Factura'),
(33,'000033','B001','Boleta'),
(34,'000034','F001','Factura'),
(35,'000035','B001','Boleta'),
(36,'000036','F001','Factura'),
(37,'000037','B001','Boleta'),
(38,'000038','F001','Factura'),
(39,'000039','B001','Boleta'),
(40,'000040','F001','Factura'),
(41,'000041','B001','Boleta'),
(42,'000042','F001','Factura'),
(43,'000043','B001','Boleta'),
(44,'000044','F001','Factura'),
(45,'000045','B001','Boleta'),
(46,'000046','F001','Factura'),
(47,'000047','B001','Boleta'),
(48,'000048','F001','Factura'),
(49,'000049','B001','Boleta'),
(50,'000050','F001','Factura'),
(51,'000051','B001','Boleta'),
(52,'000052','F001','Factura'),
(53,'000053','B001','Boleta'),
(54,'000054','F001','Factura'),
(55,'000055','B001','Boleta'),
(56,'000056','F001','Factura'),
(57,'000057','B001','Boleta'),
(58,'000058','F001','Factura'),
(59,'000059','B001','Boleta'),
(60,'000060','F001','Factura'),
(61,'000061','B001','Boleta'),
(62,'000062','F001','Factura'),
(63,'000063','B001','Boleta'),
(64,'000064','F001','Factura'),
(65,'000065','B001','Boleta'),
(66,'000066','F001','Factura'),
(67,'000067','B001','Boleta'),
(68,'000068','F001','Factura'),
(69,'000069','B001','Boleta'),
(70,'000070','F001','Factura'),
(71,'000071','B001','Boleta'),
(72,'000072','F001','Factura'),
(73,'000073','B001','Boleta'),
(74,'000074','F001','Factura'),
(75,'000075','B001','Boleta'),
(76,'000076','F001','Factura'),
(77,'000077','B001','Boleta'),
(78,'000078','F001','Factura'),
(79,'000079','B001','Boleta'),
(80,'000080','F001','Factura'),
(81,'000081','B001','Boleta'),
(82,'000082','F001','Factura'),
(83,'000083','B001','Boleta'),
(84,'000084','F001','Factura'),
(85,'000085','B001','Boleta'),
(86,'000086','F001','Factura'),
(87,'000087','B001','Boleta'),
(88,'000088','F001','Factura'),
(89,'000089','B001','Boleta'),
(90,'000090','F001','Factura'),
(91,'000091','B001','Boleta'),
(92,'000092','F001','Factura'),
(93,'000093','B001','Boleta'),
(94,'000094','F001','Factura'),
(95,'000095','B001','Boleta'),
(96,'000096','F001','Factura'),
(97,'000097','B001','Boleta'),
(98,'000098','F001','Factura'),
(99,'000099','B001','Boleta'),
(100,'000100','F001','Factura'),
(101,'000001','FC01','Factura'),
(102,'000002','FC01','Factura'),
(103,'000003','FC01','Factura'),
(104,'000004','FC01','Factura'),
(105,'000005','FC01','Factura'),
(106,'000006','FC01','Factura'),
(107,'000007','FC01','Factura'),
(108,'000008','FC01','Factura'),
(109,'000009','FC01','Factura'),
(110,'000010','FC01','Factura'),
(111,'000011','FC01','Factura'),
(112,'000012','FC01','Factura'),
(113,'000013','FC01','Factura'),
(114,'000014','FC01','Factura'),
(115,'000015','FC01','Factura'),
(116,'000016','FC01','Factura'),
(117,'000017','FC01','Factura'),
(118,'000018','FC01','Factura'),
(119,'000019','FC01','Factura'),
(120,'000020','FC01','Factura'),
(121,'000021','FC01','Factura'),
(122,'000022','FC01','Factura'),
(123,'000023','FC01','Factura'),
(124,'000024','FC01','Factura'),
(125,'000025','FC01','Factura'),
(126,'000026','FC01','Factura'),
(127,'000027','FC01','Factura'),
(128,'000028','FC01','Factura'),
(129,'000029','FC01','Factura'),
(130,'000030','FC01','Factura'),
(131,'000031','FC01','Factura'),
(132,'000032','FC01','Factura'),
(133,'000033','FC01','Factura'),
(134,'000034','FC01','Factura'),
(135,'000035','FC01','Factura'),
(136,'000036','FC01','Factura'),
(137,'000037','FC01','Factura'),
(138,'000038','FC01','Factura'),
(139,'000039','FC01','Factura'),
(140,'000040','FC01','Factura'),
(141,'000041','FC01','Factura'),
(142,'000042','FC01','Factura'),
(143,'000043','FC01','Factura'),
(144,'000044','FC01','Factura'),
(145,'000045','FC01','Factura'),
(146,'000046','FC01','Factura'),
(147,'000047','FC01','Factura'),
(148,'000048','FC01','Factura'),
(149,'000049','FC01','Factura'),
(150,'000050','FC01','Factura'),
(151,'000051','FC01','Factura'),
(152,'000052','FC01','Factura'),
(153,'000053','FC01','Factura'),
(154,'000054','FC01','Factura'),
(155,'000055','FC01','Factura'),
(156,'000056','FC01','Factura'),
(157,'000057','FC01','Factura'),
(158,'000058','FC01','Factura'),
(159,'000059','FC01','Factura'),
(160,'000060','FC01','Factura'),
(161,'000061','FC01','Factura'),
(162,'000062','FC01','Factura'),
(163,'000063','FC01','Factura'),
(164,'000064','FC01','Factura'),
(165,'000065','FC01','Factura'),
(166,'000066','FC01','Factura'),
(167,'000067','FC01','Factura'),
(168,'000068','FC01','Factura'),
(169,'000069','FC01','Factura'),
(170,'000070','FC01','Factura'),
(171,'000071','FC01','Factura'),
(172,'000072','FC01','Factura'),
(173,'000073','FC01','Factura'),
(174,'000074','FC01','Factura'),
(175,'000075','FC01','Factura'),
(176,'000076','FC01','Factura'),
(177,'000077','FC01','Factura'),
(178,'000078','FC01','Factura'),
(179,'000079','FC01','Factura'),
(180,'000080','FC01','Factura'),
(181,'000081','FC01','Factura'),
(182,'000082','FC01','Factura'),
(183,'000083','FC01','Factura'),
(184,'000084','FC01','Factura'),
(185,'000085','FC01','Factura'),
(186,'000086','FC01','Factura'),
(187,'000087','FC01','Factura'),
(188,'000088','FC01','Factura'),
(189,'000089','FC01','Factura'),
(190,'000090','FC01','Factura'),
(191,'000091','FC01','Factura'),
(192,'000092','FC01','Factura'),
(193,'000093','FC01','Factura'),
(194,'000094','FC01','Factura'),
(195,'000095','FC01','Factura'),
(196,'000096','FC01','Factura'),
(197,'000097','FC01','Factura'),
(198,'000098','FC01','Factura'),
(199,'000099','FC01','Factura'),
(200,'000100','FC01','Factura');


INSERT INTO COMPROBANTE_VENTA (IdComprobante,IdVenta,Estado) VALUES
(1,1,'Emitido'),
(2,2,'Emitido'),
(3,3,'Emitido'),
(4,4,'Emitido'),
(5,5,'Emitido'),
(6,6,'Emitido'),
(7,7,'Emitido'),
(8,8,'Emitido'),
(9,9,'Emitido'),
(10,10,'Emitido'),
(11,11,'Emitido'),
(12,12,'Emitido'),
(13,13,'Emitido'),
(14,14,'Emitido'),
(15,15,'Emitido'),
(16,16,'Emitido'),
(17,17,'Emitido'),
(18,18,'Emitido'),
(19,19,'Emitido'),
(20,20,'Emitido'),
(21,21,'Emitido'),
(22,22,'Emitido'),
(23,23,'Emitido'),
(24,24,'Emitido'),
(25,25,'Emitido'),
(26,26,'Emitido'),
(27,27,'Emitido'),
(28,28,'Emitido'),
(29,29,'Emitido'),
(30,30,'Emitido'),
(31,31,'Emitido'),
(32,32,'Emitido'),
(33,33,'Emitido'),
(34,34,'Emitido'),
(35,35,'Emitido'),
(36,36,'Emitido'),
(37,37,'Emitido'),
(38,38,'Emitido'),
(39,39,'Emitido'),
(40,40,'Emitido'),
(41,41,'Emitido'),
(42,42,'Emitido'),
(43,43,'Emitido'),
(44,44,'Emitido'),
(45,45,'Emitido'),
(46,46,'Emitido'),
(47,47,'Emitido'),
(48,48,'Emitido'),
(49,49,'Emitido'),
(50,50,'Emitido'),
(51,51,'Emitido'),
(52,52,'Emitido'),
(53,53,'Emitido'),
(54,54,'Emitido'),
(55,55,'Emitido'),
(56,56,'Emitido'),
(57,57,'Emitido'),
(58,58,'Emitido'),
(59,59,'Emitido'),
(60,60,'Emitido'),
(61,61,'Emitido'),
(62,62,'Emitido'),
(63,63,'Emitido'),
(64,64,'Emitido'),
(65,65,'Emitido'),
(66,66,'Emitido'),
(67,67,'Emitido'),
(68,68,'Emitido'),
(69,69,'Emitido'),
(70,70,'Emitido'),
(71,71,'Emitido'),
(72,72,'Emitido'),
(73,73,'Emitido'),
(74,74,'Emitido'),
(75,75,'Emitido'),
(76,76,'Emitido'),
(77,77,'Emitido'),
(78,78,'Emitido'),
(79,79,'Emitido'),
(80,80,'Emitido'),
(81,81,'Emitido'),
(82,82,'Emitido'),
(83,83,'Emitido'),
(84,84,'Emitido'),
(85,85,'Emitido'),
(86,86,'Emitido'),
(87,87,'Emitido'),
(88,88,'Emitido'),
(89,89,'Emitido'),
(90,90,'Emitido'),
(91,91,'Emitido'),
(92,92,'Emitido'),
(93,93,'Emitido'),
(94,94,'Emitido'),
(95,95,'Emitido'),
(96,96,'Emitido'),
(97,97,'Emitido'),
(98,98,'Emitido'),
(99,99,'Emitido'),
(100,100,'Emitido');


INSERT INTO COMPROBANTE_COMPRA (IdComprobante,IdCompra) VALUES
(101,1),
(102,2),
(103,3),
(104,4),
(105,5),
(106,6),
(107,7),
(108,8),
(109,9),
(110,10),
(111,11),
(112,12),
(113,13),
(114,14),
(115,15),
(116,16),
(117,17),
(118,18),
(119,19),
(120,20),
(121,21),
(122,22),
(123,23),
(124,24),
(125,25),
(126,26),
(127,27),
(128,28),
(129,29),
(130,30),
(131,31),
(132,32),
(133,33),
(134,34),
(135,35),
(136,36),
(137,37),
(138,38),
(139,39),
(140,40),
(141,41),
(142,42),
(143,43),
(144,44),
(145,45),
(146,46),
(147,47),
(148,48),
(149,49),
(150,50),
(151,51),
(152,52),
(153,53),
(154,54),
(155,55),
(156,56),
(157,57),
(158,58),
(159,59),
(160,60),
(161,61),
(162,62),
(163,63),
(164,64),
(165,65),
(166,66),
(167,67),
(168,68),
(169,69),
(170,70),
(171,71),
(172,72),
(173,73),
(174,74),
(175,75),
(176,76),
(177,77),
(178,78),
(179,79),
(180,80),
(181,81),
(182,82),
(183,83),
(184,84),
(185,85),
(186,86),
(187,87),
(188,88),
(189,89),
(190,90),
(191,91),
(192,92),
(193,93),
(194,94),
(195,95),
(196,96),
(197,97),
(198,98),
(199,99),
(200,100);

DELIMITER $$
CREATE TRIGGER trg_validar_stock_venta
BEFORE INSERT ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    DECLARE stock_actual INT;
    SELECT Stock INTO stock_actual
    FROM PRODUCTO
    WHERE IdProducto=NEW.IdProducto;

    IF stock_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Producto inexistente';
    END IF;

    IF NEW.Cantidad > stock_actual THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Stock insuficiente';
    END IF;
END$$

CREATE TRIGGER trg_disminuir_stock_venta
AFTER INSERT ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
    SET Stock=Stock-NEW.Cantidad
    WHERE IdProducto=NEW.IdProducto;
END$$

CREATE TRIGGER trg_aumentar_stock_compra
AFTER INSERT ON DETALLE_COMPRA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
    SET Stock=Stock+NEW.Cantidad
    WHERE IdProducto=NEW.IdProducto;
END$$

DELIMITER ;

-- VALIDACION DE CANTIDADES
SELECT 'CLIENTE' Tabla,COUNT(*) Registros FROM CLIENTE
UNION ALL SELECT 'CLIENTE_NATURAL',COUNT(*) FROM CLIENTE_NATURAL
UNION ALL SELECT 'CLIENTE_EMPRESA',COUNT(*) FROM CLIENTE_EMPRESA
UNION ALL SELECT 'EMPLEADO',COUNT(*) FROM EMPLEADO
UNION ALL SELECT 'CATEGORIA',COUNT(*) FROM CATEGORIA
UNION ALL SELECT 'MARCA_VEHICULO',COUNT(*) FROM MARCA_VEHICULO
UNION ALL SELECT 'MODELO_VEHICULO',COUNT(*) FROM MODELO_VEHICULO
UNION ALL SELECT 'PRODUCTO',COUNT(*) FROM PRODUCTO
UNION ALL SELECT 'COMPATIBILIDAD',COUNT(*) FROM COMPATIBILIDAD
UNION ALL SELECT 'PROVEEDOR',COUNT(*) FROM PROVEEDOR
UNION ALL SELECT 'VENTA',COUNT(*) FROM VENTA
UNION ALL SELECT 'DETALLE_VENTA',COUNT(*) FROM DETALLE_VENTA
UNION ALL SELECT 'COMPRA',COUNT(*) FROM COMPRA
UNION ALL SELECT 'DETALLE_COMPRA',COUNT(*) FROM DETALLE_COMPRA
UNION ALL SELECT 'PAGO',COUNT(*) FROM PAGO
UNION ALL SELECT 'PAGO_VENTA',COUNT(*) FROM PAGO_VENTA
UNION ALL SELECT 'PAGO_COMPRA',COUNT(*) FROM PAGO_COMPRA
UNION ALL SELECT 'COMPROBANTE',COUNT(*) FROM COMPROBANTE
UNION ALL SELECT 'COMPROBANTE_VENTA',COUNT(*) FROM COMPROBANTE_VENTA
UNION ALL SELECT 'COMPROBANTE_COMPRA',COUNT(*) FROM COMPROBANTE_COMPRA;

-- VALIDAR VENTAS Y PAGOS
SELECT V.IdVenta,
       ROUND(SUM(DV.Cantidad*DV.PrecioUnitario),2) TotalVenta,
       P.Monto MontoPago,
       CASE WHEN ROUND(SUM(DV.Cantidad*DV.PrecioUnitario),2)=P.Monto
            THEN 'CORRECTO' ELSE 'REVISAR' END Validacion
FROM VENTA V
JOIN DETALLE_VENTA DV ON DV.IdVenta=V.IdVenta
JOIN PAGO_VENTA PV ON PV.IdVenta=V.IdVenta
JOIN PAGO P ON P.IdPago=PV.IdPago
GROUP BY V.IdVenta,P.Monto
ORDER BY V.IdVenta;

-- VALIDAR COMPRAS, DETALLE Y PAGOS
SELECT C.IdCompra,
       C.MontoTotal,
       ROUND(SUM(DC.Cantidad*DC.PrecioCompra),2) TotalDetalle,
       P.Monto MontoPago,
       CASE WHEN C.MontoTotal=ROUND(SUM(DC.Cantidad*DC.PrecioCompra),2)
                 AND C.MontoTotal=P.Monto
            THEN 'CORRECTO' ELSE 'REVISAR' END Validacion
FROM COMPRA C
JOIN DETALLE_COMPRA DC ON DC.IdCompra=C.IdCompra
JOIN PAGO_COMPRA PC ON PC.IdCompra=C.IdCompra
JOIN PAGO P ON P.IdPago=PC.IdPago
GROUP BY C.IdCompra,C.MontoTotal,P.Monto
ORDER BY C.IdCompra;


-- CONSULTAS 

USE COMERCIAL_VIDA;

-- 1. MOSTRAR TODOS LOS CLIENTES
SELECT *
FROM CLIENTE;

-- 2. CLIENTES Y QUIÉN LOS RECOMENDÓ
SELECT
    C.IdCliente,
    COALESCE(
        CONCAT(CN.Nombre, ' ', CN.Apellido),
        CE.RazonSocial
    ) AS Cliente,
    C.IdCliente_Recomienda,
    COALESCE(
        CONCAT(CNR.Nombre, ' ', CNR.Apellido),
        CER.RazonSocial
    ) AS Recomienda
FROM CLIENTE C
LEFT JOIN CLIENTE_NATURAL CN
       ON C.IdCliente = CN.IdCliente
LEFT JOIN CLIENTE_EMPRESA CE
       ON C.IdCliente = CE.IdCliente
LEFT JOIN CLIENTE R
       ON C.IdCliente_Recomienda = R.IdCliente
LEFT JOIN CLIENTE_NATURAL CNR
       ON R.IdCliente = CNR.IdCliente
LEFT JOIN CLIENTE_EMPRESA CER
       ON R.IdCliente = CER.IdCliente
ORDER BY C.IdCliente;

-- 3. CANTIDAD DE PRODUCTOS POR CATEGORÍA
SELECT
    C.IdCategoria,
    C.Nombre AS Categoria,
    COUNT(P.IdProducto) AS CantidadProductos
FROM CATEGORIA C
LEFT JOIN PRODUCTO P
       ON C.IdCategoria = P.IdCategoria
GROUP BY C.IdCategoria, C.Nombre
ORDER BY C.IdCategoria;


-- 4. MÉTODOS DE PAGO MÁS UTILIZADOS
SELECT
    MetodoPago,
    COUNT(*) AS Cantidad
FROM PAGO
GROUP BY MetodoPago
ORDER BY Cantidad DESC, MetodoPago;

-- 5. PRODUCTOS CON BAJO STOCK-
SELECT
    P.IdProducto,
    P.Nombre,
    P.Marca,
    C.Nombre AS Categoria,
    P.Stock,
    P.Ubicacion
FROM PRODUCTO P
INNER JOIN CATEGORIA C
        ON P.IdCategoria = C.IdCategoria
WHERE P.Stock <= 3
ORDER BY P.Stock ASC, P.Nombre;

-- 6. HISTORIAL DE VENTAS CON CLIENTE, EMPLEADO Y MONTO TOTAL
SELECT
    V.IdVenta,
    V.Fecha,
    COALESCE(
        CONCAT(CN.Nombre, ' ', CN.Apellido),
        CE.RazonSocial
    ) AS Cliente,
    E.Nombre AS Empleado,
    SUM(DV.Cantidad * DV.PrecioUnitario) AS TotalVenta
FROM VENTA V
INNER JOIN CLIENTE C
        ON V.IdCliente = C.IdCliente
LEFT JOIN CLIENTE_NATURAL CN
       ON C.IdCliente = CN.IdCliente
LEFT JOIN CLIENTE_EMPRESA CE
       ON C.IdCliente = CE.IdCliente
INNER JOIN EMPLEADO E
        ON V.IdEmpleado = E.IdEmpleado
INNER JOIN DETALLE_VENTA DV
        ON V.IdVenta = DV.IdVenta
GROUP BY
    V.IdVenta,
    V.Fecha,
    C.IdCliente,
    CN.Nombre,
    CN.Apellido,
    CE.RazonSocial,
    E.Nombre
ORDER BY V.Fecha, V.IdVenta;


-- 7. CLIENTES FRECUENTES
SELECT
    C.IdCliente,
    COALESCE(
        CONCAT(CN.Nombre, ' ', CN.Apellido),
        CE.RazonSocial
    ) AS Cliente,
    COUNT(DISTINCT DV.IdProducto) AS ProductosDiferentes,
    SUM(DV.Cantidad) AS UnidadesCompradas
FROM CLIENTE C
LEFT JOIN CLIENTE_NATURAL CN
       ON C.IdCliente = CN.IdCliente
LEFT JOIN CLIENTE_EMPRESA CE
       ON C.IdCliente = CE.IdCliente
INNER JOIN VENTA V
        ON C.IdCliente = V.IdCliente
INNER JOIN DETALLE_VENTA DV
        ON V.IdVenta = DV.IdVenta
GROUP BY
    C.IdCliente,
    CN.Nombre,
    CN.Apellido,
    CE.RazonSocial
HAVING COUNT(DISTINCT DV.IdProducto) > 3
ORDER BY ProductosDiferentes DESC, UnidadesCompradas DESC;

-- 8. LOS 5 PRODUCTOS MÁS VENDIDOS
SELECT
    P.IdProducto,
    P.Nombre,
    P.Marca,
    SUM(DV.Cantidad) AS TotalVendido
FROM PRODUCTO P
INNER JOIN DETALLE_VENTA DV
        ON P.IdProducto = DV.IdProducto
GROUP BY P.IdProducto, P.Nombre, P.Marca
ORDER BY TotalVendido DESC
LIMIT 5;


-- 9. MÉTODOS DE PAGO UTILIZADOS MÁS DE UNA VEZ
SELECT
    MetodoPago,
    COUNT(IdPago) AS TotalPagos
FROM PAGO
GROUP BY MetodoPago
HAVING COUNT(IdPago) > 1
ORDER BY TotalPagos DESC;

-- 10. PRODUCTOS COMPRADOS POR CADA CLIENTE
SELECT
    C.IdCliente,
    COALESCE(
        CONCAT(CN.Nombre, ' ', CN.Apellido),
        CE.RazonSocial
    ) AS Cliente,
    P.IdProducto,
    P.Nombre AS Producto,
    DV.Cantidad,
    DV.PrecioUnitario,
    ROUND(DV.Cantidad * DV.PrecioUnitario, 2) AS Subtotal
FROM CLIENTE C
LEFT JOIN CLIENTE_NATURAL CN
       ON C.IdCliente = CN.IdCliente
LEFT JOIN CLIENTE_EMPRESA CE
       ON C.IdCliente = CE.IdCliente
INNER JOIN VENTA V
        ON C.IdCliente = V.IdCliente
INNER JOIN DETALLE_VENTA DV
        ON V.IdVenta = DV.IdVenta
INNER JOIN PRODUCTO P
        ON DV.IdProducto = P.IdProducto
ORDER BY C.IdCliente, V.IdVenta;


-- 11. TOTAL VENDIDO POR CATEGORÍA
SELECT
    C.IdCategoria,
    C.Nombre AS Categoria,
    ROUND(SUM(DV.Cantidad * DV.PrecioUnitario), 2) AS TotalVendido
FROM CATEGORIA C
INNER JOIN PRODUCTO P
        ON C.IdCategoria = P.IdCategoria
INNER JOIN DETALLE_VENTA DV
        ON P.IdProducto = DV.IdProducto
GROUP BY C.IdCategoria, C.Nombre
ORDER BY TotalVendido DESC;

-- 12. PRODUCTOS ADQUIRIDOS A CADA PROVEEDOR Y COSTO TOTAL
SELECT
    PR.IdProveedor,
    PR.Nombre AS Proveedor,
    P.IdProducto,
    P.Nombre AS Producto,
    SUM(DC.Cantidad) AS CantidadComprada,
    ROUND(SUM(DC.Cantidad * DC.PrecioCompra), 2) AS TotalCompra
FROM PROVEEDOR PR
INNER JOIN COMPRA C
        ON PR.IdProveedor = C.IdProveedor
INNER JOIN DETALLE_COMPRA DC
        ON C.IdCompra = DC.IdCompra
INNER JOIN PRODUCTO P
        ON DC.IdProducto = P.IdProducto
GROUP BY
    PR.IdProveedor,
    PR.Nombre,
    P.IdProducto,
    P.Nombre
ORDER BY TotalCompra DESC;


-- 13. PRODUCTOS CON PRECIO SUPERIOR AL PROMEDIO
SELECT
    IdProducto,
    Nombre,
    Marca,
    Precio
FROM PRODUCTO
WHERE Precio > (
    SELECT AVG(Precio)
    FROM PRODUCTO
)
ORDER BY Precio DESC;


-- 14. PRODUCTOS CON VENTAS SUPERIORES AL PROMEDIO
SELECT
    P.IdProducto,
    P.Nombre,
    SUM(DV.Cantidad) AS TotalVendido
FROM PRODUCTO P
INNER JOIN DETALLE_VENTA DV
        ON P.IdProducto = DV.IdProducto
GROUP BY P.IdProducto, P.Nombre
HAVING SUM(DV.Cantidad) > (
    SELECT AVG(TotalVentas)
    FROM (
        SELECT
            SUM(Cantidad) AS TotalVentas
        FROM DETALLE_VENTA
        GROUP BY IdProducto
    ) AS VentasProducto
)
ORDER BY TotalVendido DESC;

-- 15. CLIENTES RECOMENDADOS POR OTROS CLIENTES
SELECT
    C.IdCliente,
    COALESCE(
        CONCAT(CN.Nombre, ' ', CN.Apellido),
        CE.RazonSocial
    ) AS Cliente,
    COALESCE(
        CONCAT(CNR.Nombre, ' ', CNR.Apellido),
        CER.RazonSocial
    ) AS RecomendadoPor
FROM CLIENTE C
LEFT JOIN CLIENTE_NATURAL CN
       ON C.IdCliente = CN.IdCliente
LEFT JOIN CLIENTE_EMPRESA CE
       ON C.IdCliente = CE.IdCliente
INNER JOIN CLIENTE R
        ON C.IdCliente_Recomienda = R.IdCliente
LEFT JOIN CLIENTE_NATURAL CNR
       ON R.IdCliente = CNR.IdCliente
LEFT JOIN CLIENTE_EMPRESA CER
       ON R.IdCliente = CER.IdCliente
ORDER BY RecomendadoPor, Cliente;


-- 16. CANTIDAD DE PRODUCTOS VENDIDOS POR MARCA DE REPUESTO
SELECT
    P.Marca,
    SUM(DV.Cantidad) AS TotalVendido
FROM PRODUCTO P
INNER JOIN DETALLE_VENTA DV
        ON P.IdProducto = DV.IdProducto
GROUP BY P.Marca
ORDER BY TotalVendido DESC;


-- 17. CANTIDAD DE COMPRAS REALIZADAS POR PROVEEDOR
SELECT
    PR.IdProveedor,
    PR.Nombre AS Proveedor,
    COUNT(C.IdCompra) AS TotalCompras,
    ROUND(SUM(C.MontoTotal), 2) AS ImporteComprado
FROM PROVEEDOR PR
INNER JOIN COMPRA C
        ON PR.IdProveedor = C.IdProveedor
GROUP BY PR.IdProveedor, PR.Nombre
ORDER BY TotalCompras DESC, ImporteComprado DESC;

-- 18. CANTIDAD DE PRODUCTOS VENDIDOS POR CLIENTE
SELECT
    C.IdCliente,
    COALESCE(
        CONCAT(CN.Nombre, ' ', CN.Apellido),
        CE.RazonSocial
    ) AS Cliente,
    SUM(DV.Cantidad) AS TotalProductosComprados,
    ROUND(SUM(DV.Cantidad * DV.PrecioUnitario), 2) AS TotalGastado
FROM CLIENTE C
LEFT JOIN CLIENTE_NATURAL CN
       ON C.IdCliente = CN.IdCliente
LEFT JOIN CLIENTE_EMPRESA CE
       ON C.IdCliente = CE.IdCliente
INNER JOIN VENTA V
        ON C.IdCliente = V.IdCliente
INNER JOIN DETALLE_VENTA DV
        ON V.IdVenta = DV.IdVenta
GROUP BY
    C.IdCliente,
    CN.Nombre,
    CN.Apellido,
    CE.RazonSocial
ORDER BY TotalProductosComprados DESC, TotalGastado DESC;


-- 19. COMPORTAMIENTO DE VENTAS POR MES
SELECT
    YEAR(V.Fecha) AS Anio,
    MONTH(V.Fecha) AS Mes,
    COUNT(DISTINCT V.IdVenta) AS CantidadVentas,
    SUM(DV.Cantidad) AS UnidadesVendidas,
    ROUND(SUM(DV.Cantidad * DV.PrecioUnitario), 2) AS TotalVendido
FROM VENTA V
INNER JOIN DETALLE_VENTA DV
        ON V.IdVenta = DV.IdVenta
GROUP BY YEAR(V.Fecha), MONTH(V.Fecha)
ORDER BY Anio, Mes;


-- 20. COMPATIBILIDAD: PRODUCTO, MARCA Y MODELO DE VEHÍCULO
SELECT
    P.IdProducto,
    P.Nombre AS Producto,
    P.Marca AS MarcaRepuesto,
    MVH.NombreMarca AS MarcaVehiculo,
    MDV.NombreModelo AS ModeloVehiculo,
    CO.Año AS Año
FROM COMPATIBILIDAD CO
INNER JOIN PRODUCTO P
        ON CO.IdProducto = P.IdProducto
INNER JOIN MODELO_VEHICULO MDV
        ON CO.IdModeloVehiculo = MDV.IdModeloVehiculo
INNER JOIN MARCA_VEHICULO MVH
        ON MDV.IdMarcaVehiculo = MVH.IdMarcaVehiculo
ORDER BY MVH.NombreMarca, MDV.NombreModelo, P.Nombre, CO.Año;


-- 21. CANTIDAD DE MODELOS REGISTRADOS POR MARCA DE VEHÍCULO
SELECT
    MVH.IdMarcaVehiculo,
    MVH.NombreMarca,
    COUNT(MDV.IdModeloVehiculo) AS CantidadModelos
FROM MARCA_VEHICULO MVH
LEFT JOIN MODELO_VEHICULO MDV
       ON MVH.IdMarcaVehiculo = MDV.IdMarcaVehiculo
GROUP BY MVH.IdMarcaVehiculo, MVH.NombreMarca
ORDER BY CantidadModelos DESC, MVH.NombreMarca;


-- 22. DETALLE COMPLETO DE PAGOS DE VENTA

SELECT
    PV.IdPago,
    PV.IdVenta,
    P.Fecha,
    P.MetodoPago,
    P.Monto,
    PV.Estado
FROM PAGO_VENTA PV
INNER JOIN PAGO P
        ON PV.IdPago = P.IdPago
ORDER BY PV.IdVenta;

-- 23. DETALLE COMPLETO DE PAGOS DE COMPRA
SELECT
    PC.IdPago,
    PC.IdCompra,
    P.Fecha,
    P.MetodoPago,
    P.Monto
FROM PAGO_COMPRA PC
INNER JOIN PAGO P
        ON PC.IdPago = P.IdPago
ORDER BY PC.IdCompra;


-- 24. COMPROBANTES DE VENTA

SELECT
    CV.IdVenta,
    C.IdComprobante,
    C.TipoComprobante,
    C.Serie,
    C.Correlativo,
    CV.Estado
FROM COMPROBANTE_VENTA CV
INNER JOIN COMPROBANTE C
        ON CV.IdComprobante = C.IdComprobante
ORDER BY CV.IdVenta;

-- 25. COMPROBANTES DE COMPRA
SELECT
    CC.IdCompra,
    C.IdComprobante,
    C.TipoComprobante,
    C.Serie,
    C.Correlativo
FROM COMPROBANTE_COMPRA CC
INNER JOIN COMPROBANTE C
        ON CC.IdComprobante = C.IdComprobante
ORDER BY CC.IdCompra;

-- 26. VENTAS REALIZADAS POR EMPLEADO
SELECT
    E.IdEmpleado,
    E.Nombre AS Empleado,
    E.Cargo,
    COUNT(V.IdVenta) AS CantidadVentas,
    ROUND(SUM(DV.Cantidad * DV.PrecioUnitario), 2) AS TotalVendido
FROM EMPLEADO E
INNER JOIN VENTA V
        ON E.IdEmpleado = V.IdEmpleado
INNER JOIN DETALLE_VENTA DV
        ON V.IdVenta = DV.IdVenta
GROUP BY E.IdEmpleado, E.Nombre, E.Cargo
ORDER BY TotalVendido DESC;

-- VALIDACIONES DE INTEGRIDAD
-- 27. Verifica que los montos de venta coincidan con los pagos.
SELECT
    V.IdVenta,
    DV.TotalVenta,
    PG.TotalPagado,
    CASE
        WHEN DV.TotalVenta = PG.TotalPagado
            THEN 'CORRECTO'
        ELSE 'REVISAR'
    END AS Validacion
FROM VENTA V

INNER JOIN (
    SELECT
        IdVenta,
        ROUND(SUM(Cantidad * PrecioUnitario), 2) AS TotalVenta
    FROM DETALLE_VENTA
    GROUP BY IdVenta
) DV
    ON V.IdVenta = DV.IdVenta

INNER JOIN (
    SELECT
        PV.IdVenta,
        ROUND(SUM(P.Monto), 2) AS TotalPagado
    FROM PAGO_VENTA PV
    INNER JOIN PAGO P
        ON PV.IdPago = P.IdPago
    GROUP BY PV.IdVenta
) PG
    ON V.IdVenta = PG.IdVenta

ORDER BY V.IdVenta;

-- 28. Verifica que compra, detalle y pago coincidan.
SELECT
    C.IdCompra,
    C.MontoTotal AS MontoCompra,
    ROUND(SUM(DC.Cantidad * DC.PrecioCompra), 2) AS TotalDetalle,
    P.Monto AS MontoPagado,
    CASE
        WHEN C.MontoTotal = ROUND(SUM(DC.Cantidad * DC.PrecioCompra), 2)
         AND C.MontoTotal = P.Monto
            THEN 'CORRECTO'
        ELSE 'REVISAR'
    END AS Validacion
FROM COMPRA C
INNER JOIN DETALLE_COMPRA DC
        ON C.IdCompra = DC.IdCompra
INNER JOIN PAGO_COMPRA PC
        ON C.IdCompra = PC.IdCompra
INNER JOIN PAGO P
        ON PC.IdPago = P.IdPago
GROUP BY C.IdCompra, C.MontoTotal, P.Monto
ORDER BY C.IdCompra;

-- 29. Conteo final de registros por tabla.
SELECT 'CLIENTE' AS Tabla, COUNT(*) AS Registros FROM CLIENTE
UNION ALL SELECT 'CLIENTE_NATURAL', COUNT(*) FROM CLIENTE_NATURAL
UNION ALL SELECT 'CLIENTE_EMPRESA', COUNT(*) FROM CLIENTE_EMPRESA
UNION ALL SELECT 'EMPLEADO', COUNT(*) FROM EMPLEADO
UNION ALL SELECT 'CATEGORIA', COUNT(*) FROM CATEGORIA
UNION ALL SELECT 'MARCA_VEHICULO', COUNT(*) FROM MARCA_VEHICULO
UNION ALL SELECT 'MODELO_VEHICULO', COUNT(*) FROM MODELO_VEHICULO
UNION ALL SELECT 'PRODUCTO', COUNT(*) FROM PRODUCTO
UNION ALL SELECT 'COMPATIBILIDAD', COUNT(*) FROM COMPATIBILIDAD
UNION ALL SELECT 'PROVEEDOR', COUNT(*) FROM PROVEEDOR
UNION ALL SELECT 'VENTA', COUNT(*) FROM VENTA
UNION ALL SELECT 'DETALLE_VENTA', COUNT(*) FROM DETALLE_VENTA
UNION ALL SELECT 'COMPRA', COUNT(*) FROM COMPRA
UNION ALL SELECT 'DETALLE_COMPRA', COUNT(*) FROM DETALLE_COMPRA
UNION ALL SELECT 'PAGO', COUNT(*) FROM PAGO
UNION ALL SELECT 'PAGO_VENTA', COUNT(*) FROM PAGO_VENTA
UNION ALL SELECT 'PAGO_COMPRA', COUNT(*) FROM PAGO_COMPRA
UNION ALL SELECT 'COMPROBANTE', COUNT(*) FROM COMPROBANTE
UNION ALL SELECT 'COMPROBANTE_VENTA', COUNT(*) FROM COMPROBANTE_VENTA
UNION ALL SELECT 'COMPROBANTE_COMPRA', COUNT(*) FROM COMPROBANTE_COMPRA;


