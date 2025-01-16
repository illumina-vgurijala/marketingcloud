import {
    LightningElement,
    track,
    api
} from 'lwc';
import {
    NavigationMixin
} from 'lightning/navigation';
import {
    consoleLog,
    showErrorToast,
    showSuccessToast,
    isBlank,
    isNotNull,
    callServer,
    genericEvent
} from 'c/utils';
import {
    loadSharedData,
    createChannelPartnerOptionListHelper,
    getYearOptions,
    territorySelectHelper,
    yearSelectHelper,
    validateInputHelper
} from 'c/planCreationHelper'
import loadPage from '@salesforce/apex/PlanCreationController.loadPage';
import FORM_FACTOR from '@salesforce/client/formFactor';
const STRING_SEPARATOR = "|";
export default class PlanCreation extends NavigationMixin(LightningElement) {
    @api currentUserId;
    @track territoryName;
    @track territoryId;
    @track territoryCode;
    @api territoryRecordTypeId;
    @track createView = false;
    @track selectionView = false;
    @track objectApiName = 'Plan__c';
    @track territoryOptions = [];
    @track pageLayoutSection;
    @track pageLayout;
    @track checkPageLoaded = false;
    @track activeSections = [];
    @track booLoading = true;
    @track pathStages = [];
    @track lastStage;
    @track modalHeader;
    @track mapUILabels = [];
    @track idOverlayRecordTypeId;
    @track startDate = new Date();
    @track endDate = new Date();
    @track year;
    @track territorySelectView = false;
    @track roleSelectView = false;
    @track yearSelectView = false;
    @track overlayRole;
    @track roleOptions = [];
    @track isOverLayPlan = false;
    @track idRecordTypeId; //DCP-39621 : to fetch recordTypeId
    // DCP-39735
    @track idChannelPartner;
    @track isCommunity = false;
    @track isIndirectRecord = false;
    @track channelPartnerSelectView = false;
    @track channelPartnerOption = [];
    @track mapAccountWrapper = [];
    @track hasSingleTerritory = false;
    @track channelPartnerCode;
    @track territoryRegion;
    // DCP-40495
    @track planTarget;
    // DCP-40495
    @track mapAccountToMapYearQuota = {};
    @track channelPartnerValue;
    // Sprint 2 feedback DCP-41767
    @track planNameAutomated;
    @track channelPartnerName;
    @track isMobile = false;
    setIgnoredSection = ['System Information','Plan Metrices','Territory Snapshot','Channel Partner Territory Snapshot'];
    connectedCallback() {
        if(FORM_FACTOR == 'Small')
            this.isMobile = true;
        consoleLog('Record type -->', this.territoryRecordTypeId);
        // DCP-39735
        this.loadRecords();
    }
    loadRecords() {
        this.pathStages = [];
        this.territoryOptions = [];
        let argument = {
            userRecordIdLocal: this.currentUserId,
            recordTypeID: this.territoryRecordTypeId
        }
        loadSharedData(this, argument, 'New');
    }
    // DCP-39735
    // Create option list for channel partner
    createChannelPartnerOptionList() {
        createChannelPartnerOptionListHelper(this);
    }
    // DCP-39735
    // Handle on channel partner selection
    channelPartnerSelect(event) {
        let split = event.target.value.split(STRING_SEPARATOR);
        this.idChannelPartner = split[0];
        this.channelPartnerCode = split[1];
        this.channelPartnerName = split[2];
    }
    loadLayout() {
        callServer(loadPage, {
            recordTypeID: this.territoryRecordTypeId
        }, result => {
            this.pageLayout = JSON.parse(result);
            let pagelayoutMeta = JSON.parse(result);
            pagelayoutMeta = pagelayoutMeta.Sections;
            pagelayoutMeta.forEach((element, index, array) => {
                element.Columns.forEach((element1) => {
                    element1.Fields.forEach((element2, index2, array2) => {
                        if (element2.Behavior == 'Required')
                            array2[index2]['isRequired'] = true;
                        else
                            array2[index2]['isRequired'] = false;
                        if (element2.Behavior == 'Readonly')
                            array2[index2]['isReadOnly'] = true;
                        else
                            array2[index2]['isReadOnly'] = false;
                        if (element2.APIName == 'Territory_Name__c')
                            array2[index2]['defaultValue'] = this.territoryName;
                        if (element2.APIName == 'End_Date__c')
                            array2[index2]['defaultValue'] = this.endDate;
                        if (element2.APIName == 'Start_Date__c')
                            array2[index2]['defaultValue'] = this.startDate;
                        if (element2.APIName == 'Overlay_Role__c')
                            array2[index2]['defaultValue'] = this.overlayRole;
                        // DCP-40495
                        if (element2.APIName == 'Plan_Target__c' && isNotNull(this.planTarget))
                            array2[index2]['defaultValue'] = parseFloat(this.planTarget);
                        // DCP-39735
                        if (element2.APIName == 'Channel_Partner__c' && this.isIndirectRecord)
                            array2[index2]['defaultValue'] = this.idChannelPartner;
                        // DCP-41767
                        if (element2.APIName == 'Name')
                            array2[index2]['defaultValue'] = this.planNameAutomated;
                    })
                })
                if(this.setIgnoredSection.includes(element.Label))
                    array[index]['isSystemColumn'] = true;
                else {
                    array[index]['isSystemColumn'] = false;
                    this.activeSections.push(element.Label);
                }
            })
            consoleLog('Updated JSON', JSON.stringify(pagelayoutMeta));
            this.pageLayoutSection = pagelayoutMeta;
            this.createView = true;
            this.booLoading = false;
        }, error => {
            this.booLoading = false;
        });
    }
    nextScreen(event) {
        if (!validateInputHelper(this)) {
            consoleLog('Inside next');
            this.booLoading = true;
            this.selectionView = false;
            if (!this.isOverLayPlan){
                this.lastStage = this.mapUILabels.UI_Label_Select_Territory;
                // DCP-41767
                this.planNameAutomated = this.isIndirectRecord ? this.year +' '+this.channelPartnerName+' Plan' : this.year +' '+this.territoryName+' Plan';
            }
            else
                this.lastStage = this.mapUILabels.UI_Label_Select_Role;
            // DCP-40495
            if (this.isIndirectRecord && Object.keys(this.mapAccountToMapYearQuota).length > 0) {
                this.fetchPlanTarget();
            }
            this.loadLayout();
        }
    }
    // DCP-40495
    fetchPlanTarget() {

        if (isNotNull(this.mapAccountToMapYearQuota[this.idChannelPartner]))
            this.planTarget = this.isCommunity ? this.mapAccountToMapYearQuota[this.idChannelPartner].mapAccountIdToFYQuota[this.year] :  this.mapAccountToMapYearQuota[this.idChannelPartner][this.year];
    }
    territorySelect(event) {
        territorySelectHelper(event, this);
    }
    closeModal() {
        this.createView = false;
        this.selectionView = false;
        this.booLoading = false;
        if (isBlank(this.territoryRecordId)) {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Plan__c',
                    actionName: 'list'
                },
                state: {
                    filterName: 'Recent'
                },
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.territoryRecordId,
                    objectApiName: 'Plan__c',
                    actionName: 'view'
                },
            });
        }
        this.territoryRecordId = '';
        const objDetails = Object.create({});
        objDetails.endIndex = this.endIndex;
        genericEvent('closemodal', objDetails, this);
    }
    handleError(event) {
        if (event.detail.message)
            showErrorToast(event.detail.message);
        this.booLoading = false;
    }
    handleSubmit(event) {
        this.booLoading = true;
        const fields = event.detail.fields;
        if (!this.isOverLayPlan) {
            fields.Territory_Id__c = this.territoryId;
            fields.Territory_Code__c = this.territoryCode;
            fields.Territory_Region__c = this.territoryRegion;
            if (this.isIndirectRecord) {
                fields.Channel_Partner_Territory_Code__c = this.channelPartnerCode;
            }
        }
        fields.RecordTypeId = this.idRecordTypeId; //DCP-39621 : assigning recordTypeId
        fields.Overlay_Role__c = this.overlayRole;
        consoleLog('Fields--', fields);
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    handleSuccess(event) {
        this.territoryRecordId = event.detail.id;
        showSuccessToast(this.mapUILabels.UI_Message_Plan_Created);
        this.closeModal();
        this.booLoading = false;
    }
    //DCP-39791
    //To select year of Start Date and End Date on Plan object
    get yearOptions() {
        return getYearOptions();

    }
    //DCP-39791
    //To default value of Start Date and End Date with selected year on Plan object
    yearSelect(event) {
        yearSelectHelper(event, this);
    }

    //DCP-39736
    //To default value of Overlay Role on Plan object
    roleSelect(event) {

        this.overlayRole = event.target.value;
    }
}