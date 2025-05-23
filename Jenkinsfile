pipeline {
    agent any
    tools {
        maven 'Maven'
    }

    environment {
        GCP_PROJECT = 'active-alchemy-459306-v2'     
        GKE_CLUSTER = 'kube-cluster'                 
        GKE_ZONE = 'us-central1-c'                   
        CREDENTIALS_ID = 'gcp-service-account'       
        IMAGE_NAME = "gcr.io/${GCP_PROJECT}/gcp-spring-project"  
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

        stage('Build Docker Image') {
            steps {
                script {
                   def myimage = docker.build("gcr.io/active-alchemy-459306-v2/gcp-spring-project:${BUILD_NUMBER}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                        myimage.push("${env.BUILD_ID}")
                        myimage.push("latest")
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

                    
                    def files = ['kubernetes/deployment.yaml', 'kubernetes/service.yaml']
                    files.each { file ->
                        sh "sed -i 's|gcr.io/.*/gcp-spring-project:.*|${IMAGE_NAME}:${env.BUILD_ID}|' ${file}"
                    }

                    
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
