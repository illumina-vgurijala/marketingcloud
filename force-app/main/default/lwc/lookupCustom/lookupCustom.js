import { LightningElement, track, api } from 'lwc';
import findRecords from '@salesforce/apex/CustomLookupController.findRecords';
export default class LookupCustom extends LightningElement {
    @track records;
    @track error;
    @api selectedrecord;
    @api index;
    @api relationshipfield;
    @api iconname = 'standard:account';
    @api objectname = 'Account';
    @api searchfield = 'Name';
    @api label;
    @api displayfieldname;
    @api selectedRecordId;

    /*constructor(){
        super();
        this.iconname = "standard:account";
        this.objectname = 'Account';
        this.searchField = 'Name';
    }*/

    handleOnchange(event){
        //event.preventDefault();
        const searchKey = event.detail.value;
        //this.records = null;
        /* eslint-disable no-console */
        //console.log(searchKey);

        /* Call the Salesforce Apex class method to find the Records */
        findRecords({
            searchKey : searchKey, 
            objectName : this.objectname, 
            searchField : this.searchfield
        })
        .then(result => {
            this.records = result;
            console.log('find records ---> '+JSON.stringify(this.records));
            for(let i=0; i < this.records.length; i++){
                const rec = this.records[i];
                this.records[i].Name = rec[this.searchfield];
            }
            this.error = undefined;
            //console.log(' records ', this.records);
            
        })
        .catch(error => {
            this.error = error;
            this.records = undefined;
            console.log('find records error ---> '+JSON.stringify(this.error));
        });
    }
    handleSelect(event){
        this.selectedRecordId = event.detail;
        console.log('selected record id --->'+this.selectedRecordId);
        /* eslint-disable no-console*/
        this.selectedrecord = this.records.find( record => record.Id === this.selectedRecordId);
        /* fire the event with the value of RecordId for the Selected RecordId */
        console.log('Selected record complete--->'+JSON.stringify(this.selectedrecord));
        const selectedRecordEvent = new CustomEvent(
            "selectedrec",
            {
                //detail : selectedRecordId
                detail : { recordId : this.selectedRecordId, index : this.index, relationshipfield : this.relationshipfield}
            }
        );
        this.dispatchEvent(selectedRecordEvent);
    }

    handleRemove(event){
        event.preventDefault();
        this.selectedrecord = undefined;
        this.records = undefined;
        this.error = undefined;
        /* fire the event with the value of undefined for the Selected RecordId */
        const selectedRecordEvent = new CustomEvent(
            "selectedrec",
            {
                detail : { recordId : undefined, index : this.index, relationshipfield : this.relationshipfield}
            }
        );
        this.dispatchEvent(selectedRecordEvent);
    }
    @api
    selectRecordId() {
        return this.selectedrecord;
    }


}