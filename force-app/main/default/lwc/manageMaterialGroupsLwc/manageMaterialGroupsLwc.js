/**
*    @author        Tapas Chakraborty
*    @date          Sep-12-2020
*    @description   DCP-40571 add material groups to  Standing Quote Opportunities
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Tapas Chakraborty              17 Aug 2020         Initial Version: DCP-40571 add material groups to  Standing Quote Opportunities
*------------------------------------------------------------- ------------------------------------------------------------------------------------------------------
*/

import { LightningElement, api, track, wire } from 'lwc';
import getMaterialGroups from '@salesforce/apex/AddMaterialGroupController.getMaterialGroups';
import insertMaterialGroupsOnOpp from '@salesforce/apex/AddMaterialGroupController.insertMaterialGroupsOnOpp';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import materialGroupsUpdated from '@salesforce/label/c.UI_Msg_MaterialGroupsUpdateSuccess';
import noMaterialGroupsExist from '@salesforce/label/c.UI_Msg_NoMaterialGroupsExist';

export default class ManageMaterialGroupsLwc extends NavigationMixin(LightningElement) {
    label = {materialGroupsUpdated,noMaterialGroupsExist};

    error;
    showSpinner = true;
    sortCount = 0;
    dataAbsent = false;

    @track wrapperData = [];
    @track wiredResult;
    @track allChecked;

    @api agreementId;
    @api opportunityId;

    @wire(getMaterialGroups, { agreementId: '$agreementId', opportunityId: '$opportunityId' })
    getMaterialGroups(result) {
        this.wiredResult = result;
        let data = result.data;
        let error = result.error;
        if (data) {
            this.showSpinner = false;
            this.wrapperData = JSON.parse(data);
            this.dataAbsent = this.wrapperData.length > 0 ? false : true;
            this.error = undefined;
            this.checkIfAllRecordsSelected();
        }
        else if (error) {
            this.showSpinner = false;
            this.error = error;
            this.wrapperData = undefined;
            console.log(JSON.stringify(this.error));
        }
    }


    editRowAmount(event) {
        this.wrapperData[event.target.dataset.index].ForecastAmount = event.target.value;
    }

    selectRow(event) {
        this.wrapperData[event.target.dataset.index].isChecked = event.target.checked;
        this.checkIfAllRecordsSelected();        
    }

    selectAll(event) {
        this.allChecked = event.target.checked;
        for (let i = 0; i < this.wrapperData.length; i++) {
            this.wrapperData[i].isChecked = event.target.checked;
        }
    }

    Save(event) {
        const allValid = [...this.template.querySelectorAll('lightning-input[data-amount=required]')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if (!allValid)
            return;
        
        this.showSpinner = true;
        const selectedGroups = this.wrapperData.filter(element => element.isChecked);
        insertMaterialGroupsOnOpp({ selectedGroups: selectedGroups, opportunityId: this.opportunityId })
            .then(result => {
                this.showSpinner = false;
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordRelationshipPage',
                    attributes: {
                        recordId: this.opportunityId,
                        objectApiName: 'Opportunity',
                        relationshipApiName: 'Standing_Quote_Opportunity_Products__r',
                        actionName: 'view'
                    }
                });
                this.showToastMessage('Success',this.label.materialGroupsUpdated, 'success', 'dismissable');             
                refreshApex(this.wiredResult);
            })
            .catch(error => {
                let errorContent = JSON.stringify(error);
                console.log('error ' + JSON.stringify(error));
                this.showSpinner = false;
                let message;
                if(errorContent === '{}')
                    message =  'Error is ' + error.name + error.message + error.stack ;
                else{
                    message = error.body.message;
                }
                this.showToastMessage('Error', message, 'error', 'sticky');
            });

    }
    closeModal(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.opportunityId,
                objectApiName: 'Opportunity',
                relationshipApiName: 'Standing_Quote_Opportunity_Products__r',
                actionName: 'view'
            }
        });
    }

    checkIfAllRecordsSelected() {
        let row;
        for(row of this.wrapperData){
            if(!row.isChecked){
                this.allChecked = false;
                return;
            }
        } 
        this.allChecked = true;
    }


    sortByMaterialGroup(){
        this.sortCount += 1;
        let wrapperCopy = [...this.wrapperData];
        wrapperCopy.sort(function(x, y) {
            if (x.MaterialGroup < y.MaterialGroup) {
                return -1;
            }
            if (x.MaterialGroup > y.MaterialGroup) {
                return 1;
            }
            return 0;
        });
        if(this.sortCount % 2 === 1)
            this.wrapperData = wrapperCopy;
        else{
            this.wrapperData = wrapperCopy.reverse();
        }        
    }

    //to show toast message to user
    showToastMessage(title,message, variant, mode){
        const evt = new ShowToastEvent({title, message, variant, mode});
        this.dispatchEvent(evt);
    }
}