import { LightningElement, wire, track, api } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import ELEVATIONS_OBJECT from '@salesforce/schema/Elevations__c'; 
import ADDITIONAL_SUPPORT_FIELD from '@salesforce/schema/Elevations__c.If_Needed_Additional_Support__c';

export default class MultiSelectPicklist extends LightningElement {    
    @api selectedRecordId ;    
    @api label;
    @track lstSelected = [];
    @track lstOptions = [];
    values = [];    
    // Get Object Info.
    @wire (getObjectInfo, {objectApiName: ELEVATIONS_OBJECT})
    elevationsObjectInfo;

    // Get Picklist values.
    @wire(getPicklistValues, {recordTypeId: '$elevationsObjectInfo.data.defaultRecordTypeId', fieldApiName: ADDITIONAL_SUPPORT_FIELD })
    additionalSupport(data, error){  
        if(this.selectedRecordId !== undefined) {            
            //main logic 
            let selectedSupportReq = this.selectedRecordId.split(';');            
            this.values.push(...selectedSupportReq);                                   
        }                    
        if(data && data.data && data.data.values){
            data.data.values.forEach( objPicklist => {     
                this.lstOptions.push({
                    label: objPicklist.label,
                    value: objPicklist.value                    
                });                            
            });
        } else if(error){
            console.log(error);
        }
    };

    handleChange(event) {
        this.lstSelected = event.detail.value;   
        this.selectedRecordId ='';        
        for (const obj in this.lstSelected) {    
            this.selectedRecordId +=this.lstSelected[obj]+';' ;        
        }   
        this.selectedRecordId= this.selectedRecordId.trim();
        this.selectedRecordId=this.selectedRecordId.slice(0, -1);         
    }
}