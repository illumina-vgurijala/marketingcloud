/*
 * @Author: Sravan Panchangam
 * @Decription : For DCP-13048 : Wrapper class for order and and Order Line Items which we will be getting through json
 * @Date : 10/08/2018
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                        Description
 * Rahul Bishnoi           07-Jan-2020                  DCP-31268 : Informatics : Updated mapping
 * Rahul Bishnoi           14-Jan-2020                  DCP-32794 Removed Field Software Id
 * Shivani Jain            28-Jun-2021                  DCP-46875 : Added Billing_Block on Order Line Item
 * Juned                   21-Sep-2021                  DCP-49671 : Added Material Group 5 on Order Line Item
 * Himanshu                31-Mar-2022                  Code Scan Fixes 
 * Rucha Dalvi             05-Jul-2022                  Codescan Fixes - Position Literal first
 * Koustubh M              12-Apr-2022                  TASK0730598: Used header level asset activation - removed code of order status and item status = 'Open'
 * Jitesh Lakhwani         09-Jan-2023                  CodeScan fix
 * Saurabh Brahmankar      16-Nov-2023                  tradeInIndicator - CodeScan fix [Trade_In_Indicator]
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * 
*/
public class ApttusOrderWrapper {
   /**
     * @author Sravan Panchangam
     * @description Wrapper class for order here the Json values are deserialized and mapping accordingly to the below mentioned attributes
    */
    public static final String SALES_CANCELLED = 'Cancelled';
    public static final String SALES_REJECTED = 'Rejected';
    //Codescan Fix - Position Literal First
    public static final String SALES_OPEN = 'Open';
    public static final String SALES_PARTIAL = 'Partial';
    /**
     * @author Sravan Panchangam
     * @description Wrapper class for order here the Json values are deserialized and mapping accordingly to the below mentioned attributes
    */
    public class Order{
        public String Apttus_Config2_OrderReferenceNumber;
        public String Apttus_Config2_Type;
        public String Order_Reason;
        public String ERP_Quote_Number;
        public String Apttus_Config2_PONumber;
        public String Apttus_Config2_PODate;
        public String Contract_Review_Status;
        public String Total_Price;
        public String Total_Price_USD;
        public String Apttus_Config2_SoldToAccountId ;//lookup
        public String Ship_To;//lookup
        public String Bill_To;//lookup
        public String Payer;//lookup
        public String Ultimate_Consignee;//lookup
        public String Distributor;//lookup
        public String PO_Type;
        public String Order_Status;
        public String Contact_Name;
        public String Contact_Email;
        public String Payment_Term;
        public String Inco_Term_1;
        public String Billing_Block;
        public String Total_Frieght;
        public String Total_Frieght_USD;
        public String CurrencyIsoCode;
        public String Total_Discount;
        public String Total_Discount_USD;
        public String ASOP_Number;
        public String Apttus_QPConfig_ProposalId;//lookup
        public String Apttus_Config2_RelatedOpportunityId;//lookup
        public List<OrderLineItem> orderLineItem;
        /**
        * @author  Sravan Panchangam
        * @description The above mentioned attributes are set to respective orders using this method
        * @params NA
        * @return Apttus_Config2__Order__c
        **/ 
        public Apttus_Config2__Order__c getSObject(){
           // Map<String, Map<String,String>> objectToPicklistValueMap=UtilsSettings.getCustomMetadataPicklistMap('Apttus_Config2__Order__c','ERP',false);
            UtilsRest utilRest = new UtilsRest();
            ApttusOrderWrapper.OrderLineItem dateConversionValue = new ApttusOrderWrapper.OrderLineItem();
            Apttus_Config2__Order__c objOrder=new Apttus_Config2__Order__c(Apttus_Config2__OrderReferenceNumber__c=this.Apttus_Config2_OrderReferenceNumber,
                                                                           Sales_Order_Number_Unique__c=this.Apttus_Config2_OrderReferenceNumber,
                                                                            Apttus_Config2__Type__c=this.Apttus_Config2_Type,
                                                                           Order_Reason__c =this.Order_Reason,
                                                                           ERP_Quote_Number__c=this.ERP_Quote_Number,
                                                                           Apttus_Config2__PONumber__c=this.Apttus_Config2_PONumber,
                                                                           Apttus_Config2__PODate__c= dateConversionValue.stringTODateTimeFormatConversion(Apttus_Config2_PODate),
                                                                           Contract_Review_Status__c=this.Contract_Review_Status,
                                                                           Total_Price__c=String.isNotBlank(this.Total_Price)?utilRest.stringToDecimalConversion(this.Total_Price):null,
                                                                           Total_Price_USD__c=String.isNotBlank(this.Total_Price_USD)?utilRest.stringToDecimalConversion(this.Total_Price_USD):null,
                                                                           //For Populating the LookUps we are setting the values to ERP Ids which will be used in ApttusOrderTrigger for populating the lookups
                                                                           Apttus_Config2_SoldToAccountId_ERP_Id__c=this.Apttus_Config2_SoldToAccountId,
                                                                           Ship_To_ERP_Id__c=this.Ship_To,
                                                                           Bill_To_ERP_Id__c=this.Bill_To,
                                                                           Payer_ERP_Id__c=this.Payer,
                                                                           Ultimate_Consignee_ERP_Id__c=this.Ultimate_Consignee,
                                                                           Distributor_ERP_Id__c=this.Distributor,
                                                                           PO_Type__c=this.PO_Type,
                                                                           Order_Status__c=this.Order_Status,
                                                                           Contact_Name__c=this.Contact_Name,
                                                                           Contact_Email__c=this.Contact_Email,
                                                                           Payment_Term__c=this.Payment_Term,
                                                                           Inco_Term_1__c=this.Inco_Term_1,//objectToPicklistValueMap.get('Inco_Term_1__c').get(this.Inco_Term_1),
                                                                           Billing_Block__c=this.Billing_Block,
                                                                           Total_Freight__c=String.isNotBlank(this.Total_Frieght)?utilRest.stringToDecimalConversion(this.Total_Frieght):null,
                                                                           Total_Freight_USD__c=String.isNotBlank(this.Total_Frieght_USD)?utilRest.stringToDecimalConversion(this.Total_Frieght_USD):null,
                                                                           CurrencyIsoCode=this.CurrencyIsoCode,
                                                                           Total_Discount__c=String.isNotBlank(this.Total_Discount)?utilRest.stringToDecimalConversion(this.Total_Discount):null,
                                                                           Total_Discount_USD__c=String.isNotBlank(this.Total_Discount_USD)?utilRest.stringToDecimalConversion(this.Total_Discount_USD):null,
                                                                           ASOP_Number__c=this.ASOP_Number,
                                    //Assigning the the value to ApttusQuoteNumber for populating the lookups Proposal And Opportunity in orders
                                                                           APTTUS_Quote_Number__c=this.Apttus_QPConfig_ProposalId
                                                                           );
            if(Order_Status!=null){
                     
                if(Order_Status==Label.LineItemLineStatusCancelled||Order_Status==Label.OrderLineItemStatusRejected){
                    objOrder.Apttus_Config2__Status__c=Label.LineItemLineStatusCancelled;
                }
                else if('Partial'.equals(Order_Status)){
                    objOrder.Apttus_Config2__Status__c='Partially Fulfilled';
                }
            }
                  
            return objOrder;
        }
        
    }
    /**
     * @author Sravan Panchangam
     * @description Wrapper class for orderLineItems here the Json values are deserialized and mapping accordingly to the below mentioned attributes
    */
    public class OrderLineItem{
        public String ERP_Line_Number_Id; 
        public String Apttus_Config2_ProductId;//lookup
        public String Apttus_Config2_Quantity;
        public String Apttus_Config2_NetPrice;
        public String CurrencyIsoCode;
        public String Net_Price_USD;
        public String Total_Item_Discount;
        public String Total_Item_Discount_USD;
        public String Total_Item_Freight;
        public String Total_Item_Freight_USD;
        public String Actual_Ship_Date;
        public String Reason_For_Rejection;
        public String Apttus_Config2_NetUnitPrice;
        public String Delivery_Block;
        public String Item_Status;
        public String Apttus_QPConfig_ProposalLineItemId;//lookup
        //Added for DCP 11240
        public String Start_Date;
        public String End_Date;
        public String ERP_Contract_Type;
         // Added by KD
        public String SVMXC_Start_Date;
        public String SVMXC_End_Date;
        public String Equipment_Id;
        public String Software_Id;
        public String Serial_Number;
        public String SVMXC_Service_Plan;
        public String Apttus_Config2_BillingFrequency;
        public String Name;
        public String Estimated_Delivery_Date;
        //Informatics : DCP-31270
        public String PGUID;
        public String Workgroup_ID;
        public String Domain_ID;
        public String Region;
        public String Subscription_ID;
        public String URL;
        public String Subscription_Activation_Flag;
        public String Registration_Relevant;
        //Informatics : DCP-31268
        public String Registrant_Contact;
        public String Registrant_Lead;
        public String Workgroup_Name;
        public String Domain_Pattern;
        public String Object_Status;
        public Boolean Custom_License_Flag;
        public String Dragen_Connectivity;
        public String Billing_Block; //DCP-46875
        public String Material_Group_5; //DCP-49671
        public String Trade_In_Indicator; //TRADE-IN

