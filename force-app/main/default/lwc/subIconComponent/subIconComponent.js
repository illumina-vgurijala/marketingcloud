import { LightningElement,api } from 'lwc';

export default class SubIconComponent extends LightningElement {

    @api isvisible;
    @api index;
    
    handleClick(event){
    if(this.isvisible){
        this.isvisible = false;
    }
    else{
        this.isvisible = true;
    }
    let returnString = {
        "index":this.index,
        "selectedValue":this.isvisible
     };
     const sendValues = new CustomEvent('showhide',{ detail : returnString
     });
     this.dispatchEvent(sendValues);
    }

}