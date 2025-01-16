/**
 *    @author Rohan Chandarana
 *    @date   2018-07-20
 *    @description    Class to get the Line Item records based on different conditions
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                    Date                 Description
 *    Rohan                        2018-07-20           Initial Version
 *    Gopesh                       2018-10-04           adding field Global_Trade_Block__cin getSObjectFieldList method
 *    Satya Swain                  2018-10-30           added fields and selectLineItemsByConfigIdAndAssetLineItemId for DCP-736
 *    Kristiyan Petkov             2018-11-16           added method to fetch Line Items for the id passed in the argument
 *    Kushagra Desai               2019-06-04           DCP-25190 - Demo Program
 *    Joshith K                    2019-12-03           INC0238317-- Added fields in selectLineItemsByConfigId
 *    Rahul Bishnoi                2020-01-13           DCP-32794 Remove Software Id
 *    Roopal Verma                 2021-03-08           DCP-42729 : Added Total_Requested_Discount__c
 *    Todd                         2021-04-15           DCP-45737: Add quote instrumentation (with feature flag)
 *    KD                           2021-05-05           DCP-45742 : Added Product intrest
 *    Ashwin                       2021-05-11           INC0321438 Updated selectLineItemsByConfigId() param from single Id to Set of Product Config Ids
 *    Nesar                        2022-06-02           DCP-53938 : Added a field in getSObjectFieldList, Updated selectById method
 *    Himanshu                     2022-07-19           DCP-55231 Updated selectLineItemsByConfigId   
 *    Jitesh                       2022-Aug-2           DCP-54361
 *    Jitesh Lakhwani              02-Aug-2022          DCP-53975 Fix
 *    Jitesh Lakhwani              2022-08-23           HyperCare 0794448
 *    Vinay S Reddy                2023-10-23           CMCM 1482 Updates
 *    --------------------------------------------------------------------------------------------------------------------------
 *    Iram Malik                   2022-07-14           Codescan Fixes
 * --------------------------------------------------------------------------------------------------------------------------
 */
public class ApttusLineItemsSelector extends ilib_SObjectSelector {

    private final String LOG_TITLE = 'ApttusLineItemsSelector';
    public static final String SALES_QUERYLOGS = 'SalesQueryLogs';

