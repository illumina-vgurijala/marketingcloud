import {
    LightningElement,
    api,
    track
} from 'lwc';
import getRecordTypeData from '@salesforce/apex/KnowledgeCreationMasterController.getRecordTypeData';
import Knowledge_Resource from '@salesforce/resourceUrl/Knowledge_Resource';
import {
    genericEvent,
    callServer,
    isBlank,
    consoleLog    
} from 'c/utils';



export default class KnowledgeRecordSelection extends LightningElement {

    @track listToDisplay = [];
    @track displayImage = false;
    @track selectedRecordType = '';
    booLoading = false;
    @api recordTypeId;
      
    

    connectedCallback() {  
                
        this.selectedRecordType =  this.recordTypeId;  
        this.fetchRecordTypes();        
    }

    fetchRecordTypes() {
        this.booLoading = true;
        callServer(getRecordTypeData, {
            objectApiName: 'Knowledge__kav'
        }, result => {           
            result.forEach((element) => {
                this.listToDisplay.push({
                    label: element.strRecordTypeLabel,
                    value: element.strRecordTypeId,
                    image: Knowledge_Resource + '/' + element.strImageName,
                    description: element.strRecordTypeDescription,
                    checked:false
                });
                 
            });
            //for previous selection
            if(!isBlank(this.selectedRecordType)){                
            this.listToDisplay.forEach(ele => ele.checked = ele.value === this.selectedRecordType)};             
            this.displayImage = true;
            this.booLoading = false;
        }, error => {
            alert(error);
            this.booLoading = false;
        });
    }

    handleChange(event) {       
        this.selectedRecordType = event.target.value;
        this.listToDisplay.forEach(ele => ele.checked = ele.value === this.selectedRecordType);        
        consoleLog('handle change'+this.selectedRecordType);
        consoleLog('handle change ::'+JSON.stringify(this.listToDisplay));
        const objDetails = Object.create({});
        objDetails.value = this.selectedRecordType;
        genericEvent('recordtypeselection', objDetails, this);
    }
}