       /**
        * @author  Sravan Panchangam
        * @description As actual ship date is accepts only date in this conversion we are modifying the value that we are getting and change it to date format
        * @params String dateString
        * @return Date
        **/
        public Date stringTODateTimeFormatConversion(String dateString){
            if( dateString!=null  &&  dateString.length()==8){
                String year=dateString.substring(0, 4);
                String month=dateString.substring(4,6);
                String day=dateString.substring(6);
                Date dateValue = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month),Integer.valueOf(day));
                return dateValue;
            }
            return null;
        }        
       /**
        * @author  Sravan Panchangam
        * @description the above mentioned attributes are set to respective orderlineitems using this method  
        * @params NA
        * @return Apttus_Config2__OrderLineItem__c
        **/    
        public Apttus_Config2__OrderLineItem__c getSObject(){
            UtilsRest utilRest = new UtilsRest();
            Apttus_Config2__OrderLineItem__c    objOrderLineItem=new Apttus_Config2__OrderLineItem__c(ERP_Line_Number_Id__c=this.ERP_Line_Number_Id,
                                                                                                      Dragen_Connectivity__c = Dragen_Connectivity,
                                                                                                      Work_Group_Name__c=Workgroup_Name,
                                                                                                      Instance_Region__c=Region,
                                                                                                      Zuora_Subscription_ID__c=Subscription_ID,
                                                                                                      Domain_URL__c=Domain_Pattern,
                                                                                                      Object_Status__c=Object_Status,
                                                                                                      Custom_License_Flag__c=Custom_License_Flag,
                                                                                                      Apttus_Config2__Quantity__c=String.isNotBlank(this.Apttus_Config2_Quantity)?utilRest.stringToDecimalConversion(this.Apttus_Config2_Quantity):null,
                                                                                                      Apttus_Config2__NetPrice__c=String.isNotBlank(this.Apttus_Config2_NetPrice)?utilRest.stringToDecimalConversion(this.Apttus_Config2_NetPrice):null,
                                                                                                      CurrencyIsoCode=this.CurrencyIsoCode,
                                                                                                      Net_Price_USD__c=String.isNotBlank(this.Net_Price_USD)?utilRest.stringToDecimalConversion(this.Net_Price_USD):null,
                                                                                                      Total_Item_Discount__c=String.isNotBlank(this.Total_Item_Discount)?utilRest.stringToDecimalConversion(this.Total_Item_Discount):null,
                                                                                                      Total_Item_Discount_USD__c=String.isNotBlank(this.Total_Item_Discount_USD)?utilRest.stringToDecimalConversion(this.Total_Item_Discount_USD):null,
                                                                                                      Total_Item_Freight__c=String.isNotBlank(this.Total_Item_Freight)?utilRest.stringToDecimalConversion(this.Total_Item_Freight):null,
                                                                                                      Total_Item_Freight_USD__c=String.isNotBlank(this.Total_Item_Freight_USD)?utilRest.stringToDecimalConversion(this.Total_Item_Freight_USD):null,
                                                                                                      Actual_Ship_Date__c=this.stringTODateTimeFormatConversion(this.Actual_Ship_Date),
                                                                                                      Estimated_Delivery_Date__c=this.stringTODateTimeFormatConversion(this.Estimated_Delivery_Date),
                                                                                                      Reason_For_Rejection__c=this.Reason_For_Rejection,
                                                                                                      Apttus_Config2__NetUnitPrice__c=String.isNotBlank(this.Apttus_Config2_NetUnitPrice)?utilRest.stringToDecimalConversion(this.Apttus_Config2_NetUnitPrice):null,
                                                                                                      Delivery_Block__c=this.Delivery_Block,
                                                                                                      Item_Status__c=this.Item_Status,
                                                                                                      Apttus_Quote_Line_Item_Number__c=this.Apttus_QPConfig_ProposalLineItemId,
                                                                                                      Apttus_Config2__StartDate__c=this.stringTODateTimeFormatConversion(this.SVMXC_Start_Date),
                                                                                                      Apttus_Config2__EndDate__c=this.stringTODateTimeFormatConversion(this.SVMXC_End_Date),
                                                                                                      ERP_Contract_Type__c=this.ERP_Contract_Type,
                                                                                                      //Software_Id__c = this.Software_Id,
                                                                                                      Serial_Number__c = this.Serial_Number,
                                                                                                      Apttus_Config2__BillingFrequency__c = this.Apttus_Config2_BillingFrequency,
																									  Equipment_Id__c = this.Equipment_Id,
                                                                                                      //DCP-46875
                                                                                                      Billing_Block__c=this.Billing_Block,
                                                                                                      //DCP-49671
                                                                                                      Material_Group_5__c=this.Material_Group_5,
                                                                                                      Trade_In_Indicator__c = this.Trade_In_Indicator // need validate nulls
                                                                                                      );
            if(Item_Status!=null){
                if(Item_Status == Label.LineItemLineStatusCancelled ||Item_Status == Label.OrderLineItemStatusRejected){
                    objOrderLineItem.Apttus_Config2__Status__c='Cancelled';
                }
                else if('Partial'.equals(Item_Status)){
                    objOrderLineItem.Apttus_Config2__Status__c='Partially Fulfilled';
                }
            }
            return objOrderLineItem;
        }
        
    }
}