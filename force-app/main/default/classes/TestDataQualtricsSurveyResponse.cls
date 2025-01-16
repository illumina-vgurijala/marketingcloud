/**
*   @author KD
*   @date  16-June-2020
*   @description    Test Data for Qualtrics_Survey_Response__c.
*   Modification Log:
*   ------------------------------------------------------------------------------------
*           Developer                   Date                Description         
*   ------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestDataQualtricsSurveyResponse {

    /*
    * create qualtrics Survey Response record
    */		
    public static Qualtrics_Survey_Response__c getNewCaseQSR(Case cs,Id idRecordType){
        Qualtrics_Survey_Response__c qsr = new Qualtrics_Survey_Response__c(
                                                    Case__c=cs.id,
                                                    NPS_Score__c=1,
                                                    OSAT_Score__c=2,
                                                    RecordTypeid = idRecordType);
        insert qsr;
        return qsr;
    }
	
	/*
    * create qualtrics Survey Response record with work order
    */			
    public static Qualtrics_Survey_Response__c getNewWOQSR(SVMXC__Service_Order__c wo,Id idRecordType){
        Qualtrics_Survey_Response__c qsr = new Qualtrics_Survey_Response__c(
                                                    Work_Order__c=wo.id,
                                                    NPS_Score__c=1,
                                                    OSAT_Score__c=2,
                                                    RecordTypeid = idRecordType);
        insert qsr;
        return qsr;
    }
	
	/*
    * create qualtrics Survey Response record with related contact
    */			
    public static Qualtrics_Survey_Response__c getNewRelatedContactQSR(Related_Contacts__c rc,Id idRecordType){
        Qualtrics_Survey_Response__c qsr = new Qualtrics_Survey_Response__c(
                                                    RelatedContacts__c=rc.id,
                                                    NPS_Score__c=1,
                                                    OSAT_Score__c=2,
                                                    RecordTypeid = idRecordType);
        insert qsr;
        return qsr;
    }
}