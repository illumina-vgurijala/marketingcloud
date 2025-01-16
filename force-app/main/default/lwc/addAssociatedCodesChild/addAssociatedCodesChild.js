import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord, createRecord  } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import codeLibrary from '@salesforce/schema/Code_Library__c'; 
import getAssociatedCodesLwc from '@salesforce/apex/AddAssociatedCodeController.getAssociatedCodesLwc';
import getUserAndCodeLibraryTypeData from '@salesforce/apex/AddAssociatedCodeController.getUserAndCodeLibraryTypeInfo';
import getCodeLibrary from '@salesforce/apex/AddAssociatedCodeController.getCodeLibrary';
import getIVDFlag from '@salesforce/apex/AddAssociatedCodeController.getIVDWorkflow';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Import utils.js Variables/Functions
import { LABELS, CONSTANTS, ASSOCIATEDCODESCOLUMNS, CODELIBCOLUMNS, setFields } from './utils';

export default class AddAssociatedCodesChild extends LightningElement {

    LABELS = LABELS;
    CONSTANTS = CONSTANTS;
    
    @api recordId;
    @api objectApiName;
    
    @track _recordId;
    @track selectedCaseType = [];
    @track highlightedCodes=false;
    @track recordTypeName;
    addedAssociatedRecordId;
    showSpinner = true;
    @track sortBy;
    @track sortDirection;
    searchedCodeName;
    selectedRadioButton;
    bIsElevation = false;
    bLockCodes = false;
    boolQAUser;
    boolLogisticsUser;
    userInfo;
    @track codeTypePicklistArr = [];
    picklistArray = [];
    recordsData;
    @track codeLibApiName;
    objName;
    @track defaultRecordTypeId;
    requiredCodes = [];
    @track associatedCodes = [];
    associatedCodeColumns = [];
    disassociatedCodeLib = {};
    allCodeBLibs = [];
    nonDisassociatedCodeLib = [];
    @track filteredCodeLibrary = [];
    objWireFields = [];
    @track isHazardPresent = false; // added by Dhairya Shah for CMCM - 5951
    ivdWorkflow;  //CMCM-2392
    codeLibColumns = CODELIBCOLUMNS;
    warningMessage = false; // added by Dhairya Shah for CMCM - 4207
    
    get disableSearchButton(){
        
       return (this.selectedRadioButton ) ? false : true;
    }

    
    get showCodeLibrary() {
        return this.filteredCodeLibrary.length > 0;
    }

    //return the fields array based on the API Name.
    get fields() {
        if (this.objectApiName === 'Case') {
            return this.CONSTANTS.CaseOptionalFields;
        }
        else if (this.objectApiName === 'SVMXC__Service_Order__c') {
            return this.CONSTANTS.WOOptionalFields;
        }
        else return [];
    }

    get displayAssociatedCodes() {
        
        this.associatedCodeColumns = ASSOCIATEDCODESCOLUMNS;
        setTimeout(() => {
            this.highlightedCodes = false;
            this.codeTypePicklistArr.forEach(element => {
                this.associatedCodes.forEach(codeType => {
                    if (codeType.Code_Type__c === element.value) {
                        element.class = "slds-form-element__label";
                        
                    }
                });
                if(element.class.includes('highlight')){
                    this.highlightedCodes = true;
                }
            }); 
        }, 200);
        return this.associatedCodes.length > 0 ? true : false;
    }
    
    constructor(){
        super(); 
    } 

    connectedCallback(){ 
        this.getObjWireFields();
        this.fetchAssociatedCodes();
        this.fetchUserAndCodeLibraryTypeData(); 
        this.initCodeTypePicklistArr();
    }
    initCodeTypePicklistArr() {
       this.codeTypePicklistArr = this.codeTypePicklistArr.map((item, index) => {
        return { ...item, checked: index === 0 }; // Check only the first item
    });
    }


    getObjWireFields(){  
        if (this.recordId !== undefined && this.recordId.startsWith("500")) {
            this.objWireFields = this.CONSTANTS.CaseOptionalFields;  
            this.objectApiName = 'Case';
        }else if(this.recordId !== undefined && this.recordId.startsWith("a2B")){
            this.objWireFields = this.CONSTANTS.WOOptionalFields; 
            this.objectApiName = 'SVMXC__Service_Order__c'; 
        }  
    }

