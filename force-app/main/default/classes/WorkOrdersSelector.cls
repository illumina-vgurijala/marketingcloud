/**
 *    @author Ritika Maheshwari
 *    @date   26-05-2018
 *    @description    Class to get the Work Order records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Ritika                 26-May-2018             Initial Version
 *    Debalina               04-June-2018            DCP-803/DCP-802
 *    Sandeep Ram Ch.        05-July-2018            DCP-575
 *    Soumya Ranjan Sahu     10-Sept-2018            Added selectWorkOrdersFromIds method
 *    Adyasha Satapathy      07 May 2021             Added selectWorkOrderWithWorkDetails for DCP-38809/DCP-47462
 *    Adyasha Satapathy      07 May 2021             Added Account_Region__c field  for DCP-46472
 *    KD                     20-May-2021             Added Query Instrumentation to selectWorkOrders
 *    KD                     31-May-2021             Added New method selectWOByName
 *    Adyasha                24-Jun-2021             DCP-45746: Added fields in selectWorkOrderLstFromStringIds method
 *    Gladis                 25-Jun-2021             DCP-38816: Fetch work orders which are associated with Opportunity Id's passed as parameter
 *    Sarath                 28-June-2021            DCP-47421 - PS Log Query Instrumentation for Service Selectors
 *    Shivani                24-Aug-2021             DCP-47684 - Add Visibility of Code Types on Case/Work Order
 *    Nishan Shetty          27-Aug-2021             CMCP-32 -Added new fields in selectWorkOrders method.
 *    Rucha Dalvi            26-Aug-2021             DCP-46273 - Added field to selectWorkOrders, added method:selectWorkOrderWithRelatedWorkOrder 
 *    Gladis                 01-Sep-2021             CMCP-16 Added method workOrdersWithShipmentPartsOrder to Fetch Work orders with related to Parts Orders with type Shipment.
 *    Shivani                16-Sep-2021             DCP-47698 - Sync Acceptance Code to Install Work Order
 *    Shivani                28-Feb-2022             DCP-49675 - Elevation 2.0 Technical Plan of Action Send Notification
 *    Rohan                  23-Mar-2022             DCP-49682  Elevation 1.0 Removal 
 *    Preetha                29-Mar-2022             QACM-18 Added SVMXC__Order_Status__c in the query in selectWorkOrderIdOnCase Method
 *    Preetha                29-Mar-2022             QACM-770 Added selectWorkOrderIdByCaseId method
 *    Sagar                  29-Sep-2022             DCP-56433 Added Fields to select in the query in selectWorkOrders Method
 *    Avina                  06-Oct-2022             QACM-175 Created selectWorkOrderIdWithCase method to retrieve workorder with case 
 *    Rohan                  20-Dec-2022             DCP-56388 Added selectElevatedWorkOrders
 *    Saikiran               01-Aug-2023             CMCM-261  Added the field SVMXC__Component__r.SVMXC__Status__c in the query
 *    Priya               07-Nov-2023             CMCM-301  Added new method selectWorkOrdersWithNonNullContact
 *    Siddartha Reddy Kalam  28-Nov-2023             CMCM-3980 Added LWC Related Selectors
 *    Sudarshan              05-Dec-2023             CMCM-1354  EOL WO Changes
 *    Nancy                  13-Feb-2024             CMCM-5307 Work Order Trigger Query Optimization
 * ------------------------------------------------------------------------------------ 
 */
