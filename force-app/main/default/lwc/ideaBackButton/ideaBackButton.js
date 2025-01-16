import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class MyCustomElement extends NavigationMixin(
    LightningElement
){

    goToPrev(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/s/innovation-idea/innohub__Innovation_Idea__c/Default'
            }
        }).then(generatedUrl => {
            window.open(generatedUrl,'_parent');
        });
           
    }
    
}