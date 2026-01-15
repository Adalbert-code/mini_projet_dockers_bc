# Guide: Déploiement avec Docker Registry Privé

Ce guide explique comment déployer un registry Docker privé et y pusher les images PayMyBuddy (Phase 3 - 4 points).

## Étape 1: Déployer un Registry Docker Local

### Démarrer le registry
```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

**Explication:**
- `-d` : Mode détaché (en arrière-plan)
- `-p 5000:5000` : Expose le registry sur le port 5000
- `--restart=always` : Redémarre automatiquement le conteneur
- `--name registry` : Nom du conteneur
- `registry:2` : Image officielle du registry Docker v2

### Vérifier que le registry fonctionne
```bash
# Vérifier le conteneur
docker ps | grep registry

# Tester l'API du registry
curl http://localhost:5000/v2/_catalog
```

**Résultat attendu:** `{"repositories":[]}`

---

## Étape 2: Builder les Images Localement

### Builder l'image du backend
```bash
docker-compose build paymybuddy-backend
```

Ou directement:
```bash
docker build -t paymybuddy-backend:latest .
```

### Vérifier les images créées
```bash
docker images | grep paymybuddy
```

---

## Étape 3: Tagger les Images pour le Registry

### Tagger l'image du backend
```bash
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:latest
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:1.0
```

### Tagger l'image MySQL (optionnel mais recommandé)
```bash
docker tag mysql:8.0 localhost:5000/mysql:8.0
```

### Vérifier les tags
```bash
docker images | grep localhost:5000
```

**Vous devriez voir:**
```
localhost:5000/paymybuddy-backend   latest    <IMAGE_ID>   <SIZE>
localhost:5000/paymybuddy-backend   1.0       <IMAGE_ID>   <SIZE>
localhost:5000/mysql                8.0       <IMAGE_ID>   <SIZE>
```

---

## Étape 4: Pusher les Images vers le Registry

### Pusher l'image du backend
```bash
docker push localhost:5000/paymybuddy-backend:latest
docker push localhost:5000/paymybuddy-backend:1.0
```

### Pusher l'image MySQL
```bash
docker push localhost:5000/mysql:8.0
```

### Vérifier les images dans le registry
```bash
# Lister tous les repositories
curl http://localhost:5000/v2/_catalog

# Lister les tags du backend
curl http://localhost:5000/v2/paymybuddy-backend/tags/list

# Lister les tags MySQL
curl http://localhost:5000/v2/mysql/tags/list
```

**Résultat attendu:**
```json
{"repositories":["mysql","paymybuddy-backend"]}
{"name":"paymybuddy-backend","tags":["1.0","latest"]}
{"name":"mysql","tags":["8.0"]}
```

---

## Étape 5: Mettre à Jour docker-compose.yml

### Créer un nouveau fichier: docker-compose-registry.yml
Ce fichier utilisera les images depuis le registry privé.

```yaml
version: '3.8'

services:
  # Service MySQL Database (depuis registry)
  paymybuddy-db:
    image: localhost:5000/mysql:8.0
    container_name: paymybuddy-db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ./initdb:/docker-entrypoint-initdb.d
    networks:
      - paymybuddy-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # Service Spring Boot Backend (depuis registry)
  paymybuddy-backend:
    image: localhost:5000/paymybuddy-backend:latest
    container_name: paymybuddy-backend
    restart: always
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: ${SPRING_DATASOURCE_URL}
      SPRING_DATASOURCE_USERNAME: ${SPRING_DATASOURCE_USERNAME}
      SPRING_DATASOURCE_PASSWORD: ${SPRING_DATASOURCE_PASSWORD}
    depends_on:
      paymybuddy-db:
        condition: service_healthy
    networks:
      - paymybuddy-network

networks:
  paymybuddy-network:
    driver: bridge

volumes:
  mysql-data:
    driver: local