    fetchUserAndCodeLibraryTypeData(){ 
        getUserAndCodeLibraryTypeData()
		.then(result => { 
            try{   
                this.userInfo = JSON.parse(result);  
                this.boolQAUserCheck(); 
                this.setRadioButtons();
            } catch(er) { 
            }
		})
		.catch(error => { 
		}) 
    }
    @wire(getIVDFlag)
    wiredFlag({ data, error }) {
        if (data) {          
            this.ivdWorkflow = data.IsOn__c;
        } else if (error) {
        }
    }
    //get code library recordType info
    @wire(getObjectInfo, { objectApiName: codeLibrary })
    getObjectInfo({ data, error }) {
        

        if (data) {
            this.codeLibApiName = data.fields.Code_Type__c.apiName;
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        }
        else if(error) {
            
        }
    }
    setRadioButtons(){   
        if (!this.boolQAUser && !this.boolLogisticsUser) { 
             this.codeTypePicklistArr = [
                 {  label: 'All', value: 'All', class: 'slds-form-element__label' , checked : true }
             ];
             this.selectedRadioButton = 'All';
             let userProfile = this.userInfo.profileName;
             if (userProfile !== 'System Administrator' || userProfile === undefined) {
                 this.addCodesRadio(this.userInfo,'nonlogistics');
             } else { 
                 this.addCodesRadio(this.userInfo,'all');
             }
         }else if(this.boolLogisticsUser){
             this.addCodesRadio(this.userInfo,'logistics');
         }
 
    } 

    addCodesRadio(data,codeType){
        if(codeType === 'all'){
            data.values.forEach((element) => {
                this.codeTypePicklistArr.push({
                    label: element.label, value: element.value, class: 'slds-form-element__label' , checked : false
                    });
            });
        }else if(codeType === 'logistics'){
            data.values.forEach((element) => {
                if(element.value === 'Logistics') {
                this.codeTypePicklistArr.push({
                    label: element.label, value: element.value, class: 'slds-form-element__label' , checked : false
                });
              }
            }); 
        }else if(codeType === 'nonlogistics'){
            data.values.forEach((element) => {
                if(element.value !== 'Logistics') {
                this.codeTypePicklistArr.push({
                    label: element.label, value: element.value, class: 'slds-form-element__label' , checked : false
                });
              }
            });
        }

    }

    //get cases or wo data.
    //@wire(getRecord, { recordId: '$recordId', fields: '$fields', optionalFields?: '$fields' })
    @wire(getRecord, { recordId: '$recordId', optionalFields: '$objWireFields' })
    getRecordHandler({ data, error }) {
        if (data) {
            setTimeout(() => {
                let fieldObj = setFields(data, this.objectApiName);
                // set fields
                this.caseObj = fieldObj.caseObj;
                this.workOrderObj = fieldObj.workOrderObj;
                this.productObj = fieldObj.productObj;
                if(this.caseObj.Record_Type__c === undefined){
                    this.recordTypeName = '';
                }else{
                    this.recordTypeName = this.caseObj.Record_Type__c;
                }  

                this.validateCaseAndWorkOrder();
                this.initialize();
                this.fetchCodeLibrary();
                this.warningTextOnAssociateCodes() // added by Dhairya Shah for CMCM - 4207
            }, 1000);
        }
        else if(error) { 
        }
    }
 
    fetchAssociatedCodes(){ 
        getAssociatedCodesLwc({ recordId: this.recordId, objAPIName: this.objectApiName })
		.then(result => { 
            this.associatedCodes = [];
            result.forEach(element => {
                    let associatedCode = {...element};
                    associatedCode.Parent_Code_Name = associatedCode.Parent_Code__r?.Name;
                    associatedCode.Parent_Code_Id = (associatedCode.Parent_Code__c ? '/' + associatedCode.Parent_Code__c : '');
                    if(associatedCode.Code_Type__c ==='Hazard'){
                        this.isHazardPresent = true;
                    }
                    this.associatedCodes.push(associatedCode);
                }); 
                this.validateCaseAndWorkOrder();
                this.refreshFilteredCodeLibrary(true);
		})
		.catch(error => { 
		}) 
    }

