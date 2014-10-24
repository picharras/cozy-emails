{a, h4,  pre, div, button, span, strong, i} = React.DOM
SocketUtils = require '../utils/socketio_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes, NotifyType} = require '../constants/app_constants'

classer = React.addons.classSet

module.exports = Toast = React.createClass
    displayName: 'Toast'

    getInitialState: ->
        return modalErrors: false

    closeModal: ->
        @setState modalErrors: false

    showModal: (errors) ->
        @setState modalErrors: errors

    acknowledge: ->
        if @props.toast.type is NotifyType.SERVER
            SocketUtils.acknowledgeTask @props.toast.id
        else
            AppDispatcher.handleViewAction
                type: ActionTypes.RECEIVE_TASK_DELETE
                value: @props.toast.id

    renderErrorModal: ->
        div className: "modal fade in", role: "dialog", style: display: 'block',
            div className: "modal-dialog",
                div className: "modal-content",
                    div className: "modal-header",
                        h4 className: "modal-title", t 'modal please contribute'
                    div className: "modal-body",
                        span null, t 'modal please report'
                        pre style: "max-height": "300px", "word-wrap": "normal",
                            @state.modalErrors.join "\n\n"
                    div className: "modal-footer",
                        button
                            type: 'button',
                            className: 'btn',
                            onClick: @closeModal,
                            t 'app alert close'

    render: ->
        toast = @props.toast
        hasErrors = toast.errors? and toast.errors.length
        classes = classer
            alert: true
            toast: true
            'alert-dismissible': toast.finished
            'alert-info': not hasErrors
            'alert-warning': hasErrors
        if toast.done? and toast.total?
            percent = parseInt(100 * toast.done / toast.total) + '%'
        if hasErrors
            showModal = @showModal.bind(this, toast.errors)

        div className: classes, role: "alert",
            if @state.modalErrors
                @renderErrorModal()

            if percent?
                div className: "progress",
                    div
                        className: 'progress-bar',
                        style: width: percent
                    div
                        className: 'progress-bar-label start',
                        style: width: percent,
                        "#{t "task " + toast.code, toast} : #{percent}"
                    div
                        className: 'progress-bar-label end',
                        "#{t "task " + toast.code, toast} : #{percent}"

            if toast.message
                div className: "message", toast.message

            if toast.finished
                button
                    type: "button",
                    className: "close",
                    onClick: @acknowledge,
                        span 'aria-hidden': "true", "×"
                        span className: "sr-only", t "app alert close"

            if hasErrors
                a onClick: showModal,
                    t 'there were errors', smart_count: toast.errors.length

    componentDidMount: ->
        if @props.toast.autoclose
            setTimeout =>
                @getDOMNode().classList.add 'autoclose'
            , 1000
            setTimeout =>
                @acknowledge()
            , 10000

module.exports.Container = ToastContainer =  React.createClass
    displayName: 'ToastContainer'

    getInitialState: ->
        return hidden: false

    render: ->
        toasts = @props.toasts.toJS?() or @props.toasts

        classes = classer
            'toasts-container': true
            'action-hidden': @state.hidden
            'has-toasts': Object.keys(toasts).length isnt 0

        div className: classes,
            Toast {toast, key: id} for id, toast of toasts
            div className: 'alert alert-success toast toast-actions',
                span
                    className: "toast-action hide-action",
                    title: t 'toast hide'
                    onClick: @toggleHidden,
                        i className: 'fa fa-eye-slash'
                span
                    className: "toast-action show-action",
                    title: t 'toast show'
                    onClick: @toggleHidden,
                        i className: 'fa fa-eye'
                span
                    className: "toast-action close-action",
                    title: t 'toast close all'
                    onClick: @closeAll,
                        i className: 'fa fa-times'

    toggleHidden: ->
        @setState hidden: not @state.hidden

    closeAll: ->
        toasts = @props.toasts.toJS?() or @props.toasts
        close = (toast) ->
            if toast.type is NotifyType.SERVER
                SocketUtils.acknowledgeTask toast.id
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_TASK_DELETE
                    value: toast.id
        close toast for id, toast of toasts
        @props.toasts.clear()