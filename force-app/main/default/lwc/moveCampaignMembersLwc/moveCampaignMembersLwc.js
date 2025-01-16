import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    consoleLog,
    consoleError,
    callServer,
    genericEvent,
    isNotBlank,
    showSuccessToast,
    isBlank,
    isEmpty,
    showErrorToast
} from 'c/utils';
import getCampaignMembers from '@salesforce/apex/MoveCampaignMembersController.getCampaignMembers';
import moveCampaignMembers from '@salesforce/apex/MoveCampaignMembersController.moveCampaignMembers';
import {
    columns
} from './column.js';
export default class MoveCampaignMembersLwc extends LightningElement {
    /*global Map*/   
    
    @api lstFilteredCampaignMemberRecords=[];
    @api recordId;
    @track isLoading;
    preselectedRows=[];
    @track offsetSize;
    campaignName;
    mapLabels=new Map();
    lstFinalCampaignMemberRecords = [];
       
       
    connectedCallback(){
       this.columns=columns;
       this.initializeData();
    }
    //Initial Data Load Method
    initializeData(){
        this.isLoading=true;
        callServer(getCampaignMembers,{
            campaignId:this.recordId
        },result =>{
                let returnData = JSON.parse(result);
                consoleLog('Data = ',returnData);
                this.lstFinalCampaignMemberRecords=returnData.lstCampaignMembers;
                this.lstFilteredCampaignMemberRecords=returnData.lstCampaignMembers;
                this.campaignName=returnData.strCampaignName;
                this.mapLabels=returnData.mapLabels;
                this.offsetSize=returnData.strOffsetSize;
                this.isLoading=false;
        }, error => {
            consoleError('error ',JSON.stringify(error));
        });
    }
    
    //Cancel Method.
    handleCancel(event){
        genericEvent('close',event,this);
    }
     
    //Submit Method.
    handleSubmit(){
        let selectedCampaignMemberIds=[];
        selectedCampaignMemberIds=this.lstFinalCampaignMemberRecords.filter((rec)=>{
            return rec.checked;
        }).reduce((accumulator,currentValue)=>{
            accumulator.push(currentValue.id);
            return accumulator;
        },selectedCampaignMemberIds);

        consoleLog('selectedCampaignMemberIds',selectedCampaignMemberIds);

        let newCampaignId = this.template.querySelector('[data-id="inputText0"]');
        if(isBlank(newCampaignId.value)){
            newCampaignId.setErrors([{message:"Complete this field."}]);
            newCampaignId.focus();
            return;
        }

        if(isEmpty(selectedCampaignMemberIds)){
            showErrorToast(this.mapLabels.Move_Campaign_Members_Cmp_ErrorMsg_Unselected);
            return;
        }

        if(this.recordId===newCampaignId.value){
            showErrorToast(this.mapLabels.Move_Campaign_Members_Cmp_ErrorMsg_Existing);
            return;
        }
        
        consoleLog('All Validation Passed');
        this.isLoading=true;
        callServer(moveCampaignMembers,{
            strCampaignMemberIds:JSON.stringify(selectedCampaignMemberIds),
            strNewCampaignId:newCampaignId.value
            },result =>{
                if(isNotBlank(result) && result ==='SUCCESS'){
                   this.isLoading=false; 
                   showSuccessToast(this.mapLabels.Move_Campaign_Members_Cmp_SuccessMsg);
                   this.handleCancel();
                 }else if(isNotBlank(result) && result ==='NOTEXIST'){
                    this.isLoading=false;   
                    showErrorToast(this.mapLabels.Move_Campaign_Members_Cmp_ErrorMsg_Member_Already_Moved);
                    this.handleCancel();
                 }
            }, error => {
                    consoleError('error ',JSON.stringify(error));
        });
        
        
    }

    //Search Functionality Method.
    handleSearchChange(event) {
        let searchString = event.target.value.toUpperCase();
        this.isLoading=true;
        this.lstFilteredCampaignMemberRecords = this.lstFinalCampaignMemberRecords.filter(function (ele){
            if((isNotBlank(ele.strType)) && (ele.strType.toUpperCase().includes(searchString))|| 
            (isNotBlank(ele.strStatus)) && (ele.strStatus.toUpperCase().includes(searchString)) || 
            (isNotBlank(ele.strFirstName)) && (ele.strFirstName.toUpperCase().includes(searchString))||
            (isNotBlank(ele.strLastName)) && (ele.strLastName.toUpperCase().includes(searchString))||
            (isNotBlank(ele.strCompanyOrAccount)) && (ele.strCompanyOrAccount.toUpperCase().includes(searchString))|| 
            (isNotBlank(ele.strCampaignMemberNotes)) && (ele.strCampaignMemberNotes.toUpperCase().includes(searchString))){
                           return true;
            }
            return false;
         });
         
        this.handlePreselectedRows(this.lstFilteredCampaignMemberRecords);    
           
        consoleLog('preselectedRows',this.preselectedRows);
        consoleLog('Filtered List',this.lstFilteredCampaignMemberRecords);

        let context = this;
        setTimeout(function(){
            context.isLoading = false;         
        },'500');
    }

    //Row Selection Method
    handleSelectedRows(event) {
        let selRows = event.detail;
        this.lstFinalCampaignMemberRecords.forEach((rec)=>{
            if(selRows.some(el => el.id === rec.id)){
                rec.checked=true;
            }else if(this.lstFilteredCampaignMemberRecords.some((el)=>el.id === rec.id)){
                rec.checked=false;
            }

        });
        consoleLog('this.final List',this.lstFinalCampaignMemberRecords);
    }

    // Enable-Disable  Submit Button Method
    get deActivateButton() {
        return isEmpty(this.lstFilteredCampaignMemberRecords);
    }


    //Handle Load More Method 
    handleLoadMore() { 
        this.handlePreselectedRows(this.lstFinalCampaignMemberRecords);
        consoleLog('preselectedRows',this.preselectedRows);
    }

    //Handle PreSelected Rows
    handlePreselectedRows(datalist) {
        this.preselectedRows=[];
        datalist.forEach((rec)=>{
            if(rec.checked){
                this.preselectedRows.push(rec.id);
            }
        });
    }

}