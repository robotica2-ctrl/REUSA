# ReUsa — marketplace de alquiler de objetos

Aplicación React + Vite conectada a Supabase para autenticación, publicaciones, solicitudes de alquiler y fotos.

## Requisitos
- Node.js 20 o superior (recomendado).
- Una cuenta/proyecto en Supabase.
- Visual Studio Code (opcional).

## 1. Instalar dependencias
En una terminal abierta en la carpeta del proyecto:

```bash
npm install
```

## 2. Crear las tablas y el almacenamiento en Supabase
1. Abre tu proyecto en Supabase.
2. Entra a **SQL Editor** y crea una consulta nueva.
3. Copia y ejecuta el contenido de `supabase-setup.sql`.
4. En **Authentication > URL Configuration**, configura la URL local `http://localhost:5173` como URL de desarrollo o redirección permitida.
5. Para pruebas, puedes desactivar temporalmente la confirmación de correo en **Authentication > Providers > Email**. Para producción, es preferible mantenerla activada y configurar el correo.

El SQL crea `listings`, `rentals`, las políticas RLS y el bucket público `product-photos`. Las fotografías son públicas para que el catálogo pueda mostrarlas; solo el usuario autenticado puede subir archivos a la carpeta que lleva su propio ID.

## 3. Configurar las credenciales
1. En Supabase abre **Project Settings > API** (o **Connect**, según la interfaz).
2. Copia la **Project URL** y la clave **publishable** (o `anon` legacy).
3. Duplica `.env.example` y nombra la copia `.env.local`.
4. Reemplaza los valores de ejemplo:

```env
VITE_SUPABASE_URL=https://TU-PROYECTO.supabase.co
VITE_SUPABASE_ANON_KEY=TU_CLAVE_PUBLICABLE
```

No uses la clave `service_role` en React ni la compartas en el navegador. Vite solo expone las variables que empiezan con `VITE_`.

## 4. Ejecutar

```bash
npm run dev
```

Abre la dirección que muestre Vite, normalmente `http://localhost:5173`.

## Qué se guarda en Supabase
- **Authentication:** cuentas y contraseñas (gestionadas por Supabase; la aplicación no guarda contraseñas propias).
- **Database / `listings`:** título, categoría, precio diario, ubicación, descripción, propietario y URL de la foto.
- **Storage / `product-photos`:** archivo de imagen comprimido.
- **Database / `rentals`:** fechas, días, total, comisión calculada del 15 %, neto estimado del 85 % y estado de la solicitud.

## Alcance y limitaciones
- Las solicitudes y el reparto 15 % / 85 % son de demostración. No se cobra dinero ni se realizan transferencias.
- La comisión se calcula en el navegador; antes de operar con dinero real, debe calcularse y validarse en una función de servidor y conectarse una pasarela de pagos adecuada.
- El bucket de imágenes es público. No subas documentos de identidad ni fotografías privadas.
- Los productos de demostración anteriores no se migran automáticamente. Tras configurar Supabase, el catálogo mostrará los registros de la base de datos.
- No existe aún prevención de reservas solapadas, verificación de identidad, mensajería ni gestión de disputas.
