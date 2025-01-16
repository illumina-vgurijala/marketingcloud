/***************************************************************************************************************************************
* NAME         : WorkOrderWrapper
* DESCRIPTION  : [DCP-8444] Work Order Synchronization from ServiceMax to SAP (NEW).
*                - This wrapper class holds mapping fields related  to SAP columns and Work order object fields.
*                    
* @AUTHOR      : 
* @DATE        : 27-July-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Deepika                  17-May-2021         DCP-38815 -Added Abdonded Reason to JSON Mapping 
* Akshay Mohan             01-June-2021        DCP-46834: Add SVMX_ReleaseForBilling
* Vaibhav p                 24-June-2021        DCP-46059: Populated SVMX_ReleaseForBilling
* Rucha Dalvi              17-Mar-2023         INC0453598 - Send Contract Details Blank in case of Billable
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class WorkOrderWrapper {

    /* VARIABLES */
    public List < ServiceOrder > lstServiceOrders; // holds parent(work order) data.
	public static final string STRING_WORK_DETAIL_MATERIAL_LINE_TYPE = 'Material Consumed';
    public static final string STRING_DATE_FORMAT = 'M/d/yyyy';
    public static final string STRING_DATE_FORMATTED_WITH_TIME_ZONE = 'America/Los_Angeles';
    public static final string STRING_ACCEPTANCE_STATUS_COMPLETED = 'Completed';
    public static final string STRING_ORDER_TYPE_INSTALLATION = 'Installation';
    public static final string STRING_ACCEPTANCE_FORECAST = '100% Completed - LOA Signed';


    /*WRAPPER CLASS: Holds the field mapping related to Work Order object.*/
    public class ServiceOrder {

        /* WRAPPER VARIABLES */
        public String Name;
        public String WorkOrderId;
        public String Owner;
        public String SVMX_PS_External_ID;
        public String SVMXC_Order_Status;
        public String RecordType;
        public String SVMXC_Order_Type;
        public String SVMXC_Case;
        public String SVMXC_Company;
        public String SVMXC_Site;
        public String Material_Number;
        public String Lot_Serial_Number;
        public String SVMX_PS_Subject;
        public String SVMXC_Priority;
        public String SVMXC_Scheduled_Date_Time;
        public String SVMXC_Closed_On;
        public String ERP_Quote_No;
        public String PO_Number;
        public String Cost_Center;
        //public String ERP_Header_Contract_Number;
        //public String ERP_Contract_Line_Number;
        public String ERP_Order_Number;
        public String ERP_Order_Line_Number;
        public String ERP_Equipment_ID;
		public String Opportunity; //INC0255382
        public String SVMXC_Customer_Down;
        public List < ServiceOrderLine > lstServiceOrderLines;
        public List < ServiceContracts > lstServiceContracts;
        public String ZZBATCHTRIG;//DCP-37399 - Batch Trigger or Manual Trigger
        public String Abandoned_Reason;//DCP-38815
        public String SVMX_ReleaseForBilling='';//DCP-46834
        public String SVMXC_Billing_Type;//DCP-46834
        public String SVMXC_Service_Date; // CMCM-13

        /*CONSTRUCTOR: Without parameters.*/
        public ServiceOrder() {}

        /*CONSTRUCTOR: With (SVMXC__Service_Order__c) as a parameters.*/
        public ServiceOrder(SVMXC__Service_Order__c workOrder) {

            //mapping JSON fields with the object fields.    
            this.Name = workOrder.Name;
            this.WorkOrderId = workOrder.Id;
			this.Opportunity = String.isNotBlank(workOrder.Opportunity__c) ? workOrder.Opportunity__c : null;//INC0255382
            this.SVMXC_Site = workOrder.SVMXC__Site__r.SVMX_PS_External_ID__c;
            this.SVMXC_Company = workOrder.SVMXC__Company__r.ERP_Customer_Id__c;
            this.RecordType = String.valueOf(workOrder.RecordType.Name);
            this.SVMXC_Order_Type = workOrder.SVMXC__Order_Type__c;
            this.SVMX_PS_External_ID = workOrder.SVMX_PS_External_ID__c;
            this.SVMXC_Case = workOrder.SVMXC__Case__r.CaseNumber;
            this.ERP_Equipment_ID = workOrder.SVMXC__Component__r.ERP_Equipment_ID__c;
            this.SVMXC_Scheduled_Date_Time = (workOrder.SVMXC__Scheduled_Date_Time__c != null ? String.valueOf(workOrder.SVMXC__Scheduled_Date_Time__c.format(STRING_DATE_FORMAT,  STRING_DATE_FORMATTED_WITH_TIME_ZONE)) : '') ; //extracting just dates.
            this.SVMXC_Closed_On = (workOrder.SVMXC__Closed_On__c != null ? String.valueOf(workOrder.SVMXC__Closed_On__c.format(STRING_DATE_FORMAT,  STRING_DATE_FORMATTED_WITH_TIME_ZONE)) : '') ; //extracting just dates.
            this.SVMX_PS_Subject = workOrder.SVMX_PS_Subject__c;
            this.SVMXC_Priority = workOrder.SVMXC__Priority__c;
            this.Material_Number = workOrder.Material_Number__c;
            this.Lot_Serial_Number = workOrder.Installed_Product_Serial_Number__c;
            this.SVMXC_Order_Status = workOrder.SVMXC__Order_Status__c;
            this.PO_Number = workOrder.PO_Number__c;
            this.Cost_Center = String.valueOf(workOrder.Cost_Center__c);
            //this.ERP_Header_Contract_Number = workOrder.SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c;
            //this.ERP_Contract_Line_Number = workOrder.SVMXC__Service_Contract__r.ERP_Contract_Line_Number__c;
            this.ERP_Order_Number = workOrder.ERP_Order_Number__c;
            this.ERP_Order_Line_Number = workOrder.ERP_Order_Line_Number__c;
            //this.ERP_Quote_No = workOrder.ERP_Quote_No__c;
            this.SVMXC_Customer_Down = String.valueOf(workOrder.SVMXC__Customer_Down__c);
            //list to hold work detail records.
            lstServiceOrderLines = new List < ServiceOrderLine > ();
            lstServiceContracts = new List < ServiceContracts > ();
            this.ZZBATCHTRIG = WorkOrderDataSender.triggeredManuallyOrFromBatch == 'Batch' ? 'X' : '';//DCP-37399
            this.Abandoned_Reason = workOrder.Abandoned_Reason__c;//DCP-38815
            //DCP-46834: Start- Set value for SVMXC_Billing_Type
            this.SVMXC_Billing_Type=workOrder.SVMXC__Billing_Type__c;
            //DCP-46834: End- Set value for SVMXC_Billing_Type
            this.SVMXC_Service_Date = (workOrder.Final_Service_Date_Time__c != null ? String.valueOf(workOrder.Final_Service_Date_Time__c.format(STRING_DATE_FORMAT,  STRING_DATE_FORMATTED_WITH_TIME_ZONE)) : ''); //CMCM-13
        }
    }

    /*WRAPPER CLASS: Holds the field mapping related to Work Detail object.*/
    public class ServiceOrderLine {

        /* WRAPPER VARIABLES */
        public String SVMXC_Service_Order_Line;
        public String Name;
        public String SVMX_PS_External_ID;
        public String SVMXC_Line_type;
        public String SVMXC_Consumed_From_Location;
        public String ERP_Header_Contract_Number;
        public String ERP_Contract_Line_Number;
        public String SVMXC_Is_Billable;
        public String SVMXC_Non_Billable_Reason;
        public String SVMXC_Actual_Quantity;
        public String SVMXC_Start_Date;
        public String SVMXC_Start_Time;
        public String SVMXC_End_Date;
        public String SVMXC_End_Time;
        public String SVMXC_Activity_Type;
        public String SVMXC_Group_Member;
        public String SVMXC_Batch_Number;
        //public String Duration_in_hours;
        public String SVMX_PS_VS_Consumed_Product_Stock;
        public String SVMX_PS_VS_Consumed_Stocked_Serial;
		public String Labor_Hours;
        public String Travel_Hours;
        public String SVMXC_Indirect_in_hours;
        public String Indirect_Confirmation_ERP_ID;
        public String Travel_Confirmation_ERP_ID;
        public String SVMXC_Line_Status;//DCP-37747
        public String ZZCONS_ACK;//DCP-37399 Consumption Confirmed
        public String IS_BILLABLE='';//DCP-46834
        
        /*CONSTRUCTOR: Without parameters.*/
        public ServiceOrderLine() {}

        /*CONSTRUCTOR: With (SVMXC__Service_Order_Line__c) as a parameters.*/     
        public ServiceOrderLine(SVMXC__Service_Order_Line__c workOrderLine) {

            this.SVMXC_Service_Order_Line = workOrderLine.Id;
            this.Name = workOrderLine.Name;
            this.SVMX_PS_External_ID = workOrderLine.SVMX_PS_External_ID__c;
            this.SVMXC_Line_type = workOrderLine.SVMXC__Line_Type__c;
            this.SVMXC_Consumed_From_Location = workOrderLine.SVMXC__Consumed_From_Location__r.SVMX_PS_External_ID__c;
            //INC0453598 - Send Contract Details Blank in case of Billable
            this.ERP_Header_Contract_Number = (workOrderLine.SVMXC__Is_Billable__c !=true ? workOrderLine.ERP_Header_Contract_Number__c:'');
            this.ERP_Contract_Line_Number = (workOrderLine.SVMXC__Is_Billable__c !=true? workOrderLine.ERP_Contract_Line_Number__c:'');
            this.SVMXC_Is_Billable = String.valueOf(workOrderLine.SVMXC__Is_Billable__c);
            this.SVMXC_Non_Billable_Reason = workOrderLine.Non_Billable_Reason__c;
            this.SVMXC_Actual_Quantity = String.valueOf(workOrderLine.SVMXC__Actual_Quantity2__c);
            this.SVMXC_Activity_Type = workOrderLine.SVMXC__Activity_Type__c;
            this.SVMXC_Start_Date = (workOrderLine.SVMXC__Start_Date_and_Time__c != null ? workOrderLine.SVMXC__Start_Date_and_Time__c.format(STRING_DATE_FORMAT,  STRING_DATE_FORMATTED_WITH_TIME_ZONE) : '');
            this.SVMXC_Start_Time = (workOrderLine.SVMXC__Start_Date_and_Time__c != null ? workOrderLine.SVMXC__Start_Date_and_Time__c.format('HH:mm:ss',  STRING_DATE_FORMATTED_WITH_TIME_ZONE) : '') ;
            this.SVMXC_End_Date = (workOrderLine.SVMXC__End_Date_and_Time__c != null ? workOrderLine.SVMXC__End_Date_and_Time__c.format(STRING_DATE_FORMAT,  STRING_DATE_FORMATTED_WITH_TIME_ZONE) : '');
            this.SVMXC_End_Time =  (workOrderLine.SVMXC__End_Date_and_Time__c != null ? workOrderLine.SVMXC__End_Date_and_Time__c.format('HH:mm:ss',  STRING_DATE_FORMATTED_WITH_TIME_ZONE) : '');
             this.SVMX_PS_VS_Consumed_Product_Stock = workOrderLine.SVMXC__Line_Type__c == STRING_WORK_DETAIL_MATERIAL_LINE_TYPE ? workOrderLine.SVMXC__Product__r.ProductCode : workOrderLine.SVMX_PS_VS_Consumed_Product_Stock__r.Product_Code__c;
            this.SVMX_PS_VS_Consumed_Stocked_Serial = workOrderLine.SVMXC__Line_Type__c == STRING_WORK_DETAIL_MATERIAL_LINE_TYPE ? workOrderLine.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c : workOrderLine.SVMX_PS_VS_Consumed_Stocked_Serial__r.Name;
           //this.Duration_in_hours = workOrderLine.Duration_in_hours__c;
            this.SVMXC_Batch_Number = workOrderLine.Batch_Number__c;
			this.Labor_Hours = workOrderLine.Labor_Hours__c;
            this.Travel_Hours = workOrderLine.Travel_Time_in_Hours__c;
            this.SVMXC_Indirect_in_hours = workOrderLine.Indirect_in_hours__c;
            this.Indirect_Confirmation_ERP_ID = workOrderLine.Indirect_Confirmation_ERP_ID__c;
            this.Travel_Confirmation_ERP_ID = workOrderLine.Travel_Confirmation_ERP_ID__c;
            this.SVMXC_Line_Status = String.isNotBlank(workOrderLine.SVMXC__Line_Status__c) && workOrderLine.SVMXC__Line_Status__c.equalsIgnoreCase('Reversal Requested') ? 'Canceled' : workOrderLine.SVMXC__Line_Status__c;//DCP-37747
            this.ZZCONS_ACK = workOrderLine.Consumption_Confirmed__c ? 'X' : '';//DCP-37399
        }

    }
    
    /*WRAPPER CLASS: Holds the field mapping related to Work Detail object.*/
    public class ServiceContracts {
    
    public String ERP_Header_Contract_Number;
    public String ERP_Contract_Line_Number;
    
    /*CONSTRUCTOR: Without parameters.*/
        public ServiceContracts() {}
        
        /*CONSTRUCTOR: With (SVMXC__Service_Order_Line__c) as a parameters.*/    
        public ServiceContracts(Applied_Contract__c serviceContract) {
        this.ERP_Header_Contract_Number = serviceContract.Service_Contract__r.ERP_Header_Contract_Number__c;
        this.ERP_Contract_Line_Number = serviceContract.Service_Contract__r.ERP_Contract_Line_Number__c;
        }
    
    }


}