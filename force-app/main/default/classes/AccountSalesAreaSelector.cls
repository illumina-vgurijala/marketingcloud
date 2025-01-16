/**
*    @author Rahul Sharma
*    @date   2018-08-04
*    @description    DCP-8330: Account Sales Area Selector class
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------
*     Developer                    Date                Description
*     Rahul Sharma              04 Aug 2018            Account Sales Area Selector Class
*     Rahul Sharma              24 Aug 2018            Added Price List field in query
*     Akshay Mohan              03 Oct 2018            Get the ASA based on ERP in selectAccountSaleaAreaByERP
*     Rahul Sharma              05 Oct 2018            Added IsInactive Condition and Division in query fields
*     Akshay Mohan              16 Oct 2018            Get the ASA based on Account & Sales Area Metadata
*     Rahul Sharma              18 Oct 2018            Added Contract Number in query list
*     Satya Swain               23 Oct 2018            Added Company Code in query list
*     Rahul Sharma              30 Nov 2018            Added Inco_Term_1__c in query list
*     Govind Dubey              06 Aug 2019            Fetch ASA from related CMD
*     Satya Swain               04 Sep 2019            Added cache for selectAccountSaleaAreaByERP method as part of INC0225110
*     Saswati Prusty            06 Dec 2019            DCP-31654 - Added Price Group 
*     B Kamini                  08 Feb 2020            DCP-33776 - Added method selectAccountSaleaAreaByPriceGrpSalesOrg
*     Pankaj Sharma             10 Feb 2020             DCP-33708 - Added Price Group Description
*     Sagar Madkaikar           13-Sep-2021            CMCP-22:Added relocation related fields in SOQL of selectAccountSaleaArea() method. 
                                                               Added Query Instrumentation                           
*    ---------------------------------------------------------------------------------------------------------------------------- 
*                    
*/
public with sharing class AccountSalesAreaSelector extends ilib_SObjectSelector {

   private static final string  LOG_TITLE = 'AccountSalesAreaSelector';//CMCP-22
   private static final  string SALES_QUERY_LOGS = 'SalesQueryLogs';//CMCP-22
    /*
     * Return SObject Type of Account Sales Area
     */
    public Schema.SObjectType getSObjectType()
    {
        return Account_Sales_Area__c.sObjectType;
    }

    /*
    * @author Rahul Sharma
    * @date   02-08-2018
    * @description  Retrieve list of fields for Account Sales Area sObject
    * @return sObjectFieldList list of Schema.SObjectField
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Account_Sales_Area__c.Id,
            Account_Sales_Area__c.Name,
            Account_Sales_Area__c.Price_List_Type__c,
            Account_Sales_Area__c.Account__c,
            Account_Sales_Area__c.CurrencyIsoCode,
            Account_Sales_Area__c.ERP_Account_Sales_Area_Id__c,
            Account_Sales_Area__c.Price_List__c,
            Account_Sales_Area__c.Sales_Organization__c,
            Account_Sales_Area__c.Distribution_Channel__c,
            Account_Sales_Area__c.Term_Of_Payment__c,
            Account_Sales_Area__c.Division__c,
            Account_Sales_Area__c.Contract_Number__c,
            Account_Sales_Area__c.Company_Code__c,
            Account_Sales_Area__c.Inco_Term_1__c,
            Account_Sales_Area__c.Customer_Master_Data__c,
            Account_Sales_Area__c.Price_Group__c, // Saswati : DCP-31654 
			Account_Sales_Area__c.Price_Group_Description__c //Pankaj : 33708
        };
    }


    /*
    * @author Rahul Sharma
    * @description Fetch Account Sales Area Record for the Matching Sales Area from Opportunity
    * @param accountIds Set of Account Ids
    *
    */
    public List<Account_Sales_Area__c> selectAccountSaleaArea(Set<Id> accountIds) 
    {
        ilib_LogQuery logger=null;

        if(Feature.isOn(SALES_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountSaleaArea', UtilsCollection.serializeIds(accountIds));

        List<Account_Sales_Area__c> res = (List<Account_Sales_Area__c>) Database.query(
             newQueryFactory()
            .selectField('Price_Group__c') // Saswati : DCP-31654 
            .selectField('Sales_Organization__c') // Added for CMCP-22
            .selectField('Distribution_Channel__c') // Added for CMCP-22
            .selectField('Division__c') // Added for CMCP-22
            .setCondition('Account__r.id IN :accountIds AND IsInactive__c = false').toSOQL());

        if(Feature.isOn(SALES_QUERY_LOGS))
        logger.stop(res.size());

        return res;
    }   
      
    
    /*
    * @author Akshay Mohan
    * @description Fetch Account Sales Area Record for the Matching ERP Id
    * @param setERPs Set of Account ERPs
    *
    */
    // Added by Satya for INC0225110
    private static Map<String, List<Account_Sales_Area__c>> cacheForselectAccountSaleaAreaByERP = new Map<String, List<Account_Sales_Area__c>>();
    
    /*
     * Return list of Account Sales Area objects based on ERP
     */
    public List<Account_Sales_Area__c> selectAccountSaleaAreaByERP(Set<String> setERPs)
    {
        if (setERPs.isEmpty())
            return new List<Account_Sales_Area__c>();

        String serialized = UtilsCollection.serializeIds(setERPs);

        if (cacheForselectAccountSaleaAreaByERP.containsKey(serialized))
            return cacheForselectAccountSaleaAreaByERP.get(serialized);
        
        ilib_QueryFactory query = newQueryFactory()
            .selectField('Account__r.ERP_Customer_Id__c')
            .setCondition(' ERP_Account_Sales_Area_Id__c IN :setERPs ');

        CustomerMasterDataSelector selectorCMD = new CustomerMasterDataSelector();
        selectorCMD.configureQueryFactoryFields(query,'Customer_Master_Data__r');

        new AccountRelationshipsSelector().addQueryFactorySubselect(query, 'Partner_Functions__r');

        List<Account_Sales_Area__c> res = (List<Account_Sales_Area__c>) Database.query(query.toSOQL());
        cacheForselectAccountSaleaAreaByERP.put(serialized,res);
        return res;
    }
    
    /*
    * @author Akshay Mohan
    * @description Fetch Account Sales Area Record based on Account Id & Sales Area metadata
    * @param idAccount Account Id
    * @param objSalesArea Sales Area Metadata
    *
    */
    public List<Account_Sales_Area__c> selectAccountSaleaAreaByAccount(Id idAccount, Sales_Area__mdt objSalesArea)
    {
        String strSalesOrg = objSalesArea.Sales_Organization__c;
        String strDistribution = objSalesArea.Distribution_Channel__c;
        String strDivision = objSalesArea.Division__c;
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition(' Account__c = :idAccount AND Sales_Organization__c = :strSalesOrg AND IsInactive__c = false '
            + ' AND Distribution_Channel__c = :strDistribution AND Division__c = :strDivision ');

        return (List<Account_Sales_Area__c>) Database.query( query.toSOQL() );
    }

    /*
    * @author Govind Dubey
    * @description Fetch Account Sales Area Record based on CMD Id & Sales Area metadata
    * @param Set of CMD ERP and Sales Area
    *
    */
    public List<Account_Sales_Area__c> selectASAByCMDERP(Set<String> setCMDERP, String strSalesArea)
    {
        String strSalesOrg = strSalesArea.subString(0,4);
        String strDistribution = strSalesArea.subString(4,6);
        String strDivision = strSalesArea.right(2);

        ilib_QueryFactory query = newQueryFactory()
            .setCondition(' Customer_Master_Data__r.ERP_Customer_Id__c IN :setCMDERP AND Sales_Organization__c = :strSalesOrg AND IsInactive__c = false '
                + ' AND Distribution_Channel__c = :strDistribution AND Division__c = :strDivision');

        return (List<Account_Sales_Area__c>) Database.query( query.toSOQL() );
    }

     /*
    * @author B Kamini
    * @description Fetch Account Sales Area Record based on Price Group & Sales Organization
    * @param List of Price group & Sales Org
    *
    */
    public List<Account_Sales_Area__c> selectAccountSaleaAreaByAccount(List<String> lstPG,List<String> lstsalesOrg){
        return (List<Account_Sales_Area__c>) Database.query(
                                newQueryFactory()
                                .selectField('Account__c')
                                .selectField('Price_Group__c')
                                .selectfield('Sales_Organization__c')
                                .selectfield('Account__r.ERP_Customer_Id__c')
                                .setCondition('Price_Group__c=:lstPG AND Sales_Organization__c=:lstsalesOrg AND Account__c != NULL')
                                .toSOQL());
    }
    
    /*
    * @author Rucha Dalvi
    * @date   07-29-2022
    * @description Fetch Account Sales Area for Account NGN and Account Status
    * @param Set of Account NGN and Set of Account Status Values
    *
    */
    public List<Account_Sales_Area__c> getAcntSalesAreaByAccountNGN(Set<String> setNGN,Set<String> strStatusValue){
        return (List<Account_Sales_Area__c>) Database.query(
                                newQueryFactory()
                                .selectField('Account__c')
                                .selectField('Distribution_Channel__c')
                                .selectfield('Sales_Organization__c')
                                .selectfield('Account__r.National_Group_Number__c')
                                .selectfield('Account__r.Account_Status__c')
                                .selectField('Account__r.Signed_Open_Offer__c')
                                .selectfield('Account__r.ERP_Customer_Id__c') // Added for DCP-54439
                                .setCondition('Account__r.Account_Status__c IN: strStatusValue AND Account__r.National_Group_Number__c IN: setNGN  AND Account__r.Signed_Open_Offer__c!=true')
                                .toSOQL());
    }

}