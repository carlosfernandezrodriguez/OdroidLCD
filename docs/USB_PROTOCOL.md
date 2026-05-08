# Protocolo USB - ODROID VU7A Plus

## Información General del Dispositivo

### Identificadores USB
- **Vendor ID**: 0x16b4 (GOODIX Technology Co., Ltd.)
- **Product ID**: 0x0705 (VU7A Plus Touch Controller)
- **Clase**: HID (Human Interface Device)
- **Subclase**: Boot Interface
- **Protocolo**: Mouse

### Especificaciones de Conexión
- **Velocidad**: Full-Speed (12 Mbps)
- **Tipo de transferencia**: Interrupt
- **Interfaz**: Controlador táctil vía Micro-USB
- **Potencia**: 5V, ~100mA

## Estructura de Paquetes USB

### Tamaño de Paquete
- **Máximo de datos**: 64 bytes por paquete
- **Frecuencia de polling**: 10-20 ms (50-100 Hz)
- **Tiempo de respuesta**: Típicamente < 5 ms

### Formato General del Paquete

```
Byte 0: Tipo de paquete / Contador de puntos
Bytes 1-63: Datos de puntos táctiles
```

## Datos de Puntos Táctiles

### Formato por Punto Táctil (6 bytes)

```
+--------+--------+--------+--------+--------+--------+
| Byte 0 | Byte 1 | Byte 2 | Byte 3 | Byte 4 | Byte 5 |
+--------+--------+--------+--------+--------+--------+
| Touch  | X_High | X_Low  | Y_High | Y_Low  | Presión|
|  ID    |        |        |        |        |        |
+--------+--------+--------+--------+--------+--------+
```

### Descripción de Campos

**Byte 0 - Touch ID**: Identificador del punto (0-4)
- Rango: 0x00 - 0x04
- Valor especial 0xFF: Punto inactivo

**Bytes 1-2 - Coordenada X**: Posición X del punto (16 bits, big-endian)
- Rango: 0x0000 - 0xFFFF (0 - 65535)
- Fórmula: x_raw = (byte1 << 8) | byte2
- Mapeo de pantalla: 0-65535 → 0-1023 píxeles

**Bytes 3-4 - Coordenada Y**: Posición Y del punto (16 bits, big-endian)
- Rango: 0x0000 - 0xFFFF (0 - 65535)
- Fórmula: y_raw = (byte3 << 8) | byte4
- Mapeo de pantalla: 0-65535 → 0-599 píxeles

**Byte 5 - Presión**: Presión o área del contacto
- Rango: 0x00 - 0xFF (0 - 255)
- Valor 0x00: Contacto mínimo
- Valor 0xFF: Contacto máximo

## Ejemplos de Paquetes

### Ejemplo 1: 2 Puntos Táctiles

```
Byte 0: 0x02              # 2 puntos táctiles activos
Byte 1-6: 0x00 0x20 0x40 0x01 0x80 0xC0  # Punto 0
Byte 7-12: 0x01 0x40 0x80 0x02 0x00 0xD0 # Punto 1
```

Interpretación:
```
Punto 0:
  ID: 0x00
  X_raw: (0x20 << 8) | 0x40 = 0x2040 (8256)
  Y_raw: (0x01 << 8) | 0x80 = 0x0180 (384)
  Presión: 0xC0 (192)

Punto 1:
  ID: 0x01
  X_raw: (0x40 << 8) | 0x80 = 0x4080 (16512)
  Y_raw: (0x02 << 8) | 0x00 = 0x0200 (512)
  Presión: 0xD0 (208)
```

### Ejemplo 2: Sin Puntos Táctiles

```
Byte 0: 0x00              # Sin puntos táctiles activos
Bytes 1-63: 0x00          # Datos irrelevantes
```

## Transformación de Coordenadas

### Mapeado Bruto a Pantalla

Sin calibración (mapeado lineal simple):
```
x_pantalla = (x_raw * 1023) / 65535
y_pantalla = (y_raw * 599)  / 65535
```