    fetchCodeLibrary(){ 
        getCodeLibrary({ caseType : this.recordTypeName })
		.then(result => { 
            try{ 
                result.forEach(element => {
                    if (element.Name === 'Code Disassociated') {
                        this.disassociatedCodeLib = element;
                    }else{
                        let associatedCode = {...element};
                        associatedCode.Parent_Code_Name = associatedCode.Parent_Code__r?.Name;
                        associatedCode.Parent_Code_Id = (associatedCode.Parent_Code__c ? associatedCode.Parent_Code__c : '');
                        this.nonDisassociatedCodeLib.push(associatedCode); 
                    }
                }); 
                
                this.allCodeBLibs = this.nonDisassociatedCodeLib;

                this.refreshFilteredCodeLibrary(false);
            } catch(er) { 
            }
		})
		.catch(error => { 
		}) 
    }

    validateCaseAndWorkOrder() {
        
        if (this.LABELS.CaseRecordTypeBusinessIssue === this.caseObj.Record_Type__c){
            this.validateBusinessIssueCase();
        }
        this.validateServiceSupportBusinessIssueWorkOrder();
        this.validateInquiryCase();
        this.validateServiceRequestCase();
        this.validateResOnStandaloneWO();//CMCM-10145
        let codeTypeList = [];
        this.associatedCodes.forEach((element) => {
            codeTypeList.push(element.Code_Type__c);
        });

        if (this.codeTypePicklistArr) {
            this.codeTypePicklistArr.forEach((element) => {
                if (this.requiredCodes.includes(element.value) && !codeTypeList.includes(element.value)) {
                    element.class = "slds-form-element__label highlight"; 
                }
            });
        }
    }

    validateBusinessIssueCase() {
        if (this.workOrderObj.Abandoned_Reason__c === null && (this.LABELS.CaseSubTypeComplaint === this.caseObj.Sub_Type__c || this.LABELS.CaseSubTypeGeneralIssue === this.caseObj.Sub_Type__c)) {
            if (this.caseObj.Category__c!== this.LABELS.CaseCategoryLogistics && !this.caseObj.Has_Analysis_Code__c)
                this.requiredCodes.push(this.LABELS.AssociatedCodeTypeAnalysis);
            if (!this.caseObj.Has_Resolution_Code__c)
                this.requiredCodes.push(this.LABELS.AssociatedCodeTypeResolution);
            if ( !this.ivdWorkflow && this.isVerificationCodeRequired())
                this.requiredCodes.push(this.LABELS.AssociatedCodeTypeVerification);
            if (this.caseObj.Category__c === this.LABELS.CaseCategoryLogistics)
                this.requiredCodes.push(this.LABELS.AssociatedCodeTypeLogistics); 
        } 
        if (!this.caseObj.Has_SR_Case_Subject_Code__c)
                this.requiredCodes.push(this.LABELS.AssociatedCodeTypeSubject);
        if (this.isHazardCodeRequired())  
                this.requiredCodes.push(this.LABELS.AssociatedCodeTypeHazard); 
        
    }

    isHazardCodeRequired(){
        let result;
        if (!(this.CONSTANTS.QAREVIEW_NONIVDPRODUCT === this.caseObj.QA_Review__c && this.CONSTANTS.STRING_NO === this.caseObj.PAE_PFA_Evaluation_Required__c)
                && this.LABELS.CaseStatusPendingQAReview === this.caseObj.Status && !this.caseObj.HasHazardCode__c) {
                result = true;
                }
        if(this.LABELS.CaseSubTypeComplaint === this.caseObj.Sub_Type__c && (this.caseObj.IVD_Product_Identifier_Additional_Prod__c === true || this.caseObj.IVD_Product_Identifier__c === true || this.CONSTANTS.STRING_YES === this.caseObj.PAE_PFA_Evaluation_Required__c)) {
                result = true;
                }
        return result;
    }

    isVerificationCodeRequired(){
        let result;
        if(this.CONSTANTS.PRODUCTTYPE_INSTRUMENT === this.productObj.Service_Product_Type__c
            && this.productObj.Regulatory_Type__c !== null
            && this.LABELS.WorkOrderRecordTypeRemoteSupport !== this.workOrderObj.Record_Type__c 
            && (this.productObj.Regulatory_Type__c.includes(this.CONSTANTS.REGULATORYTYPE_DX) || this.productObj.Regulatory_Type__c.includes(this.CONSTANTS.REGULATORYTYPE_EUA) || this.CONSTANTS.REGULATORYTYPE_IUO === this.productObj.Regulatory_Type__c)){ 
                result = true;
        }
        return result;
    }

