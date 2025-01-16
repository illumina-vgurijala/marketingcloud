/**
 *    @author KD
 *    @date   31-May-2021
 *    @description   DCP-38933 : ZDSTWorkOrder Wrapper is used to deserialize the json 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * ------------------------------------------------------------------------------------
 * KD                        3-June-2021        DCP-38933 : Initial Version
 * Dhairya Shah       11-Oct-2024             CMCM-5165      

*/
public with sharing class ZDSTWorkOrderDataReceiverWrapper {
    /*
     * @Author: KD
     * @Description : While deserializing the Json all the values that belong to Work Order are mapped to the variables in the WorkOrders class 
   */
    public class WorkOrders{
        public String SVMXC_Order_Type;
        public String ERP_Order_Number;
        public String SVMXC_Site;
        public String SVMXC_Company;
        public String PO_Number;
        public String Opportunity;
        public String WorkOrderNumber;
        public String SVMXC_Component;
        public String ERP_Order_Line_Number;
        public String SVMXC_Product;
        public String Contact_Email ;
        public String TimeStamp;
        /*
         * @Author: KD
         * @Description : Once the values are mapped to the variables then getSobject is method is used for mapping the variables with the fields in the SVMXC__Service_Order__c object 
		*/
        public SVMXC__Service_Order__c getSObject(){
            SVMXC__Service_Order__c objWO = new SVMXC__Service_Order__c(Opportunity__c = this.Opportunity,
                                                                        ERP_Order_Number__c = this.ERP_Order_Number,
                                                                        SVMXC__Billing_Type__c = Label.WorkOrderBillingTypeBillable,
                                                                        SVMXC__Order_Status__c = Label.WorkOrderStatusAssigned,
                                                                        PO_Number__c = this.PO_Number
            );
            if(String.isBlank(this.Opportunity)){
                objWO.ERP_Order_Line_Number__c = this.ERP_Order_Line_Number;
            }
            objWO.Notes__c = 'Order ' + this.ERP_Order_Number + ' has been processed in SAP for Billable Service and is ready for onsite  coordination from FAS or FSE.'; // Added field by Dhairya for CMCM - 5165
            return objWO;
        }
    }
}