/**
 * WebSocket Server Logic (Socket.io)
 */
const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const config = require('./config');

let io;

// Configuration CORS sécurisée
const getCorsConfig = () => {
    if (config.isProd) {
        // En production, utiliser les origines configurées
        const allowedOrigins = config.cors.origin;
        return {
            origin: (origin, callback) => {
                // Autoriser les connexions sans origin (mobile apps, Postman, etc.)
                if (!origin) return callback(null, true);
                
                // Vérifier si l'origine est autorisée
                const isAllowed = Array.isArray(allowedOrigins) 
                    ? allowedOrigins.includes(origin)
                    : allowedOrigins === origin || allowedOrigins === '*';
                    
                if (isAllowed) {
                    callback(null, true);
                } else {
                    callback(new Error('Not allowed by CORS'));
                }
            },
            methods: ["GET", "POST"],
            credentials: true
        };
    } else {
        // En développement, autoriser toutes les origines mais avec un warning
        console.warn('⚠️  Socket.io CORS: Mode développement - toutes les origines autorisées');
        return {
            origin: "*",
            methods: ["GET", "POST"]
        };
    }
};

exports.init = (server) => {
    // En mode test, ne pas initialiser socket.io si le serveur n'écoute pas
    if (process.env.NODE_ENV === 'test' && (!server || !server.listening)) {
        // Retourner un mock io pour les tests
        io = {
            use: () => {},
            on: () => {},
            emit: () => {},
            to: () => ({ emit: () => {} }),
            close: (callback) => callback && callback()
        };
        return io;
    }
    
    io = socketIo(server, {
        cors: getCorsConfig()
    });

    // Middleware d'authentification Socket
    io.use((socket, next) => {
        if (socket.handshake.query && socket.handshake.query.token) {
            jwt.verify(socket.handshake.query.token, config.jwt.secret, (err, decoded) => {
                if (err) return next(new Error('Authentication error'));
                socket.user = decoded;
                next();
            });
        } else {
            next(new Error('Authentication error'));
        }
    });

    io.on('connection', (socket) => {
        // console.log(`User connected: ${socket.user.id}`);

        // Rejoindre une room personnelle pour les messages privés
        socket.join(`user_${socket.user.id}`);

        // Gestion connexion chat conversation
        socket.on('join_conversation', (conversationId) => {
            socket.join(`conversation_${conversationId}`);
            // console.log(`User ${socket.user.id} joined conversation ${conversationId}`);
        });

        socket.on('leave_conversation', (conversationId) => {
            socket.leave(`conversation_${conversationId}`);
        });

        // Typing indicators
        socket.on('typing', (data) => {
            socket.to(`conversation_${data.conversationId}`).emit('user_typing', {
                userId: socket.user.id,
                conversationId: data.conversationId
            });
        });

        socket.on('stop_typing', (data) => {
            socket.to(`conversation_${data.conversationId}`).emit('user_stop_typing', {
                userId: socket.user.id,
                conversationId: data.conversationId
            });
        });

        socket.on('disconnect', () => {
            // console.log('User disconnected');
        });
    });

    return io;
};

exports.getIo = () => {
    if (!io) {
        throw new Error("Socket.io not initialized!");
    }
    return io;
};

// Helper pour envoyer des messages depuis les controllers
exports.emitToUser = (userId, event, data) => {
    if (io) io.to(`user_${userId}`).emit(event, data);
};

exports.emitToConversation = (conversationId, event, data) => {
    if (io) io.to(`conversation_${conversationId}`).emit(event, data);
};
