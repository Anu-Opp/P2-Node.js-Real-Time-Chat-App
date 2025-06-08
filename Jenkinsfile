pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        EC2_HOST = '3.212.184.245'
        SSH_KEY = credentials('ec2-ssh-key')
        APP_DIR = '/opt/chat-app'
        APP_NAME = 'chat-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                // checkout scm  // Uncomment when using Git
                sh 'echo "✅ Source code ready"'
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
                sh 'echo "✅ Build completed"'
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo 'Deploying U-connect chat app to EC2...'
                script {
                    sh '''
                        # Create deployment directory
                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@$EC2_HOST "sudo mkdir -p /tmp/app-deployment && sudo chown ec2-user:ec2-user /tmp/app-deployment"
                        
                        # Copy files
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY -r ./* ec2-user@$EC2_HOST:/tmp/app-deployment/
                        
                        # Deploy
                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@$EC2_HOST "
                            sudo -u nodejs pm2 stop $APP_NAME || true
                            sudo cp -r $APP_DIR $APP_DIR.backup.$(date +%Y%m%d_%H%M%S) || true
                            sudo cp -r /tmp/app-deployment/* $APP_DIR/
                            sudo chown -R nodejs:nodejs $APP_DIR
                            cd $APP_DIR
                            sudo -u nodejs npm install --production
                            sudo -u nodejs pm2 start ecosystem.config.js
                            sudo -u nodejs pm2 save
                            sleep 5
                            sudo -u nodejs pm2 status
                            rm -rf /tmp/app-deployment
                        "
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    sh '''
                        sleep 15
                        curl -f http://$EC2_HOST/health || exit 1
                        curl -f http://$EC2_HOST || exit 1
                        echo "✅ U-connect app is healthy!"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 U-connect deployment completed successfully!'
            echo "🌐 App: http://${env.EC2_HOST}"
        }
        failure {
            echo '❌ Deployment failed!'
        }
        always {
            cleanWs()
        }
    }
}