//Title:      LWC - Community Self Registration Form
//Author:     Sarath Pullanikkatt
//Date:       12/04/2019

import { LightningElement, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import MAILING_COUNTRY_CODE_FIELD from '@salesforce/schema/Contact.MailingCountryCode';
import reCAPTCHA_RESOURCE from '@salesforce/resourceUrl/reCAPTCHA_v2';
import registerCommunityUser from '@salesforce/apex/CommunitySelfRegistrationFormController.registerCommunityUser';

export default class communitySelfRegistrationForm extends LightningElement {
    passwordPattern = '^(?=.{10,})(?=.*[a-z])(?=.*[A-Z])(?=.*[\\d])(?=.*[\\W]).*$';
    @track navigateTo = reCAPTCHA_RESOURCE;
    @track strEmail = '';
    @track strFirstName = '';
    @track strLastName = '';
    @track strTitle = '';
    @track strLocation = 'US';
    @track strPreferredLanguage = 'en_US';
    @track strPassword = '';
    @track strConfirmPassword = '';
    @track blnTandC = false;
    @track blnHuman = false;
    @track blnPwTyped = false;
    @track registrationSuccess;
    @track registrationError;
    @track blnFormSubmitted = false;

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$contactObjectInfo.data.defaultRecordTypeId', fieldApiName: MAILING_COUNTRY_CODE_FIELD})
    locations;

    get languages() {
        return [
            { label: 'Chinese', value: 'zh_CN' },
            { label: 'English', value: 'en_US' },
            { label: 'French', value: 'fr' },
            { label: 'German', value: 'de' },
            { label: 'Italian', value: 'it' },
            { label: 'Japanese', value: 'ja' },
            { label: 'Korean', value: 'ko' },
            { label: 'Portuguese', value: 'pt_BR' },
            { label: 'Spanish', value: 'es' },
        ];
    }

    handleChange(event) {
        if(event.target.name === 'email') {
            this.strEmail = event.target.value;
        }
        else if(event.target.name === 'first-name') {
            this.strFirstName = event.target.value;
        }
        else if(event.target.name === 'last-name') {
            this.strLastName = event.target.value;
        }
        else if(event.target.name === 'title') {
            this.strTitle = event.target.value;
        }
        else if(event.target.name === 'location') {
            this.strLocation = event.target.value;
        }
        else if(event.target.name === 'pref-lang') {
            this.strPreferredLanguage = event.target.value;
        }
        else if(event.target.name === 'pw') {
            this.strPassword = event.target.value;
        }
        else if(event.target.name === 'confirm-pw') {
            this.strConfirmPassword = event.target.value;
            this.blnPwTyped = true;
        }
        else if(event.target.name === 't-and-c') {
            this.blnTandC = event.target.checked;
        }
    }

    handlePw() {
        let pwFields = this.template.querySelectorAll('.pw-selector');

        if(this.strPassword !== this.strConfirmPassword && this.blnPwTyped) {
            pwFields.forEach(function(pw) {
                pw.setCustomValidity('Passwords do not match.');
                pw.reportValidity();
            });
        }
        else {
            pwFields.forEach(function(pw) {
                pw.setCustomValidity('');
                pw.reportValidity();
            });
        }
    }

    handleSubmit(event) {
        let reqFields = this.template.querySelectorAll('.req-field');
        let formValidated = true;
        
        reqFields.forEach(function(rf) {
            rf.reportValidity();
            if(!rf.checkValidity()) {
                formValidated = false;
            }
        });

        if(formValidated) {
            console.log('Human');
            this.blnFormSubmitted = true;
            registerCommunityUser({ strEmail: this.strEmail,
                                    strFirstName: this.strFirstName,
                                    strLastName: this.strLastName,
                                    strTitle: this.strTitle,
                                    strLocation: this.strLocation,
                                    strPreferredLanguage: this.strPreferredLanguage,
                                    strPassword: this.strPassword
                                })
                .then(result => {
                    this.registrationSuccess = result;
                    this.registrationError = undefined;
                    console.log(this.registrationSuccess);
                })
                .catch(error => {
                    this.registrationSuccess = undefined;
                    this.registrationError = error;
                    console.log(this.registrationError.body.message);
                });
        }
    }

    //Scripts below are for handling Google reCAPTCHA v2
    captchaLoaded(event){
        if(event.target.getAttribute('src') == reCAPTCHA_RESOURCE){
            //You know that reCAPTCHA is loaded
            console.log('reCAPTCHA Loaded');
        }
    }

    listenForMessage(event){
        let submitBtn = this.template.querySelector('.submit-selector');
        if(event.data === 'Unlock') {
            this.blnHuman = true;
            submitBtn.disabled = false;
            console.log('Unlock reCAPTCHA');
        }
        else if(event.data === 'Expired') {
            this.blnHuman = false;
            submitBtn.disabled = true;
            console.log('Lock reCAPTCHA');
        }
    }

    connectedCallback() {
        window.addEventListener("message", this.listenForMessage.bind(this));
    }
    
    disconnectedCallback() {
        window.removeEventListener("message", this.listenForMessage.bind(this));
    }
    //End of Google reCAPTCHA v2 scripts
}