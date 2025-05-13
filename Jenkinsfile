pipeline {
    agent any
    tools {
        maven 'Maven'
    }

    environment {
        GCP_PROJECT = 'active-alchemy-459306-v2'     // Your GCP Project ID
        GKE_CLUSTER = 'kube-cluster'                 // Your GKE Cluster Name
        GKE_ZONE = 'us-central1-c'                   // Your GKE Cluster Zone
        CREDENTIALS_ID = 'gcp-service-account'       // Your GCP Service Account Credentials ID
        IMAGE_NAME = "gcr.io/${GCP_PROJECT}/gcp-spring-project"  // GCR Image
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package -U -DskipTests'
            }
        }

        stage('Test') {
            steps {
                echo "Running Tests..."
                sh 'mvn test'
            }
        }

        stage('Docker Build and Push') {
            steps {
                script {
                    withCredentials([file(credentialsId: CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh '''
                        gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                        gcloud auth configure-docker gcr.io --quiet

                        docker build -t ${IMAGE_NAME}:${env.BUILD_ID} .
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
                    withCredentials([file(credentialsId: CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
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
            script {
                def imageList = sh(returnStdout: true, script: "docker images -q ${IMAGE_NAME}:${env.BUILD_ID}").trim()
                if (imageList) {
                    sh "docker rmi ${IMAGE_NAME}:${env.BUILD_ID} || true"
                } else {
                    echo "Image ${IMAGE_NAME}:${env.BUILD_ID} does not exist locally, skipping cleanup."
                }

                imageList = sh(returnStdout: true, script: "docker images -q ${IMAGE_NAME}:latest").trim()
                if (imageList) {
                    sh "docker rmi ${IMAGE_NAME}:latest || true"
                } else {
                    echo "Image ${IMAGE_NAME}:latest does not exist locally, skipping cleanup."
                }
            }
        }
    }
}
