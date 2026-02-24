# Constitution Annex: Python Language Implementation Details

**Scope**: All Python backend projects
**Constitution Version**: 2.0+

This annex defines the specific execution standards for the [Project Development Constitution](../../constitution.md) in Python projects.

---

## 1. Simplicity Principle Implementation
- **1.1 Stdlib First**: Outside framework constraints, prioritize Python standard library.
- **1.2 Dependency Management**: Strictly prohibit introducing unused dependencies. Use `pip freeze` or `poetry` to keep clean.

## 2. Testing Quality Implementation
- **2.1 Pytest Parametrization**: Unit tests **MUST** use pytest parametrization for multiple test cases.
- **2.2 Framework Selection**: 
    - Unit tests: `pytest` (preferred) or `unittest`.
    - Mock: Use `unittest.mock` or `pytest-mock` for mocking.
- **2.3 Async Testing**: Async code must be tested with `pytest-asyncio`.

## 3. Clarity Principle Implementation
- **3.1 Error Handling**:
    - **Prohibited**: Strictly forbid bare `except:` clauses.
    - **Exception Chaining**: Use `raise ... from err` to preserve exception chains.
    - **Fail Fast**: Validate inputs early and raise exceptions immediately.
- **3.2 Dependency Injection**: All dependencies (DB, Cache, Config) must be passed through function parameters or class constructors; strictly prohibit global variables.
- **3.3 Docstrings**: Functions and classes must have docstrings following PEP 257 conventions.

## 4. Code Style & Structure
- **4.1 Formatting**: Mandatory use of `black` and `isort` for formatting and import sorting.
- **4.2 Async Model**: 
    - Use `asyncio` or `asyncio.TaskGroup` for concurrency.
    - Use `asyncio.sleep()` instead of blocking `time.sleep()` in async code.
    - Always pass context for timeout and cancellation control.
- **4.3 Type Hints**: Use type hints for function parameters and return types.
- **4.4 File Limits**: 
    - Single file recommended < 200 lines.
    - Single function recommended < 20 lines.

## 5. Architecture Patterns
- **5.1 ETL Pattern**: Data processing follows `Query` -> `Clean` -> `Export` pipeline.
- **5.2 Optimistic Locking**: Handle concurrent updates with version checks.
- **5.3 Modular Design**: Keep modules focused and loosely coupled.
