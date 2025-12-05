# syntax=docker/dockerfile:1.6

# Build GraalVM native executable
FROM ghcr.io/graalvm/native-image-community:21 AS build
ENV JAVA_HOME=/usr/lib64/graalvm/graalvm-community-java21
ENV PATH="${JAVA_HOME}/bin:${PATH}"
WORKDIR /workspace

# Install required build tooling (zip needed by Gradle wrapper)
RUN microdnf install -y zip unzip findutils tar && microdnf clean all

# Install Gradle via wrapper download (requires JDK+curl) after copying sources
COPY gradlew gradlew.bat settings.gradle build.gradle gradle.properties ./
COPY gradle ./gradle
COPY src ./src

RUN chmod +x gradlew

# Build native executable (output in build/native/nativeCompile)
RUN ./gradlew --no-daemon clean nativeCompile

########################################
# Minimal runtime image (requires glibc)
########################################
FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /app

# Copy the native binary produced above
COPY --from=build /workspace/build/native/nativeCompile/myservice ./myservice

# Copy zlib dependency (soname + actual shared object) into common search paths
COPY --from=build /lib64/libz.so.1 /lib64/libz.so.1
COPY --from=build /lib64/libz.so.1.2.11 /lib64/libz.so.1.2.11
COPY --from=build /lib64/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=build /lib64/libz.so.1.2.11 /lib/x86_64-linux-gnu/libz.so.1.2.11

USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["./myservice"]
