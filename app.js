const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Route to serve index.html
app.get('/', (req, res) => {
  res.sendFile('index.html', { root: __dirname });
});

io.on('connection', (socket) => {
  console.log('User connected');
  socket.on('disconnect', () => {
    console.log('User disconnected');
  });
});

server.listen(3000, () => {
  console.log('Chat app running on port 3000');
});
