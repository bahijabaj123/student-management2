pipeline {
    agent any

    tools {
        maven 'M2_HOME'
        jdk 'JAVA_HOME'
    }

    environment {
        // CONFIGURATION DOCKER - À ADAPTER AVEC VOS INFOS
        DOCKER_REGISTRY = 'https://index.docker.io/v1/'
        DOCKER_IMAGE = 'bahija123/student-management'  // Votre nom Docker Hub
        DOCKER_TAG = "${BUILD_NUMBER}-${env.BRANCH_NAME ?: 'main'}"
        
        // CONFIGURATION KUBERNETES
        K8S_NAMESPACE = 'default'
        K8S_DEPLOYMENT = 'student-management-app'
        K8S_SERVICE = 'student-service'
    }

    stages {
        // ==================== ÉTAPE 1 : CHECKOUT CODE ====================
        stage('1️⃣ Checkout Code') {
            steps {
                echo '📥 Clonage du repository Git...'
                git branch: 'main', 
                     url: 'https://github.com/bahijabaj123/student-management.git',
                     credentialsId: 'github-credentials'  // Optionnel si privé
                echo '✅ Repository cloné'
                
                // Afficher la structure
                sh 'ls -la'
            }
        }

        // ==================== ÉTAPE 2 : BUILD AVEC MAVEN ====================
        stage('2️⃣ Build avec Maven') {
            steps {
                echo '🔨 Construction du projet Java...'
                sh 'mvn clean compile'
                echo '✅ Compilation terminée'
                
                echo '🧪 Exécution des tests...'
                sh 'mvn test'
                echo '✅ Tests exécutés'
            }
            
            post {
                success {
                    echo '📊 Rapport de tests généré'
                    junit 'target/surefire-reports/*.xml'  // Publier les résultats
                }
            }
        }

        // ==================== ÉTAPE 3 : PACKAGE JAR ====================
        stage('3️⃣ Package JAR') {
            steps {
                echo '📦 Création du package JAR...'
                sh 'mvn package -DskipTests'
                echo '✅ JAR créé'
                
                // Vérifier le JAR
                sh 'ls -lh target/*.jar'
                
                // Archiver le JAR
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        // ==================== ÉTAPE 4 : BUILD DOCKER IMAGE ====================
        stage('4️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction de l\'image Docker...'
                
                script {
                    // Vérifier/Créer Dockerfile
                    if (!fileExists('Dockerfile')) {
                        writeFile file: 'Dockerfile', text: '''# Dockerfile pour application Java Spring Boot
FROM openjdk:11-jre-slim
LABEL maintainer="bahija123"

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier le JAR
COPY target/*.jar app.jar

# Exposer le port
EXPOSE 8080

# Commande de démarrage
ENTRYPOINT ["java", "-jar", "app.jar"]
'''
                        echo '📄 Dockerfile créé automatiquement'
                    }
                    
                    // Vérifier le contenu
                    sh 'cat Dockerfile'
                    
                    // Construire l'image
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                    
                    // Lister les images
                    sh 'docker images | grep ${DOCKER_IMAGE}'
                }
                echo '✅ Image Docker construite'
            }
        }

        // ==================== ÉTAPE 5 : PUSH DOCKER IMAGE ====================
        stage('5️⃣ Push Docker Image') {
            steps {
                echo '⬆️  Pushing image to Docker Hub...'
                
                script {
                    // UTILISATION DE VOTRE TOKEN - L'ID DOIT CORRESPONDRE À JENKINS
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',  // L'ID que vous avez créé
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            # Se connecter à Docker Hub
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            # Pousser les images
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            
                            # Se déconnecter
                            docker logout
                        """
                    }
                }
                echo '✅ Image poussée sur Docker Hub'
            }
        }

        // ==================== ÉTAPE 6 : DÉPLOYER SUR KUBERNETES ====================
        stage('6️⃣ Déployer sur Kubernetes Cluster') {
            steps {
                echo '⚙️  Déploiement sur Kubernetes...'
                
                script {
                    // Créer le dossier k8s s'il n'existe pas
                    sh 'mkdir -p k8s'
                    
                    // Fichier de déploiement
                    writeFile file: 'k8s/deployment.yaml', text: """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${K8S_DEPLOYMENT}
  namespace: ${K8S_NAMESPACE}
  labels:
    app: student-management
spec:
  replicas: 2
  selector:
    matchLabels:
      app: student-management
  template:
    metadata:
      labels:
        app: student-management
    spec:
      containers:
      - name: student-management
        image: ${DOCKER_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 45
          periodSeconds: 15
"""
                    
                    // Fichier de service
                    writeFile file: 'k8s/service.yaml', text: """
apiVersion: v1
kind: Service
metadata:
  name: ${K8S_SERVICE}
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: student-management
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 30080
  type: NodePort
"""
                    
                    // Appliquer les configurations
                    sh """
                        echo "📄 Application des fichiers Kubernetes..."
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    """
                    
                    // Vérifier le déploiement
                    sh """
                        echo "🔍 Vérification du déploiement..."
                        kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} --timeout=180s
                    """
                }
                echo '✅ Déploiement Kubernetes terminé'
            }
        }

        // ==================== ÉTAPE 7 : VÉRIFICATION ====================
        stage('7️⃣ Vérification du déploiement') {
            steps {
                echo '🔍 Vérification finale...'
                
                script {
                    sh """
                        # Vérifier les pods
                        echo "📦 Pods:"
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=student-management
                        
                        # Vérifier les déploiements
                        echo "🚀 Déploiements:"
                        kubectl get deployments -n ${K8S_NAMESPACE}
                        
                        # Vérifier les services
                        echo "🔌 Services:"
                        kubectl get svc -n ${K8S_NAMESPACE}
                        
                        # Obtenir l'URL Minikube
                        echo "🌐 URLs d'accès:"
                        minikube service ${K8S_SERVICE} -n ${K8S_NAMESPACE} --url || echo "Minikube non disponible"
                    """
                    
                    // Test de santé
                    sh """
                        # Attendre que l'application soit prête
                        sleep 10
                        
                        # Obtenir l'URL du service
                        SERVICE_URL=\$(minikube service ${K8S_SERVICE} -n ${K8S_NAMESPACE} --url 2>/dev/null | head -1)
                        
                        if [ ! -z "\$SERVICE_URL" ]; then
                            echo "Testing health endpoint at: \$SERVICE_URL/actuator/health"
                            curl -f \$SERVICE_URL/actuator/health || echo "Health check failed"
                        else
                            echo "⚠️  Impossible d'obtenir l'URL du service"
                        fi
                    """
                }
                echo '✅ Vérification terminée'
            }
        }
    }

    post {
        always {
            echo '🧹 Nettoyage...'
            script {
                // Nettoyer les images locales pour économiser l'espace
                sh """
                    docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} 2>/dev/null || true
                    docker rmi ${DOCKER_IMAGE}:latest 2>/dev/null || true
                """
            }
        }
        
        success {
            echo '🎉 🎉 🎉 PIPELINE RÉUSSIE ! 🎉 🎉 🎉'
            echo "Image Docker: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "Déploiement: ${K8S_DEPLOYMENT}"
            echo "Service: ${K8S_SERVICE}"
            
            // Notification optionnelle
            emailext (
                subject: "✅ Pipeline réussie: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} terminée avec succès!
                
                Détails:
                - Image Docker: ${DOCKER_IMAGE}:${DOCKER_TAG}
                - Déploiement K8s: ${K8S_DEPLOYMENT}
                - Lien Jenkins: ${env.BUILD_URL}
                
                Pour accéder à l'application: minikube service ${K8S_SERVICE}
                """,
                to: 'votre-email@example.com'
            )
        }
        
        failure {
            echo '❌ ❌ ❌ PIPELINE ÉCHOUÉE ❌ ❌ ❌'
            
            // Rollback automatique
            script {
                sh """
                    echo "🔄 Tentative de rollback..."
                    kubectl rollout undo deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} || echo "Rollback impossible"
                """
            }
        }
        
        unstable {
            echo '⚠️  Pipeline instable - vérifiez les tests'
        }
    }
}
