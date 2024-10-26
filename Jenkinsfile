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
        terraformDir = 'terraform'  // Ensure this points to your Terraform directory
    }

    stages {
    stage('Cleanup') {
        steps {
            cleanWs()
        }
    }
        stage('Checkout Git') {
            steps {
                script {
                    echo 'Checking out code from Git...'
                    git branch:'master', url:'https://github.com/mariemMoula/TerraformWithK8s.git'
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
                    sh 'mvn deploy'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    dockerImage = docker.build("${registry}:latest")
                }
            }
        }

        stage('Deploy Docker Image') {
            steps {
                script {
                    echo 'Deploying Docker image to Docker Hub...'
                    docker.withRegistry('https://registry.hub.docker.com', registryCredential) {
                        dockerImage.push()
                    }
                }
            }
        }

        // New Stage to Test AWS Credentials
                stage('Test AWS Credentials') {
                    steps {
                        withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                            script {
                                sh"tree"
                                def awsCredentials = readFile(AWS_CREDENTIALS_FILE).trim().split("\n")
                                env.AWS_ACCESS_KEY_ID = awsCredentials.find { it.startsWith("aws_access_key_id") }.split("=")[1].trim()
                                env.AWS_SECRET_ACCESS_KEY = awsCredentials.find { it.startsWith("aws_secret_access_key") }.split("=")[1].trim()
                                env.AWS_SESSION_TOKEN = awsCredentials.find { it.startsWith("aws_session_token") }?.split("=")[1]?.trim()

                                echo "AWS Access Key ID: ${env.AWS_ACCESS_KEY_ID}"
                                // Optional: echo "AWS Session Token: ${env.AWS_SESSION_TOKEN}"

                                echo "AWS Credentials File Loaded"

                                // Test AWS Credentials
                                sh 'aws sts get-caller-identity' // Ensure AWS CLI can access the credentials
                            }
                        }
                    }
                }

                stage('Retrieve AWS Resources') {
                    steps {
                        withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                            script {
                                def awsCredentials = readFile(AWS_CREDENTIALS_FILE).trim().split("\n")
                                env.AWS_ACCESS_KEY_ID = awsCredentials.find { it.startsWith("aws_access_key_id") }.split("=")[1].trim()
                                env.AWS_SECRET_ACCESS_KEY = awsCredentials.find { it.startsWith("aws_secret_access_key") }.split("=")[1].trim()
                                env.AWS_SESSION_TOKEN = awsCredentials.find { it.startsWith("aws_session_token") }?.split("=")[1]?.trim()

                                echo "AWS Access Key ID: ${env.AWS_ACCESS_KEY_ID}"
                                echo "AWS Credentials File Loaded"

                                // Retrieve role_arn
                                env.ROLE_ARN = sh(script: "aws iam list-roles --query 'Roles[?RoleName==`LabRole`].Arn' --output text", returnStdout: true).trim()
                                echo "Retrieved Role ARN: ${env.ROLE_ARN}"

                                // Retrieve VPC ID
                                env.VPC_ID = sh(script: "aws ec2 describe-vpcs --region ${region} --query 'Vpcs[0].VpcId' --output text", returnStdout: true).trim()
                                echo "Retrieved VPC ID: ${env.VPC_ID}"

                                // Retrieve Subnet IDs
                                def subnetIds = sh(script: "aws ec2 describe-subnets --region ${region} --filters Name=vpc-id,Values=${env.VPC_ID} --query 'Subnets[0:2].SubnetId' --output text", returnStdout: true).trim().split()
                                env.SUBNET_ID_A = subnetIds[0]
                                env.SUBNET_ID_B = subnetIds[1]
                                echo "Retrieved Subnet IDs: ${env.SUBNET_ID_A}, ${env.SUBNET_ID_B}"
                            }
                        }
                    }
                }

                stage('Terraform Setup') {
                    steps {
                        script {
                            // Initialize Terraform
                            sh 'terraform -chdir=terraform init'

                            // Validate Terraform configuration files
                            sh 'terraform -chdir=terraform validate'

                            // Apply the configuration changes
                            // sh 'terraform -chdir=terraform apply -auto-approve -var aws_region=${region} -var cluster_name=${clusterName}'

                            sh """
                                terraform -chdir=terraform apply -auto-approve \
                                    -var aws_region=${region} \
                                    -var cluster_name=${clusterName} \
                                    -var role_arn=${env.ROLE_ARN} \
                                    -var vpc_id=${env.VPC_ID} \
                                    -var 'subnet_ids=[\"${env.SUBNET_ID_A}\",\"${env.SUBNET_ID_B}\"]'
                            """
                        }
                    }
                }


        stage('Configure Kubernetes') {
            steps {
                script {
                    echo 'Configuring kubectl with AWS IAM...'
                    withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                        def awsCredentials = readFile(AWS_CREDENTIALS_FILE).trim().split("\n")
                        env.AWS_ACCESS_KEY_ID = awsCredentials.find { it.startsWith("aws_access_key_id") }.split("=")[1].trim()
                        env.AWS_SECRET_ACCESS_KEY = awsCredentials.find { it.startsWith("aws_secret_access_key") }.split("=")[1].trim()
                        env.AWS_SESSION_TOKEN = awsCredentials.find { it.startsWith("aws_session_token") }?.split("=")[1]?.trim()

                        def result = sh(script: "aws eks --region ${region} update-kubeconfig --name ${clusterName}", returnStdout: true).trim()
                        echo "Kubeconfig output: ${result}"

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
