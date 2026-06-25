Name: nestjs-best-practices

Description: Best practices and architecture rules for NestJS to evaluate, review, and refactor backend code. Validates modular cohesion, dependency injection, JWT security, Prisma ORM usage, and strict communication between functional layers.

Metadata:
Version: "1.1.0"

---

# 🛠️ Backend Validation Skill and Best Practices Guide (NestJS)

This document defines the code quality standards, software design rules, and strict review criteria (MUST/SHOULD) applied to the backend ecosystem of the project.

---

## 1. Detailed Architecture and Dependency Definition

The backend follows a **Feature-Based Modular Architecture**. Traditional horizontal organization by generic technical layers is prohibited. Instead, the system is composed of autonomous, highly cohesive vertical feature modules.

### 🔄 Internal Layer Communication Flow

Each functional module is isolated and follows a strict one-way communication flow divided into three responsibility levels:

1. **Entry Layer (Controllers):** Handle incoming HTTP requests, expose endpoints, and immediately delegate execution. Controllers must not contain business logic.
2. **Business Layer (Services):** Orchestrate business rules, validate state transitions, and apply all required business logic.
3. **Data Access Layer (Prisma ORM):** Type-safe abstraction responsible for centralized interaction with the PostgreSQL database.

```text
┌────────────────────────────────────────────────────────┐
│               Client HTTP Request                      │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│            Controllers (tasks.controller)              │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│             Services (tasks.service)                   │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│         Prisma ORM / Database (PostgreSQL)             │
└────────────────────────────────────────────────────────┘
```

### 📊 Module Dependency Matrix

To guarantee that **no circular dependencies exist**, NestJS module imports must strictly follow the rules below:

| From Module   | To Module            | Purpose and Connectivity                                                      |
| :------------ | :------------------- | :---------------------------------------------------------------------------- |
| `AppModule`   | `UsersModule`        | Registers and exposes the user management module in the application root.     |
| `AppModule`   | `TasksModule`        | Registers and exposes the task management module in the application root.     |
| `AppModule`   | `AuthModule`         | Registers and exposes authentication and security flows.                      |
| `AppModule`   | `PostulationsModule` | Registers the postulations feature module.                                    |
| `AppModule`   | `PrismaModule`       | Provides the shared database connection throughout the application lifecycle. |
| `UsersModule` | `PrismaModule`       | Allows `UsersService` to persist user data through Prisma.                    |
| `TasksModule` | `PrismaModule`       | Allows `TasksService` to persist tasks and task state history.                |
| `AuthModule`  | `PrismaModule`       | Validates credentials against database entities.                              |
| `AuthModule`  | `JwtModule`          | Signs, verifies, and decodes secure JWT tokens for authentication guards.     |

---

## 🚦 2. Review Criteria: MUST Have and SHOULD Have

### 🏛️ Modular Architecture (`arch-`)

#### `arch-avoid-circular-deps`

* **Classification:** 🔴 **MUST HAVE**
* **Description:** Direct or indirect circular dependencies between functional modules are strictly prohibited. Every feature must remain isolated.
* **❌ Bad Practice:**

```typescript
// tasks.module.ts
@Module({ imports: [forwardRef(() => UsersModule)] })
export class TasksModule {}
```

* **✅ Good Practice:**

```typescript
// tasks.module.ts
@Module({
  imports: [PrismaModule],
  controllers: [TasksController],
  providers: [TasksService],
})
export class TasksModule {}
```

---

### 💉 Dependency Injection (`di-`)

#### `di-prefer-constructor-injection`

* **Classification:** 🔴 **MUST HAVE**

* **Description:** Dependencies must always be injected explicitly through the constructor using `private readonly`. Property injection using `@Inject()` or runtime dependency resolution is prohibited.

* **❌ Bad Practice:**

```typescript
export class TasksService {
  @Inject(PrismaService)
  private prisma: PrismaService;
}
```

* **✅ Good Practice:**

```typescript
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}
}
```

---

### 🛡️ Security and Validation (`security-`)

#### `security-validate-all-input`

* **Classification:** 🔴 **MUST HAVE**

* **Description:** Every endpoint receiving a request body (`@Body()`) must validate input using typed DTOs with `class-validator`. Services must sanitize critical string fields using `.trim()`.

* **❌ Bad Practice:**

```typescript
@Post()
async create(@Body() rawData: any) {
  return this.tasksService.create(rawData);
}
```

* **✅ Good Practice:**

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

### 🧪 Unit Testing (`test-`)

#### `test-mock-external-services`

* **Classification:** 🔴 **MUST HAVE**

