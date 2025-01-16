/*	
   Author - Rishab
   Description - [DCP-52334] LWC Component to Create Idea (Innovation Hub) records and show suggestions to users to avoid duplicates.
	
   Modification Log:
	Developer                       Date                   Description
	====================================================================================================================
	Deep Diwakar	              May-31-2023          DCP-60043:Added code to handle service console navigation through Parent Aura component

   */
import { LightningElement,track,api,wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ideaObject from '@salesforce/schema/innohub__Innovation_Idea__c';  
import { consoleLog, callServer,genericEvent,showSuccessToast,showErrorToast,isEmpty } from 'c/utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAllInnovationIdeaRecords from '@salesforce/apex/IdeaCreationComponentController.getAllInnovationIdeaRecords';
import successMessage from '@salesforce/label/c.UI_Idea_Creation_Successful';
import messageSimilarIdeas from '@salesforce/label/c.UI_Message_Similar_Ideas';
import postIdeaHeading from '@salesforce/label/c.UI_Post_An_Idea_Heading';

export default class IdeaCreationComponent extends NavigationMixin(LightningElement) {
    
    @track showEditForm = false;
    @track showSpinner = true;
    @track showSuggestions = false; 
    @api iscommunity = false;
    duplicateList = [];
    allIdeaRecordList = [];
    recordTypeId = '';
    showDependent=false;
    errorMessage = '';
    showError = false;

    label = {
        successMessage,
        messageSimilarIdeas,
        postIdeaHeading
    };

    @wire(getObjectInfo,{objectApiName : ideaObject})
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Idea');
        }else if(result.error){
            consoleLog('error '+result.error);
        }
    }

	renderedCallback()
	{
		if(!this.showEditForm)
		{
			this.callServerController();
			this.showEditForm = true;
			this.isRequired = true;
		}
	}

	showSubCat(event)
	{
		event.detail.value !== '' ? this.showDependent = true : this.showDependent = false;   
	}

	handleSubmit()
	{
		this.showSpinner = true;
		this.showError = false;
	}

	handleSuccess(event)
	{
		consoleLog('In success');
		let reccId = event.detail.id;
		showSuccessToast(this.label.successMessage);

		//DCP-60043: firing custom event for Parent aura component to handle navigation
		const closeEvent = new CustomEvent('closetab', { detail: {ideaId: reccId},});
		this.dispatchEvent(closeEvent);
		this.showSpinner = false; 
	}

	checkDuplicates(event)
	{
		try{
			let strInput = event.target.value;
			if(strInput && strInput.length > 2 && this.allIdeaRecordList && !isEmpty(this.allIdeaRecordList))
			{
				this.duplicateList = [];
				this.showSuggestions = false;

				let duplicates = [];
				duplicates =  this.allIdeaRecordList.filter(function(objIdeaRecord) {
					return objIdeaRecord.Name.toLowerCase().includes(strInput.toLowerCase()) ;
				});

				if(duplicates && !isEmpty(duplicates))
				{
					this.duplicateList = duplicates.slice(0,5);
					this.showSuggestions = true;
				}
			}
			else
			{
				this.showSuggestions = false;
			}
		}catch (err) {
			consoleLog('The error is ' + err.message);
		}
	}

	goToListView()
	{
		if(this.iscommunity)
		{
			genericEvent('closepopup',{},this);
		}
		this.navigateToListView();
	}

	//DCP-60043: Added api decorator so this method can be called from parent Aura component
	@api
	navigateToCreatedIdea(ideaRecordId) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: ideaRecordId,
				objectApiName: 'innohub__Innovation_Idea__c',
				actionName: 'view'
			}
		});
	}

	navigateToListView() {
		this[NavigationMixin.Navigate]({
			type: 'standard__objectPage',
			attributes: {
				objectApiName: 'innohub__Innovation_Idea__c',
				actionName: 'list'
			},
			state: {
				filterName: 'Recent'
			}
		});
	}

	callServerController()
	{
		callServer(getAllInnovationIdeaRecords,{}
				,result => {
				this.allIdeaRecordList = JSON.parse(result);
				if(!isEmpty(this.allIdeaRecordList))
				{
					this.allIdeaRecordList.forEach(objIdea => { objIdea.redirectUrl =  '/' + objIdea.Id; });
				}
				this.showSpinner = false;
			},
			error => {
				showErrorToast(error.body.message);
			});
	}

	handleEditOnError(event) {                
        this.errorMessage =  event.detail.message + "\n" + event.detail.detail;
        this.showSpinner = false;
        this.showError = true;   
        const evt = new ShowToastEvent({
            title: "Error!",
            message: this.errorMessage,
            variant: "error",
        });   
        this.dispatchEvent(evt);     
    }

	//DCP-60043: Added method to log navigation error and display user frieldy message
	@api
	handleNavigationError(error) {
		consoleLog('navigation error: ' + error.message);
		const evt = new ShowToastEvent({
            title: "Error!",
            message: "Your idea is created, but we couldn't navigate you to that Idea. Please find it through Idea list view",
            variant: "error"
        });   
        this.dispatchEvent(evt);

	}

}