    validateServiceSupportBusinessIssueWorkOrder() {
        if (!this.ivdWorkflow && (this.CONSTANTS.orderTypesToCheck.includes(this.workOrderObj.SVMXC__Order_Type__c)
            || (this.LABELS.WorkOrderTypeServiceActivities === this.workOrderObj.SVMXC__Order_Type__c && this.LABELS.CaseRecordTypeBusinessIssue === this.caseObj.Record_Type__c && this.LABELS.CaseSubTypeComplaint === this.caseObj.Sub_Type__c))
            && (this.LABELS.WorkOrderRecordTypeServiceSupport === this.workOrderObj.Record_Type__c || this.LABELS.WorkOrderRecordTypeFieldService === this.workOrderObj.Record_Type__c)
            && this.CONSTANTS.PRODUCTTYPE_INSTRUMENT === this.productObj.Service_Product_Type__c
            && this.productObj.Regulatory_Type__c !== null && (this.productObj.Regulatory_Type__c.includes(this.CONSTANTS.REGULATORYTYPE_DX) || this.productObj.Regulatory_Type__c.includes(this.CONSTANTS.REGULATORYTYPE_EUA) || this.CONSTANTS.REGULATORYTYPE_IUO === this.productObj.Regulatory_Type__c)
            && !this.workOrderObj.Has_Verification_Code__c
            && this.LABELS.WorkOrderRecordTypeRemoteSupport !== this.workOrderObj.Record_Type__c) { 
            this.requiredCodes.push(this.LABELS.AssociatedCodeTypeVerification);
        }
    }

    validateInquiryCase() {
        if (this.LABELS.CaseRecordTypeInquiry === this.caseObj.Record_Type__c
            && (this.CONSTANTS.SUBTYPE_ORDER !== this.caseObj.Sub_Type__c && this.CONSTANTS.SUBTYPE_GENERAL !== this.caseObj.Sub_Type__c)
            && !this.caseObj.Has_Inquiry_Case_Subject_Code__c) {
            this.requiredCodes.push(this.LABELS.AssociatedCodeTypeSubject);
        }
    }

    validateServiceRequestCase() {
        if (this.LABELS.CaseRecordTypeServiceRequest === this.caseObj.Record_Type__c && !this.caseObj.Has_SR_Case_Subject_Code__c) {
            this.requiredCodes.push(this.LABELS.AssociatedCodeTypeSubject);
        }
        // added this.LABELS.WorkOrderTypeBillableInstall === this.workOrderObj.SVMXC__Order_Type__c condition by Dhairya Shah for CMCM-12461
        if (this.ivdWorkflow && this.workOrderObj.Abandoned_Reason__c === null && this.LABELS.CaseRecordTypeServiceRequest === this.caseObj.Record_Type__c && !this.caseObj.Has_Resolution_Code__c &&
            (
                (this.LABELS.WorkOrderRecordTypeFieldService === this.workOrderObj.Record_Type__c && (this.LABELS.WorkOrderTypeServiceActivities === this.workOrderObj.SVMXC__Order_Type__c || this.LABELS.WorkOrderTypeRelocation === this.workOrderObj.SVMXC__Order_Type__c || this.LABELS.WorkOrderTypeInstallation === this.workOrderObj.SVMXC__Order_Type__c || this.LABELS.WorkOrderTypePreventativeMaintenance === this.workOrderObj.SVMXC__Order_Type__c || this.LABELS.WorkOrderTypeBillableInstall === this.workOrderObj.SVMXC__Order_Type__c))
                 || (this.LABELS.WorkOrderRecordTypeServiceSupport === this.workOrderObj.Record_Type__c && this.LABELS.WorkOrderTypeProfessionalServices === this.workOrderObj.SVMXC__Order_Type__c)
            ))
            {
                this.requiredCodes.push(this.LABELS.AssociatedCodeTypeResolution);
            }
    }

