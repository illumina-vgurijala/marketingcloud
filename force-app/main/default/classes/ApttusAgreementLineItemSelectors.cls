/**
 *    @author Kushagra Desai
 *    @date   11-Dec-2019
 *    @description    Class to get the Agreement line item records based on different conditions
 *    Modification Log:
 *   Test class for 90% coverage: TestApttusAgreements,
 *   Test class for 75% coverage: TestOpenOfferagreements 
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    B Kamini                      1/13/2020            Added method as part of DCP-31209
 *    Umesh Mor                     1/15/2020            method getSObjectFieldList() modified as part of DCP-31142
 *    Saswati                       1/20/2020            DCP-31789
 *    Umesh                         2020-1-27            Modified getSObjectFieldList() - Fields Add as part of DCP-31177..
 *    Kamini                        2/8/2020             Added Price_Group__c as part of DCP-33776
 *    Prabhsimran                   3/5/2020             MOdified selectAgreementLineItem and added Material_Group_1_Description__c as part of DCP-35369
 *    Rishab Wali                   16/6/2020            Added fields for DCP-38285
 *    Rahul Bishnoi                 6/25/2020            TASK0486150- Delete Agreement Account relationships after Line is items is discontinued.
 *    Joshith k                     7/10/2020            TASK0493822-- Added selectAgreementLineItemSorted method.
 *    Anish                         12/10/2020           DCP-43353 - Added Customer_Condition_Group_4__c                     
 *    Adyasha                       16/09/2021           DCP-47726 : Added selectByAgreementIdExcludingFew                                           
 *    Adyasha                       24/09/2021           DCP-47727 - Added new Method selectByAccountIdsExcludingGivenAgreements               
 *    Nesar Mohan                   01/04/2022           CodeScan Fix - Code Comments
 *    Nishan Shetty                 29-June-2022         DCP-52703 Added Material Group 1 and Priority Field  of Product and Query Implementation in selectAgreementLineItemSorted method.
 *    Saddam                        02-sep-2022          DCP-54536  Added Fields to fieldlist.
 *    SAddam                        09-sep-2022          DCP-54532 Added 2 new fields in selectByAgreementId() ,selectByAgreementId().
 *    Parthasarathy D               15-Sept-2022         DCP-56501 - Introduced method "selectAgreementLineItemForMaterialNumber" for the Open Offer Agreement Line items.
 *    Saddam                        22-Sep-22            DCP-56505 Added a field to a method.
 *    Gerardo Garcia                03-Jun-24            DGP-107 Modify Sorting selectAgreementLineItemSorted
 *--------------------------------------------------------------------------------------------------------------------------------------------------------------
 */
