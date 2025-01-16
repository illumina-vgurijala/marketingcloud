/**
 *    @author Debanka Chakraborty
 *    @date   11-07-2018
 *    @description    Class to get the work Detail records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *      Developer                      Date                Description
 *      Debanka                        11-July-2018        Initial Version
 *      KD                             3-March-2021         DCP-43163 Added selectWorkDetailRecordsByInstalledProduct
 *      Adyasha                        17-May-2021          DCP-38809:Added Fields
 *      Akshay                         17-May-2021          DCP-46579 Added Discount_Reason__c
 *      Adyasha                        07-Jun-2021          DCP-38810: Added fields in selectNonCanceledWorkDetailsForWorkOrderId method
 *      KD                             16-June-2021         DCP-38810 : Renamed selectWorkDetailsByWorkOrderIdExcludingFew to selectBillableWorkDetailsByWorkOrderIdExcludingFew
 *      Adyasha                        29-Jun-2021          DCP-45793: Added selectNonLaborTravelWorkDetailsByWOIdWithRecordType method
 *      Sarath                         02-July-2021         DCP-47421 - PS Log Query Instrumentation for Service Selectors
 *      Rucha Dalvi                    31-Aug-2021          DCP-46273 - Added fields to selectWorkDetailsByWorkDetailId, selectWorkDetailsForWorkOrderId
 *      Shivani                        08-Sep-2021          DCP-47686 : OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition
 *      Vignesh                        16-Sep-2021          DCP-49744: Method selectWorkDetailsByWOIdLineType Created
 *      Pooja                          17-March-2022        DCP-49921: Method selectWorkDetailFields, added field "SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Date_Installed__c" and "Consumption_Confirmed__c" in the dynamic query

 *    ------------------------------------------------------------------------------------ 
 *  
 */
