import { LightningElement, track, api } from 'lwc';

export default class SearchComponent extends LightningElement {
    
    @track searchKey;
    @api label;
    @api displayfieldname;
    
    handleChange(event){
        /* eslint-disable no-console */
        //console.log('Search Event Started ');
        const searchKey = event.target.value;
        /* eslint-disable no-console */
        event.preventDefault();
        const searchEvent = new CustomEvent(
            'change', 
            { 
                detail : searchKey
            }
        );
        this.dispatchEvent(searchEvent);
    }
}