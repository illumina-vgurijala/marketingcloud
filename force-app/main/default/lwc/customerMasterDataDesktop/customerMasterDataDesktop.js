import { LightningElement, api, track } from 'lwc';
import { isNotEmpty} from 'c/utils';


export default class CustomerMasterDataDesktop extends LightningElement {
    @api boolstempty;
    @api columns;
    @api lstdata;
    @api keyField;
    @api sortBy;
    @api sortDirection;
    @api identifier;
    @api booPageGr1;
    @api booIsFirstPage;
    @api booIsLastPage;
    @api intPageNumber;
    @api intPageTotal;
    @api mapLabels;
    @api booIsBillTo;
    @api searchButtonLabel;
    @api saveButtonLabel;

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

    handleSortdata(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        let returnString = {
            "fieldName":this.sortBy,
            "sortDirection":this.sortDirection
        };
        const sendValues = new CustomEvent('sortdata',{ detail : returnString
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

    getSelectedRow(event) {
        if(isNotEmpty(event.detail.selectedRows)) {
            let returnString = {
                "selectedRows":event.detail.selectedRows
            };
            const sendValues = new CustomEvent('rowselection',{ detail : returnString
            });
            this.dispatchEvent(sendValues);
        }
        
        
    }

}