import { LightningElement,wire,track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import returnResponse from '@salesforce/apex/FindDuplicateRecordsController.fetchDuplicates';
import createWarnings from '@salesforce/apex/FindDuplicateRecordsController.createDuplicateWarnings';
import sendMergeReqst from '@salesforce/apex/FindDuplicateRecordsController.sendEmailMergeRequest';
import {getRecord} from 'lightning/uiRecordApi';
import getContactMergeAccess from '@salesforce/apex/FindDuplicateRecordsController.isMergeAccessGranted';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import helpText from '@salesforce/label/c.DB_Help_Text_Non_Admins';
import showMsg1 from '@salesforce/label/c.DB_Show_Msg_1';
import showMsg2 from '@salesforce/label/c.DB_Show_Msg_2';
import emailSuccessMessage from '@salesforce/label/c.Email_Sent_Successfully';
import commentBoxMsg from '@salesforce/label/c.Comment_Box_Label';
export default class ContactDuplicatesComponent extends NavigationMixin(LightningElement) {
    @api objectApiName;
    @api recordId;
    @track showButton = false;
    @track loaded = false;
    @track showModal = false;
    @track showCommentBox = false;
    @track showMergeButton = false;
    @track noOfRecords = 0;
    @track title;
    @track error;
	//Field to be displayed in UI along with their initial  width
    @track fieldnamestr = {"Id":"105","Name":"185","FirstNameLocal":"190","LastNameLocal":"190","Email":"195","Title":"100","Department__c":"150","Department_Local__c":"195","Marketing_Contact_Status__c":"195","Is_Active__c":"75","Account.Name":"175","Title":"85","Is_MyIllumina_User__c":"165","Phone":"155","MobilePhone":"155","Country_Local__c":"165","Is_Community_User__c":"140","RecordType.Name":"130","CreatedDate":"185"};
    //look up Field to be displayed in UI along with column header 
    @track lookupmap = {"Account.Name":"Account Name", "RecordType.Name":"Record Type"};
    //where clause
    @track whereclause;
    //selected record for merging
    @track selectedRecords;
    @track disableNextButton = true;
    @track isWarningCreated = true;
    @track adminUser = false;
    @track hideCheckboxColumn = true;
    @track profileName;
    //style class for lightning data table
    className = 'tablecss';
    // Expose the labels to use in the templat
    label = {
        helpText, showMsg1,showMsg2,emailSuccessMessage,commentBoxMsg
    };
    //list of profile for whom Submit Merge Button visible
    lstProfilesMergePermission = ["Sales User","Commercial and Revenue Operations","Commercial Ops Quoting User","Channel Partner Sales","Channel Partner Sales and Service","Customer Service","Data Steward","Global Channel Partner", "Sales Contracts","Service Operations","Technical Support","Field Service","Marketing","Marketing Lead Qualification"];
    lstProfiles = ["Data Steward", "System Administrator"];
    connectedCallback(){
        //call the server load
        returnResponse({recordId:this.recordId})
        .then(data => {
            console.log('data-->',data);
            this.loaded=true;
            //if we have duplicates
            if(data.lstDuplicateRecords){
                this.noOfRecords=data.lstDuplicateRecords.length;
                let myArray = data.lstDuplicateRecords;
                //data
                if(this.noOfRecords > 0){
                    this.showButton = true;
                    myArray.unshift(this.recordId);
                    //build the whereclause
                    this.whereclause = "Id in "+"('" + myArray.join("', '") + "')";
                    //buiild the title to displat based on the count of duplicates
                    this.title= this.label.showMsg1+" "+this.noOfRecords+" "+this.label.showMsg2+" "+data.objectName.toLowerCase()+".";
                   
                }else{
                    this.title=this.label.showMsg1+" no "+this.label.showMsg2+" "+data.objectName.toLowerCase()+".";
                }
                //store the map of duplicates along with scenario Ids for merging
                if(data.mapDuplicatesRules){
                    this.mapScenarios = data.mapDuplicatesRules;
                    let firstKey = Object.keys(this.mapScenarios)[0];
                    this.mapScenarios[this.recordId] = this.mapScenarios[firstKey];
                }
                console.log('this.mapScenarios--:',this.mapScenarios);
                 
            }else{
				this.title=this.label.showMsg1+" no "+this.label.showMsg2+" "+data.objectName.toLowerCase()+".";
			}
        })
        //catch the error if any and show it as a toast message.
        .catch((error) => {
            this.data = undefined;
            this.error = error;
            this.loaded=true; 
            console.log('error-->',error);
            if(error && error.body){
                this.ShowTostMessage('Error', error.body.message, 'error');
            }	
        });
    }

    //below code will be used as a function
   @wire(getContactMergeAccess , { permissionSetName: 'MK_Contact_Merge' } ) 
   wiredPermissionSet ({ error, data }) {
        if (data) {
            if(data == true){
                this.adminUser = true;
                this.hideCheckboxColumn = false;
            }
        } else if (error) {
            console.log('permission set access error:', JSON.stringify(error));
            if(error.body){
                this.ShowTostMessage('Error', error.body.message, 'error');
            }
        }
    }

    // wire function for fetching user related fields like profile name.
    @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME] })
    userRecord(result){
        console.log('result:'+JSON.stringify(result));
        if(result.data){
            this.profileName = result.data.fields.Profile.value.fields.Name.value;
            if(this.lstProfiles.includes(this.profileName)){
                this.adminUser = true;
                this.hideCheckboxColumn = false;
            }
        }else if(result.error){
            console.log('Error:'+JSON.stringify(result));
        }
    }
    /**
     * Method: redirectToMergePage
     * params:NA
     * Description: onclick of view duplicates button to open the modal with list of duplicates.
     */
    viewDuplicates(){
        this.showModal = true;
        if(this.lstProfilesMergePermission.includes(this.profileName)){
            this.showMergeButton = true;
        }
        this.showCommentBox= false;
    }
    /**
     * Close the error Modal
     */
    closeModal(){
        this.showModal = false;
    }
	//to display the toast message
    ShowTostMessage(vartitle, varmessage, varvariant) {
        const evt = new ShowToastEvent({
            title: vartitle,
            message: varmessage,
            variant: varvariant,
        });
        this.dispatchEvent(evt);

    }
    /*
    *method:handleSelect
    * description: It will fire when we select a record for merge and store the values in a variable to use later.
    */
    handleSelect(event){
        let records = event.detail.recordIds;
        console.log('selectedRecordIds--?',records);
        if(records && Object.keys(records).length > 1){
            this.selectedRecords = records;
            //enable the next button if userprofile is data stewards || admins
            //disable for all other profiles
            if(this.adminUser){
                this.disableNextButton = false;
            }
        }else{
            this.disableNextButton = true;
            this.selectedRecords={};
        }        
    }
    /*
    * method:next
    * Description: It will redirect to the merge vf page that has been built by dupeblocker for merge functionality
    */
    next(){
        if(this.selectedRecords && this.selectedRecords.length > 0){
            this.isWarningCreated = false;
            //create a json obj and send as param with record id as the key and scenario Id as the value.
            let duplicateRecords={};
            for(let i=0; i<Object.keys(this.selectedRecords).length;i++){
                duplicateRecords[this.selectedRecords[i]]=this.mapScenarios[this.selectedRecords[i]];
            }
            console.log('duplicateRecords-->',duplicateRecords);
            //create warning records using these record Ids.
            createWarnings({recordId:this.recordId, mapDuplicates:duplicateRecords, scenarioType:this.objectApiName})
            .then(data=>{
                console.log('warning-->',data);
                if(data){
                    let mergePageURL=window.location.origin+'/apex/CRMfusionDBR101__DB_Warning_Merge?id='+data;
                    this.isWarningCreated = true;
                    window.open(mergePageURL,"_self");
                }
                this.isWarningCreated = true;
            })
            //catch the error and display it on UI
            .catch((error)=>{
                this.isWarningCreated = true;
                console.log('error-->',error);
                if(error && error.body){
                    this.ShowTostMessage('Error', error.body.message, 'error');
                }
            });
        }
    }
    /*
    * method:submitMergeButton
    * Description: It will open the commentbox with 'Send Merge Request' Button.
    */
    submitMergeButton(){
        this.showCommentBox=true ;
        this.showMergeButton=false ;
    }
    /*
    * method:sendEmail
    * Description: It will send an email to Data Stewards for requesting them to merge contact duplicate records.
    */
    sendEmail(){
        let comment= this.template.querySelector('lightning-textarea').value;
		this.showModal = false;
        sendMergeReqst({recordId:this.recordId, comment})	
        .then(success=>{
            if(success){
                this.ShowTostMessage('Success', this.label.emailSuccessMessage, 'success');
            }
            
        })
        //catch the error and display it on UI
        .catch((error)=>{
            this.isWarningCreated = true;
            console.log('error-->',error);
            if(error && error.body){
                this.ShowTostMessage('Error', error.body.message, 'error');
            }
        });
        
    }
}