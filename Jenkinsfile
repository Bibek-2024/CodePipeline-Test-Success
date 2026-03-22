pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID = "845561723983"
        AWS_REGION     = "ap-south-1"
        ECR_REPO_NAME  = "mini-devops-test"
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME = "${ECR_URL}/${ECR_REPO_NAME}"
        // Current build number for unique tagging
        BUILD_TAG      = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('ECR Login') {
            steps {
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
            }
        }

        stage('Build & Tag') {
            steps {
                script {
                    // Build with --no-cache to ensure a fresh image every time
                    sh "docker build --no-cache -t ${ECR_REPO_NAME}:latest ."
                    
                    // Tag 1: The specific build number (e.g., 6, 7, 8)
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                    
                    // Tag 2: The 'latest' pointer
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:latest"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh "docker push ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                sh "docker push ${FULL_IMAGE_NAME}:latest"
            }
        }

        stage('Cleanup & Retention') {
            steps {
                script {
                    echo "Cleaning up local Docker images to save space on m7i-flex..."
                    sh "docker image prune -f"
                    
                    echo "Enforcing ECR Retention: Keeping only the last 2 tagged images..."
                    // This AWS CLI command finds all images except the 2 most recent and deletes them
                    sh """
                        IMAGES_TO_DELETE=\$(aws ecr describe-images --repository-name ${ECR_REPO_NAME} \
                        --query 'imageDetails[?imageTags!=null] | sort_by(@, &imagePushedAt) | [:-2].imageDigest' \
                        --output text)
                        
                        if [ ! -z "\$IMAGES_TO_DELETE" ]; then
                            for digest in \$IMAGES_TO_DELETE; do
                                aws ecr batch-delete-image --repository-name ${ECR_REPO_NAME} --image-ids imageDigest=\$digest
                            done
                        else
                            echo "No old images to delete."
                        fi
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Successfully pushed Build #${BUILD_TAG} and updated 'latest'. Retention policy applied."
        }
    }
}
