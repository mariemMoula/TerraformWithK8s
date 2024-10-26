pipeline {
    agent any

    environment {
        registry = "mimi019/docker-spring-boot"
        registryCredential = 'dockerhub_credentials'
        sonarqubeCredential = 'sonarqube_credentials'
        awsCredentialsId = 'aws_credentials'
        dockerImage = ''
        clusterName = 'my_Kubernetes'
        region = 'us-east-1'
        namespace = 'kubernetes-namespace'
        terraformDir = 'terraform'  // Ensure this points to your Terraform config directory
    }

    stages {
        stage('Checkout Git') {
            steps {
                script {
                    echo 'Checking out code from Git...'
                    git 'https://github.com/mariemMoula/TerraformWithK8s.git'
                }
            }
        }

        stage('Checkout Terraform Repo') {
            steps {
                script {
                    echo 'Cloning Terraform repository...'
                    dir(terraformDir) {
                        git 'https://github.com/mariemMoula/TerraformWithK8s.git'
                    }
                }
            }
        }

        stage('Maven Clean') {
            steps {
                script {
                    echo 'Cleaning Maven project...'
                    sh 'mvn clean'
                }
            }
        }

        stage('Artifact Construction') {
            steps {
                script {
                    echo 'Constructing artifacts...'
                    sh 'mvn package -Dmaven.test.skip=true -P test-coverage'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    echo 'Launching Unit Tests...'
                    sh 'mvn test'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    echo 'Running SonarQube analysis...'
                    withCredentials([usernamePassword(credentialsId: sonarqubeCredential, usernameVariable: 'SONAR_USER', passwordVariable: 'SONAR_PASSWORD')]) {
                        sh 'mvn sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASSWORD'
                    }
                }
            }
        }

        stage('Publish to Nexus') {
            steps {
                script {
                    echo 'Publishing artifacts to Nexus...'
                    sh 'mvn deploy -DaltDeploymentRepository=nexus-releases::default::http://nexus:8081/repository/maven-releases/'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    dockerImage = docker.build("${registry}:${BUILD_NUMBER}")
                }
            }
        }

        stage('Deploy Docker Image') {
            steps {
                script {
                    echo 'Deploying Docker image to Docker Hub...'
                    docker.withRegistry('https://index.docker.io/v1/', registryCredential) {
                        dockerImage.push()
                    }
                }
            }
        }

        stage('Test AWS Credentials') {
            steps {
                script {
                    echo 'Testing AWS credentials...'
                    withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                        def awsCredentials = readFile(AWS_CREDENTIALS_FILE).trim().split("\n")
                        env.AWS_ACCESS_KEY_ID = awsCredentials.find { it.startsWith("aws_access_key_id") }.split("=")[1].trim()
                        env.AWS_SECRET_ACCESS_KEY = awsCredentials.find { it.startsWith("aws_secret_access_key") }.split("=")[1].trim()
                        env.AWS_SESSION_TOKEN = awsCredentials.find { it.startsWith("aws_session_token") }?.split("=")[1]?.trim()

                        echo "AWS Access Key ID: ${env.AWS_ACCESS_KEY_ID}"
                        echo "AWS Credentials File Loaded"

                        sh 'aws sts get-caller-identity'
                    }
                }
            }
        }

        stage('Terraform Setup') {
            steps {
                script {
                    echo 'Setting up Terraform...'
                    dir(terraformDir) {  // Ensure this points to your Terraform config directory
                        sh 'pwd'  // Print the current directory
                        sh 'ls -al'  // List all files in the directory
                        sh 'terraform init'
                        sh 'terraform validate'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Configure Kubernetes') {
            steps {
                script {
                    echo 'Configuring kubectl with AWS IAM...'
                    withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                        // Load AWS credentials
                        def awsCredentials = readFile(AWS_CREDENTIALS_FILE).trim().split("\n")
                        env.AWS_ACCESS_KEY_ID = awsCredentials.find { it.startsWith("aws_access_key_id") }.split("=")[1].trim()
                        env.AWS_SECRET_ACCESS_KEY = awsCredentials.find { it.startsWith("aws_secret_access_key") }.split("=")[1].trim()
                        env.AWS_SESSION_TOKEN = awsCredentials.find { it.startsWith("aws_session_token") }?.split("=")[1]?.trim()

                        // Run the update kubeconfig command
                        def result = sh(script: "aws eks --region ${region} update-kubeconfig --name ${clusterName}", returnStdout: true).trim()
                        echo "Kubeconfig output: ${result}"

                        // Optional: Check the current context
                        sh 'kubectl config current-context'
                    }
                }
            }
        }

        stage('Deploy to AWS Kubernetes') {
            steps {
                script {
                    echo 'Deploying Docker image to AWS Kubernetes...'
                    withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                        // Deploy to Kubernetes using the specified kubeconfig
                        sh """
                        kubectl apply -f deployment.yaml
                        kubectl apply -f service.yaml
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
