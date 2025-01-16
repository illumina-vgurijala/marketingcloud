import { LightningElement ,track,api} from 'lwc';
import getCaseList from '@salesforce/apex/CaseENBAListViewController.getCaseList';
import getWorkOrderList from '@salesforce/apex/CaseENBAListViewController.getWorkOrderList';
import { caseColumns } from './caseColumns.js';
import { woColumns }  from './workOrderColumns.js';
import getPublishedKnwArticles from '@salesforce/apex/CaseENBAListViewController.getPublishedKnwArticles';
import getAccountFieldDetails from '@salesforce/apex/CaseENBAListViewController.getAccountFieldDetails';
import { knowledgeArticlesColumns }  from './knowledgeColumns.js';
import { accountColumns }  from './accountColumns.js';
import { showErrorToast, callServer, consoleError, isNotNull,isNull, isNotBlank,isBlank } from 'c/utils';

export default class caseENBAListView extends LightningElement {
    @api listViewName = '';
    @api listTitle ='';
    @api recordId;
    @api caseIPId;
    @api workOrderId;
    @api records;
    @api recommendationName;
    @track hideColumn = false;
    @track showInfiteLoad = false;
    @track showDataTable = false;
    @track columns;
    @track offSet = 10;
    @track error;
    @track isvisble;
    @track recid;
    top=50;
    left=50;
    @track impactedRecId;
    @track strToggleSpinnerClass = 'slds-hide';
    @track obApiName = "Field_Action_Notification__c";
    @track strFieldAPINames = "Subject__c,Status__c,Customer_Messaging__c";
    @track strFormHeader = "Details";
    @track booReadOnly = true;
    @track strReadOnlyFields = "Subject__c,Status__c,Customer_Messaging__c";
    @track obApiNameImProd = "Impacted_Products_Serials_Lots__c";
    @track strFieldAPINamesImProd = "Serial_Number__c,Lot_Number__c";
    @track strFormHeaderImProd = "Details Im Prod";
    @track strReadOnlyFieldsImProd = "Serial_Number__c,Lot_Number__c";
    @track fanHeader = "Potential Matched FAN Records";
    @track showSpinner = true; 
    @track showPlusButton = false;
    @track workOrderId ;
    @track showFanList = false;
    @track showEmailList = false;

    /*
    * Method Name: Connected callback              
    */
    connectedCallback(){
        this.showSpinner = false;
        // isNotNull added for checking undefined value. IsBlank is not checking undefined
        if(((this.listViewName === 'Cases' && isNotNull(this.recommendationName) && isNotBlank(this.recommendationName)  && isNotNull(this.caseIPId) && isNotBlank(this.caseIPId)) || this.listViewName === 'Work Order' || this.listViewName === 'FAN' ) && isNotNull(this.recordId) && isNotBlank(this.recordId)){
            this.executeCaseWOFanListViews();
        } else if(this.listViewName === 'Cases' && (isNull(this.caseIPId) || isBlank(this.caseIPId))) {
            let tempRecs = [];
            this.records = tempRecs;
            this.error = undefined;
            this.showDataTable = true;
            this.columns = woColumns;
        }
        else if((this.listViewName === 'Knowledge' || this.listViewName === 'EmailMessages' || this.listViewName === 'Account') && isNotNull(this.recordId) && isNotBlank(this.recordId)){

            this.executeKnowlegeEMAccountListViews();

        }
    }
    /*
    * Method Name: executeKnowlegeEMAccountListViews
    * Description: DCP-54039 Method to get prepare listviews for Knowlege,EmailMessage and Account objects              
    */
     executeKnowlegeEMAccountListViews() {
        if(this.listViewName === 'Knowledge' && isNotNull(this.recordId) && isNotBlank(this.recordId)) {
            this.showFanList = false;
            this.getPublishedKnowledgeArticles();
        } else if(this.listViewName === 'EmailMessages' && isNotNull(this.recordId) && isNotBlank(this.recordId)) {
            this.showFanList = false;
            this.openEmailList();
        } else if(this.listViewName === 'Account' && isNotNull(this.recordId) && isNotBlank(this.recordId)){
            this.getAccountDetails();
        }
     }
    /*
    * Method Name: executeCaseWOFanListViews
    * Description: DCP-51725 Method to get prepare listviews for Work Order ,Case And Fan objects              
    */
    executeCaseWOFanListViews() {
        if(this.listViewName === 'Cases' && isNotNull(this.recommendationName) && isNotBlank(this.recommendationName)){
            this.prepareCaseListView();
        }
        else  if(this.listViewName === 'Work Order' && isNotNull(this.recordId) && isNotBlank(this.recordId)){
            callServer(getWorkOrderList,{accountId : this.recordId
            }, result => {    
                this.records = result;
                this.error = undefined;
                this.showDataTable = true;
                this.columns = woColumns;
                let tempRecs = [];
                let data = this.records;
                data.forEach( ( record ) => {
                    let tempRec = Object.assign( {}, record );  
                    tempRec.NameURL = '/lightning/r/SVMXC__Service_Order__c/' + tempRec.Id+'/view';
                    tempRecs.push( tempRec ); 
                }); 
                this.showSpinner = false;
                this.records = tempRecs;
            },error => {
                consoleError(error);
                showErrorToast(error);
                this.showSpinner = false;
                this.error = error.body.message; 
                this.contacts = undefined;
            });
        
        } else if(this.listViewName === 'FAN' && isNotNull(this.recordId) && isNotBlank(this.recordId)) {
            this.showPlusButton = true;
            this.workOrderId = this.conIPId;
            this.showSpinner = false;
            this.showFanList = true;
        } 
      }
      
