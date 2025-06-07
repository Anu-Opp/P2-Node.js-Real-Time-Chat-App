# CEEYIT Real-Time Chat Application

[![Build Status](https://jenkins.example.com/buildStatus/icon?job=chat-app)](https://jenkins.example.com/job/chat-app/)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)

## Description

A real-time chat application built with Node.js, Express, and Socket.IO. This application demonstrates modern DevOps practices including Infrastructure as Code (Terraform), Configuration Management (Ansible), and CI/CD pipelines (Jenkins).

## Features

- **Real-time messaging** using Socket.IO
- **User join/leave notifications**
- **Typing indicators**
- **Responsive design** for mobile and desktop
- **Health check endpoint** for monitoring
- **Production-ready deployment** with PM2 and Nginx

## Technology Stack

### Frontend
- HTML5, CSS3, JavaScript (ES6+)
- Socket.IO Client
- Responsive design with CSS Grid/Flexbox

### Backend
- Node.js (v18+)
- Express.js
- Socket.IO Server
- PM2 for process management

### Infrastructure & DevOps
- **Cloud Platform**: AWS (EC2, VPC, Security Groups, Elastic IP)
- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **CI/CD**: Jenkins
- **Web Server**: Nginx (reverse proxy)
- **Process Manager**: PM2

## Architecture

```
Internet → AWS ELB → Nginx → Node.js App (PM2) → Socket.IO
                                ↓
                          Health Checks & Monitoring
```

## Local Development

### Prerequisites
- Node.js (v18 or higher)
- npm or yarn

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd nodejs-chat-app
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Open your browser and navigate to `http://localhost:3000`

### Testing
```bash
npm test
```

## Production Deployment

### Prerequisites
- AWS Account with appropriate permissions
- Terraform installed
- Ansible installed
- Jenkins server (optional for CI/CD)

### Infrastructure Deployment

1. **Deploy Infrastructure with Terraform**:
```bash
cd ../nodejs-chat-terraform
terraform init
terraform plan
terraform apply
```

2. **Configure Server with Ansible**:
```bash
cd ../ansible-config
# Update inventory file with EC2 IP from Terraform output
ansible-playbook playbook.yml
```

3. **Deploy Application**:
```bash
# Manual deployment
scp -r nodejs-chat-app/* ec2-user@<EC2-IP>:/tmp/
ssh ec2-user@<EC2-IP>
sudo cp -r /tmp/* /opt/chat-app/
sudo chown -R nodejs:nodejs /opt/chat-app
cd /opt/chat-app
sudo -u nodejs npm install --production
sudo -u nodejs pm2 start ecosystem.config.js
```

### CI/CD with Jenkins

1. Configure Jenkins with required plugins
2. Add EC2 SSH credentials to Jenkins
3. Create a new Pipeline job pointing to this repository
4. The Jenkinsfile will handle automated deployment

## Configuration

### Environment Variables
- `PORT`: Application port (default: 3000)
- `NODE_ENV`: Environment mode (development/production)

### PM2 Configuration
The application uses PM2 for process management in production. Configuration is in `ecosystem.config.js`.

### Nginx Configuration
Nginx acts as a reverse proxy and is configured via Ansible playbook.

## API Endpoints

- `GET /`: Main chat application
- `GET /health`: Health check endpoint (returns JSON status)

## Socket.IO Events

### Client to Server
- `chat message`: Send a chat message
- `typing`: User is typing
- `stop typing`: User stopped typing

### Server to Client
- `chat message`: Broadcast chat message
- `user joined`: User joined notification
- `user left`: User left notification
- `typing`: Someone is typing
- `stop typing`: Stop typing indicator

## Monitoring & Logs

### Application Logs
- PM2 logs: `/var/log/chat-app.log`
- Error logs: `/var/log/chat-app-error.log`
- Output logs: `/var/log/chat-app-out.log`

### Nginx Logs
- Access logs: `/var/log/nginx/access.log`
- Error logs: `/var/log/nginx/error.log`

### Health Monitoring
- Health endpoint: `http://<server-ip>/health`
- PM2 monitoring: `pm2 monit`

## Security Considerations

- **Security Groups**: Configured to allow only necessary ports (22, 80, 443)
- **Firewall**: UFW/firewalld configured on server
- **Process Isolation**: Application runs as non-root user (nodejs)
- **Input Sanitization**: XSS protection on client-side
- **HTTPS Ready**: SSL can be configured with Let's Encrypt

## Troubleshooting

### Common Issues

1. **Application not starting**:
   ```bash
   sudo -u nodejs pm2 logs chat-app
   ```

2. **Nginx issues**:
   ```bash
   sudo systemctl status nginx
   sudo nginx -t  # Test configuration
   ```

3. **Firewall blocking connections**:
   ```bash
   sudo firewall-cmd --list-all
   ```

4. **Node.js dependencies**:
   ```bash
   cd /opt/chat-app
   sudo -u nodejs npm install
   ```

### Log Locations
- Application: `/var/log/chat-app.log`
- Nginx: `/var/log/nginx/`
- System: `/var/log/messages`

## Performance Optimization

- **PM2 Cluster Mode**: For high-traffic scenarios
- **Nginx Caching**: Can be configured for static assets
- **Load Balancing**: Multiple EC2 instances with ALB
- **Database**: Add Redis for session storage and message persistence

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the troubleshooting section above

## Changelog

### v1.0.0
- Initial release
- Real-time chat functionality
- Complete DevOps pipeline
- Production deployment ready

---

**CEEYIT DevOps Project** - Demonstrating modern cloud-native application deployment practices.
