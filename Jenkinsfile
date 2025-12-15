pipeline {
    agent any

    tools {
        maven 'M2_HOME'      // Nom EXACT de Maven dans Jenkins
        jdk 'JAVA_HOME'      // Nom EXACT du JDK dans Jenkins
    }

    stages {

        stage('1️⃣ Clone Repository') {
            steps {
                echo '📥 Clonage du repository Git...'
                git branch: 'main',
                    url: 'https://github.com/bahijabaj123/student-management2.git'
                echo '✅ Clonage terminé'
            }
        }

        stage('2️⃣ Build Project') {
            steps {
                echo '🔨 Compilation du projet avec Maven...'
                sh 'mvn clean compile -DskipTests'
                echo '✅ Build terminé'
            }
        }

        stage('3️⃣ Package Project') {
            steps {
                echo '📦 Packaging du projet...'
                sh 'mvn package -DskipTests'
                echo '✅ Packaging terminé'
            }
        }

        stage('4️⃣ SonarQube Analysis') {
            steps {
                echo '🔍 Analyse de la qualité du code avec SonarQube...'
                withSonarQubeEnv('SonarQube') {
                    sh """
                    mvn sonar:sonar \
                    -Dsonar.projectKey=student-management \
                    -Dsonar.projectName=student-management
                    """
                }
            }
        }

        stage('5️⃣ Package JAR') {
            steps {
                echo '📦 Packaging final en JAR...'
                sh 'mvn clean package -DskipTests'
                echo '✅ JAR prêt'
            }
        }

        stage('6️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage du fichier JAR...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline terminé avec succès'
        }
        failure {
            echo '❌ Le pipeline a échoué'
        }
    }
}