    /*
    * Method Name: prepareCaseListView
    * Description: DCP-51725 Method to prepare case list view datatable.               
    */
    prepareCaseListView() {
        callServer(getCaseList, {caseId : this.recordId,conIPId:this.caseIPId,recommendationName:this.recommendationName
        }, result => {
            this.records = result;
            this.error = undefined;
            this.showDataTable = true ;
            this.columns = caseColumns;
            let tempRecs = [];
            let data = this.records;
            this.showSpinner = false;
            data.forEach( ( record ) => {
                let tempRec = Object.assign( {}, record );  
                tempRec.CaseURL = '/lightning/r/' + tempRec.Id+'/view';
                tempRec.OwnerURL = '/lightning/r/' + tempRec.OwnerId+'/view';
                tempRec.OwnerName = tempRec.Owner.Name;
                if(isNotNull(tempRec.AccountId) && isNotBlank(tempRec.AccountId)){
                    tempRec.AccountURL = '/lightning/r/' + tempRec.AccountId+'/view';
                    tempRec.AccountName = tempRec.Account.Name;
                }
                if(isNotNull(tempRec.ContactId) && isNotBlank(tempRec.ContactId)){
                    tempRec.ContactURL = '/lightning/r/' + tempRec.ContactId+'/view';
                    tempRec.ContactName = tempRec.Contact.Name;
                }
                tempRecs.push( tempRec ); 
            }); 
            this.showSpinner = false;
            this.records = tempRecs;
        },error => {
            consoleError(error);
            showErrorToast(error);
            this.showSpinner = false;
            this.error = error;
            this.records = undefined;
        });
    }

    /*
    * Method Name: getPublishedKnowledgeArticles
    * Description: DCP-54039 Method to get published articles.               
    */
    getPublishedKnowledgeArticles() {
        this.showSpinner = true;
        callServer(getPublishedKnwArticles,{recordId: this.recordId},result => { 
            this.showSpinner = false;
            this.records = result;
            this.error = undefined;
            this.showDataTable = true;
            this.columns = knowledgeArticlesColumns;
            let tempRecs = [];
            let data = this.records;
            data.forEach( ( record ) => {
                let tempRec = Object.assign( {}, record );  
                tempRec.TitleURL = '/lightning/r/Knowledge__kav/' + tempRec.Id+'/view';
                tempRecs.push( tempRec ); 
            }); 
            this.records = tempRecs;
        },error => {
            showErrorToast(JSON.stringify(error));
            consoleError('error ', JSON.stringify(error));
            this.showSpinner = false;
            this.isvisble =false; 
        });
    }

     /*
    * Method Name: getAccountDetails
    * Description: DCP-54039 Method to get Case's Account .               
    */

     getAccountDetails(){
        this.showSpinner = true;
        getAccountFieldDetails({recordId: this.recordId})
        .then((result) => { 
            this.showSpinner = false;
            this.records = result;
            this.error = undefined;
            this.showDataTable = true;
            this.columns = accountColumns;
            let tempRecs = [];
            let data = this.records; 
            data.forEach( ( record ) => {
                let tempRec = Object.assign( {}, record );        
                    tempRec.AccountURL = '/' + tempRec.Id;
                    tempRecs.push( tempRec );
            }); 
            this.records = tempRecs;
        })
        .catch((error) => {
            showErrorToast(JSON.stringify(error));
            consoleError('error ', JSON.stringify(error));
            this.showSpinner = false;
            this.isvisble =false; 
        }); 
    }

    /*
    * Method Name: openEmailList
    * Description: DCP-54039 Method to get Case's Email Messages.               
    */
    openEmailList() {
        this.showSpinner = false;
        this.showEmailList = true;
        this.showDataTable = false;
    }
}