pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        EC2_HOST = 'REPLACE_WITH_EC2_IP'  // Update this after Terraform apply
        SSH_KEY = credentials('ec2-ssh-key')  // Configure in Jenkins
        APP_DIR = '/opt/chat-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh 'npm install'
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                sh 'npm test'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'echo "Build completed - Node.js app ready for deployment"'
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo 'Deploying to EC2 server...'
                script {
                    sh '''
                        # Create deployment directory on remote server
                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@$EC2_HOST '
                            sudo mkdir -p /tmp/app-deployment
                            sudo chown ec2-user:ec2-user /tmp/app-deployment
                        '
                        
                        # Copy application files
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY -r ./* ec2-user@$EC2_HOST:/tmp/app-deployment/
                        
                        # Deploy and restart application
                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@$EC2_HOST '
                            # Stop existing application
                            sudo -u nodejs pm2 stop chat-app || true
                            
                            # Backup current application
                            sudo cp -r $APP_DIR $APP_DIR.backup.$(date +%Y%m%d_%H%M%S) || true
                            
                            # Copy new application files
                            sudo cp -r /tmp/app-deployment/* $APP_DIR/
                            sudo chown -R nodejs:nodejs $APP_DIR
                            
                            # Install dependencies
                            cd $APP_DIR
                            sudo -u nodejs npm install --production
                            
                            # Start application with PM2
                            sudo -u nodejs pm2 start ecosystem.config.js
                            sudo -u nodejs pm2 save
                            
                            # Verify application is running
                            sleep 5
                            sudo -u nodejs pm2 status
                            
                            # Clean up deployment files
                            rm -rf /tmp/app-deployment
                        '
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    sh '''
                        # Wait for application to be ready
                        sleep 10
                        
                        # Check if application is responding
                        curl -f http://$EC2_HOST/health || exit 1
                        echo "Health check passed!"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment completed successfully!'
            slackSend(
                channel: '#deployments', 
                color: 'good', 
                message: "✅ Chat App deployed successfully to ${env.EC2_HOST}"
            )
        }
        failure {
            echo 'Deployment failed!'
            slackSend(
                channel: '#deployments', 
                color: 'danger', 
                message: "❌ Chat App deployment failed on ${env.EC2_HOST}"
            )
        }
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
