/**
* @author Todd Newman
* @description  Utility class for performing actions on agreement and agreement line item data
* Modification Log:
* ------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                Description                                                 
*   Todd Newman                                 Inital Version
*   Himanshu              31-March-2022          Code Scan Fixes     
* ------------------------------------------------------------------------------------------------------------------------------------          
*/
public with sharing class ApttusAgreementLineItemsService {

    
    /**
    * @description this agreement status was changed to approved or rejected update child line item status to match
    * @params NA
    * @return void
    **/
    public static void updateStatusToMatchHeader(Id agreementId, String agreementStatus)
    {
        // by setting the flag to true, certain operations on the agreement are blocked
        // QUESTION: shoudl this move upstream to the agreement after update trigger?
        // There might be a couple second delay to get here. But putting it there causes a recursive update which risks getting closer to limits
        setUpdatingLinesFlag(agreementId, true);

        // update line items in a batch since hundreds of record updates result in a CPU timeout
        ilib_BatchManager.executeBatch(new AgreementLineStatusBatchUpdate(agreementId, agreementStatus), 100);
    }

    /**
    * @description this flag is true for the duration of the batch job which updates the status on all line items while it's true certain operations on the agreement are blocked
    * @params NA
    * @return void
    **/
    public static void setUpdatingLinesFlag(Id agreementId, Boolean val)
    {
        ilib_LogEvent.message('Setting update line status flag to ' + val + ' for agreement ' + agreementId); 

        // NOTE: if there are permission problems with this we could publish a platform event
        update new Apttus__APTS_Agreement__c(Id = agreementId, Is_Updating_Line_Status__c = val);
    }

}