Name: nestjs-best-practices

Description: Reglas de buenas prácticas y patrones de arquitectura NestJS para evaluar, revisar y refactorizar el código del backend. Valida la cohesión modular, la inyección de dependencias, la seguridad con JWT, el uso de Prisma ORM y la comunicación estricta entre capas funcionales.

Metadata:
  Version: "1.1.0"
---

# 🛠️ Guía de Buenas Prácticas y Skill de Validación - Backend (NestJS)

Este documento establece los estándares de calidad de código, reglas de diseño de software y criterios estrictos de revisión (MUST/SHOULD) aplicados al desarrollo del ecosistema backend del proyecto.

---

## 1. Definición Detallada de la Arquitectura y Dependencias

El backend está estructurado bajo una **Arquitectura Modular Basada en Características (Feature-Based Architecture)**. Se prohíbe la organización horizontal tradicional por capas técnicas genéricas independientes. En su lugar, el sistema se compone de módulos verticales autónomos y altamente cohesivos.

### 🔄 Flujo de Comunicación Interna por Capas
Cada módulo funcional está aislado y respeta un flujo unidireccional estricto dividido en tres niveles de responsabilidad:

1.  **Capa de Entrada (Controladores - `Controllers`):** Interceptan las peticiones HTTP externas, gestionan los endpoints y delegan la ejecución de manera inmediata. No contienen lógica de negocio.
2.  **Capa de Negocio (Servicios - `Services`):** Orquestan la lógica del sistema, aplican validaciones de estados y mutan los datos según las reglas requeridas.
3.  **Capa de Acceso a Datos (Prisma ORM):** Abstracción tipo-segura encargada de interactuar directamente con la base de datos PostgreSQL de manera centralizada.

```text
┌────────────────────────────────────────────────────────┐
│               Petición HTTP del Cliente                │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│             Controladores (tasks.controller)           │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│              Servicios (tasks.service)                 │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│         Prisma ORM / Database (PostgreSQL)             │
└────────────────────────────────────────────────────────┘
```

### 📊 Matriz de Dependencias entre Módulos
Para garantizar que **no exista acoplamiento circular**, el mapa de importaciones en NestJS está estrictamente controlado bajo las siguientes directrices:

| Desde Módulo | Hacia Módulo | Propósito y Conectividad |
| :--- | :--- | :--- |
| `AppModule` | `UsersModule` | Registra y expone el módulo de gestión de usuarios en la raíz. |
| `AppModule` | `TasksModule` | Registra y expone el módulo de control de tareas en la raíz. |
| `AppModule` | `AuthModule` | Registra y expone el flujo de seguridad y sesiones. |
| `AppModule` | `PostulationsModule` | Registra el flujo relacional de postulaciones. |
| `AppModule` | `PrismaModule` | Instancia de conexión compartida para el ciclo de vida del servidor. |
| `UsersModule` | `PrismaModule` | Permite a `UsersService` persistir cuentas utilizando el cliente de Prisma. |
| `TasksModule` | `PrismaModule` | Permite a `TasksService` persistir tareas e historiales de estados. |
| `AuthModule` | `PrismaModule` | Valida credenciales contra las entidades de la base de datos. |
| `AuthModule` | `JwtModule` | Sella, firma y descifra los tokens de sesión seguros para las Guards. |

---

## 🚦 2. Criterios de Revisión: MUST Have y SHOULD Have

### 🏛️ Arquitectura Modular (`arch-`)
#### `arch-avoid-circular-deps`
* **Clasificación:** 🔴 **MUST HAVE**
* **Descripción:** Queda estrictamente prohibido el acoplamiento circular directo o indirecto entre módulos funcionales. Cada característica debe resolverse de forma aislada.
* **❌ Mala Práctica:**
    ```typescript
    // En tasks.module.ts
    @Module({ imports: [forwardRef(() => UsersModule)] })
    export class TasksModule {}
    ```
* **✅ Buena Práctica:**
    ```typescript
    // En tasks.module.ts compartiendo únicamente acceso desacoplado mediante PrismaModule
    @Module({
      imports: [PrismaModule],
      controllers: [TasksController],
      providers: [TasksService],
    })
    export class TasksModule {}
    ```