Con calibración (transformación bilineal):
```
x_pantalla = (a * x_raw + b * y_raw + c) / 10000
y_pantalla = (d * x_raw + e * y_raw + f) / 10000
```

Donde a, b, c, d, e, f se calculan durante la calibración.

## Estados del Dispositivo

### Estados de Contacto

| Valor | Significado |
|-------|------------|
| 0x00-0x04 | Punto táctil activo con ID |
| 0xFF | Punto táctil inactivo/liberado |
| 0x00 (Byte 0) | Sin puntos táctiles activos |

## Protocolo de Comunicación

### Sentido de Comunicación

**Dispositivo → Host (Interrupt IN)**
- Endpoint: 0x81 (Interrupt In)
- Frecuencia: 10-20 ms
- Contenido: Datos de puntos táctiles

No hay comunicación **Host → Device** normal.

## Descriptores USB

### Descriptor de Dispositivo

```
Device Descriptor:
  bLength: 18
  bDescriptorType: DEVICE
  bcdUSB: 2.00
  bDeviceClass: 0
  bDeviceSubClass: 0
  bDeviceProtocol: 0
  bMaxPacketSize0: 64
  idVendor: 0x16b4
  idProduct: 0x0705
  bcdDevice: 0.0.1
  iManufacturer: 1
  iProduct: 2
  iSerialNumber: 0
  bNumConfigurations: 1
```

### Descriptor de Interfaz

```
Interface Descriptor:
  bLength: 9
  bDescriptorType: INTERFACE
  bInterfaceNumber: 0
  bAlternateSetting: 0
  bNumEndpoints: 1
  bInterfaceClass: 3 (HID)
  bInterfaceSubClass: 1 (Boot)
  bInterfaceProtocol: 2 (Mouse)
  iInterface: 3
```

### Descriptor de Endpoint

```
Endpoint Descriptor:
  bLength: 7
  bDescriptorType: ENDPOINT
  bEndpointAddress: 0x81 (IN)
  bmAttributes: 3 (Interrupt)
  wMaxPacketSize: 64
  bInterval: 10 ms
```

## Manejo de Errores

### Códigos de Error USB

| Código | Significado | Acción |
|--------|------------|--------|
| -ECONNRESET | Conexión reiniciada | Reintentear |
| -ENOENT | Dispositivo desconectado | Cancelar URB |
| -ESHUTDOWN | USB apagado | Cancelar URB |
| -ENODEV | Dispositivo no encontrado | Cancelar URB |

## Sincronización de Datos

### Formato de Frame

Cada paquete USB representa un frame con estado actual de todos los puntos:

```
Frame N:
  ├─ Byte 0: Número de puntos (0-5)
  ├─ Punto 0: Coordenadas + Presión
  ├─ Punto 1: Coordenadas + Presión
  ├─ Punto 2: Coordenadas + Presión
  ├─ Punto 3: Coordenadas + Presión
  └─ Punto 4: Coordenadas + Presión

Frame N+1: (20ms después)
  └─ ...
```

## Características Especiales

### Multi-Touch Tracking

El dispositivo proporciona tracking automático mediante Touch ID:
- Cada punto mantiene el mismo ID entre frames
- ID puede cambiar si el dispositivo reordena puntos
- ID 0xFF indica punto inactivo

### Presión/Area de Contacto

La presión indica:
- Fuerza del contacto
- Área de contacto aproximada
- Útil para detectar contacto accidental

## Compatibilidad

### Sistemas Operativos Soportados

- Linux (driver kernel personalizado)
- Android (con driver integrado)
- Windows (con driver genérico HID)
- macOS (con driver genérico HID)

## Debugging del Protocolo

### Captura de Tráfico USB

```bash
# Usar usbmon para capturar tráfico
sudo modprobe usbmon
cat /sys/kernel/debug/usb/usbmon/1u

# O usar Wireshark con plugin USB
wireshark
```

### Validación de Paquetes

Usar herramienta `diagnostic`:
```bash
sudo diagnostic -m
```

---

**Versión del Protocolo**: 1.0
**Dispositivo**: ODROID VU7A Plus
**Última actualización**: 2026-05-08
