# ADR 0004: Service Locator for Dependency Injection

## Status
Accepted

## Context
`main.dart` was bloated with manual engine registrations and instantiation of repositories and services. This made it difficult to manage dependencies cleanly and caused runtime issues when background isolates (like the persistent notification handler) needed to access database helpers or repositories without mounting the Flutter widget tree.

## Decision
We decided to adopt a Service Locator pattern using `GetIt`:
1. **Service Locator Setup**: Centralize all registrations in `service_locator.dart`.
2. **App Bootstrapper**: Implement `AppBootstrapper` containing `init()` to register all core singletons.
3. **Isolate Compatibility**: The bootstrapper's initializer must be decoupled from UI bindings (`WidgetsFlutterBinding`) and `runApp`, allowing background threads and Kotlin notification actions to load database/logic dependencies cleanly without throwing UI thread errors.
4. **Retrieve via Locator**: Access singletons using `GetIt.I<T>()` rather than static global instances.

## Consequences
### Positive
* Isolate Safety: Background isolates can boot up and register their own DB/Service connections cleanly.
* Decoupling: UI widgets can retrieve logic controllers via GetIt instead of chaining instances down the widget tree.
* Testability: We can register mock implementations in our test suites easily.

### Negative
* Runtime Resolution: If a class is not registered before retrieval, it will throw a `GetItNotInitializedException` at runtime (prevented by strict test coverage).

## Alternatives Considered
* *Provider / InheritedWidget DI*: Rejected because Providers are bound to the Flutter Widget Tree, making them inaccessible from background Isolates (which run headless without a widget tree).
