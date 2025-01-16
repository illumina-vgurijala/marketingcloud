/**
*    @author Rohan Chandarana
*    @date   2018-06-07
*    @description    Class to get the Proposal Line Items records based on different conditions
*    Modification Log:
*   ------------------------------------------------------------------------------------
*    Developer             Date                Description
*    Rohan                 2018-06-07          Initial Version
*    Govind Dubey          2018-07-25          added selectByQuoteId for DCP-2638
*    Govind Dubey          2018-08-17          added selectAllRecycleRowsProposalLineItems for DCP-10119
*    Milan Savaliya        2018-10-30          added fields in selectByQuoteId
*    Rahul Sharma          2019-04-17          Added query fields for Catalyst
*    Roopal Verma          2019-08-07          Added program type for regression fix
*    Arnab Modak           2019-08-23          Added Material_Class_Type__c for DCP-28284,28664
*    Arnab Modak           2019-10-10          Added query fields for DCP-28284 (Generate cart)
*    Govind Dubey          2019-09-23          Added query fields for DCP-29855
*    Rahul Bishnoi         2020-01-13          DCP-32794 Remove Software Id
*	 Rahul Bishnoi         2020-01-20          DCP-31269 Added Fields
*    Rahul Bishnoi         2019-12-05          Added fields for DCP-30367
*    Roopal Verma          2020-14-05          Added Product specifi term for DCP-29812
*    Bharath Varma         2020-11-20          Added fields for DCP-31776
*    Satya Swain           2021-03-17          Added fields for INC0313896
*    Todd                  2021-05-26          DCP-45737: Added instrumentation and converted queries to SOQL for performance gains
*    Satya Swain           2021-05-12          Restored Manual Rebate field in selectByQuoteId
*    Pradeep Landge        2024-09-27          Added fields for DGP-497
*    ------------------------------------------------------------------------------------
*/

