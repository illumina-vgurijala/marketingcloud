/**
*    @author Joshith k
*    @date  21 Aug 2019
*    @description  Lead Selector class
*    Modification Log:
*	 @Test Class Name:TestSoftwareDownloadDataReceiver
*    ------------------------------------------------------------------------------------
*    Developer                  Date                   Description
*    Rahul Bishnoi              1/7/2019               Fetch the Leads based on PGUID - DCP - 31268
*    Deep Diwakar             July 14 2021             DCP-47095: Adding SOQL instrumentation for all selector queries with
*                                                                 feature flag implementation.
*    Deep Diwakar             June-26-2024             CMCM-6457: Added selector method for converted lead with waterfall fields
*    Deep Diwakar             Jul-29-2024              CMCM-7519: Added selector method for querying leads using task whoid field
*    Deep Diwakar             Aug-08-2024              CMCM-9421: Added selector method for querying lead fields to move to campaign member
*    ------------------------------------------------------------------------------------
*
*/
public with sharing class LeadsSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'LeadsSelector';
    private static final String STRMARKETINGQUERYLOGS = 'MarketingQueryLogs';
    
    /**Method - Get sobjectType */
    public Schema.SObjectType getSObjectType()
    {
        return Lead.sObjectType;
    }

    /**
     *  @author  Joshith k
     *  @description Retrieve list of fields for Software_Download__c sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Lead.Id,
           Lead.Email,
            //DCP-31268
           Lead.PGUID__c,
		   Lead.Country,
           Lead.CountryCode,
           Lead.FirstNameLocal,
           Lead.LastNameLocal,
		   Lead.OwnerId
       };
    }


    private Boolean removeDefaultOrderBy=false;
     /**
    *  @author Joshith K
    *  @description Override Default name Ordering
    *
    *  @return String for Ordering
    **/
    public override String getOrderBy() {
        if(removeDefaultOrderBy){
            return 'LastModifiedDate DESC';
        }else{
            return super.getOrderBy();
        }

    }
    /**
    *  @author Rahul Bishnoi
    *  @description Fetch the Leads based on PGUID
    *  @param Set of PGUID Ids
    *  @return List of Leads
    **/
    public List<Lead> selectLeadsForPGUID(Set<String> setPGUID)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLeadsForPGUID',UtilsCollection.serializeIds(setPGUID));
        }

        removeDefaultOrderBy=TRUE;
        List<Lead> res = (List<Lead>) Database.query(
                    newQueryFactory().setCondition('Lead.PGUID__c IN :setPGUID').toSOQL()
        );


        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /*
    * @author  Joshith k
    * @date 21-Aug-2019
    * @description Fetch list of Leads with Software Downloads for Set of Emails
    * @param Set of  Email Ids
    *
    */
    public List<Lead> selectLeadsWithSftwDwnldByEmail(Set<String> setLeadEmails)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLeadsWithSftwDwnldByEmail',UtilsCollection.serializeIds(setLeadEmails));
        }


        removeDefaultOrderBy=TRUE;
        ilib_QueryFactory leadQuery = newQueryFactory();
        leadQuery.selectField('FirstName');
        leadQuery.selectField('LastName');
        leadQuery.selectField('Country');
        leadQuery.selectField('Country_Local__c');

        ilib_QueryFactory softwareQueryFactory = new SoftwareDownloadsSelector().
        addQueryFactorySubselect(leadQuery,'Software_Downloads__r');
        List<Lead> res = (List<Lead>) Database.query(
            leadQuery.setCondition('Email in :setLeadEmails').toSOQL());

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /* @author     : Monika
     * @param      : List of Lead Ids
     * @return     : List of Lead Record
     * @Description: Method that returns list of contacts with Id,ConvertContactId,Is AutoConversion In Progress,Is AutoMerge In Progress.
    **/
    public List<Lead> returnAutoConvertMergeCheckbox(List<Id> leadId)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.returnAutoConvertMergeCheckbox',UtilsCollection.serializeIds(new Set<Id>(leadId)));
        }

        ilib_QueryFactory leadQuery = newQueryFactory();
        leadQuery.selectField('Id');
        leadQuery.selectField('ConvertedContactId');
        leadQuery.selectField('ConvertedAccount.Name');
        leadQuery.selectField('Is_AutoConversion_In_Progress__c');
        leadQuery.selectField('Is_AutoMerge_In_Progress__c');
        leadQuery.selectField('CreatedDate');
        List<Lead> res = (List<Lead>)Database.query(leadQuery.setCondition('Id in :leadId').toSOQL());

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /* @author     : Prashanth
     * @param      : List of Lead Ids
     * @return     : List of Lead Records
     * @Description: Method that returns list of contacts which are not converted yet.
    **/
    public List<Lead> returnNonConvertedLeads(List<Id> leadId)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.returnNonConvertedLeads',UtilsCollection.serializeIds(new Set<Id>(leadId)));
        }

        List<Lead> res = (List<Lead>)Database.query(newQueryFactory().setCondition('Id in :leadId AND IsConverted = false').toSOQL());

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of lead ids
     * @return     : List of lead records
     * @Description: retuns list of converted lead with waterfall fields. It only queries fields specified in the method, doesn't
     *               query default fields. 
    **/
    public List<Lead> selectConvertedLeadsWithWaterfall(Set<Id> setLeadIds) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(STRMARKETINGQUERYLOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectConvertedLeadsWithWaterfall',UtilsCollection.serializeIds(setLeadIds));
        }

        List<Lead> res = (List<Lead>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField('ConvertedContactId')
                                .selectField('Waterfall_Stage__c')
                                .selectField('Waterfall_Engaged_Date__c')
                                .selectField('Waterfall_Qualified_Date__c')
                                .selectField('Waterfall_Sales_Accepted_Date__c')
                                .selectField('Waterfall_Opportunity_Date__c')
                                .selectField('Waterfall_Closed_Won_Date__c')
                                .selectField('Last_Responded_Campaign_Date__c')
                                .selectField('Last_Responded_Campaign__c')
                                .setCondition('Id IN : setLeadIds AND IsConverted = true').toSOQL());

        if (Feature.isOn(STRMARKETINGQUERYLOGS)) {
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of lead ids
     * @return     : List of lead records
     * @Description: retuns list of leads with field values needed for Marketing task updates. It only queries
     *               fields specified in the method, doesn't query default fields.
    **/
    public List<Lead> selectLeadFieldsForTask(Set<Id> setLeadIds) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(STRMARKETINGQUERYLOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLeadFieldsForTask',UtilsCollection.serializeIds(setLeadIds));
        }

        List<Lead> res = (List<Lead>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField('Product_Interest__c')
                                .selectField('Form_Type__c')
                                .selectField('Last_Form_Submission_URL__c')
                                .selectField('Questions_For_Rep__c')
                                .setCondition('Id IN : setLeadIds AND IsConverted = false').toSOQL());

        if (Feature.isOn(STRMARKETINGQUERYLOGS)) {
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of lead ids
     * @return     : List of lead records
     * @Description: retuns list of leads with field values needed for moving to corresponding campaign members. 
     *               It only queries fields specified in the method, doesn't query default fields.
    **/
    public List<Lead> selectLeadsForCampMemberFields(Set<Id> setLeadIds) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(STRMARKETINGQUERYLOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLeadsForCampMemberFields',UtilsCollection.serializeIds(setLeadIds));
        }

        List<Lead> res = (List<Lead>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField('Email')
                                .selectField('Form_Type__c')
                                .selectField('Campaign_Attribution__c')
                                .selectField('Media_Code__c')
                                .setCondition('Id IN : setLeadIds AND IsConverted = false').toSOQL());

        if (Feature.isOn(STRMARKETINGQUERYLOGS)) {
            logger.stop(res.size());
        }

        return res;

    }

}