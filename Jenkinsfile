pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID = "845561723983"
        AWS_REGION     = "ap-south-1"
        ECR_REPO_NAME  = "mini-devops-test"
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME = "${ECR_URL}/${ECR_REPO_NAME}:latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                // This now works because Jenkins pulls the context from GitHub
                checkout scm
            }
        }

        stage('ECR Authentication') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_REPO_NAME} ."
                }
            }
        }

        stage('Tag and Push') {
            steps {
                script {
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}"
                    sh "docker push ${FULL_IMAGE_NAME}"
                }
            }
        }
    }

    post {
        success {
            echo "--- AUTO-TRIGGER SUCCESS: ${FULL_IMAGE_NAME} is in ECR ---"
        }
    }
}