public with sharing class ApttusProposalLineItemsSelector extends ilib_SObjectSelector
{
    private final String LOG_TITLE = 'ApttusProposalLineItemsSelector';

    /**
     *  @author Rohan Chandarana
     *  @description
     *  @return SObjectType The Schema.SObjectType of the Proposal Line Item
     **/
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Proposal__Proposal_Line_Item__c.sObjectType;
    }

    /**
     *  @author  Rohan Chandarana
     *  @description Retrieve list of fields for Proposal Adjustment Line Items sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus_Proposal__Proposal_Line_Item__c.Id,
            Apttus_Proposal__Proposal_Line_Item__c.Customer_Net_Price__c,
            Apttus_Proposal__Proposal_Line_Item__c.Premium__c,
            Apttus_Proposal__Proposal_Line_Item__c.Freight_Discount_Amount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__Uom__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Quantity__c,
            Apttus_Proposal__Proposal_Line_Item__c.Approval_Level_Promotion__c,
            Apttus_Proposal__Proposal_Line_Item__c.Approval_Category__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Proposal__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPApprov__Approval_Status__c,
            Apttus_Proposal__Proposal_Line_Item__c.Configuration_Status__c,
            Apttus_Proposal__Proposal_Line_Item__c.Material_Number__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__ListPrice__c,
            Apttus_Proposal__Proposal_Line_Item__c.Applied_Discount_Amount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Applied_Discount_Details__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__AdjustedPrice__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__Quantity2__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__NetPrice__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__NetAdjustmentPercent__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__AdjustmentAmount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__AdjustmentType__c ,
            Apttus_Proposal__Proposal_Line_Item__c.Applied_Discount_Percentage__c,
            Apttus_Proposal__Proposal_Line_Item__c.Freight_Discount_Amount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Freight_Discount_Percentage__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__NetPrice__c,
            Apttus_Proposal__Proposal_Line_Item__c.Discounted_Price_Per_Unit__c,
            Apttus_Proposal__Proposal_Line_Item__c.Distributor_Discount_Amount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Distributor_Discount_Percentage__c,
            Apttus_Proposal__Proposal_Line_Item__c.Stacked_Discount_Amount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Stacked_Discount_Percentage__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__ListPrice__c,
            //Added for DCP-13048 sales Order Sync
            Apttus_Proposal__Proposal_Line_Item__c.Name,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__LineNumber__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__ItemSequence__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__LineType__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__PrimaryLineNumber__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__IsPrimaryLine__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__LineStatus__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__AssetLineItemId__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__PriceType__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__SellingFrequency__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__ChargeType__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Product__c,
            Apttus_Proposal__Proposal_Line_Item__c.ERP_Line_Number__c,
            Apttus_Proposal__Proposal_Line_Item__c.Serial_Number__c,
            Apttus_Proposal__Proposal_Line_Item__c.Billing_Type__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__SellingTerm__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__ParentBundleNumber__c,
            Apttus_Proposal__Proposal_Line_Item__c.Total_Discount_Percentage__c,
            Apttus_Proposal__Proposal_Line_Item__c.Total_Discount_Amount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Distributor_Specific_Discount_Percentage__c,
            Apttus_Proposal__Proposal_Line_Item__c.Distributor_Specific_Discount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__BillingFrequency__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Proposal__c,
            Apttus_Proposal__Proposal_Line_Item__c.Derived_From_Name__c,
            Apttus_Proposal__Proposal_Line_Item__c.Sales_Discretionary_Type__c,
            Apttus_Proposal__Proposal_Line_Item__c.Sales_Discretionary_Discount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Customer_Price_Per_Unit__c,
            Apttus_Proposal__Proposal_Line_Item__c.Customer_Net_Price__c,
            Apttus_Proposal__Proposal_Line_Item__c.Distributor_Rebate__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__OptionId__c,
            Apttus_Proposal__Proposal_Line_Item__c.Price_Override__c,
            Apttus_Proposal__Proposal_Line_Item__c.Beadchip_Part_Number__c,
            Apttus_Proposal__Proposal_Line_Item__c.Project_Id__c,
            Apttus_Proposal__Proposal_Line_Item__c.List_Price__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__PriceAdjustmentAmount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Max_Samples_Allowed_Per_kit__c,
            Apttus_Proposal__Proposal_Line_Item__c.Price_per_sample__c,
            Apttus_Proposal__Proposal_Line_Item__c.Total_List_Price__c,
            Apttus_Proposal__Proposal_Line_Item__c.Customer_Premium_Amount_Per_Unit__c,
            Apttus_Proposal__Proposal_Line_Item__c.Distributor_Specific_Price__c,
            Apttus_Proposal__Proposal_Line_Item__c.Program_Type__c,
            Apttus_Proposal__Proposal_Line_Item__c.Equipment_Id__c,
            //DCP-30367 Added by Rahul B for renewal Opportunity
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__StartDate__c,
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__EndDate__c,
            //Added by Rahul for Catalyst
            Apttus_Proposal__Proposal_Line_Item__c.Suggested_Sales_Discount_Percentage__c,
            Apttus_Proposal__Proposal_Line_Item__c.Suggested_Sales_Discount_Amount__c,
            Apttus_Proposal__Proposal_Line_Item__c.Meets_Discount_Guidelines__c,
            //DCP - 31269
            Apttus_Proposal__Proposal_Line_Item__c.Previous_ERP_Contract_Line_Number__c,
            Apttus_Proposal__Proposal_Line_Item__c.Instance_Region__c,
            Apttus_Proposal__Proposal_Line_Item__c.Domain_Name__c,
            Apttus_Proposal__Proposal_Line_Item__c.Previous_ERP_Contract_Number__c,
            Apttus_Proposal__Proposal_Line_Item__c.Registrant_Contact__c,
            Apttus_Proposal__Proposal_Line_Item__c.Service_Connectivity__c,
            Apttus_Proposal__Proposal_Line_Item__c.Custom_License_Flag__c,
            Apttus_Proposal__Proposal_Line_Item__c.Custom_Licensing_Description__c,
            //DCP-31767 Added for informatics fields
            Apttus_Proposal__Proposal_Line_Item__c.Product_Family__c,
            Apttus_Proposal__Proposal_Line_Item__c.Product_Type__c,
            Apttus_Proposal__Proposal_Line_Item__c.Product_Tier__c,
            Apttus_Proposal__Proposal_Line_Item__c.Is_Informatics_Product__c,
            Apttus_Proposal__Proposal_Line_Item__c.Is_iCredit__c,
            Apttus_Proposal__Proposal_Line_Item__c.Is_Dragen__c,
            //DCP-41818
            Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__DerivedFromId__c,
            // DCP-31776
            Apttus_Proposal__Proposal_Line_Item__c.Existing_Subscription__c,
            Apttus_Proposal__Proposal_Line_Item__c.Renewal_Subscription__c,
            Apttus_Proposal__Proposal_Line_Item__c.CurrencyIsoCode,
            Apttus_Proposal__Proposal_Line_Item__c.Manual_Rebate__c,
            Apttus_Proposal__Proposal_Line_Item__c.Signed_Open_Offer__c,
            Apttus_Proposal__Proposal_Line_Item__c.Open_Offer_Comparison_Customer__c,
            Apttus_Proposal__Proposal_Line_Item__c.Open_Offer_Product__c,
            Apttus_Proposal__Proposal_Line_Item__c.Custom_Setup_Details__c,
            Apttus_Proposal__Proposal_Line_Item__c.Manual_Rebate_Per_Unit__c,
            Apttus_Proposal__Proposal_Line_Item__c.Select_Instance_Type__c,
            Apttus_Proposal__Proposal_Line_Item__c.Primary_Email__c,
            Apttus_Proposal__Proposal_Line_Item__c.Server_Connectivity__c,
            Apttus_Proposal__Proposal_Line_Item__c.Trade_In_Type__c
        };
    }

    // /*
    //  * @Author : Sravan Panchangam
    //  * @Description : DCP-13048 Sales Order Sync-fetching the Id from Apttus_Proposal__Proposal_Line_Item__c
    //  */
    // public List<Apttus_Proposal__Proposal_Line_Item__c> fetchQuoteLineERPid(Set<String> ERPLinenumber)
    // {
    //     ilib_LogQuery logger = new ilib_LogQuery(
    //         LOG_TITLE + '.fetchQuoteLineERPid',
    //         UtilsCollection.serializeIds(ERPLinenumber)
    //     );

    //     List<Apttus_Proposal__Proposal_Line_Item__c> res = [
    //         SELECT Applied_Discount_Amount__c, Applied_Discount_Details__c, Applied_Discount_Percentage__c, Approval_Category__c, Approval_Level_Promotion__c, Apttus_Proposal__Product__c, Apttus_Proposal__Proposal__c, Apttus_Proposal__Quantity__c, Apttus_QPApprov__Approval_Status__c, Apttus_QPConfig__AdjustedPrice__c, Apttus_QPConfig__AdjustmentAmount__c, Apttus_QPConfig__AdjustmentType__c, Apttus_QPConfig__AssetLineItemId__c, Apttus_QPConfig__BillingFrequency__c, Apttus_QPConfig__ChargeType__c, Apttus_QPConfig__DerivedFromId__c, Apttus_QPConfig__EndDate__c, Apttus_QPConfig__IsPrimaryLine__c, Apttus_QPConfig__ItemSequence__c, Apttus_QPConfig__LineNumber__c, Apttus_QPConfig__LineStatus__c, Apttus_QPConfig__LineType__c, Apttus_QPConfig__ListPrice__c, Apttus_QPConfig__NetAdjustmentPercent__c, Apttus_QPConfig__NetPrice__c, Apttus_QPConfig__OptionId__c, Apttus_QPConfig__ParentBundleNumber__c, Apttus_QPConfig__PriceAdjustmentAmount__c, Apttus_QPConfig__PriceType__c, Apttus_QPConfig__PrimaryLineNumber__c, Apttus_QPConfig__Quantity2__c, Apttus_QPConfig__SellingFrequency__c, Apttus_QPConfig__SellingTerm__c, Apttus_QPConfig__StartDate__c, Apttus_QPConfig__Uom__c, Beadchip_Part_Number__c, Billing_Type__c, Configuration_Status__c, CurrencyIsoCode, Custom_License_Flag__c, Custom_Licensing_Description__c, Customer_Net_Price__c, Customer_Premium_Amount_Per_Unit__c, Customer_Price_Per_Unit__c, Derived_From_Name__c, Discounted_Price_Per_Unit__c, Distributor_Discount_Amount__c, Distributor_Discount_Percentage__c, Distributor_Rebate__c, Distributor_Specific_Discount_Percentage__c, Distributor_Specific_Discount__c, Distributor_Specific_Price__c, Domain_Name__c, ERP_Line_Number__c, Equipment_Id__c, Existing_Subscription__c, Freight_Discount_Amount__c, Freight_Discount_Percentage__c, Id, Instance_Region__c, Is_Dragen__c, Is_Informatics_Product__c, Is_iCredit__c, List_Price__c, Material_Number__c, Max_Samples_Allowed_Per_kit__c, Meets_Discount_Guidelines__c, Name, Premium__c, Previous_ERP_Contract_Line_Number__c, Previous_ERP_Contract_Number__c, Price_Override__c, Price_per_sample__c, Product_Family__c, Product_Tier__c, Product_Type__c, Program_Type__c, Project_Id__c, Registrant_Contact__c, Renewal_Subscription__c, Sales_Discretionary_Discount__c, Sales_Discretionary_Type__c, Serial_Number__c, Service_Connectivity__c, Stacked_Discount_Amount__c, Stacked_Discount_Percentage__c, Suggested_Sales_Discount_Amount__c, Suggested_Sales_Discount_Percentage__c, Total_Discount_Amount__c, Total_Discount_Percentage__c, Total_List_Price__c
    //         FROM Apttus_Proposal__Proposal_Line_Item__c
    //         WHERE ERP_Line_number__c IN : ERPLinenumber
    //         ORDER BY Name ASC NULLS FIRST
    //     ];

    //     logger.stop(res.size());
    //     return res;
    // }




    /**
     *  @author Govind Dubey
     *  @description fetch proposal lines related to Quotes
     *  @param setQuoteIds set of Quote ids
     *  @return list of proposal line item records
     **/

    public List<Apttus_Proposal__Proposal_Line_Item__c> selectByQuoteId(Set<Id> setQuoteIds)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByQuoteId',
            UtilsCollection.serializeIds(setQuoteIds)
        );

        List<Apttus_Proposal__Proposal_Line_Item__c> res = (List<Apttus_Proposal__Proposal_Line_Item__c>)Database.query(
            newQueryFactory()
            .selectField('Apttus_QPConfig__BillingFrequency__c')
            .selectField('ERP_Line_Number__c')
            .selectField('Apttus_Proposal__Product__c')
            .selectField('Sold_To_Sales_Organization__c')
            .selectField('Apttus_Proposal__Product__r.Name')
            .selectField('Apttus_Proposal__Product__r.ProductCode')
            .selectField('Apttus_Proposal__Product__r.Bundle_Id__c')
            .selectField('Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c')
            .selectField('Apttus_Proposal__Product__r.Description')
            .selectField('Apttus_Proposal__Product__r.Material_Type__c')
            .selectField('Apttus_QPConfig__Quantity2__c')
            .selectField('Apttus_QPConfig__StartDate__c')
            .selectField('Apttus_QPConfig__EndDate__c')
            .selectField('Apttus_QPConfig__NetUnitPrice__c')
            .selectField('Apttus_QPConfig__NetPrice__c')
            .selectField('Material_Class_Type__c')
            .selectField('Shipping_In_Close_Quarter__c')
            .selectField('Shipping_In_1Q_After_Close_Quarter__c')
            .selectField('Shipping_In_2Q_After_Close_Quarter__c')
            .selectField('Term_Months__c')
            .selectField('Server_Connectivity__c')
            .selectField('Apttus_Proposal__Product__r.End_Of_Sale_Date__c')
            .selectField('Control_Code_India_SAC__c')
            .selectField('Commodity_Import_Code_India_HSN__c')
            .selectField('Apttus_Proposal__Product__r.End_Of_Service_Date__c')
            .selectField('Apttus_Proposal__Product__r.Material_Number__c')
            .selectField('Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c')
            .selectField('Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c')
            .selectField('Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c')
            .selectField('Apttus_QPConfig__OptionId__r.Material_Number__c')
            .selectField('Apttus_QPConfig__OptionId__r.Name')
            .selectField('Product_Indicator__c')
            .selectField('Apttus_Proposal__Proposal__r.Quote_Type__c')
            .selectField('Apttus_Proposal__Proposal__r.Name')
            .selectField('Apttus_Proposal__Product__r.Material_Class_Type__c')
            .selectField('Apttus_Proposal__Proposal__r.Direct_Sale_to_Ultimate_Consignee__c')
            .selectField('Apttus_QPConfig__OptionId__c')
            .selectField('Apttus_QPConfig__LineNumber__c')
            .selectField('Registrant_Contact__r.PGUID__c')
            .selectField('Registrant_Contact__r.Email')
            .selectField('Previous_ERP_Contract_Number__c')
            .selectField('Previous_ERP_Contract_Line_Number__c')
            .selectField('Instance_Region__c')
            .selectField('Service_Connectivity__c')
            .selectField('Custom_License_Setup_Required__c')
            .selectField('Custom_Setup_Required__c')
            .selectField('Is_Dragen__c')
            .selectField('Open_Offer_Max__c')
            .selectField('Trade_In_Type__c')
            .selectField('currencyIsoCode')
            .selectField('List_Price__c')
            .selectField('Material_Class__c') 
            .selectField('Price_Override__c') 
            .selectField('Customer_Historical_Discount__c') 
            .selectField('Total_Discount_Percentage__c') 
            .selectField('Distributor_Specific_Discount_Percentage__c')
            .selectField('Apttus_Proposal__Product__r.Name') 
            .selectField('Customer_Net_Price__c') 
            .selectField('Distributor_Rebate__c') 
            .selectField('Derived_From_Name__c') 
            .selectField('Apttus_QPConfig__PriceListId__r.currencyIsoCode') 
            .selectField('Apttus_QPConfig__Quantity2__c') 
            .selectField('Apttus_Proposal__Product__r.Custom_Product__c')
            .selectField('Apttus_Proposal__Product__r.Product_Line_ilmn__c')
            .selectField('Apttus_Proposal__Proposal__r.Sold_To_Account_Name__c')
            .selectField('Apttus_Proposal__Proposal__r.currencyIsoCode')
            .selectField('Apttus_Proposal__Proposal__r.Apttus_QPConfig__PriceListId__r.currencyIsoCode')
            .selectField('Apttus_Proposal__Proposal__r.Apttus_Proposal__Opportunity__c')
            .selectField('Apttus_Proposal__Proposal__r.Apttus_Proposal__Opportunity__r.CloseDate')
            .selectField('Apttus_Proposal__Proposal__r.SAP_Quote__c')
            .selectField('Apttus_Proposal__Proposal__r.Sub_Region_UC__c')
            .selectField('Apttus_Proposal__Proposal__r.Region_Ultimate_Consignee__c')
            .setCondition('Apttus_Proposal__Proposal__c  IN :setQuoteIds')
            .addOrdering('Apttus_QPConfig__LineNumber__c', ilib_QueryFactory.SortOrder.ASCENDING)
            .addOrdering('Apttus_QPConfig__OptionId__r.Apttus_Config2__ConfigurationType__c', ilib_QueryFactory.SortOrder.ASCENDING)
            .toSOQL()
        );

        logger.stop(res.size());
        return res;
    }

    /**
     *  @author Govind Dubey
     *  @description fetch deleted proposal lines related to Quotes
     *  @param setProposalLineItems set of Proposal Line Item ids
     *  @return list of proposal line item records
     **/
    public List<Apttus_Proposal__Proposal_Line_Item__c> selectAllRecycleRowsProposalLineItems(Set<Id> setProposalLineItems)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectAllRecycleRowsProposalLineItems',
            UtilsCollection.serializeIds(setProposalLineItems)
        );

        string strQueryString;
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN :setProposalLineItems');
        strQueryString = query.toSOQL();
        strQueryString = strQueryString + ' ALL ROWS';

        List<Apttus_Proposal__Proposal_Line_Item__c> res = (List<Apttus_Proposal__Proposal_Line_Item__c>)Database.query(
            strQueryString
        );

        logger.stop(res.size());
        return res;
    }

    /*
     * @Author : Govind Dubey
     * @Description : fetch Apttus_Proposal__Proposal_Line_Item__c by id
     */
    public List<Apttus_Proposal__Proposal_Line_Item__c> fetchQuotationLineItemById(Set<Id> setProposalLineItemIds)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchQuotationLineItemById',
            UtilsCollection.serializeIds(setProposalLineItemIds)
        );

        List<Apttus_Proposal__Proposal_Line_Item__c> res = (List<Apttus_Proposal__Proposal_Line_Item__c>) Database.query(
            newQueryFactory()
            .setCondition('Id IN :setProposalLineItemIds')
            .toSOQL()
        );

        logger.stop(res.size());
        return res;
    }

     /*
     * @Author : Vinay
     * @Description : fetch Apttus_Proposal__Proposal_Line_Item__c  (CMCM-9066)
     */
     public static List<Apttus_Proposal__Proposal_Line_Item__c> proposalsSelectByQuoteIdCurrApprval(List<Id> lineItemCurrApprval) {
        return [SELECT Id,Customer_Net_Price__c,Premium__c,Freight_Discount_Amount__c,Apttus_QPConfig__Uom__c,Apttus_Proposal__Quantity__c,Approval_Level_Promotion__c,Approval_Category__c,Apttus_Proposal__Proposal__c,Apttus_QPApprov__Approval_Status__c,
        Configuration_Status__c,Material_Number__c,Apttus_QPConfig__ListPrice__c,Applied_Discount_Amount__c,Applied_Discount_Details__c,Apttus_QPConfig__AdjustedPrice__c,Apttus_QPConfig__Quantity2__c,
        Apttus_QPConfig__NetPrice__c,Apttus_QPConfig__NetAdjustmentPercent__c,
        Apttus_QPConfig__AdjustmentAmount__c,Apttus_QPConfig__AdjustmentType__c ,Applied_Discount_Percentage__c,Freight_Discount_Percentage__c,Discounted_Price_Per_Unit__c,Distributor_Discount_Amount__c,Distributor_Discount_Percentage__c,
        Stacked_Discount_Amount__c,Stacked_Discount_Percentage__c,Name,Apttus_QPConfig__LineNumber__c,Apttus_QPConfig__ItemSequence__c,Apttus_QPConfig__LineType__c,Apttus_QPConfig__PrimaryLineNumber__c,Apttus_QPConfig__IsPrimaryLine__c,
        Apttus_QPConfig__LineStatus__c,Apttus_QPConfig__AssetLineItemId__c,Apttus_QPConfig__PriceType__c,Apttus_QPConfig__SellingFrequency__c,Apttus_QPConfig__ChargeType__c,Apttus_Proposal__Product__c,ERP_Line_Number__c,
        Serial_Number__c,Billing_Type__c,Apttus_QPConfig__SellingTerm__c,Apttus_QPConfig__ParentBundleNumber__c,Total_Discount_Percentage__c,Total_Discount_Amount__c,Distributor_Specific_Discount_Percentage__c,Distributor_Specific_Discount__c,
        Apttus_QPConfig__BillingFrequency__c,Derived_From_Name__c,Sales_Discretionary_Type__c,Sales_Discretionary_Discount__c,Customer_Price_Per_Unit__c,Distributor_Rebate__c,Apttus_QPConfig__OptionId__c,Price_Override__c,
        Beadchip_Part_Number__c,Project_Id__c,List_Price__c,Apttus_QPConfig__PriceAdjustmentAmount__c,Max_Samples_Allowed_Per_kit__c,Price_per_sample__c,Total_List_Price__c,Customer_Premium_Amount_Per_Unit__c,Distributor_Specific_Price__c,
        Program_Type__c,Equipment_Id__c,Apttus_QPConfig__StartDate__c,Apttus_QPConfig__EndDate__c,Suggested_Sales_Discount_Percentage__c,Suggested_Sales_Discount_Amount__c,Meets_Discount_Guidelines__c,Previous_ERP_Contract_Line_Number__c,
        Instance_Region__c,Domain_Name__c,Previous_ERP_Contract_Number__c,Registrant_Contact__c,Service_Connectivity__c,Custom_License_Flag__c,Custom_Licensing_Description__c,Product_Family__c,Product_Type__c,Product_Tier__c,
        Is_Informatics_Product__c,Is_iCredit__c,Is_Dragen__c,Apttus_QPConfig__DerivedFromId__c,Existing_Subscription__c,Renewal_Subscription__c,CurrencyIsoCode,Manual_Rebate__c,Signed_Open_Offer__c,Open_Offer_Comparison_Customer__c,
        Open_Offer_Product__c,Custom_Setup_Details__c,Manual_Rebate_Per_Unit__c,Select_Instance_Type__c,Primary_Email__c,Server_Connectivity__c,Sold_To_Sales_Organization__c,Apttus_Proposal__Product__r.Name,Apttus_Proposal__Product__r.ProductCode,
        Apttus_Proposal__Product__r.Bundle_Id__c,Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c,Apttus_Proposal__Product__r.Description,Apttus_Proposal__Product__r.Material_Type__c,Apttus_QPConfig__NetUnitPrice__c,
        Material_Class_Type__c,Shipping_In_Close_Quarter__c,Shipping_In_1Q_After_Close_Quarter__c,Shipping_In_2Q_After_Close_Quarter__c,Term_Months__c,Apttus_Proposal__Product__r.End_Of_Sale_Date__c,Control_Code_India_SAC__c,
        Commodity_Import_Code_India_HSN__c,Apttus_Proposal__Product__r.End_Of_Service_Date__c,Apttus_Proposal__Product__r.Material_Number__c,Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c,Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c,
        Apttus_QPConfig__OptionId__r.Material_Number__c,Apttus_QPConfig__OptionId__r.Name,Product_Indicator__c,Apttus_Proposal__Proposal__r.Quote_Type__c,Apttus_Proposal__Proposal__r.Name,Apttus_Proposal__Product__r.Material_Class_Type__c,
        Registrant_Contact__r.PGUID__c,Registrant_Contact__r.Email,Custom_License_Setup_Required__c,Custom_Setup_Required__c,Open_Offer_Max__c,Trade_In_Type__c,Sales_Approval_Threshold__c,Median_Discount_Guidance__c,Max_Discount_Guidance__c,
        Submitter_Notes__c,Customer_Historical_Discount__c,Approval_Level_Product__c,Approval_Level_UC_Discount__c,Apttus_QPConfig__ExtendedPrice__c,Approval_Level_Record_Owner__c
        FROM Apttus_Proposal__Proposal_Line_Item__c
        WHERE Id IN :lineItemCurrApprval
        ];
    }


    /*
     * @Author : Sravan Panchangam
     * @Description : DCP-13048 Sales Order Sync-fetching the Id from Apttus_Proposal__Proposal_Line_Item__c
     */
    public List<Apttus_Proposal__Proposal_Line_Item__c> fetchQuoteLineItemId(Set<String> setProposalLineItemIds)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchQuoteLineItemId',
            UtilsCollection.serializeIds(setProposalLineItemIds)
        );

        List<Apttus_Proposal__Proposal_Line_Item__c> res = (List<Apttus_Proposal__Proposal_Line_Item__c>) Database.query(
            newQueryFactory()
            .setCondition('Name IN :setProposalLineItemIds')
            .toSOQL()
        );

        logger.stop(res.size());
        return res;
    }

    // public List<Apttus_Proposal__Proposal_Line_Item__c> fetchQuoteLineERPid(Set<String> ERPLinenumber)
    // {
    //     ilib_LogQuery logger = new ilib_LogQuery(
    //         LOG_TITLE + '.fetchQuoteLineERPid',
    //         UtilsCollection.serializeIds(ERPLinenumber)
    //     );

    //     List<Apttus_Proposal__Proposal_Line_Item__c> res = (List<Apttus_Proposal__Proposal_Line_Item__c>) Database.query(
    //         newQueryFactory()
    //         .setCondition('ERP_Line_number__c IN : ERPLinenumber')
    //         .toSOQL()
    //     );

    //     logger.stop(res.size());
    //     return res;
    // }

}