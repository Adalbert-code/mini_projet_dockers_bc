# Guide de Démarrage Rapide - Vagrant

Votre projet est déjà configuré avec Vagrant! Suivez ce guide pour déployer PayMyBuddy.

---

## 📋 Configuration Existante

### Vagrantfile
- **Box:** `eazytrainingfr/ubuntu` (Ubuntu 20.04 custom)
- **IP:** `192.168.56.5` (IP statique)
- **Ressources:** 8GB RAM, 4 CPUs
- **Hostname:** `dockerPayMyBuddy`
- **Script:** `install_docker.sh` (installe Docker automatiquement)

### Ports d'Accès depuis Windows
- Backend: `http://192.168.56.5:8080`
- MySQL: `192.168.56.5:3306`
- Registry: `http://192.168.56.5:5000`

---

## 🚀 Démarrage en 4 Étapes

### Étape 1: Démarrer la VM

```powershell
# Dans PowerShell ou CMD, depuis le répertoire du projet
cd "c:\Users\adaln\EAZYTRAINING\DevOpsBootCamps\Introduction-a-Docker\bootcamp-project-update\mini-projet-docker"

# Démarrer la VM (première fois: 5-10 minutes)
vagrant up
```

**Ce qui se passe:**
1. Téléchargement de la box Ubuntu (si première fois)
2. Création de la VM avec 8GB RAM et 4 CPUs
3. Exécution du script `install_docker.sh`
4. Installation de Docker, Docker Compose, et zsh

### Étape 2: Se Connecter à la VM

```powershell
# Connexion SSH
vagrant ssh
```

Vous êtes maintenant dans la VM Ubuntu! 🎉

### Étape 3: Aller dans le Projet

```bash
# Le dossier est automatiquement synchronisé
cd /vagrant

# Vérifier les fichiers
ls -la

# Vous devriez voir:
# - Dockerfile
# - docker-compose.yml
# - .env
# - target/paymybuddy.jar
# - etc.
```

### Étape 4: Déployer l'Application

```bash
# Démarrer tous les services
docker-compose up -d --build

# Voir les logs
docker-compose logs -f

# Pour quitter les logs: Ctrl+C

# Vérifier l'état
docker-compose ps
```

---

## 🌐 Accès depuis Windows

### Application Web
Ouvrir dans le navigateur Windows:
```
http://192.168.56.5:8080
```

### Vérifier avec curl (PowerShell)
```powershell
curl http://192.168.56.5:8080
```

---

## 🐳 Phase 1 & 2: Build et Orchestration

### Dans la VM (après vagrant ssh)

```bash
# Aller dans le projet
cd /vagrant

# 1. Démarrer les services
docker-compose up -d --build

# 2. Vérifier l'état
docker-compose ps

# Résultat attendu:
# NAME                  STATUS              PORTS
# paymybuddy-backend    Up                  0.0.0.0:8080->8080/tcp
# paymybuddy-db         Up (healthy)        0.0.0.0:3306->3306/tcp

# 3. Voir les logs
docker-compose logs -f paymybuddy-backend
docker-compose logs -f paymybuddy-db

# 4. Vérifier MySQL
docker exec -it paymybuddy-db mysql -uroot -prootpassword db_paymybuddy

# Dans MySQL:
SHOW TABLES;
SELECT * FROM user;
exit

# 5. Tester depuis la VM
curl http://localhost:8080
```

### Depuis Windows

```powershell
# Navigateur
start http://192.168.56.5:8080

# PowerShell
curl http://192.168.56.5:8080
```

---

## 🏢 Phase 3: Docker Registry Privé

### Dans la VM

```bash
# 1. Déployer le registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# 2. Vérifier
curl http://localhost:5000/v2/_catalog
# Résultat: {"repositories":[]}

# 3. Tagger les images
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:latest
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:1.0
docker tag mysql:8.0 localhost:5000/mysql:8.0

# 4. Pusher vers le registry
docker push localhost:5000/paymybuddy-backend:latest
docker push localhost:5000/paymybuddy-backend:1.0
docker push localhost:5000/mysql:8.0

# 5. Vérifier les images dans le registry
curl http://localhost:5000/v2/_catalog
# Résultat: {"repositories":["mysql","paymybuddy-backend"]}

curl http://localhost:5000/v2/paymybuddy-backend/tags/list
# Résultat: {"name":"paymybuddy-backend","tags":["1.0","latest"]}

# 6. Redéployer avec le registry
docker-compose down
docker-compose -f docker-compose-registry.yml up -d

# 7. Vérifier
docker-compose ps
docker images | grep localhost:5000
```

### Depuis Windows - Tester le Registry

```powershell
# Voir le catalogue
curl http://192.168.56.5:5000/v2/_catalog

# Ou dans le navigateur
start http://192.168.56.5:5000/v2/_catalog
```

---

## 📸 Captures d'Écran à Prendre

### 1. Dans la VM (via vagrant ssh)

```bash
# Version Docker
docker --version

# Version Docker Compose
docker compose version

# Liste des images
docker images

# Conteneurs actifs
docker ps

# Services docker-compose
docker-compose ps

# Contenu du registry
curl http://localhost:5000/v2/_catalog

# Tags disponibles
curl http://localhost:5000/v2/paymybuddy-backend/tags/list

# Logs des services
docker-compose logs --tail=30

# Réseau Docker
docker network ls
docker network inspect vagrant_paymybuddy-network

# Volumes
docker volume ls
```

