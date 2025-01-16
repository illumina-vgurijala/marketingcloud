import { track,LightningElement } from 'lwc';
import {isNull,isBlank } from 'c/utils';

/**
* @ author       : Abhinav Gupta
* @ date         : 23-Mar-2022
* @ Description  : QACM-14,15 This component is created under QACM-14 and displays fields to search QI Records on
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             23-Mar-2022                 Initial version
*/

export default class SearchQiRecordsComponent extends LightningElement {
    
    @track problemTitle = "";
    @track createdDate = "";
    @track etqNumber = "";
    @track sitesImpacted = "";
    @track btnDisabled = false;

    connectedCallback(){
        //disable the search button on initial load
        this.btnDisabled = true;
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to send input data to parent component through CustomEvent.
    */
    qiSearch(){
        if(isNull(this.createdDate)){
            this.createdDate="";
        }
        const searchEvent = new CustomEvent('searchqi',{
            detail:{
                inpproblemTitle:this.problemTitle,
                inpcreatedDate:this.createdDate,
                inpetqNumber:this.etqNumber,
                inpsitesImpacted:this.sitesImpacted
            }
        });
        this.dispatchEvent(searchEvent);
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to update problemTitle variable when input is changed from UI
    */
    handleTitleChange(event){
        this.problemTitle = event.detail.value;
        this.validateSearchBtnVisibility();
    }

     /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to update sitesImpacted variable when input is changed from UI
    */
    handleSitesChange(event){
        this.sitesImpacted = event.detail.value;
        this.validateSearchBtnVisibility();
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to update etqNumber variable when input is changed from UI
    */
    handleNumberChange(event){
        this.etqNumber = event.detail.value;
        this.validateSearchBtnVisibility();
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to update createdDate variable when input is changed from UI
    */
    handleDateChange(event){
        this.createdDate = event.detail.value;
        if(isNull(this.createdDate)){
            this.createdDate = '';
        }
        this.validateSearchBtnVisibility();
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to make the search button disable or enabled based on search parameters
    */
    validateSearchBtnVisibility(){
        if(isBlank(this.problemTitle) && isBlank(this.sitesImpacted) && isBlank(this.etqNumber) && isBlank(this.createdDate)){
            this.btnDisabled=true;
        }
        else{
            this.btnDisabled=false;
        }
    }

}