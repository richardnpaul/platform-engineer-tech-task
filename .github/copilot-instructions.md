# Platform Engineer Tech Task – AI Guide

## Architecture & Code Layout

- Spring Boot 3.5 app (`src/main/java/com/example/demo`) with a single `HelloController` under `/api/hello`; keep new endpoints under `/api` to align with routing + MockMvc tests.
- Actuator + Prometheus metrics already wired via `spring-boot-starter-actuator` and `micrometer-registry-prometheus`; `/actuator/prometheus` is assumed live for Helm probes, so avoid changing the path without updating `helm/templates/deployment.yaml`.
- `application.yml` turns on `management.endpoint.health.probes.enabled`; readiness/liveness hit `/actuator/health/{readiness,liveness}`, so reuse those for additional components.
- Tests live in `src/test/java/com/example/demo`; follow the pattern of `@WebMvcTest` + `MockMvc` (`HelloControllerTest`) for slice tests and `@SpringBootTest` for context-level checks.

## Build & Test Workflow

- Use the Gradle wrapper (`./gradlew ...`) with the Java 21 toolchain already pinned in `build.gradle`.
- `./gradlew test` is the authoritative verification step (mirrors `.github/workflows/ci.yml`). Add new tests before modifying the workflow.
- `./gradlew bootRun` is the quickest dev loop; the native toolchain is optional.
- Native executable path: `./gradlew nativeCompile` -> `build/native/nativeCompile/myservice`. Keep binary name in sync with `graalvmNative.binaries.main.imageName`.
- OCI image path: `./gradlew bootBuildImage --imageName=<repo>:<tag>`; `build.gradle` defaults to `myservice:0.0.1-native` with the Paketo tiny builder + `BP_NATIVE_IMAGE=true`.

## Container & Deployment Flow

- Dockerfile performs a GraalVM native build stage followed by a `distroless/base-debian12` runtime; any new native dependencies must be copied like the existing `libz` entries.
- Default port is 8080; the Dockerfile exposes it and Helm Service maps cluster port→8080.
- Helm chart (`helm/`) expects the native image tag (`values.yaml` -> `image.tag: 0.0.1-native`). Update both `values.yaml` and `build.gradle` imageName/tag together.
- `values-minikube.yaml` switches to a local image with `pullPolicy: Never` for `minikube image load` workflows; keep overrides minimal so it stays a drop-in.
- Deployment template injects Prometheus scrape annotations behind `metrics.enabled`. If you disable metrics at build time, also turn this flag off to avoid scraping failures.

## Infrastructure & Env Notes

- `terraform/` and `terragrunt/` are placeholders—do not assume tooling exists. Document any new IaC modules you add there.
- No existing README; surface critical operational notes inside this file or inline code comments sparingly.
- CI only runs unit tests. Include commands or scripts in PR descriptions if additional validation (native builds, Docker, Helm lint) is needed until workflows expand.
- Keep configuration ASCII-only unless a file already uses Unicode. Project name is `myservice` (`settings.gradle`) and is reused by Helm helpers and Docker artefacts—update consistently.
