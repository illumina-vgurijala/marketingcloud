import { LightningElement, api } from 'lwc';

export default class CustomPath extends LightningElement {
    @api allStages;
    @api lastCompletedStage;

    renderedCallback(){
        this.updateCurrentStage(this.lastCompletedStage);
    }

    updateCurrentStage(stageName) {
        let lstLiElements = this.template.querySelectorAll('li');
        let activeIndex = 0;
        for (let i = 0; i < lstLiElements.length; i++) {
            console.log('li element-->'+JSON.stringify(lstLiElements[i]));
            if (lstLiElements[i].dataset.identifier === 'pathstage') {
                if (lstLiElements[i].dataset.key === stageName) {
                    activeIndex = i + 1;
                    break;
                }
            }
        }
        for (let i = 0; i < activeIndex; i++) {
            if (lstLiElements[i].dataset.identifier === 'pathstage') {
                lstLiElements[i].className = 'slds-path__item slds-is-complete';
            }   
        }
        if (activeIndex < lstLiElements.length) {
            lstLiElements[activeIndex].className = 'slds-path__item slds-is-current slds-is-active';
        }
    }
}