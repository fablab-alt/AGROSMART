'use client'

import { useEffect, useState, useCallback, useRef } from 'react'
import {
  MessageSquare,
  Send,
  Search,
  Check,
  CheckCheck,
  Paperclip,
  Smile,
  MoreVertical,
  Phone,
  Video,
  ArrowLeft,
  Plus,
  UserPlus,
  X,
} from 'lucide-react'
import { 
  Card, 
  CardContent, 
  Button, 
  Input, 
  Badge, 
  Skeleton,
  Avatar,
  AvatarImage,
  AvatarFallback,
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui'
import { cn, safeDate } from '@/lib/utils'
import { useAuthStore } from '@/lib/store'
import api from '@/lib/api'
import { format, isToday, isYesterday } from 'date-fns'
import { fr } from 'date-fns/locale'

interface Conversation {
  id: string
  participant_id: string
  participant_nom: string
  participant_avatar?: string
  dernier_message?: string
  dernier_message_at?: string
  non_lus: number
  is_online?: boolean
}

interface Message {
  id: string
  conversation_id: string
  expediteur_id: string
  contenu: string
  type: 'texte' | 'image' | 'fichier'
  lu: boolean
  created_at: string
}

export default function MessagesPage() {
  const { user } = useAuthStore()
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [messages, setMessages] = useState<Message[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingMessages, setLoadingMessages] = useState(false)
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null)
  const [newMessage, setNewMessage] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [showMobileChat, setShowMobileChat] = useState(false)
  const [showNewConversation, setShowNewConversation] = useState(false)
  const [contacts, setContacts] = useState<Array<{ id: string; nom: string; prenoms: string; telephone: string; avatar?: string }>>([])
  const [contactSearch, setContactSearch] = useState('')
  const [loadingContacts, setLoadingContacts] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const fetchConversations = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get('/messages/conversations')
      if (response.data.success) {
        setConversations(response.data.data)
      }
    } catch (error) {
      console.error('Error fetching conversations:', error)
      // Pas de données mockées - afficher liste vide
      setConversations([])
    } finally {
      setLoading(false)
    }
  }, [])

  const fetchMessages = useCallback(async (conversationId: string) => {
    setLoadingMessages(true)
    try {
      const response = await api.get(`/messages/conversations/${conversationId}`)
      if (response.data.success) {
        setMessages(response.data.data)
      }
    } catch (error) {
      console.error('Error fetching messages:', error)
      // Pas de données mockées - afficher liste vide
      setMessages([])
    } finally {
      setLoadingMessages(false)
    }
  }, [])

  useEffect(() => {
    fetchConversations()
  }, [fetchConversations])

  const fetchContacts = useCallback(async (query: string) => {
    if (!query.trim()) {
      setContacts([])
      return
    }
    setLoadingContacts(true)
    try {
      const response = await api.get(`/messages/contacts/search?q=${encodeURIComponent(query)}`)
      if (response.data.success) {
        setContacts(response.data.data || [])
      }
    } catch (error) {
      console.error('Error searching contacts:', error)
      // Fallback: try users endpoint
      try {
        const response = await api.get(`/users?search=${encodeURIComponent(query)}&limit=10`)
        if (response.data.success) {
          setContacts(response.data.data || [])
        }
      } catch {
        setContacts([])
      }
    } finally {
      setLoadingContacts(false)
    }
  }, [])

  useEffect(() => {
    const timer = setTimeout(() => {
      if (contactSearch.trim()) {
        fetchContacts(contactSearch)
      }
    }, 300)
    return () => clearTimeout(timer)
  }, [contactSearch, fetchContacts])

  const handleStartConversation = async (contact: { id: string; nom: string; prenoms?: string }) => {
    // Check if conversation already exists
    const existing = conversations.find(c => c.participant_id === contact.id)
    if (existing) {
      handleSelectConversation(existing)
      setShowNewConversation(false)
      return
    }

    // Create a new conversation placeholder
    const newConv: Conversation = {
      id: contact.id,
      participant_id: contact.id,
      participant_nom: `${contact.prenoms || ''} ${contact.nom}`.trim(),
      non_lus: 0,
    }
    setSelectedConversation(newConv)
    setMessages([])
    setShowNewConversation(false)
    setShowMobileChat(true)
  }

  useEffect(() => {
    if (selectedConversation) {
      fetchMessages(selectedConversation.id)
    }
  }, [selectedConversation, fetchMessages])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSelectConversation = (conversation: Conversation) => {
    setSelectedConversation(conversation)
    setShowMobileChat(true)
  }

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newMessage.trim() || !selectedConversation) return

    const tempMessage: Message = {
      id: Date.now().toString(),
      conversation_id: selectedConversation.id,
      expediteur_id: user?.id || 'me',
      contenu: newMessage,
      type: 'texte',
      lu: false,
      created_at: new Date().toISOString(),
    }

    setMessages(prev => [...prev, tempMessage])
    setNewMessage('')

    try {
      await api.post(`/messages`, {
        destinataire_id: selectedConversation.participant_id || selectedConversation.id,
        contenu: newMessage,
        type: 'texte',
      })
      // Refresh conversations to get the new one
      fetchConversations()
    } catch (error) {
      console.error('Error sending message:', error)
      // Keep the message in UI even if API fails
    }
  }

  const formatMessageDate = (dateString: string) => {
    const date = safeDate(dateString)
    if (!date) return 'N/A'
    
    try {
      if (isToday(date)) {
        return format(date, 'HH:mm', { locale: fr })
      } else if (isYesterday(date)) {
        return 'Hier ' + format(date, 'HH:mm', { locale: fr })
      }
      return format(date, 'dd/MM HH:mm', { locale: fr })
    } catch {
      return 'N/A'
    }
  }

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
  }

  const filteredConversations = conversations.filter(c =>
    c.participant_nom.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const totalUnread = conversations.reduce((acc, c) => acc + c.non_lus, 0)

  return (
    <div className="h-[calc(100vh-8rem)] flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <MessageSquare className="h-6 w-6 text-green-600" />
            Messages
            {totalUnread > 0 && (
              <Badge variant="danger">{totalUnread}</Badge>
            )}
          </h1>
          <p className="text-gray-500">
            Communiquez avec d&apos;autres agriculteurs
          </p>
        </div>
        <Button onClick={() => setShowNewConversation(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Nouveau message
        </Button>
      </div>

      {/* New Conversation Modal */}
      {showNewConversation && (
        <Card className="mb-4 border-green-200">
          <CardContent className="p-4">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-medium text-gray-900 flex items-center gap-2">
                <UserPlus className="h-4 w-4 text-green-600" />
                Nouvelle conversation
              </h3>
              <button onClick={() => setShowNewConversation(false)} className="p-1 hover:bg-gray-100 rounded" aria-label="Fermer">
                <X className="h-4 w-4" />
              </button>
            </div>
            <div className="relative mb-3">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <Input
                placeholder="Rechercher un utilisateur par nom ou téléphone..."
                value={contactSearch}
                onChange={(e) => setContactSearch(e.target.value)}
                className="pl-10"
                autoFocus
              />
            </div>
            {loadingContacts ? (
              <div className="py-4 text-center text-gray-500">Recherche...</div>
            ) : contacts.length > 0 ? (
              <div className="max-h-48 overflow-y-auto space-y-1">
                {contacts.map((contact) => (
                  <button
                    key={contact.id}
                    onClick={() => handleStartConversation(contact)}
                    className="w-full flex items-center gap-3 p-2 hover:bg-gray-50 rounded-lg text-left transition-colors"
                  >
                    <div className="h-8 w-8 rounded-full bg-green-100 flex items-center justify-center text-green-700 font-medium text-sm">
                      {contact.nom?.charAt(0) || '?'}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {contact.prenoms} {contact.nom}
                      </p>
                      <p className="text-xs text-gray-500">{contact.telephone}</p>
                    </div>
                  </button>
                ))}
              </div>
            ) : contactSearch.trim() ? (
              <div className="py-4 text-center text-gray-500 text-sm">
                Aucun utilisateur trouvé
              </div>
            ) : (
              <div className="py-4 text-center text-gray-500 text-sm">
                Tapez un nom ou un numéro pour rechercher
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Main content */}
      <div className="flex-1 flex gap-4 overflow-hidden">
        {/* Conversations list */}
        <Card className={cn(
          "w-full md:w-80 shrink-0 flex flex-col",
          showMobileChat && "hidden md:flex"
        )}>
          <div className="p-4 border-b">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <Input
                placeholder="Rechercher..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>
          <div className="flex-1 overflow-y-auto">
            {loading ? (
              <div className="p-4 space-y-3">
                <Skeleton className="h-16 w-full" />
                <Skeleton className="h-16 w-full" />
                <Skeleton className="h-16 w-full" />
              </div>
            ) : filteredConversations.length === 0 ? (
              <div className="p-8 text-center text-gray-500">
                <MessageSquare className="h-10 w-10 mx-auto mb-2 opacity-50" />
                <p>Aucune conversation</p>
              </div>
            ) : (
              filteredConversations.map((conv) => (
                <button
                  key={conv.id}
                  onClick={() => handleSelectConversation(conv)}
                  className={cn(
                    "w-full p-4 flex items-start gap-3 hover:bg-gray-50 transition-colors text-left border-b",
                    selectedConversation?.id === conv.id && "bg-green-50"
                  )}
                >
                  <div className="relative">
                    <Avatar>
                      <AvatarImage src={conv.participant_avatar} />
                      <AvatarFallback>{getInitials(conv.participant_nom)}</AvatarFallback>
                    </Avatar>
                    {conv.is_online && (
                      <span className="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-green-500 border-2 border-white" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <p className="font-medium text-gray-900 truncate">
                        {conv.participant_nom}
                      </p>
                      <span className="text-xs text-gray-500">
                        {conv.dernier_message_at && formatMessageDate(conv.dernier_message_at)}
                      </span>
                    </div>
                    <div className="flex items-center justify-between mt-0.5">
                      <p className="text-sm text-gray-500 truncate">
                        {conv.dernier_message}
                      </p>
                      {conv.non_lus > 0 && (
                        <Badge variant="success" className="ml-2 h-5 w-5 p-0 flex items-center justify-center text-xs">
                          {conv.non_lus}
                        </Badge>
                      )}
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </Card>

        {/* Chat area */}
        <Card className={cn(
          "flex-1 flex flex-col",
          !showMobileChat && !selectedConversation && "hidden md:flex"
        )}>
          {selectedConversation ? (
            <>
              {/* Chat header */}
              <div className="p-4 border-b flex items-center gap-3">
                <button
                  onClick={() => setShowMobileChat(false)}
                  className="md:hidden p-2 -ml-2 hover:bg-gray-100 rounded-lg"
                  aria-label="Retour"
                >
                  <ArrowLeft className="h-5 w-5" />
                </button>
                <Avatar>
                  <AvatarImage src={selectedConversation.participant_avatar} />
                  <AvatarFallback>
                    {getInitials(selectedConversation.participant_nom)}
                  </AvatarFallback>
                </Avatar>
                <div className="flex-1">
                  <p className="font-medium text-gray-900">
                    {selectedConversation.participant_nom}
                  </p>
                  <p className="text-xs text-gray-500">
                    {selectedConversation.is_online ? 'En ligne' : 'Hors ligne'}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <Button variant="ghost" size="sm">
                    <Phone className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="sm">
                    <Video className="h-4 w-4" />
                  </Button>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="sm">
                        <MoreVertical className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem>Voir le profil</DropdownMenuItem>
                      <DropdownMenuItem>Bloquer</DropdownMenuItem>
                      <DropdownMenuItem className="text-red-600">Supprimer</DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {loadingMessages ? (
                  <div className="space-y-3">
                    <Skeleton className="h-12 w-2/3" />
                    <Skeleton className="h-12 w-1/2 ml-auto" />
                    <Skeleton className="h-12 w-2/3" />
                  </div>
                ) : (
                  messages.map((message) => {
                    const isMe = message.expediteur_id === user?.id || message.expediteur_id === 'me'
                    return (
                      <div
                        key={message.id}
                        className={cn(
                          "flex",
                          isMe ? "justify-end" : "justify-start"
                        )}
                      >
                        <div
                          className={cn(
                            "max-w-[70%] rounded-2xl px-4 py-2",
                            isMe
                              ? "bg-green-500 text-white rounded-br-md"
                              : "bg-gray-100 text-gray-900 rounded-bl-md"
                          )}
                        >
                          <p className="text-sm">{message.contenu}</p>
                          <div className={cn(
                            "flex items-center justify-end gap-1 mt-1",
                            isMe ? "text-green-100" : "text-gray-400"
                          )}>
                            <span className="text-xs">
                              {(() => {
                                const date = safeDate(message.created_at);
                                return date ? format(date, 'HH:mm') : 'N/A';
                              })()}
                            </span>
                            {isMe && (
                              message.lu 
                                ? <CheckCheck className="h-3 w-3" />
                                : <Check className="h-3 w-3" />
                            )}
                          </div>
                        </div>
                      </div>
                    )
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Message input */}
              <form onSubmit={handleSendMessage} className="p-4 border-t flex items-center gap-2">
                <Button type="button" variant="ghost" size="sm">
                  <Paperclip className="h-5 w-5 text-gray-500" />
                </Button>
                <Input
                  ref={inputRef}
                  placeholder="Écrivez un message..."
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  className="flex-1"
                />
                <Button type="button" variant="ghost" size="sm">
                  <Smile className="h-5 w-5 text-gray-500" />
                </Button>
                <Button type="submit" disabled={!newMessage.trim()}>
                  <Send className="h-4 w-4" />
                </Button>
              </form>
            </>
          ) : (
            <CardContent className="flex-1 flex items-center justify-center">
              <div className="text-center text-gray-500">
                <MessageSquare className="h-16 w-16 mx-auto mb-4 opacity-30" />
                <p className="text-lg font-medium">Sélectionnez une conversation</p>
                <p className="text-sm">Choisissez une conversation pour commencer à discuter</p>
              </div>
            </CardContent>
          )}
        </Card>
      </div>
    </div>
  )
}
