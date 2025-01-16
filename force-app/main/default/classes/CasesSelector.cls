/**
 *    @author Ritika Maheshwari
 *    @date   26-05-2018
 *    @description    Class to get the Case records based on different conditions
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------------------------
 *      Developer                      Date                Description
 *      Ritika                        26-May-2018            Initial Version
 *      KD                            25-March-2021        Added fields
 *      KD                            30-April-2021        Create selectCasesFromSetIdsDynamicField
 *      Sarath                        16-June-2021         DCP-47421 - PS Log Query Instrumentation for Service Selectors
 *      Vignesh                       20-Jun-2021          Updated Method selectCases.
 *      Shivani                       24-Aug-2021          DCP-47684 - Add Visibility of Code Types on Case/Work Order
 *      Nishan Shetty                 27-Aug-2021          Added fields in selectCases method for CMCP-32.
 *      Sagar Madkaikar               13-Sep-2021          CMCP-22:Added relocation related fields in SOQL of selectCases() method
 *      Preetha                       09-Mar-2022          QACM-51 Added Sub_Type_c in the query
 *      Rohan Rathod                  23-Mar-2022          Removed Elevation 1.0 fields from selectCases and elevation selector methods
 *      Preetha                       28-Mar-2022          QACM-82 Added selectCasesWithProduct method to get Product details
 *      Gladis                        19-Apr-2022          QACM-14/QACM-672 fetch Cases with No Quality Junction Records
 *      Shahnawaz                     10 June 2022         DCP-51725 Fetch the Cases with dynamic set of fields and condition
 *      Gladis                        21 June 2022         DCP-45368 Added method fetchCaseWithNullIPIds    
 *      Preetha                       31-Aug-2022          QACM-782 Create selectCaseByCaseId to get the case field  
 *      Sagar Madkaikar               30-Aug-2022          DCP-51201:Added fields in SOQL of selectCases() method
 *      Pooja Shalwadi                22-Sep-2022          Added Query Instrumentation 
 *      Priya                         07-Nov-2023          CMCM-301  Added new method selectCasesWithNonNullContact
 *      Siddartha Reddy Kalam         28-Nov-2023          CMCM-3980 Added LWC Related Selectors
 *  -------------------------------------------------------------------------------------------------------------------
 */
