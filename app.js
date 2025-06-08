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
app.use(express.static('public'));

// Root route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);
  
  // Join notification
  socket.broadcast.emit('user joined', {
    message: 'A user joined the chat',
    timestamp: new Date().toISOString()
  });
  
  // Handle chat messages
  socket.on('chat message', (data) => {
    console.log('Message received:', data);
    // Broadcast message to all clients
    io.emit('chat message', {
      message: data.message,
      user: data.user || 'Anonymous',
      timestamp: new Date().toISOString()
    });
  });
  
  // Handle typing indicator
  socket.on('typing', (data) => {
    socket.broadcast.emit('typing', data);
  });
  
  socket.on('stop typing', () => {
    socket.broadcast.emit('stop typing');
  });
  
  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    socket.broadcast.emit('user left', {
      message: 'A user left the chat',
      timestamp: new Date().toISOString()
    });
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`CEEYIT Chat app running on port ${PORT}`);
  console.log(`Server started at ${new Date().toISOString()}`);
});
