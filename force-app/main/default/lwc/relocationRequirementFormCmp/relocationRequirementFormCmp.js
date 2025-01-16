/* eslint-disable no-alert */
import { LightningElement, track, api } from "lwc";
import { consoleLog } from "c/utils";
import checkUserAuthenticity from "@salesforce/apex/RelocationFormExternalSiteController.checkUserAuthenticity";

export default class RelocationRequirementFormCmp extends LightningElement {
	@track booLoading = true;
	showError = false;
	@api recordId;
	showform = false;
	message = "";
	showsecurityform = false;
	error;
	strPassValue;
	@api labelValueMap;
	@api picklistValueTranslationMap;
	// connected Callback
	connectedCallback() {
		consoleLog('Connected Callback ->RelocationRequirementFormCmp');
		consoleLog('Connected Callback ->RelocationRequirementFormCmp',this.labelValueMap.Relocation_Site_Password_Text);
		this.showform = false;
		this.showsecurityform = true;
		this.booLoading = false;
		consoleLog('connectedCallback ends');
	}
	// Handler for change on passkey field
	handlechange(event) {
		this.strPassValue = event.target.value;
		consoleLog(this.strPassValue);
	}
	// Method to check password
	submitPasscode() {
		this.booLoading = true;
		consoleLog("submitPasscode()");
		checkUserAuthenticity({
			strUserPassKey: this.strPassValue,
			strRecordId: this.recordId,
		})
			.then((result) => {
				if (result === "User Not Authorized") {
					consoleLog("User Not Authorized");
					this.showsecurityform = false;
					this.message = result;
					this.showError = true;
				} else {
					consoleLog("User Authorized");
					this.showform = true;
					this.showsecurityform = false;
				}
				this.booLoading = false;
			})
			.catch((error) => {
				consoleLog(error);
			});
	}
	
}