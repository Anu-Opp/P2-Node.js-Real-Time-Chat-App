const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Serve the main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Store connected users
let connectedUsers = 0;
let userSockets = new Map();

// Socket.IO connection handling
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);
    connectedUsers++;
    
    // Send initial data to new user
    socket.emit('welcome message', { 
        message: 'Welcome to CEEYIT Chat! 🎉' 
    });
    
    socket.emit('user count', { count: connectedUsers });
    
    // Notify all users about user count update
    io.emit('user count', { count: connectedUsers });
    
    // Handle user joining with profile
    socket.on('user join', (userData) => {
        console.log('User joined:', userData);
        socket.userData = userData;
        userSockets.set(socket.id, userData);
        
        // Notify all users about new user
        socket.broadcast.emit('user joined', {
            message: `${userData.username} joined the chat`,
            userCount: connectedUsers
        });
    });
    
    // Handle chat messages
    socket.on('chat message', (data) => {
        console.log('Message received:', data);
        const messageData = {
            username: socket.userData?.username || 'Anonymous',
            avatar: socket.userData?.avatar || '😊',
            color: socket.userData?.color || '#667eea',
            message: data.message,
            timestamp: new Date().toISOString()
        };
        
        // Broadcast message to all users including sender
        io.emit('chat message', messageData);
    });
    
    // Handle typing indicators
    socket.on('typing start', () => {
        if (socket.userData) {
            socket.broadcast.emit('user typing', {
                username: socket.userData.username,
                avatar: socket.userData.avatar
            });
        }
    });
    
    socket.on('typing stop', () => {
        if (socket.userData) {
            socket.broadcast.emit('user stop typing', {
                username: socket.userData.username
            });
        }
    });
    
    // Handle disconnect
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
        connectedUsers--;
        
        if (socket.userData) {
            userSockets.delete(socket.id);
            
            // Notify all users about user leaving
            socket.broadcast.emit('user left', {
                message: `${socket.userData.username} left the chat`,
                userCount: connectedUsers
            });
        }
        
        // Update user count for all remaining users
        io.emit('user count', { count: connectedUsers });
    });
});

// Start server - IMPORTANT: Listen on all interfaces (0.0.0.0)
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`CEEYIT Chat app running on port ${PORT}`);
    console.log(`Server started at ${new Date().toISOString()}`);
    console.log(`Access via: http://0.0.0.0:${PORT}`);
});