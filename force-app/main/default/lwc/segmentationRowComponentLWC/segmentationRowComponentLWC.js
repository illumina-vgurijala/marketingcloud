import { LightningElement, api, track } from 'lwc';
import { isNotNull, isEmpty, genericEvent, showErrorToast } from 'c/utils';

const EVENT_MARKET_SEGMENT_CHANGE = 'marketsegmentchange';
export default class SegmentationRowComponentLWC extends LightningElement {    
    @track record;//The record to be displayed
    @api rowIndex; //The index of record to be displayed
    @api lstMarketSegmentPicklistValues; // A list of Market_Segment__c values
    @api marketSegmentToSubSegment;  // A map of Market_Segment__c to Market_Sub_Segment__c values    
    @api mapLabels;  // A map of label values
    @api booReadOnly;  //indicates if component is read only and controls all buttons and actions
    @track lstMarketSubSegmentPicklistValues = [];  // A list of Market_Sub_Segment__c values

    connectedCallback() {        
        if(isNotNull(this.record)) {            
            this.lstMarketSubSegmentPicklistValues = this.generateDependentPicklistOptions(this.marketSegmentToSubSegment,this.record.strMarketSegment);                  
        }
    }

    @api
    get marketSegmentRecord() {
        return this.record;
    }
    set marketSegmentRecord(value) {        
        this.record = JSON.parse(JSON.stringify(value));        
    }
    
    @api
    validateInputFields() {
        return [...this.template.querySelectorAll('.validate')]
            .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
            }, true);
    }

    handleChange(event) {
        const targetName = event.target.name;
        const targetValue = event.target.value;               
        
        if(targetName === this.mapLabels.UI_Label_Segmentation_Selection_Field_Market_Segment) {
            this.record.strMarketSegment = targetValue;         
            this.lstMarketSubSegmentPicklistValues = this.generateDependentPicklistOptions(this.marketSegmentToSubSegment,this.record.strMarketSegment); 
            this.record.lstSubSegments = [];                       
        }

        if(targetName === this.mapLabels.UI_Label_Segmentation_Selection_Field_Market_Sub_Segment) {            
            this.record.lstSubSegments = targetValue; 
        }

        if(targetName === this.mapLabels.UI_Label_Segmentation_Selection_Field_Allocation) {
            this.record.decAllocation = targetValue;
        }
        
        const returnObject = this.generateDetailsForEvent();
        this.sendEvent(returnObject,EVENT_MARKET_SEGMENT_CHANGE);                           
    }
    
    handleDelete(event) {        
        if(this.booReadOnly){
			showErrorToast(this.mapLabels.UI_Error_Message_Segmentation_Selection_Market_Segment_Locked);
			return;
		}
        this.record.booDelete = true;
        const returnObject = this.generateDetailsForEvent();
        this.sendEvent(returnObject,EVENT_MARKET_SEGMENT_CHANGE);		
    }

    generateDetailsForEvent() {
        const objDetails = Object.create({});
        objDetails.index = this.rowIndex;
        objDetails.strMarketSegment = this.record.strMarketSegment;
        objDetails.lstSubSegments = this.record.lstSubSegments;             
        objDetails.decAllocation = this.record.decAllocation;
        objDetails.booDelete = this.record.booDelete;
        return objDetails;
    }
    
    generateDependentPicklistOptions(mapDependencies,strSelectedValue) {        
        return mapDependencies[strSelectedValue];
    }

    sendEvent(returnObject, eventName){         
        genericEvent(eventName,returnObject,this);            
    }
    
    get showSegmentationRow() {
        return !this.record?.booDelete;
    }

    get disableMarketSubSegment() {
        return this.booReadOnly || isEmpty(this.lstMarketSubSegmentPicklistValues);
    }
}