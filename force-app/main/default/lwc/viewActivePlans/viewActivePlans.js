import { LightningElement, track, api, wire } from 'lwc';
import initRecords from '@salesforce/apex/ViewActivePlansController.initRecords';
import { refreshApex } from '@salesforce/apex';

export default class ViewActivePlans extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api fieldNames;
    @track showtable = true;
    @track data;
    @track columns;
    @track lstOfRecord;
    wiredsObjectData;
    @wire(initRecords, {
        ObjectName: '$objectApiName',
        fieldNames: '$fieldNames',
        recordId: '$recordId'
    }
    )
    wiredSobjects (result) {
        this.wiredsObjectData = result;
        if (result.data) {
            this.data = result.data.lstSob;
            // eslint-disable-next-line no-console
            console.log('data-->'+JSON.stringify(this.data));
            // eslint-disable-next-line no-console
            console.log('data lebgth-->'+JSON.stringify(this.data.length));
            if(this.data.length >0){
                this.showtable = true;
            
            let lstOfTempRecord = [];
            this.data.forEach((con) => {
                lstOfTempRecord.push(this.flatten(con));
            });
            this.lstOfRecord = lstOfTempRecord;
            this.columns = result.data.lstLabelDescription;
            refreshApex(this.wiredSobjects);
            // eslint-disable-next-line no-console
            console.log('this.columns-->'+JSON.stringify(this.columns));
        }else{
            this.showtable = false;
        }
        }
    }
    _flatten (target, obj, path) {
        let i, empty;
        if (obj.constructor === Object) {
            empty = true;
            // eslint-disable-next-line guard-for-in
            for (i in obj) {
                if (i === 'Id' && (obj.Account_Name__c != null || obj.Start_Date__c != null)) {
                    this._flatten(target, '/' + obj[i], i);
                }
                else if (i === 'Account_Name__c') {
                    this._flatten(target, '/' + obj[i], i);
                } else {
                    empty = false;
                    this._flatten(target, obj[i], path ? path + '.' + i : i);
                }
            }
            if (empty && path) {
                target[path] = {};
            }
        } else if (obj.constructor === Array) {
            i = obj.length;
            if (i > 0) {
                while (i--) {
                    this._flatten(target, obj[i], path + '[' + i + ']');
                }
            } else {
                target[path] = [];
            }
        } else {
            target[path] = obj;
        }
    }

    flatten (data) {
        let result = {};
        this._flatten(result, data, null);
        return result;
    }
}