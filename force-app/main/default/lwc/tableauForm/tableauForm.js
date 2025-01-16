import {
    LightningElement,
    api,
    track
} from 'lwc';

import {
    isEmpty,
    isNull,
    isNotBlank,
} from 'c/utils';

export default class TableauForm extends LightningElement {
    //design parameters start
    @api strobjectApi;
    @api recordId;
    @api strTableauURL;
    @api intHeight;
    @api booHideTab;
    @api booHideToolbar;
    @api strFilters;
    @api strField; //dummy not to be used. Put to make configuration on lightning record page easier
    @api strReportName;
    @api strFormName;
    @api strFields;
    @api strRequiredFields;
    //design parameters end

    @track booShowTableau = false;
    @track booConfigurationProper = false;
    @api intErrorCounter = 1;
    @track lstErrors = [];
    @track lstForms =[];

    connectedCallback() {
        let numForms = this.getFormCounts(this.strFormName);
        let booValid=true;
        
        let numFormFieldSets=this.getFormCounts(this.strFields);
        if(numForms!=numFormFieldSets){
            this.addError('Form Header Count('+numForms+') different from field section count('+numFormFieldSets+')');
            booValid=false;
        }

        let numFormRequiredFieldSets=this.getFormCounts(this.strRequiredFields);
        if(isNotBlank(this.strRequiredFields) && numForms!=numFormRequiredFieldSets){
            this.addError('Form Header Count('+numForms+') different from required field section count('+numFormRequiredFieldSets+')');
            booValid=false;
        }

        if(booValid && numForms>0){
            const seperator='\|';
            let lstFormHeaders = this.strFormName.split(seperator);
            let lstFields = this.strFields.split(seperator);
            let lstRequiredFields = isNotBlank(this.strRequiredFields)? this.strRequiredFields.split(seperator) : [];
            let context=this;
            lstFormHeaders.forEach(function(element,index){
                let strRequiredFields;
                if(isEmpty(lstRequiredFields))
                    strRequiredFields='';
                else if(context.checkRequiredFields(lstFields[index].trim(),lstRequiredFields[index].trim())){
                    strRequiredFields = lstRequiredFields[index].trim();
                }else{
                    booValid=false;
                }

                let formDetail={
                                header: element.trim(),
                                fields: lstFields[index].trim(),
                                requiredFields: strRequiredFields
                };
                context.lstForms.push(formDetail);
            });
        }else if(booValid){
            let formDetail={ 
                            header: this.strFormName,
                            fields: this.strFields,
                            requiredFields: this.strRequiredFields
                        };
            this.lstForms.push(formDetail);
        }
        
        if(booValid)
            this.loadReportAndForm();
    }

    getFormCounts(strConfigValue){
        return isNull(strConfigValue)?0:(strConfigValue.match(/\|/g) || []).length;
    }

    checkRequiredFields(strFields,strRequiredFields){
        let booValid=true;
        if(isNotBlank(this.strRequiredFields)){
            let lstFields = strFields.split(',');
            strRequiredFields.split(',').forEach(strField => {
                if(isNull(lstFields.find(element => element === strField))){
                    this.addError('Required field '+strField+' not in main field list '+strFields);
                    booValid=false;
                }
            });
        }
        return booValid;
    }

    loadReportAndForm(){
        this.booConfigurationProper=true;
        this.booShowTableau=true;
    }

    onFormSave(){
        this.reloadTableau();
    }

    addError(strMessage) { //add message to list of errors. Can't keep in util because of dependency of error counter in this JS
        let strError = {
            intIndex: this.intErrorCounter++,
            strValue: strMessage
        };
        this.lstErrors.push(strError);
    }

    reloadTableau(){
        let context=this;
        this.booShowTableau=false;
        setTimeout(function(){
            context.booShowTableau=true;
        },100);
    }
}