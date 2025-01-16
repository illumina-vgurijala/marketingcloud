import { LightningElement,track,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import gettemplateID from '@salesforce/apex/AgreementTemplateSelector.selectAgreementTemplatebyName';
import DCIRTemplateName from '@salesforce/label/c.DCIRTemplateName';
import CofDTemplateName from '@salesforce/label/c.CofDTemplateName';
import COFD_Label from '@salesforce/label/c.COFD_Label';
import DCIR_Label from '@salesforce/label/c.DCIR_Label';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USERTYPE_FIELD from '@salesforce/schema/User.UserType';
const FIELDS = ['SVMXC__RMA_Shipment_Order__c.SVMXC__Order_Type__c'];


export default class DcirSummaryComp extends NavigationMixin(LightningElement) {
@api 
recordId;

@track 
isReturnPartsOrder=false;

@track
isportaluser=false;

@api tabSource='';
@track isDcirTab = false;
@track isCofdTab = false;

@track
objectapiname2='SVMXC__RMA_Shipment_Line__c';

//Field to be displayed in UI along with their initial  width
@track
fieldnamestr={"Id":"103","Name":"103","SVMXC__RMA_Shipment_Order__r.Name":"","SVMXC__Product__r.Name":"210","SVMXC__Actual_Quantity2__c":"","Decontamination_Required__c":"80","Is_DCIR_Filled__c":"60"}

//Field to be displayed in UI along with their initial  width
@track
fieldnamestr2={"Id":"110","Name":"110","SVMXC__RMA_Shipment_Order__r.Name":"130","SVMXC__Product__r.Name":"","SVMXC__Actual_Quantity2__c":"120","Decontamination_Required__c":"110","Is_DCIR_Filled__c":"90"}

@track
fieldnamestr3={"Id":"103","Name":"103","SVMXC__RMA_Shipment_Order__r.Name":"","SVMXC__Product__r.Name":"210","SVMXC__Actual_Quantity2__c":"","Item_Destroyed__c":"80","Is_CofD_Filled__c":"60"}

@track
fieldnamestr4={"Id":"110","Name":"110","SVMXC__RMA_Shipment_Order__r.Name":"130","SVMXC__Product__r.Name":"","SVMXC__Actual_Quantity2__c":"120","Item_Destroyed__c":"110","Is_CofD_Filled__c":"90"}

//look up Field to be displayed in UI along with column header 
@track
lookupmap={"SVMXC__RMA_Shipment_Order__r.Name":"Part Number","SVMXC__Product__r.Name":"Product"};

@track
rowactionmap={"Attach DCIR":"attach"};
@track
rowactionmap2={"Attach CofD":"attach"}
@track
inlineedit=false;
@track 
colaction=false;

@track 
whereclause1 ='SVMXC__RMA_Shipment_Order__c=\''+'$recordId'+'\'';
@track
whereclause2 ='SVMXC__RMA_Shipment_Order__c=\''+'$recordId'+'\'';

//columns where button with action need to be shown
@track 
columnactionmap={"Click to attach":"Attach DCIR,138","Generate Adobe DCIR(self)":"Generate Adobe DCIR(self),215"};

@track 
columnactionmap2={"Click to attach":"Attach CofD,138","Generate Adobe CofD(self)":"Generate Adobe CofD(self),215"};

templateId;

@track dcir = DCIR_Label;
@track cofd = COFD_Label;
@track templteName = '';

//method to check the Part Order Type
@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
partsOrderRecord(result){
    console.log('data.fields.SVMXC__Order_Type__c.value..'+JSON.stringify(result));
   if(result.data){
        console.log('here..');
        if(result.data.fields.SVMXC__Order_Type__c.value==='Return'){        
            this.isReturnPartsOrder=true;
        }
        console.log('this.isReturnPartsOrder..'+this.isReturnPartsOrder);
    }else if(result.error){
        console.log('Error:Parts Order'+JSON.stringify(result));
       /* this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error loading Record',
                message: result.error.message,
                variant: 'error',
            }),
        );
        */
    } 
}

@wire(getRecord, { recordId: USER_ID, fields: [USERTYPE_FIELD] })
userrecord(result){
    console.log('result:'+JSON.stringify(result));
    if(result.data){
        console.log('UserType:'+JSON.stringify(result.data));
        if(result.data.fields.UserType.value==='PowerPartner'){  
            this.isportaluser =true;       
            this.columnactionmap={"Click to attach":"Attach DCIR,138"};
            this.columnactionmap2={"Click to attach":"Attach CofD,138"};
        }
    }else if(result.error){
        console.log('Error:'+JSON.stringify(result));
    /* this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error loading Record',
                message: result.error.message,
                variant: 'error',
            }),
        );*/
    }
}



//method call to fetch the template ID
@wire(gettemplateID, { templatename: '$templteName' })
    templatelist(result) {
        
	 if (result.data) {
	 this.templateId=result.data[0].Id;
     }else if(result.error){
        console.log('Error:'+JSON.stringify(result));
      /*  this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error loading Record',
                message: result.error.message,
                variant: 'error',
            }),
        );
      */
    }
}

connectedCallback() {

  //set the where clause needed for the Query
    this.whereclause ='SVMXC__RMA_Shipment_Order__c=\''+this.recordId+'\' and Is_DCIR_Filled__c=false and Decontamination_Required__c=true';
    this.whereclause2 ='SVMXC__RMA_Shipment_Order__c=\''+this.recordId+'\' and Is_DCIR_Filled__c=true and Decontamination_Required__c=true';
    this.whereclause3 ='SVMXC__RMA_Shipment_Order__c=\''+this.recordId+'\' and Is_CofD_Filled__c=false and Item_Destroyed__c=true';
    this.whereclause4 ='SVMXC__RMA_Shipment_Order__c=\''+this.recordId+'\' and Is_CofD_Filled__c=true and Item_Destroyed__c=true';
    if(this.tabSource===DCIR_Label){
        this.isDcirTab = true;
        this.templteName = DCIRTemplateName;
    }
    if(this.tabSource===COFD_Label){
        this.isCofdTab = true;
        this.templteName = CofDTemplateName;
    }
}


//event handler when the  event is fired from the datatable row
handleActionEvent(event){
    //if the event is upload event call the child component method
    if(event.detail.action==='clicktoattachbutton'){
        this.template.querySelector('c-upload-attachement').handleuploadevent(event.detail.rowId);
    }

    //if the event is Generate DCIR from adobe esign event launch the adobe esign Url
    if(event.detail.action==='generateadobedcir(self)button'){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                "url": "/apex/AgreementTemplateProcessRedirect?masterId="+event.detail.rowId+"&templateID="+this.templateId
            },
        }).then(url => {
            window.open(url, 'DCIR Form',"width="+screen.availWidth+",height="+screen.availHeight);
            
        });
        }

    if(event.detail.action==='generateadobecofd(self)button'){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                "url": "/apex/AgreementTemplateProcessRedirect?masterId="+event.detail.rowId+"&templateID="+this.templateId
            },
        }).then(url => {
            window.open(url, 'COFD Form',"width="+screen.availWidth+",height="+screen.availHeight);
            
        });
        }

}


//event fired after file upload is finished and POL is updated with IS_DCIR_Filled=true
refreshtable(event){

    console.log('here..'+event);
   // this in result refreshes both the data table to show the updated data
   this.template.querySelectorAll('c-l-w-c-data-table').forEach(comp => comp.forceRefreshtable());
}
}