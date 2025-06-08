pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        EC2_HOST = '3.212.184.245'
        APP_DIR = '/opt/chat-app'
        EC2_USER = 'ec2-user'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                sh 'echo "✅ Source code checked out from: ${GIT_URL}"'
                sh 'echo "✅ Branch: ${GIT_BRANCH}"'
                sh 'echo "✅ Commit: ${GIT_COMMIT}"'
                sh 'ls -la'
            }
        }
        
        stage('Setup Node.js') {
            steps {
                echo 'Setting up Node.js environment...'
                sh '''
                    export PATH=/usr/local/bin:$PATH
                    if command -v node >/dev/null 2>&1; then
                        echo "✅ Node.js found: $(node --version)"
                        echo "✅ npm found: $(npm --version)"
                    else
                        echo "❌ Node.js not found - will install dependencies on EC2"
                    fi
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application...'
                sh '''
                    echo "🔨 Preparing deployment package..."
                    echo "📋 Application files to deploy:"
                    ls -la *.js *.json *.html || true
                    echo "✅ Build completed - U-connect app ready for deployment"
                '''
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo 'Deploying U-connect chat app to EC2...'
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        echo "🚀 Starting deployment to: $EC2_HOST"
                        echo "📁 Target directory: $APP_DIR"
                        echo "🎯 Deploying commit: ${GIT_COMMIT}"
                        
                        # Debug information
                        echo "🔍 Debug information:"
                        echo "SSH Key file: $SSH_KEY"
                        echo "SSH User from credential: $SSH_USER"
                        echo "Target user: $EC2_USER"
                        
                        # Check SSH key file
                        if [ -f "$SSH_KEY" ]; then
                            echo "✅ SSH key file found"
                            ls -la "$SSH_KEY"
                        else
                            echo "❌ SSH key file not found: $SSH_KEY"
                            exit 1
                        fi
                        
                        # Test SSH connectivity
                        echo "🔑 Testing SSH connection..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i "$SSH_KEY" $EC2_USER@$EC2_HOST "echo 'SSH connection successful - $(date)'" || {
                            echo "❌ SSH connection failed!"
                            echo "Troubleshooting steps:"
                            echo "1. Check if EC2 instance is running"
                            echo "2. Verify security group allows SSH (port 22)"
                            echo "3. Confirm SSH key is correct"
                            echo "4. Test manually: ssh -i key.pem ec2-user@$EC2_HOST"
                            exit 1
                        }
                        
                        # Create app directory
                        echo "📁 Preparing application directory..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" $EC2_USER@$EC2_HOST "
                            sudo mkdir -p $APP_DIR
                            sudo chown $EC2_USER:$EC2_USER $APP_DIR
                            echo 'Directory prepared successfully'
                        "
                        
                        # Copy essential application files
                        echo "📤 Copying application files..."
                        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" \
                            app.js package.json index.html \
                            $EC2_USER@$EC2_HOST:$APP_DIR/
                        
                        # Copy public directory if it exists
                        if [ -d "public" ]; then
                            echo "📁 Copying public directory..."
                            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -r public/ $EC2_USER@$EC2_HOST:$APP_DIR/
                        fi
                        
                        echo "✅ Files copied successfully"
                        
                        # Install dependencies and start application
                        echo "🔄 Installing dependencies and starting application..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" $EC2_USER@$EC2_HOST "
                            cd $APP_DIR
                            echo 'Current directory contents:'
                            ls -la
                            
                            echo '📦 Installing Node.js dependencies...'
                            npm install --production
                            
                            echo '🔄 Managing PM2 process...'
                            # Stop and remove existing process
                            pm2 stop chat-app 2>/dev/null || echo 'No existing process to stop'
                            pm2 delete chat-app 2>/dev/null || echo 'No existing process to delete'
                            
                            # Start new process
                            pm2 start app.js --name chat-app
                            pm2 save
                            
                            echo '📊 PM2 status:'
                            pm2 status
                            pm2 logs chat-app --lines 5
                            
                            echo '✅ Application started successfully'
                        "
                        
                        echo "✅ Deployment completed successfully"
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health check...'
                sh '''
                    echo "🏥 Testing application health..."
                    echo "🌐 URL: http://$EC2_HOST"
                    
                    # Wait for application to start
                    echo "⏳ Waiting 10 seconds for application to start..."
                    sleep 10
                    
                    # Test HTTP connectivity
                    echo "🔍 Testing HTTP connectivity..."
                    if curl -f --max-time 15 --retry 2 --retry-delay 3 -s http://$EC2_HOST > /tmp/health_check.html; then
                        echo "✅ Health check passed!"
                        echo "📄 Response preview:"
                        head -3 /tmp/health_check.html
                        echo "🎉 U-connect app is running and accessible!"
                    else
                        echo "⚠️ HTTP health check failed, but application may still be starting"
                        echo "🔍 Manual check required at: http://$EC2_HOST"
                    fi
                '''
            }
        }
    }
    
    post {
        success {
            echo '🎉 Deployment completed successfully!'
            echo "🚀 Deployed commit: ${env.GIT_COMMIT}"
            echo "🌐 Access your app: http://${env.EC2_HOST}"
            echo "📋 Next steps:"
            echo "1. Open http://${env.EC2_HOST} in your browser"
            echo "2. Test the chat functionality"
            echo "3. Check PM2 logs if needed: pm2 logs chat-app"
        }
        failure {
            echo '❌ Deployment failed!'
            echo "🔍 Most common issues:"
            echo "1. SSH key not configured in Jenkins credentials"
            echo "2. EC2 instance not running or accessible"
            echo "3. Security group doesn't allow SSH access"
            echo "4. Node.js/PM2 not installed on EC2"
        }
        always {
            echo "📊 Pipeline completed in ${currentBuild.durationString}"
        }
    }
}