# Build inside the image so the laptop's JDK doesn't matter; tests run
# outside (mvn test: they start their own database containers).
FROM maven:3.9.16-eclipse-temurin-25-noble AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:25.0.4_7-jre-noble
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin orders
COPY --from=build /src/target/orders.jar /app/orders.jar
USER 10001
EXPOSE 8080
# Heap at 50% of the container's memory limit leaves room for metaspace,
# thread stacks, direct buffers and the rest of the JVM: about 215 MiB at
# peak. At 60% of 512 MiB a pod was OOMKilled when requests piled up during
# a failover (runbook 26, 2026-10-30).
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=50", "-Duser.timezone=UTC", "-jar", "/app/orders.jar"]
