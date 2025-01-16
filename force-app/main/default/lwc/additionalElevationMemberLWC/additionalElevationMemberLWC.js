import { LightningElement, track, wire, api } from "lwc";  
import {showErrorToast,consoleLog } from 'c/utils';
import findRecords from "@salesforce/apex/AdditionalElevationMemController.findRecords";
import fetchElevationMember from "@salesforce/apex/AdditionalElevationMemController.fetchElevationMember";
import deleteElevationMember from "@salesforce/apex/AdditionalElevationMemController.deleteElevationMember";
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import RELATED_CONTACTS_OBJECT from '@salesforce/schema/Related_Contacts__c'; 
import TYPE_FIELD from '@salesforce/schema/Related_Contacts__c.Type__c';
import userHelpText from '@salesforce/label/c.UserHelpText';//DCP-51754
import contactHelpText from '@salesforce/label/c.ContactHelpText';//DCP-51754
import ElevationMemberText from '@salesforce/label/c.ElevationMemberText';//DCP-51754
import contactText from '@salesforce/label/c.sObject_Type_Contact';//DCP-56756

const actions = [
  { label: 'Delete', name: 'delete' },
];

const columns = [
  { label: 'Type', fieldName: 'typePiclst' },
  { label: 'Name', fieldName: 'name' },
  { label: 'Title', fieldName: 'title' },
  { label: 'Representative', fieldName: 'representative'},
  { type: 'action',
    typeAttributes: { rowActions: actions },  
  },
];

 export default class additionalElevationMemberLWC extends LightningElement {
   //Track
  @track lstSelected = {};
  @track lstOptions = []; //Dual list box
  @track recordsList=[];  
  @track recordsListTemp=[];  
  @track searchKey = ""; //Lookup 
  @track iconName;  //Lookup icon
  @track lookupLabel = "Search";  
  @track message; //Lookup message 
  @track objName;// = "Contact";
  @track lstRecContact =[];  
  @track finalLstRecContactAssigned = []; //stringify Final string 
  @track _columns = columns;
  @track strSelectedValue='';
  @track record;
  //DCP-51754 :End
  helpTextContent='';
  isSearchObjSelected=false;
  ElevationMemberMessage;
  //DCP-51754:End
  @track isContact; //DCP-56756

  //Api
  @api selectedValue;  
  @api selectedRecordId;  // to get the WO ID  
  @api objectApiName; //Object Combobox 
  @api placeholder;
  @api label; 
  @api required = false; //Type field
  @api requiredMessage;
  @api strRecContact; //stringify Final string output property
  validity = true;
  selectedMemberId;   
  value = 'Contact'; 
  data = [];  
  isEmptyCheck=false;
  isSearchObjSelected=false;
  isRendered=false;
  doneTypingInterval = 500; // interval time for key debounce
  typingTimer; // timer var for key debounce
  
  renderedCallback(){
    if(this.isRendered){
      return; 
    }
    this.isRendered=true;
    this.fetchElevationMemberData();
    this.ElevationMemberMessage = ElevationMemberText;
  }


    fetchElevationMemberData()
    {
      fetchElevationMember({recId: this.selectedRecordId})
            .then((result) => {
              console.log("Inside method selectedRecordId=== ",this.selectedRecordId);
              this.record  = result;
              this.finalLstRecContactAssigned=JSON.parse(JSON.stringify(result));
              console.log("Inside method record=== ",this.record); 
            })
            .catch((error) => {
              console.log("error === "+error);
            });
    }
  
  // Get Related Contacts Object Info for Type Dual list box
  @wire (getObjectInfo, {objectApiName: RELATED_CONTACTS_OBJECT})
    relatedContactsObjectInfo;
  
  // Get Type Picklist values.
  @wire(getPicklistValues, {recordTypeId: '$relatedContactsObjectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_FIELD })
  types(data, error){
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
  }
  
  //Handle Dual list box change event
  handleListChange(event) {
    this.lstSelected = event.detail.value;
    this.strSelectedValue ='';    
    for (const obj in this.lstSelected) {   
      this.strSelectedValue +=this.lstSelected[obj]+';' ;      
    }   
    this.strSelectedValue= this.strSelectedValue.trim();
    this.strSelectedValue=this.strSelectedValue.slice(0, -1);    
}

    get options() {
        return [
            { label: 'User', value: 'User' },
            { label: 'Contact', value: 'Contact' }            
        ];
    }

	//Handle Contact/User combo box change event  
  handleSearchRelatedToChange(event) {
        this.value = event.detail.value;
        this.searchKey = "";
        this.selectedValue = null;  
        this.selectedMemberId = null;
        this.recordsList = []; 
        //Enables the visiblity of helptext on UI
        this.isSearchObjSelected=true;//DCP-51754 
        if(event.detail.value === 'Contact'){            
                    this.objName = 'Contact';
                    this.lookupLabel = 'Contact';
                    this.iconName = 'standard:contact';
                    this.helpTextContent=contactHelpText;//DCP-51754
                }
                else{            
                    this.objName = 'User';
                    this.lookupLabel = 'User';
                    this.iconName = 'standard:user';
                    this.helpTextContent=userHelpText;//DCP-51754
                }
    }
       
  //Handle Search name combo box change event
  onRecordSelection(event) {  
   this.selectedMemberId = event.target.dataset.key;  
   this.selectedValue = event.target.dataset.name; 
   this.recordsListTemp=this.recordsList;
   //---------
   
   }

  /*Add Row event will populate the datatable and prepare List of string to send as output 
  	for related contact record creation using invocable method in screen flow.
  */
  addRow(){  	   
  this.isEmptyCheck=false; 
	if(this.strSelectedValue === ''){						 
		showErrorToast('Type is Required to create Additional Elevation Member'); 		
	}
	else if(this.selectedValue === '' || this.selectedValue === null){		
		showErrorToast('Please identify a User or Contact before saving'); 		
	}
	else
  {		
	    this.addRelatedConHandler(); 
	}
      
}
   
// This function is used to add related contact records to an array 
  addRelatedConHandler()
  {
    for(let i=0; i< this.recordsListTemp.length; i++)
    {   
			if(this.recordsListTemp[i].Id===this.selectedMemberId){    
        let strRepresentative = this.objName==='User'? this.recordsListTemp[i].CompanyName: this.recordsListTemp[i].Account.Name ;
        let objCon={
          'typePiclst': this.strSelectedValue,
          'title':this.recordsListTemp[i].Title,
          'representative':strRepresentative,
          'name' :this.selectedValue,
          'woRecId' : this.selectedRecordId,
          'tempAllIds':this.selectedMemberId,
        }
			   //This is used to assigning ids based on contacts and users as these are different fields
			   if(this.objName ==='Contact'){
          objCon.contactId=this.selectedMemberId; 
			  }
			  else{
          objCon.userId=this.selectedMemberId;
			  }
        this.finalLstRecContactAssigned.push(objCon);
		   }
		  }
      
				const filteredArr = this.finalLstRecContactAssigned.reduce((acc, current) => {
				const x = acc.find(item => item.tempAllIds === current.tempAllIds &&  item.typePiclst===current.typePiclst);
				if (!x) {
				  return acc.concat([current]);
				  } 
				  
				else {
					return acc;
				  }
				}, []);        
		  this.finalLstRecContactAssigned=JSON.parse(JSON.stringify(filteredArr));//filteredArr;
	    
		  this.strRecContact=JSON.stringify(this.finalLstRecContactAssigned);
		  this.searchKey = "";
		  this.selectedValue = null;  
		  this.selectedMemberId = null;
		  this.lstSelected = {};		                     
		  this.recordsList = []; 
  }

  handleKeyChange(event) {       
   this.searchKey =  event.target.value;    
   clearTimeout(this.typingTimer);
    this.typingTimer = setTimeout(() => {
      this.getLookupResult();
    }, this.doneTypingInterval);
  }  
   
  removeRecordOnLookup(event) {  
   this.isEmptyCheck=false; 
   this.searchKey = "";  
   this.selectedValue = null;  
   this.selectedMemberId = null;  
   this.recordsList = [];  
   this.onSeletedRecordUpdate();     
 }  

 //get the user or contact records from apex class 
 getLookupResult() {   
   if(this.objName!==null && this.objName !=='undefined' && this.searchKey.length >= 3)  
   {  
    this.isEmptyCheck=true; 
      findRecords({ searchKey: this.searchKey, objectName : this.objName })  
      .then((result) => {  
        this.isContact = false; //DCP-56756
        if (result.length===0) {  
          this.recordsList = [];  
          this.message = "No Records Found";  
        } 
        else {  
          this.recordsList = result; 
          //DCP-56756 starts
          if(this.objName === contactText) {
            this.isContact = true;
          }
          //DCP-56756 ends
          this.message = "";        
        }  
        this.error = undefined;  
      })  
    //Add toast message    
      .catch((error) => {  	
        this.error = error; 
        showErrorToast(error.body.output.errors[0].errorCode + '- '+ error.body.output.errors[0].message);  
      });  
   }
   if(this.objName!==null && this.objName !=='undefined' && this.searchKey.length < 1)  
   { 
      this.isEmptyCheck=false; 
      this.selectedValue = null;  
      this.selectedMemberId = null;
      this.recordsList = [];
   }  
  }
    
  onSeletedRecordUpdate(){  
    const passEventr = new CustomEvent('recordselection', {  
      detail: { selectedRecordId: this.selectedMemberId, selectedValue: this.selectedValue }  
     });  
     this.dispatchEvent(passEventr);  
   } 

   //To handle datatable row delete action
   handleRowAction(event) {
    const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                this.strRecContact=JSON.stringify(this.finalLstRecContactAssigned); 
                break; 
            default: 
        }
           
	} 

  deleteRow(row) {
      const { tempAllIds } = row;      
      const index = this.findRowIndexById(tempAllIds); //1  
      if (index !== -1)
      {          
          if(this.finalLstRecContactAssigned[index].memberId!==null)
          {            
            deleteElevationMember({delId: this.finalLstRecContactAssigned[index].memberId})
            .then(() => {
            })
            .catch((error) => {
              consoleLog("error === "+error);
            });
           
          }  
          this.finalLstRecContactAssigned = this.finalLstRecContactAssigned.slice(0, index)
              .concat(this.finalLstRecContactAssigned.slice(index + 1));
      }    
    }

    

    findRowIndexById(tempAllIds) {
      let ret = -1;
      this.finalLstRecContactAssigned.some((row, index) => {
          if (row.tempAllIds === tempAllIds) {
              ret = index;
              return true;
          }
          return false;
      });
      return ret;
    }

    @api
    validate() {
        if( this.validateInput() ) { 
            return { 
                isValid: true 
            }; 
        } else { 
            return { 
                isValid: false, 
                errorMessage: this.requiredMessage 
            }; 
        } 
    }

    validateInput(){
        if(!this.value){
            this.validity = false;
        }
        return this.validity;
    }	

      
  }