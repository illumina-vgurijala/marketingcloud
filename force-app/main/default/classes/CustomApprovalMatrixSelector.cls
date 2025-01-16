/**
 *    @author Rohan Chandarana
 *    @date   06-06-2018
 *    @description    Class to get the Custom Approvaal Matrix records based on different conditions
 *    Modification Log:
 *    --------------------------------------------------------------------------------------------------------------- 
 *    Developer                   Date                Description
 *      Rohan                   06-June-2018        Initial Version
 *      Govind Dubey            09-Sep-2018         Added PPM Approver level fields
 *      Govind Dubey            03-Apr-2019         Modified selectActive method added Ordering
 *      Roopal Verma            05-July-2019        DCP-25340, Added promotion fields Promotion__c and Promo_Code__c
 *      Satya Swain             04 Sep 2019         Added cache for selectActive method as part of INC0225110
 *      Saswati                 15-JAN-2020         DCP-31789
  *     Saswati                 09-Mar-2020          DCP-32046
*       Raja Siva Krishna       24-Aug-2020         DCP-40114
*     Roopal                  01-Sep-2020         DCp-40115 Added Lastmodified and Approval_Hierarchy_Type__c
  *     Saswati                 09-Mar-2020          DCP-32046
*       Raja Siva Krishna       24-Aug-2020         DCP-40114
*       Monika Parihar          06-Dec-2020         DCP-43373
*       Himanshu                30-Mar-2022         Code Scan Fixes
 *    --------------------------------------------------------------------------------------------------------------- 
 *                    
 */
