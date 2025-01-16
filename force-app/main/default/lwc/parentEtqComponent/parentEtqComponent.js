import { api, LightningElement,track,wire } from 'lwc';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import {getRecord} from 'lightning/uiRecordApi';
import {showErrorToast } from 'c/utils';

/**
* @ author       : Abhinav Gupta
* @ date         : 23-Mar-2022
* @ Description  : QACM-14,15 This component is created under QACM-14 and the displays the searched QR records on the search screen 
                    and provides linking functionality or QI records to Case/FAN
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             23-Mar-2022                 Initial version
* Abhinav             15-Apr-2022                 QACM-647 Added Visibility to 'Manual Link' button based on Object i.e. Case or FAN
*/

export default class ParentEtqComponent extends LightningElement {

    @api blnCreateQi = false;
    @api blnSearchQi = false;
    @api blnManualLink = false;
    @api recordId;
    @api objectApiName;
    @track isExtraAccess = false;
    @track linkClickState = false;
    @track tempVar=false;
    @track isCase = false;

    @api prfName;
    userId = strUserId;

    @track isAdminOrQA = false;

    connectedCallback(){
        this.tempVar=true;
        if(this.objectApiName==='Case'){
            this.isCase=true;
        }
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Wired call to fetch user's profile
    */
    @wire(getRecord, {
        recordId: strUserId,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
        this.error = error ; 
        showErrorToast(error.body.message);
        } else if (data) {
            this.prfName =data.fields.Profile.value.fields.Name.value; 
            if(this.prfName === 'System Administrator' || this.prfName === 'Quality Assurance'){
                this.isAdminOrQA = true;
            } 
            else{
                this.isAdminOrQA = false;
            }
        }
    }

    handleCreateQIClick(){
        if(!this.blnCreateQi){
            this.blnCreateQi = true;
        }
    }

    updateCreateQiModalState(event){
        this.blnCreateQi = false;
    }


    handleSearchQIClick(){
        if(!this.blnSearchQi){
            this.blnSearchQi = true;
        }
    }

    updateSearchQiModalState(event){
        this.blnSearchQi = false;
    }

    addManualClicked(){
        if(!this.blnManualLink){
            this.blnManualLink = true;
        }
    }

    updateManualModalState(event){
        this.blnManualLink = false;
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  When the link button is clicked, refresh the existing linked QI records table
    */
    linkClicked(event){
        this.tempVar=false;
        window.clearTimeout(this.delayTimeout);
                this.delayTimeout = setTimeout(() => {
                    this.tempVar=true;
        this.template.querySelector("c-display-existing-qi-records").displayLinkedQI();
                },500);
        
    }

}