public with sharing class WorkDetailsSelector extends ilib_SObjectSelector
{   
    private static final String STRING_SERVICE_QUERY_LOGS = 'servicequerylogs';
    //Added for DCP-38817
    private Boolean removeDefaultOrderBy=false;
    private static final String LOG_TITLE = 'WorkDetailsSelector';

    /**
     *  @author Debanka 
     *  @description  
     *  @return SObjectType The Schema.SObjectType of the proposal
     */
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Service_Order_Line__c.sObjectType;
    }

    /**
     *  @author Vaibhav
     *  @description  override default order by
     *  @return string
     */
    public override String getOrderBy()
    {
        if(removeDefaultOrderBy)
        {
            return 'LastModifiedDate DESC';
        }
        else
        {
            return super.getOrderBy();
        }
    }

    /**
     *  @author  Debanka 
     *  @description Retrieve list of fields for SVMXC__Service_Order_Line__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            SVMXC__Service_Order_Line__c.Id, 
            SVMXC__Service_Order_Line__c.Name, 
            SVMXC__Service_Order_Line__c.SVMXC__Service_Order__c, 
            SVMXC__Service_Order_Line__c.SVMX_PS_VS_Return_Installed_Product__c,
            SVMXC__Service_Order_Line__c.SVMXC__Line_Type__c,
            SVMXC__Service_Order_Line__c.RecordTypeId,
            SVMXC__Service_Order_Line__c.Show_On_Case__c,
            SVMXC__Service_Order_Line__c.SVMXC__Serial_Number__c,
            SVMXC__Service_Order_Line__c.SVMXC__Product__c,
            SVMXC__Service_Order_Line__c.CreatedDate,
            SVMXC__Service_Order_Line__c.SVMXC__Line_Status__c
        };
    }

    /*Returns Parts Swap Work Details from ID*/
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsMatchingWorkOrderId(Set<Id> setWorkOrderId, String strRecordType, String strLineType) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsMatchingWorkOrderId', UtilsCollection.serializeIds(setWorkOrderId) + '|' + strRecordType + '|' + strLineType);

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .setCondition(' SVMXC__Service_Order__c IN:setWorkOrderId AND RecordTypeId =:strRecordType AND SVMXC__Line_Type__c= :strLineType')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
        logger.stop(res.size());
        return res;
    }
    /**
     *  @author Shashank Singhal
     *  @description Fetch workdetails for workorderid and recordtype name passed
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWorkOrderIdWithRecordTypeAndShowOnCase(Set<Id> setWorkOrderId, string strRecordTypeName, boolean boolShowOncase) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsByWorkOrderIdWithRecordTypeAndShowOnCase', UtilsCollection.serializeIds(setWorkOrderId) + '|' + strRecordTypeName + '|' + boolShowOncase);

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .setCondition(' SVMXC__Service_Order__c IN :setWorkOrderId AND RecordType.Name = :strRecordTypeName AND Show_On_Case__c = :boolShowOncase')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch workdetails for workorderid and recordtype name passed
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWorkOrderIdWithRecordType(Set<Id> setWorkOrderId, string strRecordTypeName) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsByWorkOrderIdWithRecordType', UtilsCollection.serializeIds(setWorkOrderId) + '|' + strRecordTypeName);

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Serial_Number__r.Product_Category__c')
            .selectField('SVMXC__Product__r.Product_Category__c')
            //Added Fields for DCP-38809
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Start_Date_and_Time__c')
            .selectField('SVMXC__End_Date_and_Time__c')
            .selectField('SVMXC__Service_Order__r.Installed_Product_Serial_Number__c')
            .selectField('SVMXC__Product__r.Material_Number__c')
            .selectField('SVMXC__Product__r.Name')
            //End of fields for DCP-38809
            .selectField('Discount_Reason__c')//DCP-46579(Added here to minimize pereformance issues due to long text area field)
            .selectField('SVMXC__Product__r.ProductCode')//DCP-46579
            .selectField('SVMXC__Activity_Type__c')
            .setCondition(' SVMXC__Service_Order__c IN :setWorkOrderId AND RecordType.Name = :strRecordTypeName')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Nitin Sood
     *  @description Fetch workdetails and related WorkOrder Information for workDetail 
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWorkDetailId(Set<Id> setWorkDetailId ) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsByWorkDetailId', UtilsCollection.serializeIds(setWorkDetailId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Service_Order__r.SVMXC__Company__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Contact__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Case__c')
            .selectField('SVMX_PS_VS_Return_Installed_Product__c')
            .selectField('SVMXC__Product__r.Material_Number__c')
            .selectField('SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__c')
            //DCP-46273 Added fields
            .selectField('SVMXC__Service_Order__r.Confirmed_Operability__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Order_Status__c')
            .selectField('Work_Order_Type__c')
            .selectField('SVMXC__Activity_Type__c')
            .setCondition('Id IN :setWorkDetailId')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch workdetails
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWorkDetailStringId(Set<String> setWorkDetailId ) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsByWorkDetailStringId', UtilsCollection.serializeIds(setWorkDetailId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMX_PS_External_ID__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('SVMXC__Consumed_From_Location__c')
            .selectField('SVMXC__Consumed_From_Location__r.Type__c')
            .setCondition(' Id IN :setWorkDetailId')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch workdetails correspding to Work Order ID and specified activity type
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWorkOrderIdAndActivityTypeAndStatus(Set<Id> setWorkOrderId, String strActivityType, string strStatus) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsByWorkOrderIdAndActivityTypeAndStatus', UtilsCollection.serializeIds(setWorkOrderId) + '|' + strActivityType + '|' + strStatus);

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .setCondition(' SVMXC__Service_Order__c IN:setWorkOrderId AND SVMXC__Activity_Type__c =:strActivityType AND SVMXC__Line_Status__c =:strStatus')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Ritika Maheshwari
     *  @description Fetch workdetails correspding to Work Order ID excluding some work details
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectBillableWorkDetailsByWorkOrderIdExcludingFew(Set<Id> setWorkOrderId, Set<Id> setWorkDetailsToBeExcluded) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectBillableWorkDetailsByWorkOrderIdExcludingFew', UtilsCollection.serializeIds(setWorkOrderId) + '|' + UtilsCollection.serializeIds(setWorkDetailsToBeExcluded));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Actual_Quantity2__c')
            .selectField('Duration_in_hours__c')
            .selectField('SVMXC__Is_Billable__c')
            .setCondition(' SVMXC__Service_Order__c IN:setWorkOrderId AND ID NOT IN : setWorkDetailsToBeExcluded AND SVMXC__Is_Billable__c = TRUE')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/*******************************************************************************************************
    * @description Query Billable Work Detail Records filtered by Work Order Ids
    * @param setWorkOrderId Set<Id>
    * @return List<SVMXC__Service_Order_Line__c>
    */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWorkOrderId(Set<Id> setWorkOrderId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsByWorkOrderId', UtilsCollection.serializeIds(setWorkOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Actual_Quantity2__c')
            .selectField('Duration_in_hours__c')
            .selectField('SVMXC__Is_Billable__c')
            .setCondition(' SVMXC__Service_Order__c IN:setWorkOrderId AND SVMXC__Is_Billable__c = TRUE')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/*******************************************************************************************************
    * @description Query Work Detail Records filtered by Work Order Ids
    * @param setWorkOrderId Set<Id>
    * @return List<SVMXC__Service_Order_Line__c>
    */	
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsForWorkOrderId(Set<Id> setWorkOrderId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsForWorkOrderId', UtilsCollection.serializeIds(setWorkOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.EmployeeNumber')
	        .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.isPortalEnabled')
            //Added by shruti Karn to populate Product group on work order for ICE integration
            .selectField('SVMXC__Product__c')
            .selectField('Is_Auto_Created__c')
            .selectField('SVMXC__Service_Order__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('SVMXC__Product__r.Product_Group__c')
            .selectField('Is_Under_Service_Contract__c')
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Is_Billable__c')
            .selectField('Non_Billable_Reason__c')
            //Added Fields for DCP-38809
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Start_Date_and_Time__c')
            .selectField('SVMXC__End_Date_and_Time__c')
            .selectField('SVMXC__Service_Order__r.Installed_Product_Serial_Number__c')
            .selectField('SVMXC__Product__r.Material_Number__c')
            .selectField('SVMXC__Product__r.Name')
            //End of fields for DCP-38809
			.selectField('Approval_Status__c')//DCP-43634
            .selectField('Discount_Reason__c')//DCP-46579(Added here to minimize pereformance issues due to long text area field)
            .selectField('SVMXC__Product__r.ProductCode')//DCP-46579
            //Added for DCP-46273
            .selectField('SVMXC__Service_Order__r.Confirmed_Operability__c')
            .selectField('SVMXC__Service_Order__r.Related_WO_to_Confirm_Operability__c')
            .selectField('Work_Order_Type__c')
            .selectField('SVMXC__Activity_Type__c')
            .selectField('Labor_Numeric__c')//DCP-47686
            .selectField('Indirect_in_hours__c')
            .selectField('Labor_Hours__c')
            .selectField('Travel_Time_in_hours__c')
            .selectField('Billable_AutoUpdated__c')
            .setCondition('SVMXC__Service_Order__c IN:setWorkOrderId')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Ritika Maheshwari
     *  @description Fetch labor workdetails correspding to Work Order ID excluding some work details
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectLaborWorkDetailsByWorkOrderIdExcludingFew(List<Id> lstWorkOrderId, Set<Id> setWorkDetailsToBeExcluded) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLaborWorkDetailsByWorkOrderIdExcludingFew', UtilsCollection.serializeIds(new Set<Id>(lstWorkOrderId)) + '|' + UtilsCollection.serializeIds(setWorkDetailsToBeExcluded));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Service_Order__c')
            .setCondition(' SVMXC__Service_Order__c IN:lstWorkOrderId AND ' + 
                          ' ID NOT IN : setWorkDetailsToBeExcluded AND SVMXC__Line_Type__c = \'LABOR\' AND SVMXC__Activity_Type__c != NULL')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Mandeep Singh
     *  @description Fetch workdetails fields and related records fields
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailFields(Set<Id> setWorkDetailsIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailFields', UtilsCollection.serializeIds(setWorkDetailsIds));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
			newQueryFactory()
            .selectField('SVMXC__Service_Order__r.SVMXC__Contact__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Site__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Company__c')
            .selectField('SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__c')
            .selectField('SVMX_PS_VS_Return_Installed_Product__r.Product_Code__c')
            .selectField('SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__c')
            .selectField('SVMX_PS_VS_Consumed_Product_Stock__r.Product_Code__c')
            .selectField('SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__r.RMA_Required__c')
            .selectField('SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__r.RMA_Required__c')
            .selectField('SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__r.Service_Product_Type__c')
            .selectField('SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__r.Service_Product_Type__c')
            .selectField('SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Date_Installed__c')// Pooja : DCP-49921
            .selectField('Consumption_Confirmed__c')// Pooja : DCP-49921
			.selectField('SVMXC__Actual_Quantity2__c')
            .setCondition('Id IN:setWorkDetailsIds AND (( SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__r.RMA_Required__c = true) OR ( SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__r.RMA_Required__c = true))')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Digvijay Singh
     *  @description Fetch workdetails fields and related records fields
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailRecords(Id workOrderId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailRecords', String.valueOf(workOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('Name')
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Product__c')
            .selectField('SVMXC__Product__r.Name')
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Work_Description__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('CreatedDate')
            .setCondition('SVMXC__Service_Order__c=:workOrderId')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description Fetch labor workdetails correspding to Work Order ID
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsWithLaborOrTravelOrPartsUsed(set<Id> setWorkOrderId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailsWithLaborOrTravelOrPartsUsed', UtilsCollection.serializeIds(setWorkOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('SVMXC__Line_Type__c')
            .selectField('Travel_Time_in_hours__c')
            .selectField('Labor_Hours__c')
            .selectField('CreatedDate')
            .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__c')
            .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.IsPortalEnabled')
		    .setCondition('SVMXC__Service_Order__c IN:setWorkOrderId AND ((SVMXC__Line_Type__c = \'Parts\') OR (SVMXC__Line_Type__c = \'Labor\'))')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
    /**
     *  @author Vaibhav
     *  @description DCP-29080 - Get all parts work details associated to work orders
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectPartsWorkDetailsByWorkOrderId(set<Id> setWorkOrderId) 
    {
		Id loggedInUserId = UserInfo.getUserId() ;
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsWorkDetailsByWorkOrderId', UtilsCollection.serializeIds(setWorkOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__Service_Order__c IN:setWorkOrderId AND Consumption_Confirmed__c = FALSE AND CreatedById =: loggedInUserId AND SVMXC__Line_Type__c = \'Parts\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author Prashanth
     * @descirption Get all the work details which have blank contracts for the given work orders.
     * @return List of work details
     */
    public List<SVMXC__Service_Order_Line__c> selectBlankContractWorkDetailsByWorkOrderId(Set<Id> setWorkOrderId)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectBlankContractWorkDetailsByWorkOrderId', UtilsCollection.serializeIds(setWorkOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__Service_Order__c IN:setWorkOrderId AND ERP_Header_Contract_Number__c = NULL AND ERP_Contract_Line_Number__c = NULL')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description - [DCP-37765] - Fetch open labor workdetails correspding to Work Order ID excluding some work details
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectOpenLaborWorkDetailsByWorkOrderId(set<Id> setWorkOrderId, Set<String> queryFilterStatuses) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenLaborWorkDetailsByWorkOrderId', UtilsCollection.serializeIds(setWorkOrderId) + '|' + UtilsCollection.serializeIds(setWorkOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Service_Order__c')
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Line_Type__c')
            .selectField('SVMXC__Line_Status__c')
            .setCondition(' SVMXC__Service_Order__c IN:setWorkOrderId AND ' + 
                          ' SVMXC__Line_Type__c = \'LABOR\' AND SVMXC__Line_Status__c NOT IN : queryFilterStatuses')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/**
     *  @author : Sandeep Chatrathi
     *  @description Fetch workdetails which are not canceled correspding to Work Order ID
     *  @return List of Work Details
     */
	public List<SVMXC__Service_Order_Line__c> selectNonCanceledWorkDetailsForWorkOrderId(Set<Id> setWorkOrderId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNonCanceledWorkDetailsForWorkOrderId', UtilsCollection.serializeIds(setWorkOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Product__c')
            .selectField('SVMXC__Service_Order__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('Is_Under_Service_Contract__c')
            .selectField('SVMXC__Is_Billable__c')
            .selectField('Non_Billable_Reason__c')
            .selectField('SVMXC__Activity_Type__c')
            // Adding fields as part of DCP-38810
            .selectField('SVMXC__Product__r.ProductCode')
            .selectField('Labor_Hours__c')
            .selectField('SVMXC__Actual_Quantity2__c')
            // end of DCP-38810
            .selectField('SVMXC__Product__r.Product_Group__c')
            .setCondition(' SVMXC__Service_Order__c IN:setWorkOrderId AND SVMXC__Line_Status__c!=\'Canceled\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Sravan
     *  @description DCP-33467: Fetch Parts workdetails correspding to work details id set
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWDWithLineTypeParts(set<Id> setIdtoSpareWd) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWDWithLineTypeParts', UtilsCollection.serializeIds(setIdtoSpareWd));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()		   
            .selectField('SVMXC__Consumed_From_Location__c')
            .selectField('SVMX_PS_VS_Consumed_Product_Stock__c')
            .selectField('SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__c')
            .selectField('SVMX_PS_VS_Consumed_Stocked_Serial__c')
            .selectField('Batch_Number__c')
            .selectField('SVMXC__Actual_Quantity2__c')
            .selectField('SVMXC__Service_Order__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('Debrief_Batch_Number__c')
            .selectField('Debrief_Batch_Number__r.Batch_Number__c')
            .selectField('Batch_Lookup__c')
            .setCondition('Id IN:setIdtoSpareWd AND SVMXC__Line_Type__c = \'Parts\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Sravan
     *  @description DCP-33467: Fetch Parts workdetails correspding to workorder id set
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWDWTypePartsByWorkOrderId(set<Id> setWOIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWDWTypePartsByWorkOrderId', UtilsCollection.serializeIds(setWOIds));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__Service_Order__c IN:setWOIds AND SVMXC__Line_Type__c = \'Parts\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/**
     *  @author : Sandeep
     *  @description DCP-38965 - Fetch workdetails to update the is billable field from wo.
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWDLinkedWithBillableWO(set<Id> setWoId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWDLinkedWithBillableWO', UtilsCollection.serializeIds(setWoId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()       
            .selectField('SVMXC__Line_Type__c')
            .selectField('Indirect_in_hours__c')
            .selectField('SVMXC__Is_Billable__c')
            .selectField('SVMXC__Service_Order__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('Non_Billable_Reason__c')
            .setCondition('Non_Billable_Reason__c = null and SVMXC__Line_Status__c !=  \'Canceled\'  and SVMXC__Line_Type__c !=\'Tools\' and Indirect_in_hours__c=null and (not SVMXC__Activity_Type__c  like \'%Review\') and svmxc__service_order__C IN : setWoId and SVMXC__Is_Billable__c =false')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
	}

    /**
     *  @author Vaibhav
     *  @description DCP-38817 - Fetch Non Billable WorkDetails
     *  @return List of Work Details
     */
    public List < SVMXC__Service_Order_Line__c > selectNonBillableWorkDetailsById(Set < Id > setNonBillableWorkDetailsId)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNonBillableWorkDetailsById', UtilsCollection.serializeIds(setNonBillableWorkDetailsId));

        List<SVMXC__Service_Order_Line__c> res = (List < SVMXC__Service_Order_Line__c > ) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Service_Order__r.SVMXC__Company__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Contact__c')
            .selectField('SVMXC__Service_Order__r.OwnerId')
            .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__c')
            .selectField('Non_Billable_Reason__c')
            .setCondition(' Id IN:setNonBillableWorkDetailsId ')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description DCP-38817 - Fetch workdetails fields and related records fields
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailRecordsWithNonBillableReason(Id workOrderId) 
    {
        removeDefaultOrderBy = true;    
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkDetailRecordsWithNonBillableReason', String.valueOf(workOrderId));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('Name')
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Product__c')
            .selectField('SVMXC__Product__r.Name')
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Work_Description__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('LastModifiedDate')
            .selectField('Non_Billable_Reason__c')
            .selectField('SVMXC__Group_Member__c')
            .selectField('SVMXC__Group_Member__r.Name')
            .selectField('SVMXC__Line_Type__c')
            .selectField('SVMXC__Actual_Quantity2__c')
            .selectField('Labor_Hours__c')
            .selectField('Travel_Time_in_hours__c')
            .setCondition('SVMXC__Service_Order__c=:workOrderId AND Non_Billable_Reason__c != NULL AND Non_Billable_Reason__c != \'Consumable Warranty\' AND SVMXC__Line_Status__c != \'Canceled\' ')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Raja Siva Krishna
     *  @description DCP-43185 Fetch open labor type workdetails fields and related records fields
     *  @return List of Work Details
     */
    public List<SVMXC__Service_Order_Line__c> selectLaborWorkDetailRecords(set<Id> workOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLaborWorkDetailRecords', String.valueOf(workOrderIds));

        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Activity_Type__c')
            .selectField('SVMXC__Line_Status__c')
            .selectField('CreatedDate')
            .setCondition('SVMXC__Line_Type__c = \'Labor\' AND SVMXC__Line_Status__c != \'Canceled\' AND SVMXC__Service_Order__c IN :workOrderIds')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

     /**
     *  @author Adyasha Satapathy
     *  @description Fetch workdetails with non blocked products with service product types as Spare, Instrument, Consumable for workorderid and recordtype name passed
     *  @return List of Work Details
     **/
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWOIdWithRecordTypeAndServiceProdType(Set<Id> setWorkOrderId, string strRecordTypeName, Set<String> setServiceProductTypes) 
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn(STRING_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '. selectNonLaborTravelWorkDetailsByWOIdWithRecordType',
            UtilsCollection.serializeIds(setWorkOrderId)
        );

        String strQuery = newQueryFactory()
            .selectField('SVMXC__Estimated_Quantity2__c')
            .selectField('SVMXC__Service_Order__r.PO_Number__c')
            .selectField('SVMXC__Product__r.Is_Product_Blocked__c')
            .selectField('SVMXC__Product__r.Service_Product_Type__c')
            .selectField('Field_Replaceable_Unit_Product__c')
            .setCondition(' SVMXC__Service_Order__c IN :setWorkOrderId AND RecordType.Name = :strRecordTypeName AND SVMXC__Product__c != null AND SVMXC__Product__r.Is_Product_Blocked__c = false AND SVMXC__Product__r.Service_Product_Type__c IN :setServiceProductTypes').toSOQL();
            
        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(strQuery);
        if (Feature.isOn(STRING_SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
    
    }

    /*******************************************************************************************************
    * @description : Method to select WorkDetails By WO Id and LineType
    * @param setWorkOrderId - List of Work OrderId
    * @param setLineTypes - List of Line Types
    * @return List<SVMXC__Service_Order_Line__c> - list of WorkDetails
    * @example
    ********************************************************************************************************/
    public List<SVMXC__Service_Order_Line__c> selectWorkDetailsByWOIdLineType(list<Id> setWorkOrderId, set<String> setLineTypes) 
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn(STRING_SERVICE_QUERY_LOGS)){ 
            logger = new ilib_LogQuery(LOG_TITLE + '. selectWorkDetailsByWOIdLineType');
        }

        String strQuery = newQueryFactory()
        .selectField('SVMXC__Serial_Number__c')
        .selectField('SVMXC__Service_Order__r.SVMXC__Component__c')
        .selectField('SVMXC__Serial_Number__r.SVMXC__Parent__c')
        .selectField('SVMXC__Serial_Number__r.Service_Product_Type__c')
        .selectField('SVMX_PS_VS_Return_Installed_Product__r.Service_Product_Type__c')
        .setCondition(' SVMXC__Service_Order__c IN :setWorkOrderId AND SVMXC__Line_Type__c IN :setLineTypes AND SVMXC__Line_Status__c = \'open\'').toSOQL();
            
        List<SVMXC__Service_Order_Line__c> res = (List<SVMXC__Service_Order_Line__c>) Database.query(strQuery);
        
        if (Feature.isOn(STRING_SERVICE_QUERY_LOGS)){ 
            logger.stop(res.size());
        }
        return res;
    
    }

}