    //CMCM-10145 changes starts here ====>
    validateResOnStandaloneWO(){
        // added this.LABELS.WorkOrderTypeBillableInstall === this.workOrderObj.SVMXC__Order_Type__c condition by Dhairya Shah for CMCM-12461
        // added this.LABELS.WorkOrderRecordTypeServiceSupport === this.workOrderObj.Record_Type__c condition by Dhairya Shah for CMCM-12461
        // added this.LABELS.WorkOrderTypeProfessionalServices === this.workOrderObj.SVMXC__Order_Type__c condition by Dhairya Shah for CMCM-12461
        if (this.ivdWorkflow && 
            ((this.LABELS.WorkOrderRecordTypeFieldService === this.workOrderObj.Record_Type__c && 
              (this.LABELS.WorkOrderTypePreventativeMaintenance === this.workOrderObj.SVMXC__Order_Type__c || 
               this.LABELS.WorkOrderTypeInstallation === this.workOrderObj.SVMXC__Order_Type__c || 
               this.LABELS.WorkOrderTypeBillableInstall === this.workOrderObj.SVMXC__Order_Type__c)) || 
             (this.LABELS.WorkOrderRecordTypeServiceSupport === this.workOrderObj.Record_Type__c && 
              this.LABELS.WorkOrderTypeProfessionalServices === this.workOrderObj.SVMXC__Order_Type__c)) && 
            this.workOrderObj.SVMXC__Case__c === undefined && 
            this.workOrderObj.Has_Resolution_Code__c === false) {
            this.requiredCodes.push(this.LABELS.AssociatedCodeTypeResolution);
        }        
    }
    //CMCM-10145 changes ends here ====>

    initialize() {

        this.bIsElevation = (this.caseObj.Record_Type__c === 'Elevation' ? true : false);
        if (this.caseObj.Status === LABELS.CaseStatusCompleted || this.caseObj.Status === LABELS.CaseStatusClosed
            || this.caseObj.Status === 'Closed-Duplicate') 
            this.bLockCodes = true;

        this.showSpinner = false;
    }

    // CMCM - 4207 Changes by Dhairya Shah
    warningTextOnAssociateCodes(){
        if((this.caseObj.Status === LABELS.CaseStatusInitiated || this.caseObj.Status === LABELS.CaseStatusAwaitingResponseCustomer || this.caseObj.Status === LABELS.CaseStatusAwaitingResponseInternal || this.caseObj.Status === LABELS.CaseStatusInProgress) 
            && (this.workOrderObj.SVMXC__Order_Status__c === LABELS.Completed || this.workOrderObj.SVMXC__Order_Status__c === LABELS.Closed || this.workOrderObj.SVMXC__Order_Status__c === LABELS.Canceled || this.workOrderObj.SVMXC__Order_Status__c === LABELS.ReopenRequested ||
                this.workOrderObj.SVMXC__Order_Status__c === LABELS.PendingReviewOrderStatus || this.workOrderObj.SVMXC__Order_Status__c === LABELS.WorkOrderStatusClosedDuplicate)){
            this.warningMessage = true;
        }
    }
    
    handleRowAction(event) {

        if (event.detail.action.name === 'Remove_Record') { 
            let codeLibRec = event.detail.row; 
            this.removeAssociatedCode(codeLibRec.Id);
            if(codeLibRec.Parent_Code_Id !== ''){ 
                let parentCodeId = codeLibRec.Parent_Code_Id.replace("/", "");
                for(let element of this.associatedCodes){ 
                    if (element.Code_Title__c === parentCodeId) {  
                        setTimeout(() => {
                            this.removeAssociatedCode(element.Id);
                        }, 3000); 
                        break;
                    }  
                }; 
            }
        }
        else if(event.detail.action.name==='Add_Record'){
            let codeLibRec = event.detail.row;
            this.addAssociatedCode(codeLibRec);
        }
    }

    //add associated code
    addAssociatedCode(codeLibRec){
        this.showSpinner = true;
        const recordInput = {
            apiName : 'Associated_Codes__c', 
            fields : {
                'Case__c': this.caseObj.Id,
                'Case_Type__c': codeLibRec.Case_Type__c,
                'Work_Order__c': this.workOrderObj.Id,
                'Code_Description__c': codeLibRec.Code_Description__c,
                'Code_Title__c': codeLibRec.Id,
                'Code_Type__c': codeLibRec.Code_Type__c,
                'Parent_Code__c': codeLibRec.Parent_Code__c
            }
        };
        // added if else by Dhairya Shah for CMCM - 5951
        if(this.isHazardPresent === true && codeLibRec.Code_Type__c === 'Hazard'){
            this.showToast('Multiple Hazard Codes cannot be selected. To replace the existing Hazard Code, first remove it, then add the replacement code. If multiple hazards are present, create one case to represent each hazard.', '', 'error', 'dismissable');
            this.showSpinner = false;
        }else{
            createRecord(recordInput)
            .then(result=>{ 
                this.fetchAssociatedCodes(); 
                this.showSpinner = false;
                this.showToast('Associated Code added successfully.', '', 'success', 'dismissable');
            }).catch((error)=>{
                this.showSpinner = false;
                let errorMessage = error.body.output.errors[0].message;// added by Dhairya Shah for CMCM - 4207
                this.showToast(errorMessage, '', 'error', 'dismissable');// added by Dhairya Shah for CMCM - 4207
                //this.showToast('System Error! Please refresh the page.', '', 'error', 'dismissable'); // commented by Dhairya Shah for CMCM - 4207
            });
        }
    }

