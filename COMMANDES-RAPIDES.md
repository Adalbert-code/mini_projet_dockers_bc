# Commandes Rapides - PayMyBuddy Docker

## Prérequis
- Docker Desktop démarré et en cours d'exécution
- Être dans le répertoire `mini-projet-docker`

---

## Phase 1 & 2: Build et Orchestration (12 points)

### 1. Démarrer l'application (première fois)
```bash
# Builder et démarrer tous les services
docker-compose up -d --build

# Voir les logs en temps réel
docker-compose logs -f

# Pour quitter les logs: Ctrl+C
```

### 2. Vérifier que tout fonctionne
```bash
# Voir l'état des services
docker-compose ps

# Devrait afficher:
# paymybuddy-backend   running   0.0.0.0:8080->8080/tcp
# paymybuddy-db        running   0.0.0.0:3306->3306/tcp
```

### 3. Tester l'application
```bash
# Tester l'API
curl http://localhost:8080

# Ou ouvrir dans le navigateur
start http://localhost:8080
```

### 4. Vérifier la base de données
```bash
# Se connecter à MySQL
docker exec -it paymybuddy-db mysql -uroot -prootpassword db_paymybuddy

# Dans MySQL, exécuter:
SHOW TABLES;
SELECT * FROM user;
exit
```

### 5. Arrêter les services
```bash
# Arrêter sans supprimer les volumes
docker-compose stop

# Arrêter et tout supprimer (⚠️ données perdues)
docker-compose down -v
```

---

## Phase 3: Docker Registry Privé (4 points)

### Étape 1: Déployer le registry
```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

### Étape 2: Vérifier le registry
```bash
curl http://localhost:5000/v2/_catalog
# Résultat attendu: {"repositories":[]}
```

### Étape 3: Builder l'image du backend
```bash
docker-compose build paymybuddy-backend
```

### Étape 4: Tagger les images
```bash
# Tagger le backend
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:latest
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:1.0

# Tagger MySQL
docker tag mysql:8.0 localhost:5000/mysql:8.0
```

### Étape 5: Pusher vers le registry
```bash
# Pusher le backend
docker push localhost:5000/paymybuddy-backend:latest
docker push localhost:5000/paymybuddy-backend:1.0

# Pusher MySQL
docker push localhost:5000/mysql:8.0
```

### Étape 6: Vérifier les images dans le registry
```bash
# Lister les repositories
curl http://localhost:5000/v2/_catalog

# Lister les tags du backend
curl http://localhost:5000/v2/paymybuddy-backend/tags/list

# Résultat attendu:
# {"repositories":["mysql","paymybuddy-backend"]}
# {"name":"paymybuddy-backend","tags":["1.0","latest"]}
```

### Étape 7: Déployer avec le registry
```bash
# Arrêter les services actuels
docker-compose down

# Démarrer avec le nouveau fichier (images du registry)
docker-compose -f docker-compose-registry.yml up -d

# Vérifier
docker-compose -f docker-compose-registry.yml ps
```

---

## Commandes de Maintenance

### Voir les logs
```bash
# Tous les services
docker-compose logs -f

# Un service spécifique
docker-compose logs -f paymybuddy-backend
docker-compose logs -f paymybuddy-db
```

### Redémarrer un service
```bash
docker-compose restart paymybuddy-backend
docker-compose restart paymybuddy-db
```

### Reconstruire une image
```bash
# Reconstruire le backend
docker-compose build --no-cache paymybuddy-backend

# Redémarrer avec la nouvelle image
docker-compose up -d paymybuddy-backend
```

### Nettoyer Docker
```bash
# Supprimer les images inutilisées
docker image prune -a

# Supprimer tout (⚠️ ATTENTION)
docker system prune -a --volumes
```

---

## Commandes de Diagnostic

### Voir les images Docker
```bash
docker images
```

### Voir les conteneurs en cours
```bash
docker ps
```

### Voir tous les conteneurs (même arrêtés)
```bash
docker ps -a
```

### Voir l'utilisation des ressources
```bash
docker stats
```

### Inspecter un conteneur
```bash
docker inspect paymybuddy-backend
docker inspect paymybuddy-db
```

### Voir les volumes
```bash
docker volume ls
```

---

## Utilisateurs de Test

Utilisez ces comptes pour tester l'application après connexion:

|      Email        | Password (BCrypt hashé) | Nom          |
|-------------------|-------------------------|--------------|
| hayley@mymail.com | (voir base de données)  | Hayley James |
| clara@mail.com    | (voir base de données)  | Clara Tarazi |
| smith@mail.com    | (voir base de données)  | Smith Sam    |
| lambda@mail.com   | (voir base de données)  | Lambda User  |

**Note:** Les mots de passe sont hashés avec BCrypt dans le script SQL.

---

## Captures d'écran à Prendre (Phase 4)

1. ✅ Commande `docker images` - Montrer les images créées
2. ✅ Commande `docker ps` - Services en cours d'exécution
3. ✅ Commande `docker-compose ps` - État des services
4. ✅ Registry: `curl http://localhost:5000/v2/_catalog`
5. ✅ Navigateur: `http://localhost:8080` - Page d'accueil
6. ✅ Page de login
7. ✅ Dashboard après connexion
8. ✅ Logs: `docker-compose logs`

---

## Troubleshooting

### Problème: Port déjà utilisé
```bash
# Trouver le processus qui utilise le port 8080
netstat -ano | findstr :8080

# Ou changer le port dans docker-compose.yml
ports:
  - "8081:8080"  # Utiliser 8081 au lieu de 8080
```

### Problème: Base de données non initialisée
```bash
# Supprimer le volume et recréer
docker-compose down -v
docker-compose up -d
```

### Problème: Connexion refusée au backend
```bash
# Vérifier les logs
docker-compose logs paymybuddy-backend

# Vérifier que MySQL est prêt
docker-compose logs paymybuddy-db | grep "ready for connections"
```

### Problème: Registry non accessible
```bash
# Vérifier que le registry tourne
docker ps | grep registry

# Redémarrer le registry
docker restart registry

# Vérifier les logs
docker logs registry
```

---

## Workflow Complet (Toutes les phases)

```bash
# === PHASE 1 & 2: Build et Orchestration ===
# 1. Démarrer l'application
docker-compose up -d --build

# 2. Vérifier
docker-compose ps
curl http://localhost:8080

# === PHASE 3: Registry Privé ===
# 3. Déployer le registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# 4. Tagger et pusher
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:latest
docker tag mysql:8.0 localhost:5000/mysql:8.0
docker push localhost:5000/paymybuddy-backend:latest
docker push localhost:5000/mysql:8.0

# 5. Vérifier le registry
curl http://localhost:5000/v2/_catalog

# 6. Redéployer avec le registry
docker-compose down
docker-compose -f docker-compose-registry.yml up -d

# 7. Tester
curl http://localhost:8080
```

---
