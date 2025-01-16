import { LightningElement,api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getPendingApprovals from '@salesforce/apex/PendingApprovalRequestController.getPendingApprovals';
import getRequestForApproveReject from '@salesforce/apex/PendingApprovalRequestController.getRequestForApproveReject';
import setpagelimit from '@salesforce/label/c.UI_Set_Page_Limit_Button';
import buttonnext from '@salesforce/label/c.UI_Button_Next';
import buttonprevious from '@salesforce/label/c.UI_Button_Previous';
import buttonapprove from '@salesforce/label/c.UI_Button_Approve';
import thapprovereject from '@salesforce/label/c.UI_Approve_Reject_Comments';
import thjustification from '@salesforce/label/c.UI_Justification';
import thhighestlevelapprovalreqd from '@salesforce/label/c.UI_Highest_Level_of_Approval_Required';
import thhighestdiscountrequested from '@salesforce/label/c.UI_Highest_Discount_Requested';
import thagreementnumber from '@salesforce/label/c.UI_Agreement_Number';
import threquestdetails from '@salesforce/label/c.UI_Request_Details';
import thagreementmetricslink from '@salesforce/label/c.UI_Agreement_Metrics_Link';
import thagreementprimaryaccount from '@salesforce/label/c.UI_Agreement_Primary_Account';
import threcordtype from '@salesforce/label/c.UI_Record_Type';
import thagreementlink from '@salesforce/label/c.UI_Agreement_Link';
import errorvalidnumber from '@salesforce/label/c.UI_Enter_Valid_Number_Error';
import errornorecordselected from '@salesforce/label/c.UI_No_Records_Selected_Error_Message';
import errornoapprovals from '@salesforce/label/c.UI_No_Approvals_Error_Message';
import currentapprovalpending from '@salesforce/label/c.UI_Current_Pending_Approvals';
import errorcomponentmessage from '@salesforce/label/c.UI_Error_Message_Recall_Agreement';
import pendingapprovalrequestheading from '@salesforce/label/c.UI_Pending_Approval_Requests';
import messagewanttoapprove from '@salesforce/label/c.UI_Message_Want_To_Approve';
import approvalrequestsmessage from '@salesforce/label/c.UI_Message_Approval_Requests';
import batchinprogress from '@salesforce/label/c.UI_Message_Batch_In_Progress';
import metricslink from '@salesforce/label/c.UI_Metrics_Link_Row_Heading';
import standingQuote from '@salesforce/label/c.AgreementRecordTypeNameStandingQuote';
import masterCustomerAgreement from '@salesforce/label/c.AgreementRecordTypeNameMasterCustomerAgreement';

export default class ApprovalRequestBatchApprover extends LightningElement {

    @track noData = false;
    @track appReqData = [];
    @track currentDisplayList = [];
    @track disableNext = false;
    @track disablePrevious = false;
    @track showSpinner = true;
    @track pageLimit = 25;
    @track startIndex = 0;
    @track lastIndex = 0;
    @track totalReq ;
    @track allSelected = false;
    @track errorMessage = '';
    @track checkedList = [];

    label = {
        setpagelimit,
        buttonnext,
        buttonprevious,
        buttonapprove,
        thapprovereject,
        thjustification,
        thhighestlevelapprovalreqd,
        thhighestdiscountrequested,
        thagreementnumber,
        threquestdetails,
        thagreementmetricslink,
        thagreementprimaryaccount,
        threcordtype,
        thagreementlink,
        errorvalidnumber,
        errornorecordselected,
        errornoapprovals,
        currentapprovalpending,
        errorcomponentmessage,
        pendingapprovalrequestheading,
        messagewanttoapprove,
        approvalrequestsmessage,
        batchinprogress,
        metricslink
    };
	
	isValidRecordType(){
        for(let i = 0 ; i < this.appReqData.length ; i++){
            if(this.appReqData[i]["agreementRecordTypeName"] == standingQuote || this.appReqData[i]["agreementRecordTypeName"] == masterCustomerAgreement)
                this.appReqData[i]["isValidRecordType"] = true;
            else{
                this.appReqData[i]["isValidRecordType"] = false;
            }
        }
    }

    connectedCallback()
    {
        const sobjectName = 'Apttus__APTS_Agreement__c';
        getPendingApprovals({objectname : sobjectName})
        .then(result => {
            if(JSON.parse(result) == "BatchInProgress")
            {
                this.noData = true;
                this.showSpinner = false;
                this.errorMessage = this.label.batchinprogress;
				return;
            }
            
            this.appReqData = JSON.parse(result);
            if(this.appReqData)
            {
				this.isValidRecordType();
              this.showSpinner = false;
              if(this.appReqData.length <= this.pageLimit)
              {
                  this.currentDisplayList = this.appReqData;
                  this.disableNext = true;
                  this.disablePrevious = true;
              }
              else
              {
                  this.disablePrevious = true;
                  this.currentDisplayList = this.appReqData.slice(this.startIndex,this.pageLimit);
                  this.lastIndex = this.startIndex + this.pageLimit;
              }
              this.totalReq = this.label.currentapprovalpending + ' - ' + this.appReqData.length ;
            }
            else
            {
                this.noData = true;
                this.showSpinner = false;
                this.errorMessage = this.label.errornoapprovals;
            }
        })
        .catch(error => {
                console.error('Error - ' + error);
                this.noData = true;
                this.showSpinner = false;
                this.errorMessage = this.label.errorcomponentmessage;
            });
    }

    selectAll(event)
    {
        this.allSelected = true;
        for(let i = 0 ; i < this.currentDisplayList.length ; i++)
        {
            this.currentDisplayList[i].isChecked = true;
        }
    }

    unselectAll(event)
    {
        this.allSelected = false;
        for(let i = 0 ; i < this.currentDisplayList.length ; i++)
        {
            this.currentDisplayList[i].isChecked = false;
        }
    }

    viewNext()
    {
        this.disablePrevious = false;
        this.startIndex = this.lastIndex;
        this.lastIndex = this.lastIndex + parseInt(this.pageLimit);
        if(this.lastIndex >= this.appReqData.length)
        {
            this.disableNext = true;
            this.lastIndex = this.appReqData.length;
        }
        this.currentDisplayList = this.appReqData.slice(this.startIndex,this.lastIndex);
        this.checkSelectAll();
    }

    viewPrevious()
    {
        this.disableNext = false;
        this.lastIndex = this.startIndex;
        this.startIndex = this.startIndex - this.pageLimit;
        if(this.startIndex == 0)
        {
            this.disablePrevious = true;
            this.startIndex = 0;
        }
        this.currentDisplayList = this.appReqData.slice(this.startIndex,this.lastIndex);
        this.checkSelectAll();
    }

    selectCurrent(event)
    {
      let requestName = event.currentTarget.id;
      if(requestName.includes('-'))
      {
         let req = requestName.split('-');
         requestName = req[0];
      }
      let selectedIndex ; 
      for(let i =0 ; i < this.currentDisplayList.length ; i++)
      {
          if(this.currentDisplayList[i].requestName == requestName)
          {
            selectedIndex = i;
            break;
          }
      } 
      this.currentDisplayList[selectedIndex].isChecked = true;
      this.checkSelectAll();
    }

    removeCurrent(event)
    {
        let requestName = event.currentTarget.id;
        if(requestName.includes('-'))
      {
         let req = requestName.split('-');
         requestName = req[0];
      }
      for(let i =0 ; i < this.currentDisplayList.length ; i++)
      {
          if(this.currentDisplayList[i].requestName == requestName)
          {
            this.currentDisplayList[i].isChecked = false;
            break;
          }
      }
      this.checkSelectAll();
    }

    checkSelectAll()
    {
        let selectallLines = true;
        for(let i = 0 ; i < this.currentDisplayList.length ; i++)
        {
           if(this.currentDisplayList[i].isChecked == false)
           {
               selectallLines = false;
               break;
           }
        }
        if(selectallLines)
        {
            this.allSelected = true;
        }
        else
        {
            this.allSelected = false;
        }
    }

    approveSelected()
    {
        let isSelected = false;
        let finalList = [];
        for(let i = 0 ; i < this.appReqData.length ; i++)
        {
            if(this.appReqData[i].isChecked == true)
            {
                isSelected = true;
                finalList.push(this.appReqData[i]);
            }
        }
        if(isSelected == false)
        {
            this.notifyUser('Error',this.label.errornorecordselected,'error');
        }
        else
        {
            let msg = this.label.messagewanttoapprove + ' ' + finalList.length + ' ' + this.label.approvalrequestsmessage;
            let resp = this.callConfirmWindow(msg);
            if(resp == false)
            {
                return;
            }
            this.checkedList = finalList;
            this.showSpinner = true;
            this.serverCall('approve');
        }
    }

    serverCall(approveorreject)
    {
        getRequestForApproveReject({dataList:JSON.stringify(this.checkedList) ,approveOrReject : approveorreject})
        .then(result => {
            if(result)
            {
            this.showSpinner = true;
            this.notifyUser('Success',this.label.batchinprogress,'success');
            setTimeout(function(){ location.reload(); }, 3000);
            }  
        })
        .catch(error => {
            console.error('Error - ' + error);
            this.noData = true;
            this.showSpinner = false;
            this.errorMessage =  this.label.errorcomponentmessage;
        });
        
    }

    notifyUser(title, message, variant) {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
    }

    populateComment(event)
    {
        let requestName = event.currentTarget.id;
        let commentValue = event.target.value;
        if(requestName.includes('-'))
        {
            let req = requestName.split('-');
            requestName = req[0];
        }

    for(let i =0 ; i < this.currentDisplayList.length ; i++)
      {
          if(this.currentDisplayList[i].requestName == requestName)
          {
            this.currentDisplayList[i].comments = commentValue;
            break;
          }
      }
    }

    setPageLimit(event)
    {
        let newLimit = event.target.value;
        this.pageLimit = newLimit;
    }

    changeLimit(event)
    {
        if(!isNaN(this.pageLimit) && this.pageLimit != 0)
        {
            this.showSpinner = true;
            if(this.appReqData.length <= this.pageLimit)
              {
                  this.currentDisplayList = this.appReqData;
                  this.startIndex = 0;
                  this.lastIndex = this.pageLimit;
                  this.disableNext = true;
                  this.disablePrevious = true;
                  this.checkSelectAll();
              }
              else
              {
                  this.disablePrevious = true;
                  this.disableNext = false;
                  this.startIndex = 0;
                  this.lastIndex = this.startIndex + parseInt(this.pageLimit);
                  this.currentDisplayList = this.appReqData.slice(this.startIndex,this.lastIndex);
                  this.checkSelectAll();
              }
            this.showSpinner = false;
        }
        else
        {
            this.notifyUser('Error',this.label.errorvalidnumber,'error');
        }

    }

    populateValueFromChild(event)
    {
        let apprequestid = event.detail.index;
        let commentValue = event.detail.selectedValue;
        for(let i = 0 ; i < this.appReqData.length ; i++)
        {
            if(this.appReqData[i].requestName == apprequestid)
            {
                this.appReqData[i].comments = commentValue;
            }
        }        
    }

    callConfirmWindow(input) {
        let response = confirm(input);
        return response;
    }

}