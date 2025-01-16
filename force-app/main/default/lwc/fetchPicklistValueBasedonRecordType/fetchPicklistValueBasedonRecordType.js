import { LightningElement, api , wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { consoleLog , consoleError } from 'c/utils';
export default class FetchPicklistValueBasedonRecordType extends LightningElement {
    @api recordTypeId;
    @api fieldAPI;
    // Wire adapter to fetch all picklist value
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: '$fieldAPI'
    })
    picklistValues({
        data,
        error
    }) {
        if (data) {
            consoleLog('Result: ', data)
            const picklistFetch = new CustomEvent(
                'recordtypepicklistvaluefetched', {
                    detail: {
                        picklist: JSON.stringify(data.values),
                        recordTypeId: this.recordTypeId,
                        fieldAPI: this.fieldAPI
                    }
                }
            );
            this.dispatchEvent(picklistFetch);
        } else if (error) {
            consoleError('Error: ', error.body.message);
            const throwError = new CustomEvent(
                'recordtypepicklistvalueerror', {
                    detail: {
                        error: JSON.stringify(error),
                        recordTypeId: this.recordTypeId,
                        fieldAPI: this.fieldAPI
                    }
                }
            );
            this.dispatchEvent(throwError);
        }
    }
}