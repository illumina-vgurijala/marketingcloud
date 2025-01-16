/*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description:  updates line items on an agreement to a specified status
    *  moved to batch since hundreds of record updates result in a CPU timeout
    *  Test class for 90% coverage: TestApttusAgreements
    *  Test class for 75% coverage: TestApttusAgreements
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Todd Newman                                      Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix - Add code comments
    *       Nitin                       2022-05-18           CMSI-19 - Setting Transaction id 
    *       Preetha                     2022-06-28           CMSI-90 Instrumenting the Class
    *       Vivek R                     2022-10-03           Inputs variable set to Test visible
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/
 public with sharing class AgreementLineStatusBatchUpdate extends ilib_BatchDeferrable {

    public final static String LOG_TITLE = 'AgreementLineStatusBatchUpdate';
    @TestVisible private Inputs inputs;
    /*
    *  @Author      : Todd Newman
    *  @Description : Parameter wrapper for easy serialization
    */
    public class Inputs
    {
        public Id agreementId;
        public String agreementStatus;
        /**
        * @author illumina
        * @description 
        */
        public Inputs(Id agreementId, String agreementStatus)
        {
            this.agreementId = agreementId;
            this.agreementStatus = agreementStatus;
        }
    }
    

    /*
    *  @Author      : Todd Newman
    *  @Description : Constructor required to reinstantiate after deferral
    */

    public AgreementLineStatusBatchUpdate() { }

    /*
    *  @Author      : Todd Newman
    *  @Description : Constructor to collect parameters of batch operation
    *  @Param       : Id, String
    */
    public AgreementLineStatusBatchUpdate(Id agreementId, String agreementStatus)
    {
        this.inputs = new Inputs(agreementId, agreementStatus);

        ilib_LogEvent.setTitle(LOG_TITLE);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to specify scope of batch
    *  @Param       : Database.BatchableContext
    *  @Return      : Database.QueryLocator
    */
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        String updatedAgreementId = inputs.agreementId;
        String soql = 'SELECT Id, Apttus_Approval__Approval_Status__c'
            + ' FROM Apttus__AgreementLineItem__c'
            + ' WHERE Apttus__AgreementId__c = :updatedAgreementId';
        return Database.getQueryLocator(soql);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : update one batch worth of records
    *  @Param       : Database.BatchableContext, List<SObject>
    *  @Return      : void
    */
    public override void execute(Database.BatchableContext bc, List<SObject> records)
    {
        //CMSI-19 setting transaction id
        ilib_LogEvent.setworkstream(ilib_logEvent.SALES);//CMSI-90
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        ilib_LogEvent.info('records ids: ' + UtilsCollection.getSetOfIds(records));//CSMI-90
        
        List<Apttus__AgreementLineItem__c> lstAgreementLineToUpdate = new List<Apttus__AgreementLineItem__c>();
        for (Apttus__AgreementLineItem__c objLine : (List<Apttus__AgreementLineItem__c>)records)
        {
            // if line status is approval required or rejected
            // update it to header value
            if (
                objLine.Apttus_Approval__Approval_Status__c == ApttusAgreements.APPROVAL_STATUS_APPROVAL_REQUIRED
             || objLine.Apttus_Approval__Approval_Status__c == ApttusAgreements.APPROVAL_STATUS_REJECTED
            ) {
                objLine.Apttus_Approval__Approval_Status__c = inputs.agreementStatus;
                ilib_LogEvent.message('Line to update: ' + objLine);
                lstAgreementLineToUpdate.add(objLine);
            }
        }

        try
        {
            update lstAgreementLineToUpdate;
        }
        catch(Exception e)
        {
            //CMSI-38: new emit method accepting three parameters (String source, String message, String workstream)
            ApexExceptions.emit(LOG_TITLE, e, ilib_LogEvent.SALES);
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to update header now that line batches have been completed
    *  @Param       : Database.BatchableContext
    *  @Return      : void
    */
    public override void finish(Database.BatchableContext bc)
    {
        //CMSI-19 setting transaction id
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE + '.finish()');
        // by setting the flag to false, certain operations on the agreement can resume
        ApttusAgreementLineItemsService.setUpdatingLinesFlag(inputs.agreementId, false);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************
    
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs()
    {
        return JSON.serialize(inputs);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs)
    {
        this.inputs = (AgreementLineStatusBatchUpdate.Inputs)JSON.deserialize(serializedInputs, AgreementLineStatusBatchUpdate.Inputs.class);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to get default val
    *  @Param       : None
    *  @Return      : Integer
    */
    public override Integer getDefaultBatchSize()
    {
        return 100;
    }

}