    //remove disassociated code
    removeAssociatedCode(selAssCodeId) {

        this.showSpinner = true;
        const fields = {
            'Id': selAssCodeId,
            'Code_Title__c': this.disassociatedCodeLib.Id
        };
        updateRecord({ fields })
            .then(() => {
                this.associatedCodes = this.associatedCodes.filter(element => {
                    return element.Id !== selAssCodeId;
                });
                this.showToast('Associated Code removed successfully.', '', 'success', 'dismissable');
                this.refreshFilteredCodeLibrary(true);
                this.isHazardPresent = false; // added by Dhairya Shah for CMCM - 5951
                this.validateCaseAndWorkOrder();
                this.fetchAssociatedCodes();// added by Dhairya Shah for CMCM - 5951
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showSpinner = false;
                let errorMessage = error.body.output.errors[0].message;// added by Dhairya Shah for CMCM - 4207
                this.showToast(errorMessage, '', 'error', 'dismissable');// added by Dhairya Shah for CMCM - 4207
                //this.showToast('System Error! Please refresh the page.', '', 'error', 'dismissable'); // commented by Dhairya Shah for CMCM - 4207   
            });
    }

    refreshFilteredCodeLibrary(callSearchHandler) {

        let nonDisassociatedCodeLib = [];
        let selCodeLibs = [];
        this.associatedCodes.forEach(element => {
            selCodeLibs.push(element.Code_Title__c);
        });
        this.allCodeBLibs.forEach(element => {
            if(!selCodeLibs.includes(element.Id))
                nonDisassociatedCodeLib.push(element);
        });
        this.nonDisassociatedCodeLib = nonDisassociatedCodeLib;
        if(callSearchHandler)
            this.searchHandler();
    }

    searchHandler() {
        this.showSpinner = true;
        this.filteredCodeLibrary = [];
        this.nonDisassociatedCodeLib = this.nonDisassociatedCodeLib.filter((obj, index) => {
            return index === this.nonDisassociatedCodeLib.findIndex(o => obj.Id === o.Id);
        });
        if (this.nonDisassociatedCodeLib.length > 0) {
            if(!this.selectedRadioButton) {
                if(!this.disableSearchButton)
                    this.filterCodeLibraryNoRadioSelected();
            }
            else if(this.selectedRadioButton === 'All') {
                this.filterCodeLibraryAllRadioSelected();
            }
            else if(this.selectedRadioButton !== 'All') {
                this.filterCodeLibraryOtherRadioSelected();
            }
        }
        this.showSpinner = false;
    }

    filterCodeLibraryNoRadioSelected() {
        if(this.searchedCodeName && (this.searchedCodeName !== ''||this.searchedCodeName!==undefined)) {
            this.filteredCodeLibrary = this.nonDisassociatedCodeLib.filter(item => { 
                return (item.Name.toLowerCase().includes(this.searchedCodeName.toLowerCase()) || ( item.Code_ID__c !== undefined &&item.Code_ID__c.toLowerCase().includes(this.searchedCodeName.toLowerCase()) ) ); 
            });
        } else {
            this.filteredCodeLibrary = this.nonDisassociatedCodeLib;
        }
    }

