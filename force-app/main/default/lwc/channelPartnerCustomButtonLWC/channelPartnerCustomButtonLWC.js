import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    showSuccessToast,
    showErrorToast,
    callServer,
    consoleError,
    isNotBlank
} from 'c/utils';
import initializeMap from '@salesforce/apex/ChannelPartnerCustomButtonLwcController.initializeMap';
import updateRequestOwnershipFields from '@salesforce/apex/ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields';
export default class ChannelPartnerCustomButtonLWC extends LightningElement {
    /*global Map*/  
    // variable used to get Object name.
    @api selectObject;
    // variable used to get corresponding Case or Work Order Id.
    @api recordId;
    // variable used to control the spinner.
    @track booLoading = false;
    // variable used to store map.
    mapLabels=new Map();

    connectedCallback(){
        this.initializeLabels();
    }

     //Server call to set mapLabels.
     initializeLabels() {
        this.booLoading=true;
        callServer(initializeMap,{},result =>{
                let returnData = JSON.parse(result);
                this.mapLabels=returnData.mapLabels;
                this.booLoading=false;
        }, error => {
                consoleError('error',JSON.stringify(error));
                this.booLoading=false;
        });
    }

    //Server call to initiate request ownership change on corresponding Case/WorkOrder.
    requestOwnershipChange() {
        this.booLoading=true;
        callServer(updateRequestOwnershipFields,{
            recordId:this.recordId,
            objectName:this.selectObject
        },result => {
                if(isNotBlank(result) && result ==='SUCCESS'){
                    showSuccessToast(this.mapLabels.Channel_Partner_Request_Ownership_Success_Msg);
                } else if(isNotBlank(result) && result ==='DENIED'){
                    showErrorToast(this.mapLabels.Channel_Partner_Request_Ownership_Denied);
                } else if (isNotBlank(result) && result ==='RAISED') {
                    showErrorToast(this.mapLabels.Channel_Partner_Request_Ownership_Already_Raised);
                }
                this.booLoading=false;
        }, error => {
                consoleError('error',JSON.stringify(error));
                this.booLoading=false;
        });
    }

}