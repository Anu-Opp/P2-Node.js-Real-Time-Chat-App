# Deployment Guide - CEEYIT Chat Application

## Overview

This guide provides step-by-step instructions for deploying the CEEYIT Real-Time Chat Application using Infrastructure as Code (Terraform), Configuration Management (Ansible), and CI/CD (Jenkins).

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (v2.9+)
- [AWS CLI](https://aws.amazon.com/cli/) (v2.0+)
- [Node.js](https://nodejs.org/) (v18+)
- [Git](https://git-scm.com/)

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- EC2 Key Pair created in target region

### Permissions Required
- EC2: Full access
- VPC: Full access
- IAM: Limited access for role creation
- Route53: Full access (if using custom domain)

## Phase 1: Infrastructure Deployment

### Step 1: Prepare Terraform Configuration

1. **Navigate to Terraform directory**:
```bash
cd nodejs-chat-terraform
```

2. **Update variables** in `variables.tf`:
```hcl
variable "key_name" {
  description = "AWS Key Pair name"
  type        = string
  default     = "your-actual-key-name"  # REPLACE THIS
}
```

3. **Initialize Terraform**:
```bash
terraform init
```

4. **Review the plan**:
```bash
terraform plan
```

5. **Apply the configuration**:
```bash
terraform apply
```
   - Type `yes` when prompted
   - **Note the public IP** from the output

### Step 2: Verify Infrastructure

1. **Check Terraform outputs**:
```bash
terraform output
```

2. **Verify EC2 instance** in AWS Console:
   - Instance should be running
   - Security groups configured
   - Elastic IP attached

## Phase 2: Server Configuration

### Step 1: Update Ansible Inventory

1. **Navigate to Ansible directory**:
```bash
cd ../ansible-config
```

2. **Update inventory file** with actual EC2 IP:
```bash
# Edit inventory file
nano inventory

# Replace REPLACE_WITH_EC2_IP with actual IP from Terraform output
[chat_servers]
chat-server ansible_host=YOUR_ACTUAL_EC2_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

3. **Update ansible.cfg** with correct key path:
```bash
nano ansible.cfg

# Update private_key_file path to your actual key location
```

### Step 2: Test Ansible Connection

```bash
# Test connectivity
ansible chat_servers -m ping

# Should return:
# chat-server | SUCCESS => {
#     "ansible_facts": {
#         "discovered_interpreter_python": "/usr/bin/python"
#     },
#     "changed": false,
#     "ping": "pong"
# }
```

### Step 3: Run Ansible Playbook

```bash
# Run the playbook
ansible-playbook playbook.yml -v

# This will:
# - Update system packages
# - Install Node.js, npm, Nginx
# - Configure firewall
# - Set up application user and directories
# - Configure Nginx as reverse proxy
# - Install PM2 process manager
```

## Phase 3: Application Deployment

### Step 1: Prepare Application

1. **Navigate to application directory**:
```bash
cd ../nodejs-chat-app
```

2. **Test application locally** (optional):
```bash
npm install
npm start
# Test at http://localhost:3000
```

### Step 2: Deploy Application to Server

1. **Copy application files**:
```bash
# Copy files to temporary location
scp -i ~/.ssh/your-key.pem -r ./* ec2-user@YOUR_EC2_IP:/tmp/chat-app/
```

2. **SSH into server and deploy**:
```bash
# Connect to server
ssh -i ~/.ssh/your-key.pem ec2-user@YOUR_EC2_IP

# Move files to application directory
sudo mkdir -p /opt/chat-app
sudo cp -r /tmp/chat-app/* /opt/chat-app/
sudo chown -R nodejs:nodejs /opt/chat-app

# Install dependencies
cd /opt/chat-app
sudo -u nodejs npm install --production

# Start application with PM2
sudo -u nodejs pm2 start ecosystem.config.js
sudo -u nodejs pm2 startup systemd
sudo -u nodejs pm2 save

# Verify application is running
sudo -u nodejs pm2 status
```

### Step 3: Verify Deployment

1. **Check application status**:
```bash
# PM2 status
sudo -u nodejs pm2 status

# Application logs
sudo -u nodejs pm2 logs chat-app

# Nginx status
sudo systemctl status nginx
```

2. **Test application**:
```bash
# Health check
curl http://YOUR_EC2_IP/health

# Should return: {"status":"OK","timestamp":"..."}
```

3. **Access application**:
   - Open browser to `http://YOUR_EC2_IP`
   - Test chat functionality

## Phase 4: CI/CD Setup (Optional)

### Step 1: Prepare Jenkins

1. **Install Jenkins** on separate server or use existing
2. **Install required plugins**:
   - NodeJS Plugin
   - SSH Agent Plugin
   - Pipeline Plugin

### Step 2: Configure Jenkins Credentials

1. **Add SSH Key**:
   - Manage Jenkins → Manage Credentials
   - Add Secret File (your EC2 key)
   - ID: `ec2-ssh-key`

2. **Add GitHub credentials** (if using private repo)

### Step 3: Update Jenkinsfile

1. **Edit Jenkinsfile** in your application:
```groovy
environment {
    AWS_REGION = 'us-east-1'
    EC2_HOST = 'YOUR_ACTUAL_EC2_IP'  // Update this
    SSH_KEY = credentials('ec2-ssh-key')
    APP_DIR = '/opt/chat-app'
}
```

### Step 4: Create Jenkins Pipeline

1. **New Item** → Pipeline
2. **Pipeline from SCM** → Git
3. **Repository URL**: Your Git repository
4. **Credentials**: Your GitHub credentials
5. **Script Path**: `Jenkinsfile`

## Phase 5: SSL Configuration (Optional)

### Step 1: Install Certbot

```bash
# On your EC2 server
sudo yum install certbot python3-certbot-nginx
```

### Step 2: Obtain SSL Certificate

```bash
# Replace with your domain
sudo certbot --nginx -d your-domain.com

# Follow the prompts
# Certbot will automatically update Nginx configuration
```

### Step 3: Test SSL Renewal

```bash
# Test automatic renewal
sudo certbot renew --dry-run
```

## Phase 6: Monitoring Setup (Optional)

### Step 1: Install Monitoring Tools

```bash
# Install htop for system monitoring
sudo yum install htop

# PM2 monitoring
sudo -u nodejs pm2 install pm2-logrotate
```

### Step 2: Set up Log Rotation

```bash
# Configure logrotate for application logs
sudo nano /etc/logrotate.d/chat-app

# Add configuration:
/var/log/chat-app*.log {
    daily
    missingok
    rotate 52
    compress
    notifempty
    create 644 nodejs nodejs
    postrotate
        sudo -u nodejs pm2 reloadLogs
    endscript
}
```

## Troubleshooting

### Common Issues and Solutions

1. **Terraform Apply Fails**:
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify region and availability zones
   aws ec2 describe-availability-zones --region us-east-1
   ```

2. **Ansible Connection Fails**:
   ```bash
   # Check SSH key permissions
   chmod 600 ~/.ssh/your-key.pem
   
   # Test direct SSH
   ssh -i ~/.ssh/your-key.pem ec2-user@YOUR_EC2_IP
   ```

3. **Application Not Starting**:
   ```bash
   # Check Node.js installation
   node --version
   npm --version
   
   # Check application logs
   sudo -u nodejs pm2 logs chat-app
   
   # Check if port is in use
   sudo netstat -tlnp | grep :3000
   ```

4. **Nginx Not Serving**:
   ```bash
   # Test Nginx configuration
   sudo nginx -t
   
   # Check Nginx status
   sudo systemctl status nginx
   
   # Check Nginx logs
   sudo tail -f /var/log/nginx/error.log
   ```

5. **Firewall Issues**:
   ```bash
   # Check security groups in AWS Console
   # Check local firewall
   sudo firewall-cmd --list-all
   
   # Temporarily disable for testing
   sudo systemctl stop firewalld
   ```

### Log Locations

- **Application Logs**: `/var/log/chat-app*.log`
- **Nginx Logs**: `/var/log/nginx/`
- **System Logs**: `/var/log/messages`
- **PM2 Logs**: `sudo -u nodejs pm2 logs`

## Cleanup

### Destroy Infrastructure

```bash
# Navigate to Terraform directory
cd nodejs-chat-terraform

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

## Security Best Practices

1. **Regular Updates**:
   ```bash
   # Update system packages
   sudo yum update -y
   
   # Update Node.js dependencies
   cd /opt/chat-app && sudo -u nodejs npm audit fix
   ```

2. **Backup Strategy**:
   - Regular EC2 snapshots
   - Application code in Git
   - Database backups (if applicable)

3. **Monitoring**:
   - Set up CloudWatch alarms
   - Monitor application logs
   - Regular security audits

## Performance Optimization

1. **PM2 Cluster Mode**:
   ```javascript
   // Update ecosystem.config.js
   instances: 'max',
   exec_mode: 'cluster'
   ```

2. **Nginx Optimization**:
   ```nginx
   # Add to Nginx configuration
   gzip on;
   gzip_types text/plain text/css application/javascript;
   ```

3. **Caching**:
   - Implement Redis for session storage
   - Add CDN for static assets

## Next Steps

1. **High Availability**: Deploy across multiple AZs
2. **Load Balancing**: Add Application Load Balancer
3. **Database**: Add persistent storage (RDS/DynamoDB)
4. **Monitoring**: Implement comprehensive monitoring (CloudWatch, Grafana)
5. **Security**: Implement WAF, security scanning

---

This deployment guide provides a complete workflow for deploying the CEEYIT Chat Application with modern DevOps practices.
