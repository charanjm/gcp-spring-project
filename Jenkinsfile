pipeline {
    agent any
    environment {
        GCP_PROJECT = 'your-gcp-project-id'
        GKE_CLUSTER = 'your-gke-cluster-name'
        GKE_ZONE = 'your-gke-cluster-zone'
        IMAGE_NAME = 'gcr.io/${GCP_PROJECT}/gcp-spring-project'
    }
    stages {
        stage('Build') {
            steps {
                script {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                script {
                    sh """
                    docker build -t ${IMAGE_NAME}:latest .
                    docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to GKE') {
            steps {
                script {
                    sh """
                    gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE} --project ${GCP_PROJECT}
                    kubectl apply -f kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/service.yaml
                    """
                }
            }
        }
    }
}
