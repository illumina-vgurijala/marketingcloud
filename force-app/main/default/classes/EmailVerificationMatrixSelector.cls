/**
*    @author Ashwin
*    @date   11th July 2022
*    @description  Email VerificationMatrix Selector
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date                   Description
*         Ashwin                        11-July-2022           INC0403213 - Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class EmailVerificationMatrixSelector extends ilib_SObjectSelector{
    
    private static final String LOG_TITLE = 'EmailVerificationMatrixSelector';
    private static final String SALES_QUERY_LOGS = 'SalesQueryLogs';

    /**
     *  @author Ashwin Kumar
     *  @description
     *  @return SObjectType The Schema.SObjectType of the Email_Verification_Matrix__mdt
    **/
    public Schema.SObjectType getSObjectType() {
        return Email_Verification_Matrix__mdt.sObjectType;
    }

    /**
    *  @author  Ashwin Kumar
    *  @description Retrieve list of fields for Email_Verification_Matrix__mdt
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Email_Verification_Matrix__mdt.Id,
            Email_Verification_Matrix__mdt.ReasonCode__c,
            Email_Verification_Matrix__mdt.StatusNbr__c,
            Email_Verification_Matrix__mdt.Verification_Status__c
        };
    }

    /**
     *  @author Ashwin
     *  @description Get all Email Verification Matrix cmd records
     *  @return List of Email_Verification_Matrix__mdt records 
     **/
    public List<Email_Verification_Matrix__mdt> getAllRecords() {
        
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '.getAllRecords');
        }

        List<Email_Verification_Matrix__mdt> lstEmailVerificationMatrix = (List<Email_Verification_Matrix__mdt>) Database.query(
            newQueryFactory().toSOQL()
        );

        if (Feature.isOn(SALES_QUERY_LOGS)) { logger.stop(lstEmailVerificationMatrix.size()); }
        return lstEmailVerificationMatrix;
    }

}