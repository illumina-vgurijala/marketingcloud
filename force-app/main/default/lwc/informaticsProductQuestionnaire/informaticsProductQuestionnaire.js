/* eslint-disable no-alert */
/* eslint-disable no-console */
/* eslint-disable no-undef */
import { LightningElement, track, api } from 'lwc';
import fetchFields from '@salesforce/apex/InformaticsProductQuestionnaireCntrl.fetchFields';
export default class OnLoadLWC extends LightningElement {
    @api   recordId;
    @api   ObjectName = 'Apttus_Proposal__Proposal_Line_Item__c';
    @track booShowForm1=false;
	 @track isDragen=false;
    @track records;
    @track formHeader;
    @api strFieldName;
    @api readOnly;
    @track mapUILabels;
    @api strRequiredField;
    @api strReadOnlyFields;
	@api strProductFamily;

    
  // initialize component
  connectedCallback() {
    let JSONObj;
 
    /* Call the Salesforce Apex class method to find the Records */
    fetchFields({
      objectName : this.ObjectName, 
      recordID : this.recordId,
    })
  .then(result => {
    this.records = result;  
    console.log('records after response -> ' +JSON.stringify(this.records));
    JSONObj = JSON.parse(result);
    this.strFieldName  =  JSONObj.Quote_Line_Item_Fields;
    this.strRequiredField = JSONObj.Required_Fields;
    this.mapUILabels = JSONObj.mapLabels;
	this.strProductFamily = JSONObj.Product_Family;
    this.strReadOnlyFields = JSONObj.Read_Only_Fields;
    this.formHeader = this.mapUILabels.Questionnaire_Header_QLI;
    if(this.strProductFamily !== null && this.strProductFamily === 'DRAGEN')
	{
		this.isDragen = true;
	}      
    // eslint-disable-next-line eqeqeq     

        /* if(this.ObjectName === 'Apttus_Proposal__Proposal_Line_Item__c'){
          this.formHeader = this.mapUILabels.UI_Questionnaire_Header_QLI;
          this.readOnly = false;
        }

        if(this.ObjectName === 'Apttus_Config2__AssetLineItem__c'){
          this.formHeader = this.mapUILabels.UI_Questionnaire_Header_ALI;
          this.readOnly = false;
        }

        if(this.ObjectName === 'Apttus_Config2__OrderLineItem__c'){
          this.formHeader = this.mapUILabels.UI_Questionnaire_Header_OLI; 
          this.readOnly = false;
        } */
        if(this.strFieldName!==null && this.strFieldName.trim()!=='')
		{
			this.booShowForm1 = true;
		}          

    this.error = undefined;
    
})
.catch(error => {
    this.error = error;
    this.records = undefined;
    console.log('find records error ---> '+JSON.stringify(error));

});
  }
}