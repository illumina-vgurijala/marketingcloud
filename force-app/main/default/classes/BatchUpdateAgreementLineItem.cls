/**
*	@author KD
*	@date	
*	@description	Bulk update on Agreement Line item post SAP action
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description	
*           KD		                                        Initial Version
*           Himanhsu                    2022-03-29          Code Scan Fixes
*           Nishan Shetty               2022-05-23          Implementing Batch Manager and Logging Framework [DCP-50962].
*           Nishan Shetty               2022-Aug-22         [TASK0802266] Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
*           Aman Tyagi                  2022-sep-22         Added logic as per DCP-56506
*           Aman Tyagi                  2022-Dec-12         CodeScan Fixes
*	------------------------------------------------------------------------------------
**/
global without sharing class BatchUpdateAgreementLineItem extends ilib_BatchDeferrable {

    public final static String LOG_TITLE = 'BatchUpdateAgreementLineItem';
    private Inputs inputs;//DCP-50962
    private String strQuery;
    private String strAgreementId;
    public Date dtActionDate;
    public String strAction;
    

    /*
    *  @Author      : Nishan Shetty[DCP-50962]
    *  @Description : Parameter wrapper for easy serialization
    */
    public class Inputs {
        public String strIdAgreement;
        public Date dateOfAction;
        public String strActionName;

        /*Constructor*/
        public Inputs(String strAgreementId, Date dtActionDate,String strAction) {
            this.strIdAgreement = strAgreementId;
            this.dateOfAction = dtActionDate;
            this.strActionName = strAction;
        }
    }

    /*
     * @Author : Nishan Shetty[TASK0802266]
     * @Description : Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
    */
    public BatchUpdateAgreementLineItem() {
        super();
    }

 
    /**
     * @author  KD
     * @description  paramterized constructor
     * @param String String strAgreementId,Date dtActionDate,String strAction
     * @return NA
    **/
    public BatchUpdateAgreementLineItem(String strAgreementId,Date dtActionDate,String strAction) {
        super();
        ilib_LogEvent.setTitle(LOG_TITLE);
        this.inputs = new Inputs(strAgreementId,dtActionDate,strAction);
        this.strAgreementId = inputs.strIdAgreement;
        this.strAction = inputs.strActionName;
        this.dtActionDate = inputs.dateOfAction;
        ilib_LogEvent.message('strAgreementId' + inputs.strIdAgreement);
        this.strQuery = 'Select id,Name,Discontinued__c,Apttus_CMConfig__StartDate__c,RecordType.DeveloperName,Previous_Customer_Elections__c,Customer_Election__c,Apttus_CMConfig__EndDate__c,Apttus_CMConfig__LineStatus__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =\''+strAgreementId+'\'';
        ilib_LogEvent.message('#####BatchUpdateAgreementLineItem query: ' + this.strQuery);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    
    /**
    *	@author KD
    *	@description Start Method For the Apex JOb
    **/
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug(Database.getQueryLocator(this.strQuery));
        return Database.getQueryLocator(this.strQuery);
    }

    /**
    *	@author KD
    *	@description Update Line items
    **/
    global override void execute(Database.BatchableContext bC, list<Sobject> scope){
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE+'.execute');
        Boolean boolCheckStartDate = false;
        Boolean boolCheckEndDate = false;
        Date dtStartDate;
        Date dtEndDate;
        List<Apttus__AgreementLineItem__c> lstAgrLineItemsUpdate = new List<Apttus__AgreementLineItem__c>();
        for(Apttus__AgreementLineItem__c aLI : (List<Apttus__AgreementLineItem__c>)scope){
            ilib_LogEvent.message('Line item -->' +aLI);
            boolCheckStartDate = false;
            boolCheckEndDate = false;
            Boolean boolAgrmntLineItemIsOpenOffer = aLI.RecordType.DeveloperName == Label.AgreementLineItemRecordTypeDevNameOpenOffer ;
            dtStartDate = strAction == Label.AgreementActionTerminate ? aLI.Apttus_CMConfig__StartDate__c : ApttusAgreementErrorHandler.generateStartDate(aLI,dtActionDate);
            if(dtStartDate != null){
                boolCheckStartDate = true;
            }
            dtEndDate = strAction == Label.AgreementActionTerminate ? ApttusAgreementErrorHandler.generateTerminateEndDate(aLI,dtActionDate) : ApttusAgreementErrorHandler.generateEndDate(aLI,dtActionDate);
            if(dtEndDate != null){
                boolCheckEndDate = true;
            }
            if(boolCheckStartDate)
                aLI.Apttus_CMConfig__StartDate__c = dtStartDate;
            if(boolCheckEndDate)
                aLI.Apttus_CMConfig__EndDate__c = dtEndDate;
            if(strAction == Label.AgreementActionActivate) {
                aLI.Apttus_CMConfig__LineStatus__c = Label.AgreementLineItemLineStatusExisting;
                aLI.Previous_Customer_Elections__c = boolAgrmntLineItemIsOpenOffer ? aLI.Customer_Election__c : '';
            }
            if(boolCheckEndDate || boolCheckStartDate || strAction == Label.AgreementActionActivate)
                lstAgrLineItemsUpdate.add(aLI);
        }
        if(!lstAgrLineItemsUpdate.isEmpty())
            update lstAgrLineItemsUpdate;
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *	@author KD
    *	@description Update Agreement status post line item update
    **/
    global override void finish(Database.BatchableContext bc) {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE+'.finish');
        if(strAction == Label.AgreementActionActivate){
            ilib_LogEvent.message('Agreement Id-->'+strAgreementId);
            Apttus__APTS_Agreement__c objAgreementUpdated = new ApttusAgreementSelectors().selectAgreementWithLines(new Set<id>{strAgreementId})[0];
            if(objAgreementUpdated.Apttus__Contract_Start_Date__c < objAgreementUpdated.Action_Date__c)
                objAgreementUpdated.Apttus__Contract_Start_Date__c = objAgreementUpdated.Action_Date__c;
            objAgreementUpdated.Validation_Status__c = Label.UI_Agreement_Validation_Status_Completed.replace('{0}',objAgreementUpdated.Validation_Status__c.split(' ')[0]);
            update objAgreementUpdated;
            ApttusAgreementActionService.updateParentAgreement(objAgreementUpdated,Label.AgreementActionActivate);
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************
    
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs()
    {
        return JSON.serialize(inputs);
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs)
    {
        this.inputs = (BatchUpdateAgreementLineItem.Inputs)JSON.deserialize(serializedInputs,BatchUpdateAgreementLineItem.Inputs.class);
    }

}