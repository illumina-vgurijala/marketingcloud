import { LightningElement,api,track } from 'lwc';
import getTemplateData from '@salesforce/apex/QaReviewTemplateController.getTemplateData';
import upsertInvestigationSummary from '@salesforce/apex/QaReviewTemplateController.upsertSummaryField';
import {  getRecordNotifyChange } from 'lightning/uiRecordApi';
import SuccessMessage from '@salesforce/label/c.CustomQuickTextSuccessMessage';
import SearchErrorMessage from '@salesforce/label/c.CustomQuickTextSearchError';
import LimitErrorMessage from '@salesforce/label/c.CustomQuickTextLimitExceedError';
import QAReviewIsEmpty from '@salesforce/label/c.ErrorMessage_CaseQAReviewIsEmpty';
import {
    consoleLog,
    isNotBlank,
    callServer,
    showErrorToast,
    showSuccessToast,
    consoleError
} from 'c/utils';
export default class InsertQuickText extends LightningElement {
    @track orginalDropDownValue= []
    @track inputValue
    @track dropDownValue=[]
    @track caseDMLStatus
    @track isspinner =false
    @api recordId
    @track title
    @track message
    @track variant
    @api componentTitle
    @api objectApiName
    @track quickTextData=[]
    showTemplate = false
    insideDropdown =false
    successMessage = 'Successfully Updated'
    limitExceed = 'Limit Exceed'
    QAReviewFieldStatus = 'QA Review Field Is Empty'

    get optionStr(){
        return this.dropDownValue
    }

    get showTemplate(){
        return this.showTemplate;
    }

    connectedCallback(){
        callServer(getTemplateData,{ 
            objectName: this.objectApiName},
        result => {
            let count=0
            for(let key in result){
                this.orginalDropDownValue.push({ind:count,Name:key,value:result[key]}); 
                count++;
            }
        },
        error => {
            this.orginalDropDownValue=[]
            consoleError('ConnectedCallback',error)
        });
    }

  
    onclickHandler(){
            this.dropDownValue = [...this.orginalDropDownValue]
            if(this.dropDownValue){
                this.showTemplate = true
                this.template.querySelector('.my-menu').classList.add('slds-is-open');
             }
             else{
                 this.showTemplate = false
             }
    }

    onBlurHandler(){
        if(this.insideDropdown===false){
            this.template.querySelector('.my-menu').classList.remove('slds-is-open');
            consoleLog("inside onBlur handlers"+this.showTemplate)
        }
            consoleLog("input",this.inputValue)
        
    }

    mouseoverHandler(){
        this.insideDropdown = true
    }
    mouseoutHandler(){
        this.insideDropdown = false
    }
    scrollHandler(){
        this.insideDropdown = false
    }

    inputhandler(event){
        this.dropDownValue=[]
        this.inputValue = ''
        if(isNotBlank(event.target.value)){
            this.orginalDropDownValue.forEach(item=> {
                consoleLog("item",((item.Name).toLowerCase()).includes((event.target.value).toLowerCase()),item)
                if( ((item.Name).toLowerCase()).includes((event.target.value).toLowerCase())){
                    this.dropDownValue[(this.dropDownValue.length)]=item
                    
                }
            });
        }
        else{
            this.dropDownValue = []
            this.dropDownValue = [...this.orginalDropDownValue]
        }
    }
   
    choicehandler(event){
        
        let secondClasses =  this.template.querySelector('input');
        consoleLog('event.currentTarget.dataset.id',this.orginalDropDownValue[event.currentTarget.dataset.id].Name)
        secondClasses.value= this.orginalDropDownValue[event.currentTarget.dataset.id].Name
        this.inputValue = this.orginalDropDownValue[event.currentTarget.dataset.id].value
        this.dropDownValue=[]
        this.showTemplate=false
        this.mouseoutHandler()
    }

    inserthandleClick(){
        if(isNotBlank(this.inputValue)){
            consoleLog('insertupdate')
            this.isspinner = true
            upsertInvestigationSummary({ 
                recordId: this.recordId, 
                impactValue: this.inputValue,
                objectAPI: this.objectApiName
            })
            .then((result) => {
                this.caseDMLStatus = result;
                consoleLog("result",result)

                if(this.caseDMLStatus === this.successMessage){
                    getRecordNotifyChange([{recordId: this.recordId}]);
                    let secondClasses1 =  this.template.querySelector('input');
                    secondClasses1.value= ''
                    showSuccessToast(SuccessMessage);
                    this.isspinner = false
                    this.inputValue=''  

                }
                else if(this.caseDMLStatus === this.limitExceed){
                    let secondClasses1 =  this.template.querySelector('input');
                    secondClasses1.value= ''
                    showErrorToast(LimitErrorMessage); 
                    this.isspinner = false
                    this.inputValue=''
                    this.dropDownValue=[] 
                } 
                else if(this.caseDMLStatus === this.QAReviewFieldStatus){
                    let secondClasses1 =  this.template.querySelector('input');
                    secondClasses1.value= ''
                    showErrorToast(QAReviewIsEmpty); 
                    this.isspinner = false
                    this.inputValue=''
                    this.dropDownValue=[] 
                }
            })
            .catch((error) => {
                    this.caseDMLStatus = null;
                    let secondClasses1 =  this.template.querySelector('input');
                    secondClasses1.value= ''
                    this.isspinner = false
                    this.inputValue='' 
                    this.dropDownValue=[]
                    consoleLog("test",error)
                    showErrorToast(error.body.message); 
            });
        }
        else{
            this.caseDMLStatus = null;
            let secondClasses1 =  this.template.querySelector('input');
            secondClasses1.value= ''
            showErrorToast(SearchErrorMessage); 
            this.isspinner = false
            this.inputValue=''  
            this.dropDownValue=[]
        }
    }
}