import { LightningElement, api } from 'lwc';
import {genericEvent} from 'c/utils';

export default class ModalPopup extends LightningElement {
    @api title;
    @api body;
    @api button1Title;
    @api button2Title;
    @api showModal;

    @api
    closeModal() {
        this.showModal = false;
    }

    @api
    openModal() {
        this.showModal = true;
    }
    
    button1Action(event) {
        const objDetails = Object.create({});
        genericEvent('button1action', objDetails, this);
    }

    button2Action(event) {
        const objDetails = Object.create({});
        genericEvent('button2action', objDetails, this);
    }
}