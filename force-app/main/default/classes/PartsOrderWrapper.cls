/***************************************************************************************************************************************
* NAME         : PartsOrderWrapper
* DESCRIPTION  : Parts Order creation in SAP (Inbound to SAP from SVMX)
*                - This wrapper class holds mapping fields related  to SAP columns and Parts order/ Parts Order Line object fields.
*                    
* @AUTHOR      : 
* @DATE        : 21-Aug-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class PartsOrderWrapper {

    /* WRAPPER VARIABLES */
    public String PackSlipNotes;
    public String InternalNotes;
    public String ServiceOrd;
    public String PurchNoC;
    public String SvmxPartOrdTyp;
    public String SvmxPartOrd;
    public String SvmxWorkOrd;
    public String Caseid;
    public String OpportunityId = '';
    public String PartOrder;
    public String Priority;
	public String CostCenter;//DCP-31970
    
    //DCP-25278 - Start
    public String SalesOrg;
    public String DistrChan;
    public String Division;
    //DCP-25278 - End
    
    //G2022-171 - Start
    public String CaseCategory;
    public String CaseSubType;
    public String WORecordType;
    public String WOOrderType;
    public String DedicatedOnsiteCnt;
    //G2022-171 - End

    public List < NAVHDRTOITM > NAVHDRTOITM = new List < NAVHDRTOITM > ();
    public List < NAVHDRTOPTR > NAVHDRTOPTR = new List < NAVHDRTOPTR > ();
    public List < NAVHDRTOITMOUT > NAVHDRTOITMOUT = new List < NAVHDRTOITMOUT > ();
    public NAVHDRTOHDROUT NAVHDRTOHDROUT = new NAVHDRTOHDROUT();
    public List < NAVHDRTORET > NAVHDRTORET = new List < NAVHDRTORET > ();

    public List < NAVHDRTOSER > NAVHDRTOSER = new List < NAVHDRTOSER > ();
    public List < NAVHDRTOADDR > NAVHDRTOADDR = new List < NAVHDRTOADDR > ();

    //DCP-28844
    public String Svmxextemail;
    
    
    //Other wrapper
    //public List<Object> NAVHDRTOSCHD = new List<Object>();
    //public List<Object> NAVHDRTOSTATHOUT = new List<Object>();
    //public List<Object> NAVHDRTOSTATIOUT = new List<Object>();



        /*
         * Description - WRAPPER CLASS: Holds the field mapping related to Parts Order detail object.
         */ 
    public class NAVHDRTOITM {

        /* WRAPPER VARIABLES */
        public String PartOrdLn;
        public String Contract;
        public String ContractItem;
        public String IsBillable;
        public String Material;
        public String Batch;
        public String TargetQty;
        public String ReqDateH;
        public String CostCenter;
        public String SubstInd;
        public String ItmNumber;
        public String Extid;
        public String NonBillable;
        public String RtrnResCode;
        public String Zzwaybill;//DCP-29175

        //CONSTRUCTOR: Without parameters.
		
		/*
         * Constructor
         */ 		
        public NAVHDRTOITM() {}
        
        //CONSTRUCTOR: With (SVMXC__RMA_Shipment_Line__c) as a parameters.        
		
		/*
         * Constructor
         */ 		
          public NAVHDRTOITM(SVMXC__RMA_Shipment_Line__c partsOrderLine, String returnReason ) {
            
            this.PartOrdLn = (partsOrderLine.Name != null ? partsOrderLine.Name : '');
            this.Contract = (partsOrderLine.ERP_Contract_Number__c != null ? partsOrderLine.ERP_Contract_Number__c : '');
            this.ContractItem = (partsOrderLine.ERP_Contract_Line_Number__c != null ? partsOrderLine.ERP_Contract_Line_Number__c : '');
            this.IsBillable = (String.ValueOf(partsOrderLine.Is_Billable__c) != null && String.ValueOf(partsOrderLine.Is_Billable__c) == 'true' ? 'X' : '');
            this.Material = (partsOrderLine.SVMXC__Product__r.ProductCode != null ? partsOrderLine.SVMXC__Product__r.ProductCode : '');
            this.Batch = (partsOrderLine.Batch_Number__c != null ? partsOrderLine.Batch_Number__c : '');
            this.TargetQty = (String.ValueOf(partsOrderLine.SVMXC__Actual_Quantity2__c) != null ? String.ValueOf(partsOrderLine.SVMXC__Actual_Quantity2__c) : '0.000');
            this.ReqDateH = (String.ValueOf(partsOrderLine.Requested_Delivery_Date__c) != null ? datetime.newInstance(partsOrderLine.Requested_Delivery_Date__c.year(), partsOrderLine.Requested_Delivery_Date__c.month(), partsOrderLine.Requested_Delivery_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss') : null);
            this.CostCenter = (String.ValueOf(partsOrderLine.Cost_Center__c) != null && partsOrderLine.Parts_Order_Type__c != 'Replenishment' ? String.ValueOf(partsOrderLine.Cost_Center__c) : '');//updated for DCP-31970
            this.SubstInd = (String.ValueOf(partsOrderLine.No_Substitute_Parts__c) != null && String.ValueOf(partsOrderLine.No_Substitute_Parts__c) == 'true' ? 'X' : '');
            this.ItmNumber = (String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) != null ? String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) : '');
            this.Extid = String.isNotBlank(partsOrderLine.Work_Detail_Line_Number__c) ? partsOrderLine.Work_Detail_Line_Number__c : '';
            this.NonBillable = String.isNotBlank(partsOrderLine.Reason__c) ? partsOrderLine.Reason__c : '';
            this.RtrnResCode = String.isNotBlank(returnReason)  ? returnReason : '';
            this.Zzwaybill = String.isNotBlank(partsOrderLine.Tracking_Number__c) ? partsOrderLine.Tracking_Number__c : '';//DCP-29175
        }

        //CONSTRUCTOR: With (SVMXC__RMA_Shipment_Line__c) as a parameters.        
		
		/*
         * Constructor
         */ 		
          public NAVHDRTOITM(SVMXC__RMA_Shipment_Line__c partsOrderLine, Integer randomNum, String returnReason ) {
            
            string randomPrefix = randomNum <= 90 ? '0000' : '000';
            
            this.PartOrdLn = (partsOrderLine.Name != null ? partsOrderLine.Name : '');
            this.Contract = (partsOrderLine.ERP_Contract_Number__c != null ? partsOrderLine.ERP_Contract_Number__c : '');
            this.ContractItem = (partsOrderLine.ERP_Contract_Line_Number__c != null ? partsOrderLine.ERP_Contract_Line_Number__c : '');
            this.IsBillable = (String.ValueOf(partsOrderLine.Is_Billable__c) != null && String.ValueOf(partsOrderLine.Is_Billable__c) == 'true' ? 'X' : '');
            this.Material = (partsOrderLine.SVMXC__Product__r.ProductCode != null ? partsOrderLine.SVMXC__Product__r.ProductCode : '');
            this.Batch = (partsOrderLine.Batch_Number__c != null ? partsOrderLine.Batch_Number__c : '');
            this.TargetQty = (String.ValueOf(partsOrderLine.SVMXC__Actual_Quantity2__c) != null ? String.ValueOf(partsOrderLine.SVMXC__Actual_Quantity2__c) : '0.000');
            this.ReqDateH = (String.ValueOf(partsOrderLine.Requested_Delivery_Date__c) != null ? datetime.newInstance(partsOrderLine.Requested_Delivery_Date__c.year(), partsOrderLine.Requested_Delivery_Date__c.month(), partsOrderLine.Requested_Delivery_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss') : null);
            this.CostCenter = (String.ValueOf(partsOrderLine.Cost_Center__c) != null && partsOrderLine.Parts_Order_Type__c != 'Replenishment' ? String.ValueOf(partsOrderLine.Cost_Center__c) : '');//DCP-31970
            this.SubstInd = (String.ValueOf(partsOrderLine.No_Substitute_Parts__c) != null && String.ValueOf(partsOrderLine.No_Substitute_Parts__c) == 'true' ? 'X' : '');
            this.ItmNumber = (String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) != null ? String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) : randomPrefix+String.ValueOf(randomNum));
            this.Extid = String.isNotBlank(partsOrderLine.Work_Detail_Line_Number__c) ? partsOrderLine.Work_Detail_Line_Number__c : '';
            this.NonBillable = String.isNotBlank(partsOrderLine.Reason__c) ? partsOrderLine.Reason__c : '';
            this.RtrnResCode = String.isNotBlank(returnReason)  ? returnReason : '';
            this.Zzwaybill = String.isNotBlank(partsOrderLine.Tracking_Number__c) ? partsOrderLine.Tracking_Number__c : '';//DCP-29175
        }
        
        //CONSTRUCTOR: With (SVMXC__Stock_Transfer_Line__c) as a parameters.        
		
		/*
         * Constructor
         */ 		
        public NAVHDRTOITM(SVMXC__Stock_Transfer_Line__c stockTransferLine) {

            this.PartOrdLn = '';
            this.Contract = '';
            this.ContractItem = '';
            this.IsBillable = '';
            this.Material = (stockTransferLine.SVMXC__Product__r.ProductCode != null ? stockTransferLine.SVMXC__Product__r.ProductCode : '');
            this.Batch = (stockTransferLine.Batch_Number__c != null ? stockTransferLine.Batch_Number__c : '');
            this.TargetQty =  (String.ValueOf(stockTransferLine.SVMXC__Quantity_Transferred2__c) != null ? String.ValueOf(stockTransferLine.SVMXC__Quantity_Transferred2__c) : '0.000');
            this.ReqDateH = null ;
            this.CostCenter = '' ;
            this.SubstInd = '' ;
            this.ItmNumber = (String.isNotBlank(stockTransferLine.Name) ? stockTransferLine.Name.right(6) : '');
            this.Extid = '';
            this.NonBillable = '';
            this.RtrnResCode = '';
            this.Zzwaybill = '';//DCP-29175


        }
        
        //CONSTRUCTOR: With (SVMXC__Parts_Request_Line__c) as a parameters.  
		
		/*
         * Constructor
         */ 		
        public NAVHDRTOITM(SVMXC__Parts_Request_Line__c partsRequestLine) {

            this.PartOrdLn = '';
            this.Contract = '';
            this.ContractItem = '';
            this.IsBillable = '';
            this.Material = (partsRequestLine.SVMXC__Product__r.ProductCode != null ? partsRequestLine.SVMXC__Product__r.ProductCode : '');
            this.Batch = (partsRequestLine.Batch_Number__c != null ? partsRequestLine.Batch_Number__c : '');
            this.TargetQty =  (String.ValueOf(partsRequestLine.SVMXC__Quantity_Required2__c) != null ? String.ValueOf(partsRequestLine.SVMXC__Quantity_Required2__c) : '0.000');
            this.ReqDateH = null ;
            this.CostCenter = '' ;
            this.SubstInd = '' ;
            this.ItmNumber = (String.isNotBlank(partsRequestLine.Name) ? partsRequestLine.Name.right(6) : '');
            this.Extid = '';
			this.NonBillable = '';
			this.RtrnResCode = '';
			this.Zzwaybill = '';//DCP-29175


        }


    }
    
    
		/*
         * Constructor
         */ 	
    public class NAVHDRTOADDR {
    
    /* WRAPPER VARIABLES */
       public String Name2;
       public String Tel1Numbr;
       public String Name;
       public String COName;
       public String Street;
       public String StrSuppl1;
       public String Email;//DCP-28844
       public String Country;
       public String Region;
       public String City;
       public String PostlCod1;
       public String Name3;
       
       //CONSTRUCTOR: Without parameters.
		/*
         * Constructor
         */ 	   
        public NAVHDRTOADDR() {
        
        this.Name2 = '';
        this.Tel1Numbr = '';
        this.Name = '';
        this.COName = '';
        this.Street = '';
        this.StrSuppl1 = '';
        this.Email = '';//DCP-28844
        this.Country = '';
        this.Region = '';
        this.City = '';
        this.PostlCod1 = '';
        this.Name3 = '';
        
        
        }
        
        /*
        * @author : Vaibhav
        * @description : CONSTRUCTOR: With (SVMXC__RMA_Shipment_Order__c) as a parameters. 
        */      
        public NAVHDRTOADDR(SVMXC__RMA_Shipment_Order__c  partsOrder,string contactEmail) {
        
        this.Name2 = (String.isNotBlank(partsOrder.Contact_Name__c) ? partsOrder.Contact_Name__c : '');
        this.Tel1Numbr = (String.isNotBlank(partsOrder.Contact_Phone__c) ? partsOrder.Contact_Phone__c : '');
        this.Name = (String.isNotBlank(partsOrder.Ship_To_Company__c) ? partsOrder.Ship_To_Company__c : '');
        this.Name3 = (String.isNotBlank(partsOrder.Ship_To_Company_2__c) ? partsOrder.Ship_To_Company_2__c : '');
        this.Street = (String.isNotBlank(partsOrder.Shipping_Street__c) ? partsOrder.Shipping_Street__c : '');
        this.StrSuppl1 = (String.isNotBlank(partsOrder.Shipping_Street_2__c) ? partsOrder.Shipping_Street_2__c : '');
        this.Email = (String.isNotBlank(contactEmail) ? contactEmail : '');//DCP-28844
        this.Country = (String.isNotBlank(partsOrder.Shipping_Country__c) && partsOrder.Shipping_Country__c.contains('[')  ? partsOrder.Shipping_Country__c.substringBetween('[',']') : '');
        if(String.isNotBlank(partsOrder.Shipping_State_Province__c)){
            this.Region = (String.isNotBlank(partsOrder.Shipping_State_Province__c) && partsOrder.Shipping_State_Province__c.contains('[') && !partsOrder.Shipping_State_Province__c.EqualsIgnoreCase('N/A') ? partsOrder.Shipping_State_Province__c.substringBetween('[',']') : '');
        }else if(String.isNotBlank(partsOrder.Shipping_State_Province_2__c)){
            this.Region = (String.isNotBlank(partsOrder.Shipping_State_Province_2__c) && partsOrder.Shipping_State_Province_2__c.contains('[') && !partsOrder.Shipping_State_Province_2__c.EqualsIgnoreCase('N/A') ? partsOrder.Shipping_State_Province_2__c.substringBetween('[',']') : '');
        }else{
            this.Region = '';
        }
        this.City = (String.isNotBlank(partsOrder.Shipping_City__c) ? partsOrder.Shipping_City__c : '');
        this.PostlCod1 = (String.isNotBlank(partsOrder.Shipping_Postal_Code__c) ? partsOrder.Shipping_Postal_Code__c : '');
        this.COName = (String.isNotBlank(partsOrder.Care_Of__c) ? partsOrder.Care_Of__c : '');
        
        }
        
     }   


    //WRAPPER CLASS: Holds the field mapping related to Parts Order detail object.
	
		/*
         * Constructor
         */ 	
    public class NAVHDRTOPTR {

       
        public String PartnRole;
        public String PartnNumb;

        //CONSTRUCTOR: Without parameters.

		/*
         * Constructor
         */ 		
        public NAVHDRTOPTR() {}

        //CONSTRUCTOR: With (SVMXC__RMA_Shipment_Line__c) as a parameters.    

		/*
         * Constructor
         */ 		
        public NAVHDRTOPTR(String PartnRole, String PartnNumb) {
            this.PartnRole = PartnRole;
            this.PartnNumb = PartnNumb;
        }

    }
    


    //WRAPPER CLASS: Holds the field mapping related to Parts Order detail response back.
	
		/*
         * Constructor
         */ 	
    public class NAVHDRTOITMOUT {

        /* WRAPPER VARIABLES */
        public String DocNumber;
        public String ItmNumber;
        public String Material;
        public String TargetQty;
        public String PartOrdLn;
        public String Priority;
        public String ExpShpDt;
        public String ExpDelDt;

        //CONSTRUCTOR: Without parameters.
		
		/*
         * Constructor
         */ 		
        public NAVHDRTOITMOUT() {
            this.DocNumber = '';
            this.ItmNumber = '';
            this.Material = '';
            this.TargetQty = '0.000';
            this.PartOrdLn = '';
            this.Priority = '';
            this.ExpShpDt = null;
            this.ExpDelDt = null;
        }


    }


    //WRAPPER CLASS: Holds the field mapping related to Parts Order  response back.
	
		/*
         * Constructor
         */ 	
    public class NAVHDRTOHDROUT {

        /* WRAPPER VARIABLES */
        public String DocNumber;
        public String RecDate;
        public String CreatedBy;
        public String DocType;
        public String PartOrder;
        public String SvmxPartOrd;

        //CONSTRUCTOR: Without parameters.
		
		/*
         * Constructor
         */ 		
        public NAVHDRTOHDROUT() {
            this.DocNumber = '';
            this.RecDate = null;
            this.CreatedBy = '';
            this.DocType = '';
            this.PartOrder = '';
            this.SvmxPartOrd = '';
        }


    }


    //WRAPPER CLASS: Holds the field mapping related to Parts Order detail response back.
	
		/*
         * Constructor
         */ 	
    public class NAVHDRTORET {

        /* WRAPPER VARIABLES */
        public String Type;
        public String Id;
        public String Message;
        public String LogNo;
        public String LogMsgNo;
        public String MessageV1;
        public String MessageV2;
        public String MessageV3;
        public String MessageV4;
        public String Parameter;
        public String Field;


        //CONSTRUCTOR: Without parameters.
		
		/*
         * Constructor
         */ 		
        public NAVHDRTORET() {
            this.Type = '';
            this.Id = '';

            this.Message = '';
            this.LogNo = '';
            this.LogMsgNo = '';
            this.MessageV1 = '';
            this.MessageV2 = '';
            this.MessageV3 = '';
            this.MessageV4 = '';
            this.Parameter = '';
            this.Field = '';


        }


    }
    
		/*
         * Constructor
         */ 	
    public class NAVHDRTOSER {

       
        public String RefItem;
        public String Serialno;
        
         //CONSTRUCTOR:
		 
		/*
         * Constructor
         */ 		 
        public NAVHDRTOSER(SVMXC__RMA_Shipment_Line__c partsOrderLine) {
        this.RefItem = (String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) != null ? String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) : '');
        //if Order Type != Stock Transfer -> Get the serial number from Installed Product else use Stocked Serial lookup.
        if(partsOrderLine.Parts_Order_Type__c != 'Stock Transfer'){
        this.Serialno = (partsOrderLine.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c != null ? partsOrderLine.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c : '');
        } else {
        this.Serialno = (partsOrderLine.Stocked_Serial__c != null ? partsOrderLine.Stocked_Serial__r.Name : '');
        }
        
        }

        //CONSTRUCTOR:
		/*
         * Constructor
         */ 		
        public NAVHDRTOSER(SVMXC__RMA_Shipment_Line__c partsOrderLine, Integer randomNum) {
        string randomPrefix = randomNum <= 90 ? '0000' : '000';
        this.RefItem = (String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) != null ? String.ValueOf(partsOrderLine.ERP_Sales_Order_Item__c) : randomPrefix+String.ValueOf(randomNum));
        //if Order Type != Stock Transfer -> Get the serial number from Installed Product else use Stocked Serial lookup.
        if(partsOrderLine.Parts_Order_Type__c != 'Stock Transfer'){
        this.Serialno = (partsOrderLine.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c != null ? partsOrderLine.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c : '');
        } else {
        this.Serialno = (partsOrderLine.Stocked_Serial__c != null ? partsOrderLine.Stocked_Serial__r.Name : '');
        }
        }

        //CONSTRUCTOR:
		/*
         * Constructor
         */ 		
        public NAVHDRTOSER(SVMXC__Stock_Transfer_Line__c stockTransferLine) {
        this.RefItem = (String.isNotBlank(stockTransferLine.Name) ? stockTransferLine.Name.right(6) : '');
        this.Serialno = (stockTransferLine.SVMX_PS_VS_Serial_Number__c != null ? stockTransferLine.SVMX_PS_VS_Serial_Number__c: '');
        }
        
        //CONSTRUCTOR:
		
		/*
         * Constructor
         */ 		
        public NAVHDRTOSER(SVMXC__Parts_Request_Line__c partsRequestLine) {
        this.RefItem = (String.isNotBlank(partsRequestLine.Name) ? partsRequestLine.Name.right(6) : '');
        this.Serialno = (partsRequestLine.SVMXC__Serial_Number_List__c != null ? partsRequestLine.SVMXC__Serial_Number_List__c: '');
        }

    }

}