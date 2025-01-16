import { LightningElement ,api, track} from 'lwc';
import { genericEvent } from 'c/utils';
const ADDRESS_CHANGE_EVENT = 'selectaddress';
export default class AddressCardLWC extends LightningElement {        
    @api cardTitle;    
    @track record;
    selectedRadioValue = '';
    intIndex;
    
    @api 
    get addressRecord() {
        return this.record;
    }
    set addressRecord(value) {
        this.record = JSON.parse(JSON.stringify(value));
        this.selectedRadioValue = this.record.selectedRadioValue;
        this.intIndex = this.record.index;
    }   

    handleChange(event) {
        this.selectedRadioValue = event.detail.value;            
        const objDetails = { 
            addressDetails : {
                strStreet : this.record.strStreet,
                strCity : this.record.strCity,                
                strState : this.record.strState,
                strZip : this.record.strZip
            },
            index : this.intIndex
        };        
        genericEvent(ADDRESS_CHANGE_EVENT,objDetails,this);                
    }

    get options() {            
        return [
            { value: 'option1', label : null}];
    }
}