public with sharing class CasesSelector extends ilib_SObjectSelector
{
   private static final string  LOG_TITLE = 'CasesSelector';
   private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
   private static final String STRING_ACCOUNT_C = 'AccountId'; //Codescan issue fix
   private static final String STRING_PRODUCT_C = 'SVMXC__Product__c'; //Codescan issue fix
   private static final String STRING_COMPONENT = 'SVMXC__Component__c';//Codescan issue fix

   /**
    *  @author Ritika Maheshwari 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Case.sObjectType;
    }
    
    /**
     *  @author  Ritika Maheshwari 
     *  @description Retrieve list of fields for Case sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            Case.Id,
            Case.CaseNumber,
            Case.Work_Order_Status__c,
            Case.Parts_Order_Status__c,
            Case.IsClosed,
            Case.SVMXC__Product__c,
            Case.AP_Product__c,
            Case.AP_Installed_Product__c,
            Case.Priority,
            Case.Origin,
            Case.OwnerId,
            Case.RecordTypeId,
            Case.Unread_Emails__c,
            Case.SVMXC__Entitlement_Notes__c,
            Case.Description,
            Case.ContactId,
            Case.Has_Additional_Product__c,
            Case.Subject,
            Case.ContactEmail,
            Case.Region__c,
            Case.Logged_In_User_Profile__c,
            Case.Category__c
        };
    }
    
    /**
     *  @author Ritika Maheshwari
     *  @description Fetch the status of parts order and work order associated with the case
     *  @param Parts order ids
     *  @param case ids
     *  @return List of open cases
     */
    public List<Case> selectOpenCases(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenCases', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .setCondition('ID IN : setCaseIds AND Status != \'Closed\'')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
        logger.stop(res.size());

        return res;
    }
    /**
     *  @author Nitin Sood
     *  @description Fetch the Product associated with the case
     *  @param caseIds
     *  @param case ids
     *  @return List of open cases
     */
    public List<Case> selectCases(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCases', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Component__r.Product_Category__c')
            .selectField('SVMXC__Product__r.Product_Category__c')
            .selectField('Owner.Name')
            .selectField('Has_Analysis_Code__c')
            .selectField('Has_Verification_Code__c')
            .selectField('Has_Resolution_Code__c')
            .selectField('Has_Inquiry_Case_Subject_Code__c')
            .selectField('Has_SR_Case_Subject_Code__c')
            .selectField('Has_BI_Case_Subject_Code__c')
            .selectField('PAE_PFA_Evaluation_Required__c')
            .selectField('Record_Type__c')
            .selectField('Work_Order__r.Field_Support_Salesforce_User_Id__c')
            .selectField('Work_Order__r.OwnerId')
            .selectField(STRING_ACCOUNT_C)
            .selectField('Account.ERP_Customer_Id__c')//QACM-78
            .selectField('Account.Name')//QACM-78
            .selectField('RecordType.Name')
            .selectField('Status')
            .selectField('Work_Order__r.SVMXC__Case__c')            
            .selectField(STRING_COMPONENT)
            .selectField('SVMXC__Component__r.Service_Bill_Of_Materials__c')
            .selectField('SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c')             
            .selectField('Has_Closed_Duplicate_WO__c')
            .selectField('Installed_Product_Upgrade_Type__c')
            .selectField('Region__c')
            .selectField('PO__c')
            .selectField('Country__c')
            .selectField('contact.Email')
            .selectField('contact.Phone')
            .selectField('subject')
            .selectField('ProductId')
            .selectField('Follow_up_Needed__c')
            .selectField('Next_Steps__c')
            .selectField('SVMXC__Site__c')    
            .selectField('Account.BillingCountryCode')
            .selectField('Record_Type__c')
            .selectField('SVMXC__Product__r.ProductCode')
            .selectField('SVMXC__Product__r.Name')
            .selectField('SVMXC__Product__r.Service_Product_Type__c')
            .selectField('SVMXC__Component__r.SVMXC__Serial_Lot_Number__c')
            .selectField('SVMXC__Component__r.Name')
            .selectField(STRING_COMPONENT)            
            .selectField('Product_Serial_Number__c') //Added for DCP-46053
            .selectField('Product_Lot_Number__c') //Added for DCP-46053
            .selectField('Work_Order_Status__c')//Added for DCP-45457
            //START DCP-47684
            .selectField('Sub_Type__c')
            .selectField('QA_Review__c')
            .selectField('HasHazardCode__c')
            .selectField('Work_Order__r.Abandoned_Reason__c')
            .selectField('Work_Order__r.SVMXC__Order_Type__c')
            .selectField('Work_Order__r.SVMXC__Product__r.Service_Product_Type__c')
            .selectField('Work_Order__r.SVMXC__Product__r.Regulatory_Type__c')
            .selectField('Work_Order__r.Record_Type__c')
            .selectField('Work_Order__r.Has_Verification_Code__c')
            //END DCP-47684
            //START CMCP-32
            .selectField('Request_Ownership_Status__c')
            .selectField('Ownership_Requested_By__c')
            .selectField('Case_Owner_Role__c')
            //END CMCP-32
            .selectField('ERP_Sales_Order__c') //Added for CMCP-22
            .selectField('CaseNumber') //Added for CMCP-22
            .selectField('Relocated_Location__r.SVMX_PS_External_ID__c') //Added for CMCP-22
            .selectField('Account.ERP_Customer_Id__c') //Added for CMCP-22
            .selectField('SVMXC__Site__r.SVMX_PS_External_ID__c') //Added for CMCP-22
            .selectField('Account.SVMX_PS_Location__r.SVMX_PS_External_ID__c')//Added for CMCP-22
            .selectField('ContactId')//Added for CMCP-22
            .selectField('Origin')//Added for CMCP-22
            .selectField('Installed_Product_Serial_Number__c')//Added for CMCP-22
            .selectField('Account.Name')//Added for CMCP-22
      .selectField('SVMXC__Component__r.Proactive_Connectivity_Status__c')// DCP-44003
            .selectField(STRING_COMPONENT)// DCP-44003
            .selectField('SVMXC__Product__r.Family')//DCP-51587
            .selectField('Order_Line_External_Id__c')//DCP-45368
            //START DCP-51201
            .selectField('Contact.Name')
            .selectField('SuppliedEmail')
            .selectField('Description')
            .selectField('Product_Name__c')
            .selectField('Investigation_Summary_Comments__c')//QACM-88
            //CMCM-11352
            .selectField(STRING_PRODUCT_C)
            .selectField('Subscription__c')
            .selectField('Subscription__r.Product_Name__c')
            .selectField('recordTypeId')
            .setCondition('ID IN : setCaseIds ')
            .selectField('Contact.FirstName')
            .selectField('Contact.LastName')
            .selectField('Contact.Email')
            .selectField('Contact.Phone')
            .selectField('SubscriptionID__c')
            .selectField('Record_Edit_Source__c')
            //END DCP-51201
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank
     *  @description Fetch the cases with Additional Product
     *  @param caseIds
     *  @return List of cases
     */
    public List<Case> selectCasesWithAdditionalProduct(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithAdditionalProduct', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .setCondition('Has_Additional_Product__c = true and ID IN : setCaseIds ')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch the Cases
     *  @param CaseNumber
     *  @return List of cases
     */
    public List<Case> selectCaseForCaseNumber(Set<String> setCaseNumbers) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseForCaseNumber', UtilsCollection.serializeIds(setCaseNumbers));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .setCondition('CaseNumber IN : setCaseNumbers')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
       
    /**
     *  @author Vaibhav
     *  @description Fetch the Cases
     *  @param caseIds
     *  @return List of cases
     */
    public List<Case> selectCasesFromSetIds(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesFromSetIds', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('RecordType.Name')
            .selectField('Status')
            .selectField('Sub_Type__c')//QACM-51
            .selectField('Work_Order__r.SVMXC__Case__c')
            .selectField('owner.type')
            .selectField('Account.ERP_Customer_Id__c')
            .selectField('Owner.Name')
            .setCondition('ID IN : setCaseIds')
            .selectField('Category__c') // G2022-171
            .selectField('Sub_Type__c') // G2022-171
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 

    /**
     *  @author Ritika
     *  @description Fetch the Cases along with Service BOMs assocaited with its IP
     *  @param caseIds
     *  @return List of cases
     */
    public List<Case> selectCasesWithServiceBOM(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithServiceBOM', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField(STRING_COMPONENT)
            .selectField(STRING_PRODUCT_C)
            .selectField('SVMXC__Component__r.Service_Bill_Of_Materials__c')
            .selectField('SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c')
            .setCondition('ID IN : setCaseIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 

    /**
     *  @author Ritika
     *  @description Fetch the Cases along with Region associated with its account
     *  @param caseIds
     *  @return List of cases
     */
    public List<Case> selectCasesWithRegion(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithRegion', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()        
            .setCondition('ID IN : setCaseIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Prashanth
     *  DCP-25229
     *  @description Fetch the cases with Has_Closed_Duplicate_WO__c for specific record type
     *  @param setCaseId, recordtype
     *  @return List of cases
     */
    public List<Case> selectCasesByRecordType(Set<Id> setCaseId, String recordType) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesByRecordType', UtilsCollection.serializeIds(setCaseId) + '|' + recordType);

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Has_Closed_Duplicate_WO__c')
            .setCondition('ID IN :setCaseId'+' AND recordType.Name =:recordType')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Digvijay
     *  @description Fetch the Cases along with IVD Indicator associated with its account
     *  @param caseIds
     *  @return List of cases
     */
    public List<Case> selectCasesRelatedtoIP(Set<Id> setIPIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesRelatedtoIP', UtilsCollection.serializeIds(setIPIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Installed_Product_Upgrade_Type__c')
            .selectField('Status')
            .selectField(STRING_COMPONENT)
            .setCondition(' SVMXC__Component__c IN : setIPIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description Fetch the Cases by ids - DCP-37828
     *  @param String CaseId
     *  @return Case
     */
    public Case selectCaseByCaseId(String caseId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseByCaseId', caseId);
        }

        Case res = (Case) Database.query(
            newQueryFactory()
            .selectField('Region__c')
            .selectField('PO__c')
            .selectField('Country__c')
            .selectField(STRING_ACCOUNT_C)
            .selectField('Account.BillingCountryCode')
            .selectField(STRING_PRODUCT_C)
            .selectField('SVMXC__Component__r.SVMXC__Serial_Lot_Number__c')
            .selectField('Product_Serial_Number__c')
            .selectField('Installed_Product_Serial_Number__c')    
            .selectField('Contact.Contact_Record_Type__c') //QACM-175
            .selectField('Contact.OtherPhone') //QACM-175
            .selectField('Contact.Full_Name_Local__c') //QACM-175
            .selectField('Contact.Name') //QACM-175
            .selectField('Contact.Alternate_Email__c') //QACM-175
            .selectField('Contact.OtherCountry') //QACM-175
            .selectField('Contact.OtherCountryCode') //QACM-175
            .selectField('Contact.OtherStreet') //QACM-175
            .selectField('Contact.OtherCity') //QACM-175
            .selectField('Contact.OtherState') //QACM-175
            .selectField('Contact.OtherPostalCode') //QACM-175
            .selectField('Contact.CreatedBy.Name') //QACM-175
            .selectField('Contact.LastModifiedBy.Name') //QACM-175
            .selectField('Id') //QACM-175
            .setCondition('ID = : caseId')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res == null ? 0 : 1);
        }

        return res;
    }

    /**
     *  @author Sravan
     *  @description DCP-40120: Fetch the Cases by id set
     *  @param String caseIdSet
     *  @return Case list
     */
    public List<Case> selectCasesByCaseIdSet(Set<Id> caseIdSet) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesByCaseIdSet', UtilsCollection.serializeIds(caseIdSet));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField(STRING_ACCOUNT_C)
            .setCondition('Origin =\'Email - CS\' AND ID IN : caseIdSet')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Vaibhav
     *  @description DCP-46141: Fetch the Cases by id set
     *  @param set caseIdSet
     *  @return Case list
     **/
    public List<Case> selectCasesByCaseIdSetForQualtrics(Set<Id> caseIdSet) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
        logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesByCaseIdSetForQualtrics', UtilsCollection.serializeIds(caseIdSet));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Contact.FirstName')
            .selectField('Contact.LastName')
            .selectField('Contact.Email')
            .selectField('Contact.Phone')
            .selectField('case_owner_name__c')
            .selectField('date_time_completed__c')
            .selectField('country__c')
            .selectField('region__c')
            .selectField('category__c')
            .selectField('district__c')
            .selectField('case_owner_role__c')
            .selectField(STRING_ACCOUNT_C)
            .selectField('svmxc__component__c')
            .selectField('case_owner_s_manager_email__c')
            .selectField('ivd_product_identifier__c')
            .selectField('ivd_product_identifier_additional_prod__c')
            .selectField('case_owner_manager__c')
            .selectField('product_group__c')
            .selectField('WeChatFollower__c')
            //Start DCP-49920
            .selectField('Subject')
            .selectField('Description')
            //End DCP-49920
            .selectField('WeChatFollower__r.Email__c') //DCP-49913
            .setCondition('ID IN : caseIdSet').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;    
        
    }
    /**
     *  @author KD
     *  @description MS team integration dynamic Case query
     *  @param Set caseIdSet, Set of fields
     *  @return Case list
     */
    public List<Case> selectCasesFromSetIdsDynamicField(Set<Id> setCaseIds, Set<String> setFieldUpdate) 
    {
        ilib_QueryFactory objQueryFactory = newQueryFactory();
        for(String strField : setFieldUpdate)
            objQueryFactory.selectField(strField);
        objQueryFactory.setCondition('ID IN : setCaseIds');
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesFromSetIdsDynamicField', UtilsCollection.serializeIds(setCaseIds) + '|' + UtilsCollection.serializeIds(setFieldUpdate));

        List<Case> res = (List<Case>) Database.query(
            objQueryFactory.toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
     /**
     *  @author Preetha[QACM-82]
     *  @description Fetch the Cases Product details
     *  @param caseIds
     *  @return List of cases
     */
    public List<Case> selectCasesWithProduct(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithProduct', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField(STRING_PRODUCT_C)
            .selectField('SVMXC__Product__r.Regulatory_Type__c')
            .setCondition('ID IN : setCaseIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /*
    *  @AUTHOR: Gladis
    *  @DESCRIPTION: QACM-14/QACM-672 fetch Cases with No Quality Junction Records
    *  @PARAM : setCaseIds
    *  @RETURN: List<Case>
    */
    public List<Case> selectCasesWithNoQualityJunctionRecords(Set<Id> setCaseIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithNoQualityJunctionRecords', UtilsCollection.serializeIds(setCaseIds));
        }
        ilib_QueryFactory caseQuery = newQueryFactory();
        caseQuery.selectField('Id');
        ilib_QueryFactory objQRJSelector = new QualityRecordJunctionSelector().addQueryFactorySubselect(caseQuery,'Quality_Record_Junctions__r');
        objQRJSelector.selectField('Id');
        
        List<Case> res = (List<Case>) Database.query(
            caseQuery
            .setCondition('ID IN : setCaseIds')
            .toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    } 
    
    /**
     *  @author Shahnawaz[DCP-51725]
     *  @description Fetch the Cases with dynamic set of fields and condition
     *  @param setCaseIds,setFieldUpdate,strCondition
     *  @return List of cases
     */
    public List<Case> selectCasesWithDynamicFieldsAndCondition(Set<Id> setCaseIds,Set<Id> setAccConIPIds, Set<String> setFieldUpdate,Set<String> setStatus,String strCondition,DateTime eightHoursPastDate,DateTime eightHoursFutureDate) {
        ilib_QueryFactory objQueryFactory = newQueryFactory();
        for(String strField : setFieldUpdate) {
            objQueryFactory.selectField(strField);
        }
        objQueryFactory.setCondition(strCondition);
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithDynamicFieldsAndCondition', UtilsCollection.serializeIds(setCaseIds) + '|' + UtilsCollection.serializeIds(setFieldUpdate));
        }
        List<Case> res = (List<Case>) Database.query(
            objQueryFactory.toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /**  @author Gladis
     *  @description DCP-45368 Fetch Case Ids with Null Installed Product Ids
     *  @return  List<Case>
     **/
    public List<Case> fetchCaseWithNullIPIds(set<Id> setCaseIds) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.fetchCaseWithNullIPIds', UtilsCollection.serializeIds(setCaseIds));
        } 
        List<Case> res = (List<Case>) Database.query(
             newQueryFactory()
            .selectField('Id')
            .selectField(STRING_COMPONENT)
            .selectField('Order_Line_External_Id__c')
            .setCondition('Id IN :setCaseIds AND SVMXC__Component__c = null')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /**
     *  @author Preetha
     *  @description Fetch the Cases by ids - QACM-782
     *  @param String CaseId
     *  @return Case
     */
    public List<Case> selectCasesByCaseId(Id caseId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseByCaseId', caseId);
        }

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('RecordTypeId')   
            .selectField('Logged_In_User_Profile__c')
            .selectField('PO__c')
            .selectField(STRING_ACCOUNT_C)
            .selectField('Work_Order__c')    
            .selectField('Status')  
            .selectField('OwnerId')
            .selectField(STRING_PRODUCT_C)
            .setCondition('ID = : caseId')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /**
     *  @author Priya
     *  @description Fetch the Cases by ids when Account and Contact in not null
     *  @param String CaseId
     *  @return Case
     */
    public List<Case> selectCasesWithNonNullContact(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithNonNullContact', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('ContactId')
            .selectField(STRING_ACCOUNT_C)
            .setCondition('ID IN :setCaseIds AND ContactId != null AND AccountId != null')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
     *  @author Siddartha Reddy Kalam
     *  @description Fetch the AccountId by case id     
     *  @param String CaseId
     *  @return AccountId from Case
     */
    public List<Case> selectAccountByCaseId(String caseId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountByCaseId', caseId);
        }

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField(STRING_ACCOUNT_C)   
            .setCondition('ID = : caseId')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /**
      * CMCM-8106
     *  @author Nitin Zagade
     *  @description Fetch the Cases by ids with IVD_Product_Identifier_Additional_Prod__c
     *  @param String CaseId
     *  @return Case
     */
    public List<Case> selectCasesWithCaseID(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesWithNonNullContact', UtilsCollection.serializeIds(setCaseIds));

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('IVD_Product_Identifier_Additional_Prod__c')
            .setCondition('ID IN :setCaseIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	 /**
     *  @author Gaurav
     *  @description Retrieve list of fields for case object
     *  @return list of case
     **/
	 public List<Case> getCaseId(Set<Id> caseIdset)
    {
        return (List<Case>) Database.query(
        newQueryFactory().selectField('Id').selectField(STRING_COMPONENT).selectField('SVMXC__Product__c').setCondition('Id IN :caseIdset').toSOQL());
    } 

	/**
     *  @author Gaurav
     *  @description Retrieve list of fields for case object
     *  @return list of case
     **/
	 public List<Case> getCaseDetails(Set<Id> parentCaseIds)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getCaseDetails', UtilsCollection.serializeIds(parentCaseIds));
        }

        List<Case> res = (List<Case>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('OwnerId')
            .setCondition('Id IN :parentCaseIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}