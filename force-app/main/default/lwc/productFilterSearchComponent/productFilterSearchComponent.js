import { LightningElement,api,wire } from 'lwc';

export default class ProductFilterSearchComponent extends LightningElement {
    @api recordId
    values = ['option4']
    searchKey = '';
    
    get options(){
        return [
            {label: 'By Installed Products', value: 'option1' },
            {label: 'By Products', value: 'option2' },
            {label: 'By Subscriptions', value: 'option3'},
            {label: 'By Account', value: 'option4'}
        ];
    }
   
    handleSearchKeyChange(event) {
        const sKey = event.detail.value;

        //if (sKey.length >=3){
            this.searchKey = sKey
            
            const event1 = new CustomEvent('filterschange', { detail: { searchKey: this.searchKey ,values: this.values.join(',')} })
            this.dispatchEvent(event1)

        //}
        
    }

    handleChange(event) {
        this.values = event.detail.value;
        //if (this.searchKey.length >=3){
            
            const event2 = new CustomEvent('filterschange', { detail: { searchKey: this.searchKey ,values: this.values.join(',')} })
            this.dispatchEvent(event2)
       // }
    
    }
}