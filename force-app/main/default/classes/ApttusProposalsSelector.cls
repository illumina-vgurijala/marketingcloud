/**
 *    @author Rohan Chandarana
 *    @date   2018-05-15
 *    @description  quote queries
 *    Modification Log:
 *    --------------------------------------------------------------------------------------------------------------------
 *    Developer                    Date               Description
 *    Rohan                        15 May-2018        Initial Version
 *    Rahul                        08-Sep-2018        Get Valid Quotes
 *    Rahul                        20-Sep-2018        Added SelectField to selectValidQuote
 *    Roopal                       26-Sep-2018        Renamed Global_Language to Post_Pricing_Message__c
 *    Akash                        30-Oct-2018        Retrieve single Proposal Object by Record Id
 *    Satya Swain                  04 Sep 2019        Added cache for selectByQuoteId method as part of INC0225110
 *    Saswati                      27 Sep 2019        Added Fapiao Type fields for DCP-28565
 *    Joshith k                    28-Nov-2019        Added Select field to selectByQuoteId method for INC0235038
 *    Rahul                        05-Dec-2019        Added field Informatics_Quotation_c__c for DCP-30367
 *    Rahul                        14 Jan 2020        DCP-32794 Removed Field Software Id
 *    Anish                        21 Feb 2020        DCP-29629: Added fields for Canadian template
 *    Rishab                       14 May 2020        DCP-34910: Added field for Validate Cart Story
 *    Prabhsimran Singh            09 Jun 2020        DCP-37888: Added field for Generate Cart Story
 *    Roopal Verma                 24 Mar 2021        DCP-45303: Added view_contract__c
 *    Rishab                       23 Mar 2021        DCP-45455: Added Method to get Primary and valid quotes
 *    Anish                        24 Mar 2021        DCP-45455: Added Method to get all quotes for opportunities
 *    Todd                         26 Mar 2021        DCP-45737: Added instrumentation and converted most queries to SOQL for performance gains
 *    Akshay Mohan                 04 May 2021        DCP-38808: Add work order lookup.
 *    Adyasha Satapathy            12 May 2021        DCP-46872: Added fields for Product Interest and WorkOrder
 *    Akshay Mohan                 06 May 2021        DCP-38809: Add Submit_For_Approval__c,Approval_Category__c,Approval_Hierarchy_Record_Owner__c,Approval_Hierarchy_Transborder__c,Generate__c,Territory_Region__c
*     KD                           22-June-2021       DCP-46257: Added field Inventory_Location_ERP_Number__c
 *    KD                           29-June-2021       DCP-46226: Added new field in query Billing country
 *    Aman Tyagi                   31-Mar-2022        CodeScan Fixes
 *    Nesar Mohan                  02-Jun-2022        DCP-53938: Added new field in selectById 
 *    Adithi Acharya               10-June-2022       DCP-52166 : Restore quote selector class code
 *    Khushbu Vasani               13-Jun-2022        DCP-54531 - added new fields to selectproposalbyId    
 *    Nesar Mohan                  21-Jun-2022        DCP-53207: Added a new field in getSObjectFieldList
 **   Khushbu                      04-Sept-2022       DCP-56658- Added new field in selectvalidquote
 *    Atit Kar                     21-Mar-2023        TASK0876760 - Added fields for GTC approval rule & proposal update
 *    Balakrishna                  25-Julay-2023      CMCM-803- Added field Apttus_Proposal__Opportunity__c in selectByQuotationId method.
 *    Rajbabu Boopalan             21-Oct-2023        CMCM-2523 Annual Pricing Date Change management
 *    Arquimidez Mora              13-Aug-2024        CMCM-9645 Added new method selectQuotesWithFields
 *  ----------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class ApttusProposalsSelector extends ilib_SObjectSelector
{
    private final String LOG_TITLE = 'ApttusProposalsSelector';

    /**
     *  @author Rohan Chandarana
     *  @description
     *  @return SObjectType The Schema.SObjectType of the proposal
     **/

    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Proposal__Proposal__c.sObjectType;
    }

    /**
     *  @author  Rohan Chandarana
     *  @description Retrieve list of fields for Proposals sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
            Apttus_Proposal__Proposal__c.Id,
            Apttus_Proposal__Proposal__c.Bill_To__c,
            Apttus_Proposal__Proposal__c.Ship_To__c,
            Apttus_Proposal__Proposal__c.Apttus_QPApprov__Approval_Status__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Approval_Stage__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c,
            Apttus_Proposal__Proposal__c.Cloned_From__c,
            Apttus_Proposal__Proposal__c.Name,
            Apttus_Proposal__Proposal__c.Ship_To_ERP_Number__c,
            Apttus_Proposal__Proposal__c.CurrencyIsoCode,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Discount_Percent__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__ExpectedStartDate__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Amount__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__ExpectedEndDate__c,
            Apttus_Proposal__Proposal__c.Post_Pricing_Message__c,
            Apttus_Proposal__Proposal__c.Discount_Reason__c,
            Apttus_Proposal__Proposal__c.Discount_Reason_Definition__c,
            Apttus_Proposal__Proposal__c.Discount_Justification__c,
            Apttus_Proposal__Proposal__c.Quote_Total_Value_Prior_To_Discount__c,
            Apttus_Proposal__Proposal__c.Total_Cart_Discount__c,
            Apttus_Proposal__Proposal__c.Blended_Discount_Percentage__c,
            Apttus_Proposal__Proposal__c.Quote_Total_Value_After_Discount__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary_Contact__c,
            Apttus_Proposal__Proposal__c.Invalid_Quote__c,
            Apttus_Proposal__Proposal__c.MyIllumina_User_Email__c,
            Apttus_Proposal__Proposal__c.Distributor__c,
            Apttus_Proposal__Proposal__c.SAP_Quote__c,
            Apttus_Proposal__Proposal__c.Is_Updated_By_System__c,
            Apttus_Proposal__Proposal__c.Promo_Channel_1__c,
            Apttus_Proposal__Proposal__c.Promo_Code_1__c,
            Apttus_Proposal__Proposal__c.Promo_Channel_2__c,
            Apttus_Proposal__Proposal__c.Promo_Code_2__c,
            Apttus_Proposal__Proposal__c.Promo_Channel_3__c,
            Apttus_Proposal__Proposal__c.Promo_Code_3__c,
            Apttus_Proposal__Proposal__c.Ultimate_Consignee__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__ExpectedEndDate__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__ExpectedStartDate__c,
            Apttus_Proposal__Proposal__c.Apttus_QPConfig__PriceListId__c,
            Apttus_Proposal__Proposal__c.CurrencyIsoCode,
            Apttus_Proposal__Proposal__c.Apttus_QPConfig__PricingDate__c,
            Apttus_Proposal__Proposal__c.Sold_To_ERP_Number__c,
            Apttus_Proposal__Proposal__c.Ultimate_Consignee_ERP_Number__c,
            Apttus_Proposal__Proposal__c.Bill_To_ERP_Number__c,
            Apttus_Proposal__Proposal__c.Informatics_Quotation_c__c, //DCP-30367
            Apttus_Proposal__Proposal__c.Payer_ERP_Number__c,
            Apttus_Proposal__Proposal__c.Informatics_Product_Line_Item_Numbers__c,  //DCP-30368
            Apttus_Proposal__Proposal__c.Distributor_ERP_Number__c,
            Apttus_Proposal__Proposal__c.Name,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c,
            Apttus_Proposal__Proposal__c.MyIllumina_User_Email__c,
            Apttus_Proposal__Proposal__c.Web_Visible__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Payment_Term__c,
            Apttus_Proposal__Proposal__c.Quote_Type__c,
            Apttus_Proposal__Proposal__c.Ship_To__c,
            Apttus_Proposal__Proposal__c.Payer__c,
            Apttus_Proposal__Proposal__c.Ultimate_Consignee__c,
            Apttus_Proposal__Proposal__c.Distributor__c,
            Apttus_Proposal__Proposal__c.Total_Net__c,
            Apttus_Proposal__Proposal__c.Total_Discount__c,
            Apttus_Proposal__Proposal__c.Estimated_Freight__c,
            Apttus_Proposal__Proposal__c.Estimated_Tax__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary_Contact__c,
            Apttus_Proposal__Proposal__c.Sold_To_ERP_Number__c.Name,
            Apttus_Proposal__Proposal__c.Post_Pricing_Message_List__c,
            Apttus_Proposal__Proposal__c.Preferred_Language__c,
            Apttus_Proposal__Proposal__c.Inco_Term_1__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Approval_Stage__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary_Contact__c,
            Apttus_Proposal__Proposal__c.Prepared_by__c,
            Apttus_Proposal__Proposal__c.Sold_to_Sales_Organization__c,
            Apttus_Proposal__Proposal__c.Sold_to_Distribution_Channel__c,
            Apttus_Proposal__Proposal__c.Sold_to_Division__c,
            Apttus_Proposal__Proposal__c.Region_Ultimate_Consignee__c,
            Apttus_Proposal__Proposal__c.Region_Distributor__c,
            Apttus_Proposal__Proposal__c.Region_Sold_To__c,
            Apttus_Proposal__Proposal__c.Indirect_Transregion_Flag__c,
            Apttus_Proposal__Proposal__c.SAP_Errors__c,
            Apttus_Proposal__Proposal__c.Direct_Sale_to_Ultimate_Consignee__c,
            Apttus_Proposal__Proposal__c.Promotion_JSON__c,
            Apttus_Proposal__Proposal__c.Opportunity_Record_Type__c,
            Apttus_Proposal__Proposal__c.Sales_Discretionary_Approval_Error__c,
            Apttus_Proposal__Proposal__c.Quote_Sub_Type__c,
            Apttus_Proposal__Proposal__c.Post_Pricing_Message__c,
            Apttus_Proposal__Proposal__c.Subtotal__c,
            Apttus_Proposal__Proposal__c.Sub_Total__c,
            Apttus_Proposal__Proposal__c.Contract_Numbers__c,
            Apttus_Proposal__Proposal__c.Fapiao_Type_Code__c, //DCP-28565
            Apttus_Proposal__Proposal__c.Fapiao_Type_Description__c, //DCP-28565
            Apttus_Proposal__Proposal__c.Last_Generate_Success__c, //DCP-37888
            Apttus_Proposal__Proposal__c.Last_Validation_Id__c, //DCP-37888
            Apttus_Proposal__Proposal__c.Generate_In_Progress__c, //DCP-37888
            Apttus_Proposal__Proposal__c.Async_Generation_Complete__c, //DCP-37888
            Apttus_Proposal__Proposal__c.View_Contract__c, //DCP-45303

            //DCP-52166
            Apttus_Proposal__Proposal__c.Approval_Category__c,
            Apttus_Proposal__Proposal__c.BDR_Deal_Governing_Terms__c,
            Apttus_Proposal__Proposal__c.Estimated_Presentation_Date__c,
            Apttus_Proposal__Proposal__c.Informatics_Line_Item_Number__c,
            Apttus_Proposal__Proposal__c.Open_Offer_Discount_Exception_Request__c,
            Apttus_Proposal__Proposal__c.Open_Offer_Discount_Violation_Type__c,
            Apttus_Proposal__Proposal__c.Quote_For_Open_Offer_Customer__c,
            Apttus_Proposal__Proposal__c.Quote_Has_Open_Offer_Product__c,
            Apttus_Proposal__Proposal__c.Quote_Total_Value_Prior_To_DiscountUSD__c,
            Apttus_Proposal__Proposal__c.Sold_To_Account_Region__c,
            Apttus_Proposal__Proposal__c.Work_Order__c,
            Apttus_Proposal__Proposal__c.Number_of_MFN_Line_Items__c,
            Apttus_Proposal__Proposal__c.Apttus_Proposal__Proposal_Name__c,
            Apttus_Proposal__Proposal__c.Submit_For_Approval__c,
            Apttus_Proposal__Proposal__c.Approval_Hierarchy_Record_Owner__c,
            Apttus_Proposal__Proposal__c.Approval_Hierarchy_Transborder__c,
            Apttus_Proposal__Proposal__c.Generate__c,
            Apttus_Proposal__Proposal__c.Territory_Region__c,
            Apttus_Proposal__Proposal__c.Async_Validation_Complete__c,
            Apttus_Proposal__Proposal__c.OwnerId,
            Apttus_Proposal__Proposal__c.Validation_In_Progress__c,
            Apttus_Proposal__Proposal__c.Inventory_Location_ERP_Number__c, //INC0421167
            Apttus_Proposal__Proposal__c.Open_Offer_Legal_Approver_Comments__c, //DCP-53207, INC0421167
            //TASK0876760 : Start
            Apttus_Proposal__Proposal__c.Sub_Region_Sold_To__c,
            Apttus_Proposal__Proposal__c.Business_Unit_Sold_To__c,
            Apttus_Proposal__Proposal__c.Sub_Region_UC__c,
            Apttus_Proposal__Proposal__c.Business_Unit_UC__c,
            Apttus_Proposal__Proposal__c.Sub_Region_Distributor__c,
            Apttus_Proposal__Proposal__c.Business_Unit_Distributor__c
            //TASK0876760 : End
        };
    }

    ///////////////////////////////////////
    // Queries by Quote Criteria
    ///////////////////////////////////////
    // NOTE: first three methods were replaced by plain SOQL for performance
    // old methods are at the bottom of the class if we want to go back prior to May 2021

   

    //DCP-52166

    /*
    public List<Apttus_Proposal__Proposal__c> selectById(Set<ID> idSet)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectById',
            UtilsCollection.serializeIds(idSet)
        );
        List<Apttus_Proposal__Proposal__c> res = [
                
            SELECT Apttus_Proposal__Account__c, Apttus_Proposal__Amount__c, Apttus_Proposal__Approval_Stage__c, Apttus_Proposal__Discount_Percent__c, Apttus_Proposal__ExpectedEndDate__c, Apttus_Proposal__ExpectedStartDate__c, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Payment_Term__c, Apttus_Proposal__Primary_Contact__c, Apttus_Proposal__Primary__c, Apttus_QPApprov__Approval_Status__c, Apttus_QPConfig__PriceListId__c, Apttus_QPConfig__PricingDate__c, Async_Generation_Complete__c, Bill_To_ERP_Number__c, Bill_To__c, Blended_Discount_Percentage__c, Cloned_From__c, Contract_Numbers__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Discount_Justification__c, Discount_Reason__c, Distributor_ERP_Number__c, Distributor__c, Estimated_Freight__c, Estimated_Tax__c, Fapiao_Type_Code__c, Fapiao_Type_Description__c, Generate_In_Progress__c, Id, Inco_Term_1__c, Indirect_Transregion_Flag__c, Informatics_Product_Line_Item_Numbers__c, Informatics_Quotation_c__c, Invalid_Quote__c, Is_Updated_By_System__c, Last_Generate_Success__c, Last_Validation_Id__c, MyIllumina_User_Email__c, Name, Opportunity_Record_Type__c, Payer_ERP_Number__c, Payer__c, Post_Pricing_Message_List__c, Post_Pricing_Message__c, Preferred_Language__c, Prepared_by__c, Promo_Channel_1__c, Promo_Channel_2__c, Promo_Channel_3__c, Promo_Code_1__c, Promo_Code_2__c, Promo_Code_3__c, Promotion_JSON__c, Quote_Sub_Type__c, Quote_Total_Value_After_Discount__c, Quote_Total_Value_Prior_To_Discount__c, Quote_Type__c, Region_Distributor__c, Region_Sold_To__c, Region_Ultimate_Consignee__c, SAP_Errors__c, SAP_Quote__c, Sales_Discretionary_Approval_Error__c, Ship_To_ERP_Number__c, Ship_To__c, Sold_To_Distribution_Channel__c, Sold_To_Division__c, Sold_To_ERP_Number__c, Sold_To_Sales_Organization__c, Sub_Total__c, Subtotal__c, Total_Cart_Discount__c, Total_Discount__c, Total_Net__c, Ultimate_Consignee_ERP_Number__c, Ultimate_Consignee__c, View_Contract__c, Web_Visible__c,
                    Work_Order__c,//DCP-38809
                    Work_Order__r.Owner.Email,//DCP-38809
                    Work_Order__r.Owner.Type,//DCP-38809
                    Work_Order__r.Account_Region__c,//DCP-38809
                    Work_Order__r.OwnerId,//DCP-38809
                    Work_Order__r.Name,//DCP-38809
                    Submit_For_Approval__c,//DCP-38809
                    Approval_Category__c,//DCP-38809
                    Approval_Hierarchy_Record_Owner__c,//DCP-38809
                    Approval_Hierarchy_Transborder__c,//DCP-38809
                    Generate__c,//DCP-38809
                    Territory_Region__c,//DCP-38809
                    Apttus_Proposal__Proposal_Name__c, //TASK0573816
                    Number_of_MFN_Line_Items__c,
                    Quote_Has_Open_Offer_Product__c, //DCP-53938
                    Open_Offer_Product_Type__c

            FROM Apttus_Proposal__Proposal__c
            WHERE Id IN :idSet
            ORDER BY Name ASC NULLS FIRST
        ];
        logger.stop(res.size());
        return res;
    }
    */


    /**
     *  @author Satya Swain
     *  @description fetch proposals for the ids passed in the argument and related list passed in method call
     *  @param setQuoteIds set of proposal ids
     *  @return proposalList list of proposal records
     **/

    /*
    public List<Apttus_Proposal__Proposal__c> selectByQuoteId(Set<ID> setQuoteIds)
    {
        String serialized = UtilsCollection.serializeIds(setQuoteIds);
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByQuoteId',
            serialized
        );

        if (cacheForSelectByQuoteId.containsKey(serialized))
        return cacheForSelectByQuoteId.get(serialized); 

        List<Apttus_Proposal__Proposal__c> res = [
             SELECT Apttus_Proposal__Account__c, Apttus_Proposal__Amount__c, Apttus_Proposal__Approval_Stage__c,Quote_Total_Value_Prior_To_DiscountUSD__c,Sold_To_Account_Region__c,BDR_Deal_Governing_Terms__c,Estimated_Presentation_Date__c, Apttus_Proposal__Discount_Percent__c, Apttus_Proposal__ExpectedEndDate__c, Apttus_Proposal__ExpectedStartDate__c, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Payment_Term__c, Apttus_Proposal__Primary_Contact__c, Apttus_Proposal__Primary__c, Apttus_QPApprov__Approval_Status__c, Apttus_QPConfig__PriceListId__c, Apttus_QPConfig__PricingDate__c, Async_Generation_Complete__c, Bill_To_ERP_Number__c, Bill_To__c, Blended_Discount_Percentage__c, Cloned_From__c, Contract_Numbers__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Discount_Justification__c, Discount_Reason__c, Distributor_ERP_Number__c, Distributor__c, Estimated_Freight__c, Estimated_Tax__c, Fapiao_Type_Code__c, Fapiao_Type_Description__c, Generate_In_Progress__c, Id, Inco_Term_1__c, Indirect_Transregion_Flag__c, Informatics_Product_Line_Item_Numbers__c, Informatics_Quotation_c__c, Invalid_Quote__c, Is_Updated_By_System__c, Last_Generate_Success__c, Last_Validation_Id__c, MyIllumina_User_Email__c, Name, Opportunity_Record_Type__c, Payer_ERP_Number__c, Payer__c, Payment_Term_Description__c, Post_Pricing_Message_List__c, Post_Pricing_Message__c, Preferred_Language__c, Prepared_by__c, Promo_Channel_1__c, Promo_Channel_2__c, Promo_Channel_3__c, Promo_Code_1__c, Promo_Code_2__c, Promo_Code_3__c, Promotion_JSON__c, Quote_Sub_Type__c, Quote_Total_Value_After_Discount__c, Quote_Total_Value_Prior_To_Discount__c, Quote_Type__c, Region_Distributor__c, Region_Sold_To__c, Region_Ultimate_Consignee__c, SAP_Errors__c, SAP_Quote__c, Sales_Discretionary_Approval_Error__c, Ship_To_ERP_Number__c, Ship_To__c, Sold_To_Distribution_Channel__c, Sold_To_Division__c, Sold_To_ERP_Number__c, Sold_To_Sales_Organization__c, Sub_Total__c, Subtotal__c, Total_Cart_Discount__c, Total_Discount__c, Total_Net__c, Total_Number_Of_Samples__c, Ultimate_Consignee_ERP_Number__c, Ultimate_Consignee__c, View_Contract__c, Web_Visible__c, Apttus_Proposal__Account__r.BillingCountry, Apttus_Proposal__Account__r.Name, Apttus_Proposal__Account__r.OwnerId, Apttus_Proposal__Account__r.Territory_Region__c, Apttus_Proposal__Opportunity__r.AccountId, Apttus_Proposal__Opportunity__r.Contract_Number__c, Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_Proposal__Opportunity__r.Distributor__c, Apttus_Proposal__Opportunity__r.Name, Apttus_Proposal__Opportunity__r.Probability, Apttus_Proposal__Opportunity__r.Rev_Rec_Terms__c, Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c, Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c, Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c, Apttus_Proposal__Opportunity__r.Sales_Org_Override__c, Apttus_Proposal__Opportunity__r.StageName, Apttus_Proposal__Opportunity__r.Transborder_Flag__c, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c, Apttus_Proposal__Primary_Contact__r.Email, Bill_To__r.ERP_Customer_Id__c, Distributor__r.BillingCountry, Distributor__r.BillingCountryCode, Distributor__r.Name, Distributor__r.OwnerId, Distributor__r.Territory_Region__c, Owner.Id, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.BillingCountryCode, Ultimate_Consignee__r.Name, Ultimate_Consignee__r.OwnerId, Ultimate_Consignee__r.Territory_Region__c, Apttus_Proposal__Opportunity__r.Account.Apttus_Config2__PaymentTermId__c, Apttus_Proposal__Opportunity__r.Account.BillingCountry, Apttus_Proposal__Opportunity__r.Account.BillingCountryCode, Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c, Apttus_Proposal__Opportunity__r.Account.Name, Apttus_Proposal__Opportunity__r.Consortium__r.Minimum_Sample_Amount__c, Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c, Apttus_Proposal__Opportunity__r.Owner.Name, Apttus_Proposal__Opportunity__r.RecordType.DeveloperName, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountryCode, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Name, Apttus_Proposal__Opportunity__r.Product_Interest__c,Apttus_Proposal__Account__r.BillingCountryCode,Apttus_Proposal__Primary_Contact__r.Name,Prepared_by__r.Email,Ultimate_Consignee__r.Oncology_Lab_Manufacturer_Comparison__c, Apttus_Proposal__Account__r.Oncology_Lab_Manufacturer_Comparison__c,Approval_Category__c,Informatics_Line_Item_Number__c,
            Work_Order__c,Work_Order__r.Owner.Name,Work_Order__r.Name,Apttus_Proposal__Opportunity__r.Territory_Region__c,Apttus_Proposal__Account__r.Territory_Name__c , Open_Offer_Discount_Exception_Request__c,Open_Offer_Discount_Violation_Type__c,Quote_Has_Open_Offer_Product__c,Quote_For_Open_Offer_Customer__c // DCP-49598
            FROM Apttus_Proposal__Proposal__c
            WHERE Id IN :setQuoteIds
            ORDER BY Name ASC NULLS FIRST
        ];// DCP-46226
        //cacheForSelectByQuoteId.put(serialized, res);
        logger.stop(res.size());
        return res;
        // added fields
        // Payment_Term_Description__c
        // Total_Number_Of_Samples__c
        // Apttus_Proposal__Opportunity__r.Rev_Rec_Terms__c
        // Apttus_Proposal__Opportunity__r.Consortium__r.Minimum_Sample_Amount__c
        // Apttus_Proposal__Opportunity__r.Name
        // Apttus_Proposal__Opportunity__r.AccountId
        // Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c
        // Apttus_Proposal__Opportunity__r.Account.BillingCountry
        // Apttus_Proposal__Opportunity__r.Account.BillingCountryCode
        // Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c
        // Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c
        // Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry
        // Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountryCode
        // Apttus_Proposal__Opportunity__r.Distributor__c
        // Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c
        // Apttus_Proposal__Opportunity__r.RecordType.DeveloperName
        // Apttus_Proposal__Opportunity__r.StageName
        // Apttus_Proposal__Opportunity__r.Probability
        // Apttus_Proposal__Opportunity__r.Account.Apttus_Config2__PaymentTermId__c
        // Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c
        // Apttus_Proposal__Account__r.Territory_Region__c
        // Ultimate_Consignee__r.Territory_Region__c
        // Distributor__r.Territory_Region__c
        // Apttus_Proposal__Opportunity__r.Contract_Number__c
        // Apttus_Proposal__Opportunity__r.Transborder_Flag__c
        // Distributor__r.BillingCountry
        // Distributor__r.BillingCountryCode
        // Apttus_Proposal__Account__r.BillingCountry
        // Apttus_Proposal__Account__r.BillingCountryCode
        // Ultimate_Consignee__r.BillingCountry
        // Ultimate_Consignee__r.BillingCountryCode
        // Ultimate_Consignee__r.OwnerId
        // Distributor__r.OwnerId
        // Apttus_Proposal__Account__r.OwnerId
        // Apttus_Proposal__Opportunity__r.Account.Name
        // Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c
        // Bill_To__r.ERP_Customer_Id__c
        // Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c
        // Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c
        // Distributor__r.BillingCountryCode
        // Apttus_Proposal__Primary_Contact__r.Email
        // Apttus_Proposal__Account__r.Name
        // Ultimate_Consignee__r.Name
        // Distributor__r.Name
        // Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Name
        // Apttus_Proposal__Opportunity__r.Owner.Name
        // Apttus_Proposal__Opportunity__r.Sales_Org_Override__c
        // Apttus_Proposal__Primary_Contact__c
        // Owner.Id
    }
    /*
    /**
     * @author : Akash Kumar
     * @description DCP-14098 Select Proposal
     * Returns Apttus_Proposal__Proposal__c sObject Record
     **/
    /*
    public Apttus_Proposal__Proposal__c selectProposalById(String strProposalId)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectProposalById',
            strProposalId
        );
        Apttus_Proposal__Proposal__c res = [
            SELECT Apttus_Proposal__Account__c, Apttus_Proposal__Amount__c, Apttus_Proposal__Approval_Stage__c, Apttus_Proposal__Discount_Percent__c, Apttus_Proposal__ExpectedEndDate__c, Apttus_Proposal__ExpectedStartDate__c, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Payment_Term__c, Apttus_Proposal__Primary_Contact__c, Apttus_Proposal__Primary__c, Apttus_QPApprov__Approval_Status__c, Apttus_QPConfig__PriceListId__c, Apttus_QPConfig__PricingDate__c, Async_Generation_Complete__c, Async_Validation_Complete__c, Bill_To_ERP_Number__c, Bill_To__c, Blended_Discount_Percentage__c, Cloned_From__c, Contract_Numbers__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Discount_Justification__c, Discount_Reason__c, Distributor_ERP_Number__c, Distributor__c, Estimated_Freight__c, Estimated_Tax__c, Fapiao_Type_Code__c, Fapiao_Type_Description__c, Generate_In_Progress__c, Id, Inco_Term_1__c, Indirect_Transregion_Flag__c, Informatics_Product_Line_Item_Numbers__c, Informatics_Quotation_c__c, Invalid_Quote__c, Is_Updated_By_System__c, Last_Generate_Success__c, Last_Validation_Id__c, MyIllumina_User_Email__c, Name, Opportunity_Record_Type__c, OwnerId, Payer_ERP_Number__c, Payer__c, Post_Pricing_Message_List__c, Post_Pricing_Message__c, Preferred_Language__c, Prepared_by__c, Promo_Channel_1__c, Promo_Channel_2__c, Promo_Channel_3__c, Promo_Code_1__c, Promo_Code_2__c, Promo_Code_3__c, Promotion_JSON__c, Quote_Sub_Type__c, Quote_Total_Value_After_Discount__c, Quote_Total_Value_Prior_To_Discount__c, Quote_Type__c, Region_Distributor__c, Region_Sold_To__c, Region_Ultimate_Consignee__c, SAP_Errors__c, SAP_Quote__c, Sales_Discretionary_Approval_Error__c, Ship_To_ERP_Number__c, Ship_To__c, Sold_To_Distribution_Channel__c, Sold_To_Division__c, Sold_To_ERP_Number__c, Sold_To_Sales_Organization__c, Sub_Total__c, Subtotal__c, Total_Cart_Discount__c, Total_Discount__c, Total_Net__c, Ultimate_Consignee_ERP_Number__c, Ultimate_Consignee__c, Validation_In_Progress__c, View_Contract__c, Web_Visible__c, Apttus_Proposal__Account__r.BillingCountry, Apttus_Proposal__Opportunity__r.Name, Owner.Email, Owner.Name, Ship_To__r.Country__c, Apttus_Proposal__Opportunity__r.Account.Account_Status__c, Apttus_Proposal__Opportunity__r.Consortium__r.Name, Apttus_Proposal__Opportunity__r.Consortium__r.Species__c, Apttus_Proposal__Opportunity__r.Distributor__r.Account_Status__c, Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Account_Status__c, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Account_Status__c,Apttus_Proposal__Opportunity__r.Product_Interest__c, Work_Order__r.Name,Apttus_Proposal__Primary_Contact__r.Name,Apttus_Proposal__Opportunity__r.Account.Name,Apttus_Proposal__Opportunity__r.AccountId,Apttus_Proposal__Primary_Contact__r.Email,Prepared_by__r.Email,
            Inventory_Location_ERP_Number__c, // DCP-46257
            Apttus_Proposal__Account__r.Territory_Region__c//DCP-54531
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :strProposalId
            ORDER BY Name ASC NULLS FIRST
        ];// DCP-46257
        logger.stop(1);
        return res;
        // added fields
        // Apttus_Proposal__Opportunity__r.Name
        // Apttus_Proposal__Opportunity__r.Account.Account_Status__c
        // Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Account_Status__c
        // Apttus_Proposal__Opportunity__r.Distributor__r.Account_Status__c
        // Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Account_Status__c
        // Apttus_Proposal__Opportunity__r.Consortium__r.Name
        // Apttus_Proposal__Opportunity__r.Consortium__r.Species__c
        // Apttus_Proposal__Account__r.BillingCountry
        // Ship_To__r.Country__c
        // Validation_In_Progress__c
        // Async_Validation_Complete__c
        // OwnerId
        // Owner.Name
        // Owner.Email
    }
    */

    /**
     * @author : Sravan Panchangam
     * @description DCP-9865 ERP Quote Number
     * Returns List<Apttus_Proposal__Proposal__c> with quotation
     **/
    /*
    public List<Apttus_Proposal__Proposal__c> fetchQuotation(set<String> setApttusQuoteNumber)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchQuotation',
            UtilsCollection.serializeIds(setApttusQuoteNumber)
        );
        List<Apttus_Proposal__Proposal__c> res = [
            SELECT Apttus_Proposal__Account__c, Apttus_Proposal__Amount__c, Apttus_Proposal__Approval_Stage__c, Apttus_Proposal__Discount_Percent__c, Apttus_Proposal__ExpectedEndDate__c, Apttus_Proposal__ExpectedStartDate__c, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Payment_Term__c, Apttus_Proposal__Primary_Contact__c, Apttus_Proposal__Primary__c, Apttus_QPApprov__Approval_Status__c, Apttus_QPConfig__PriceListId__c, Apttus_QPConfig__PricingDate__c, Async_Generation_Complete__c, Bill_To_ERP_Number__c, Bill_To__c, Blended_Discount_Percentage__c, Cloned_From__c, Contract_Numbers__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Discount_Justification__c, Discount_Reason__c, Distributor_ERP_Number__c, Distributor__c, Estimated_Freight__c, Estimated_Tax__c, Fapiao_Type_Code__c, Fapiao_Type_Description__c, Generate_In_Progress__c, Id, Inco_Term_1__c, Indirect_Transregion_Flag__c, Informatics_Product_Line_Item_Numbers__c, Informatics_Quotation_c__c, Invalid_Quote__c, Is_Updated_By_System__c, Last_Generate_Success__c, Last_Validation_Id__c, MyIllumina_User_Email__c, Name, Opportunity_Record_Type__c, OwnerId, Payer_ERP_Number__c, Payer__c, Post_Pricing_Message_List__c, Post_Pricing_Message__c, Preferred_Language__c, Prepared_by__c, Promo_Channel_1__c, Promo_Channel_2__c, Promo_Channel_3__c, Promo_Code_1__c, Promo_Code_2__c, Promo_Code_3__c, Promotion_JSON__c, Quote_Sub_Type__c, Quote_Total_Value_After_Discount__c, Quote_Total_Value_Prior_To_Discount__c, Quote_Type__c, Region_Distributor__c, Region_Sold_To__c, Region_Ultimate_Consignee__c, SAP_Errors__c, SAP_Quote__c, Sales_Discretionary_Approval_Error__c, Ship_To_ERP_Number__c, Ship_To__c, Sold_To_Distribution_Channel__c, Sold_To_Division__c, Sold_To_ERP_Number__c, Sold_To_Sales_Organization__c, Sub_Total__c, Subtotal__c, Total_Cart_Discount__c, Total_Discount__c, Total_Net__c, Ultimate_Consignee_ERP_Number__c, Ultimate_Consignee__c, View_Contract__c, Web_Visible__c, Owner.Email, Owner.Name
            FROM Apttus_Proposal__Proposal__c
            WHERE Name IN :setApttusQuoteNumber
            ORDER BY Name ASC NULLS FIRST
        ];
        logger.stop(res.size());
        return res;
        // added fields
        // OwnerId
        // Owner.Name
        // Owner.Email
    }
    */
    ///////////////////////////////////////
    // Queries by Opportunity Criteria
    ///////////////////////////////////////
    // NOTE: these methods were replaced by plain SOQL for performance
    // old methods are at the bottom of the class if we want to go back prior to May 2021

    /*
    public List<Apttus_Proposal__Proposal__c> selectPrimary(Set<Id> opportunityIds)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectPrimary',
            UtilsCollection.serializeIds(opportunityIds)
        );
        List<Apttus_Proposal__Proposal__c> res = (List<Apttus_Proposal__Proposal__c>)Database.query(
            getOpportunityQuery(opportunityIds, true, false)
        );
        logger.stop(res.size());
        return res;
    }
    */


    /*
    public List<Apttus_Proposal__Proposal__c> selectValidQuote(Set<Id> opportunityIds)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectValidQuote',
            UtilsCollection.serializeIds(opportunityIds)
        );
        List<Apttus_Proposal__Proposal__c> res = (List<Apttus_Proposal__Proposal__c>)Database.query(
            getOpportunityQuery(opportunityIds, false, true)
        );
        logger.stop(res.size());
        return res;
    }
    */

    /* 
    public List<Apttus_Proposal__Proposal__c> selectPrimaryAndValidQuotes(Set<Id> opportunityIds)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectPrimaryAndValidQuotes',
            UtilsCollection.serializeIds(opportunityIds)
        );
        List<Apttus_Proposal__Proposal__c> res = (List<Apttus_Proposal__Proposal__c>)Database.query(
            getOpportunityQuery(opportunityIds, true, false)
        );
        logger.stop(res.size());
        return res;
    }
    */
    /*
    private String getOpportunityQuery(Set<Id> opportunityIds, Boolean isPrimaryOnly, Boolean isValidOnly)
    {
        // add primary and valid clauses to select
        // if flags set to true
        return 'SELECT Apttus_Proposal__Account__c, Apttus_Proposal__Amount__c, Apttus_Proposal__Approval_Stage__c, Apttus_Proposal__Discount_Percent__c, Apttus_Proposal__ExpectedEndDate__c, Apttus_Proposal__ExpectedStartDate__c, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Payment_Term__c, Apttus_Proposal__Primary_Contact__c, Apttus_Proposal__Primary__c, Apttus_QPApprov__Approval_Status__c, Apttus_QPConfig__PriceListId__c, Apttus_QPConfig__PricingDate__c, Async_Generation_Complete__c, Bill_To_ERP_Number__c, Bill_To__c, Blended_Discount_Percentage__c, Cloned_From__c, Contract_Numbers__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Discount_Justification__c, Discount_Reason__c, Distributor_ERP_Number__c, Distributor__c, Estimated_Freight__c, Estimated_Tax__c, Fapiao_Type_Code__c, Fapiao_Type_Description__c, Generate_In_Progress__c, Id, Inco_Term_1__c, Indirect_Transregion_Flag__c, Informatics_Product_Line_Item_Numbers__c, Informatics_Quotation_c__c, Invalid_Quote__c, Is_Updated_By_System__c, Last_Generate_Success__c, Last_Validation_Id__c, MyIllumina_User_Email__c, Name, Opportunity_Record_Type__c, Payer_ERP_Number__c, Payer__c, Post_Pricing_Message_List__c, Post_Pricing_Message__c, Preferred_Language__c, Prepared_by__c, Promo_Channel_1__c, Promo_Channel_2__c, Promo_Channel_3__c, Promo_Code_1__c, Promo_Code_2__c, Promo_Code_3__c, Promotion_JSON__c, Quote_Sub_Type__c, Quote_Total_Value_After_Discount__c, Quote_Total_Value_Prior_To_Discount__c, Quote_Type__c, RecordTypeId, Region_Distributor__c, Region_Sold_To__c, Region_Ultimate_Consignee__c, SAP_Errors__c, SAP_Quote__c, Sales_Discretionary_Approval_Error__c, Ship_To_ERP_Number__c, Ship_To__c, Sold_To_Distribution_Channel__c, Sold_To_Division__c, Sold_To_ERP_Number__c, Sold_To_Sales_Organization__c, Sub_Total__c, Subtotal__c, Total_Cart_Discount__c, Total_Discount__c, Total_Net__c, Ultimate_Consignee_ERP_Number__c, Ultimate_Consignee__c, View_Contract__c, Web_Visible__c, Apttus_Proposal__Opportunity__r.RecordTypeId, Apttus_Proposal__Opportunity__r.Type, Apttus_Proposal__Opportunity__r.Account.Name, Apttus_Proposal__Opportunity__r.RecordType.DeveloperName, Apttus_Proposal__Opportunity__r.Account.Owner.Id, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Id,' +
            ' Apttus_Proposal__Account__r.BillingCountry '+ // // DCP-46226
            ' FROM Apttus_Proposal__Proposal__c' +
            ' WHERE Apttus_Proposal__Opportunity__c IN :opportunityIds' +
            (isPrimaryOnly ? ' AND Apttus_Proposal__Primary__c = true' : '') +
            (isValidOnly ? ' AND Invalid_Quote__c = false' : '') +
            ' ORDER BY Name ASC NULLS FIRST';
        // added for selectByOpportunityIds
        // Apttus_Proposal__Opportunity__r.RecordTypeId
        // Apttus_Proposal__Opportunity__r.Type
        // RecordTypeId
        // added for selectValidQuote
        // Apttus_Proposal__Opportunity__r.RecordType.DeveloperName
        // Apttus_Proposal__Opportunity__r.Account.Name
        // Apttus_Proposal__Account__c
        // Ultimate_Consignee__c
        // Distributor__c
        // Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Id
        // Apttus_Proposal__Opportunity__r.Account.Owner.Id
        // Direct_Sale_to_Ultimate_Consignee__c
        // Apttus_Proposal__Approval_Stage__c
        // added for fetchQuotation
        // OwnerId
        // Owner.Name
        // Owner.Email
    }
    */

    ///////////////////////////////////////
    // Queries by Account Criteria
    ///////////////////////////////////////

    // no longer used?
    // public List<Apttus_Proposal__Proposal__c> selectByAccountIds(Set<Id> accountIds)
    // {
    //     return (List<Apttus_Proposal__Proposal__c>) Database.query(
    //         newQueryFactory()
    //         .setCondition('Apttus_Proposal__Opportunity__r.AccountId IN :accountIds')
    //         .toSOQL());
    // }
    
    /*
    * @Author: Rishab
    * @Description : method for fetching out the data based on AccountId or UCIds
    * @param  :  Set<Id> accountIds
    * @return : List<Apttus_Proposal__Proposal__c>
    */
    public List<Apttus_Proposal__Proposal__c> selectByAccountOrUCIds(Set<Id> accountIds)
    {
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByAccountOrUCIds',
            UtilsCollection.serializeIds(accountIds)
        );

        List<Apttus_Proposal__Proposal__c> res = (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .setCondition('Apttus_Proposal__Opportunity__r.AccountId IN :accountIds OR Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c IN :accountIds')
            .toSOQL()
        );

        logger.stop(res.size());
        return res;
    }


    ///////////////////////////////////////
    // Methods replaced by regular SOQL queries
    // Might restore these by May 2021 release
    // If not can delete
    ///////////////////////////////////////

    /**
     *  @author Rohan Chandarana
     *  @description fetch proposals for the ids passed in the argument
     *  @param idSet set of proposal ids
     *  @return proposalList list of proposal records
     **/
    public List<Apttus_Proposal__Proposal__c> selectById(Set<ID> idSet)
    {
         //return (List<Apttus_Proposal__Proposal__c>) selectSObjectsById(idSet);
        String serialized = UtilsCollection.serializeIds(idSet);

        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectById',
            serialized
        );
     List<Apttus_Proposal__Proposal__c> res = (List<Apttus_Proposal__Proposal__c>) Database.query(
         newQueryFactory()
         .selectfield('Work_Order__r.Owner.Email')
         .selectfield('Work_Order__r.Owner.Type')
         .selectfield('Work_Order__r.Account_Region__c')
         .selectfield('Work_Order__r.OwnerId')
         .selectfield('Work_Order__r.Name')
         .setCondition('Id  IN :idSet')
         .toSOQL()
     );
        logger.stop(res.size());
        return res;
    }

    /**
     * @author : Akash Kumar
     * @description DCP-14098 Select Proposal
     * Returns Apttus_Proposal__Proposal__c sObject Record
     **/
    public Apttus_Proposal__Proposal__c selectProposalById(String strProposalId)
    {
        return (Apttus_Proposal__Proposal__c) Database.query(
            newQueryFactory()
            .selectField('Apttus_Proposal__Opportunity__r.Name')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Account_Status__c')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Account_Status__c')
            .selectField('Apttus_Proposal__Opportunity__r.Distributor__r.Account_Status__c')
            .selectField('Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Account_Status__c')
            .selectField('Apttus_Proposal__Opportunity__r.Consortium__r.Name')
            .selectfield('Apttus_Proposal__Opportunity__r.Consortium__r.Species__c')
            .selectfield('Apttus_Proposal__Account__r.BillingCountry')//added for DCP-29629
            .selectfield('Ship_To__r.Country__c')//added for DCP-29629
            .selectField('Validation_In_Progress__c')//added for DCP-34910
            .selectField('Async_Validation_Complete__c')//added for DCP-34910
            .selectField('OwnerId')//added for DCP-34910
            .selectField('Owner.Name')//added for DCP-34910
            .selectField('Owner.Email')//added for DCP-34910
            //DCP-52166
            .selectField('Apttus_Proposal__Opportunity__r.Product_Interest__c')
            .selectField('Work_Order__r.Name')
            .selectField('Apttus_Proposal__Primary_Contact__r.Name')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Name')
            .selectField('Apttus_Proposal__Opportunity__r.AccountId')
            .selectField('Apttus_Proposal__Primary_Contact__r.Email')
            .selectField('Prepared_by__r.Email')
            .selectField('Apttus_Proposal__Opportunity__c')
            .selectField('Apttus_Proposal__Account__r.Territory_Region__c')

            .setCondition('Id = :strProposalId').toSOQL()
        );
    }

    // //// Added by Satya for INC0225110
    // //private static Map<String, List<Apttus_Proposal__Proposal__c>> cacheForSelectByQuoteId = new Map<String, List<Apttus_Proposal__Proposal__c>>();

    /**
     *  @author Satya Swain
     *  @description fetch proposals for the ids passed in the argument and related list passed in method call
     *  @param setQuoteIds set of proposal ids
     *  @return proposalList list of proposal records
     **/

    public List<Apttus_Proposal__Proposal__c> selectByQuoteId(Set<ID> setQuoteIds)
        {
           String serialized = UtilsCollection.serializeIds(setQuoteIds);

           ilib_LogQuery logger = new ilib_LogQuery(
               LOG_TITLE + '.selectByQuoteId',
               serialized
           );

    //     /* if (cacheForSelectByQuoteId.containsKey(serialized))
    //         return cacheForSelectByQuoteId.get(serialized); */

        List<Apttus_Proposal__Proposal__c> res = (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .selectfield('Payment_Term_Description__c')
            .selectfield('Total_Number_Of_Samples__c')
            .selectfield('Apttus_Proposal__Opportunity__r.Rev_Rec_Terms__c')
            .selectfield('Apttus_Proposal__Opportunity__r.Consortium__r.Minimum_Sample_Amount__c')
            .selectField('Apttus_Proposal__Opportunity__r.Name')
            .selectField('Apttus_Proposal__Opportunity__r.AccountId')
            .selectField('Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c')
            .selectField('Apttus_Proposal__Opportunity__r.Account.BillingCountry')
            .selectField('Apttus_Proposal__Opportunity__r.Account.BillingCountryCode')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountryCode')
            .selectField('Apttus_Proposal__Opportunity__r.Distributor__c')
            .selectField('Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c')
            .selectField('Apttus_Proposal__Opportunity__r.RecordType.DeveloperName')
            .selectField('Apttus_Proposal__Opportunity__r.StageName')
            .selectField('Apttus_Proposal__Opportunity__r.Probability')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Apttus_Config2__PaymentTermId__c')
            .selectField('Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c')
            .selectField('Apttus_Proposal__Account__r.Territory_Region__c')
            .selectField('Ultimate_Consignee__r.Territory_Region__c')
            .selectField('Distributor__r.Territory_Region__c')
            .selectField('Apttus_Proposal__Opportunity__r.Contract_Number__c')
            .selectField('Apttus_Proposal__Opportunity__r.Transborder_Flag__c')
            .selectField('Distributor__r.BillingCountry')
            .selectField('Distributor__r.BillingCountryCode')
            .selectField('Apttus_Proposal__Account__r.BillingCountry')
            .selectField('Apttus_Proposal__Account__r.BillingCountryCode')
            .selectField('Ultimate_Consignee__r.BillingCountry')
            .selectField('Ultimate_Consignee__r.BillingCountryCode')
            .selectField('Ultimate_Consignee__r.OwnerId')
            .selectField('Distributor__r.OwnerId')
            .selectField('Apttus_Proposal__Account__r.OwnerId')
            //changes for Bill To & Ship To Logic
            .selectField('Apttus_Proposal__Opportunity__r.Account.Name')
            .selectField('Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c')
            .selectField('Bill_To__r.ERP_Customer_Id__c')
            .selectField('Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c')
            .selectField('Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c')
            .selectField('Distributor__r.BillingCountryCode')
            //adding condition for MyilluminaEmail
            .selectField('Apttus_Proposal__Primary_Contact__r.Email')
            .selectField('Apttus_Proposal__Account__r.Name')
            .selectField('Ultimate_Consignee__r.Name')
            .selectField('Distributor__r.Name')
            .selectfield('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Name')
            .selectfield('Apttus_Proposal__Opportunity__r.Owner.Name')
            .selectfield('Apttus_Proposal__Opportunity__r.Sales_Org_Override__c')
            .selectfield('Apttus_Proposal__Primary_Contact__c')   //DCP-31200
            .selectfield('Owner.Id')
            //DCP-52166
            .selectfield('Apttus_Proposal__Account__r.Oncology_Lab_Manufacturer_Comparison__c')
            .selectfield('Apttus_Proposal__Account__r.Territory_Name__c')
            .selectfield('Apttus_Proposal__Opportunity__r.Product_Interest__c')
            .selectfield('Apttus_Proposal__Opportunity__r.Territory_Region__c')
            .selectfield('Apttus_Proposal__Primary_Contact__r.Name')
            .selectfield('Prepared_by__r.Email')
            .selectfield('Ultimate_Consignee__r.Oncology_Lab_Manufacturer_Comparison__c')
            .selectfield('Work_Order__r.Name')
            .selectfield('Work_Order__r.Owner.Name')
            //CMCM-2523
            .selectfield('Apttus_Proposal__Opportunity__r.Price_List_Type__c')

            .setCondition('Id  IN :setQuoteIds')
            .toSOQL()
        );

    //     //cacheForSelectByQuoteId.put(serialized, res);
         logger.stop(res.size());
         return res;
     }

    // public List<Apttus_Proposal__Proposal__c> selectByOpportunityIds(Set<Id> opportunityIds)
    // {
    //     return (List<Apttus_Proposal__Proposal__c>) Database.query(
    //         newQueryFactory()
    //         .selectField('Apttus_Proposal__Opportunity__r.RecordTypeId')
    //         .selectField('Apttus_Proposal__Opportunity__r.Type')
    //         .selectField('RecordTypeId')
    //         .setCondition('Apttus_Proposal__Opportunity__c IN :opportunityIds').toSOQL()
    //     );
    // }

    /**
     *  @author Rohan Chandarana
     *  @description Fetch primary quotes for the opportuties
     *  @param opportunityIds Set of Opportunity Ids
     *  @return proposalList List of Primary Proposals
     **/

    public List<Apttus_Proposal__Proposal__c> selectPrimary(Set<Id> opportunityIds)
    {
        return (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .selectField('RecordTypeId')
            .selectField('Apttus_Proposal__Opportunity__r.Type')
            .selectField('Apttus_Proposal__Account__r.BillingCountry')
            .selectField('Apttus_Proposal__Opportunity__r.RecordType.DeveloperName')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Name')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Id')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Owner.Id')
            .setCondition('Apttus_Proposal__Opportunity__c IN :opportunityIds AND Apttus_Proposal__Primary__c = true').toSOQL()
        );
    }

    /**
     *  @author Rahul Sharma
     *  @description Fetch valid quotes for the opportunities
     *  @param opportunityIds Set of Opportunity Ids
     *  @return quoteList List of Valid Quotation
     **/
    
    public List<Apttus_Proposal__Proposal__c> selectValidQuote(Set<Id> opportunityIds)
    {
        return (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .selectField('RecordTypeId')
            .selectField('Apttus_Proposal__Opportunity__r.Type')
            .selectField('Apttus_Proposal__Account__r.BillingCountry')
            .selectField('Apttus_Proposal__Opportunity__r.RecordType.DeveloperName')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Name')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Id')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Owner.Id')
            .selectField('RecordType.DeveloperName')
            .selectField('Apttus_Proposal__Opportunity__r.Distributor__r.Owner.Id')
            .selectField('Apttus_Proposal__Opportunity__r.Transborder_Flag__c')
            .setCondition('Apttus_Proposal__Opportunity__c IN :opportunityIds AND Invalid_Quote__c = false').toSOQL()
        );
    }
    /**
     *  @author Rishab
     *  @description [DCP-45455] Fetch primary quotes where invalid check is false
     *  @param opportunityIds Set of Opportunity Ids
     *  @return proposalList List of Primary Proposals
     **/
    public List<Apttus_Proposal__Proposal__c> selectPrimaryAndValidQuotes(Set<Id> opportunityIds)
    {
        return (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .selectField('RecordTypeId')
            .selectField('Apttus_Proposal__Opportunity__r.Type')
            .selectField('Apttus_Proposal__Account__r.BillingCountry')
            .selectField('Apttus_Proposal__Opportunity__r.RecordType.DeveloperName')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Name')
            .selectField('Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Id')
            .selectField('Apttus_Proposal__Opportunity__r.Account.Owner.Id')
            .setCondition('Apttus_Proposal__Opportunity__c IN :opportunityIds AND Apttus_Proposal__Primary__c = true AND Invalid_Quote__c = false').toSOQL()
        );
    }

    /**
     * @author : Sravan Panchangam
     * @description DCP-9865 ERP Quote Number
     * Returns List<Apttus_Proposal__Proposal__c> with quotation
     **/
    
    public List<Apttus_Proposal__Proposal__c> fetchQuotation(set<String> setApttusQuoteNumber)
    {
        return (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .selectField('OwnerId')//added for DCP-34910
            .selectField('Owner.Name')//added for DCP-34910
            .selectField('Owner.Email')//added for DCP-34910
            .setCondition('Name IN :setApttusQuoteNumber').toSOQL());
    }

    /**
     *  @author Dushyant
     *  @description [DCP-48875] Fetch quotes on the basis of quoation id
     *  @param quoteIds Set of Quoation Ids
     *  @return proposalList List of Primary Proposals
     **/

    public List<Apttus_Proposal__Proposal__c> selectByQuotationId(Set<String> quoteId)
    {
        return (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .selectField('Apttus_Proposal__Opportunity__r.Owner.Name')
            .selectField('Name')
            .selectField('Sold_To_ERP_Number__c')
            .selectField('Sold_To_Account_Name__c')
            .selectField('Distributor_ERP_Number__c')
            .selectField('Distributor__r.Name')
            .selectField('Ultimate_Consignee_ERP_Number__c')
            .selectField('Ultimate_Consignee__r.Name')
            .selectField('Ship_To_ERP_Number__c')
            .selectField('Ship_To__r.name')
            .selectField('Bill_To_ERP_Number__c')
            .selectField('Bill_To__r.Name')
            .selectField('Payer_ERP_Number__c')
            .selectField('Payer__r.Name')
            .selectField('SAP_Quote__c')
            .selectField('Apttus_Proposal__Opportunity__r.Territory_Region__c')
            .selectField('Apttus_Proposal__Opportunity__c')
            .selectField('SAP_Errors__c')
            .setCondition('Id IN: quoteId')
            .toSOQL()
        );
    }
        /**
     *  @author Kumar Gaurav
     *  @description [DgP-31] Fetch quotes, with reapproval reference on the basis of quoation id
     *  @param quoteIds list of Quoation Ids
     *  @return proposalList List of Primary Proposals
     **/
    public List<Apttus_Proposal__Proposal__c> selectReapprovalReferenceByQuotationIds(Set<id> quoteId)
    {
        return (List<Apttus_Proposal__Proposal__c>) Database.query(
            newQueryFactory()
            .selectField('ID')
            .selectField('Reapproval_Reference__c')
            .setCondition('Id IN: quoteId')
            .toSOQL()
        );
    }
    
    /*
     * @Author : Arquimidez Mora
     * @Decription : Fetch quotes with any fields on parameter
     * @return  Proposal List
     */
    public List<Apttus_Proposal__Proposal__c> selectQuotesWithFields(Set<Id> setQuotationIds, List<String> lstFields)
    {
        ilib_QueryFactory objQueryFactor = newQueryFactory();

        for(String strField : lstFields){
            objQueryFactor.selectField(strField);
        }

        List<Apttus_Proposal__Proposal__c> res = (List<Apttus_Proposal__Proposal__c>) Database.query(
            objQueryFactor
            .setCondition('Id IN :setQuotationIds')
            .toSOQL()
        );

        return res;
    }
}