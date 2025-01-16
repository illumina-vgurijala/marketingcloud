/**
* @author Shivani Jain
* @date 30th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to PM Work Orders 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                 DESCRIPTION 
* Pooja Shalwadi       22-Feb-2023              DCP-53985: Modified to populate "Scheduled date time" field on WO for multi year contract
* --------------------------------------------------------------------------------------------------------------------------------------
*/  
public with sharing class PreventativeMaintenance_WOHelper {
    private static final String LOG_TITLE = 'PreventativeMaintenance_WOHelper';

    /*
    *  @AUTHOR:  Digvijay
    *  @DESCRIPTION: Refactored. PM work Order processing
    *  @PARAM :  set<Id> setAccountId, List<SVMXC__Service_Order__c> lstWo
    */
    public static void processPMWorkOrders(List<Sobject> records, List<SVMXC__PM_Schedule__c> lstPMSchedule, List<SVMXC__PM_Schedule_Definition__c> listPMSchDef) {
        
        List<SVMXC__Service_Order__c> lstPMWorkOrders = new List<SVMXC__Service_Order__c>(); //DCP-28624
        Map<Id, Account> mapWorkOrderToAccounts = new  Map<Id,Account>();
        Map<Id, SVMXC__Installed_Product__c> idToInstalledProduct = new  Map<Id, SVMXC__Installed_Product__c>();
        Map<Id, SVMXC__PM_Plan__c> mapPMPlan = new Map<Id,SVMXC__PM_Plan__c>();

        mapPMPlan = popualateMapPMPlan();
        idToInstalledProduct = popualateIdToInstalledProduct();
        

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //START DCP-47686
            if(objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM && objWorkOrder.SVMXC__PM_Plan__c != NULL 
                && mapPMPlan.containsKey(objWorkOrder.SVMXC__PM_Plan__c)) {
                objWorkOrder.Qualification_Requirements__c = String.isBlank(objWorkOrder.Qualification_Requirements__c) ? 
                    WorkOrders.STRING_OQ_REQUIRED : objWorkOrder.Qualification_Requirements__c + WorkOrders.SEMICOLON + WorkOrders.STRING_OQ_REQUIRED;
            }
            //END DCP-47686
            //DCP-28624 
            if(objWorkOrder.SVMXC__Company__c!=null && objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM ) {
                lstPMWorkOrders.add(objWorkOrder);
            }
            
            if(mapPMPlan.Containskey(objWorkOrder.SVMXC__PM_Plan__c)) {
                objWorkOrder.SVMX_PS_Subject__c=objWorkOrder.SVMX_PS_Subject__c+':'+'& OQ' ;
            }
        }

        if(!lstPMWorkOrders.IsEmpty()) {
            mapWorkOrderToAccounts = fetchWorkOrderAccountDetails(lstPMWorkOrders);
        }
       
        populateWOFields(records, mapWorkOrderToAccounts, idToInstalledProduct, mapPMPlan);

        if(!WorkOrders.lstpmplans.IsEmpty()) {
            populateAnnualWOData((List < SVMXC__Service_Order__c > ) records, lstPMSchedule, listPMSchDef);
        }
    }

    /*
    *  @DESCRIPTION: 
    */
    private static void populateWOFields(List<Sobject> records,  Map<Id, Account> mapWorkOrderToAccounts,  Map<Id, SVMXC__Installed_Product__c> idToInstalledProduct, 
                                                                                Map<Id, SVMXC__PM_Plan__c> mapPMPlan) {
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //DCP-28624 
            if(objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM && objWorkOrder.Is_Auto_Created__c) {
                if(mapWorkOrderToAccounts!=null && mapWorkOrderToAccounts.containsKey(objWorkOrder.SVMXC__Company__c)){
                    objWorkOrder.SVMX_PS_Subject__c=mapWorkOrderToAccounts.get(objWorkOrder.SVMXC__Company__c).Name;   
                }
                    
                if(idToInstalledProduct!=null && idToInstalledProduct.ContainsKey(objWorkOrder.SVMXC__Component__c)){
                    
                    objWorkOrder.SVMX_PS_Subject__c=objWorkOrder.SVMX_PS_Subject__c +':'+ idToInstalledProduct.get(objWorkOrder.SVMXC__Component__c).SVMXC__Serial_Lot_Number__c;
                }
                    
                objWorkOrder.SVMX_PS_Subject__c=objWorkOrder.SVMX_PS_Subject__c+':'+WorkOrders.STRING_WO_ORDER_TYPE_PM ;
                    
                if(mapPMPlan!=null && mapPMPlan.Containskey(objWorkOrder.SVMXC__PM_Plan__c)){
                    objWorkOrder.SVMX_PS_Subject__c=objWorkOrder.SVMX_PS_Subject__c+':'+'& OQ' ;
                }
            } 
        }
    }

    /*
    *  @DESCRIPTION: 
    */
    private static Map<Id, SVMXC__PM_Plan__c> popualateMapPMPlan() {
        Map<Id, SVMXC__PM_Plan__c> mapPMPlan = new Map<Id,SVMXC__PM_Plan__c>();

        for(SVMXC__PM_Plan__c objPMPlan:WorkOrders.lstpmplans) {
            if(objPMPlan.SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.OQ_Required__c) {
                mapPMPlan.put(objPMPlan.id,objPMPlan);
            }
        }
        return mapPMPlan;
    }

    /*
    *  @DESCRIPTION: 
    */
    private static Map<Id, SVMXC__Installed_Product__c> popualateIdToInstalledProduct() {
        Map<Id, SVMXC__Installed_Product__c> idToInstalledProduct = new Map<Id, SVMXC__Installed_Product__c>();

        for(SVMXC__Installed_Product__c objIP: WorkOrders.lstInstalledProductrecords) {
            idToInstalledProduct.put(objIP.Id, objIP);
        }
        return idToInstalledProduct;
    }

    /**
     * method Name: populateAnnualWOData
     * Description: This method is to Populate onsite response due date and scheduled date for a PM work order
     * DCP-28201
     * */
    private static void populateAnnualWOData(List<SVMXC__Service_Order__c> lstWorkOrders, List<SVMXC__PM_Schedule__c> lstPMSchedule,
        List<SVMXC__PM_Schedule_Definition__c> listPMSchDef) {
        //set to store 2 Entitled Pms
        Set < Id > setBiAnnualPMPlanIds = new Set < Id > ();
        //Map of PM Plan vs scheduled definition
        Map < Id, SVMXC__PM_Schedule_Definition__c > mapPMPlanWithSchDefs = new Map < Id, SVMXC__PM_Schedule_Definition__c > ();
        Map<Id,SVMXC__PM_Schedule__c> mapPMPlanWithPMSchedule = new Map<Id,SVMXC__PM_Schedule__c>();
        //list of scheduled definitions
        for (SVMXC__PM_Schedule_Definition__c schDefs: listPMSchDef) {
            //check if frequency is 6 months and add it to 2 Entilements Set
            if ((schDefs.SVMXC__Frequency__c == 6 && schDefs.SVMXC__Frequency_Unit__c == 'Months') || (schDefs.SVMXC__Frequency__c == 26 && schDefs.SVMXC__Frequency_Unit__c == 'Weeks')) {
                setBiAnnualPMPlanIds.add(schDefs.SVMXC__PM_Plan__c);
            }
            //populate map to get startdate and end date from service contract to update onsite response due date and scheduled date
            mapPMPlanWithSchDefs.put(schDefs.SVMXC__PM_Plan__c, schDefs);
        }
        for(SVMXC__PM_Schedule__c sch : lstPMSchedule) {
            //populate map to get startdate and end date from pm schedule to update onsite response due date and scheduled date
            mapPMPlanWithPMSchedule.put(sch.SVMXC__PM_Plan__c, sch);
        }
        //logic to update onsite response due date and scheduled date
        for (SVMXC__Service_Order__c wo: lstWorkOrders) {
            if (wo.SVMXC__PM_Plan__c != null && !mapPMPlanWithSchDefs.isEmpty() && mapPMPlanWithSchDefs.containsKey(wo.SVMXC__PM_Plan__c) &&
                    wo.Is_Auto_Created__c && wo.SVMXC__Is_PM_Work_Order__c) {
                    calculateScheduleDateTime(wo,mapPMPlanWithSchDefs);  //DCP-47459
                
                if(mapPMPlanWithPMSchedule != null && mapPMPlanWithPMSchedule.containsKey(wo.SVMXC__PM_Plan__c) && mapPMPlanWithPMSchedule.get(wo.SVMXC__PM_Plan__c) != null){ 
                    //checking for Annual PM Work Order
                    if (!setBiAnnualPMPlanIds.contains(wo.SVMXC__PM_Plan__c)) {                                                        
                        //get period start date from PM schedule
                        Date lastRunOnDate = mapPMPlanWithPMSchedule.get(wo.SVMXC__PM_Plan__c).SVMXC__Last_Run_Date__c;
                        System.debug('period_startdate_Annual-->'+lastRunOnDate);
                        Date updatedOnsiteRespDate = lastRunOnDate.addDays(364);
                        System.debug('updatedOnsiteRespDate_Annual-->'+updatedOnsiteRespDate);
                        //to populate onsite response due date at 11:59 PM.
                        //Time targetTime = Time.newInstance(23, 59, 0, 0);
                        // wo.SVMXC__Scheduled_Date_Time__c = lastRunOnDate.addDays(182); DCP-47459
                        //wo.Onsite_Response_Due_Date__c = Datetime.newInstanceGmt(updatedOnsiteRespDate, targetTime);
                        wo.Onsite_Response_Due_Date__c = updatedOnsiteRespDate;
                        System.debug('wo.Onsite_Response_Due_Date__c_annual-->'+wo.Onsite_Response_Due_Date__c);
                        if(updatedOnsiteRespDate < System.today()){
                            wo.SVMXC__Order_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED; 
                        }
                    } 
                    //BiAnnual PM Work Order
                    else if (!setBiAnnualPMPlanIds.isEmpty() && setBiAnnualPMPlanIds.contains(wo.SVMXC__PM_Plan__c)) {
                        //get perios start date from PM schedule
                        Date lastRunOnDate = mapPMPlanWithPMSchedule.get(wo.SVMXC__PM_Plan__c).SVMXC__Last_Run_Date__c;
                        system.debug('period_Startdate_BI_Annual-->'+lastRunOnDate);
                        wo.SVMXC__Scheduled_Date_Time__c = lastRunOnDate.addDays(91);
                        Date updatedOnsiteRespDate = lastRunOnDate.addDays(182);
                        system.debug('updatedOnsiteRespDate_Bi_Annual-->'+updatedOnsiteRespDate);
                        //to populate onsite response due date at 11:59 PM.
                        //Time targetTime = Time.newInstance(23, 59, 0, 0);
                        //wo.Onsite_Response_Due_Date__c = Datetime.newInstanceGmt(updatedOnsiteRespDate, targetTime);
                        wo.Onsite_Response_Due_Date__c = updatedOnsiteRespDate;
                        system.debug('wo.Onsite_Response_Due_Date__c_Bi_Annual-->'+wo.Onsite_Response_Due_Date__c);
                        if(updatedOnsiteRespDate < System.today()) {
                            wo.SVMXC__Order_Status__c =WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED; 
                        }                                                                   
                    }
                } else{
                    system.debug('No PM Schedule available on PM Plan: '+wo.SVMXC__PM_Plan__c);
                }               
                
            }
        }
    }

    /*DCP-47459 
     * METHOD NAME    : calculateScheduleDateTime
     * DESCRIPTION    : calculate Schedule Date Time based on Last PM Date from Installed Product and Start Date and End date from Service Contract
     * RETURN TYPE    : void
     * PARAMETER      : SVMXC__Service_Order__c  wo, Map< Id,SVMXC__Installed_Product__c > mapInstalledProduct, Map < Id, SVMXC__PM_Schedule_Definition__c > mapPMPlanWithSchDefs
    */
    public static void calculateScheduleDateTime(SVMXC__Service_Order__c  wo, Map < Id, SVMXC__PM_Schedule_Definition__c > mapPMPlanWithSchDefs) {
        ilib_LogEvent.push(LOG_TITLE + '.calculateScheduleDateTime()');

        Integer numberDaysDue = 0;
        Integer lastPMStartDateDiff = 0;
        WorkOrders.startDate=null;
        WorkOrders.endDate=null;
        WorkOrders.lastPMDate=null;
        Integer virtualNoOfYears=0;//DCP-53985
        Map< Id,SVMXC__Installed_Product__c > mapInstalledProduct = new map <Id,SVMXC__Installed_Product__c>(WorkOrders.lstInstalledProductrecords);
        if (!mapPMPlanWithSchDefs.isEmpty() && mapPMPlanWithSchDefs.containsKey(wo.SVMXC__PM_Plan__c) && mapPMPlanWithSchDefs.get(wo.SVMXC__PM_Plan__c).SVMXC__PM_Plan__r != null && mapPMPlanWithSchDefs.get(wo.SVMXC__PM_Plan__c).SVMXC__PM_Plan__r.SVMXC__Service_Contract__r != null) 
        {
            //service contract's start date getting from map defined above
            WorkOrders.startDate = mapPMPlanWithSchDefs.get(wo.SVMXC__PM_Plan__c).SVMXC__PM_Plan__r.SVMXC__Service_Contract__r.SVMXC__Start_Date__c;
            //service contract's end date getting from map defined above
            WorkOrders.endDate =  mapPMPlanWithSchDefs.get(wo.SVMXC__PM_Plan__c).SVMXC__PM_Plan__r.SVMXC__Service_Contract__r.SVMXC__End_Date__c;
             //DCP-53985 : Start
             numberDaysDue = WorkOrders.startDate.daysBetween(WorkOrders.endDate);  //end date- start date
            
             ilib_LogEvent.info('WorkOrders.startDate:'+WorkOrders.startDate);
             ilib_LogEvent.info('WorkOrders.endDate:'+WorkOrders.endDate);
             if(WorkOrders.startDate != null && numberDaysDue > WorkOrders.INTEGER_ONE_LEAP_YEAR)
             {
                 virtualNoOfYears = (WorkOrders.startDate.daysBetween(Date.Today())+1)/360;// Considering 360 as there could be buffer time in WO creation
                 ilib_LogEvent.info('MultiYear virtualNoOfYears'+virtualNoOfYears);
                 WorkOrders.startDate = WorkOrders.startDate.addYears(virtualNoOfYears); // Add no.of years
                 
             }          
             //DCP-53985 : end
            if(!mapInstalledProduct.isEmpty() && mapInstalledProduct.containsKey(wo.SVMXC__Component__c)){
                WorkOrders.lastPMDate= mapInstalledProduct.get(wo.SVMXC__Component__c).Last_PM_Date__c;
                }
            if(WorkOrders.lastPMDate!=null){
               lastPMStartDateDiff = WorkOrders.lastPMDate.daysBetween(WorkOrders.startDate);
               ilib_LogEvent.info('WorkOrders.lastPMDate:'+WorkOrders.lastPMDate);
               ilib_LogEvent.info('WorkOrders. lastPMStartDateDiff:'+lastPMStartDateDiff);
            }
            
            if(numberDaysDue > WorkOrders.INTEGER_ONE_LEAP_YEAR) {
                calculateVirtualDateForMultiYearContract(lastPMStartDateDiff);
                ilib_LogEvent.info('MultiYear WorkOrders.startDate:'+WorkOrders.startDate);
                ilib_LogEvent.info('MultiYear WorkOrders.endDate:'+WorkOrders.endDate);
            }

            updateWOScheduledDateTime(lastPMStartDateDiff,wo);//Codescan fix : DCP-53985
        }
        ilib_LogEvent.pop();
    }

    /**
    * @description : To update Scheduled Date time filed/ resolve codescan issue of DCP-53985
    * @param lastPMStartDateDiff 
    * @param wo 
    **/
    private static void updateWOScheduledDateTime(Integer lastPMStartDateDiff,SVMXC__Service_Order__c  wo){
        Date scheduleDate;
        Time scheduleTime = Time.newInstance(8, 0, 0, 0);
        if(lastPMStartDateDiff > WorkOrders.INTEGER_ONE_MONTH && lastPMStartDateDiff < WorkOrders.INTEGER_ONE_YEAR){
            if(WorkOrders.lastPMDate < Date.today()){
            scheduleDate = Date.newInstance(WorkOrders.lastPMDate.year()+1, WorkOrders.lastPMDate.month(),1);
            }
            else{
            scheduleDate = Date.newInstance(WorkOrders.lastPMDate.year(), WorkOrders.lastPMDate.month(),1);  
            }
            if(scheduleDate < WorkOrders.startDate){ 
               scheduleDate = WorkOrders.startDate;
            }

            wo.SVMXC__Scheduled_Date_Time__c = Datetime.newInstanceGmt(scheduleDate, scheduleTime);
        }
        else if(lastPMStartDateDiff >= WorkOrders.INTEGER_ONE_YEAR || WorkOrders.lastPMDate == null){
           if(WorkOrders.startDate < Date.today()){
               scheduleDate = Date.today();
            }
           else{
               scheduleDate = WorkOrders.startDate;
            }
            wo.SVMXC__Scheduled_Date_Time__c = Datetime.newInstanceGmt(scheduleDate, scheduleTime);
        }
        else if(lastPMStartDateDiff <= WorkOrders.INTEGER_ONE_MONTH){
            scheduleDate = WorkOrders.endDate.addDays(-30);
            wo.SVMXC__Scheduled_Date_Time__c = Datetime.newInstanceGmt(scheduleDate, scheduleTime);
        } 
        ilib_LogEvent.info('WorkOrders.SVMXC__Scheduled_Date_Time__c:'+wo.SVMXC__Scheduled_Date_Time__c);
    }

      /*DCP-47459 
     * METHOD NAME    : calculateVirtualDateForMultiYearContract
     * DESCRIPTION    : calculate Date based on multiyear year contract
     * RETURN TYPE    : void
     * PARAMETER      : Integer lastPMStartDateDiff
    */
    public static void calculateVirtualDateForMultiYearContract(Integer lastPMStartDateDiff){
        if(lastPMStartDateDiff < WorkOrders.INTEGER_ONE_YEAR && lastPMStartDateDiff >WorkOrders.INTEGER_ONE_MONTH){
            if(WorkOrders.startDate.year()==WorkOrders.lastPMDate.year()){
                WorkOrders.lastPMDate=Date.newInstance(Date.Today().year(),WorkOrders.lastPMDate.month(), WorkOrders.lastPMDate.day());
            }
            else{
                WorkOrders.lastPMDate=Date.newInstance(Date.Today().year()-1, WorkOrders.lastPMDate.month(), WorkOrders.lastPMDate.day());
            }            
        }  
        else if(lastPMStartDateDiff <= WorkOrders.INTEGER_ONE_MONTH){
            //Pooja:Start DCP:53985
            Date virtualEndDate = WorkOrders.startdate.addDays(364);
            Date tempDate;
            if (virtualEndDate.day() != WorkOrders.endDate.day()){
                tempDate = Date.newInstance(virtualEndDate.year(), WorkOrders.enddate.month(), WorkOrders.enddate.day());
                WorkOrders.enddate =virtualEndDate <= WorkOrders.enddate ? tempDate: WorkOrders.enddate;
               
            } 
            else if(virtualEndDate.day() == WorkOrders.endDate.day())
            {
                WorkOrders.enddate = virtualEndDate;
            } 
            ilib_LogEvent.info('MultiYear WorkOrders virtualEndDate : '+virtualEndDate);
            ilib_LogEvent.info('WorkOrders. tempDate calculateVirtualDateForMultiYearContract: '+tempDate);
            //End DCP:53985
        }
    }

    /*
    *  @AUTHOR:  
    *  @DESCRIPTION: Refactored. 
    *  @PARAM : :ist WorkOrders
    */
    private static Map<Id,Account> fetchWorkOrderAccountDetails(List<SVMXC__Service_Order__c> lstWorkOrders) {
        Map<Id, Account> mapWorkOrderAccounts = new Map<Id, Account>();

        for(Account objAccount : WorkOrders.lstAccountRecords){
            for(SVMXC__Service_Order__c objWorkOrder : lstWorkOrders){
                if(objAccount.Id == objWorkOrder.SVMXC__Company__c){
                    mapWorkOrderAccounts.put(objWorkOrder.SVMXC__Company__c,objAccount);
                }
            }
        }
        return mapWorkOrderAccounts;
    }

    /*
     *  
     *  @AUTHOR Digvijay(code refactored)
     *  @DESCRIPTION - process PM logic after WO update 
     *  @PARAM :  Old Map of Work Orders.
     *  @RETURN : void
     */
    public static void pmWorkOrderUpdates(Map<Id, SObject> mapOld) {
        // creating set for storing the ids of PM work orders whose status is changed to completed #DCP-28837
        Set<Id> setPMCompletedWOIds = new Set<Id>();
        List<Admin_Operation__e> lstAdminOperation = new List<Admin_Operation__e>();

        for(Id idWorkOrder : mapOld.keySet()){
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            //adding work order ids in the set #DCP-28837
            if(objNewWorkorder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM 
                    && objOldWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                        && objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED) {
                setPMCompletedWOIds.add(objNewWorkorder.Id);
            }
        }

        //calling method for updating last PM date on installed products after checking for PM work detail #DCP-28837
        if(!setPMCompletedWOIds.isEmpty()) {
            String stringID = (string) (new list<id>(setPMCompletedWOIds)[0]);
            lstAdminOperation.add(new Admin_Operation__e(Name__c = 'PopulateLastPMDateOnIP', Related_Record__c = stringID ));
        }    
        if(!lstAdminOperation.isEmpty()){
            EventBus.publish(lstAdminOperation);  
        }
    }


}
