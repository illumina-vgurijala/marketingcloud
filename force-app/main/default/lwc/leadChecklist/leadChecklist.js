import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import {consoleLog,consoleError} from 'c/utils';
import EMAIL_VALUE from "@salesforce/schema/Lead.IsVerified__c";
import CITY_VALUE from "@salesforce/schema/Lead.City";
import STREET_VALUE from "@salesforce/schema/Lead.Street";
import NAME_VALUE from "@salesforce/schema/Lead.FirstName";
import email from '@salesforce/label/c.UI_Lead_EmailCheckBox';
import street from '@salesforce/label/c.UI_Lead_StreetCheckBox';
import city from '@salesforce/label/c.UI_Lead_CityCheckBox';
import name from '@salesforce/label/c.UI_Lead_FirstNameCheckBox';

export default class LeadChecklist extends LightningElement {
  @track nameCheck ;
  @track streetCheck ;
  @track cityCheck ;
  @track emailCheck ;
  label = {
      email,
      street,
      city,
      name,
  };

  @api
  recordId;

  @wire(getRecord, {
      recordId: '$recordId',
      fields:[EMAIL_VALUE, CITY_VALUE, STREET_VALUE, NAME_VALUE]
    })
    wiredRecord({ data, error }){
        if (data) {
          this.leadCheck(data);
          consoleLog(JSON.stringify(data));
        }
        if(error){
          consoleError('error',error);
        }
    }
    leadCheck(data){
      if(JSON.stringify(data.fields.FirstName.value)!=='null'){
          this.nameCheck = true;
      }else{
        this.nameCheck = false;
      }
      if(JSON.stringify(data.fields.Street.value)!=='null'){
          this.streetCheck = true;
      }else{
        this.streetCheck = false;
      }
      if(JSON.stringify(data.fields.City.value)!=='null'){
          this.cityCheck = true;
      }else{
        this.cityCheck = false;
      }
      if(JSON.stringify(data.fields.IsVerified__c.value) === 'true'){
          this.emailCheck = true;
      }else{
        this.emailCheck = false;
      }
    }
  }