### 2. Depuis Windows (navigateur)

- Application: `http://192.168.56.5:8080`
- Page de login
- Dashboard après connexion avec un utilisateur de test
- Registry: `http://192.168.56.5:5000/v2/_catalog`

---

## 🛠️ Commandes Vagrant Utiles

### Sur Windows (PowerShell/CMD)

```powershell
# Voir l'état de la VM
vagrant status

# Démarrer la VM
vagrant up

# Se connecter en SSH
vagrant ssh

# Redémarrer la VM
vagrant reload

# Arrêter la VM (conserve tout)
vagrant halt

# Supprimer complètement la VM
vagrant destroy

# Reprovisioner (réexécuter install_docker.sh)
vagrant provision

# Voir la config SSH
vagrant ssh-config
```

---

## 🔍 Vérifications Complètes

### Dans la VM

```bash
cd /vagrant

# 1. Vérifier Docker
docker --version
docker compose version
sudo systemctl status docker

# 2. Vérifier les fichiers du projet
ls -la
cat Dockerfile
cat docker-compose.yml
cat .env

# 3. Vérifier le JAR
ls -lh target/paymybuddy.jar

# 4. Vérifier les services
docker-compose ps
docker ps -a

# 5. Vérifier les images
docker images

# 6. Vérifier les volumes
docker volume ls
docker volume inspect vagrant_mysql-data

# 7. Vérifier les réseaux
docker network ls

# 8. Vérifier les logs
docker-compose logs paymybuddy-backend | tail -50
docker-compose logs paymybuddy-db | tail -50

# 9. Tester la connectivité
curl -I http://localhost:8080
ping -c 3 paymybuddy-db

# 10. Vérifier MySQL
docker exec -it paymybuddy-db mysql -uroot -prootpassword -e "SHOW DATABASES;"
```

---

## 🎯 Workflow Complet

```bash
# === Sur Windows ===
# 1. Démarrer la VM
vagrant up

# 2. Se connecter
vagrant ssh

# === Dans la VM ===
# 3. Aller dans le projet
cd /vagrant

# 4. Démarrer les services (Phase 1 & 2)
docker-compose up -d --build

# 5. Vérifier
docker-compose ps
curl http://localhost:8080

# 6. Déployer le registry (Phase 3)
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# 7. Tagger et pusher
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:latest
docker tag mysql:8.0 localhost:5000/mysql:8.0
docker push localhost:5000/paymybuddy-backend:latest
docker push localhost:5000/mysql:8.0

# 8. Vérifier le registry
curl http://localhost:5000/v2/_catalog

# 9. Redéployer avec le registry
docker-compose down
docker-compose -f docker-compose-registry.yml up -d

# 10. Vérification finale
docker-compose ps
docker images
curl http://localhost:8080

# === Sur Windows (navigateur) ===
# 11. Tester l'application
http://192.168.56.5:8080
http://192.168.56.5:5000/v2/_catalog
```

---

## ⚠️ Troubleshooting

### VM ne démarre pas

```powershell
# Vérifier VirtualBox
vagrant status

# Forcer un reload
vagrant reload --provision
```

### Docker n'est pas installé

```bash
# Reprovisioner la VM
exit
vagrant provision
vagrant ssh
```

### Permission denied avec Docker

```bash
# Vérifier le groupe
groups

# Si docker n'apparaît pas, sortir et reconnecter
exit
vagrant ssh
```

### Port 8080 ne répond pas

```bash
# Vérifier les logs
docker-compose logs paymybuddy-backend

# Vérifier que MySQL est prêt
docker-compose logs paymybuddy-db | grep "ready for connections"

# Redémarrer les services
docker-compose restart
```

### Ne peut pas accéder depuis Windows

```bash
# Vérifier l'IP de la VM
ip addr show enp0s8

# Devrait afficher: 192.168.56.5

# Vérifier le firewall dans la VM
sudo ufw status
```

---

## 🎓 Utilisateurs de Test

Pour tester l'application après connexion:

| Email | Nom | Solde Initial |
|-------|-----|---------------|
| hayley@mymail.com | Hayley James | 10.00 € |
| clara@mail.com | Clara Tarazi | 133.56 € |
| smith@mail.com | Smith Sam | 8.00 € |
| lambda@mail.com | Lambda User | 96.91 € |

**Note:** Les mots de passe sont hashés avec BCrypt dans la base de données.

---

## 💡 Avantages de cette Configuration

✅ **8GB RAM & 4 CPUs** - Performance optimale pour Docker
✅ **Box custom EazyTraining** - Préconfigurée pour la formation
✅ **Installation automatique** - Docker installé via script
✅ **IP statique** - Accès prévisible depuis Windows
✅ **Zsh + Oh My Zsh** - Terminal amélioré avec plugins Docker
✅ **Dossier synchronisé** - Modifiez sur Windows, exécutez sur Linux

---

## 📚 Ressources

- **Vagrantfile:** Configuration de la VM
- **install_docker.sh:** Script d'installation Docker
- **docker-compose.yml:** Orchestration des services
- **docker-compose-registry.yml:** Orchestration avec registry
- **.env:** Variables d'environnement
- **Dockerfile:** Image du backend

---

**Votre environnement est prêt! Lancez `vagrant up` pour commencer! 🚀**
