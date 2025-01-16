import { LightningElement, track, api } from "lwc";
import { consoleLog, isNotNull, isEmpty, callServer,consoleError } from "c/utils";
import loadPage from "@salesforce/apex/RelocationFormExternalSiteController.loadPage";
import doSave from "@salesforce/apex/RelocationFormExternalSiteController.doSave";
export default class RelocationFormExternalSite extends LightningElement {
	@api recordId;
	@track booLoading = true;
	@track showToast = false;
	showForm = false;
	isError = false;
	@track message = "";
	activeSections = [];
	@api labelValueMap;
	@api picklistValueTranslationMap;
	picklistValueMapConverted = [];
	currentValues;
	setIgnoredSection = [
		"System Information",
		"Other Information",
		"Information"
	];
	connectedCallback() {
		this.booLoading = true;
		this.picklistValueMapConverted = JSON.parse(this.picklistValueTranslationMap);
		this.loadLayout();
	}
	loadLayout() {
		callServer(
			loadPage,
			{
				strRecordId: this.recordId,
			},
			(result) => {
				let retResult = JSON.parse(result);
				let pagelayoutMeta = retResult.LayoutStructure;
				this.currentValues = retResult.mapRecordFieldToValue;
				pagelayoutMeta = pagelayoutMeta.Sections;
				pagelayoutMeta.forEach((section, sectionIndex, sections) => {
					section.Columns.forEach((column) => {
						column.Fields.forEach((field, fieldIndex, fields) => {
							let apiName = field.APIName;
							let apiNameSmall = apiName.toLowerCase();
							if(this.picklistValueMapConverted[apiNameSmall] !== null){
								fields[fieldIndex].pickListValueSet = this.picklistValueMapConverted[apiNameSmall];
							}
							if(field.Behavior === 'Required'){
								fields[fieldIndex].isRequired = true;
							}
							else
								fields[fieldIndex].isRequired = false;
							fields[fieldIndex].UserInputValue = this.currentValues[apiName];
							fields[fieldIndex].UILabel =this.labelValueMap[apiName];
						});
					});
					sections[sectionIndex].UILabel = this.labelValueMap[section.Label];
					if (this.setIgnoredSection.includes(section.Label))
						sections[sectionIndex].isSystemColumn = true;
					else {
						sections[sectionIndex].isSystemColumn = false;
						this.activeSections.push(section.Label);
					}
				});
				consoleLog("Updated JSON", pagelayoutMeta);
				this.pageLayoutSection = pagelayoutMeta;
				this.showForm = true;
				this.booLoading = false;

			},
			(error) => {
				this.booLoading = false;
			}
		);
	}

	onValueSet(event) {
		let fieldAPIName = event.detail.fieldAPIName;
		let fieldValue = event.detail.Value;
		this.pageLayoutSection.forEach((section)=> {
			section.Columns.forEach((column) => {
				column.Fields.forEach((field, fieldIndex, fields)=> {
					if (field.APIName === fieldAPIName) {
						fields[fieldIndex].UserInputValue = fieldValue;
					}
				});
			});
		});
	}

	onSubmit() {
		this.booLoading = true;
		let saveInfo = [];
		this.pageLayoutSection.forEach((section)=> {
			section.Columns.forEach((column) => {
				saveInfo = column.Fields.reduce((accumulator, field)=> {
					if (
						isNotNull(field.APIName) &&
						isNotNull(field.UserInputValue) &&
						field.UserInputValue !==
							this.currentValues[field.APIName]
					) {
						let reducedField = {
							fieldApiName: field.APIName,
							value: field.UserInputValue,
						};
						accumulator.push(reducedField);
					}
					return accumulator;
				}, saveInfo);
			});
		});
		consoleLog("saveInfo", saveInfo);
		if (isEmpty(saveInfo)) {
            this.displayMessage("No changes to save.",true);
			this.booLoading = false;
			return;
		}
		callServer(
			doSave,
			{
				strRecordId: this.recordId,
				strJSON: JSON.stringify(saveInfo),
			},
			(result) => {
				consoleLog("result", result);
				this.showForm = false;
                this.displayMessage("Record is successfully saved.",false);
			},
			(error) => {
				consoleError("error", error);
				this.showForm = false;
                this.displayMessage(error,true);
			}
		);
	}
	// getter method to set toast style
	get notificationStyle() {
		return this.isError
			? "border-color:red;color:red;"
			: "border-color:green;color:green;";
	}

    displayMessage(message,boolIsError){
        this.booLoading = false;
        this.isError = boolIsError;
        this.showToast = true;
		this.message = message;
		if(this.template.querySelector('.slds-page-header'))
			this.template.querySelector('.slds-page-header').scrollIntoView();
    }
	checkAllDataPopulated(){
		let boolFieldNotPopulated = false;
		let listChildComponent = this.template.querySelectorAll('c-dynamic-input-field');
        listChildComponent.forEach((element) =>{
			let isInvalid=element.isInvalid();
			if(!boolFieldNotPopulated && isInvalid)
				boolFieldNotPopulated=true;
        });
		if(!boolFieldNotPopulated){
			this.onSubmit();
		}
	}
}