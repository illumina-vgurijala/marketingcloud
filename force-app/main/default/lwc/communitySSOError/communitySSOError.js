import { LightningElement, api, track} from 'lwc';
import COMM_SSO_ERROR_ILLUMINA_EMPLOYEE from '@salesforce/label/c.Comm_SSO_Error_Illumina_Employee';
import COMM_SSO_ERROR_GENERIC_EXCEPTION from '@salesforce/label/c.Comm_SSO_Error_Generic_Exception';
import COMM_SSO_ERROR_INACTIVE_USER from '@salesforce/label/c.Comm_SSO_Error_Inactive_User';
import COMM_SSO_ERROR_MULTIPLE_USER_OR_CONTACT from '@salesforce/label/c.Comm_SSO_Error_Multiple_User_Or_Contact';

export default class CommunitySSOError extends LightningElement {
    @api error_message;

    @track label_map;


    label_map = new Map([['Comm_SSO_Error_Illumina_Employee', COMM_SSO_ERROR_ILLUMINA_EMPLOYEE],
                        ['Comm_SSO_Error_Generic_Exception', COMM_SSO_ERROR_GENERIC_EXCEPTION],
                        ['Comm_SSO_Error_Inactive_User', COMM_SSO_ERROR_INACTIVE_USER],
                        ['Comm_SSO_Error_Multiple_User_Or_Contact', COMM_SSO_ERROR_MULTIPLE_USER_OR_CONTACT]]);


    get message() {
        let displayMsg = this.label_map.get(this.error_message);
        if (displayMsg) {
            return displayMsg;
        }

        return this.label_map.get('COMM_SSO_ERROR_GENERIC_EXCEPTION');
    }
}