public class ApttusAgreementLineItemSelectors extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'ApttusAgreementLineItemSelectors';//DCP-52703
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';//DCP-52703
    private List<ilib_QueryFactory.Ordering> orderingOverride;//DCP-52703

    /**
    *  @author Kushagra Desai
    *  @description
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Apttus__AgreementLineItem__c.sObjectType;
    }
    /**
     *  @author Kushagra Desai
     *  @description Retrieve list of fields for Line Item sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus__AgreementLineItem__c.id,
            Apttus__AgreementLineItem__c.Name,
            Apttus__AgreementLineItem__c.Condition_Type__c,
            Apttus__AgreementLineItem__c.Condition_Table__c,
            Apttus__AgreementLineItem__c.Material_Group_1__c,
            Apttus__AgreementLineItem__c.Material_Number__c,
            Apttus__AgreementLineItem__c.Partner_Role__c,
            Apttus__AgreementLineItem__c.Discount__c,
            Apttus__AgreementLineItem__c.Discount_Type__c,
            Apttus__AgreementLineItem__c.Apttus_CMConfig__StartDate__c,
            Apttus__AgreementLineItem__c.Apttus_CMConfig__EndDate__c,
            Apttus__AgreementLineItem__c.Line_Type__c,
            Apttus__AgreementLineItem__c.Apttus__AgreementId__c,
            //Below fields Added as part of DCP-31142
            Apttus__AgreementLineItem__c.Line_Type__c,
            Apttus__AgreementLineItem__c.Customer_ERP_Number__c,
            Apttus__AgreementLineItem__c.Sales_Org__c,
            Apttus__AgreementLineItem__c.Price_Group__c,
            Apttus__AgreementLineItem__c.CurrencyIsoCode,
            Apttus__AgreementLineItem__c.Distribution_Channel__c,// Added DCP-32815
            //Below Fields Add as part of DCP-31177
            Apttus__AgreementLineItem__c.Apttus__AgreementId__r.recordType.Name,
            Apttus__AgreementLineItem__c.Ultimate_Consignee_ERP_Number__c,
            Apttus__AgreementLineItem__c.Permitted_Markup_Percentage__c,
            Apttus__AgreementLineItem__c.Q1_Quota__c,
            Apttus__AgreementLineItem__c.Q2_Quota__c,
            Apttus__AgreementLineItem__c.Q3_Quota__c,
            Apttus__AgreementLineItem__c.Q4_Quota__c,
            Apttus__AgreementLineItem__c.Total_Quota__c,
            Apttus__AgreementLineItem__c.Apttus_CMConfig__StartDate__c,
            Apttus__AgreementLineItem__c.Apttus_CMConfig__EndDate__c,
            Apttus__AgreementLineItem__c.Distribution_Channel__c, // Added DCP-32815
            Apttus__AgreementLineItem__c.Ultimate_Consignee_ERP_Number__c,
            Apttus__AgreementLineItem__c.Apttus__ProductId__c,
            Apttus__AgreementLineItem__c.Apttus_CMConfig__LineStatus__c,
            Apttus__AgreementLineItem__c.Discontinued__c,

            Apttus__AgreementLineItem__c.Material_Group_1_Description__c,
            Apttus__AgreementLineItem__c.Discount_In_Percent__c,
            Apttus__AgreementLineItem__c.Apttus_Approval__Approval_Status__c, //enhancement

            Apttus__AgreementLineItem__c.Apttus__ListPrice__c,//DCP-38285
            Apttus__AgreementLineItem__c.Discount_Amount__c,//DCP-38285
            Apttus__AgreementLineItem__c.Customer_Price__c,//DCP-38285
            Apttus__AgreementLineItem__c.Customer_Condition_Group_4__c,//DCP-43353

            Apttus__AgreementLineItem__c.RecordTypeId,//DCP-47727
            //DCP-54536 Start
            Apttus__AgreementLineItem__c.Open_Offer_Line_Type__c,
            Apttus__AgreementLineItem__c.Supply_Agreement_End_Date__c,
            Apttus__AgreementLineItem__c.Supply_Agreement_Start_Date__c,
            Apttus__AgreementLineItem__c.Customer_Election__c,
            Apttus__AgreementLineItem__c.Quote_Discount__c,
            Apttus__AgreementLineItem__c.Supply_Agreement_Discount__c,
            Apttus__AgreementLineItem__c.Universal_Grid_Discount__c,
            Apttus__AgreementLineItem__c.PSP_Discount__c,
            Apttus__AgreementLineItem__c.Quote_Discount_Type__c,
            Apttus__AgreementLineItem__c.Supply_Agreement_Discount_Type__c,
            Apttus__AgreementLineItem__c.Universal_Grid_Discount_Type__c,
            Apttus__AgreementLineItem__c.Apttus__AgreementId__r.Sales_Org__c,
            Apttus__AgreementLineItem__c.Apttus__AgreementId__r.Distribution_Channel__c,
            Apttus__AgreementLineItem__c.Apttus__AgreementId__r.CurrencyIsoCode
        };
    }
    
    /*
    *  @author      : Joshith K 
    *  @description : Override Default name Ordering [DCP-52703-Modified Existng Sorting Implementation].
    *  @param       : None
    *  @return      : String for Ordering  
    */
    public override String getOrderBy() {
        List<String> orderByClauses = new List<String>();
        if (orderingOverride == null || orderingOverride.isEmpty()) {
            return super.getOrderBy();
        }

        for (ilib_QueryFactory.Ordering ordering : orderingOverride) {
            orderByClauses.add(ordering.toSOQL());
        }
        return String.join(orderByClauses, ','); 
    }   
    /**
     *  @author B Kamini
     *  @description fetch Line Items for the Agreement Ids passed in the argument
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public List<Apttus__AgreementLineItem__c> selectAgreementLineItem(Set<Id> setAgreementId)
    {
        return (List<Apttus__AgreementLineItem__c>) Database.query(
                                newQueryFactory()
                                .selectField('Apttus__AgreementId__r.recordType.Name')
                                .selectField('Apttus__AgreementId__r.recordType.DeveloperName')
                                .selectField('Apttus__AgreementId__r.Apttus__Contract_Start_Date__c')
                                .selectField('Apttus__AgreementId__r.Apttus__Contract_End_Date__c')
                                .selectField('RecordType.name') //dcp-54536 start
                                .selectField('RecordType.developername')
                                .selectField('Apttus__AgreementId__r.Sales_Org__c')
                                .selectField('Apttus__AgreementId__r.CurrencyIsoCode')
                                .selectField('Quote_Discount_Type__c')
                                .selectField('Universal_Grid_Discount_Type__c')
                                .selectField('Supply_Agreement_Discount_Type__c')
                                .selectField('Apttus__AgreementId__r.Distribution_Channel__c')
                                .selectField('Apttus_CMConfig__EndDate__c')
                                .selectField('Apttus__ProductId__r.Material_Class__c') // Dcp-54532
                                .selectField('Apttus__AgreementId__r.Account_ERP_Number__c')
                                .selectField('Previous_Customer_Elections__c')
                                .selectField('Apttus__ProductId__r.Material_Number__c')
                                .selectField('Customer_Election__c')//56505
                                .selectField('Account__r.Name')
                                .selectField('Apttus__ProductId__r.Name')
                                .selectField('Apttus__AgreementId__r.Apttus__FF_Agreement_Number__c')
                                .selectField('Apttus__AgreementId__r.Agreement_Not_Amended__c')//56505
                                .selectField('Apttus__AgreementId__r.Freight_Charge__c')//CMCM-5305
                                .setCondition('Apttus__AgreementId__c IN: setAgreementId')
                                .toSOQL()
        );
    }

    /**
     *  @author Pradeep L
     *  @description fetch Line Items for the Agreement Ids passed in the argument
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public List<Apttus__AgreementLineItem__c> selectAgreementLineItemNew(Set<Id> setAgreementId)
    {
        return (List<Apttus__AgreementLineItem__c>) Database.query(
                                newQueryFactory()
                                .selectField('Agreement_Record_Type__c')
                                .selectField('Sales_Approval_Threshold__c')
                                .selectField('is_MFN_Line_Item__c')
                                .selectField('Do_Not_Run_Discount_Guidance__c')
                                .selectField('Max_Discount_Guidance__c')
                                .selectField('Approval_Matrix_Record_Owner__c')
                                .selectField('Agreement_Subtype__c')
                                .selectField('Median_Discount_Guidance__c')
                                .selectField('Is_MFN_TG_NextSeq_Consumable__c')
                                .selectField('Is_MFN_NovaSeq_Consumable__c')
                                .selectField('Discount_Guidance__c')
                                .selectField('Agreement_Currency__c')
                                .selectField('Customer_Historical_Discount__c')
                                .selectField('Discount_Grid_Group__c')
                                .selectField('Is_MFN_NextSeq_RUO_Consumable__c')
                                .selectField('Line_Type_1__c')
            					.selectField('Discontinued__c')
            					.selectField('Discount__c')
            					.selectField('Apttus__ProductId__c')
            					.selectField('Distribution_Channel__c')
            					.selectField('Agreement_Distribution_Channel__c')
            					.selectField('Customer_ERP_Number__c')
            					.selectField('Ultimate_Consignee_ERP_Number__c')
            					.selectField('Sales_Org__c')
            					.selectField('CurrencyIsoCode')
            					.selectField('Material_Number__c')
            					.selectField('Material_Group_1__c')
            					.selectField('Apttus_CMConfig__StartDate__c')
            					.selectField('Discount_Type__c')
            					.selectField('Apttus_CMConfig__LineStatus__c')
            					.selectField('Apttus__AgreementId__c')
            					.selectField('RecordTypeId')
                                .selectField('Apttus__ProductId__r.IsActive')
                                .setCondition('Apttus__AgreementId__c IN: setAgreementId AND Apttus_CMConfig__LineStatus__c!=\'Existing\' AND Apttus__ProductId__r.IsActive = TRUE')
                                .toSOQL()
        );
    }

    /**
     *  @author Saswati
     *  @description fetch Line Items for the Agreement Ids passed in the argument
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public List<Apttus__AgreementLineItem__c> selectByAgreementId(Set<Id> setAgreementId)
    {
        return (List<Apttus__AgreementLineItem__c>) Database.query(
                                newQueryFactory()
                                .selectField('Approval_Category__c')
                                .selectField('Apttus__AgreementId__c')
                                .selectField('Customer_ERP_Number__c')
                                .selectField('Apttus__AgreementId__r.Account_ERP_Number__c')
                                .selectField('Apttus__AgreementId__r.Apttus__Status_Category__c')
                                .selectField('Apttus__ProductId__r.Material_Number__c')
                                .selectField('Apttus__ProductId__r.Material_Class__c') // Dcp-54532
                                .selectField('Material_Group_1__c')//added for DCP-40571
                                .selectField('Apttus__AgreementId__r.Apttus__Account__c')
                                .setCondition('Apttus__AgreementId__c IN: setAgreementId')
                                .toSOQL()
      );
    }
    /**
     *  @author joshith K
     *  @description fetch Line Items for the Agreement Ids passed in the argument with orderby and limit
     *  @param idSet set of agreement ids
     *  @return list of line item records
     **/
    public List<Apttus__AgreementLineItem__c> selectAgreementLineItemSorted(Set<Id> setAgreementId,Integer limitCount,Integer rowOffset) {
        ilib_LogQuery logger = new ilib_LogQuery();
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAgreementLineItemSorted',UtilsCollection.serializeIds(setAgreementId));
        }

        addOrderingOverride(Apttus__AgreementLineItem__c.Priority__c, ilib_QueryFactory.SortOrder.ASCENDING,true);//DCP-52703
        addOrderingOverride(Apttus__AgreementLineItem__c.Discount_Beyond_Threshold__c, ilib_QueryFactory.SortOrder.DESCENDING,true);//DGP-107
        ilib_QueryFactory query = newQueryFactory();
        query.selectField('Apttus__AgreementId__r.recordType.Name');
        query.selectField('recordType.Name');
        query.selectField('RecordType.DeveloperName');
        query.selectField('Apttus__AgreementId__r.recordType.DeveloperName');
        query.selectField('Apttus__AgreementId__r.Apttus__Contract_Start_Date__c');
        query.selectField('Apttus__AgreementId__r.Apttus__Contract_End_Date__c');
                                
        query.selectField('Apttus__ProductId__r.Material_Number__c');
        query.selectField('Account__r.Name');
        query.selectField('Apttus__ProductId__r.Name');
        query.selectField('Apttus__ProductId__r.Material_Group_1__c');//DCP-52703
        query.selectField('Priority__c');//DCP-52703
        //Added by SB [DGP-104]
        query.selectField('Customer_Historical_Discount__c'); 
        query.selectField('Median_Discount_Guidance__c'); 
        query.selectField('Max_Discount_Guidance__c');  
        query.selectField('Sales_Approval_Threshold__c');  
        query.selectField('Do_Not_Run_Discount_Guidance__c');//DGP-59 Addition
        query.selectField('Discount_Beyond_Threshold__c');

        query.setCondition('Apttus__AgreementId__c IN: setAgreementId');
        if(limitCount!=null)
            query.setLimit(limitCount);
        if(rowOffset!=null)
            query.setOffSet(rowOffset);

        List<Apttus__AgreementLineItem__c> res = (List<Apttus__AgreementLineItem__c>)Database.query(query.toSOQL()); 

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    
    
    
    /**
     *  @author Adyasha
     *  @description DCP-47727: fetch Line Items for the Account Ids passed in the argument
     *  @param setAccountIds set of account ids
     *  @param setAgreementIdsToExclude set of line item ids to exclude
     *  @param setStatusCategories set of status categories to check
     *  @return list of line item records
     **/
    public List<Apttus__AgreementLineItem__c> selectByAccountIdsExcludingGivenAgreements(Set<Id> setAccountIds, Set<Id> setAgreementIdsToExclude, Set<String> setStatusCategories)
    {
        ilib_QueryFactory query = newQueryFactory();
        String strCondition = 'Apttus__AgreementId__r.Apttus__Account__c IN :setAccountIds';                            
        if(setStatusCategories != null && !setStatusCategories.isEmpty())
        {
            strCondition += ' AND Apttus__AgreementId__r.Apttus__Status_Category__c IN :setStatusCategories';
        }                   
        if(setAgreementIdsToExclude != null && !setAgreementIdsToExclude.isEmpty()) 
        { 
            strCondition += ' AND Apttus__AgreementId__c NOT IN :setAgreementIdsToExclude';
        }
        query.selectField('Apttus__AgreementId__r.Name')
             .selectField('Apttus__AgreementId__r.Apttus__FF_Agreement_Number__c');
        query.setCondition(strCondition);
        return (List<Apttus__AgreementLineItem__c>) Database.query(query.toSOQL());
    }
    
    /*
    *  @author      : Nishan Shetty 
    *  @description : Override Default Name Ordering.
    *  @param       : field - Field Name for Sorting.
    *  @param       : direction - Direction for Sorting.
    *  @param       : nullsLast - Boolean value to sort NULLS LAST/NULLS FIRST.
    *  @return      : void
    */
    private void addOrderingOverride(Schema.SObjectField field, ilib_QueryFactory.SortOrder direction, Boolean nullsLast)
    {
        if (orderingOverride == null) {
            orderingOverride = new List<ilib_QueryFactory.Ordering>();
        } 
        orderingOverride.add(new ilib_QueryFactory.Ordering(field, direction, nullsLast));
    }

    /**
     *  @author Parthasarathy D
     *  @description fetch Line Items for the Agreement Ids and Material Numbers passed in the argument
     *  @param set of Agreement IDs and set of Material numbers
     *  @return list of line item records
     **/
    public List<Apttus__AgreementLineItem__c> selectAgreementLineItemForMaterialNumber(Set<Id> setAgreementId,Set<String> setMaterialNumbers) {
        ilib_LogQuery logger = new ilib_LogQuery();
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAgreementLineItemForMaterialNumber',UtilsCollection.serializeIds(setAgreementId));
        }
        ilib_QueryFactory query = newQueryFactory();
        String strCondition = 'Apttus__AgreementId__c IN: setAgreementId AND Material_Number__c IN: setMaterialNumbers';                            
        query.setCondition(strCondition);
        List<Apttus__AgreementLineItem__c> res = (List<Apttus__AgreementLineItem__c>) Database.query(query.toSOQL());
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}