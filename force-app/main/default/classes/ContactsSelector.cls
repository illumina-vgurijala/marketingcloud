/**
*    @author Roopal Verma
*    @date   2018-09-29
*    @description    DCP-11367: Contact Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rahul Bishnoi                 1/7/2019            Fetch the Leads based on PGUID - DCP - 31268
*             Arnab Modak                   20/11/2019          DCP-30953 : Ordered query by "Last Modified" - selectContactsFromAccount()
*             Gopinath Reddy                8/1/2020            DCP-30474 Logic
*             Deep Diwakar                 16-April-2021        DCP-45348: Added customer community contact selector method
*             Deep Diwakar                 July 14 2021         DCP-47095: Adding SOQL instrumentation for all selector queries with
*                                                                 feature flag implementation.
              Saddam Hussain               Aug 23 2021          CMCP-33 Added New Field to Soql to selectLoggedInAccountContacts methodtest
*             Deep Diwakar                 Jan-02-2024          CMCM-4697: Added selector method to query contact with AOW
*             Deep Diwakar                 June-26-2024         CMCM-6457: Added selector method for contacts with waterfall fields
*             Deep Diwakar                 Jul-29-2024          CMCM-7519: Added selector method for querying contacts using task whoid field
*             Deep Diwakar                 Aug-08-2024          CMCM-9421: Added selector method for querying contact fields to move to campaign member
*    ------------------------------------------------------------------------------------
*
*/
public with sharing class ContactsSelector extends ilib_SObjectSelector{

    private final String LOG_TITLE = 'ContactsSelector';
    private static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';
    private static final String FIELDS_ACCOUNDID = 'AccountId';
    private static final String EMAIL = 'Email';

    /**Method - get sObjectType */
    public Schema.SObjectType getSObjectType()
    {
        return Contact.sObjectType;
    }

    /**
    *  @author  Roopal Verma
    *  @description Retrieve list of fields for Contact Object
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Contact.id,
            Contact.Email,
            Contact.name,
            Contact.Phone,
			Contact.Is_Active__c,
			Contact.AccountId,
            Contact.Country_Local__c,
            //DCP-30953
           Contact.LastModifiedDate,
           Contact.AccountId,
           Contact.Is_Active__c,
           Contact.Country_Local__c,
           //DCP-30474
           Contact.PGUID__c

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
    *  @author Roopal Verma
    *  @description Fetch the Contact
    *  @param Set of Account Ids
    *  @return List of Contacts
    **/
    public List<Contact> selectContactsFromAccount(Set<Id> setAccountId)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactsFromAccount',UtilsCollection.serializeIds(setAccountId));
        }

        List<Contact> res = (List<Contact>) Database.query(
                                    newQueryFactory().setCondition('Contact.AccountId IN :setAccountId').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
        }

    /**
    *  @author Roopal Verma
    *  @description Fetch the Contact
    *  @param Set of Account Ids
    *  @return List of Contacts
    **/
    public List<Contact> selectContacts(Set<Id> setContactId)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContacts',UtilsCollection.serializeIds(setContactId));
        }

        List<Contact> res = (List<Contact>) Database.query(
                                    newQueryFactory()
                                    .selectField('Id')
                                    .selectField('Is_Active__c')
                                    .selectField(FIELDS_ACCOUNDID)
                                    .selectField('email')
                                    .selectField('Account.Territory_Region__c')
                                    .selectField('Account.District__c')
                                    //Refactor PB:: Work_Order_Update_Contact_Preferred_Language
                                    .selectField('Preferred_Language__c')
                                    .selectField('FirstName')
                                    .selectField('LastName')
                                    .selectField('MailingCountry')
                                    .selectField('Country_Local__c')
                                    .setCondition('Id IN :setContactId').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /*
    * @author Shaik Moulali
    * @date   10-08-2018
    * @description Fetch list of contacts for logged in Account and based partner portal status
    * @param Pass the Logged In user's Id
    *
    */
    public List<Contact> selectLoggedInAccountContacts(Id accountId, String partnerPortalStatus)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            Set<Id> acctIdSet = new Set<Id>();
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLoggedInAccountContacts',UtilsCollection.serializeIds(acctIdSet));
        }

        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('AccountId = :accountId AND Partner_Portal_Status__c = :partnerPortalStatus');
        String strQuery = query.selectField('id')
            .selectField('Name')
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('Title')
            .selectField('Email')
            .selectField('Partner_Portal_Status__c')
            .selectField(FIELDS_ACCOUNDID)
            .selectField('CreatedDate')
            .selectField('LastModifiedDate')
            .selectField('Portal_User_Role__c')         //cmcp-33 added new role field
        .toSOQL();
        List<Contact> res = Database.query(strQuery);

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /*
    * @author Ritika M
    * @date
    * @description Fetch list of contacts for corresponding email addressed
    * @param Set of email addresses
    *
    */
    public List<Contact> selectContactsByEmail(Set<String> setContactEmails)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactsByEmail',UtilsCollection.serializeIds(setContactEmails));
        }

        List<Contact> res = (List<Contact>) Database.query(
                                    newQueryFactory().setCondition('Email IN : setContactEmails').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }


	 /*
    * @author Prakhar K
    * @date 05-Dec-2019
    * @description Fetch contact fields based on web email of Case
    * @param Set of WebEmail addresses on Case object
    *
    */
    public List<Contact> contactsByEmailID(Set<String> setEmails)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.ContactsByEmailID',UtilsCollection.serializeIds(setEmails));
        }

        List<Contact> res = (List<Contact>) Database.query(
                                    newQueryFactory().setCondition('Is_Active__c = true AND Email IN : setEmails').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }


     /*
    * @author Joshith K
    * @date 16-Aug-2019
    * @description Fetch list of contacts and Child Software Downloads for corresponding  email addressed
    * @param Set of email addresses
    *
    */
    public List<Contact> selectContactsWithSftwDwnldByEmail(Set<String> setContactEmails)
    {

        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactsWithSftwDwnldByEmail',UtilsCollection.serializeIds(setContactEmails));
        }

        removeDefaultOrderBy=TRUE;
         ilib_QueryFactory contactQuery = newQueryFactory();
         contactQuery.selectField('FirstName');
         contactQuery.selectField('LastName');
         contactQuery.selectField('MailingCountry');
         contactQuery.selectField('Country_Local__c');
        ilib_QueryFactory softwareQueryFactory = new SoftwareDownloadsSelector().
        addQueryFactorySubselect(contactQuery,'Software_Downloads__r');
        List<Contact> res = (List<Contact>) Database.query(
            contactQuery.setCondition('Email in :setContactEmails').toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /**
    *  @author Gopinath
    *  @description Fetch COntact ids to replace pguid ids.
    *  @return List of Contact Ids
    **/
   public List<Contact> selectContactIdsforPGUIDId(set<String> setSapPGUIDIds)
   {
       ilib_LogQuery logger;

       if (Feature.isOn(MARKETING_QUERY_LOGS)){
           logger = new ilib_LogQuery(LOG_TITLE + '.selectContactIdsforPGUIDId',UtilsCollection.serializeIds(setSapPGUIDIds));
       }

       List<Contact> res = (List<Contact>) Database.query(
           newQueryFactory().setCondition('PGUID__c IN : setSapPGUIDIds').toSOQL()
       );

       if (Feature.isOn(MARKETING_QUERY_LOGS)){
           logger.stop(res.size());
       }

       return res;
   }
  /* @author     : Prashanth
	 * @param      : contact Ids
	 * @return     : List of contact Records
	 * @Description: Method that returns list of contacts with AccountcontactRelations assigned to those contacts.
	 **/
    public List<Contact> returnContactWithACRDetails(Set<Id> setContactIds){
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.returnContactWithACRDetails',UtilsCollection.serializeIds(setContactIds));
        }

        ilib_QueryFactory contactQuery = newQueryFactory();
        contactQuery.selectField('Account.Ultimate_Parent_Id__c');
        ilib_QueryFactory acrSubQuery = new AccountContactRelationsSelector().addQueryFactorySubselect(contactQuery,'AccountContactRelations');
        acrSubQuery.selectField('IsDirect');
        List<Contact> res = (List<Contact>)Database.query(contactQuery.setCondition('Id in:setContactIds').toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }
   /* @author     : Monika
     * @param      : contact Ids
     * @return     : Contact Record
     * @Description: Method that returns list of contacts with Account Billing Country.
     **/
    public  Contact returnAccountBillingCountry(Id contactId)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            Set<Id>contactIdSet = new Set<Id>();
            contactIdSet.add(contactId);
            logger = new ilib_LogQuery(LOG_TITLE + '.returnAccountBillingCountry',UtilsCollection.serializeIds(contactIdSet));
        }

        ilib_QueryFactory contactQuery = newQueryFactory();
        contactQuery.selectField('Account.BillingCountry');
    contactQuery.selectField('FirstNameLocal');
        contactQuery.selectField('LastNameLocal');
        Contact res = (Contact)Database.query(contactQuery.setCondition('Id = :contactId').toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop();
        }

        return res;
    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of email ids
     * @return     : Contact Record
     * @Description: Method that returns list of contacts for customer community specific fields using
                     email id as filter criteria.
    **/
    public List<Contact> selectCustomerCommunityContactsByEmail(Set<String> emailSet) {
        ilib_LogQuery logger;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCustomerCommunityContactsByEmail',UtilsCollection.serializeIds(emailSet));
        }

        List<Contact> res = (List<Contact>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField('FirstName')
                                .selectField('LastName')
                                .selectField(EMAIL)
                                .selectField(FIELDS_ACCOUNDID)
                                .selectField('PGUID__c')
                                .selectField('Partner_Portal_Status__c')
                                .setCondition('Email IN : emailSet').setLimit(1000).toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of account ids
     * @return     : List of Contact Record
     * @Description: retuns list of contacts with AOW values. It only queries fields specified in the method, doesn't
     *               query default fields. 
    **/
    public List<Contact> selectContactWithAow(Set<Id> setAccountId) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactWithAow',UtilsCollection.serializeIds(setAccountId));
        }

        List<Contact> res = (List<Contact>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField(FIELDS_ACCOUNDID)
                                .selectField('Area_Of_Work__c')
                                .setCondition('Contact.AccountId IN : setAccountId').setLimit(1000).toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of contact ids
     * @return     : List of Contact Record
     * @Description: retuns list of contacts with waterfall field values. It only queries fields specified in the method, doesn't
     *               query default fields. 
    **/
    public List<Contact> selectContactsWithWaterfall(Set<Id> setContactIds) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactsWithWaterfall',UtilsCollection.serializeIds(setContactIds));
        }

        List<Contact> res = (List<Contact>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField('Waterfall_Stage__c')
                                .selectField('Waterfall_Engaged_Date__c')
                                .selectField('Waterfall_Qualified_Date__c')
                                .selectField('Waterfall_Sales_Accepted_Date__c')
                                .selectField('Waterfall_Opportunity_Date__c')
                                .selectField('Waterfall_Closed_Won_Date__c')
                                .selectField('Last_Responded_Campaign_Date__c')
                                .selectField('Last_Responded_Campaign__c')
                                .setCondition('Id IN : setContactIds').toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of contact ids
     * @return     : List of contact records
     * @Description: retuns list of contacts with field values needed for Marketing task updates. It only queries
     *               fields specified in the method, doesn't query default fields.  
    **/
    public List<Contact> selectContactFieldsForTask(Set<Id> setContactIds) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactFieldsForTask',UtilsCollection.serializeIds(setContactIds));
        }

        List<Contact> res = (List<Contact>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField('Product_Interest__c')
                                .selectField('Form_Type__c')
                                .selectField('Last_Form_Submission_URL__c')
                                .selectField('Questions_For_Rep__c')
                                .setCondition('Id IN : setContactIds').toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of contact ids
     * @return     : List of contact records
     * @Description: retuns list of contacts with field values needed for moving to corresponding campaign members. 
     *               It only queries fields specified in the method, doesn't query default fields.  
    **/
    public List<Contact> selectContactsForCampMemberFields(Set<Id> setContactIds) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactsForCampMemberFields',UtilsCollection.serializeIds(setContactIds));
        }

        List<Contact> res = (List<Contact>) Database.query(newQueryFactory(false)
                                .selectField('Id')
                                .selectField(EMAIL)
                                .selectField('Form_Type__c')
                                .selectField('Campaign_Attribution__c')
                                .selectField('Media_Code__c')
                                .setCondition('Id IN : setContactIds').toSOQL());

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;

    }

}