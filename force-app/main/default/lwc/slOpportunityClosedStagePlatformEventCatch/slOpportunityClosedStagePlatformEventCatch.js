import { LightningElement, api } from 'lwc';
import { subscribe, onError} from "lightning/empApi";
import { consoleLog, consoleError } from 'c/utils';
import closedAbandonedLabel from '@salesforce/label/c.OpportunityStageClosedAbandoned';
import closedLostLabel from '@salesforce/label/c.OpportunityStageClosedLost';
import userId from '@salesforce/user/Id';
import { loadScript } from "lightning/platformResourceLoader";
import cometdLib from '@salesforce/resourceUrl/CometD';
import jQueryLib from '@salesforce/resourceUrl/jquery';
import fetchSessionId from '@salesforce/apex/PartnerHelpRequestController.fetchSessionId';

const OPPORTUNITY_DATA = 'oppData';

export default class SlOpportunityClosedStagePlatformEventCatch extends LightningElement {
    @api recordId; // Automatically populated when the component is on a record page
    @api usesCommetD = false; // If true, uses the CometD library to listen for the Opportunity_Field_Updates__e platform event. if false, uses the empApi library
    cometd;
    sessionId;
    lastReplayId = -1;

    connectedCallback() {
        console.log('Record ID from @api:', this.recordId);
        if(this.usesCommetD)
            this.commetDSetup();
        else
            this.empApiSetup();
    }

    renderedCallback() {
        if(this.usesCommetD)
            this.shouldOpenClosedModal();
    }

    /**
     * @description Setup for empApi subscriber and error handler.
     */
    empApiSetup = () => {
        this.handleSubscribe();
        this.registerErrorListener();
    }

    /**
     * @description Setup for CometD library.
     */
    commetDSetup = () => {
        fetchSessionId()
        .then(result=>{
            this.sessionId = result;
            consoleLog("*** data sessionId: " , this.sessionId);
            this.initializeCometd();
        })
        .catch(error=>{
            consoleError('Unable to get sessionId', error);
            this.sessionId = undefined;
        });
    }

    /**
     * @description Handles the empApi subscribe call.
     */
    handleSubscribe() {

        subscribe('/event/Opportunity_Field_Updates__e', -1, this.onPlatformResponse)
            .then((response) => {
            consoleLog( 'Subscription request sent to: ', JSON.stringify(response.channel));
            consoleLog("*** Response: " + JSON.stringify(response, null, 4));
        });
    }

    /**
     * @description Registers error handler for empApi.
     */
    registerErrorListener() {
        onError((error) => {
            consoleError('Received error from server: ', JSON.stringify(error));
        });
    }

    /**
     * @description Loads the CometD library and initializes the CometD connection.
     */
    initializeCometd() {
        Promise.all([loadScript(this, jQueryLib), loadScript(this, cometdLib)])
            .then(() => {
                this.initializeCometdConnection();
            })
            .catch((error) => {
                consoleError('Error loading CometD: ', error);
            });
    }

    /**
     * @description Initializes CometD connection.
     */
    initializeCometdConnection() {
        this.cometd = new window.org.cometd.CometD();

        this.cometd.configure({
            url: `${window.location.protocol}//${window.location.host}/cometd/54.0/`,
            requestHeaders: {
                Authorization: `OAuth ${this.sessionId}`,
            },
            appendMessageTypeToURL: false,
        });

        this.cometd.websocketEnabled = false;

        this.cometd.handshake((handshake) => {
            if (handshake.successful) {
                console.log('CometD handshake successful');
                this.subscribeToPlatformEvents();
                
            } else {
                console.error('CometD handshake failed: ', handshake);
            }
        });
    }

    subscribeToPlatformEvents() {
        const channel = '/event/Opportunity_Field_Updates__e'; // Replace with your Platform Event's API name
        this.cometd.subscribe(channel, (message) => {
            // Call the child component's method and pass the recordId
            this.onPlatformResponse(message);
        });
    }

    /**
     * @description Receives the event payload from the Platform Event and passes it to the child component. 
     * On usesCommetD will save session storage opportunity data BUT community site refresh all components and the modal will open in renderedCallback()
     * On !usesCommetD will open the closed modal right away
     * @param {*} response Platform Event Data
     */
    onPlatformResponse = (response) =>{
        const replayId = response.data.event.replayId;
         // Prevent duplicate processing
        if (this.lastReplayId >= replayId) {
            console.log(`Duplicate event ignored. Current: ${this.lastReplayId}, Received: ${replayId}`);
            return;
        }
        // Update last processed replayId
        this.lastReplayId = replayId;
        const lastModUserId = response.data.payload.CreatedById__c+'';

        consoleLog("*** data CreatedById__c: " + lastModUserId);
        consoleLog("*** data userId: " + userId.substring(0, 15));           
        consoleLog("*** data recordId ->>: " + this.recordId);
        consoleLog("*** data Opportunity_Id__c: " + response.data.payload.Opportunity_Id__c);
        consoleLog("*** data recordId val----> : " + (this.recordId === response.data.payload.Opportunity_Id__c));
        consoleLog("*** data check val----> : " + (lastModUserId === userId.substring(0, 15)));

        let closedOpportunityData = {};
        if((response.data.payload.Updated_Values__c === closedLostLabel || response.data.payload.Updated_Values__c === closedAbandonedLabel) 
            && (lastModUserId === userId.substring(0, 15)) && (this.recordId === response.data.payload.Opportunity_Id__c))
        {                
            closedOpportunityData.stagevalue = response.data.payload.Updated_Values__c;
            closedOpportunityData.recordId = response.data.payload.Opportunity_Id__c;
            consoleLog("*** data objCloseData: " + closedOpportunityData); 

            if(this.usesCommetD)
                this.setFlagIsOpen(closedOpportunityData);
            else
                this.openClosedModal(closedOpportunityData);
        }
    }

    /**
     * @description Disconnects from CometD
     */
    disconnectedCallback() {
        if (this.cometd) {
            this.cometd.disconnect();
        }
    }

    /**
     * @description Opens modal Opportunity Closed Stage Edit Form. ONLY if it has session object. TODO: remove when Aura framework is replaced on Community Sites
     */
    shouldOpenClosedModal = ()=> {
        const stringOpp = sessionStorage.getItem(OPPORTUNITY_DATA);

        if(!stringOpp) return;// skip open modal

        let objCloseData = JSON.parse(stringOpp);

        this.openClosedModal(objCloseData);
    }

    /**
     * @description Opens modal Opportunity Closed Stage Edit Form.
     * @param {*} objCloseData opportunity data
     */
    openClosedModal = (objCloseData)=> {
        const child = this.template.querySelector('c-sl-opportunity-closed-stage-edit-form');
        if (child) {
            consoleLog(`*** data objCloseData ${JSON.stringify(objCloseData)} userId: + ${userId}`);
            child.openPopup(objCloseData); // Pass the recordId to the child
        }
    }

    /**
     * @description Saves ObjCloseData into a session variable. That would be used to open the modal after refresh.
     * @param {*} objCloseData 
     */
    setFlagIsOpen(objCloseData) {
        let stringObjectCloseData = JSON.stringify(objCloseData);
        sessionStorage.setItem(OPPORTUNITY_DATA, stringObjectCloseData);
    }

    /**
     * @description On success edit-form remove the session variable.
     */
    onSuccess() {
        sessionStorage.removeItem(OPPORTUNITY_DATA);
    }
}