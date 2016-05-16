React = require 'react'

{span} = React.DOM

MessageGetter = require '../getters/message'
SearchGetter = require '../getters/search'

ContactActionCreator = require '../actions/contact_action_creator'

module.exports = React.createClass
    displayName: 'Participant'

    render: ->
        if not @props.address?
            span null
        else
            span
                className: 'address-item'
                'data-toggle': "tooltip"
                ref: 'participant'
                title: @props.address.address
                key: @props.key

                SearchGetter.highlightSearch(@props.name)...


    addAddress: (address) ->
        ContactActionCreator.createContact address

    _initTooltip: ->
        if @props.tooltip and @refs.participant?
            MessageGetter.tooltip @refs.participant, @props.address, @addAddress

    componentDidMount: ->
        @_initTooltip()

    componentDidUpdate: ->
        @_initTooltip()
