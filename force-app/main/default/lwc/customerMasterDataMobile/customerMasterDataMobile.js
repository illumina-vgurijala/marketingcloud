import { LightningElement, api, track } from 'lwc';
import erpCustomerIdLabel from '@salesforce/label/c.UI_Label_Erp_Customer_Id';
import streetLabel from '@salesforce/label/c.UI_Label_Street';
import defaultPartnerLabel from '@salesforce/label/c.UI_Label_Default_Partner';
import careOfLabel from '@salesforce/label/c.UI_Label_Care_Of';
import cityLabel from '@salesforce/label/c.UI_Label_City';
import postalLabel from '@salesforce/label/c.UI_Label_Zip_Postal';
import stateLabel from '@salesforce/label/c.UI_Label_State_Province';
import countryLabel from '@salesforce/label/c.UI_Label_Country';
import relationshipLabel from '@salesforce/label/c.UI_Label_Relationship';
import accountGroupLabel from '@salesforce/label/c.UI_Label_Account_Group';



export default class CustomerMasterDataMobile extends LightningElement {
    @api identifier;
    @api boolstempty;
    @api lstdata;
    @api booPageGr1;
    @api booIsFirstPage;
    @api booIsLastPage;
    @api intPageNumber;
    @api intPageTotal;
    @api mapLabels;
    @api booIsBillTo;

    @track erpCustomerId = erpCustomerIdLabel;
    @track street = streetLabel;
    @track defaultPartner = defaultPartnerLabel;
    @track careOf = careOfLabel;
    @track city = cityLabel;
    @track postal = postalLabel;
    @track state = stateLabel;
    @track country = countryLabel;
    @track relationship = relationshipLabel;
    @track accountGroup = accountGroupLabel;

    @track booIsDirect;




    connectedCallback(){
        this.booIsDirect = this.checkDirect();
    }

    checkDirect(){
        if(this.identifier === 'direct') {
            return true;
        }
        else {
            return false;
        }
    }


    setvisibility(event) {
        let returnString = {
            "index":event.detail.index,
            "selectedValue":event.detail.selectedValue
        };
        const sendValues = new CustomEvent('setvisibility',{ detail : returnString
        });
        this.dispatchEvent(sendValues);
    }

    handleSelection(event) {
        let returnString = {
            "id":event.target.id
        };
        const sendValues = new CustomEvent('selection',{ detail : returnString
        });
        this.dispatchEvent(sendValues);
    }

    prevPage() {
        const sendValues = new CustomEvent('prevpage',{});
        this.dispatchEvent(sendValues);
    }

    nextPage() {
        const sendValues = new CustomEvent('nextpage',{});
        this.dispatchEvent(sendValues);
    }

}