import { LightningElement, track, api, wire } from "lwc";
import loadPage from "@salesforce/apex/KnowledgeCreationMasterController.loadPage";
import getCaseValues from "@salesforce/apex/KnowledgeCreationMasterController.getCaseValues";
import {
	consoleLog,
	showErrorToast,
	showSuccessToast,
	isBlank,
	genericEvent,
	isEmpty
} from "c/utils";
import { CurrentPageReference } from 'lightning/navigation';
import uId from '@salesforce/user/Id';

export default class KnowledgeCreationChild extends LightningElement {
	@track booLoading = false;
	@track objectApiName = "Knowledge__kav";
	@api recordTypeId;
	@track isFillInformation = false;
	@track pageLayoutSection;
	@api knowledgeRecordId;
	@track activeSections = [];
	@track selectedValue;
	@track options = [];
	@track booLoading = false;
	setIgnoredSection = ["Fields"];
	@track urlNameBool = false;
	@track givenValue;
	@track hasRendered = true;
	//Start DCP-49920
	@track caseAvailable = false;
	@track caseSubject = '';
	@track caseDescription = '';
	@track caseIvd = false;
	@track userId = uId;
	//End DCP-49920
	setHiddenFields = ['Primary_Approver__c','Secondary_Approver__c','Review_Status__c'];
	connectedCallback() {
		this.booLoading = true;
		this.selectedValue = this.recordTypeId;
		this.isFillInformation = true;
		consoleLog("before Calling Layout");
		this.booLoading = false;
		this.loadLayout();
	}

	loadLayout() {
		this.booLoading = true;
		consoleLog("selectedValue" + this.selectedValue);
		loadPage({ recordTypeID: this.selectedValue })
			.then((result) => {
				let pagelayoutMeta = JSON.parse(result);
				pagelayoutMeta = pagelayoutMeta.Sections;
				console.log("Before Updated JSON--", pagelayoutMeta);
				pagelayoutMeta.forEach((element, index, array) => {
					if(element.Label==='Information' || element.Label ==='Approval Details' || element.Label ==='Article Review')
						element.Class = 'slds-col slds-size_1-of-2';
					else
						element.Class = 'slds-col slds-size_2-of-2';
					element.Columns.forEach((element1) => {						
						element1.Fields.forEach((element2, index2, array2) => {
							if(this.setHiddenFields.includes(element2.APIName))
							 	array2[index2]["isSystemColumn"] = true;
							else{
								array2[index2]["isSystemColumn"] = false;
								if (element2.isRequired == true)
									array2[index2]["isRequired"] = true;
								else array2[index2]["isRequired"] = false;
								if (element2.isReadOnly == true)
									array2[index2]["isReadOnly"] = true;
								else array2[index2]["isReadOnly"] = false;

								if (element2.APIName == "Knowledge_Source__c") {
									array2[index2]["defaultValue"] = "DCP";
									array2[index2]["isReadOnly"] = true;
								}
								if (element2.APIName == "Primary_Workflow__c")
									array2[index2]["isRequired"] = true;
								if (element2.APIName == "Secondary_Workflow__c")
									array2[index2]["isRequired"] = true;  
								if (element2.APIName == "Title") 
									array2[index2]["isTitle"] = true;
								if (element2.APIName == "UrlName")
									array2[index2]["isUrlName"] = true;
								if (element2.APIName == "Language") {
									array2[index2]["isRequired"] = false;
								}
								//Start DCP-49920
								if (element2.APIName === "Article_Body__c") {
									array2[index2]["isArticle"] = true;
								}
								if (element2.APIName === "IVDDx_Article__c") {
									array2[index2]["isIvd"] = true;
								}
								if (element2.APIName === "Article_Version_Author__c") {
									array2[index2]["isAuthor"] = true;
								}
								//End DCP-49920
								
							}
						});
					});
					if (this.setIgnoredSection.includes(element.Label))
						array[index]["isSystemColumn"] = true;
					else {
						array[index]["isSystemColumn"] = false;
						this.activeSections.push(element.Label);
					}
				});
				console.log("Updated JSON--", pagelayoutMeta);
				this.pageLayoutSection = pagelayoutMeta;
				this.booLoading = false;
			})
			.catch((error) => {
				this.booLoading = false;
				console.log("error-->", error);
			});
	}
	@api
	setValueofURLname(event) {
		let valueofUrlName = event.detail.value;
		this.givenValue = valueofUrlName
			.replace(/([~!@#$%^&*()_+=`{}\[\]\|\\:;'<>,.\/? ])+/g, "-")
			.replace(/^(-)+|(-)+$/g, "");
	}

	validateInput = () => {
		let flag = true;
		let valueofTitle = this.template.querySelector(".Title").value;
		let valueofUrlName = this.template.querySelector(".UrlName").value;
		let valueofPrimaryWorkflow = this.template.querySelector(
			".Primary_Workflow__c"
		).value;
		if (
			isBlank(valueofTitle) ||
			isBlank(valueofUrlName) ||
			isBlank(valueofPrimaryWorkflow)
		) {
			this.template
				.querySelectorAll("lightning-input-field")
				.forEach((element) => {
					element.reportValidity();
				});
			flag = false;
		}
		return flag;
	};

	@api
	submitFilledForm() {
		if (this.validateInput()) {
			consoleLog("going to submit form");
			this.template.querySelector("lightning-record-edit-form").submit();
		}else {
			const objDetails = Object.create({});
			objDetails.value = 'No validation happened so passing event to enable next btn';
			genericEvent("saveerror", objDetails, this);
		}
	}

	handleSuccess(event) {
		event.preventDefault();
		consoleLog(
			"Success submitted Record  --> Needs to pass event " + event.detail.id
		);
		const objDetails = Object.create({});
		objDetails.value = event.detail.id;
		genericEvent("savesuccess", objDetails, this);
		this.booLoading = false;
	}

	handleError(event) {
		let message = "";
		if (Object.entries(event.detail.output.fieldErrors).length !== 0) {
			const getField = Object.keys(event.detail.output.fieldErrors)[0];
			message = event.detail.output.fieldErrors[getField][0].message;
		} else {
			message = event.detail.message + "\n" + event.detail.detail;
		}
		showErrorToast(message);
		const objDetails = Object.create({});
		objDetails.value = message;
		genericEvent("saveerror", objDetails, this);
		this.booLoading = false;
	}

	//Added for DCP-49920 to get the URL and check if case id is present
	@wire(CurrentPageReference)
		getpageRef(pageRef) {
			if(pageRef.state.hasOwnProperty('c__recordId')){
				let caseId = pageRef.state.c__recordId;
				this.getCaseDetails(caseId);
			}
		}

	//Added for DCP-49920 to set the values recieved from Case button navigation
	getCaseDetails(id){
		getCaseValues({caseId: id})
		.then((result)=>{
			if(!isEmpty(result)){
				this.caseAvailable = true;
				this.caseSubject = result[0].Subject;
				this.caseDescription = result[0].Description;
				this.caseIvd = result[0].IVD_Product_Identifier__c;
			}
		})
		.catch((error)=>{
			consoleLog('error: '+JSON.stringify(error));
		})
	}

}