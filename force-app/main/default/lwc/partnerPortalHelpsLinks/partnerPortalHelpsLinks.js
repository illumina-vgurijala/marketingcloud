import { LightningElement,track,wire } from 'lwc';
import getFetchMethod from '@salesforce/apex/DynamicQuickLinksController.fetchMethod';
import { callServer,showErrorToast,showSuccessToast} from 'c/utils';

export default class PartnerPortalHelpsLinks extends LightningElement {
@track button

@wire(getFetchMethod)
 fetchData({data,error})
 {
 if(data)
 {  
    this.button=data;
 }
 else if(error)
 {
    //  this.showToast('Error', error.body.message, 'error');
    showErrorToast(error.body.message);
 }

}
get bool()
{
    if(this.button)
    { return true;
    }
    return false;
}

}