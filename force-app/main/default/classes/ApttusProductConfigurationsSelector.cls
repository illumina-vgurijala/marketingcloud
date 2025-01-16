/**
*    @author Rohan Chandarana
*    @date   2018-07-20
*    @description    Class to get the Product Configuration records based on different conditions 
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                    Date                 Description
*    Rohan                        2018-07-20           Initial Version
*    Pankaj                       2018-10-22           Added proposal Promotion fields in selectConfigWithLines
*    Milan                        2018-10-30           Added selectProductConfigurationByQuote Method
*    Akshay                       2019-05-13           DCP-25194 Add PPM
*    Rahul                        2019-07-03           DCP-25384 UC Apex Sharing
*    Arnab                        2019-08-23           Added Material Class Type and ProductOption field in Line Items field DCP-28284
*    Rishab                       2020-05-08           DCP-34910 Validate Cart Update
*    Rishab                       2020-12-07           DCP-31081 Beadchip Error Soft Warning
*    Todd                         2021-04-15           DCP-45737: Add quote instrumentation (with feature flag)
*    KD                           2021-05-05           DCP-45742 Add new select field.
*    Adyasha                      2021-05-07           DCP-38809 Added Work Detail Line Field
*    Adyasha                      2021-05-12           DCP-46872 Added Work Order field
*    Ashwin                       2021-05-11           INC0321438 Updated method name selectConfigWithLinesByQuote to selectConfigsByQuote. Removed sub query and queried Config line items separately in ApttusLineItemsSelector
*    KD                           2021-06-27           DCP-46257 : Added new field Inventory Location
*    Ashwin Kumar                 15-Nov-2021          INC0350488: Added Is_Reprice_Completed__c field
*    Khushbu Vasani               22-Jun-2022           DCP-53200 : added fields to be fetched in fetchcart method
*    Rucha Dalvi                  2022-07-05           Code Scan Fixes 
*    ------------------------------------------------------------------------------------
*/
public with sharing class ApttusProductConfigurationsSelector extends ilib_SObjectSelector {
    
    private final String LOG_TITLE = 'ApttusProductConfigurationsSelector';
    //codescan - duplicate literals fix
    public static final string STRING_SALES_QUERY_LOG = 'SalesQueryLogs';
    public static final string STATUSFINALIZED = 'Finalized';
    public static final string STATUSSAVED = 'Saved'; //DCP-34910
    
    /**
*  @author Rohan Chandarana
*  @description
*  @return SObjectType The Schema.SObjectType of the Product Configuration
**/
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Config2__ProductConfiguration__c.sObjectType;
    }
    
    /**
*  @author  Rohan Chandarana
*  @description Retrieve list of fields for Product Configuration sObject
*  @return sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus_Config2__ProductConfiguration__c.id,
                Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__ApprovalStatus__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__BillToAccountId__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__BusinessObjectId__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__NumberOfItems__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__AccountId__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__Status__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__EffectiveDate__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__PriceListId__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__IsPricePending__c,
                Apttus_Config2__ProductConfiguration__c.Promotion_JSON__c,
                Apttus_Config2__ProductConfiguration__c.SAP_Errors__c,
                Apttus_Config2__ProductConfiguration__c.Promo_Name_1__c,
                Apttus_Config2__ProductConfiguration__c.Promo_Name_2__c,
                Apttus_Config2__ProductConfiguration__c.Promo_Name_3__c,
                Apttus_Config2__ProductConfiguration__c.SAP_quote_c__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__ExpectedEndDate__c,
                Apttus_Config2__ProductConfiguration__c.Sub_Total__c,
                Apttus_Config2__ProductConfiguration__c.Is_SAP_Pricing_Completed__c,
                Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c,
                Apttus_Config2__ProductConfiguration__c.Number_of_Line_Items_During_Check_Price__c,
                Apttus_Config2__ProductConfiguration__c.GT_Check_Pending_Count__c
                };
                    }
    
    /**
*  @author  Rohan Chandarana
*  @description find the product configuration and lind items related to given ids
*  @return List of Product Classificaiton with Line Item Records

*  @author  Arnab Modak
*  @description Querying MaterialClassType from Product and MaterialClass from Component product
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectConfigWithLines(Set<Id> idSet)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectConfigWithLines',
            UtilsCollection.serializeIds(idSet)
        );
        
        ilib_QueryFactory query = newQueryFactory()
            .selectField('Apttus_QPConfig__Proposald__r.Name')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PricingDate__c')
            .selectField('Apttus_QPConfig__Proposald__r.Sold_To_Sales_Organization__c')
            .selectField('Apttus_QPConfig__Proposald__r.Sold_To_Distribution_Channel__c')
            .selectField('Apttus_QPConfig__Proposald__r.Sold_To_Division__c')
            .selectField('Apttus_QPConfig__Proposald__r.Sold_To_ERP_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ship_To_ERP_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee_ERP_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.CurrencyIsoCode')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__ExpectedEndDate__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__ExpectedStartDate__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__c')
            .selectField('Apttus_QPConfig__Proposald__r.Quote_Sub_Type__c')
            .selectField('Apttus_QPConfig__Proposald__r.Promo_Channel_1__c')
            .selectField('Apttus_QPConfig__Proposald__r.Promo_Code_1__c')
            .selectField('Apttus_QPConfig__Proposald__r.Promo_Channel_2__c')
            .selectField('Apttus_QPConfig__Proposald__r.Promo_Code_2__c')
            .selectField('Apttus_QPConfig__Proposald__r.Promo_Channel_3__c')
            .selectField('Apttus_QPConfig__Proposald__r.Promo_Code_3__c')
            .selectField('Apttus_QPConfig__Proposald__r.Distributor__c')
            .selectField('Apttus_QPConfig__Proposald__r.SAP_Quote__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c')
            .selectField('Apttus_QPConfig__Proposald__r.Inco_Term_1__c')
            .selectField('Apttus_QPConfig__Proposald__r.MyIllumina_User_Email__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c')
            .selectField('Apttus_QPConfig__Proposald__r.Web_Visible__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Payment_Term__c')
            .selectField('Apttus_QPConfig__Proposald__r.Quote_Type__c')
            .selectField('Apttus_QPConfig__Proposald__r.Bill_To_ERP_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.Distributor_ERP_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.Payer_ERP_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.Prepared_by__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Primary_Contact__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__r')
            .selectField('Apttus_QPConfig__Proposald__r.SAP_Errors__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Consortium__r.Species__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Consortium__r.Name')
            .selectField('Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c')
            .selectField('Apttus_QPConfig__Proposald__r.Cloned_From__c')
            .selectField('Apttus_QPConfig__Proposald__r.Post_Pricing_Message__c')
            .selectField('Apttus_QPConfig__Proposald__r.Fapiao_Type_Code__c')
            .selectField('Work_Order__r.Name')//DCP-46872
            .selectField('Validation_Number__c') //DCP-34910
            .selectField('SAP_Warnings__c') //DCP-31081 Beadchip Error Soft Warning
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Current_Ultimate_Consignee__c') //DCP-45742
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c')  //DCP-45742
            .selectField('Apttus_QPConfig__Proposald__r.Inventory_Location_ERP_Number__c') //DCP-46257
            .setCondition('Id IN :idSet');
        
        query.subselectQuery('Apttus_Config2__LineItems__r').selectFields(new ApttusLineItemsSelector().getSObjectFieldList()).
            selectField('Apttus_Config2__ProductId__r.ProductCode').
            selectField('Apttus_Config2__ProductId__r.Material_Class_Type__c').
            selectField('Apttus_Config2__OptionId__r.Material_Class__c').
            selectField('Apttus_Config2__ProductOptionId__r.Apttus_Config2__ParentProductId__r.Bundle_Id__c').
            selectField('Apttus_Config2__ProductId__r.Product_Group_Code__c').
            selectField('Apttus_Config2__OptionId__r.ProductCode').
            selectField('Apttus_Config2__ProductId__r.Material_Number__c').
            selectField('Apttus_Config2__OptionId__r.Material_Number__c').
            selectField('Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c').
            selectField('Apttus_Config2__ProductId__r.Bundle_Id__c').
            selectField('Apttus_Config2__OptionId__r.Apttus_Config2__ConfigurationType__c').
            selectField('Apttus_Config2__ProductId__r.End_Of_Sale_Date__c').
            selectField('Apttus_Config2__ProductId__r.End_Of_Service_Date__c').
            selectField('Apttus_Config2__OptionId__r.End_Of_Sale_Date__c').
            selectField('Apttus_Config2__OptionId__r.End_Of_Service_Date__c').
            selectField('Apttus_Config2__ProductId__r.Name').
            selectField('Apttus_Config2__OptionId__r.Name').
            selectField('Work_Detail_Line__c'). // Added for DCP-38809
            addOrdering('Apttus_Config2__LineNumber__c',ilib_QueryFactory.SortOrder.ASCENDING).
            addOrdering('Apttus_Config2__OptionId__r.Apttus_Config2__ConfigurationType__c',ilib_QueryFactory.SortOrder.ASCENDING);
        List<Apttus_Config2__ProductConfiguration__c> res = (List<Apttus_Config2__ProductConfiguration__c>) Database.query(query.toSOQL());
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
    /**
*  @author  Govind Dubey
*  @description find the product configuration and lind items related to given ids
*  @return List of Product Classificaiton with Line Item Records
@  @param set of Proposal ids
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectConfigsByQuote(Set<Id> setProposalIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectConfigsByQuote',
            UtilsCollection.serializeIds(setProposalIds)
        );
        
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Apttus_QPConfig__Proposald__c IN :setProposalIds');
        query.addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING);
        
        List<Apttus_Config2__ProductConfiguration__c> res = (List<Apttus_Config2__ProductConfiguration__c>) Database.query(query.toSOQL());
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
    /**
*  @author Rohan Chandarana
*  @description fetch product configurations for the ids passed in the argument
*  @param idSet set of product configuration ids
*  @return list of product configuration records
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectById(Set<Id> idSet)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectById',
            UtilsCollection.serializeIds(idSet)
        );
        
        ilib_QueryFactory query = newQueryFactory()
            .selectField('Apttus_QPConfig__Proposald__r.Cloned_From__c')
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__c')
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Owner.Email') //DCP-46472
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Owner.Type')//DCP-46472
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Account_Region__c')//DCP-46472
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.OwnerId')
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Name') //DCP-38809
            .selectField('Apttus_QPConfig__Proposald__r.Name') //DCP-38809
            .selectField('Apttus_QPConfig__Proposald__r.Quote_Sub_Type__c') //CMCM-11053
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Consortium__r.Beadchip_Part_Number__c') //CMCM-11053
            .setCondition('Id IN :idSet');
        
        
        
        List<Apttus_Config2__ProductConfiguration__c> res =  (List<Apttus_Config2__ProductConfiguration__c>) Database.query(query.toSOQL());
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
    /**
* @Author : Gopinath Reddy
* @Decription : fatching the UC from the cart
* @Param cardId
* @return  cart
*/
    public Apttus_Config2__ProductConfiguration__c fetchCart(Id cartId)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchCart',
            cartId
        );
        
        Apttus_Config2__ProductConfiguration__c res = (Apttus_Config2__ProductConfiguration__c)Database.query(
            newQueryFactory()
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__c')
            .selectField('Apttus_QPConfig__Proposald__r.Is_Reprice_Completed__c') //INC0350488
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c')
            .selectField('Apttus_QPConfig__Proposald__r.Opportunity_Record_Type__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Open_Offer_Comparison_Customer__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Signed_Open_Offer__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Signed_Open_Offer__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Open_Offer_Comparison_Customer__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.ERP_Customer_Id__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.ERP_Customer_Id__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PricingDate__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.National_Group_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.National_Group_Number__c')
            .setCondition('id = :cartId')
            .toSOQL()
        );
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(1);
        return res;
    }
    
    /**
* @Author : Parth Rajdev
* @Decription : fatching the configuration and proposal details
* @Param cardId
* @return  cart
*/
    public Apttus_Config2__ProductConfiguration__c fetchConfigAndProposalforDG(Id cartId)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchConfigAndProposalforDG',
            cartId
        );
        
        Apttus_Config2__ProductConfiguration__c res = (Apttus_Config2__ProductConfiguration__c)Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Apttus_QPConfig__Proposald__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PricingDate__c')
            .selectField('Apttus_QPConfig__Proposald__r.Sold_To_Distribution_Channel__c')
            .selectField('Apttus_QPConfig__Proposald__r.Quote_For_Open_Offer_Customer__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__r.CurrencyIsoCode')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Price_List_Type__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.BillingCountry')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.BillingCountryCode')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.ERP_Customer_Id__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Territory_Region__c')
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.National_Group_Number__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.BillingCountry')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.BillingCountryCode')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.ERP_Customer_Id__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Territory_Region__c')
            .selectField('Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.National_Group_Number__c')
            .setCondition('id = :cartId')
            .toSOQL() 
        );
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(1);
        return res;
    }
    
    /**
*  @author  Milan Savaliya
*  @description find the product configuration for Proposal
*  @return List of Product Classificaiton with Line Item Records
@  @param set of Proposal ids
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectProductConfigurationByQuotIds(Set<Id> setProposalIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectProductConfigurationByQuotIds',
            UtilsCollection.serializeIds(setProposalIds)
        );
        
        List<Apttus_Config2__ProductConfiguration__c> res = (List<Apttus_Config2__ProductConfiguration__c>)Database.query(
            newQueryFactory(false)
            .selectField('Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c')  // Added by Adyasha for DCP-38809, DCP-39763
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__c') //DCP-38809
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Name') //DCP-38809
            .selectField('Apttus_QPConfig__Proposald__r.Name') //DCP-38809
            .selectField('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c') //DCP-38809
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Initiate_Quoting__c') //DCP-38809
            .selectField('Apttus_Config2__Status__c')
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Owner.Email') //DCP-46472
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Owner.Type')//DCP-46472
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.Account_Region__c')//DCP-46472
            .selectField('Apttus_QPConfig__Proposald__r.Work_Order__r.OwnerId') //DCP-46472
            .setCondition('Apttus_QPConfig__Proposald__c In :setProposalIds')
            .toSOQL()
        );
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
    /**
*  @author  Kristiyan Petkov
*  @description get product configuration by Id
*  @return List of Product Configurations
*  @param set of Proposal ids
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectProductConfigurationById(Id configId)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectProductConfigurationById',
            configId
        );
        
        String strCondition = 'Id =: configId';
        String strQuery = newQueryFactory().setCondition(strCondition).toSOQL();
        List<Apttus_Config2__ProductConfiguration__c> res = (List<Apttus_Config2__ProductConfiguration__c>) Database.query(strQuery);
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
    /**
*  @author  Rahul Sharma
*  @description DCP-25384 find the product configuration for Sold To and UC
*  @return List of Product Configuration
@  @param set of Account Ids
DCP-25384
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectProductConfigurationByAccounts(Set<Id> accountIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectProductConfigurationByAccounts',
            UtilsCollection.serializeIds(accountIds)
        );
        
        List<Apttus_Config2__ProductConfiguration__c> res = (List<Apttus_Config2__ProductConfiguration__c>)Database.query(
            newQueryFactory()
            .setCondition('Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.AccountId IN :accountIds OR Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c IN :accountIds')
            .toSOQL()
        );
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
    /**
*  @author  Rishab Wali
*  @description DCP-34910 find the saved product configuration for Proposal
*  @return List of Product Configuration with Line Item Records
@  @param set of Proposal ids
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectSavedProductConfigurationByQuotIds(Set<Id> setProposalIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectSavedProductConfigurationByQuotIds',
            UtilsCollection.serializeIds(setProposalIds)
        );
        
        List<Apttus_Config2__ProductConfiguration__c> res = (List<Apttus_Config2__ProductConfiguration__c>)Database.query(
            newQueryFactory()
            .selectField('Apttus_Config2__Status__c')
            .selectField('SAP_Errors__c')
            .selectField('SAP_Warnings__c') //DCP-31081 Beadchip Error Soft Warning
            .setCondition('Apttus_Config2__Status__c =: STATUSSAVED AND Apttus_QPConfig__Proposald__c IN: setProposalIds')
            .toSOQL()
        );
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
    /**
*  @author  Kumar Gaurav
*  @description DCP-31 find the finalized product configuration for Proposal
*  @return List of Product Configuration with Line Item Records
@  @param set of Proposal ids
**/
    public List<Apttus_Config2__ProductConfiguration__c> selectFinalizedProductConfigurationByQuotIds(Set<Id> setProposalIds)
    {
        
        return (List <Apttus_Config2__ProductConfiguration__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Apttus_QPConfig__Proposald__c')
            .setCondition('Apttus_Config2__Status__c =: STATUSFINALIZED AND Apttus_QPConfig__Proposald__c IN: setProposalIds')
            .toSOQL()
        );
        //<---End DGP-31--->
    }

/**
*  @author  Vinay S Reddy
*  @description CMCM-11308 find the SAP Errors in product configuration for Proposal
*  @return List of Product Configuration with SAPErrors
@  @param set of ConfigProd ids
**/
public List<Apttus_Config2__ProductConfiguration__c> selectConfigProdforSAPErrors(Set<Id> setConfigProdIds)
{
    
    return (List <Apttus_Config2__ProductConfiguration__c>) Database.query(
        newQueryFactory()
        .selectField('Id')
        .selectField('SAP_Errors__c')
        .setCondition('ID IN: setConfigProdIds')
        .toSOQL()
    );
   
}
    
}