```

**Note:** La section `build` a été supprimée, on utilise directement les images du registry.

---

## Étape 6: Déployer avec le Registry

### Arrêter les services actuels (si lancés)
```bash
docker-compose down
```

### Démarrer avec les images du registry
```bash
docker-compose -f docker-compose-registry.yml up -d
```

### Vérifier le déploiement
```bash
# Voir les services
docker-compose -f docker-compose-registry.yml ps

# Voir les logs
docker-compose -f docker-compose-registry.yml logs -f

# Tester l'application
curl http://localhost:8080
```

---

## Commandes de Gestion du Registry

### Lister toutes les images dans le registry
```bash
curl http://localhost:5000/v2/_catalog | jq
```

### Obtenir les informations d'une image
```bash
curl http://localhost:5000/v2/paymybuddy-backend/manifests/latest
```

### Arrêter le registry
```bash
docker stop registry
```

### Démarrer le registry
```bash
docker start registry
```

### Supprimer le registry (⚠️ Attention: efface toutes les images)
```bash
docker stop registry
docker rm registry
```

---

## Registry Privé Distant (Bonus)

Si vous souhaitez utiliser un registry distant (ex: sur un serveur Ubuntu), modifiez les commandes:

### Sur le serveur distant
```bash
# Démarrer le registry avec persistance
docker run -d -p 5000:5000 \
  --restart=always \
  --name registry \
  -v /opt/registry:/var/lib/registry \
  registry:2
```

### Sur votre machine locale
```bash
# Tagger avec l'IP du serveur distant
docker tag paymybuddy-backend:latest <IP_SERVEUR>:5000/paymybuddy-backend:latest

# Pusher
docker push <IP_SERVEUR>:5000/paymybuddy-backend:latest
```

### Configuration HTTPS (Production)
Pour un usage en production, il faut configurer le registry avec TLS/SSL:

```bash
docker run -d -p 5000:5000 \
  --restart=always \
  --name registry \
  -v /opt/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

---

## Troubleshooting

### Erreur: http: server gave HTTP response to HTTPS client

**Solution:** Configurer Docker pour accepter le registry non-sécurisé

**Windows (Docker Desktop):**
1. Ouvrir Docker Desktop
2. Settings → Docker Engine
3. Ajouter dans la configuration JSON:
```json
{
  "insecure-registries": ["localhost:5000"]
}
```
4. Apply & Restart

**Linux:**
```bash
# Éditer le daemon.json
sudo nano /etc/docker/daemon.json

# Ajouter:
{
  "insecure-registries": ["localhost:5000"]
}

# Redémarrer Docker
sudo systemctl restart docker
```

### Vérifier l'espace disque
```bash
# Taille du registry
docker exec registry du -sh /var/lib/registry

# Nettoyer les images inutiles
docker system prune -a
```

---

## Résumé des Commandes Complètes

```bash
# 1. Déployer le registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# 2. Builder l'image
docker-compose build

# 3. Tagger les images
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:latest
docker tag mysql:8.0 localhost:5000/mysql:8.0

# 4. Pusher vers le registry
docker push localhost:5000/paymybuddy-backend:latest
docker push localhost:5000/mysql:8.0

# 5. Vérifier
curl http://localhost:5000/v2/_catalog

# 6. Déployer avec docker-compose-registry.yml
docker-compose -f docker-compose-registry.yml up -d

# 7. Tester
curl http://localhost:8080
```

---

## Captures d'écran à Prendre

Pour la livraison (Phase 4), prenez ces captures:

1. ✅ `docker ps` - Montrer le registry en cours d'exécution
2. ✅ `curl http://localhost:5000/v2/_catalog` - Lister les images du registry
3. ✅ `docker images | grep localhost:5000` - Images taguées
4. ✅ `docker-compose ps` - Services en cours d'exécution
5. ✅ Navigateur sur `http://localhost:8080` - Application fonctionnelle
6. ✅ Page de login de l'application
7. ✅ Dashboard après connexion

---

**Bon courage pour le déploiement!** 🚀
