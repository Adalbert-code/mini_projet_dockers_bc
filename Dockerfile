# Base image: Amazon Corretto 17 Alpine (spécifié dans l'énoncé)
FROM amazoncorretto:17-alpine

# Métadonnées
LABEL maintainer="PayMyBuddy Team"
LABEL description="PayMyBuddy Spring Boot Application - Financial Transaction Management"
LABEL version="1.0"

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -S spring && adduser -S spring -G spring

# Répertoire de travail
WORKDIR /app

# Copier le JAR de l'application
COPY target/paymybuddy.jar app.jar

# Changer le propriétaire du fichier pour l'utilisateur spring
RUN chown spring:spring app.jar

# Passer à l'utilisateur non-root
USER spring

# Exposer le port 8080 (spécifié dans l'énoncé)
EXPOSE 8080

# Health check to ensure container is running properly
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1
# Variables d'environnement avec valeurs par défaut
# Ces valeurs seront overridées par docker-compose ou .env
ENV SPRING_DATASOURCE_URL=jdbc:mysql://paymybuddy-db:3306/db_paymybuddy?createDatabaseIfNotExist=true&serverTimezone=UTC
ENV SPRING_DATASOURCE_USERNAME=root
ENV SPRING_DATASOURCE_PASSWORD=rootpassword

# Commande de démarrage (CMD spécifié dans l'énoncé)
CMD ["java", "-jar", "app.jar"]
