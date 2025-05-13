pipeline {
    agent any
    tools {
        maven 'Maven'
    }

    environment {
        GCP_PROJECT = 'active-alchemy-459306-v2'     // Your GCP Project ID
        GKE_CLUSTER = 'kube-cluster'                 // Your GKE Cluster Name
        GKE_ZONE = 'us-central1-c'                   // Your GKE Cluster Zone
        CREDENTIALS_ID = 'kubernetes'                // Jenkins credentials ID for GCP
        IMAGE_NAME = "gcr.io/${GCP_PROJECT}/gcp-spring-project"  // GCR Image
        DOCKERHUB_CREDENTIALS = 'dockerhub'          // Jenkins credentials ID for DockerHub
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean install -U -DskipTests'
            }
        }

        stage('Test') {
            steps {
                echo "Running Tests..."
                sh 'mvn test'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    // Building the Docker image with Build ID
                    myimage = docker.build("${IMAGE_NAME}:${env.BUILD_ID}")
                }
            }
        }

        stage('Push Docker Image to GCR') {
            steps {
                script {
                    // Authenticate with GCP
                    withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh '''
                        gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                        gcloud auth configure-docker gcr.io --quiet
                        docker push ${IMAGE_NAME}:${env.BUILD_ID}
                        docker tag ${IMAGE_NAME}:${env.BUILD_ID} ${IMAGE_NAME}:latest
                        docker push ${IMAGE_NAME}:latest
                        '''
                    }
                }
            }
        }

        stage('Deploy to GKE') {
            steps {
                script {
                    // Get GKE Credentials
                    withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh '''
                        gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                        gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE} --project ${GCP_PROJECT}
                        '''
                    }

                    // Update Kubernetes manifests with the new image version
                    def files = ['kubernetes/deployment.yaml', 'kubernetes/service.yaml']
                    files.each { file ->
                        sh "sed -i 's|gcr.io/.*/gcp-spring-project:.*|${IMAGE_NAME}:${env.BUILD_ID}|' ${file}"
                    }

                    // Apply Kubernetes manifests
                    sh '''
                    kubectl apply -f kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/service.yaml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Deployment Successful!"
        }

        failure {
            echo "Deployment Failed. Please check the logs."
        }

        always {
            echo "Cleaning up local Docker images..."
            sh "docker rmi ${IMAGE_NAME}:${env.BUILD_ID} || true"
            sh "docker rmi ${IMAGE_NAME}:latest || true"
        }
    }
}
