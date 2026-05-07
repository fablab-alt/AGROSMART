const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

router.get('/conversations', chatController.getConversations);
router.get('/conversations/:id/messages', chatController.getMessages);
router.post('/conversations/:id/messages', chatController.sendMessage);
router.post('/conversations', chatController.createConversation);

module.exports = router;
