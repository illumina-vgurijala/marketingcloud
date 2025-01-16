import { LightningElement, api,track } from "lwc";
import { consoleLog, genericEvent, isBlank,isNotBlank,isNotEmpty,callServer,consoleError } from "c/utils";
import getFieldType from "@salesforce/apex/DynamicInputFieldController.getFieldType";

export default class DynamicInputField extends LightningElement {
	@api objField;
	@track boolLoaded = false;
	//field type booleans
	isPicklist = false;
	isMultiSelect = false;
	isText = false;
	fieldType = '';
	isCheckbox=false;
	//picklist variables
	lstValue = [];
	options = [];
	dummyCheckBox=[
		{ label: 'checked', value: 'true' },
		{ label: 'unchecked', value: 'false' }
	  ];
	finalValue;
	connectedCallback() {
		callServer(
			getFieldType,
			{
				strFieldAPIName : this.objField.APIName
			},
			(result) => {
				let returndata = JSON.parse(result);
				this.finalValue = this.objField.UserInputValue;
				switch (returndata.fieldType) {
					case "MULTIPICKLIST":
						this.isMultiSelect = true;
						if(isNotBlank(this.finalValue)){
							this.lstValue = this.finalValue.split(';');
						}
						this.setPicklistOptions(this.objField.pickListValueSet);
						break;
					case "PICKLIST":
						this.isPicklist = true;
						this.setPicklistOptions(this.objField.pickListValueSet);
						break;
					case "DATE":
						this.isText = true;
						this.fieldType = 'date';
						break;
					case "DATETIME":
						this.isText = true;
						this.fieldType = 'datetime';
						break;
					case "BOOLEAN":
						this.isCheckbox = true;
						this.fieldType = 'checkbox';
						break;
					default:
						this.isText = true;
						this.fieldType = 'text';
				}
				this.boolLoaded = true;
			},
			(error) => {
				consoleError("error", error);
				this.displayMessage(error,true);
			}
		);
		
	}

	get isCheckedCheckBox(){
		if(!this.isCheckbox)
			return false;
		return this.finalValue;
	}

	get isUnCheckedCheckBox(){
		if(!this.isCheckbox)
			return false;
		return !this.finalValue;
	}

	setPicklistOptions(picklistdata) {
		picklistdata.forEach((element) => {
			this.options.push({label : element.strValue , value : element.strKey});
		});
	}

	handleChange(event) {
		const objDetails = Object.create({});
		objDetails.fieldAPIName = this.objField.APIName;
		if(this.fieldType === 'checkbox'){
			objDetails.Value = event.target.checked;
		}
		else if(this.isMultiSelect && isNotEmpty(event.detail.value)){
			objDetails.Value = event.detail.value.join(';');
		}
		else{
			objDetails.Value = event.detail.value;
		}
		this.finalValue = objDetails.Value;
		genericEvent("fieldupdate", objDetails, this);
	}
	// api enabled method to validate inputs
    @api isInvalid(){
		if(this.fieldType === 'checkbox' || !this.objField.isRequired){
			return false;
		}
		else if(isNotBlank(this.fieldType) && isBlank(this.finalValue)){
            this.setInvalidInput('lightning-input');
            return true;
        }
        else if(isBlank(this.finalValue) && this.isPicklist){
			this.setInvalidInput('lightning-combobox');
            return true;
		}
		else if(isBlank(this.finalValue) && this.isMultiSelect){
			this.setInvalidInput('lightning-dual-listbox');
            return true;
		}
		return false;
    }
	setInvalidInput(inputParam){
        this.template.querySelector(inputParam).reportValidity();
        this.template.querySelector(inputParam).focus();
    }
}