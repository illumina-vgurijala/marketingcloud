import React from 'react'
import Svg from './svg.jsx'

let _id = 0

export default class Modal extends React.Component {
    constructor(props) {
        super(props)
        this.state = {
            id: `modal${_id++}`
        }
    }

    componentDidMount() {
        this.refs.confirmButton.focus()
    }

    render() {
        let ariaLabeledBy = this.hasHeader() ? { 'aria-labelledby': `modal_header_${this.state.id}` } : {}
        let extraClassName = this.props.large ? 'slds-modal--large' : ''

        return (
            <div>
                <div role='dialog' tabIndex='-1' className={`slds-modal slds-fade-in-open ${extraClassName}`} {...ariaLabeledBy}>
                  <div className='slds-modal__container'>
                    {this.renderHeader()}
                    <div className='slds-modal__content slds-p-around--medium'>
                        {this.props.children}
                    </div>
                    {this.renderFooter()}
                  </div>
                </div>
                <div className='slds-backdrop slds-backdrop--open'></div>
            </div>
        )
    }

    renderHeader() {
        if (!this.hasHeader()) {
            return <div></div>
        }

        let extraHeaderClasses = this.props.isError ? 'slds-theme--error slds-theme--alert-texture' : '';

        return (
            <div className={`slds-modal__header ${extraHeaderClasses}`}>
              {(() => {
                  // don't render close button if explicitly set to false
                  if (this.props.showHeaderCloseButton === false) {
                      return
                  }

                  let { cancelButton } = this.props
                  let closeDisabled = cancelButton && cancelButton.disabled
                  let onCloseClick = this.getCloseOnClickProp()

                  return (
                      <button disabled={closeDisabled} className='slds-button slds-button--icon-inverse slds-modal__close' {...onCloseClick}>
                          <Svg className='slds-button__icon slds-button__icon--large' props={{'aria-hidden': true}} type={Svg.Types.Action} symbol='close' />
                          <span className='slds-assistive-text'>Close</span>
                      </button>
                  )
              })()}
              <h2 id={`modal_header_${this.state.id}`} className='slds-text-heading--medium'>{this.props.title}</h2>
             {this.renderTagline()}
            </div>
        )
    }

    getCloseOnClickProp() {
        let {
            confirmButton,
            cancelButton,
            onCloseClick
        } = this.props
        let closeClick = {}

        if (cancelButton && cancelButton.callback) {
            closeClick.onClick = cancelButton.callback
        } else if (confirmButton && confirmButton.callback) {
            closeClick.onClick = confirmButton.callback
        } else if (onCloseClick) {
            closeClick.onClick = onCloseClick
        }

        return closeClick
    }

    renderTagline() {
        if (!this.props.tagline) {
            return <div></div>
        }

        return (
             <div className='slds-m-top--x-small'>{this.props.tagline}</div>
        )
    }

    renderFooter() {
        if (!this.hasFooter()) {
            return <div></div>
        }

        let extraClassName = this.props.directional ? 'slds-modal__footer--directional' : ''

        return (
            <div className={`slds-modal__footer ${extraClassName}`}>
                {this.getButtonMarkup(this.props.cancelButton)}
                {this.getButtonMarkup(this.props.confirmButton, 'slds-button--brand', { ref: 'confirmButton' })}
            </div>
        )
    }

    getButtonMarkup(buttonConfig, extraClassName = '', extraProps = {}) {
        if (!buttonConfig) {
            return <div></div>
        }

        let click = buttonConfig.callback ? { onClick: buttonConfig.callback } : {}

        return (
            <button disabled={buttonConfig.disabled} className={`slds-button slds-button--neutral ${extraClassName}`} {...click} {...extraProps}>
                {buttonConfig.text}
            </button>
        )
    }

    hasHeader() {
        return this.props.title || this.props.tagline
    }

    hasFooter() {
        return this.props.confirmButton || this.props.cancelButton
    }
}

Modal.propTypes = {
    title: React.PropTypes.string,
    tagline: React.PropTypes.node,
    large: React.PropTypes.bool,
    directional: React.PropTypes.bool,
    confirmButton: React.PropTypes.shape({
        text: React.PropTypes.string.isRequired,
        disabled: React.PropTypes.bool,
        callback: React.PropTypes.func
    }),
    cancelButton: React.PropTypes.shape({
        text: React.PropTypes.string.isRequired,
        callback: React.PropTypes.func
    }),
    showHeaderCloseButton: React.PropTypes.bool,
    onCloseClick: React.PropTypes.func
}
