import { LightningElement, track, api } from 'lwc';
import createVoteRecord from '@salesforce/apex/KAFeedbackController.createVoteRecord';
import fetchDetails from '@salesforce/apex/KAFeedbackController.fetchDetails';
import Id from '@salesforce/user/Id';
import { createRecord } from 'lightning/uiRecordApi';
import FEEDBACK_OBJECT from '@salesforce/schema/Feedback__c';
import FEEDBACK_REASON from '@salesforce/schema/Feedback__c.Feedback_Reason__c';
import FEEDBACK_DESCRIPTION from '@salesforce/schema/Feedback__c.Feedback_Description__c';
import FEEDBACK_STATUS from '@salesforce/schema/Feedback__c.Feedback_Status__c';
import FEEDBACK_DISPOSITION from '@salesforce/schema/Feedback__c.Feedback_Disposition__c';
import KNOWLEDGE_ARTICLE_LINK from '@salesforce/schema/Feedback__c.Knowledge_Article_Link__c';

import {
    callServer,
    consoleLog,
    isBlank
} from 'c/utils';
 
const POSITIVE_VOTE_TYPE = '5';
const NEGATIVE_VOTE_TYPE = '1';
const TEXTAREA_LIMIT = 32768;
const INSUFFICIENT_ACCESS_ERROR ='INSUFFICIENT_ACCESS';
const SUCCESS_CLASS = 'slds-text-body_small slds-text-color_success slds-m-left_small slds-text-align--center';
const ERROR_CLASS = 'slds-text-body_small slds-text-color_error slds-m-left_small slds-text-align--center';
const FEED_REASON = 'FeedReason';

export default class KnowledgeFeedbackComponent extends LightningElement {
    @api recordId;
    @track booLoading = true;
    showMessage = false;
    showFeedbackForm = false;
    boolAdditional = false;
    userId = Id;
    likeState = false;
    disLikeState = false;
    @track showUploadedFile = false;
    @track showUploadError = false;
    fileName = '';
    likecount = 0;
    dislikecount = 0;
    feedBackOptions = [];
    isVotedPositive = false;
    boolHasVoted = false;
    idVotedRecord = '';
    message = '';
    feedbackReason = '';
    description = '';
    successMessage;
    feedbackRecId;
    reasonMissingMessage;
    showFileUploadOption;

    connectedCallback() {
        this.initializeDetails();
    }
    get activeState() {
        return this.boolHasVoted && this.isVotedPositive;
    }
    get reverseActiveState() {
        return this.boolHasVoted && !this.isVotedPositive;
    }
    initializeDetails() {
        this.booLoading = true;
        callServer(fetchDetails, {
            kaId: this.recordId
        }, result => {
            let returnData = JSON.parse(result);
            this.knowledgeObject = returnData.knowledgeRecord;
            this.mapLabels = returnData.mapLabels;
            returnData.feedbackReasonValues.forEach((element) => {
                this.feedBackOptions.push({
                    label: element.label,
                    value: element.value
                });
            });
            returnData.listVotes.forEach((element) => {
                if (element.CreatedById === this.userId) {
                    this.boolHasVoted = true;
                    this.idVotedRecord = element.Id;
                    this.isVotedPositive = element.Type === POSITIVE_VOTE_TYPE;
                }
                if (element.Type === POSITIVE_VOTE_TYPE) {
                    this.likecount = this.likecount + 1;
                }
                if (element.Type === NEGATIVE_VOTE_TYPE) {
                    this.dislikecount = this.dislikecount + 1;
                }
            });
            this.reasonMissingMessage = this.mapLabels.UI_Message_Reason_Required;
            this.booLoading = false;
        }, error => {
            this.booLoading = false;
        });
    }
    // Method to handle additional Feedback
    handleAdditionalFeedback(event) {
        this.showMessage = false;
        this.message = '';
        this.boolAdditional = event.target.name === this.mapLabels.UI_Text_Additional_Feedback;
        this.showFeedbackForm = true;
        this.feedbackRecId = undefined;
    }
    // Vote click handler
    submitVote(event) {
        let isLikeClicked = event.target.name === 'LIKE';
        if (this.boolHasVoted) {
            if ((this.isVotedPositive && !isLikeClicked) || !this.isVotedPositive && isLikeClicked) {
                this.submitVoteCountEdit(isLikeClicked, this.idVotedRecord);
            }
        }
        else {
            this.submitVoteCountNew(isLikeClicked, this.knowledgeObject.KnowledgeArticleId);
        }
    }
    submitVoteCountEdit(isLikeClicked, voteId) {
        this.submitVoteCount(isLikeClicked, '', voteId);
    }
    submitVoteCountNew(isLikeClicked, parentId) {
        this.submitVoteCount(isLikeClicked, parentId);
    }
    submitVoteCount(voteType, parentId, voteId) {
        this.resetData();
        this.booLoading = true;
        callServer(createVoteRecord, {
            strVoteType: voteType ? POSITIVE_VOTE_TYPE : NEGATIVE_VOTE_TYPE,
            strKnowledgeArticleId: parentId,
            strVoteId: voteId
        },
        result => {
            if (this.boolHasVoted) {
                if (voteType && this.dislikecount > 0)
                    this.dislikecount--;
                if (!voteType && this.likecount > 0)
                    this.likecount--;
            }
            if (voteType) this.likecount++;
            if (!voteType) {
                this.dislikecount++;
                this.showFeedbackForm = true;
            }
            this.isVotedPositive = voteType;
            this.boolHasVoted = true;
            this.idVotedRecord = result.Id;
            this.booLoading = false;
        },
        error => {
            this.booLoading = false;
            this.errorMessageDisplay(error);
        });
    }
    // Form logic
    // On field change
    resetData() {
        this.showFeedbackForm = false;
        this.feedbackReason = '';
        this.description = '';
        this.boolAdditional = false;
        this.fileName = '';
        this.showUploadError = false;
        this.showUploadedFile = false;
        this.showMessage = false;
        this.feedbackRecId = undefined;
    }

