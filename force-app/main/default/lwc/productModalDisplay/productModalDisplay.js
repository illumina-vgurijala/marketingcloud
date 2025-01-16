import { LightningElement,track,api } from 'lwc';

export default class productModalDisplay extends LightningElement {
     //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
     @api ismodalopen = false;
     @api picture;
     @track productName;
     connectedCallback(){
        console.log('inside model'+this.picture+' '+this.ismodalopen);
     }
     closeModal() {
         // to close modal set isModalOpen tarck value as false
         this.ismodalopen = false;
         console.log('inside closeModal');
        const selectedEvent = new CustomEvent("closemodal", {
            detail: 'test'
          });
      
          // Dispatches the event.
          this.dispatchEvent(selectedEvent);
     }
     
}