    filterCodeLibraryAllRadioSelected() {
        let userProfile = this.userInfo.profileName;
        if(this.searchedCodeName && this.searchedCodeName !== '') {
            this.filteredCodeLibrary = this.nonDisassociatedCodeLib.filter(item => { 
                if(userProfile !=='Service Logistics'  && userProfile !== 'System Administrator'){
                    return (item.Code_Type__c!== 'Logistics' && ( item.Name.toLowerCase().includes(this.searchedCodeName.toLowerCase()) || ( item.Code_ID__c !== undefined && item.Code_ID__c.toLowerCase().includes(this.searchedCodeName.toLowerCase()) ) )); 
                }
                else{
                    return ( item.Name.toLowerCase().includes(this.searchedCodeName.toLowerCase()) || ( item.Code_ID__c !== undefined && item.Code_ID__c.toLowerCase().includes(this.searchedCodeName.toLowerCase()) ) ); 
                }
            });
        } else {
            this.showToast('Please enter Code Name when searching \'All\' code types', '', 'error', 'dismissable');
        }
    }

    filterCodeLibraryOtherRadioSelected() {
        if(this.searchedCodeName && (this.searchedCodeName !== ''||this.searchedCodeName!==undefined)) {
            this.filterCodeLibraryResolutionCodesForStandAloneWOs();
            this.filteredCodeLibrary = this.filteredCodeLibrary.filter(item => {
                return ((item.Name.toLowerCase().includes(this.searchedCodeName.toLowerCase()) || ( item.Code_ID__c !== undefined && item.Code_ID__c.toLowerCase().includes(this.searchedCodeName.toLowerCase()) )) );
            });
        } else {
            this.filterCodeLibraryResolutionCodesForStandAloneWOs();
        }
    }

    // cmcm-10526, filtering CodeLibrary list for StandAlone WOs and Resolution codes
    filterCodeLibraryResolutionCodesForStandAloneWOs() {
        if (this.objectApiName === 'SVMXC__Service_Order__c' && this.recordTypeName === '' && this.selectedRadioButton === 'Resolution' ) {
            this.filteredCodeLibrary = this.nonDisassociatedCodeLib.filter(item => {
                return (item.Code_Type__c === this.selectedRadioButton && (item.Case_Type__c === 'Service Request' || item.Case_Type__c === undefined));
            });
        } else {
            this.filteredCodeLibrary = this.nonDisassociatedCodeLib.filter(item => {
                return (item.Code_Type__c === this.selectedRadioButton);
            });
        }
    }
    
    radioButtonHandler(event) {

        this.selectedRadioButton = event.target.dataset.id;
        const selectedValue =  event.target.dataset.id;
        this.codeTypePicklistArr = this.codeTypePicklistArr.map(code => {
            if (code.value === selectedValue) {
                code.checked = event.target.checked;
            } else {
                code.checked = false;
            }
            return code;
        });  
        if(this.selectedRadioButton==="Hazard"){
            this.codeLibColumns = CODELIBCOLUMNS;  
        }else{
            this.codeLibColumns = [...this.codeLibColumns].filter(CODELIBCOLUMNS => CODELIBCOLUMNS.label !== 'Parent Code Title');  
        } 
         
    }
    
    handleChange(event) {

        this.searchedCodeName = event.target.value;
    }

    handleEnter(event){
        if(event.keyCode === 13){
            this.searchHandler();
        }
    }

    doCodeLibSorting(event) {

        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection, 'Code Library');
    }

    doAssociatedCodeSorting(event) {

        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection, 'Associated Codes');
    }

    sortData(fieldname, direction,datatype) {

        let parseData;
        if(datatype === 'Code Library')
           parseData = JSON.parse(JSON.stringify(this.filteredCodeLibrary));
        else if(datatype === 'Associated Codes')
           parseData = JSON.parse(JSON.stringify(this.associatedCodes));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            let x1=x;
            let y1=y;
            x1 = keyValue(x1) ? keyValue(x1) : ''; // handling null values
            y1 = keyValue(y1) ? keyValue(y1) : '';
            // sorting values based on direction
            return isReverse * ((x1 > y1) - (y1 > x1));
        });
        if(datatype === 'Code Library')
            this.filteredCodeLibrary = parseData;
        if(datatype === 'Associated Codes')
            this.associatedCodes = parseData;
    }

    //QA user check
    boolQAUserCheck() {
        (this.userInfo.userType === this.LABELS.UserTypeStandard &&
            this.userInfo.profileName === this.LABELS.Profile_Quality_Assurance) ? this.boolQAUser = true : this.boolQAUser = false;
        (this.userInfo.userType === this.LABELS.UserTypeStandard &&
            this.userInfo.profileName === this.LABELS.Profile_Service_Logistics) ? this.boolLogisticsUser = true : this.boolLogisticsUser = false; 
    }

    showToast(title, message, variant, mode) {

        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
}