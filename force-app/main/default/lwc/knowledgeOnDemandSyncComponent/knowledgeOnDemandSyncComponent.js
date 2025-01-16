import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    consoleLog,
    showSuccessToast,
    showWarningToast,
    callServer,
    isBlank,
    genericEvent
} from 'c/utils';
import {
    NavigationMixin
} from 'lightning/navigation';
import onDemandSync from '@salesforce/apex/KnowledgeOnDemandSyncCmpController.onDemandSync';
export default class KnowledgeOnDemandSyncComponent extends NavigationMixin(LightningElement) {
    @api recordId;
    booLoaded = false;
    connectedCallback(){
        this.booLoaded = false;
        this.syncArticle();
    }
    syncArticle(){
        callServer(onDemandSync,{
            strKnowledgeId : this.recordId
        },result =>{
            consoleLog(result);
            if(isBlank(result)){
                showWarningToast('This article was not found in ICE.');
            }
            else{
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Knowledge__kav',
                        actionName: 'view'
                    },
                });
                showSuccessToast('Article synced with ICE');
            }
            this.booLoaded = true;
        },error =>{
            this.booLoaded = true;
        });
    }
}