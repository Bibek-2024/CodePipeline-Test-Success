pipeline {
    agent any
    
    environment {
        // AWS Configuration
        AWS_ACCOUNT_ID = "845561723983"
        AWS_REGION     = "ap-south-1"
        ECR_REPO_NAME  = "mini-devops-test"
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME = "${ECR_URL}/${ECR_REPO_NAME}"
        
        // Port Mapping
        EXTERNAL_PORT  = "80"
        INTERNAL_PORT  = "3000"
        
        // Tagging
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
                // Pulls your 'CodePipeline-Test-Success' repo
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
                    // Forces a fresh build to avoid stale cache issues
                    sh "docker build --no-cache -t ${ECR_REPO_NAME}:latest ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Tag with Build Number for History
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                    // Tag as Latest for Deployment
                    sh "docker tag ${ECR_REPO_NAME}:latest ${FULL_IMAGE_NAME}:latest"
                    
                    sh "docker push ${FULL_IMAGE_NAME}:${BUILD_TAG}"
                    sh "docker push ${FULL_IMAGE_NAME}:latest"
                }
            }
        }

        stage('Local Deploy (Test)') {
            steps {
                script {
                    echo "Stopping previous test container if running..."
                    sh "docker stop mini-app-test || true"
                    sh "docker rm mini-app-test || true"
                    
                    echo "Launching app: Access via http://<EC2-IP>:${EXTERNAL_PORT}"
                    // Maps Host Port 80 to Container Port 3000
                    sh "docker run -d --name mini-app-test -p ${EXTERNAL_PORT}:${INTERNAL_PORT} ${FULL_IMAGE_NAME}:latest"
                }
            }
        }

        stage('ECR Retention & Cleanup') {
            steps {
                script {
                    echo "Removing old local images..."
                    sh "docker image prune -f"
                    
                    echo "Keeping only the last 2 images in ECR..."
                    sh """
                        IMAGES_TO_DELETE=\$(aws ecr describe-images --repository-name ${ECR_REPO_NAME} \
                        --query 'imageDetails[?imageTags!=null] | sort_by(@, &imagePushedAt) | [:-2].imageDigest' \
                        --output text)
                        
                        if [ ! -z "\$IMAGES_TO_DELETE" ]; then
                            for digest in \$IMAGES_TO_DELETE
