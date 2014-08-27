Store = require '../libs/flux/store/Store'
AppDispatcher = require '../AppDispatcher'

AccountStore = require './AccountStore'

{ActionTypes} = require '../constants/AppConstants'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Creates an OrderedMap of messages
    _message = Immutable.Sequence()

        # sets message ID as index
        .mapKeys (_, message) -> message.id

        # makes message object an immutable Map
        .map (message) -> Immutable.Map message
        .toOrderedMap()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MESSAGE, onReceiveRawMessage = (message, silent = false) ->
            # create or update
            message = Immutable.Map message
            _message = _message.set message.get('id'), message

            @emit 'change' unless silent

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->
            onReceiveRawMessage message, true for message in messages
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            messages = @getMessagesByAccount accountID
            _message = _message.withMutations (map) ->
                messages.forEach (message) -> map.remove message.get 'id'

            @emit 'change'


    ###
        Public API
    ###
    getAll: -> return _message

    getByID: (messageID) -> _message.get(messageID) or null

    getMessagesByAccount: (accountID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _message.filter (message) -> message.get('mailbox') is accountID
        .toOrderedMap()

    getMessagesByMailbox: (mailboxID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _message.filter (message) -> message.get('imapFolder') is mailboxID
        .toOrderedMap()

    getMessagesByConversation: (messageID) ->
        idsToLook = [messageID]
        conversation = []
        while idToLook = idsToLook.pop()
            conversation.push @getByID idToLook
            temp = _message.filter (message) -> message.get('inReplyTo') is idToLook
            idsToLook = idsToLook.concat temp.map((item) -> item.get('id')).toArray()

        return conversation

module.exports = new MessageStore()