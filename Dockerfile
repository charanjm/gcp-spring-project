# Use the official OpenJDK image
FROM openjdk:17-jdk-alpine

# Set the working directory
WORKDIR /app

# Copy the project jar file
COPY target/gcp-spring-project-0.0.1-SNAPSHOT.jar app.jar

# Expose the application port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
