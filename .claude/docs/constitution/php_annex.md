# Constitution Annex: PHP Language Implementation Details

**Scope**: All PHP (Lumen/Laravel) backend projects
**Constitution Version**: 2.0+

This annex defines the specific execution standards for the [Project Development Constitution](../../constitution.md) in PHP projects.

---

## 1. Simplicity Principle Implementation
- **1.1 Framework First**: Prioritize Lumen/Laravel built-in capabilities; avoid custom implementations.
- **1.2 Dependency Management**: Strictly prohibit manual vendor modifications. Use `composer` properly.

## 2. Testing Quality Implementation
- **2.1 PHPUnit**: Unit tests **MUST** use PHPUnit framework.
- **2.2 Mocking**: Use `Mockery` for mocking dependencies.
- **2.3 Service Layer Testing**: All service layer methods must have test coverage.

## 3. Clarity Principle Implementation
- **3.1 Error Handling**:
    - **Custom Exceptions**: Prefer custom exceptions over `die`/`exit`/`dd`.
    - **Logging**: Follow project logging standards.
    - **Type Safety**: Use PHP 7+ type annotations (scalar types, return types). Use PHPDoc for unsupported types.
- **3.2 Dependency Injection**: All dependencies must use constructor injection. Never use `new` in business logic.
- **3.3 PHPDoc**: Follow PHPDoc conventions for documentation.

## 4. Code Style & Structure
- **4.1 PSR Compliance**: Code must follow PSR-12 coding standards.
- **4.2 Naming Conventions**:
    - Classes: PascalCase
    - Methods: camelCase
    - DB Fields: snake_case
    - Arrays: Short syntax `[]`
- **4.3 Architecture**:
    - **Controller**: Only handles request/response, no business logic.
    - **Service**: Business logic.
    - **Model**: Eloquent definitions only.
- **4.4 File Limits**: 
    - Single file recommended < 200 lines.
    - Single method recommended < 20 lines.

## 5. Architecture Patterns
- **5.1 ETL Pattern**: Data processing follows `Query` -> `Clean` -> `Export` pipeline.
- **5.2 Eloquent First**: Prefer Eloquent ORM over raw SQL.
- **5.3 Helper Functions**: Use built-in helper functions appropriately.