public with sharing class CustomApprovalMatrixSelector extends ilib_SObjectSelector {
    
    //private static final String LOG_TITLE = 'CustomApprovalMatrixSelector';
    public static final string STRING_SALES_QUERY_LOG = 'SalesQueryLogs';
    
    // DGP-11 & DGP-354
    private static final Set<String> RECORD_TYPES_FOR_CPQ = new Set<String> {'CPQ_Material_Number', 'CPQ_Material_Group_1', 'CPQ_Discount'};
    private String overriddenOrderBy;

    /**
    *  @author Rohan Chandarana    
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Custom Approval Matrix
    **/
    public Schema.SObjectType getSObjectType() {
        return Custom_Approval_Matrix__c.sObjectType;
    }

    /**
     *  @author  Rohan Chandarana 
     *  @description Retrieve list of fields for Custom Appproval Matrix sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Custom_Approval_Matrix__c.Active__c,
           Custom_Approval_Matrix__c.Discount_Level_1__c,
           Custom_Approval_Matrix__c.Discount_Level_2__c,
           Custom_Approval_Matrix__c.Discount_Level_3__c,
           Custom_Approval_Matrix__c.Discount_Level_4__c,
           Custom_Approval_Matrix__c.Discount_Level_5__c,
           Custom_Approval_Matrix__c.Discount_Level_6__c,
           Custom_Approval_Matrix__c.Discount_Level_7__c,
           Custom_Approval_Matrix__c.Discount_Level_8__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_1__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_2__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_3__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_4__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_5__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_6__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_7__c,
           Custom_Approval_Matrix__c.Discount_Amount_Level_8__c,
           Custom_Approval_Matrix__c.Material_Class__c,
           Custom_Approval_Matrix__c.Product__c,
           Custom_Approval_Matrix__c.Approval_Hierarchy__c,       
           Custom_Approval_Matrix__c.Min_Discount__c,
           Custom_Approval_Matrix__c.Min_Discount_Amount__c,
           Custom_Approval_Matrix__c.Promotion__c,
           Custom_Approval_Matrix__c.Promo_Code__c,
           Custom_Approval_Matrix__c.Sales_Organization__c,
            Custom_Approval_Matrix__c.Material_Group_1__c, // DCP-31789
           Custom_Approval_Matrix__c.Material_Number__c, // DCP-31789
            Custom_Approval_Matrix__c.Agreement_Minimum_Discount__C,//DCP-32563
            Custom_Approval_Matrix__c.Action__c,
            Custom_Approval_Matrix__c.Agreement_Record_Type__c,
            Custom_Approval_Matrix__c.Clause_Name__c,
            Custom_Approval_Matrix__c.Region__c,
            Custom_Approval_Matrix__c.Approval_Hierarchy_Type__c, //DCP-40115
            Custom_Approval_Matrix__c.LastModifiedDate, //DCP-40115
            Custom_Approval_Matrix__c.Email_Queue__c,
            Custom_Approval_Matrix__c.Name //DCP 43373
       };
    }

    /**
     *  @author  Rohan Chandarana 
     *  @description Active Approval Matrix Entries 
     *  @return List<Custom_Approval_Matrix__c> List of active Custom Approval Matrix
     **/
    public List<Custom_Approval_Matrix__c> selectActive() {
        return selectActive(null);
    }

    
    // Added by Satya for INC0225110
    private static Map<String,List<Custom_Approval_Matrix__c>> cacheForSelectActive = new Map<String, List<Custom_Approval_Matrix__c>>();
    /**
     *  @author  Rohan Chandarana 
     *  @description Active Approval Matrix Entries 
     *  @params Set<String> setTypes
     *  @return List<Custom_Approval_Matrix__c> List of active Custom Approval Matrix
     **/
    public List<Custom_Approval_Matrix__c> selectActive(Set<String> setTypes) {

        String serialized = UtilsCollection.serializeIds(setTypes);
        
        if (cacheForSelectActive.containsKey(serialized))
            return cacheForSelectActive.get(serialized);

        String strCondition = 'Active__c=true' + (setTypes == null ? ''  : ' AND RecordType.DeveloperName IN :setTypes');
        List<Custom_Approval_Matrix__c> res = (List<Custom_Approval_Matrix__c>) Database.query(
            newQueryFactory().
            selectField('Active__c').
            selectField('Discount_Level_1__c').
            selectField('Discount_Level_2__c').
            selectField('Discount_Level_3__c').
            selectField('Discount_Level_4__c').
            selectField('Discount_Level_5__c').
            selectField('Discount_Level_6__c').
            selectField('Discount_Level_7__c').
            selectField('Discount_Level_8__c').
            selectField('Discount_Amount_Level_1__c').
            selectField('Discount_Amount_Level_2__c').
            selectField('Discount_Amount_Level_3__c').
            selectField('Discount_Amount_Level_4__c').
            selectField('Discount_Amount_Level_5__c').
            selectField('Discount_Amount_Level_6__c').
            selectField('Discount_Amount_Level_7__c').
            selectField('Discount_Amount_Level_8__c').
            selectField('Material_Class__c').
            selectField('Product__c').
            selectField('Approver__c').
            selectField('Promotion_Code__c').
            selectField('RecordType.DeveloperName').
            selectField('Distribution_Channel__c').
            selectField('Country__c'). 
            selectField('Currency__c').
            selectField('Price_List_Type__c'). //DGP-52
            selectField('Min_Discount__c'). //DGP-52
            selectField('Min_Discount_Amount__c'). //DGP-52
            selectField('Post_Pricing_Message__c').
            selectField('Approval_Hierarchy__c').
            selectField('Approval_Hierarchy__r.Approver_Level_1__c').
            selectField('Approval_Hierarchy__r.Approver_Level_2__c').
            selectField('Approval_Hierarchy__r.Approver_Level_3__c').
            selectField('Approval_Hierarchy__r.Approver_Level_4__c').
            selectField('Approval_Hierarchy__r.Approver_Level_5__c').
            selectField('Approval_Hierarchy__r.Approver_Level_6__c').
            selectField('Approval_Hierarchy__r.Approver_Level_7__c').
            selectField('Approval_Hierarchy__r.Approver_Level_8__c').
            selectField('Material_Number__r.Material_Number__c'). //31789
            setCondition(strCondition).
           //DCP-39486-1  addOrdering('Sales_Organization__c',ilib_QueryFactory.SortOrder.DESCENDING,true).
           //DCP-39486-1  addOrdering('Country__c',ilib_QueryFactory.SortOrder.DESCENDING,false).
           addOrdering('LastModifiedDate',ilib_QueryFactory.SortOrder.DESCENDING).//DCP-40114
            toSOQL()
        );

        cacheForSelectActive.put(serialized, res);
        return res;
    }
 
    /**
     *  @author  Rohan Chandarana 
     *  @description Order the Approval Matrix Records
     **/
    public override String getOrderBy() 
    {
        // DGP-11 & DGP-354
        if(String.isNotBlank(overriddenOrderBy)) {
            return overriddenOrderBy;
        }
        
        return 'RecordType.DeveloperName, LastModifiedDate'; //DCP-40114 added last modified date
    }

    /**
     *  @author Rohan Chandarana 
     *  @description fetch approval matrix for the ids passed in the argument
     *  @param idSet set of approval matrix ids
     *  @return list of approval matrix records
     **/
    public List<Custom_Approval_Matrix__c> selectById(Set<ID> idSet) 
    {
        return (List<Custom_Approval_Matrix__c>) selectSObjectsById(idSet);
    }
	
    /*
    * @author Monika Parihar
    * @params List<String> workflowName
    * @returns List<Custom_Approval_Matrix__c>
    */
    public List<Custom_Approval_Matrix__c> returnCustomApprovalMatrixObj(List<String> workflowName,Id  idRecordtypeId)
    {
        return (List<Custom_Approval_Matrix__c>) Database.query(
            newQueryFactory()
            .setCondition('Name IN :workflowName AND RecordtypeId = :idRecordtypeId ')
            .toSOQL());
    }
    
    
	
    /***
     * Method to fetch active Custom Approval Matrix (and associated Custom Approval Matrix Product) records
     * having CPQ specific record types for given account region and set of material numbers.
     ***/
    public List<Custom_Approval_Matrix__c> fetchApprovalMatrixRecordsForCPQ(String accountRegion, Set<String> materialNumberSet) {
        
        return fetchApprovalMatrixRecords(new List<String>{accountRegion}, materialNumberSet, RECORD_TYPES_FOR_CPQ);
    }
    
	/***
     * Method to fetch active Custom Approval Matrix (and associated Custom Approval Matrix Product) records for given
     * set of Account Regions, Material Numbers and Record Types.
     ***/
    public List<Custom_Approval_Matrix__c> fetchApprovalMatrixRecords(List<String> accountRegionSet, Set<String> materialNumberSet, Set<String> recordTypeSet) {
        
        overriddenOrderBy = 'LastModifiedDate DESC';
        String regionStr = '(\'' + String.join(accountRegionSet, '\', \'') + '\')'; 
        
        ilib_QueryFactory query = newQueryFactory().
            selectField('Id').
            selectField('Active__c').
            selectField('Region__c').
            selectField('Country__c'). 
            selectField('Currency__c').
            selectField('Price_List_Type__c').
            selectField('Material_Group_1__c').
            selectField('Distribution_Channel__c').
            selectField('RecordType.DeveloperName').
            selectField('Approval_Hierarchy_Type__c').
            setCondition('Active__c = TRUE AND RecordType.DeveloperName IN :recordTypeSet AND Region__c INCLUDES ' + regionStr);
        
        query.subselectQuery('Custom_Approval_Matrix_Products__r').
            selectField('Id').
            selectField('Product__r.ProductCode').
            setCondition('Product__r.ProductCode IN :materialNumberSet').
            addOrdering('LastModifiedDate',ilib_QueryFactory.SortOrder.DESCENDING);
        
        List<Custom_Approval_Matrix__c> res = (List<Custom_Approval_Matrix__c>) Database.query(query.toSOQL());
        
        return res; 
    }
}