---

### 💉 Inyección de Dependencias (`di-`)
#### `di-prefer-constructor-injection`
* **Clasificación:** 🔴 **MUST HAVE**
* **Descripción:** La resolución de dependencias debe realizarse de forma obligatoria mediante la declaración explícita en el constructor de la clase utilizando `private readonly`. Queda prohibido usar `@Inject()` de propiedades o llamadas directas en tiempo de ejecución.
* **❌ Mala Práctica:**
    ```typescript
    export class TasksService {
      @Inject(PrismaService)
      private prisma: PrismaService;
    }
    ```
* **✅ Buena Práctica:**
    ```typescript
    export class TasksService {
      constructor(private readonly prisma: PrismaService) {}
    }
    ```

---

### 🛡️ Seguridad y Validaciones (`security-`)
#### `security-validate-all-input`
* **Clasificación:** 🔴 **MUST HAVE**
* **Descripción:** Todos los endpoints expuestos que reciban un cuerpo de petición (`@Body()`) deben validar sus propiedades en tiempo de ejecución utilizando `class-validator` mediante Data Transfer Objects (DTOs) tipados. Los servicios deben aplicar `.trim()` en strings críticos para sanitizar los campos.
* **❌ Mala Práctica:**
    ```typescript
    @Post()
    async create(@Body() rawData: any) {
      return this.tasksService.create(rawData);
    }
    ```
* **✅ Buena Práctica:**
    ```typescript
    export class CreateTaskDto {
      @IsString()
      @IsNotEmpty({ message: 'Title is required' })
      title: string;

      @IsNumber()
      @Min(1, { message: 'Amount must be greater than zero' })
      amount: number;
    }
    ```

---

### 🧪 Pruebas Unitarias (`test-`)
#### `test-mock-external-services`
* **Clasificación:** 🔴 **MUST HAVE**
* **Descripción:** **REGLA ACADÉMICA CRÍTICA.** Queda terminantemente prohibido realizar escrituras, modificaciones o lecturas reales en la base de datos PostgreSQL durante la ejecución de pruebas unitarias. Toda interacción de datos con la capa ORM debe simularse abstrayendo el comportamiento mediante objetos mock resueltos (`prismaMock`).
* **❌ Mala Práctica:**
    ```typescript
    it('should create a task', async () => {
      const res = await realPrismaService.task.create({ data: taskDto });
      expect(res.id).toBeDefined();
    });
    ```
* **✅ Buena Práctica:**
    ```typescript
    it('should create a task without hitting the database', async () => {
      const mockResult = { id: 1, title: 'Walk the dog', amount: 20 };
      (prismaMock.task.create as any).mockResolvedValue(mockResult);

      const result = await service.create(validTaskDto);
      expect(result.amount).toEqual(20);
      expect(prismaMock.task.create).toHaveBeenCalled();
    });
    ```

---

## 📈 3. Evidencias de Cumplimiento

Todas las directrices estipuladas en esta matriz se comprueban de manera determinista mediante las herramientas automatizadas del repositorio:

1.  **Validación de Estilo y Reglas Estáticas (Linter):** Gestionado a través de **ESLint**, asegurando la inexistencia de código muerto o fallas de arquitectura estricta.
2.  **Validación Funcional Límite (Testing Unitario):** Controlado a través de **Jest**. La suite del backend ejecuta de manera exitosa los casos de prueba blindados:
    * **Test Suites:** 9 pasadas con éxito.
    * **Casos Unitarios:** Evaluación exhaustiva de datos extremos (valores inválidos, límites inferiores a cero, inputs vacíos con espaciado, y transiciones de estados lógicos controlados).

---

## 🚀 Cómo Aplicar este Skill (`How to use`)

* **Durante el desarrollo local:** Ejecute de forma preventiva `npx prisma generate` ante cambios en esquemas para mantener los tipados alineados con los modelos estáticos del proyecto.
* **Antes de realizar un Commit/Push:** Corra localmente la suite de análisis de código y testing unificado para certificar que el casillero se mantiene libre de fallas en consola:
    ```bash
    npm run test
    ```