public with sharing class WorkOrdersSelector
{
    private static final String LOG_TITLE = 'WorkOrdersSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String STRING_SERVICE_ACTIVITIES = 'Service Activities';
    private static final String STRING_RETURN = 'Return';
    private static final String STRING_CLOSED_DUPLICATE = 'Closed-Duplicate';
    private static final String STRING_INSTALLATION ='Installation';
    private static final String STRING_RETURN_SCRAP_DECOMMISSION = 'Return Scrap Decommission';

    /**
     *  @author Ritika Maheshwari
     *  @description Fetch work orders associated with case which are not cancelled
     *  @param Work order ids
     *  @param case ids
     *  @return work orders which are not cancelled
     */
    public List<SVMXC__Service_Order__c> selectWorkOrders(Set<Id> setWorkOrderIds, Set<Id> setCaseIds, String strExcludeWOStatus) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrders', UtilsCollection.serializeIds(setWorkOrderIds) + '|' + UtilsCollection.serializeIds(setCaseIds) + '|' + strExcludeWOStatus);

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where Id NOT IN :setWorkOrderIds AND SVMXC__Case__c IN :setCaseIds AND SVMXC__Order_Status__c != :strExcludeWOStatus];
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Debalina
     *  @description Fetch work orders which are associated with status passed as parameter
     *  @return List of work orders
     **/
    public List<SVMXC__Service_Order__c> selectWorkOrdersForAppropriateStatus(Set<Id> setWorkOrderIds, String strWOStatus) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersForAppropriateStatus', UtilsCollection.serializeIds(setWorkOrderIds) + '|' + strWOStatus);

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Case__r.ContactId,
        SVMXC__Case__r.OwnerId,
        SVMXC__Contact__c
        From SVMXC__Service_Order__c
        Where Id  IN :setWorkOrderIds AND SVMXC__Order_Status__c = :strWOStatus];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        return res;
    }

    /**
     *  @author      : Digvijay
     *  @description : Fetch workorders for id passed
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderLstFromIds(set<Id> setWorkOrderIds,set<Id> setcaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderLstFromIds', UtilsCollection.serializeIds(setWorkOrderIds) + '|' + UtilsCollection.serializeIds(setcaseIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c,
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Billing_Type_Set_Manually__c,
        SVMXC__SLA_Terms__c
        From SVMXC__Service_Order__c
        Where ID IN :setWorkOrderIds OR SVMXC__Case__c IN :setcaseIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Debalina
     *  @description Fetch work orders based on work order ids passed
     *  @return work orders 
     */
    public List<SVMXC__Service_Order__c> selectWorkOrders(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrders', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c,
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Case__r.OwnerId,
        Partner_Work_Order__c,
        Total_Open_Work_Details__c,
        Integration_Status__c,
        Billing_Type_Set_Manually__c,
        Distributor_Account__c,
        SVMXC__Company__r.Name,
        SVMXC__Company__r.ERP_Customer_Id__c,
        SVMXC__Contact__c,
        SVMXC__Billing_Type__c,
        Parts_Order_Status__c,
        Opportunity__c,
        Opportunity__r.Id,
        SVMX_PS_External_ID__c,
        Qualified_for_Batched_Sync_to_ERP__c,
        SVMXC__Product__c,
        ERP_Order_Number__c,
        SVMXC__Component__r.Product_Category__c,
        SVMXC__Product__r.Product_Category__c,
        SVMXC__Component__r.Service_Bill_Of_Materials__c,
        SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c,
        Warning_Message__c,
        Record_Type__c,
        SVMXC__Product__r.Regulatory_Type__c,
        SVMXC__Case__r.SVMXC__Component__c,
        SVMXC__Case__r.SVMXC__Component__r.Service_Bill_Of_Materials__c,
        SVMXC__Case__r.SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c,
        SVMXC__Case__r.SVMXC__Product__c,
        IP_Asset_Type__c,
        SVMXC__Order_Type__c,
        Logged_In_User_Profile__c,
        Send_to_ERP__c,
        SVMXC__Site__c,
        SVMXC__Component__r.Installed_Product_Upgrade_Type__c,
        SVMXC__Case__r.SVMXC__Component__r.Installed_Product_Upgrade_Type__c,
        Sold_To_Account__c,
        SVMXC__Product__r.Product_Group__c,
        SVMXC__Product__r.ProductCode,
        SVMXC__Product__r.Name,
        SVMXC__Product__r.Service_Product_Type__c,
        SVMXC__Component__r.SVMXC__Serial_Lot_Number__c,
        SVMXC__Component__r.Name,
        Parts_Consumed_By_SAP__c,
        Count_of_Estimated_Travel_Lines__c,
        Count_of_Estimated_Labor_Lines__c,
        SVMXC__Component__r.SVMXC__Product__r.Line_Of_Business__c,
        SVMXC__Component__r.SVMXC__Product__c,
        Case_Record_Type__c,
        SVMXC__Case__r.Work_Order_Status__c,
        SVMXC__Case__r.Has_Resolution_Code__c,
        SVMXC__Case__r.Has_Analysis_Code__c,
        SVMXC__Case__r.Sub_Type__c,
        SVMXC__Case__r.RecordType.Name,
        SVMXC__Case__r.Has_BI_Case_Subject_Code__c,
        SVMXC__Case__r.HasHazardCode__c,
        SVMXC__Case__r.QA_Review__c,
        SVMXC__Case__r.Has_SR_Case_Subject_Code__c,
        SVMXC__Case__r.Has_Inquiry_Case_Subject_Code__c,
        SVMXC__Case__r.PAE_PFA_Evaluation_Required__c,
        SVMXC__Case__r.Category__c,
        SVMXC__Case__r.Status,
        Request_Ownership_Status__c,
        Ownership_Requested_By__c,
        Confirmed_Operability__c,
        Total_Labor_Lines_For_Operability__c,
        Customer_Requested_Not_To_Re_Install__c,
        Related_WO_to_Confirm_Operability__c,
        SVMXC__Component__r.Proactive_Connectivity_Status__c,
        Service_Report_Generation__c,
        Sent_to_Qualtrics__c,
        SVMXC__Case__r.AccountId,
        Technical_Elevation__r.Elevation_Owner__c,
        Technical_Elevation__r.Elevation_Manager__c,
        SVMXC__Company__r.Id,
        Installed_Product_Group__c,
        Repair_protocols__c,
        Business_Impact_to_Customer__c,
        Business_Impact_to_Illumina__c,
        Lokalise_Key_ID__c,
        English_Translation_Subject__c,
        English_Translation_Description__c,
        English_Translation_Evaluation__c,
        English_Translation_Verification_Result__c,
        English_Translation_Work_Performed__c,
        SVMXC__Problem_Description__c,
        Evaluation__c,
        Verification_Result__c,
        SVMXC__Work_Performed__c,
        RecordType.Name,
        Additional_Detail__c,// Added by Dhairya Shah for CMCM - 2180 <<
        English_Translation_Additional_Detail__c,// Added by Dhairya Shah for CMCM - 2180 <<
        Related_WO_to_Confirm_Operability__r.Confirmed_Operability__c
        From SVMXC__Service_Order__c
        Where ID IN :setWorkOrderIds
        ];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description Fetch workorders for caseid passed
     *  @return List of Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderIdOnCaseNumber(Set<String> setCaseNumber) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderIdOnCaseNumber', UtilsCollection.serializeIds(setCaseNumber) + '|Service Activities');

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Case__r.CaseNumber
        From SVMXC__Service_Order__c
        Where SVMXC__Case__r.CaseNumber IN :setCaseNumber  AND SVMXC__Order_Type__c = :STRING_SERVICE_ACTIVITIES];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        system.debug('46273 : result '+res);
        return res;
    }
    
    /**
     *  @author Nitin Sood
     *  @description Fetch work orders which are associated with order type passed as parameter and set of Ids Of InstalledProducts passed as parameters
     *  @return List of work orders
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersForAppropriateTypeAndIP(Set<Id> setInstalProductIds, String strWOtype) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersForAppropriateTypeAndIP', UtilsCollection.serializeIds(setInstalProductIds) + '|' + strWOtype);

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        CreatedDate
        From SVMXC__Service_Order__c
        Where SVMXC__Component__c IN :setInstalProductIds AND SVMXC__Order_Type__c = :strWOtype];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Ritika Maheshwari
     *  @description Fetch Number of Number_Of_Parts_And_Tools__c for work Order Id passed
     *  @return Work Order
     */
    public SVMXC__Service_Order__c selectNumberOfPartsAndToolsForWorkOrder(Id idWorkOrder) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNumberOfPartsAndToolsForWorkOrder', idWorkOrder);

        SVMXC__Service_Order__c res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Number_Of_Parts_And_Tools__c,
        Estimate_Debrief_Mismatch__c,
        SVMXC__Product__c,
        SVMXC__Component__r.SVMXC__Serial_Lot_Number__c
        From SVMXC__Service_Order__c
        Where Id = :idWorkOrder];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res == null ? 0 : 1);

        return res;
    }
    
    /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch workorders for account id passed
     *  @return Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersMatchingAccount(Set<Id> setAccountIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersMatchingAccount', UtilsCollection.serializeIds(setAccountIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        CC_Email__c
        From SVMXC__Service_Order__c
        Where SVMXC__Company__c IN :setAccountIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Debanka Chakraborty
     *  @description Fetch workorders for id passed
     *  @return Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderId(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderId', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Estimate_Debrief_Mismatch__c,
        Currently_Applied_Service_Contract__c,
        CreatedDate
        From SVMXC__Service_Order__c
        Where ID IN :setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
     *  @author Ritika M
     *  @description Fetch workorders for for a location, which has flag 'Generate Inventory Snapshot' set to true by SFM
     *  @return Work Order
     */
    public List<SVMXC__Service_Order__c> selectCycleCountWorkOrderforSpanshot(Set<Id> setLocationIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCycleCountWorkOrderforSpanshot', UtilsCollection.serializeIds(setLocationIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Site__c
        From SVMXC__Service_Order__c
        Where SVMXC__Site__c IN :setLocationIds AND Generate_Inventory_Snapshot__c = true];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Debanka Chakraborty
     *  @description Fetch workorder with integration status not "Success"
     *  @return Work Order
     */
    public List<SVMXC__Service_Order__c> selectWOIntegrationStatusNotSuccess(Set<String> setIntegrationStatus, set<id> setCaseIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWOIntegrationStatusNotSuccess', UtilsCollection.serializeIds(setIntegrationStatus) + '|' + UtilsCollection.serializeIds(setCaseIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Integration_Status__c
        From SVMXC__Service_Order__c
        Where Integration_Status__c NOT IN :setIntegrationStatus AND SVMXC__Case__c In :setCaseIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch workorders matching Product ERP Order Number And ERP Order Line Number
     *  @return Work Order
     */
    public List<SVMXC__Service_Order__c> selectWOMatchingProductERPOrderNumberAndERPOrderLineNumber(Set<Id> setProductId, Set<String> setERPOrderNumber,Set<String> setERPOrderLineNumber,Set<String> setOrderType) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWOMatchingProductERPOrderNumberAndERPOrderLineNumber', UtilsCollection.serializeIds(setProductId) + '|' + UtilsCollection.serializeIds(setERPOrderNumber)
                                        + '|' + UtilsCollection.serializeIds(setERPOrderLineNumber) + '|' + UtilsCollection.serializeIds(setOrderType));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        ERP_Order_Line_Quantity__c,
        SVMXC__Product__c,
        ERP_Order_Number__c
        FROM SVMXC__Service_Order__c
        Where ERP_Order_Number__c IN :setERPOrderNumber AND ERP_Order_Line_Number__c IN :setERPOrderLineNumber AND SVMXC__Product__c IN :setProductId AND SVMXC__Order_Type__c IN :setOrderType];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch workorders for caseid passed
     *  @return List of Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderIdOnCase(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderIdOnCase', UtilsCollection.serializeIds(setCaseIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Case__r.SVMXC__Component__c,
        SVMXC__Case__r.Status,
        SVMXC__Case__r.SVMXC__Product__c,
        SVMXC__Product__c,
        SVMXC__Case__r.OwnerId,
        SVMXC__Order_Type__c,
        SVMXC__Case__r.Reason_for_Approval_Denial_of_Reopen__c,
        Reason_for_Approval_Denial_of_Reopen__c,
        Approver_Rejector__c,
        Reason_for_Reopen__c,
        Reopen_Requester__c,
        Order_Previous_Status__c,
        SVMXC__Case__r.Reason_for_Reopen__c,
        WO_Reopen_Status__c,
        Integration_Status__c,
        SVMXC__Case__r.CaseNumber,
        RecordType.Name,
        SVMXC__Contact__r.Name,
        SVMXC__Company__r.Name,
        CreatedDate,
        SVMXC__Group_Member__r.Name,
        SVMXC__Problem_Description__c,
        Evaluation__c,
        English_Translation_Evaluation__c,
        SVMXC__Work_Performed__c,
        English_Translation_Work_Performed__c,
        Verification_Result__c,
        English_Translation_Verification_Result__c,
        Other_Abandoned_Reason__c,
        Subscription_License_Status__c,
        Registrant_Email_Address__c,
        Domain_Name__c,
        Is_Reopen_Approved__c,
        Workgroup_Name__c,
        Subscription__c,
        WO_Precompletion_Status__c
        From SVMXC__Service_Order__c
        Where SVMXC__Case__c IN :setCaseIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch workorders with has Field Support
     *  @return Work Order
     */
    public List<SVMXC__Service_Order__c> selectRelatedWorkOrderWithFieldSupport(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectRelatedWorkOrderWithFieldSupport', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where SVMXC__Group_Member__c!=null AND ID IN:setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Soumya Ranjan Sahu
     *  @description Fetch workorders for id passed
     *  @return Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersFromIds(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersFromIds', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Illumina_Representative__c,
        Customer_Representative__c,
        ICE_WO_Products__c,
        SVMXC__Component__r.SVMXC__Product__r.Product_Group__c,
        SVMXC__Component__r.SVMXC__Status__c,
        SVMXC__Problem_Description__c,
        Evaluation__c,
        SVMXC__Work_Performed__c,
        Verification_Result__c
        From SVMXC__Service_Order__c
        Where Id IN :setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Gagan Sindwani 
     *  @description Fetch workorders without cases
     *  @return Work Order
     *  INC0370929
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersWithoutCasesFromIds(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersFromIds', UtilsCollection.serializeIds(setWorkOrderIds));
        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c,
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Illumina_Representative__c,
        Customer_Representative__c,
        ICE_WO_Products__c,
        SVMXC__Component__r.SVMXC__Product__r.Product_Group__c,
        SVMXC__Component__r.SVMXC__Status__c,
        SVMXC__Problem_Description__c,
        Evaluation__c,
        SVMXC__Work_Performed__c,
        Verification_Result__c,
        SVMXC__Billing_Type__c
        From SVMXC__Service_Order__c
        Where ID IN :setWorkOrderIds AND SVMXC__Case__c = NULL];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        return res;
    }
    
    /**
     *  @author      : Sravan
     *  @description : Fetch workorders for id passed
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderLstFromIds(set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderLstFromIds', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__SLA_Terms__c,
        Billing_Type_Set_Manually__c,
        SVMXC__Order_Type__c,
        createdByID,
        Parts_Consumed_By_SAP__c
        From SVMXC__Service_Order__c
        Where Id IN : setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    
    /**
     *  @author      : Vaibhav
     *  @description : Fetch workorders for id passed
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderLstFromStringIds(set<String> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderLstFromStringIds', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        createdByID,
        SVMXC__Billing_Type__c,
        Total_CS_Review_Activity_Open__c,
        RecordTypeId,
        SVMXC__Order_Type__c,
        Parts_Consumed_By_SAP__c,
        SVMXC__Product__c
        From SVMXC__Service_Order__c
        Where Id IN : setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
        
    /**
     *  @author Dipika
     *  @description Fetch the Work orders
     *  @param setCaseId
     *  @return List of Work Orders
     */
    public List<SVMXC__Service_Order__c> selectOpenWorkOrders(Set<Id> setCaseIds) 
    {
        List<String> closedStatuses = new list<String> { Label.WorkOrderStatusClosed , Label.WorkOrderStatusCompleted, Label.WorkOrderStatusClosedDuplicate  };
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenWorkOrders', UtilsCollection.serializeIds(setCaseIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Order_Previous_Status__c,
        SVMXC__Case__r.Reason_for_Reopen__c,
        SVMXC__Case__r.Status,
        WO_Reopen_Status__c
        From SVMXC__Service_Order__c
        Where SVMXC__Case__c IN :setCaseIds AND SVMXC__Order_Status__c IN: closedStatuses
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Gagan Sindwani
     *  @description Fetch the Work orders not in Closed status
     *  @param setWorkOrderIds
     *  @return List of Work Orders
     *  INC0356376
     */
    public List<SVMXC__Service_Order__c> selectOpenWorkOrdersFromIds(Set<Id> setWorkOrderIds) 	
	{
        List<String> closedStatuses = new list<String> { Label.WorkOrderStatusClosed , Label.WorkOrderStatusCompleted, Label.WorkOrderStatusClosedDuplicate, Label.WorkOrderStatusCanceled  };
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenWorkOrdersFromIds', UtilsCollection.serializeIds(setWorkOrderIds));
        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Order_Type__c,
        SVMXC__Case__r.SVMXC__Component__c,
        SVMXC__Contact__c,
        SVMXC__Product__c,
        SVMXC__Case__r.SVMXC__Product__c
        From SVMXC__Service_Order__c
        Where ID IN :setWorkOrderIds AND SVMXC__Order_Status__c NOT IN :closedStatuses AND SVMXC__Order_Status__c !=NULL AND SVMXC__Order_Type__c !=NULL
        ];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        return res;
    }

    
    /**
     *  @author Dipika
     *  @description Fetch the Work orders
     *  @param setCaseId
     *  @return List of Work Orders
     */
    public List<SVMXC__Service_Order__c> selectReopenRequestedWOForCases(Set<Id> setCaseIds) 
    {
        String reopenRequested = Label.ReopenRequested;
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectReopenRequestedWOForCases', UtilsCollection.serializeIds(setCaseIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Order_Previous_Status__c,
        SVMXC__Case__r.Status,
        SVMXC__Case__r.Reason_for_Approval_Denial_of_Reopen__c
        From SVMXC__Service_Order__c
        Where SVMXC__Case__c IN :setCaseIds AND SVMXC__Order_Status__c = :reopenRequested];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Mandeep Singh
     *  @description Fetch open work orders using set of Ids Of InstalledProducts passed as parameters
     *  @return List of work orders
     */
    public List<SVMXC__Service_Order__c> selectOpenWorkOrdersFromIP(Set<Id> setInstalledProductIds) 
    {
        List<String> closedStatuses = new list<String> { Label.WorkOrderStatusClosed , Label.WorkOrderStatusCompleted , Label.WorkOrderStatusReopenRequested};
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenWorkOrdersFromIP', UtilsCollection.serializeIds(setInstalledProductIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Update_Instrument_Down__c,
        SVMXC__Component__r.Operation_Status__c
        From SVMXC__Service_Order__c
        Where SVMXC__Component__c IN :setInstalledProductIds AND SVMXC__Order_Status__c NOT IN :closedStatuses
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch workorders for caseid passed
     *  @return List of Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersNotClosedDuplicateOnCase(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersNotClosedDuplicateOnCase', UtilsCollection.serializeIds(setCaseIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where SVMXC__Case__c IN :setCaseIds AND SVMXC__Order_Status__c != :STRING_CLOSED_DUPLICATE
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Ritika M
     *  @description Fetch workorders for Order line Numbers
     *  @return List of Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersForOrderLineNumber(Set<String> setOrderLineNumberCanceled) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersForOrderLineNumber', UtilsCollection.serializeIds(setOrderLineNumberCanceled));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where ERP_Order_Line_Number__c IN :setOrderLineNumberCanceled];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch workorders for Order line Numbers whose IP is blank
     *  @return List of Work Order
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersForOrderLineNumberWithBlankIP(Set<String> setOrderLineNumber) 
    {
        String installProd = null;
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersForOrderLineNumberWithBlankIP', UtilsCollection.serializeIds(setOrderLineNumber));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where ERP_Order_Line_Number__c IN :setOrderLineNumber AND SVMXC__Component__c = :installProd];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author      : Naomi Thammadi
     *  @description : Fetch workorders for id passed with Case info
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderAndCaseInfo(set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderAndCaseInfo', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Case__r.RecordType.Name,
        SVMXC__Case__r.Sub_Type__c,
        SVMXC__Case__r.Category__c
        From SVMXC__Service_Order__c
        Where Id IN :setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /** 
     * DCP-28624
     * @author Digvijay Singh
     *  Description :-Fetch workorders for Associated PM Plans
     */
    public List<SVMXC__Service_Order__c> selectAssociatedWorkOrderForPMPlans(set<Id> setPMPlanIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedWorkOrderForPMPlans', UtilsCollection.serializeIds(setPMPlanIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__PM_Plan__c
        From SVMXC__Service_Order__c
        Where SVMXC__PM_Plan__c IN :setPMPlanIds];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author :Nitin Sood
     * @date   :10-03-2019
     * @description :Query to Fetch Work orders with related to parts Orders.
     * @param :setWorkOrderIds - Id of Work Orders to query; loggedInUserId - Id of current logged in User, erpSubmittedValue - the value for erp submitted filter.
     */
    public List<SVMXC__Service_Order__c> workOrderWithPartsOrder(set<Id> setWorkOrderIds, Id loggedInUserId, String erpSubmittedValue )
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.workOrderWithPartsOrder', UtilsCollection.serializeIds(setWorkOrderIds) + '|' + loggedInUserId + '|' + erpSubmittedValue);

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        (Select Id, ERP_Submitted__c, Requested_By__c, SVMXC__Service_Order__c From SVMXC__RMA_Shipment_Order__r
        Where ERP_Submitted__c = :erpSubmittedValue AND Requested_By__c = :loggedInUserId AND SVMXC__Order_Type__c =:STRING_RETURN)
        From SVMXC__Service_Order__c
        Where Id IN :setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author      : Prashanth 
     *  @description : Fetch work orders for PM plans, DCP-28201
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderForPMPlans(set<Id> setPMPlanIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderForPMPlans', UtilsCollection.serializeIds(setPMPlanIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__PM_Plan__c
        From SVMXC__Service_Order__c
        Where SVMXC__PM_Plan__c IN :setPMPlanIds and (CreatedDate = LAST_N_DAYS:364 OR CreatedDate= NEXT_N_DAYS:1)];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author      : Soumya
     *  @description : Fetch workorders for id passed
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersServiceReportGenerationStatus(set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersServiceReportGenerationStatus', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMX_PS_Contact_Email__c,
        Is_Service_Report_Generated__c
        From SVMXC__Service_Order__c
        Where ID IN :setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author      : prashanth
     *  @description : Fetch workorders for set of instealled product id passed
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersForIP(set<Id> setInstalledProductIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersForIP', UtilsCollection.serializeIds(setInstalledProductIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Applied_Service_Contract__c,
        SVMXC__Site__c
        From SVMXC__Service_Order__c
        Where SVMXC__Component__c IN :setInstalledProductIds AND SVMXC__Order_Type__c = :STRING_INSTALLATION AND Applied_Service_Contract__c = null AND SVMXC__Order_Status__c NOT IN ('Closed','Completed','Reopen Requested','Closed-Duplicate')];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    

    /**
     *  @author      : Raja Siva Krishna
     *  @description : DCP-43185-Fetch workorders for id passed with recordType info
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderWithRecordType(set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderWithRecordType', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        RecordType.Name
        From SVMXC__Service_Order__c
        Where ID IN :setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author      : Raja Siva Krishna
     *  @description : DCP-43185-Fetch workorder with latest completion date
     *  @return      : Work Order
     */
    public SVMXC__Service_Order__c selectWorkOrdertoKnowCompletionDate(Id workOrderId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdertoKnowCompletionDate', String.valueOf(workOrderId));

        SVMXC__Service_Order__c res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Acceptance_Status__c,
        LOA_Signed_and_Attached__c,
        SVMXC__Order_Type__c,
        Acceptance_Forecast_in_Current_Quarter__c,
        Latest_Completion_Date_Time__c
        From SVMXC__Service_Order__c 
        Where Id = :workOrderId];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res == null ? 0 : 1);

        return res;
    }

    /**
     *  @author Siddartha Reddy Kalam 
     *  @description  
     *  @return List of open Work Orders related to Account to field support
     */
    public List<SVMXC__Service_Order__c> getAccountToFieldSupportWorkOrders(String recordID)
    {

        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getAccountToFieldSupportWorkOrders', recordID);

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Order_Type__c,
        SVMXC__Group_Member__r.Name,
        RecordType.Name,
        SVMXC__Company__r.Name,
        Owner.Name
        From SVMXC__Service_Order__c
        Where SVMXC__Order_Status__c NOT IN ('Closed','Completed','Canceled','Closed-Duplicate') AND (SVMXC__Group_Member__c IN (SELECT User__c FROM Account_to_Field_Support__c WHERE Id=:recordID))];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }  

    /**
     *  @author Siddartha Reddy Kalam 
     *  @description  
     *  @return List of open Work Orders related to field support
     */
    public List<SVMXC__Service_Order__c> getFieldSupportWorkOrders(String recordID)
    {
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getFieldSupportWorkOrders', recordID);

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Order_Type__c,
        SVMXC__Group_Member__r.Name,
        RecordType.Name,
        SVMXC__Company__r.Name,
        Owner.Name
        From SVMXC__Service_Order__c
        Where SVMXC__Order_Status__c NOT IN ('Closed','Completed','Canceled','Closed-Duplicate') AND SVMXC__Group_Member__c = :recordID];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

     /**
     *  @author      : Adyasha Satapathy
     *  @description : DCP-38809-Fetch workorders and their associated work details 
     *  @return      : List<Work Order>
     **/
    public List<SVMXC__Service_Order__c> selectWorkOrderWithWorkDetails(Set<Id> setWorkOrderIds) 
    {
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderWithWorkDetails', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [
        Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Distributor_Account__c,
        SVMXC__Contact__c,
        Opportunity__c,
        Sold_To_Account__c,
        Initiate_Quoting__c,
        Owner.Email,
        Owner.type,
        (Select SVMXC__Product__r.Material_Number__c, 
        SVMXC__Estimated_Quantity2__c, 
        SVMXC__Service_Order__r.Product_Lot_Number__c, 
        SVMXC__Service_Order__r.Installed_Product_Serial_Number__c,
        SVMXC__Start_Date_and_Time__c,
        SVMXC__End_Date_and_Time__c
        From SVMXC__Service_Order_Line__r
        Where SVMXC__Product__c != NULL
        )
        From SVMXC__Service_Order__c
        Where Id IN :setWorkOrderIds
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /*
     *  @author KD
     *  @description Fetch the work orders with Name
     *  @param String Name
     *  @return Work Orders
     */
    public List<SVMXC__Service_Order__c> selectWOByName(String strWOName) 
    {
        ilib_LogQuery logger=null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectWOByName',
            strWOName
        );

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Billing_Type_Set_Manually__c,
        SVMXC__Billing_Type__c,
        RecordType.Name,
        SVMXC__Order_Type__c,
        Opportunity__c,
        Opportunity__r.Product_Interest__c,
        ZDST_WO_Unique_Identifier__c,
        ZDST_WO_Time_Stamp__c
        From SVMXC__Service_Order__c
        Where Name =:strWOName];

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
    }

    /**
     *  @author Gladis
     *  @description Fetch work orders which are associated with Opportunity Id's passed as parameter
     *  @return List of work orders
     **/
    public List<SVMXC__Service_Order__c> selectWorkOrdersFromOpportunities(Set<Id> opportunityIds) 
    {
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectWorkOrdersFromOpportunities',
            UtilsCollection.serializeIds(opportunityIds)
        );

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Opportunity__c,
        Opportunity__r.Owner.Email,
        SVMXC__Component__r.Name,
        Estimated_Quote_Amount__c,
        CurrencyIsoCode,
        Opportunity__r.name,
        Opportunity__r.AccountId,
        Opportunity__r.Account.Name
        From SVMXC__Service_Order__c
        Where Opportunity__c IN : opportunityIds];

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
    }
    /*
     *  @author Vaibhav
     *  @description Fetch the work orders with Same ERP Order Number And ERP Order Line Number
     *  @param Set < String > setERPOrderNumber,Set < String > setERPOrderLineNumber
     *  @return Work Orders
     */
    public List<SVMXC__Service_Order__c> selectWOWithSameERPOrderAndERPOrderLineNum(Set < String > setERPOrderNumber,Set < String > setERPOrderLineNumber) 
    {
        String installationOrderType = 'Installation';    
        ilib_LogQuery logger=null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectWOWithSameERPOrderAndERPOrderLineNum',
            UtilsCollection.serializeIds(setERPOrderNumber) + '|' + UtilsCollection.serializeIds(setERPOrderLineNumber)
        );

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Acceptance_Status__c,
        LOA_Signed_and_Attached__c,
        ERP_Order_Number__c,
        SVMXC__Order_Type__c,
        Acceptance_Forecast_in_Current_Quarter__c
        From SVMXC__Service_Order__c
        Where ERP_Order_Line_Number__c IN :setERPOrderLineNumber AND ERP_Order_Number__c IN :setERPOrderNumber AND SVMXC__Order_Type__c = :installationOrderType];
        
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
    }
    /**
     * @author :Gladis
     * @date   :01-09-2021
     * @description :Query to Fetch Work orders with related to Parts Orders with type Shipment.
     * @param :setWorkOrderIds - Id of Work Orders
     */
    public List<SVMXC__Service_Order__c> workOrdersWithShipmentPartsOrder(set<Id> setWorkOrderIds) {
        String partsOrderType = 'Shipment';
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.workOrdersWithShipmentPartsOrder', UtilsCollection.serializeIds(setWorkOrderIds));
        }

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        (Select Id, SVMXC__Order_Type__c From SVMXC__RMA_Shipment_Order__r Where SVMXC__Order_Type__c = :partsOrderType)
        From SVMXC__Service_Order__c
        Where Id IN :setWorkOrderIds];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /**
     *  @author : Rucha Dalvi
     *  @description : DCP - 46273 Fetch work orders with related work orders passed
     *  @return : List of Work Orders
     **/
    public List<SVMXC__Service_Order__c> selectWorkOrderWithRelatedWorkOrder(Set<Id> setWorkOrderId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderWithRelatedWorkOrder', UtilsCollection.serializeIds(setWorkOrderId));
        }

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Confirmed_Operability__c,
        SVMXC__Order_Type__c,
        Related_WO_to_Confirm_Operability__c,
        Related_WO_to_Confirm_Operability__r.Confirmed_Operability__c
        From SVMXC__Service_Order__c
        Where Related_WO_to_Confirm_Operability__c IN :setWorkOrderId];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        system.debug('46273 Result : '+res);
        return res;
    
    }

    /*******************************************************************************************************
    * @description DCP-47698 Query to fetch Work Orders of specific Order Type and Order Line Items
    * @param setERPLineNumbers ERP Line Numbers for OLIs
    * @param orderType Order Type of Work Order
    * @return List of Work Orders
    * @example
    */
    public List<SVMXC__Service_Order__c> selectWorkOrderSpecificOrderTypeOLI(Set<String> setERPLineNumbers, String orderType) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderSpecificOrderTypeOLI', UtilsCollection.serializeIds(setERPLineNumbers));
        }
        Set<String> orderStatusToExclude = new Set<String>{'Completed', 'Closed', 'Canceled'}; //INC0358206
            
        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Acceptance_Code__c
        From SVMXC__Service_Order__c
        Where ERP_Order_Line_Number__c IN :setERPLineNumbers AND SVMXC__Order_Type__c =:orderType AND SVMXC__Order_Status__c NOT IN :orderStatusToExclude];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
	
	
	/**
     *  @author      : Raviteja Vakkalagadda 
     *  @description : Fetch workorders for id passed
     *  @return      : List<Work Order>
     */
    public List<SVMXC__Service_Order__c> selectWorkOrderLstFromIds(Id recordId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderLstFromIds', recordId);
			}
			
        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where ID = : recordId OR SVMXC__Case__c =:recordId];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
		}

        return res;
    }
	
	 /**
     *  @author      : Raviteja Vakkalagadda 
     *  @description : Fetch WorkOrder List based on WO Id or Case ID
     *  @return      : List<Work Order>
     */

    public List<SVMXC__Service_Order__c> selectWorkOrderByIDAndStatus(Set<Id> setprdWOIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderByIDAndStatus', UtilsCollection.serializeIds(setprdWOIds));
        }
        Set<String> setStatus = new Set<String>{'Completed', 'Closed'}; 

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where Id IN :setprdWOIds AND SVMXC__Order_Status__c IN : setStatus];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
	
 /**
    * @description DCP: 51725:  Query work orders under case account
    * @author Shahnawaz | 06-07-2022 
    * @param setAccountIds 
    * @return List<SVMXC__Service_Order__c> 
    **/
    public List<SVMXC__Service_Order__c> selectElevatedWorkOrdersOnAccount(Set<Id> setAccountIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectElevatedWorkOrdersOnAccount', UtilsCollection.serializeIds(setAccountIds));
        }
        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        CreatedDate
        From SVMXC__Service_Order__c
        Where SVMXC__Company__c IN : setAccountIds AND ((Technical_Elevation__c!=null AND Technical_Elevation__r.Elevation_Status__c = 'Open') OR (Account_Elevation__c!=null AND Account_Elevation__r.Elevation_Status__c = 'Open'))];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
           logger.stop(res.size()); 
        }
        return res;
    }

     /**
    * @description DCP: 52634:  Query work orders with subscription details
    * @author Rohan | 19-12-2022 
    * @param setWorkOrderIds 
    * @return List<SVMXC__Service_Order__c> 
    **/
    public List<SVMXC__Service_Order__c> selectWorkOrderWithSubscription(set<Id> setWorkOrderIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderWithSubscription', UtilsCollection.serializeIds(setWorkOrderIds));
        }

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        CreatedDate,
        Subscription__c,
        Subscription__r.Status__c
        From SVMXC__Service_Order__c
        Where Id IN : setWorkOrderIds];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
           logger.stop(res.size()); 
        }
        return res;
    }

    /**
    * @description DCP: 56388:  Query work orders
    * @author Rohan | 20-12-2022
    * @param setAccountIds 
    * @return List<SVMXC__Service_Order__c> 
    **/
    public List<SVMXC__Service_Order__c> selectElevatedWorkOrders(Set<Id> setCaseIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectElevatedWorkOrders', UtilsCollection.serializeIds(setCaseIds));
        }
        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        Technical_Elevation__r.Elevation_Status__c,
        Account_Elevation__r.Elevation_Status__c
        From SVMXC__Service_Order__c
        Where SVMXC__Case__c IN : setCaseIds AND (Technical_Elevation__c!=null OR Account_Elevation__c!=null)];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
           logger.stop(res.size()); 
        }
        return res;
    }
    /**
     *  @author Priya
     *  @description Fetch the WO by ids when Account and Contact in not null
     *  @param String setWorkOrderIds
     *  @return WO
     */
    public List<SVMXC__Service_Order__c> selectWorkOrdersWithNonNullContact(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrdersWithNonNullContact', UtilsCollection.serializeIds(setWorkOrderIds));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Contact__c
        From SVMXC__Service_Order__c
        Where Id IN :setWorkOrderIds AND SVMXC__Contact__c != null AND SVMXC__Company__c != null];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
    *  @author Sudarshan Kataria CMCM-105
    *  @description Fetch work orders on case  
    *  @return List of Work Ordera
    **/
    public List<SVMXC__Service_Order__c> getWorkOrdersOnCase(string sWOId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getWorkOrdersOnCase', sWOId);

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where Id=:sWOId];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
     /**
    *  @author Siddartha Reddy Kalam
    *  @description Fetch account on work order  
    *  @return AccountId
    **/
    public List<SVMXC__Service_Order__c> getAccountonWorkOrder(string recordId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getWorkOrdersOnCase', recordId);
        }
        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c
        From SVMXC__Service_Order__c
        Where Id=:recordId];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }    

    /**
    *  @author Sudarshan Kataria CMCM-1354
    *  @description Fetch work orders for return scrap   
    *  @return List of Work Orders
    **/
    public List<SVMXC__Service_Order__c> selectEOLWorkOrders(Set<Id> installProductIdSet) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectEOLWorkOrders', UtilsCollection.serializeIds(installProductIdSet));

        List<SVMXC__Service_Order__c> res = [Select Id,
        Name,
        SVMXC__Order_Status__c,
        SVMXC__Case__c,
        OwnerId,
        SVMXC__Company__c,
        SVMXC__Component__c,
        SVMXC__Customer_Down__c,
        PO_Number__c,
        SVMXC__Group_Member__c,
        ERP_Order_Line_Number__c,
        Original_Owner__c,
        SVMXC__Is_PM_Work_Order__c,
        SVMX_PS_Subject__c,
        Case_Description__c,
        Case_Next_Steps__c,
        Case_Follow_up_Needed__c,
        Case_Subject__c,            
        cost_center__c,
        SVMXC__Service_Contract__c,
        Account_Region__c, 
        Installed_Product_Serial_Number__c,
        Product_Serial_Number__c,
        Product_Lot_Number__c,
        Abandoned_Reason__c,
        Has_Verification_Code__c,
        SVMXC__Order_Type__c
        From SVMXC__Service_Order__c
        Where SVMXC__Component__c IN :installProductIdSet AND SVMXC__Order_Type__c = :STRING_RETURN_SCRAP_DECOMMISSION
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
      * CMCM-9610
     *  @author Kumar Gaurav
     *  @param Set<String> WorkorderId
     *  @return List <SVMXC__Service_Order__c >
     */
    public list<SVMXC__Service_order__c> getWorkOrderId(set<Id> workOrderIdSet){
        List<SVMXC__Service_Order__c> res = [Select id,
        SVMXC__Component__c,
        SVMXC__Product__c,
        SVMXC__Contact__r.Phone,
        SVMXC__Contact__c,
        SVMXC__Customer_Down__c,
        SVMXC__Order_Status__c //4207
        from SVMXC__Service_Order__c  
        where id IN:workOrderIdSet];

        return res;
    }
    /** 
    *  @author  Nitin Zagade CMCM-9391
    *  @description Fetch work orders  that has pol with given parameter   
    *  @return List of Work Orders
    **/
    public  List<SVMXC__Service_Order__c> selectWOWithGivenStatusAndReturnType(String returnType,String status,Set<Id> workOrderSet) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
        logger = new ilib_LogQuery(LOG_TITLE + '.selectEOLWorkOrders',''+workOrderSet);

        List<SVMXC__Service_Order__c> res = [select id,
        SVMXC__Case__c,
        (select id  from SVMXC__RMA_Shipment_Order__r where  (NOT (SVMXC__Order_Status__c=:status)) and SVMXC__Order_Type__c=:returnType ) 
        from SVMXC__Service_Order__c 
        where id in :workOrderSet 
        ];


        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;

    }
    

}