    errorMessageDisplay(error){
        console.log('errorMessageDisplay:  '+JSON.stringify(error));
        let errorFromServer = 'Unknown error';
        if (Array.isArray(error.body)) {
            errorFromServer = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            errorFromServer = error.body.message;
        }
        if(errorFromServer.includes(INSUFFICIENT_ACCESS_ERROR) || error.body.errorCode === INSUFFICIENT_ACCESS_ERROR ){
            errorFromServer = this.mapLabels.UI_Message_Feedback_Insufficient_Access_Error;
        }
        this.showMessage = true;
        this.successMessage = false;
        this.message = errorFromServer;
    }

    formFieldChange(event) {
        if (event.target.name == FEED_REASON) {
            this.feedbackReason = event.target.value;
        }
        if (event.target.name == this.mapLabels.UI_Text_Feedback_Description) {
            this.description = event.detail.value;
        }
    }
    saveFeedback() {
        if (isBlank(this.feedbackReason)) {
            this.template
                .querySelector(".reason")
                .showHelpMessageIfInvalid();
        }
        //Defect - 45084
        else if (this.description.length > TEXTAREA_LIMIT) {
            this.showMessage = true;
            this.successMessage = false;
            this.message = this.mapLabels.UI_Message_Feedback_Description_Length_Error;
        }
        //End of Defect - 45084
        else {
            this.booLoading = true;
            const FIELDS = {};
            FIELDS[FEEDBACK_REASON.fieldApiName] = this.feedbackReason;
            FIELDS[FEEDBACK_DESCRIPTION.fieldApiName] = this.description;
            FIELDS[FEEDBACK_STATUS.fieldApiName] = this.mapLabels.UI_Text_Feedback_Status_Open;
            FIELDS[FEEDBACK_DISPOSITION.fieldApiName] = this.mapLabels.UI_Text_Feedback_Disposition_New;
            FIELDS[KNOWLEDGE_ARTICLE_LINK.fieldApiName] = this.recordId;

            const feedbackRecord = { apiName: FEEDBACK_OBJECT.objectApiName, fields: FIELDS };
            createRecord(feedbackRecord)
                .then(result => {
                    this.resetData();
                    this.showMessage = true;
                    this.successMessage = true;
                    this.message = this.mapLabels.UI_Message_Feedback_Submitted;
                    this.showFeedbackForm = true;
                    this.booLoading = false;
                    this.feedbackRecId = result.id;
                    this.showFileUploadOption = true;
                })
                .catch(error => {
                    this.booLoading = false;
                    this.showFeedbackForm = false;
                    this.errorMessageDisplay(error);
                    this.feedbackRecId = undefined;
                });
        }
    }
    get feedbackDescription() {
        if (this.boolAdditional)
            return this.mapLabels.UI_Text_Additional_Feedback;
        else
            return this.mapLabels.UI_Text_Feedback_Description;
    }
    get reasonOption() {
        if (this.boolHasVoted && !this.isVotedPositive) {
            return this.feedBackOptions.filter(function (element) {
                return element.value;
            });
        }
        if (this.boolHasVoted && this.isVotedPositive) {
            return this.feedBackOptions.filter(function (element) {
                return element.value == 'Other';
            });
        }
        else
            return this.feedBackOptions;
    }
    // File upload handling
    onFileUpload(event) {
        this.fileName = this.mapLabels.UI_Message_File_Attached ;
        const uploadedFiles = event.detail.files;
        let filesCount = uploadedFiles.length;
        if(filesCount > 0){
            uploadedFiles.forEach((element) => {
                this.fileName += element.name + ' ,';
            });
            this.showUploadedFile = true;
            this.showSucessMessage = true;
            this.showFileUploadOption = false;
        }
    }
    get messageClass(){
        return (this.successMessage ? SUCCESS_CLASS : ERROR_CLASS);
    }
}