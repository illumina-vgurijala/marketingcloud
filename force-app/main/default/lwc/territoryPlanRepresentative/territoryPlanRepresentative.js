import {
    LightningElement,
    track,
    api
} from 'lwc';
import {
    NavigationMixin
} from 'lightning/navigation';

import {
    callServer,
    consoleLog,
    isEmpty,
    consoleError,
    showSuccessToast
} from 'c/utils';
import UI_Label_Plan_Representative from '@salesforce/label/c.UI_Label_Plan_Representative';
import initRecords from '@salesforce/apex/PlanRepresentativeController.initRecords';
import notifyOverlayUser from '@salesforce/apex/PlanRepresentativeController.notifyOverlayUser';
import {portalColumns, internalColumns} from './column.js';
export default class TerritoryPlanRepresentative extends NavigationMixin(LightningElement) {
    @api recordId;
    label = {
        UI_Label_Plan_Representative
    };
    @track booLoading = false;
    @track column = [];
    @track planRepresentatives = [];
    @track errorMessage = '';
    @track planRepView = true;
    @track removeRepView = true;
    @track buttonLabel;
    @track cardTitle = UI_Label_Plan_Representative;
    @track activeSections = ['PlanRep'];
    @track accordionOpen = false;
    @track mapLabels;
    @track isChannelPartnerProfile = true;      //DCP-39621: to fetch user's profile

    // Method to handle opening of accordian
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        consoleLog(openSections.length);
        if (!this.accordionOpen ) {
            this.fetchData();
            this.accordionOpen = true;
        }
    }

    // Method to fetch data on accordian opening
    fetchData() {
        this.booLoading = true;
        callServer(initRecords, {
            recordId: this.recordId
        }, result => {
            consoleLog('Plan Reps-->', result);
            let returndata = JSON.parse(result);
            this.isChannelPartnerProfile = returndata.channelPartnerProfile;      //DCP-39621 : returned loggedin user profile
            consoleLog('Column-->',internalColumns);
            if(this.isChannelPartnerProfile)
                this.column = portalColumns;
            else
                this.column = internalColumns;
            this.planRepresentatives = returndata.lstUserTerritory2AssociationWrap;
            this.mapLabels = returndata.mapLabels;
            this.errorMessage = this.mapLabels.UI_Error_Message_No_Territory_Plan;
            this.booLoading = false;
            
        }, error => {
            consoleError('Error', error);
            this.booLoading = false;
        });
    }
    // Getter method to display data table or error
    get hasData() {
        return !isEmpty(this.planRepresentatives);
    }
    // event handler for manageUser button
    manageUser() {
        this.planRepView = false;
        this.buttonLabel = this.mapLabels.UI_Label_Add_User;
        this.cardTitle = this.mapLabels.UI_Label_Remove_Representative;
    }
    // Method to reset all flags
    reset() {
        this.cardTitle = this.label.UI_Label_Plan_Representative;
        this.planRepView = true;
        this.removeRepView = true;
        if (isEmpty(this.activeSections))
            this.activeSections.push('PlanRep');
    }
    // handler for child event
    cancel(event) {
        this.planRepresentatives = JSON.parse(event.detail.value);
        this.reset();
    }
    // Method for handling add and remove screen
    switchScreen() {
        if (this.buttonLabel === this.mapLabels.UI_Label_Add_User) {
            this.buttonLabel = this.mapLabels.UI_Label_Remove_User;
            this.cardTitle = this.mapLabels.UI_Label_Add_Representative;
        } else {
            this.buttonLabel = this.mapLabels.UI_Label_Add_User;
            this.cardTitle = this.mapLabels.UI_Label_Remove_Representative;
        }
        this.removeRepView = !this.removeRepView;
    }
    // DCP-40041 : Row action on button click
    handleRowAction(event){
        this.booLoading = true;
        if(event.detail.actionName === 'Notify_User'){//DCP-56402 [CodeScan Issue Fix]
            callServer(notifyOverlayUser, {
                strPlanId : this.recordId,
                strOverlayUserId : event.detail.value.strUserId
            }, result => {
                this.booLoading = false;
                showSuccessToast(this.mapLabels.UI_Message_User_Notify+' '+event.detail.value.strUserName);
            }, error => {
                this.booLoading = false;
            });
        }

    }
}