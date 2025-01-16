import { api,LightningElement,track } from 'lwc';

/**
* @ author       : Abhinav Gupta
* @ date         : 23-Mar-2022
* @ Description  : QACM-14,15 This component is created under QACM-14 and displays displaySearchedQiRecords, searchQiRecordsComponent LWC Component
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             23-Mar-2022                 Initial version
*/

export default class SearchViewExistingQiRecords extends LightningElement {

    @api parentRecordId;
    @api blnCloseModalState = false;
    @track inputProblemTitle="";
    @track inputSitesImpacted="";
    @track inputEtqNumber="";
    @track inputeCreatedDate="";
    @track searchBtnClicked = false;
    @track linkClickState = false;
    @api objectApiName;

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to close the modal/change state
    */
    closeModal(){
        if(!this.blnCloseModalState){
            this.blnCloseModalState = true;
            const closeModalEvent = new CustomEvent("closemodalevent2", {
              });
          
              this.dispatchEvent(closeModalEvent);
        }
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to set input parameters when search button is clicked
    */
    handleSearchQi(event){
        this.inputProblemTitle=event.detail.inpproblemTitle;
        this.inputSitesImpacted=event.detail.inpsitesImpacted;
        this.inputEtqNumber=event.detail.inpetqNumber;
        let tempDate = event.detail.inpcreatedDate;
        this.inputeCreatedDate=tempDate.toString();
        this.searchBtnClicked = true;
        this.template.querySelector("c-display-searched-qi-records").reloadTable(this.inputProblemTitle,this.inputSitesImpacted, this.inputEtqNumber,this.inputeCreatedDate);
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to pass event to child component to refresh the searched records
    */
    linkClicked(event){
        this.linkClickState = event.detail.linkClicked;
        if(this.linkClickState){
        const clickEvent1 = new CustomEvent('linkclick1',{
            detail:{
                linkClicked1: true
            }
        });
        this.dispatchEvent(clickEvent1);
    }
    }

}