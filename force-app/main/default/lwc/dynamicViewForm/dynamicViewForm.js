import { LightningElement,api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DynamicEditFormMobile extends LightningElement {
    @api recordId;
    @api strObjectAPIName;
    @api strFieldAPINames;
    @api strFormHeader;
    @api booReadOnly;
    @api strRequiredFields;
    @api strReadOnlyFields;
    @track booShowForm=false;
    @api lstInfomatRecds=[];
    @track lstfields =[];
    @track lstRequiredFields=[];
    @track lstReadyOnlyField=[];
    
    

    connectedCallback(){
        this.lstfields = this.strFieldAPINames.split(',');
        this.lstRequiredFields = this.strRequiredFields == null ? [] : this.strRequiredFields.split(',');
        this.lstReadyOnlyField = this.strReadOnlyFields== null ? [] : this.strReadOnlyFields.split(',');
        this.generatesJSON();
        this.booShowForm=true;
        
    }

    generatesJSON(){
        let jsonData = {};    
        this.lstfields.forEach((element, index, array) => {
            jsonData['FieldName'] = element;
            if(this.lstRequiredFields.includes(element)){
                jsonData['IsReq']= true;               
            }else{
                jsonData['IsReq']= false;           
            }
            if(this.lstReadyOnlyField.includes(element) || this.booReadOnly){
                jsonData['IsReadOnly']= true;               
            }else{
                jsonData['IsReadOnly']= false;           
            }               
            this.lstInfomatRecds.push(jsonData);
            jsonData = {}
        })
       console.log('JSON fields======>'+ JSON.stringify(this.lstInfomatRecds));
            
    }

    showSuccessToast(){
        this.booShowForm=true;
        const evt = new ShowToastEvent({
            title: 'Record saved successfully',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    stopSpinner(){
        this.booShowForm=true;
    }

    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.booShowForm=false;
    }
}