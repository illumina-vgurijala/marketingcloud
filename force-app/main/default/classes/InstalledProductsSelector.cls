/**
 *    @author Debanka Chakraborty
 *    @date   11-07-2018
 *    @description    Class to get the Installed Product records based on different conditions
 *    @Test Class - TestInstalledProductsSelector
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      Debanka                         11-July-2018        Initial Version
 *      Gopinath Reddy                  28-Jan-2020         DCP-32166 : Checking LIMS/DRAGEN Products
 *      KD                              3- March            DCP-43163 : Added method selectLoanerInstalledProductById
 *      KD                              2021-05-05          DCP-45742 Add newmethod selectInstalledProductByAccountAndSerialNumber
 *      KD                              31-May-2021         DCP-38933 : Added new field and query instrumention on selectInstallProductsForEquipmentIds
 *      Sarath                          18-June-2021        DCP-47421 - PS Log Query Instrumentation for Service Selectors
 *      Vignesh                         16-Sep-2021         DCP-49744: Method selectChildInstalledProduct Created
 *      Rohan                           15-Mar-2022         DCP-49682   Elevation 1.0 Code removal
 *      Sagar Madkaikar                 27-Sep-2021         CMCP-81 - Added field in selectRelatedInstalledProducts()
 *      Gladis                          17-Jun-2022         DCP-45368 Added method selectInstalledProductsFromEquipmentId 
 *      Sagar Madkaikar                 21-Jul-2022         DCP-54367 - Added method getIPWithAttributeTemplateInstance()
 *      Shivani Jain                    16-Sep-2022         DCP-52682 - Added method selectIPsWithAttributeHistory()
 *      Siddartha Reddy Kalam           28-Nov-2023         CMCM-3980 Added LWC Related Selectors
 *      Dhairya Shah                    1st-March-2024      CMCM-5309
 *    --------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class InstalledProductsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'InstalledProductsSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final string STRING_PRODUCT_NAME = 'SVMXC__Product__r.Name';
    private static final string STRING_SITE = 'SVMXC__Site__c';
    private static final string STRING_PRODUCT = 'SVMXC__Product__c';
    private static final string STRING_ASSET_TAG = 'SVMXC__Asset_Tag__c'; // CMCM-8089
    private static final string STRING_STATUS ='SVMXC__Status__c';
    private static final string STRING_COMPANY ='SVMXC__Company__c';
    private static final string STRING_ERP_CUSTOMER_ID ='SVMXC__Company__r.ERP_Customer_Id__c'; //CMCM-12852 codescan fix
    /*US : CMCM-5309
    @description Added public string variable Instrument for "selectIPsWithAccountIdandSearch" methods */
    private static final String INSTRUMENT_KEY = 'Instrument'; 
    private static final String INSTRUMENT_KEYWORD = '\'' + String.escapeSingleQuotes(INSTRUMENT_KEY) + '\'';

    
    /**
     *  @author Debanka
     *  @description
     *  @return SObjectType The Schema.SObjectType of the proposal
     */
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Installed_Product__c.sObjectType;
    }

    /**
     *  @author  Debanka
     *  @description Retrieve list of fields for SVMXC__Installed_Product__c sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        
        return new List<Schema.SObjectField> {
            SVMXC__Installed_Product__c.Id,
            SVMXC__Installed_Product__c.Name,
            SVMXC__Installed_Product__c.SVMXC__Product__c,
            SVMXC__Installed_Product__c.SVMXC__Company__c,
            SVMXC__Installed_Product__c.ERP_Equipment_ID__c,
            SVMXC__Installed_Product__c.Acceptance_Date__c,
            SVMXC__Installed_Product__c.SVMXC__Sales_Order_Number__c,
            SVMXC__Installed_Product__c.SVMXC__Serial_Lot_Number__c,
            SVMXC__Installed_Product__c.SVMXC__Date_Installed__c,
            SVMXC__Installed_Product__c.SVMXC__Site__c,
            SVMXC__Installed_Product__c.Service_Product_Type__c,
            SVMXC__Installed_Product__c.Last_PM_Date__c  //DCP-47459
        };
    }

    // Returns list of installed products from id
	
    /**
     *  @author  Debanka
     *  @description Retrieve list of fields for Installed Product sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
	 **/
    public List<SVMXC__Installed_Product__c> selectRelatedInstalledProducts(Set<Id> setIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectRelatedInstalledProducts', UtilsCollection.serializeIds(setIds));

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Site__c')
            .selectField('Latest_Loaner_Agreement_Signature_Date__c')
            .selectField('Installed_Product_Upgrade_Type__c')
            .selectField('Last_Upgrade_Date__c')
            .selectField('Upgrade_Type__c')
            .selectField(STRING_PRODUCT)
            .selectField('SVMXC__Product__r.Product_Group__c')
            .selectField('Service_Bill_Of_Materials__r.Name')
            .selectField('SVMXC__Product__r.ProductCode')
            .selectField(STRING_PRODUCT_NAME)
            .selectField('Asset_Type__c')
            .selectField(STRING_STATUS)
            .selectField('SVMXC__Service_Contract__c')
            .selectField('SVMXC__Product__r.Informatics_Family__c')
            .selectField('SVMXC__Product__r.Informatics_SKU_Type__c')
            .selectField('SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c')
            .selectField('Currently_Active_Service_Contract__r.SVMXC__Service_Level__c')
            .selectField('SVMXC__Service_Contract__r.Custom_License_Flag__c')
            .selectField('SVMXC__Service_Contract__r.Dragen_Connectivity__c')
            .selectField('SVMXC__Site__r.ERP_Customer_ID__c')
            .selectField(STRING_ERP_CUSTOMER_ID)         
            .selectField('Operation_Status__c')
            .selectField('SVMXC__Serial_Lot_Number__c')//Added for CMCP-81
			.selectField('RecordTypeId')// Added for DCP-52308
			.selectField('createdByID')// Added for DCP-52308
            .selectField(STRING_COMPANY) // Added as part of CMCM-263 
            .setCondition('Id IN :setIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author Nitin Sood
     * @date   08-10-2018
     * @description Fetch Install Products on basis of ERP_Equipment_Id
     */
    public List<SVMXC__Installed_Product__c> selectInstallProductsForEquipmentIds(Set<String> setEquipmentIds)
    {
        ilib_LogQuery logger=null;
        if (Feature.isOn(SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectInstallProductsForEquipmentIds',
            UtilsCollection.serializeIds(setEquipmentIds)
        );
         String strQuery= newQueryFactory()
            .selectField(STRING_STATUS)
            .selectField('SVMXC__Service_Contract__c')
            .selectField('SVMXC__Product__r.Informatics_Family__c')//DCP-32166
            .selectField('SVMXC__Product__r.Informatics_SKU_Type__c')//DCP-32166
            .selectField('SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c')
            .selectField('SVMXC__Service_Contract__r.Custom_License_Flag__c')
            .selectField('SVMXC__Service_Contract__r.Dragen_Connectivity__c')
            .selectField('SVMXC__Product__r.Auto_Create_Billable_Work_Order__c') // DCP-38933
            .selectField(STRING_PRODUCT_NAME) // DCP-38933
            .selectField(STRING_ERP_CUSTOMER_ID) // DCP-38933
            .setCondition('ERP_Equipment_ID__c IN :setEquipmentIds')
            .toSOQL();

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(strQuery);
        if (Feature.isOn(SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
    }

    /**
     * @author Todd Newman
     * @date   04-11-2019
     * @description
     * @param accountIds
     */
    public List<SVMXC__Installed_Product__c> selectByAccountIds(Set<Id> accountIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByAccountIds', UtilsCollection.serializeIds(accountIds));

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory(true)
            .selectField(STRING_PRODUCT_NAME)
            .selectField('SVMXC__Product__r.Apttus_Config2__ProductType__c')
            .setCondition('SVMXC__Company__c IN :accountIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author Mandeep Singh
     * @date   08-13-2018
     * @description  Fetch Install Products fields on basis of record Id
     * @param setIds - Set of Installed Product IDs
     */
    public List<SVMXC__Installed_Product__c> selectInstalledProductsFromIds(Set<Id> setIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstalledProductsFromIds', UtilsCollection.serializeIds(setIds));

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Site__r.ERP_Customer_ID__c')
            .selectField(STRING_ERP_CUSTOMER_ID)
            .selectField(STRING_STATUS) 
            .setCondition('Id IN :setIds') 
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author Vaibhav Parashar
     * @date   08-16-2018
     * @description Fetch Install Products on basis of Serial/Lot Number. Added for defect DCP[9512].
     * @param setSerialLotNumbers
     */
    public List<SVMXC__Installed_Product__c> selectInstallProductsForSerialLotNumber(Set<String> setSerialLotNumbers)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstallProductsForSerialLotNumber', UtilsCollection.serializeIds(setSerialLotNumbers));

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__Serial_Lot_Number__c IN :setSerialLotNumbers')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Prakhar
     *  @description Fetch latest created Installed Products
     */
    public SVMXC__Installed_Product__c selectLatestIP()
    {
        String query = 'select id,IP_Serial_no_Auto_No__c,CreatedDate FROM SVMXC__Installed_Product__c ORDER BY CreatedDate DESC LIMIT 1';

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLatestIP');

        SVMXC__Installed_Product__c res = (SVMXC__Installed_Product__c) Database.query(query);

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res == null ? 0 : 1);

        return res;
    }

    /**
     *  @author KD
     *  @description Fetch loaner Installed Products based on Id
     */
    public List<SVMXC__Installed_Product__c> selectLoanerInstalledProductById(List<Id> lstInstalledProductId)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLoanerInstalledProductById', UtilsCollection.serializeIds(new Set<Id>(lstInstalledProductId)));

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Product__r.Condition_Type__c')
            .selectField('SVMXC__Product__r.Serial_Number_Profile__c')
            .setCondition('ID IN :lstInstalledProductId AND SVMXC__Product__r.Condition_Type__c = \'LOANER\' AND SVMXC__Product__r.Serial_Number_Profile__c = \'IL02\'')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author KD
     *  @description Fetch Installed Products based on Account and Serial number
     *  @parameter : boolIncludeOnly --> true if only mentioned serial number to be selected ; false if serial nnumber need to be excluded from search
     */
    public List<SVMXC__Installed_Product__c> selectInstalledProductByAccountAndSerialNumber(Set<Id> accountIds,List<String> lstSerialNumber,Boolean boolIncludeOnly){
        ilib_LogQuery logger=null;
        if (Feature.isOn('SalesQueryLogs')) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectInstalledProductByAccountAndSerialNumber',
            UtilsCollection.serializeIds(accountIds)
        );
        String strExcludeCondition = '';
        if(lstSerialNumber == null && boolIncludeOnly)
            return new List<SVMXC__Installed_Product__c>();
        else if(lstSerialNumber == null && !boolIncludeOnly)
            strExcludeCondition = '';
        else
            strExcludeCondition = boolIncludeOnly ? 'AND SVMXC__Serial_Lot_Number__c IN: lstSerialNumber' : 'AND SVMXC__Serial_Lot_Number__c NOT IN: lstSerialNumber';
        String strQuery= newQueryFactory(true)
            .selectField(STRING_PRODUCT_NAME)
            .selectField('SVMXC__Product__r.Apttus_Config2__ProductType__c')
            .selectField('SVMXC__Product__r.ProductCode')
            .setCondition('SVMXC__Company__c IN :accountIds AND Service_Product_Type__c = \'Instrument\' '+strExcludeCondition)
            .toSOQL();

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(strQuery);
        if (Feature.isOn('SalesQueryLogs')) logger.stop(res.size());
        return res;
    }
     
     /**
      *  @description Fetch Installed Products based on products code
      */
	public List<SVMXC__Installed_Product__c> selectIPsFromProductExtIds(Set<String> setPRoductCodes)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIPsFromProductExtIds', UtilsCollection.serializeIds(setPRoductCodes));

        
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
             newQueryFactory()
            .selectField('Product_Code1__c')
            .setCondition('Product_Code1__c IN :setPRoductCodes')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Ritika
     *  @description Fetch Locations for account id passed
     *  @return List of Location Ids
     **/
    public List<SVMXC__Installed_Product__c> selecInstalledProductsFromLocation(set<Id> recordIDsWithNoAccount) 
    {  
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selecInstalledProductsFromLocation',
            UtilsCollection.serializeIds(recordIDsWithNoAccount)
        );
        String strQuery= newQueryFactory(true)
            .setCondition('SVMXC__Site__c IN: recordIDsWithNoAccount')
            .toSOQL();

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(strQuery);
        if (Feature.isOn(SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
        

    }    

    /*******************************************************************************************************
    * @description Method to return Installed Product based on Serial/Lot Number or Id
    * @param List<String> list of Serial Number
    * @param List<String> list of Installed Product Id
    * @return List<SVMXC__Installed_Product__c>
    * @example
    *******************************************************************************************************/
    public List<SVMXC__Installed_Product__c> selectIPForSerialLotNumberOrID (List<String> lstSerialLotNumber, List<String> lstIPs ){
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIPForSerialLotNumberOrID');
        }
            
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory()
            .setCondition('External_Id__c IN :lstSerialLotNumber OR ID IN :lstIPs')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }          
        return res;
    }
	
	/*******************************************************************************************************
    *Author: Raviteja Vakkalagadda 
	* @description Method to return Installed Product based on SerialNumber
    * @param SerialNumber
    * @return List<SVMXC__Installed_Product__c>
    * @example
    *******************************************************************************************************/
    public List<SVMXC__Installed_Product__c> selectIPForSerialNumber (String serialNumbers){
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(SERVICE_QUERY_LOGS)){
         logger = new ilib_LogQuery(
            LOG_TITLE + '.selectIPForSerialNumber',serialNumbers
        );
    }
            
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Name')
            .selectField('Proactive_Connectivity_Status__c')
            .selectField('SVMXC__Product__r.Product_Category__c')
            .setCondition('Name =: serialNumbers')
            .setLimit(1)
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }          
        return res;
    }
    /*******************************************************************************************************
    *Author: Sagar Madkaikar
	* @description Method to return Installed Product with Child Attribute Instance Records
    * @param setInstPrdIDs
    * @return List<SVMXC__Installed_Product__c>
    * @example
    *******************************************************************************************************/
    public List<SVMXC__Installed_Product__c> getIPWithAttributeTemplateInstance (Set<Id> setInstPrdIDs){
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getIPWithAttributeTemplateInstance');
        }


        ilib_QueryFactory ipQuery = newQueryFactory();
        ipQuery.selectField('Id');
        ipQuery.selectField('SVMXC__Product__r.Family');
        ilib_QueryFactory templateInstanceQuery = new SMAttributesTemplateInstanceSelector().addQueryFactorySubselect(ipQuery,'SVMXC__IB_Attributes_Template_Instance__r');
        templateInstanceQuery.selectField('Id');
        templateInstanceQuery.selectField('SVMXC__SM_Installed_Product_Id__c');
        templateInstanceQuery.selectField('SVMXC__SM_Attr_Payload__c');
        templateInstanceQuery.selectField('SVMXC__SM_Instance_Template_Id__c');
        templateInstanceQuery.setCondition('SVMXC__SM_Installed_Product_Id__c IN :setInstPrdIDs');
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(ipQuery.setCondition('Id IN :setInstPrdIDs').toSOQL());

        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

    /**
     *  @author Gladis
     *  @description DCP-45368 Method to return Installed Product based on Equipment Id on OrderLineItem
     *  @return List<SVMXC__Installed_Product__c>
     **/
    public List<SVMXC__Installed_Product__c> selectInstalledProductsFromEquipmentId(Set<String> setEquipmentIds) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstalledProductsFromEquipmentId');
        } 
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
             newQueryFactory()
            .selectField('Id')
            .selectField('ERP_Equipment_ID__c')
            .setCondition('ERP_Equipment_ID__c IN :setEquipmentIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /*******************************************************************************************************
    * @description DCP-52682 Method to return Installed Product with Attribute History
    * @param setIPIds set of INstalled Product Ids
    * @return List<SVMXC__Installed_Product__c>
    */
    public List<SVMXC__Installed_Product__c> selectIPsWithAttributeHistory(Set<Id> setIPIds) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIPsWithAttributeHistory');
        } 

        ilib_QueryFactory ipQuery = newQueryFactory();
        ipQuery.selectField('Proactive_Last_Connected_Date__c');
        ipQuery.selectField(STRING_PRODUCT_NAME);
        ipQuery.selectField('SVMXC__Product__r.family');
        ipQuery.setCondition('Id IN : setIPIds');

        ilib_QueryFactory attrHistorySelector = new IBAttributesHistorySelector().addQueryFactorySubselect(ipQuery,'SVMXC__IB_Attributes_Historys__r');
        attrHistorySelector.setLimit(1);
       
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            ipQuery
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /*******************************************************************************************************
    * @description CMCM-10540 LWC Fetches data using Key attribute which holds search data
    * @author Abhishek Yadav
    * @param key Key attribute which holds search data
    * @return List<SVMXC__Installed_Product__c>
    */
    public List<SVMXC__Installed_Product__c> selectIPsWithSearchWithSOSL(String key) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIPsWithSearchWithSOSL');
        } 
    
        List<List<SObject>> searchResults = [FIND :(key) 
            IN ALL FIELDS 
            RETURNING SVMXC__Installed_Product__c (
                Id,
                Name, 
                SVMXC__Product_Name__c, 
                Product_Code__c, 
                SVMXC__Company__c,
                Service_Product_Type__c,
                SVMXC__Product__c, 
                SVMXC__Asset_Tag__c,
                Currently_Active_Service_Contract__r.Name
            ) 
            LIMIT 50];
        
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) searchResults[0];
    
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /*******************************************************************************************************
    * @description CMCM-3980 LWC Fetches data using Account Id and Key attribute which holds search data
    *  @author Siddartha Reddy Kalam
    * @param AccountID & key Key attribute which holds search data
    * @return List<SVMXC__Installed_Product__c>
    */
    public List<SVMXC__Installed_Product__c> selectIPsWithAccountIdandSearch(Id accountId,String key) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIPsWithAccountIdandSearch');
        } 

        ilib_QueryFactory ipQuery = newQueryFactory();
        ipQuery.selectField('Id');
        ipQuery.selectField('Name');
        ipQuery.selectField('SVMXC__Product_Name__c');
        ipQuery.selectField('Product_Code__c');
        ipQuery.selectField(STRING_PRODUCT);
        ipQuery.selectField(STRING_ASSET_TAG); // added for CMCM 8089 by Dhairya Shah new change by Doug
        ipQuery.selectField('Currently_Active_Service_Contract__r.Name'); // added by dhairya shah for CMCM 7944
        ipQuery.setCondition('SVMXC__Company__c =: accountId AND (SVMXC__Company__r.Name LIKE :key OR Name LIKE :key OR SVMXC__Product__r.ProductCode LIKE :key OR SVMXC__Product__r.Name LIKE :key OR SVMXC__Asset_Tag__c LIKE :key) AND Service_Product_Type__c=' +INSTRUMENT_KEYWORD);
        ipQuery.setLimit(50); //CMCM-5309 :14th March adding limit of 20 //CMCM 11619 Increase limit from 20 to 50
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            ipQuery
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /*******************************************************************************************************
    * @description CMCM-3980 LWC Fetches data using id attribute which holds record data
    *  @author Siddartha Reddy Kalam
    * @param idofIPs attribute which holds associated products data
    * @return List<SVMXC__Installed_Product__c>
    */
    public List<SVMXC__Installed_Product__c> selectIPsWithId(List<Id> idofIPs) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIPsWithId');
        } 

        ilib_QueryFactory ipQuery = newQueryFactory();
        ipQuery.selectField('Id');
        ipQuery.selectField('Name');
        ipQuery.selectField(STRING_COMPANY);
        ipQuery.selectField('Product_Code__c');
        ipQuery.selectField('SVMXC__Site__c');
        ipQuery.setCondition('id =: idofIPs');
       
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            ipQuery
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /*******************************************************************************************************
    * @description Searches for Installed Products by a partial name match.(CMCM-3200)
    *  @author Priya Mukherjee
    * @param name The partial name to search for.   
    * @return List<SVMXC__Installed_Product__c>
    */
    public List<SVMXC__Installed_Product__c> selectInstalledProductsByName(String name) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstalledProductsByName', name);
        }
    
        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('SVMXC__Product__r.Name')
            .selectField('SVMXC__Product__r.ProductCode')
            .selectField('SVMXC__Product__r.Service_Product_Type__c')
            .selectField('Service_Bill_Of_Materials__c')
            .setCondition('Name LIKE \'%' + String.escapeSingleQuotes(name) + '%\'')
            .setLimit(1)
            .toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /**
     *  @author  Abhishek Yadav
     *  @description Retrieve list of fields for Installed Product sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
	 **/
    public List<SVMXC__Installed_Product__c> selectInstalledProductByIds(Set<Id> setIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstalledProductByIds', UtilsCollection.serializeIds(setIds));

        List<SVMXC__Installed_Product__c> res = (List<SVMXC__Installed_Product__c>) Database.query(
            newQueryFactory(false,false,false)
            .selectField(STRING_PRODUCT)
            .selectField(STRING_COMPANY)
            .selectField('SVMXC__Serial_Lot_Number__c')// added by dhairya shah for CMCM 7910
            .selectField(STRING_SITE)
            .selectField('Installed_Product_Upgrade_Type__c')
            .setCondition('Id IN :setIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	 /**
     *  @author Gaurav
     *  @description Retrieve list of fields for Install Product Object. 
     *  @return list of installed products
     **/
	 public List<SVMXC__Installed_Product__c> getInstallProduct(Set<Id> parentInstallProductIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getInstallProduct', UtilsCollection.serializeIds(parentInstallProductIds));

        List<SVMXC__Installed_Product__c> res= (List<SVMXC__Installed_Product__c>) Database.query(
        newQueryFactory()
        .selectField('Id')
        .selectField('Deinstall_Date__c')
        .selectField(STRING_STATUS)
        .selectField('SVMXC__Parent__c')
        .selectField('SVMXC__Top_Level__c')
        .setCondition('Id IN :parentInstallProductIds')
        .toSOQL());
        
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

     /**
     *  @author Vishal
     *  @description Retrieve a single record for Installed Product. 
     *  @return Installed Products
     **/
    public SVMXC__Installed_Product__c getIP(Id installProductId)
    {        
        SVMXC__Installed_Product__c ipRecord = (SVMXC__Installed_Product__c) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Account_Country__c')
            .selectField('SVMXC__Product__r.Id')
            .selectField('SVMXC__Product__r.Name')
            .selectField('Product_Category__c')
            .selectField('Product_Group__c')
            .selectField('Product_Regulatory_Type__c')
            .selectField('Region__c')
            .selectField('SVMXC__Company__r.Name')
            .selectField(STRING_ERP_CUSTOMER_ID)
            .selectField('SVMXC__Contact__r.Id')
            .selectField('SVMXC__Contact__r.Email')
            .selectField('SVMXC__Contact__r.FirstName')
            .selectField('SVMXC__Contact__r.LastName')
            .selectField('SVMXC__Contact__r.Name')
            .selectField('SVMXC__Contact__r.Preferred_Language__c')
            .selectField('SVMXC__Date_Shipped__c')
            .setCondition('Id = :installProductId') // Query for a single ID
            .toSOQL());        
        return ipRecord;  
    }

}