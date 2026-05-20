
# SHRTN — Shortener Module (`url-shortener-shortener`)

Este módulo serverless expone la lógica transaccional de negocio para **la generación y el registro de enlaces acortados**. Se encarga de recibir URLs extensas enviadas por clientes autenticados, validar su identidad de forma segura mediante criptografía nativa, estructurar el esquema de datos indexado y salvar el registro vinculándolo directamente al usuario propietario en la base de datos central.

---

## 🔒 Seguridad e Identidad (Validación JWT Semicustom)

Para asegurar un consumo ligero y de bajo impacto en el tiempo de arranque en frío (*cold start*) de AWS Lambda, la función procesa las cabeceras de autorización de la siguiente manera:

* **Intercepción CORS:** Responde inmediatamente con un estado `204 (No Content)` ante llamadas del tipo `OPTIONS` inyectando las cabeceras `Access-Control-Allow-*` requeridas.
* **Verificación de Firma Criptográfica:** Extrae el token tipo *Bearer* de la cabecera `Authorization` y reconstruye síncronamente la firma digital utilizando el módulo nativo `crypto` de Node.js y la variable `JWT_SECRET`.
* **Gobernanza del Token:** Evalúa la caducidad del payload extraído (`exp`) y, si es legítimo, asocia el atributo `username` al registro de base de datos como llave de auditoría.

---

## 📂 Estructura del Módulo

El componente organiza sus artefactos y recetas Terraform de forma modular:

```text
C:\CODE PROJECTS\URL-SHORTENER\MODULES\URL-SHORTENER-SHORTENER
│   .env                      <-- Configuración de entorno local
│   .gitignore
│   README.md                 <-- (Este archivo)
│
├───src                       <-- LÓGICA DE NEGOCIO (Node.js)
│       index.js              <-- Validaciones de firma, generación aleatoria y PutCommand
│       package.json          <-- Manifiesto con las dependencias del SDK v3 de AWS
│
└───terraform                 <-- CAPA DE INFRAESTRUCTURA SOLITARIA
        main.tf               <-- Empaquetado zip, declaración de Lambda e integraciones de API Gateway
        outputs.tf
        providers.tf
        terraform.tfstate
        terraform.tfstate.backup
        terraform.tfvars
        variables.tf
        lambda_function.zip   <-- Código fuente empaquetado para despliegue

```

---

## ⚡ Estructura del Documento Registrado

Cada vez que se procesa una solicitud exitosa a través de un comando `PutCommand`, el microservicio inicializa y persiste un objeto estructurado en **Amazon DynamoDB** con el siguiente esquema:

```json
{
  "short_code": "XyZ123",      // Hash de 6 caracteres (Llave primaria / Hash Key)
  "long_url": "https://...",   // URL destino original
  "user_id": "nombre_usuario", // Propietario extraído del JWT (Garantiza autoría)
  "created_at": "ISO_String",  // Fecha exacta de creación
  "clicks": 0,                 // Inicializador de métricas globales
  "visit_history": []          // Vector vacío listo para recibir timestamps de visitas
}

```

---

## ⚙️ Variables de Entorno Requeridas

Las siguientes variables son inyectadas dinámicamente en el entorno de AWS Lambda mediante las declaraciones del archivo `main.tf`:

| Variable | Descripción | Origen / Ejemplo |
| --- | --- | --- |
| `DYNAMODB_TABLE` | Nombre de la tabla global de almacenamiento de enlaces. | *Provisto desde los outputs del módulo `/shared*` |
| `JWT_SECRET` | Semilla secreta utilizada para validar la legitimidad de las firmas. | *Compartida por la capa de configuración global* |

---

## 🚀 Despliegue e Integración

> ⚠️ **Nota:** Este módulo requiere que la tabla de DynamoDB (definida en el bloque `/shared` de la raíz) esté previamente aprovisionada.

1. **Descargar módulos requeridos:**
Múdate a la carpeta de código e instala los binarios necesarios:
```bash
cd src
npm install

```


2. **Aplicar cambios de infraestructura:**
Navega a la carpeta de infraestructura paralela para compilar y desplegar:
```bash
cd ../terraform
terraform init
terraform apply

```


3. **Consumo del Endpoint:**
Al finalizar, el API Gateway expondrá el endpoint protegido para la creación de enlaces cortos (ej: `POST /shorten`). Toda llamada exitosa retornará una estructura `201 Created` con el `short_code` generado y el enlace completo apuntando al subdominio de redirección `/r/`.