* **Description:** **CRITICAL ACADEMIC RULE.** Reading from or writing to the real PostgreSQL database during unit testing is strictly prohibited. Every ORM interaction must be simulated using resolved mocks (`prismaMock`).

* **❌ Bad Practice:**

```typescript
it('should create a task', async () => {
  const res = await realPrismaService.task.create({ data: taskDto });
  expect(res.id).toBeDefined();
});
```

* **✅ Good Practice:**

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

## 📈 3. Compliance Evidence

All rules defined in this skill must be verified deterministically using the repository's automated tools.

1. **Static Analysis (Linter):** Managed through **ESLint**, ensuring the absence of dead code and architectural violations.
2. **Unit Testing:** Managed through **Jest**. The backend test suite must successfully execute:

   * **Test Suites:** 9 passing.
   * **Unit Tests:** Comprehensive validation of boundary cases, invalid values, negative limits, empty or whitespace-only inputs, and controlled logical state transitions.

---

## 🧠 4. Skill Verification Rules (MANDATORY)

Every evaluation must comply with the following requirements:

1. Compliance must never be inferred from project structure or file names.
2. Every MUST rule must be validated with direct evidence from the source code.
3. Every finding must include:

   * Exact file
   * Relevant code fragment
   * Short technical explanation
4. If direct evidence cannot be found:

   * Mark the rule as **❌ NOT VERIFIABLE**
5. The following expressions are prohibited:

   * "assumed"
   * "probably"
   * "suggests"
   * "inferred"
6. The evaluator must behave as a code auditor, not as a structural analyst.

---

## 📊 5. Produce the Review Report

### Severity Levels

* **MUST FIX (Blocking)** — Circular dependencies between modules, business logic inside controllers, property injection using `@Inject()`, missing DTO validation with `class-validator`, missing `.trim()` on critical string fields, direct database access during unit tests instead of `prismaMock`.

* **SHOULD FIX (Non-blocking)** — Inconsistent module organization, missing `private readonly` in constructor injection, inconsistent response structure, missing input sanitization on non-critical fields, incomplete unit test coverage for expected scenarios.

* **SUGGESTION** — Optional refactoring opportunities, naming consistency improvements, code readability enhancements, additional test cases for edge cases, documentation improvements.



### Output Format

Return **only** the structured report below. Do not include introductions, explanations, or narration.

#### Backend Review Report

* **Scope:** [Full audit / Local changes / PR #]
* **Files reviewed:** [count and list grouped by layer]

###### Architecture Compliance

| # | File:Line | Rule | Severity | Details |
| - | --------- | ---- | -------- | ------- |

##### Code Quality

| # | File:Line | Rule | Severity | Details |
| - | --------- | ---- | -------- | ------- |

##### Security

| # | File:Line | Rule | Severity | Details |
| - | --------- | ---- | -------- | ------- |

##### Testing

| # | File:Line | Rule | Severity | Details |
| - | --------- | ---- | -------- | ------- |

### Test coverage 
[expected vs found, gaps identified]

### Verdict

✅ APPROVED

🟡 APPROVED WITH OBSERVATIONS

🔴 CHANGES REQUIRED

### Summary

[1–2 sentence overall assessment]

---

## 🧠 6. Evaluator Execution Mode (MANDATORY)

This skill must be executed as a deterministic code auditing system.

The evaluator must strictly follow the workflow below.

---

### 1. Mandatory Skill Reading

* Read the entire `skill_back.md` file before performing any analysis.
* This file is the single source of truth for the evaluation.

---

### 2. Repository Analysis

* Analyze the entire backend repository.
* Do not limit the evaluation to isolated files or partial assumptions.

---

### 3. Rule-by-Rule Evaluation

* Every MUST and SHOULD rule must be evaluated individually.
* Generic or grouped evaluations are not allowed.

---

### 4. Mandatory Evidence

Every decision must include:

* Exact file
* Line number or relevant code fragment
* Short technical explanation based on the actual implementation

If no direct evidence exists:

→ Mark the rule as **❌ NOT VERIFIABLE**

---

### 5. Strict Prohibitions

* Do not infer compliance from project structure.
* Do not assume compliance based on file names.
* Do not use probabilistic language such as:

  * "appears"
  * "probably"
  * "inferred"
  * "suggests"

---

### 6. Evaluator Objective

The evaluator must behave as a senior NestJS backend auditor for production environments, not as a superficial architecture reviewer.

Its responsibility is to detect real implementation issues rather than apparent architectural patterns.

---

## 🚀 How to Use This Skill

* **During local development:** Run `npx prisma generate` whenever the Prisma schema changes to keep generated types synchronized.
* **Before every commit or push:** Execute the complete validation suite to ensure the project is free of code quality and testing issues.

```bash
npm run test
```
