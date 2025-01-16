/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to update Work Details
*/ 
public class UpdateWDQueueable_WOHelper implements Queueable {

    List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();
    Set<Id> setworkorders = new Set<Id>();
    String methodName;
    private static final String STRING_METHOD_UPDATE_IS_BILLABLE_ON_WD = 'updateIsBillabeOnWorkDetails';
    private static final String STRING_METHOD_UPDATE_IS_BILLABLE_ON_WD_BY_CS = 'updateIsBillaleOnWdByCS';

    /*******************************************************************************************************
    * @description Constructor
    * @param lstWorkOrders List<SVMXC__Service_Order__c> 
    * @return
    */
    public UpdateWDQueueable_WOHelper(List<SVMXC__Service_Order__c> lstWorkOrders, String methodName) {
        this.lstWorkOrders = lstWorkOrders;
        this.methodName = methodName;
    }

    /*******************************************************************************************************
    * @description Constructor
    * @param setworkorders Set<Id>
    * @return
    */
    public UpdateWDQueueable_WOHelper(Set<Id> setworkorders, String methodName) {
        this.setworkorders = setworkorders;
        this.methodName = methodName;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            if(methodName == STRING_METHOD_UPDATE_IS_BILLABLE_ON_WD) {
                updateIsBillabeOnWorkDetails(setworkorders);
            }
            if(methodName == STRING_METHOD_UPDATE_IS_BILLABLE_ON_WD_BY_CS) {
                updateIsBillaleOnWdByCS(setworkorders);
            }      
        } catch(Exception ex) {
            ApexExceptions.emit('UpdateWDQueueable_WOHelper.'+ 'methodName', ex);
            throw ex;
        }

    }

    /**
    *  @AUTHOR:  Soumya
    *  @DESCRIPTION: To update the is billable flag on Work details when installed product is changed on Work Order
    *  @PARAM :  Set<Id> - Work Order ids
    *  return : void
    */
    public static void updateIsBillabeOnWorkDetails(Set<Id> setworkorders){
        //To fetch the work deatils of work orders
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
        List<SVMXC__Service_Order_Line__c> lstWorkDetailstoupdate = new List<SVMXC__Service_Order_Line__c>();
        Map<Id,Boolean> mapoldFlagValue=new Map<Id,Boolean>();
        for(SVMXC__Service_Order_Line__c objWorkDetail :new WorkDetailsSelector().selectWorkDetailsForWorkOrderId(setworkorders)){
            if(objWorkDetail.SVMXC__Line_Status__c!= WorkOrders.STRING_WORK_DETAIL_LINE_STATUS_CANCELED){
                lstWorkDetails.add(objWorkDetail);
                mapoldFlagValue.put(objWorkDetail.Id,objWorkDetail.SVMXC__Is_Billable__c);
            }
        }
        if(!lstWorkDetails.IsEmpty()) {

            List<Sobject> lstwd=BillableRules_WorkdetailsHelper.executeIsBillableRules(lstWorkDetails);
            for(SVMXC__Service_Order_Line__c wd:(List<SVMXC__Service_Order_Line__c>)lstwd){
                if(mapoldFlagValue.get(wd.Id)!=null && mapoldFlagValue.get(wd.Id)!=wd.SVMXC__Is_Billable__c) {
                    wd.Billable_AutoUpdated__c= !wd.SVMXC__Is_Billable__c ? true  :  wd.Billable_AutoUpdated__c;
                    lstWorkDetailstoupdate.add(wd);
                }
            }


            if(lstWorkDetailstoupdate!=null && !lstWorkDetailstoupdate.IsEmpty()){
                update lstWorkDetailstoupdate;
            }
        }
    }

    /*DCP-38965
    * method :updateIsBillaleOnWdByCS
    * params : set<Id> setWoId
    * description: update wd as billable, if the customer service updates the billable type as billable.
    * return: void
    */
    public static void updateIsBillaleOnWdByCS(set<Id> setWoId){
        List<SVMXC__Service_Order_Line__c> lstWd = new List<SVMXC__Service_Order_Line__c> ();
        for(SVMXC__Service_Order_Line__c objWd:new WorkDetailsSelector().selectWDLinkedWithBillableWO(setWoId)){
            if(!(objWd.SVMXC__Line_Type__c == WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWd.SVMXC__Line_Type__c==WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED)){
            objWd.SVMXC__Is_Billable__c=true;
            lstWd.add(objWd);
            }
        }

        if(!lstWd.isEmpty()){
            update lstWd;
        }
    }


}