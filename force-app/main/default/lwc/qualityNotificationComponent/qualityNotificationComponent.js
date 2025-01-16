import { LightningElement, track, api, wire } from 'lwc';
import {showErrorToast} from 'c/utils';
import getPartsOrderWithQN from '@salesforce/apex/QualityNotificationController.getPartsOrderWithQN';
import getCurrentApp from '@salesforce/apex/QualityNotificationController.getCurrentApp';
import { NavigationMixin } from "lightning/navigation";
import QualityNotificationURLLabel from '@salesforce/label/c.QualityNotificationURL';
import QualityNotificationNoData from '@salesforce/label/c.QualityNotificationNoData';


export default class QualityNotificationComponent extends NavigationMixin(LightningElement) {

    @api recordId;
    @track showtable;
    @track treeItems;
    @track booLoading = true;
    label = QualityNotificationNoData;

    @track columnsProductComponents = [
        {
            type: 'text',
            fieldName: 'label',
            label: 'Parts Order and Parts Order Line with RMA'
        },
        {
            type: 'button',
            label: 'Link',
            typeAttributes: {
                label: 'View',
                name :'name',
                variant:'base',
                value: 'view',
                class: 'buttonStyle',
            },
        }
   ];
   @track isLoaded = false;
   renderedCallback(){
    if(this.showtable){
        if(this.isLoaded){
            return
        } 
            const style = document.createElement('style')
            style.innerText = `c-quality-notification-component lightning-tree-grid .buttonStyle .slds-button{
                color: var(--lwc-brandTextLink,rgb(1, 118, 211));
            } `
            this.template.querySelector('lightning-tree-grid').appendChild(style)
            this.isLoaded = true
        }
    }
    @wire(getPartsOrderWithQN,{
        recordId: '$recordId'
    })
    QNTreeData({ error, data }) {
        this.booLoading = true;
        if (error) {
            this.error = error;
            this.treeItems = null;
        }
        else if (data) {
            if(data.length===0){
                this.showtable = false;
            }else{
                this.showtable = true;  
            }
            let tempjson = JSON.parse(JSON.stringify(data).split('items').join('_children'));
            this.treeItems = tempjson;
    }
     this.booLoading = false;
}
    handleOnselect(event) {
        const row = event.detail.row;
        if(row.name.length === 15 || row.name.length === 18){
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'SVMXC__RMA_Shipment_Order__c',
                    recordId: row.name,
                    actionName: 'view',
                },
            }).then(url => {
                getCurrentApp().then(result=>{
                    let appName = result.toUpperCase();
                    if(appName.includes('CONSOLE')){
                        // View a custom object record.
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                objectApiName: 'SVMXC__RMA_Shipment_Order__c',
                                recordId: row.name,
                                actionName: 'view'
                            }
                        });
                    }else{
                        window.open(url);
                    }
                }).catch(error=>{
                    showErrorToast('Error Message'+error.body.message);
                });
            });
        }
        else{
            window.open(QualityNotificationURLLabel + row.name);
        }
    }
}