# -------- Stage 1: Build --------
FROM maven:3.9.9-eclipse-temurin-21-alpine AS builder
WORKDIR /app

# Cache Maven dependencies
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests

<<<<<<< HEAD
# -------- Stage 2: Runtime ---------
=======
# -------- Stage 2: Runtime -----------
>>>>>>> eebb415c3bd5aee9a49d6ae4085b89967087ec05
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy only the built jar
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 9000
ENTRYPOINT ["java", "-jar", "app.jar"]