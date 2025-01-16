import { LightningElement,wire,track,api  } from 'lwc';
import updateRelatedWO from '@salesforce/apex/WorkOrderBulkUpdateController.updateRelatedWO';
import {refreshApex} from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
export default class workOrderBulkUpdateLookupRecords extends LightningElement {

    @api selectedrecordIds;
    @api selectedRecords = new Object();
    @api record;
    @track loadingupdate= true;
    //Submit field support value
    submitDetails(event) {
        this.loadingupdate=false;
        console.log('eventdetails:'+event.detail.fields['SVMXC__Group_Member__c']);
        this.record = event.detail;
        console.log('eventdetails:'+this.record);
        console.log('selectedRecords:'+this.selectedRecords);
        let selectedRec = JSON.parse(JSON.stringify(this.selectedRecords));
        selectedRec.forEach(function(record){
            delete record.ownerName;
            delete record.fieldSupportName;
            delete record.woUrl;
            record['Id']=record['woId'];
            record['Name']=record['woName'];
            delete record.orderType;
            delete record.orderStatus;
            record.SVMXC__Group_Member__c = event.detail.fields['SVMXC__Group_Member__c'];
        });
        // update operation through apex controller
        console.log('selectedRec==>'+selectedRec);  
        updateRelatedWO({workOrderRecs:selectedRec})
        .then(result=>{
            this.loadingupdate=true;
            if(result === null){
            console.log('result::'+result);           
            this.dispatchEvent(new CustomEvent('closemodal'));          
            this.dispatchEvent(
                new ShowToastEvent({
                    //title: 'Success!!',
                    message: 'The record has been updated successfully',
                    variant: 'success',
                
                }),
            );           
            }
           else if(result !== null){
                console.log('error::'+result);
                this.dispatchEvent(new CustomEvent('closemodal'));
                this.dispatchEvent(
                    new ShowToastEvent({
                        //title: 'Error!!',
                        message: result,
                        variant: 'error',
                    }),
                );
            }
                return refreshApex(result);
          })

        .catch(error=>{
            });
    }
}