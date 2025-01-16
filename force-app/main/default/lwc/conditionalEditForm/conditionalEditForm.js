import { LightningElement,api,track } from 'lwc';
import getDragenCustomMetaData from '@salesforce/apex/ConditionalEditFormController.getDragenCustomMetaData';
import {
    showSuccessToast,
    genericEvent,
    callServer,
    consoleLog
} from 'c/utils';
import Cloud from '@salesforce/label/c.Cloud';
import On_Prem from '@salesforce/label/c.On_Prem';
import Select_Instance_Type from '@salesforce/label/c.Select_Instance_Type';
import Server_Connectivity from '@salesforce/label/c.Server_Connectivity';
import Will_Server_Be_Connected_To_Internet from '@salesforce/label/c.Will_Server_Be_Connected_To_Internet';

export default class conditionalEditForm extends LightningElement {
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
    @track lstDefaultFields=[];
    @track lstDependentFields=[];
    @track lstControllingFields=[];
    @track instanceType='';
    @track connectedToInternet='';
    @track onPremObj ;
    @track cloudObj ;
    @track nullObj ;
    @track instanceTypeValue = '';
    
    
    connectedCallback(){        
        let jsonObj;        
        callServer(getDragenCustomMetaData,{
            recordId : this.recordId
        }, result => {                
                jsonObj = JSON.parse(result);                  
                this.onPremObj = jsonObj.onPremType;
                this.cloudObj = jsonObj.cloudType;
                this.nullObj = jsonObj.nullType;                   
                this.instanceType = jsonObj.instanceTypeValue;
                this.connectedToInternet =  jsonObj.serverConnectivity;
                this.booShowForm=false;                 
                this.selectInstenceType();
                this.booShowForm=true;                                               
            }, error => {                
                consoleLog('Error ---> ', error);                
            }            
        );          
                         
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
        }else{
            intSmall=6;
            intMed=4;
            intLarge=3;
        }
        this.lstInfomatRecds = [];
        this.lstDefaultFields.push(Select_Instance_Type);
        this.lstfields.forEach((element) => {            
            jsonData['FieldName'] = element;
            this.lstRequiredFields.includes(element) ? jsonData['IsReq']= true : jsonData['IsReq']= false;
            this.lstReadyOnlyField.includes(element) ? jsonData['IsReadOnly']= true : jsonData['IsReadOnly']= false;
            this.lstDefaultFields.includes(element) ? jsonData['controlVisible']= true : jsonData['controlVisible']= false;            
            this.lstControllingFields.includes(element) ? jsonData['isControlling']= true : jsonData['isControlling']= false;
            this.lstDependentFields.includes(element) ? jsonData['isDependent']= true : jsonData['isDependent']= false;                        
            jsonData.intSmall=intSmall;
            jsonData.intMed=intMed;
            jsonData.intLarge=intLarge;            
            this.lstInfomatRecds.push(jsonData);
            jsonData = {}
        })
       console.log('JSON fields1======>'+ JSON.stringify(this.lstInfomatRecds));
            
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
        event.preventDefault();// stop the form from submitting
        const fields = event.detail.fields;        
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.booShowForm=false;
    }
    handleChange(event) {         
        let insType = event.target.value;        
        insType = insType === '' ? null : insType;
        this.instanceType = insType;
        this.booShowForm=false;   
        this.selectInstenceType();                                        
        this.booShowForm = true;         
        
    }
    
    selectInstenceType() {
        this.lstfields = [];
        this.lstRequiredFields = [];
        this.lstReadyOnlyField = [];
        this.lstControllingFields=[];
        this.lstDependentFields=[];
        if(this.instanceType === On_Prem)
        {                    
            this.lstfields = this.onPremObj.strFields.split(',');
            this.lstRequiredFields = this.onPremObj.strRequiredFields;
            this.lstReadyOnlyField = this.onPremObj.strReadOnlyFields;
            this.lstControllingFields.push(Will_Server_Be_Connected_To_Internet); 
            this.lstDependentFields.push(Server_Connectivity);              

            this.generatesJSON();            
        }
        else if(this.instanceType === Cloud) 
        {                    
            this.lstfields = this.cloudObj.strFields.split(',');
            this.lstRequiredFields = this.cloudObj.strRequiredFields;
            this.lstReadyOnlyField = this.cloudObj.strReadOnlyFields;                          
            
            this.generatesJSON();
        }
        else if(this.instanceType === null)
        {                     
            this.lstfields = this.nullObj.strFields.split(',');
            this.lstRequiredFields = this.nullObj.strRequiredFields;
            this.lstReadyOnlyField = this.nullObj.strReadOnlyFields;
            this.generatesJSON();
        }
    }   

    handleChangeFieldDependency(event) {        
        let insType = event.target.value;        
        insType = insType === '' ? null : insType;
        this.booShowForm=false;                                                
        this.booShowForm=true;             
        insType === 'Yes' ? this.connectedToInternet= 'Online' : '';
        insType === 'No' ? this.connectedToInternet= 'Offline': '';
        insType === 'I Am Not Sure' ? this.connectedToInternet= 'Offline': '';
        insType === null ? this.connectedToInternet= null : '';        
        this.generatesJSON();                                   
                
    }
}