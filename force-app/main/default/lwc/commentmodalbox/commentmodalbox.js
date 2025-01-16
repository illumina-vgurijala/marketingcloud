import { LightningElement,track,api } from 'lwc';

import addapproverejectcomments from '@salesforce/label/c.UI_Add_Approve_Reject_Comments';
import addcommentshere from '@salesforce/label/c.UI_Add_Comments_Here';
import buttonok from '@salesforce/label/c.UI_Button_Ok';
import buttoncancel from '@salesforce/label/c.UI_Button_Cancel';
import buttonclose from '@salesforce/label/c.UI_Button_Close';

export default class Commentmodalbox extends LightningElement {

    @track isModalOpen = false;
    @api oldValue;
    @api appreqid;
    @track newValue;

    label = {
        addapproverejectcomments,
        addcommentshere,
        buttonok,
        buttoncancel,
        buttonclose
    }

    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    submitDetails() {
        let returnString = {
            "index":this.appreqid,
            "selectedValue":this.newValue
         };
        const sendData = new CustomEvent('sendcomment',{ detail : returnString});
        this.dispatchEvent(sendData);
        this.isModalOpen = false;
    }
    handleChange(event)
    {
        let newVal = event.target.value;
        this.newValue = newVal;
    }
    
}