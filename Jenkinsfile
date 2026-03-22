pipeline {
    agent any
    
    environment {
        // AWS Configuration (Mumbai)
        AWS_ACCOUNT_ID = "845561723983"
        AWS_REGION     = "ap-south-1"
        ECR_REPO_NAME  = "mini-devops-test"
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME = "${ECR_URL}/${ECR_REPO_NAME}"
        
        // Port Configuration
        EXTERNAL_PORT  = "80"
        INTERNAL_PORT  = "3000"
        
        // Versioning
        BUILD_TAG      = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                // Automatically pulls from your GitHub repo
                checkout scm
            }
        }

        stage('ECR Login') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    // --no-cache ensures the 'echo' in your Dockerfile actually updates
                    sh "docker build --no-cache -t ${ECR_REPO_NAME}:latest ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Tagging for history and 'latest' pointer
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:latest"
                    
                    sh "docker push ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                    sh "docker push ${FULL_IMAGE_NAME}:latest"
                }
            }
        }

        stage('Local Deploy (Permanent)') {
            steps {
                script {
                    echo "Stopping old container..."
                    sh "docker stop mini-app-test || true"
                    sh "docker rm mini-app-test || true"
                    
                    echo "Deploying with Auto-Restart enabled..."
                    // --restart unless-stopped makes this permanent across EC2 reboots
                    sh "docker run -d --restart unless-stopped --name mini-app-test -p ${EXTERNAL_PORT}:${INTERNAL_PORT} ${FULL_IMAGE_NAME}:latest"
                }
            }
        }

        stage('ECR Retention') {
            steps {
                script {
                    echo "Cleaning local Docker cache..."
                    sh "docker image prune -f"
                    
                    echo "Keeping only the last 2 images in ECR history..."
                    sh """
                        IMAGES_TO_DELETE=\$(aws ecr describe-images --repository-name ${ECR_REPO_NAME} --query 'imageDetails[?imageTags!=null] | sort_by(@, &imagePushedAt) | [:-2].imageDigest' --output text)
                        if [ ! -z "\$IMAGES_TO_DELETE" ]; then
                            for digest in \$IMAGES_TO_DELETE; do
                                aws ecr batch-delete-image --repository-name ${ECR_REPO_NAME} --image-ids imageDigest=\$digest
                            done
                        fi
                    """
                }
            }
        }
    }

    post {
        success {
            echo "-----------------------------------------------------------"
            echo "SUCCESS: Build #${BUILD_TAG} is LIVE and PERMANENT"
            echo "URL: http://your-ec2-public-ip"
            echo "-----------------------------------------------------------"
        }
    }
}
