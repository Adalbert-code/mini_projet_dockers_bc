# Guide de Déploiement sur VM Vagrant

Ce guide explique comment déployer PayMyBuddy sur une VM Ubuntu provisionnée avec Vagrant.

---

## Prérequis sur la Machine Locale (Windows)

- VirtualBox installé
- Vagrant installé
- Les fichiers du projet PayMyBuddy

---

## Étape 1: Créer le Vagrantfile

### Créer un Vagrantfile dans le répertoire du projet

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Box Ubuntu 20.04 (spécifié dans l'énoncé)
  config.vm.box = "ubuntu/focal64"

  # Configuration réseau
  # Port forwarding pour accéder à l'application depuis Windows
  config.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 3306, host: 3306, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 5000, host: 5000, host_ip: "127.0.0.1"

  # IP privée (optionnel, pour accès direct)
  config.vm.network "private_network", ip: "192.168.56.10"

  # Nom de la VM
  config.vm.hostname = "paymybuddy-docker"

  # Configuration des ressources
  config.vm.provider "virtualbox" do |vb|
    vb.name = "paymybuddy-docker-vm"
    vb.memory = "2048"  # 2GB RAM
    vb.cpus = 2         # 2 CPUs
  end

  # Synchronisation du dossier du projet
  config.vm.synced_folder ".", "/home/vagrant/paymybuddy"

  # Provisioning: Installation de Docker
  config.vm.provision "shell", inline: <<-SHELL
    # Mise à jour du système
    apt-get update

    # Installation des dépendances
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      git

    # Ajout de la clé GPG officielle de Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Ajout du repository Docker
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Installation de Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # Installation de Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Ajouter l'utilisateur vagrant au groupe docker
    usermod -aG docker vagrant

    # Démarrer et activer Docker
    systemctl start docker
    systemctl enable docker

    # Vérifications
    echo "=== Docker version ==="
    docker --version
    echo "=== Docker Compose version ==="
    docker-compose --version
    echo "=== Installation terminée! ==="
  SHELL
end
```

---

## Étape 2: Démarrer la VM

### Sur Windows (PowerShell ou CMD)

```bash
# Aller dans le répertoire du projet
cd "c:\Users\adal..\..\..\..\bootcamp-project-update\mini-projet-docker"

# Créer le Vagrantfile (copier le contenu ci-dessus)
# Ou utiliser le fichier fourni

# Démarrer la VM (première fois: téléchargement + provisioning)
vagrant up

# La VM va:
# 1. Télécharger Ubuntu 20.04
# 2. Installer Docker et Docker Compose
# 3. Configurer tout automatiquement
```

**Note:** Le premier `vagrant up` peut prendre 5-10 minutes selon votre connexion internet.

---

## 📡 Étape 3: Se Connecter à la VM

```bash
# SSH dans la VM
vagrant ssh

# Vous êtes maintenant dans la VM Ubuntu!
# Vérifier que Docker fonctionne
docker --version
docker-compose --version

# Aller dans le répertoire du projet
cd /home/vagrant/paymybuddy
ls -la
```

---

## 🐳 Étape 4: Déployer PayMyBuddy (Phase 1 & 2)

### Dans la VM (après vagrant ssh)

```bash
# Vérifier les fichiers
ls -la
# Vous devriez voir: Dockerfile, docker-compose.yml, .env, target/, etc.

# Démarrer les services
docker-compose up -d --build

# Voir les logs
docker-compose logs -f

# Pour quitter les logs: Ctrl+C

# Vérifier l'état des services
docker-compose ps
```

### Tester depuis Windows

Une fois les services démarrés dans la VM:

```bash
# Dans un navigateur Windows
http://localhost:8080

# Ou avec curl (PowerShell)
curl http://localhost:8080

# Ou avec l'IP privée
http://192.168.56.10:8080
```

---

## 🏢 Étape 5: Déployer le Registry Privé (Phase 3)

### Dans la VM

```bash
# 1. Déployer le registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# 2. Vérifier le registry
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

# 5. Vérifier
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/paymybuddy-backend/tags/list

# 6. Redéployer avec le registry
docker-compose down
docker-compose -f docker-compose-registry.yml up -d

# 7. Vérifier
docker-compose ps
```

### Tester le registry depuis Windows

```bash
# Dans PowerShell/CMD Windows
curl http://localhost:5000/v2/_catalog

# Ou dans le navigateur
http://localhost:5000/v2/_catalog
```

---

## 🔍 Étape 6: Vérifications et Tests

### Dans la VM

```bash
# 1. Voir tous les conteneurs
docker ps

# 2. Voir toutes les images
docker images

# 3. Vérifier les logs du backend
docker-compose logs paymybuddy-backend

# 4. Vérifier les logs de MySQL
docker-compose logs paymybuddy-db

# 5. Se connecter à MySQL
docker exec -it paymybuddy-db mysql -uroot -prootpassword db_paymybuddy

# Dans MySQL:
SHOW TABLES;
SELECT * FROM user;
exit

# 6. Vérifier les volumes
docker volume ls

# 7. Vérifier le réseau
docker network ls
docker network inspect mini-projet-docker_paymybuddy-network
```

### Depuis Windows

```bash
# Tester l'application web
start http://localhost:8080

# Tester avec curl
curl http://localhost:8080

# Ou avec l'IP privée
start http://192.168.56.10:8080
```

---

## 📸 Captures d'Écran à Prendre

### Dans la VM (via vagrant ssh)

```bash
# 1. Version Docker
docker --version

# 2. Version Docker Compose
docker-compose --version

# 3. Images Docker
docker images

# 4. Conteneurs en cours
docker ps

# 5. Services docker-compose
docker-compose ps

# 6. Contenu du registry
curl http://localhost:5000/v2/_catalog

# 7. Tags du backend
curl http://localhost:5000/v2/paymybuddy-backend/tags/list

# 8. Logs
docker-compose logs --tail=50
```

### Dans le navigateur Windows

1. Page d'accueil: `http://localhost:8080`
2. Page de login
3. Dashboard après connexion
4. Registry: `http://localhost:5000/v2/_catalog`

---

## 🛠️ Commandes Vagrant Utiles

### Sur Windows

```bash
# Démarrer la VM
vagrant up

# Se connecter en SSH
vagrant ssh

# Voir l'état de la VM
vagrant status

# Redémarrer la VM
vagrant reload

# Arrêter la VM (mais la conserver)
vagrant halt

# Supprimer complètement la VM
vagrant destroy

# Reprovisioner la VM (réinstaller Docker, etc.)
vagrant provision

# Voir les infos SSH
vagrant ssh-config
```

---

## 🔧 Configuration Réseau - Détails

### Ports Forwarding Configurés

| Service  | Port VM | Port Windows |       Description       |
|----------|---------|--------------|-------------------------|
| Backend  |  8080   |    8080      | Application Spring Boot |
| MySQL    |  3306   |    3306      |    Base de données      |
| Registry | 5000    |    5000      |  Registry Docker privé  |

### Accès depuis Windows

Vous pouvez accéder aux services de 2 façons:

1. **Via localhost** (port forwarding):
   - `http://localhost:8080` → Backend
   - `http://localhost:3306` → MySQL
   - `http://localhost:5000` → Registry

2. **Via IP privée**:
   - `http://192.168.56.10:8080` → Backend
   - `http://192.168.56.10:3306` → MySQL
   - `http://192.168.56.10:5000` → Registry

---

## Dossier Partagé

Le dossier du projet est automatiquement synchronisé:

- **Windows:** `c:\Users\adaln\...\mini-projet-docker`
- **VM:** `/home/vagrant/paymybuddy`

**Avantages:**
- Modifier les fichiers sur Windows → changements visibles dans la VM
- Pas besoin de copier/coller les fichiers
- Les modifications de code sont immédiatement disponibles

---

## Troubleshooting

### Problème: Port déjà utilisé sur Windows

```bash
# Changer les ports dans Vagrantfile
config.vm.network "forwarded_port", guest: 8080, host: 8081  # Utiliser 8081
```

### Problème: Erreur de synchronisation de dossier

```bash
# Sur Windows, installer le plugin vbguest
vagrant plugin install vagrant-vbguest

# Recharger la VM
vagrant reload
```

### Problème: Docker ne démarre pas dans la VM

```bash
# Dans la VM
vagrant ssh

# Vérifier le statut
sudo systemctl status docker

# Redémarrer Docker
sudo systemctl restart docker
```

### Problème: Permission denied avec Docker

```bash
# Sortir et reconnecter (pour appliquer le groupe docker)
exit
vagrant ssh

# Ou forcer l'ajout au groupe
sudo usermod -aG docker $USER
```

---

##  Workflow Complet sur VM Vagrant

```bash
# === Sur Windows ===
# 1. Démarrer la VM
vagrant up

# 2. Se connecter
vagrant ssh

# === Dans la VM ===
# 3. Aller dans le projet
cd /home/vagrant/paymybuddy

# 4. Démarrer les services (Phase 1 & 2)
docker-compose up -d --build

# 5. Déployer le registry (Phase 3)
docker run -d -p 5000:5000 --restart=always --name registry registry:2
docker tag paymybuddy-backend:latest localhost:5000/paymybuddy-backend:latest
docker tag mysql:8.0 localhost:5000/mysql:8.0
docker push localhost:5000/paymybuddy-backend:latest
docker push localhost:5000/mysql:8.0

# 6. Vérifier
curl http://localhost:5000/v2/_catalog
docker-compose ps

# === Sur Windows (navigateur) ===
# 7. Tester
http://localhost:8080
http://localhost:5000/v2/_catalog
```

---

##  Avantages de Vagrant pour ce Projet

1. ✅ **Environnement identique à la production** (Ubuntu 20.04)
2. ✅ **Installation automatique de Docker**
3. ✅ **Isolation complète** (pas d'impact sur Windows)
4. ✅ **Reproductible** (vagrant destroy + vagrant up = environnement neuf)
5. ✅ **Pratique DevOps** (Infrastructure as Code)

---

##  Conseils

1. **Première fois:** Laissez `vagrant up` finir complètement avant de faire `vagrant ssh`
2. **Logs:** Utilisez `docker-compose logs -f` pour voir les erreurs en temps réel
3. **Nettoyage:** N'oubliez pas de faire `vagrant halt` quand vous avez fini (libère la RAM)
4. **Backup:** Le dossier est synchronisé, donc vos fichiers Windows sont la source de vérité
5. **Captures d'écran:** Prenez-les depuis la VM via SSH pour montrer les commandes Linux

---

**Votre environnement Vagrant est prêt! 

Prochaine étape: Créer le Vagrantfile et lancer `vagrant up`
