import { LightningElement,api,track } from 'lwc';
import {
    showSuccessToast,
    genericEvent
} from 'c/utils';

export default class DynamicEditForm extends LightningElement {
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
        let size = this.lstfields.length;
        let intSmall=6,intMed=3,intLarge=4;
        if(size===1){
            intSmall=12;
            intMed=12;
            intLarge=12;
        }else if(size===2){
            intSmall=6;
            intMed=6;
            intLarge=6;
        }else if(size===3){
            intSmall=6;
            intMed=3;
            intLarge=3;
        }else{
            intSmall=6;
            intMed=4;
            intLarge=3;
        }
        
        this.lstfields.forEach((element) => {
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
            jsonData.intSmall=intSmall;
            jsonData.intMed=intMed;
            jsonData.intLarge=intLarge;
            this.lstInfomatRecds.push(jsonData);
            jsonData = {}
        })
       console.log('JSON fields======>'+ JSON.stringify(this.lstInfomatRecds));
            
    }

    handleSuccess(){
        this.booShowForm=true;
        showSuccessToast('Record saved successfully');
        const objDetails = Object.create({});
        objDetails.value = 'Record saved successfully';
        genericEvent('recordsave', objDetails, this);
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