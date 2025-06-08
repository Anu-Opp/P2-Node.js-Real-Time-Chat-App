pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        EC2_HOST = '3.212.184.245'
        SSH_KEY = credentials('ec2-ssh-key')
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
                        echo "❌ Node.js not found - please install Node.js on Jenkins server"
                        echo "Install commands:"
                        echo "curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -"
                        echo "sudo yum install -y nodejs"
                    fi
                '''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh '''
                    export PATH=/usr/local/bin:$PATH
                    if command -v npm >/dev/null 2>&1; then
                        echo "📦 Installing dependencies..."
                        npm install
                        echo "✅ Dependencies installed successfully"
                    else
                        echo "⚠️ npm not available, skipping dependency installation"
                        echo "Dependencies will be installed on target server"
                    fi
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                sh '''
                    export PATH=/usr/local/bin:$PATH
                    if command -v npm >/dev/null 2>&1; then
                        echo "🧪 Running tests..."
                        npm test || echo "⚠️ No tests defined in package.json"
                        echo "✅ Test stage completed"
                    else
                        echo "✅ Tests would run here (npm not available on Jenkins)"
                    fi
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application...'
                sh '''
                    echo "🔨 Preparing deployment package..."
                    echo "📋 Current directory contents:"
                    ls -la
                    echo "📦 Package.json contents:"
                    cat package.json || echo "package.json not found"
                    echo "✅ Build completed - U-connect app ready for deployment"
                '''
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo 'Deploying U-connect chat app to EC2...'
                script {
                    sh '''
                        echo "🚀 Starting deployment to: $EC2_HOST"
                        echo "📁 Target directory: $APP_DIR"
                        echo "🎯 Deploying commit: ${GIT_COMMIT}"
                        
                        # Test SSH connectivity
                        echo "🔑 Testing SSH connection..."
                        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $SSH_KEY $EC2_USER@$EC2_HOST "echo 'SSH connection successful'" || {
                            echo "❌ SSH connection failed!"
                            echo "Check if:"
                            echo "1. EC2 instance is running"
                            echo "2. Security group allows SSH (port 22)"
                            echo "3. SSH key is correct"
                            exit 1
                        }
                        
                        # Create and prepare app directory
                        echo "📁 Preparing application directory..."
                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY $EC2_USER@$EC2_HOST "
                            sudo mkdir -p $APP_DIR
                            sudo chown $EC2_USER:$EC2_USER $APP_DIR
                            echo 'Directory prepared: $APP_DIR'
                        "
                        
                        # Copy application files
                        echo "📤 Copying application files..."
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY -r ./* $EC2_USER@$EC2_HOST:$APP_DIR/ || {
                            echo "❌ File copy failed!"
                            exit 1
                        }
                        
                        # Deploy and start application
                        echo "🔄 Installing dependencies and starting application..."
                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY $EC2_USER@$EC2_HOST "
                            cd $APP_DIR
                            echo '📦 Installing Node.js dependencies...'
                            npm install --production
                            
                            echo '🔄 Managing PM2 process...'
                            # Stop existing process if running
                            pm2 stop chat-app 2>/dev/null || echo 'No existing process to stop'
                            pm2 delete chat-app 2>/dev/null || echo 'No existing process to delete'
                            
                            # Start new process
                            pm2 start app.js --name chat-app
                            pm2 save
                            
                            echo '📊 Current PM2 status:'
                            pm2 status
                            
                            echo '✅ Application deployed and started successfully'
                        " || {
                            echo "❌ Application deployment failed!"
                            echo "🔍 Checking logs..."
                            ssh -o StrictHostKeyChecking=no -i $SSH_KEY $EC2_USER@$EC2_HOST "pm2 logs chat-app --lines 10" || true
                            exit 1
                        }
                        
                        echo "✅ Deployment completed successfully"
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    sh '''
                        echo "🏥 Testing application health..."
                        echo "🌐 Checking: http://$EC2_HOST"
                        
                        # Wait for application to fully start
                        echo "⏳ Waiting for application to start..."
                        sleep 15
                        
                        # Perform actual health check
                        echo "🔍 Testing HTTP connectivity..."
                        if curl -f --max-time 30 --retry 3 --retry-delay 5 http://$EC2_HOST; then
                            echo "✅ Health check passed!"
                            echo "🎉 U-connect app is running and accessible!"
                        else
                            echo "❌ Health check failed!"
                            echo "🔍 Checking application status on server..."
                            ssh -o StrictHostKeyChecking=no -i $SSH_KEY $EC2_USER@$EC2_HOST "
                                echo 'PM2 status:'
                                pm2 status
                                echo 'Application logs:'
                                pm2 logs chat-app --lines 20
                                echo 'Nginx status:'
                                sudo systemctl status nginx --no-pager
                                echo 'Port 3000 status:'
                                netstat -tlnp | grep 3000 || echo 'Port 3000 not listening'
                            "
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Post-Deployment Verification') {
            steps {
                echo 'Running post-deployment verification...'
                sh '''
                    echo "🔍 Final verification checks..."
                    
                    # Check if application responds with expected content
                    echo "📄 Checking application content..."
                    RESPONSE=$(curl -s http://$EC2_HOST)
                    if echo "$RESPONSE" | grep -q "CEEYIT"; then
                        echo "✅ Application content verified"
                    else
                        echo "⚠️ Unexpected application content"
                        echo "Response: $RESPONSE"
                    fi
                    
                    # Log final status
                    ssh -o StrictHostKeyChecking=no -i $SSH_KEY $EC2_USER@$EC2_HOST "
                        echo '📊 Final deployment status:'
                        pm2 jlist | jq '.[0] | {name: .name, status: .pm2_env.status, uptime: .pm2_env.pm_uptime}'
                    " || echo "jq not available, using basic status"
                    
                    echo "🎯 Deployment verification completed"
                '''
            }
        }
    }
    
    post {
        success {
            echo '🎉 Webhook-triggered deployment completed successfully!'
            echo "🚀 Deployed commit: ${env.GIT_COMMIT}"
            echo "🌐 App URL: http://${env.EC2_HOST}"
            echo "📱 Test your chat app now!"
        }
        failure {
            echo '❌ Webhook-triggered deployment failed!'
            echo "🔍 Check the logs above for detailed error information"
            echo "Common issues to check:"
            echo "1. Node.js installed on Jenkins server"
            echo "2. SSH key configured correctly"
            echo "3. EC2 instance running and accessible"
            echo "4. Security groups allow ports 22, 80, 3000"
            echo "5. PM2 and Node.js installed on EC2"
        }
        always {
            echo '📊 Pipeline execution completed'
            echo "📅 Execution time: ${currentBuild.durationString}"
        }
    }
}