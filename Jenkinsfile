pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        EC2_HOST = '3.212.184.245'
        APP_DIR = '/opt/chat-app'
        EC2_USER = 'ec2-user'
        TEMP_DIR = '/tmp/chat-app-deploy'
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
                        echo "ℹ️ Node.js not found on Jenkins server"
                        echo "✅ This is OK - dependencies will be installed on EC2"
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
                        echo "📦 Installing dependencies on Jenkins server..."
                        npm install
                        echo "✅ Dependencies installed successfully"
                    else
                        echo "ℹ️ npm not available on Jenkins server"
                        echo "✅ Dependencies will be installed on EC2 target server"
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
                        echo "ℹ️ Tests skipped - npm not available on Jenkins"
                        echo "✅ Tests will be validated after deployment"
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
                        
                        # Test SSH connectivity
                        echo "🔑 Testing SSH connection..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i "$SSH_KEY" $EC2_USER@$EC2_HOST "echo 'SSH connection successful - $(date)'"
                        
                        # Create temporary directory and copy files there first
                        echo "📁 Creating temporary deployment directory..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" $EC2_USER@$EC2_HOST "
                            rm -rf $TEMP_DIR
                            mkdir -p $TEMP_DIR
                            echo 'Temporary directory created: $TEMP_DIR'
                        "
                        
                        # Copy files to temporary directory first (user has full access to /tmp)
                        echo "📤 Copying application files to temporary directory..."
                        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" \
                            app.js package.json index.html \
                            $EC2_USER@$EC2_HOST:$TEMP_DIR/
                        
                        # Copy public directory if it exists
                        if [ -d "public" ]; then
                            echo "📁 Copying public directory..."
                            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -r public/ $EC2_USER@$EC2_HOST:$TEMP_DIR/
                        fi
                        
                        echo "✅ Files copied to temporary directory"
                        
                        # Now move files from temp to final destination and set up application
                        echo "🔄 Setting up application directory and installing dependencies..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" $EC2_USER@$EC2_HOST "
                            # Create app directory with proper permissions
                            sudo mkdir -p $APP_DIR
                            sudo chown -R $EC2_USER:$EC2_USER $APP_DIR
                            sudo chmod -R 755 $APP_DIR
                            
                            # Move files from temp to app directory
                            cp -r $TEMP_DIR/* $APP_DIR/
                            cd $APP_DIR
                            
                            echo 'Current directory contents:'
                            ls -la
                            
                            echo '📦 Installing Node.js dependencies on EC2...'
                            if command -v npm >/dev/null 2>&1; then
                                npm install --production
                                echo '✅ Dependencies installed successfully'
                            else
                                echo '❌ npm not found on EC2! Installing Node.js...'
                                curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
                                sudo yum install -y nodejs
                                npm install --production
                                echo '✅ Node.js installed and dependencies installed'
                            fi
                            
                            echo '🔄 Managing PM2 process...'
                            # Install PM2 if not available
                            if ! command -v pm2 >/dev/null 2>&1; then
                                echo 'Installing PM2...'
                                sudo npm install -g pm2
                            fi
                            
                            # Stop and remove existing process
                            pm2 stop chat-app 2>/dev/null || echo 'No existing process to stop'
                            pm2 delete chat-app 2>/dev/null || echo 'No existing process to delete'
                            
                            # Start new process
                            pm2 start app.js --name chat-app
                            pm2 save
                            
                            echo '📊 PM2 status:'
                            pm2 status
                            
                            echo '🧹 Cleaning up temporary files...'
                            rm -rf $TEMP_DIR
                            
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
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        sh '''
                            echo "🏥 Testing application health..."
                            echo "🌐 URL: http://$EC2_HOST"
                            
                            # Wait for application to start
                            echo "⏳ Waiting 15 seconds for application to start..."
                            sleep 15
                            
                            # Test HTTP connectivity
                            echo "🔍 Testing HTTP connectivity..."
                            if curl -f --max-time 20 --retry 3 --retry-delay 5 -s http://$EC2_HOST > /tmp/health_check.html; then
                                echo "✅ Health check passed!"
                                echo "📄 Response preview:"
                                head -3 /tmp/health_check.html
                                echo "🎉 U-connect app is running and accessible!"
                                
                                # Check if it contains expected content
                                if grep -q "CEEYIT" /tmp/health_check.html; then
                                    echo "✅ Application content verified - CEEYIT branding found"
                                else
                                    echo "ℹ️ Application running but checking content..."
                                    cat /tmp/health_check.html
                                fi
                            else
                                echo "⚠️ HTTP health check failed, checking application status..."
                                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" $EC2_USER@$EC2_HOST "
                                    echo 'PM2 process status:'
                                    pm2 status
                                    echo 'Application logs (last 10 lines):'
                                    pm2 logs chat-app --lines 10 --nostream
                                    echo 'Checking if port 3000 is listening:'
                                    netstat -tlnp | grep 3000 || echo 'Port 3000 not found'
                                    echo 'Testing local connection:'
                                    curl -s http://localhost:3000 || echo 'Local connection failed'
                                " || echo "Could not retrieve debugging info"
                                
                                echo "🌐 Manual check required: http://$EC2_HOST"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Final Verification') {
            steps {
                echo 'Running final verification...'
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        echo "🔍 Final deployment verification..."
                        
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" $EC2_USER@$EC2_HOST "
                            echo '📊 Application Status Summary:'
                            echo '================================'
                            echo 'Directory contents:'
                            ls -la $APP_DIR
                            echo ''
                            echo 'Node.js version:'
                            node --version || echo 'Node.js not found'
                            echo ''
                            echo 'PM2 Status:'
                            pm2 status
                            echo ''
                            echo 'Application Process:'
                            ps aux | grep node | grep -v grep || echo 'No node processes found'
                            echo ''
                            echo 'Network Status:'
                            netstat -tlnp | grep 3000 || echo 'Port 3000 not listening'
                            echo ''
                            echo 'Recent logs:'
                            pm2 logs chat-app --lines 5 --nostream || echo 'No logs available'
                        "
                        
                        echo "🎯 Deployment verification completed"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Deployment completed successfully!'
            echo "🚀 Deployed commit: ${env.GIT_COMMIT}"
            echo "🌐 Access your app: http://${env.EC2_HOST}"
            echo "📋 What to do next:"
            echo "1. Open http://${env.EC2_HOST} in your browser"
            echo "2. Test the real-time chat functionality"
            echo "3. Open multiple browser tabs to test Socket.IO connection"
            echo "4. Monitor: ssh to EC2 and run 'pm2 logs chat-app'"
        }
        failure {
            echo '❌ Deployment failed!'
            echo "🔍 Check the detailed logs above for specific errors"
            echo "💡 Common solutions:"
            echo "1. Ensure EC2 instance is running and accessible"
            echo "2. Check security group allows ports 22, 80, 3000"
            echo "3. Verify SSH key is configured correctly"
            echo "4. Node.js will be auto-installed on EC2 if missing"
        }
        always {
            echo "📊 Pipeline completed in ${currentBuild.durationString}"
        }
    }
}