    /**
    *  @author Rohan Chandarana
    *  @description
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Apttus_Config2__LineItem__c.sObjectType;
    }

    /**
     *  @author  Rohan Chandarana
     *  @description Retrieve list of fields for Line Item sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus_Config2__LineItem__c.id,
            Apttus_Config2__LineItem__c.Name,
            Apttus_Config2__LineItem__c.Apttus_Config2__AdjustmentAmount__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__AdjustmentType__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__ListPrice__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__LineNumber__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__Quantity__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__BasePrice__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__NetPrice__c,
            Apttus_Config2__LineItem__c.Sales_Discretionary_Discount__c,
            Apttus_Config2__LineItem__c.Sales_Discretionary_Type__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__SellingTerm__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__BaseExtendedPrice__c,
            Apttus_Config2__LineItem__c.Volume_Discount__c,
            Apttus_Config2__LineItem__c.Promotion_Discount__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__PriceMethod__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__PriceType__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__StartDate__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__EndDate__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__SellingFrequency__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__ListPrice__c,
            Apttus_Config2__LineItem__c.Customer_Distributor_Specific_Price__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__LineNumber__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__ItemSequence__c,
            Apttus_Config2__LineItem__c.Distributor_Specific_Price__c,
            Apttus_Config2__LineItem__c.Distributor_Specific_Discount_Percentage__c,
            Apttus_Config2__LineItem__c.Distributor_Specific_Discount__c,
            Apttus_Config2__LineItem__c.Total_Discount_Percentage__c,
            Apttus_Config2__LineItem__c.Total_Discount_Amount__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__PricingStatus__c,
            Apttus_Config2__LineItem__c.Promo_Name__c,
            Apttus_Config2__LineItem__c.Promotion_Code__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__PriceListItemId__c,
            Apttus_Config2__LineItem__c.Global_Trade_Block__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__PrimaryLineNumber__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__ParentBundleNumber__c,
            Apttus_Config2__LineItem__c.SAP_Net_Price__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__HasOptions__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__LineType__c,
            Apttus_Config2__LineItem__c.SAP_Cross_Plant_Status__c,
            Apttus_Config2__LineItem__c.Max_Samples_Allowed_Per_kit__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__AssetLineItemId__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__ConfigurationId__c,
            Apttus_Config2__LineItem__c.ERP_Line_Number__c,
            Apttus_Config2__LineItem__c.Software_Type__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__ProductId__c,
            Apttus_Config2__LineItem__c.Apttus_Config2__BillingFrequency__c,
            Apttus_Config2__LineItem__c.Distributor_Rebate__c,
            Apttus_Config2__LineItem__c.Applied_Discount_Details__c,
            //Apttus_Config2__LineItem__c.SAP_Errors__c,
            Apttus_Config2__LineItem__c.Price_Override__c,
            Apttus_Config2__LineItem__c.Reason_For_Price_Override__c,
            Apttus_Config2__LineItem__c.Project_Id__c,
            Apttus_Config2__LineItem__c.Beadchip_Part_Number__c,
            Apttus_Config2__LineItem__c.Customer_Price_Per_Unit__c,
            Apttus_Config2__LineItem__c.Customer_Net_Price__c,
            //Apttus_Config2__LineItem__c.Software_Id__c,
            Apttus_Config2__LineItem__c.LastModifiedById,
            Apttus_Config2__LineItem__c.List_Price__c,
            Apttus_Config2__LineItem__c.Unit_Price__c,
            Apttus_Config2__LineItem__c.Total_List_Price__c,
            Apttus_Config2__LineItem__c.Price_per_sample__c,
            Apttus_Config2__LineItem__c.Customer_Premium_Amount_Per_Unit__c,
            Apttus_Config2__LineItem__c.Equipment_Id__c,
            Apttus_Config2__LineItem__c.Serial_Number__c,
            Apttus_Config2__LineItem__c.End_Of_Sale_Date__c,
            Apttus_Config2__LineItem__c.End_Of_Service_Date__c,
            Apttus_Config2__LineItem__c.Line_Item_Old_Values__c,
            Apttus_Config2__LineItem__c.Approval_Matrix_Custom__c,
            Apttus_Config2__LineItem__c.Approval_Matrix_Record_Owner__c,
            Apttus_Config2__LineItem__c.Suggested_Sales_Discount_Percentage__c,
            Apttus_Config2__LineItem__c.Suggested_Sales_Discount_Amount__c,
            //DCP-25322, added Manual Rebate and Line Item Validate Old fields
            Apttus_Config2__LineItem__c.Manual_Rebate__c,
            Apttus_Config2__LineItem__c.Manual_Rebate_Per_Unit__c,
            Apttus_Config2__LineItem__c.Line_Item_Validate_Old__c,
            Apttus_Config2__LineItem__c.Program_Type__c,
        Apttus_Config2__LineItem__c.Shipping_In_Close_Quarter__c,
            Apttus_Config2__LineItem__c.Cost_Center__c,
            Apttus_Config2__LineItem__c.Distributor_Total_Discount__c,
            Apttus_Config2__LineItem__c.Open_Offer_Max__c,
            Apttus_Config2__LineItem__c.Applied_Discount_Percentage__c, // 53938 
            Apttus_Config2__LineItem__c.Trade_In_Type__c  //added as part of cmcm 1482
            
        };
    }

    /**
     *  @author Rohan Chandarana
     *  @description fetch Line Items for the ids passed in the argument
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public List<Apttus_Config2__LineItem__c> selectById(Set<ID> idSet)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERYLOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectById',
            UtilsCollection.serializeIds(idSet)
        );

        List<Apttus_Config2__LineItem__c> res = (List<Apttus_Config2__LineItem__c>) Database.query( //DCP-53938
        newQueryFactory()
       .selectField('Apttus_Config2__ProductId__r.Open_Offer_Product__c')
       .selectField('Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c')
       .selectField('Apttus_Config2__ProductId__r.Material_Class__c')
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Open_Offer_Comparison_Customer__c')//DCP-55231 start
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Signed_Open_Offer__c')
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Open_Offer_Comparison_Customer__c')
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Signed_Open_Offer__c')
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.National_Group_Number__c')
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.National_Group_Number__c')//DCP-55231 end
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.ERP_Customer_Id__c')
       .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.ERP_Customer_Id__c')//DCP-56658 end

       .setCondition('Id IN :idSet')
       .toSOQL()
       );
        if (Feature.isOn(SALES_QUERYLOGS)) logger.stop(res.size());
        return res;
    }

    /**
     *  @author Satya Swain
     *  @description fetch Line Items for the ids passed in the argument
     *  @param idConfigRequest Id For Product Configuration Id
     *  @return list of line item records
     **/
    public List<Apttus_Config2__LineItem__c> selectLineItemsByConfigIdAndAssetLineItemId(Id idConfigRequest)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERYLOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectLineItemsByConfigIdAndAssetLineItemId', idConfigRequest
        );

        String strCondition = 'Apttus_Config2__ConfigurationId__c = :idConfigRequest AND Apttus_Config2__AssetLineItemId__c != NULL';
        String strQuery = newQueryFactory().setCondition(strCondition).toSOQL();
        List<Apttus_Config2__LineItem__c> res = (List<Apttus_Config2__LineItem__c>) Database.query(strQuery);

        if (Feature.isOn(SALES_QUERYLOGS)) logger.stop(res.size());
        return res;
    }

    /**
     *  @author Kristiyan Petkov
     *  @description fetch Line Items for the ids passed in the argument
     *  @param idConfigRequest Set<Id> For Product Configuration Ids
     *  @return list of line item records
     **/
    public List<Apttus_Config2__LineItem__c> selectLineItemsByConfigId(Set<Id> idConfigRequest)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERYLOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectLineItemsByConfigId',
            UtilsCollection.serializeIds(idConfigRequest)
        );

        String strCondition;
        String strQuery;
        strCondition = 'Apttus_Config2__ConfigurationId__c IN :idConfigRequest';    //INC0321438

        strQuery = newQueryFactory()
          .selectField('Apttus_Config2__ProductId__r.ProductCode')
          .selectField('Apttus_Config2__ProductId__r.Material_Class_Type__c')
          .selectField('Apttus_Config2__OptionId__r.Material_Class__c')
          .selectField('Apttus_Config2__ProductOptionId__r.Apttus_Config2__ParentProductId__r.Bundle_Id__c')
          .selectField('Apttus_Config2__ProductId__r.Product_Group_Code__c')
          .selectField('Apttus_Config2__OptionId__r.ProductCode')
          .selectField('Apttus_Config2__ProductId__r.Material_Number__c')
          .selectField('Apttus_Config2__OptionId__r.Material_Number__c')
          .selectField('Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c')
          .selectField('Apttus_Config2__ProductId__r.Bundle_Id__c')
          .selectField('Apttus_Config2__OptionId__r.Apttus_Config2__ConfigurationType__c')
          .selectField('Apttus_Config2__ProductId__r.End_Of_Sale_Date__c')
          .selectField('Apttus_Config2__ProductId__r.End_Of_Service_Date__c')
          .selectField('Apttus_Config2__OptionId__r.End_Of_Sale_Date__c')
          .selectField('Apttus_Config2__OptionId__r.End_Of_Service_Date__c')
          .selectField('Apttus_Config2__ProductId__r.Name')
          .selectField('Apttus_Config2__OptionId__r.Name')
          .selectField('Apttus_Config2__ConfigurationId__r.Promo_Name_1__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Promo_Name_2__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Promo_Name_3__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c') 
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c')  //DCP-45742
          .selectField('Apttus_Config2__ProductId__r.Open_Offer_Product__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Quote_For_Open_Offer_Customer__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c')
           // INC0439986 Start
           .selectField('Registrant_Contact__c')
           .selectField('Registrant_Contact__r.AccountId')
           .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c')
           .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__c')
         // INC0439986 End
          //DCP-55231 -- Start  
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Open_Offer_Comparison_Customer__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Signed_Open_Offer__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Open_Offer_Comparison_Customer__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Signed_Open_Offer__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.National_Group_Number__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.National_Group_Number__c')
         //DCP-55231 -- End
         
          .addOrdering('Apttus_Config2__LineNumber__c',ilib_QueryFactory.SortOrder.ASCENDING)
          .addOrdering('Apttus_Config2__OptionId__r.Apttus_Config2__ConfigurationType__c' ,ilib_QueryFactory.SortOrder.ASCENDING)
          .selectField('Apttus_Config2__ProductId__r.Open_Offer_Product__c') //DCP-53938
          .selectField('Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.ERP_Customer_Id__c')
          .selectField('Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.ERP_Customer_Id__c')
          .selectField('Customer_Premium_Type__c')
          .selectField('Customer_Premium_Per_Unit__c')
          .selectField('Approval_Matrix_Record_Owner__c') 
          .selectField('Approval_Matrix_Custom__c') 
          .setCondition(strCondition)
          .toSOQL();
        List<Apttus_Config2__LineItem__c> res = (List<Apttus_Config2__LineItem__c>) Database.query(strQuery);

        if (Feature.isOn(SALES_QUERYLOGS)) logger.stop(res.size());
        return res;
    }
    //<---DGP-31--->
        /**
     *  @author Kumar Gaurav
     *  @description fetch Line Items for the ids passed in the argument
     *  @param idConfigRequest Set<Id> For Product Configuration Ids
     *  @return list of line item records
     **/
    public List<Apttus_Config2__LineItem__c> selectLineItemsByConfigIds(Set<Id> idConfigRequest)
    {
        return (List <Apttus_Config2__LineItem__c>) Database.query(
        newQueryFactory()
        .selectField('Id')
        .selectField('Name')
        .selectField('Apttus_Config2__LineNumber__c')
        .selectField('Apttus_Config2__ProductId__r.ProductCode')
        .selectField('Apttus_Config2__Quantity__c')
        .selectField('Apttus_Config2__Term__c')
        .selectField('Apttus_Config2__AdjustmentAmount__c')
        .setCondition('Apttus_Config2__ConfigurationId__c IN :idConfigRequest')
        .toSOQL()
        );
    }   


}