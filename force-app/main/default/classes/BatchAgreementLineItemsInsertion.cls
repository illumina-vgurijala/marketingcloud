/**
*    @author: Prabhsimran Singh 
*    @date:   31-July-2020
*    @description:  Batch class to insert agreement line item on amend operation
*    Modification Log:
*    ------------------------------------------------------------------------------------
*     Developer                      Date                Description
*     Prabhsimran Singh             14-Dec-2020          TASK0548096
*     Nishan Shetty                 23-May-2022          DCP-50962 [Ilib Batch Manager Implementation]
*     Preetha                       28-Jun-2022          CMSI-90 Instrumenting the class
*     Nishan Shetty                 2022-Aug-22         [TASK0802266] Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
*     Jitesh                        2022-Sept-14          DCP-56503    
*     Aman Tyagi                    2022-sep-22          added field as per DCP-56506
*     Raja Babu                     2024-feb-22          Do not copy the lines to renewal agreement if the original agreement line is having inactive product as per TASK0995233
*     Sushil Bolwar                 2024-June-5          DGP-108
*    ------------------------------------------------------------------------------------ 
*/

global without sharing class BatchAgreementLineItemsInsertion extends ilib_BatchDeferrable implements Database.AllowsCallouts {    

    public final static String LOG_TITLE = 'BatchAgreementLineItemsInsertion';
    global Id agreementIdToUpdate;
    global Apttus__APTS_Related_Agreement__c relatedAgreement;
    global Boolean isError = false;
    global Apttus__APTS_Agreement__c childAgreement;
    global final static string RENEWED_TYPE = 'Renewed';
    global final static string NEW_LINE_TYPE = 'New';
    private Inputs inputs;//DCP-50962

    global set<string> setFieldsToCopy = new set<string> {
        'Sales_Org__c','Ultimate_Consignee_ERP_Number__c',
        'RecordTypeId','Account__c','Apttus__ProductId__c','CurrencyIsoCode','Condition_Table__c',
        'Condition_Type__c','Customer_ERP_Number__c','Discontinued__c','Discount_In_Percent__c','Discount_Type__c',
        'Discount__c','Discount_Amount__c','Distribution_Channel__c','Line_Type_1__c','Line_Type__c',
        'Material_Group_1_Description__c','Material_Group_1__c','Material_Number__c','Partner_Role__c','Previous_Customer_Elections__c',
        'Permitted_Markup_Percentage__c','Price_Group__c','Customer_Price__c','Q1_Quota__c','Q2_Quota__c',
        'Q3_Quota__c','Q4_Quota__c', 'Open_Offer_Line_Type__c', 'Customer_Election__c', 
        'PSP_Category__c', 'PSP_Discount__c', 'Quote_Discount_Type__c', 'Quote_Discount__c', 'Quote_Number__c', 
        'Refer_to_MSA__c', 'Supply_Agreement_Discount_Type__c', 'Supply_Agreement_Discount__c', 'Supply_Agreement_End_Date__c',
        'Supply_Agreement_Start_Date__c', 'Universal_Grid_Discount_Type__c', 'Universal_Grid_Discount__c'
    };

    global set<string> setNullCheckFields = new set<string> {
        'Discount_In_Percent__c','Discount__c','Discount_Amount__c','Permitted_Markup_Percentage__c',
        'Customer_Price__c','Q1_Quota__c','Q2_Quota__c','Q3_Quota__c','Q4_Quota__c'
    };

    /*
    *  @Author      : Nishan Shetty DCP-50962
    *  @Description : Parameter wrapper for easy serialization
    */
    public class Inputs {
        public Apttus__APTS_Related_Agreement__c objRelatedAgreement;
        public Id idAgreementToUpdate;
        /*Constructor*/
        public Inputs(Apttus__APTS_Related_Agreement__c relatedAgreement) {
            this.objRelatedAgreement = relatedAgreement;
            this.idAgreementToUpdate= relatedAgreement.Apttus__APTS_Contract_To__c;
        }
    }

    /*
    * @Author : Nishan Shetty[TASK0802266]
    * @Description : Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
    */
    public BatchAgreementLineItemsInsertion() {
        super();
    }


    /* constructor to initialise lstagreement and mapParentChildAgreement*/
    public BatchAgreementLineItemsInsertion(Apttus__APTS_Related_Agreement__c relatedAgreement) {
        super();
        ilib_LogEvent.setTitle(LOG_TITLE);
        this.inputs = new Inputs(relatedAgreement);
        this.relatedAgreement = inputs.objRelatedAgreement;
        this.agreementIdToUpdate = inputs.idAgreementToUpdate;
        childAgreement = new ApttusAgreementSelectors().selectAgreements(new Set<Id>{inputs.idAgreementToUpdate})[0];
    }

    /* start method to query records */
    global override Database.QueryLocator start(Database.BatchableContext bc)
    {   ilib_LogEvent.push(LOG_TITLE+'.start');
        String discontinueLabel = Label.AgreementLineItemDiscontinue;
        String strSoql = 'SELECT Account__c, Apttus_CMConfig__EndDate__c, Apttus_CMConfig__LineStatus__c, Apttus_CMConfig__StartDate__c, Apttus__AgreementId__c, ' +
            'Apttus__ProductId__c, CurrencyIsoCode, Condition_Table__c, Condition_Type__c, Customer_ERP_Number__c, Discontinued__c, Discount_In_Percent__c, ' +
            'Discount__c, Discount_Amount__c, Distribution_Channel__c, Line_Type_1__c, Line_Type__c, Material_Group_1_Description__c, Material_Group_1__c, ' +
            'Material_Number__c, Discount_Type__c, Partner_Role__c, Permitted_Markup_Percentage__c, Price_Group__c, Customer_Price__c, Q1_Quota__c, Q2_Quota__c, ' +
            'Q3_Quota__c, Q4_Quota__c, RecordTypeId, Sales_Org__c, Ultimate_Consignee_ERP_Number__c, Apttus__AgreementId__r.RecordTypeId, Customer_Election__c, ' +
            'Supply_Agreement_End_Date__c, Open_Offer_Line_Type__c, PSP_Category__c, PSP_Discount__c, Quote_Discount_Type__c, Quote_Discount__c, Quote_Number__c,'+ 
            'Refer_to_MSA__c, Supply_Agreement_Discount_Type__c, Supply_Agreement_Discount__c,'+
            'Supply_Agreement_Start_Date__c, Universal_Grid_Discount_Type__c, Previous_Customer_Elections__c, Universal_Grid_Discount__c,Apttus__ProductId__r.IsActive,' + 
            'Median_Discount_Guidance__c, Max_Discount_Guidance__c, Customer_Historical_Discount__c '+
            'FROM Apttus__AgreementLineItem__c ' +
            'WHERE Apttus__AgreementId__c = \''+relatedAgreement.Apttus__APTS_Contract_From__c+'\' ' +
            'AND Discontinued__c = \''+discontinueLabel+'\' ' +
            'AND Apttus_CMConfig__EndDate__c >= TODAY';
        
        ilib_LogEvent.message('Query: '+strSoql);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
        return Database.getQueryLocator(strSoql);
    }

    /* method to execute logic for each chunk of records*/
    global override void execute(Database.BatchableContext bc, List<sobject> lstAgreementLineItem)
    {
        ilib_LogEvent.setworkstream(ilib_logEvent.SALES);//CMSI-90
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);//CMSI-90
        ilib_LogEvent.push(LOG_TITLE + '.execute()'); //CMSI-90
        //If any error occurs in any chunk, then bypass the next in queue chunks to insert line items
        if (isError){
            ilib_LogEvent.pop();//CMSI-90
            ilib_LogEvent.emit();//CMSI-90
            return;
        }

        // build list of line items for child agreement
        List<Apttus__AgreementLineItem__c> lstALI = new List<Apttus__AgreementLineItem__c>();  
        Map<Id, RecordTypeInfo> agreementRecordTypeMap = ApttusAgreements.getRecordTypeMap();
        ilib_LogEvent.info('lstAgreementLineItem ids :'+UtilsCollection.getSetOfIds(lstAgreementLineItem));//CMSI-90          
        for (Apttus__AgreementLineItem__c ali : (List<Apttus__AgreementLineItem__c>) lstAgreementLineItem){

            if(System.label.AgreementRecordTypeOpenOffer == agreementRecordTypeMap.get(ali.Apttus__AgreementId__r.RecordTypeId).getDeveloperName()) { 

                if(LABEL.CustomElectionPickListSupplyAgreement.equals(ali.Customer_Election__c) && ali.Supply_Agreement_End_Date__c < Date.Today()) {continue;}
                
            }
 
            if(ali.Material_Number__c != null && !ali.Apttus__ProductId__r.IsActive){ //TASK0995233
		continue; //TASK0995233
	    }else{
                Apttus__AgreementLineItem__c newAli = createLineItem(ali);
                ilib_LogEvent.message('newAli : '+newAli);
                lstALI.add(newAli);
            }
        }
        if (lstALI.isEmpty()){
            ilib_LogEvent.pop();//CMSI-90
            ilib_LogEvent.emit();//CMSI-90
            return;
        }

        // insert and keep track of errors that occur
        ilib_LogEvent.info('lstALI : '+UtilsCollection.getSetOfIds(lstALI));//CMSI-90          
        List<Database.SaveResult> srList = Database.insert(lstALI, false);
        ApexExceptions.emitSaveErrors(srList, 'BatchAgreementLineItemsInsertion');
        for (Database.SaveResult sr : srList) {   
            ilib_LogEvent.message('sr : ' + sr);
            if (!sr.isSuccess()) {                    
                isError = true;                
            }
        }
        ilib_LogEvent.pop();//CMSI-90
        ilib_LogEvent.emit();//CMSI-90
    }

    /**
    * @author Prabhsimran Singh
    * @date   10-08-2020
    * @description To create new agreement line item
    */
    private Apttus__AgreementLineItem__c createLineItem(Apttus__AgreementLineItem__c ali)
    {
        Apttus__AgreementLineItem__c newAli = new Apttus__AgreementLineItem__c();
        newAli.Apttus__AgreementId__c = relatedAgreement.Apttus__APTS_Contract_To__c;

        // copy line item values from related agreement to the child agreement
        for (String field : setFieldsToCopy)
        {
            if(setNullCheckFields.contains(field)) {
                if(ali.get(field) != null) {
                    newAli.put(field,ali.get(field));
                }
            }
            else if(String.isNotBlank(String.valueOf(ali.get(field)))) {
                newAli.put(field,ali.get(field));
            }
        }

        // set values specific to renewal agreements
        if(relatedAgreement.Apttus__Relationship_From_Type__c.contains(RENEWED_TYPE)) {
            newAli.Apttus_CMConfig__LineStatus__c = NEW_LINE_TYPE;
            if(childAgreement.Apttus__Contract_End_Date__c != null) {
                newAli.Apttus_CMConfig__EndDate__c = childAgreement.Apttus__Contract_End_Date__c;
            }
            if(childAgreement.Apttus__Contract_Start_Date__c != null) {
                newAli.Apttus_CMConfig__StartDate__c = childAgreement.Apttus__Contract_Start_Date__c;
            }
        }
        // set values specific to amended agreements
        else
        {
            if (ali.Apttus_CMConfig__EndDate__c != null) {
                newAli.Apttus_CMConfig__EndDate__c = ali.Apttus_CMConfig__EndDate__c;
            }
            if (String.isNotBlank(ali.Apttus_CMConfig__LineStatus__c)) {
                newAli.Apttus_CMConfig__LineStatus__c = ali.Apttus_CMConfig__LineStatus__c;
            }
            if (ali.Apttus_CMConfig__StartDate__c != null) {
                newAli.Apttus_CMConfig__StartDate__c = ali.Apttus_CMConfig__StartDate__c;
            }
            //DGP-108 : start
            if (ali.Median_Discount_Guidance__c != null) {
                newAli.Median_Discount_Guidance__c = ali.Median_Discount_Guidance__c;
            }
            if (ali.Max_Discount_Guidance__c != null) {
                newAli.Max_Discount_Guidance__c	= ali.Max_Discount_Guidance__c;
            }
            if (ali.Customer_Historical_Discount__c	!= null) {
                newAli.Customer_Historical_Discount__c = ali.Customer_Historical_Discount__c;
            }
            //DGP-108 : end
        }
        return newAli;
    }

    /* method to be called once all chunks executed */
    global override void finish(Database.BatchableContext bc)
    {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE+'.finish()');
        
        if (agreementIdToUpdate == null){
            ilib_LogEvent.pop();//CMSI-90
            ilib_LogEvent.emit();//CMSI-90
            return;
        }

        try
        {
            Apttus__APTS_Agreement__c relatedAgreement =  new ApttusAgreementSelectors().selectAgreements(new Set<Id> {agreementIdToUpdate}).get(0);

            if (isError)
            {
                String res = ApttusAgreementValidateController.sendCancelRequest(String.valueOf(relatedAgreement.Id), 'Cancel');
                ilib_LogEvent.info('Cancel result ' + res);//CMSI-90
            }
            else
            {
                relatedAgreement.Amend_Batch_Completed__c = true;
                update relatedAgreement;
            }
            ilib_LogEvent.pop();//CMSI-90
            ilib_LogEvent.emit();//CMSI-90
        }
        catch (exception e)
        {
            ApexExceptions.emit('BatchAgreementLineItemsInsertion',e);
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
        this.inputs = (BatchAgreementLineItemsInsertion.Inputs)JSON.deserialize(serializedInputs,BatchAgreementLineItemsInsertion.Inputs.class);
    }

}