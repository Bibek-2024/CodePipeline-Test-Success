pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID = "845561723983"
        AWS_REGION     = "ap-south-1"
        ECR_REPO_NAME  = "mini-devops-test"
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME = "${ECR_URL}/${ECR_REPO_NAME}"
        EXTERNAL_PORT  = "80"
        INTERNAL_PORT  = "3000"
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
                    sh "docker build --no-cache -t ${ECR_REPO_NAME}:latest ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:latest"
                    sh "docker push ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                    sh "docker push ${FULL_IMAGE_NAME}:latest"
                }
            }
        }

        stage('Local Deploy') {
            steps {
                script {
                    sh "docker stop mini-app-test || true"
                    sh "docker rm mini-app-test || true"
                    sh "docker run -d --name mini-app-test -p ${EXTERNAL_PORT}:${INTERNAL_PORT} ${FULL_IMAGE_NAME}:latest"
                }
            }
        }

        stage('ECR Retention') {
            steps {
                script {
                    sh "docker image prune -f"
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
}
