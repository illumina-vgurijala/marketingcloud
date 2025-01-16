/* eslint-disable no-undef */
/* eslint-disable no-empty */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */


import { LightningElement,track,wire,api} from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
// import server side apex class method 
import findRecords from '@salesforce/apex/AddArticletoCaseController.findRecords';
import attachCase from '@salesforce/apex/AddArticletoCaseController.attachCase';
import { getRecord } from 'lightning/uiRecordApi';
// import standard toast event 
import {ShowToastEvent} from 'lightning/platformShowToastEvent'




export default class customSearch extends NavigationMixin(LightningElement) {
    //@track: Marks a property for internal monitoring. A template or function using- 
    //this property forces a component to rerender when the property’s value changes.
    @track cases;
    @track showTable=false;
    @track isLoading=false;
    searchKey = '';
    searchObject='Case';
    searchField='CaseNumber,Subject';
    queryFields='CaseNumber,Owner.FirstName,Owner.LastName,Subject';
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: ['Knowledge__kav.Id'] })
    knowledgerecord;
 
    // update sVal var when input field value change
    updateSeachKey(event) {
        this.searchKey = event.target.value;
        this.searchKey=this.searchKey.trim();
        if(this.searchKey===null || this.searchKey===''){
        this.cases='';
        this.showTable=false;
    }
    }
	//handle enter  key
    handleEnterEvent(evt){
        console.log('here...'+evt.which);
        if(evt.which===13){
           this.handleOnchange(evt); 
        }

    }
    //call search method
    
	handleOnchange(event){
        //event.preventDefault();
        this.isLoading=true;
       console.log('here..'+this.searchKey + this.isLoading);
       // const searchKey = event.detail.value;
        //this.records = null;
        /* eslint-disable no-console */
        //console.log(seevarchKey);

        /* Call the Salesforce Apex class method to find the Records */
        if(this.searchKey!==null && this.searchKey!==''){
        findRecords({
            searchKey : this.searchKey, 
            objectName : this.searchObject, 
            searchField : this.searchField,
            queryFields : this.queryFields
        })
        .then(result => {
            this.showTable=true;
            this.isLoading=false;
            this.cases = result;
            console.log('find records ---> '+JSON.stringify(this.records));
            this.error = undefined;
            console.log(' records ',  this.isLoading);
            
        })
        .catch(error => {
            this.isLoading=false;
            this.error = error;
            this.records = undefined;
            console.log('find records error ---> '+JSON.stringify(this.error)+ this.isLoading);
        });
    }
    }

    onattachCase(event){
        let CaseIdn=event.detail.value;
        let rec=this.recordId;
        console.log('event here ..'+event.target.la);
        console.log('event ..'+CaseIdn);
      

        attachCase({
            articleId : rec, 
            caseId :CaseIdn 
        })
        .then(result => {
          if(result===false){
              console.log('toasted..'+result);
            const eventMsg = new ShowToastEvent({
                title: 'Info',
                variant: 'Info',
                message: 'Article Already attached to this Case',
                mode: 'pester'
            });
            this.dispatchEvent(eventMsg);
          }else{
            const eventMsg = new ShowToastEvent({
                title: 'Success',
                variant: 'Success',
                message: 'Article  attached to the Case',
                mode: 'pester'
            });
            this.dispatchEvent(eventMsg);
           this.error = undefined;
           console.log(' record inserted'+result);
          }
            
        })
        .catch(error => {
            this.error = error;
           // this.records = undefined;
            console.log('find records error ---> '+JSON.stringify(this.error));
        });

    }

    navigateToCase(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

   
    }