/*
 * @Author: Kushagra Desai
 * @Date: 2018-10-05
 * @Description : Quotation Wrapper is used to deserialize the json and map the values to Apttus_Proposal__Proposal_Line_Item__c and Apttus_Proposal__Proposal__c objects 
 *  Modification Log:
 *       ------------------------------------------------------------------------------------
 *       Prem Ranjan         04 May 2022             CodeScan Fix (APEX) Unused Local Variable 
 *       Kushagra Desai       2018-10-05           Initial Version
 *       Aman Tyagi           2022-03-31           CodeScan Fixes
 *       Khushbu Vasani       2022-05-25           INC0399426 fix to populate list price
 *       ------------------------------------------------------------------------------------
 */
public class QuotationDataRecieverWrapper{

//START CodeScan Fix [Avoid Literals in If condition]
private static final String STRING_W_Y = 'W_Y';
private static final String STRING_W_N = 'W_N';
private static final String STRING_A = 'A';
private static final String STRING_N = 'N'; 
//END CodeScan Fix 
/*
 * @Author: Kushagra Desai
 * @Description : static method for null check
 * @param: String check
 * @return: boolean
 */

public static boolean nullChecker(String Check){
  system.debug('Check-'+Check);
  if(Check == '' || Check == null){
    return false;
  }
  else{
    return true;
  }
}

/*
 * @Author: Kushagra Desai
 * @Description : static method to convert date time format
 * @param: String dateTimeString
 * @return: DateTime
 */
public static DateTime stringTODateTimeFormatConversion(String dateTimeString){
        if( dateTimeString!=null  &&  dateTimeString.length()==8){
            String year=dateTimeString.substring(0, 4);
            String month=dateTimeString.substring(4,6);
            String day=dateTimeString.substring(6);
            String format=year+'-'+month+'-'+day;
            DateTime dateTimeValue= datetime.valueOf(format+' 00:00:00');
            return dateTimeValue;
        }
           return null;
    }

 /*
 * @Author: Kushagra Desai
 * @Description : static method to convert date format
 * @param: String dateString
 * @return: Date
 */
public static Date stringTODateFormatConversion(String dateString){
    if( dateString!=null  &&  dateString.length()==8){
        String year=dateString.substring(0, 4);
        String month=dateString.substring(4,6);
        String day=dateString.substring(6);
        String format=year+'-'+month+'-'+day;
        Date dateTimeValue= date.valueOf(format);
        return dateTimeValue;
    }
       return null;
}
/*
     * @Author: Kushagra Desai
     * @Description : While deserializing the Json all the values that belong to Apttus_Proposal__Proposal__c are mapped to the variables in the QuoteWrapper class 
   */
public class QuoteWrapper{

        public String SAP_Quote;
        public String Apttus_Proposal_ExpectedEndDate;
        public String Apttus_QPConfig_PricingDate; // 20180322
        public String Apttus_Proposal_Quote_Stage;
        public String Apttus_Proposal_Account; 
        public String Ship_To; 
        public String Bill_To;
        public String Payer;
        public String Ultimate_Consignee;
        public String Distributor;
        public String Apttus_Proposal_Opportunity;
        public String Discount_Justification;
        public String Inco_Term_1;
        public String Apttus_Proposal_Payment_Term;
        public String Web_Visible;  // W_Y or W_N
        public String CurrencyIsoCode;
        public String Total_Net;
        public String Total_Net_USD;
        public String Total_Discount;
        public String Total_Discount_USD;
        public String Estimated_Freight;
        public String Estimated_Freight_USD;
        public String Estimated_Tax;
        public String Estimated_Tax_USD;
        public String Promo_Code_1;
        public String Promo_Code_2;
        public String Promo_Code_3;
        public String Promo_Channel_1;
        public String Promo_Channel_2;
        public String Promo_Channel_3;
        public String Post_Pricing_Message;
        public list<ProposalLineitemWrapper> ProposalLineitemWrapper;

        
           /*
         *@Author: Kushagra Desai
         *@Description: String to Date format Conversion for DCP-11857 (Conversion from YYYYMMDD to YYYY-MM-DD)
          */
        public Date stringTODateFormatConversion(String dateString){
            if( dateString!=null  &&  dateString.length()==8){
                String year=dateString.substring(0, 4);
                String month=dateString.substring(4,6);
                String day=dateString.substring(6);
                String format=year+'-'+month+'-'+day;
                Date dateValue = Date.valueOf(format);
                return dateValue;
            }
            return null;
        }       
        /*
         * @Author: Kushagra Desai
         * @Description : Once the values are mapped  to the variables then getSobject is method is used for mapping the variables with the fields in the Apttus_Proposal__Proposal__c object 
         * @return Apttus_Proposal__Proposal__c record
        */
        public Apttus_Proposal__Proposal__c getSobject(){
            UtilsRest utilRest = new UtilsRest();
            system.debug('*****'+Total_Net);
            system.debug('*****--' + nullChecker(this.Total_Net));
            Apttus_Proposal__Proposal__c quoteobj = new Apttus_Proposal__Proposal__c(
                                                               SAP_Quote__c = this.SAP_Quote,
                                                               Apttus_Proposal__ExpectedEndDate__c  = stringTODateFormatConversion(this.Apttus_Proposal_ExpectedEndDate),
                                                               Apttus_QPConfig__PricingDate__c = stringTODateTimeFormatConversion(this.Apttus_QPConfig_PricingDate),
                                                               Discount_Justification__c = this.Discount_Justification,
                                                               Inco_Term_1__c= this.Inco_Term_1,//objectToPicklistValueMap.get('Inco_Term_1__c').get(this.Inco_Term_1),
                                                               Apttus_Proposal__Payment_Term__c = this.Apttus_Proposal_Payment_Term,
                                                               CurrencyIsoCode = this.CurrencyIsoCode,
                                                               Total_Net__c = nullChecker(this.Total_Net) ? utilRest.stringToDecimalConversion(this.Total_Net):null,
                                                               Total_Net_USD__c = nullChecker(this.Total_Net_USD) ? utilRest.stringToDecimalConversion(this.Total_Net_USD):null,
                                                               Total_Discount__c = nullChecker(this.Total_Discount) ? utilRest.stringToDecimalConversion(this.Total_Discount):null,
                                                               Total_Discount_USD__c = nullChecker(this.Total_Discount_USD) ? utilRest.stringToDecimalConversion(this.Total_Discount_USD):null,
                                                               Estimated_Freight__c = nullChecker(this.Estimated_Freight) ? utilRest.stringToDecimalConversion(this.Estimated_Freight):null,
                                                               Estimated_Freight_USD__c = nullChecker(this.Estimated_Freight_USD) ? utilRest.stringToDecimalConversion(this.Estimated_Freight_USD):null,
                                                               Estimated_Tax__c = nullChecker(this.Estimated_Tax) ? utilRest.stringToDecimalConversion(this.Estimated_Tax):null,
                                                               Estimated_Tax_USD__c = nullChecker(Estimated_Tax_USD) ? utilRest.stringToDecimalConversion(this.Estimated_Tax_USD):null,
                                                               Promo_Code_1__c = this.Promo_Code_1,
                                                               Promo_Code_2__c = this.Promo_Code_2,
                                                               Promo_Code_3__c = this.Promo_Code_3,
                                                               Promo_Channel_1__c = this.Promo_Channel_1,
                                                               Promo_Channel_2__c = this.Promo_Channel_2,
                                                               Promo_Channel_3__c = this.Promo_Channel_3,
                                                               Post_Pricing_Message__c = this.Post_Pricing_Message,
                                                               Apttus_Proposal__Opportunity__c = this.Apttus_Proposal_Opportunity
                                                               );
            if(this.Web_Visible == STRING_W_Y){ 
              quoteobj.Web_Visible__c = true;
            }
            else if(this.Web_Visible == STRING_W_N){ 
              quoteobj.Web_Visible__c = false;
            }
            if(this.Apttus_Proposal_Quote_Stage == 'Initial' || this.Apttus_Proposal_Quote_Stage == 'Pending'){
              quoteobj.Apttus_Proposal__Approval_Stage__c = Label.QuoteStageDraft;
            }else
              quoteobj.Apttus_Proposal__Approval_Stage__c = this.Apttus_Proposal_Quote_Stage;
            /* else if(this.Apttus_Proposal_Quote_Stage == 'Approved'){
              quoteobj.Apttus_Proposal__Approval_Stage__c = 'Approved';
            }
            else if(this.Apttus_Proposal_Quote_Stage == 'Rejected'){
              quoteobj.Apttus_Proposal__Approval_Stage__c = 'Rejected';
            } */
            return quoteobj;
        }
        
    }
      public class ProposalLineitemWrapper{

      public String ERP_Line_number;
      public String Apttus_Proposal_Product;
      public String Apttus_Proposal_Quantity;
      public String CurrencyIsoCode;
      public String Total_Item_Discount;
      public String Total_Item_Discount_USD;
      public String Apttus_QPConfig_ListPrice;
      public String Stacked_Discount_Percentage;
      public String Stacked_Discount_Amount;
      public String Distributor_Discount_Percentage;
      public String Distributor_Discount_Amount;
      public String Customer_Net_Price;
      public String Discounted_Price_Per_Unit;
      public String Apttus_QPConfig_NetPrice;
      public String Freight_Discount_Percentage;
      public String Freight_Discount_Amount;
      public String Applied_Discount_Details;
      public String Applied_Discount_Percentage;
      public String Applied_Discount_Amount;
      public String Serial_Number;
      public String Apttus_QPConfig_StartDate;
      public String Apttus_QPConfig_EndDate;
      public String Project_Id;
      public String Attempted_Beadtypes;
      public String Add_On_Attempted_Beadtypes;
      public String Beadchip_Part_Number;
      public String Customer_Product_Name;
      public String Species_Name;
      public String Species_Category;
      public String Reason_For_Rejection;
      public String Apttus_QPConfig_AdjustmentType;
      public String Apttus_QPConfig_AdjustmentAmount;
      public String Customer_Price_Per_Unit;
      public String Distributor_Rebate;
      public list<Promotion> Promotion;


          
     /*
         * @Author: Kushagra Desai
         * @Description : Once the values are mapped  to the variables then getSobject is method is used for mapping the variables with the fields in the Apttus_Proposal__Proposal_Line_Item__c object 
         * @return Apttus_Proposal__Proposal_Line_Item__c record
        */
     public Apttus_Proposal__Proposal_Line_Item__c getSobject(){
     
      UtilsRest utilRest = new UtilsRest();
        Apttus_Proposal__Proposal_Line_Item__c QuoteList= new Apttus_Proposal__Proposal_Line_Item__c(
                                                                //ERP_Line_Number__c = this.ERP_Line_number,
                                                                Apttus_QPConfig__Quantity2__c = nullChecker(this.Apttus_Proposal_Quantity) ? utilRest.stringToDecimalConversion(this.Apttus_Proposal_Quantity):null,
                                                                CurrencyIsoCode = this.CurrencyIsoCode,
                                                                Total_Item_Discount__c = nullChecker(this.Total_Item_Discount) ? utilRest.stringToDecimalConversion(this.Total_Item_Discount):null,
                                                                Total_Item_Discount_USD__c = nullChecker(this.Total_Item_Discount_USD) ? utilRest.stringToDecimalConversion(this.Total_Item_Discount_USD):null,
                                                                Stacked_Discount_Percentage__c = nullChecker(this.Stacked_Discount_Percentage) ? utilRest.stringToDecimalConversion(this.Stacked_Discount_Percentage):null,
                                                                Stacked_Discount_Amount__c = nullChecker(this.Stacked_Discount_Amount) ? utilRest.stringToDecimalConversion(this.Stacked_Discount_Amount):null,
                                                                Distributor_Discount_Percentage__c = nullChecker(this.Distributor_Discount_Percentage) ? utilRest.stringToDecimalConversion(this.Distributor_Discount_Percentage):null,
                                                                Distributor_Discount_Amount__c = nullChecker(this.Distributor_Discount_Amount) ? utilRest.stringToDecimalConversion(this.Distributor_Discount_Amount):null,
                                                            
                                                                Discounted_Price_Per_Unit__c = nullChecker(this.Discounted_Price_Per_Unit) ? utilRest.stringToDecimalConversion(this.Discounted_Price_Per_Unit):null,
                                                                Apttus_QPConfig__NetPrice__c = nullChecker(this.Apttus_QPConfig_NetPrice) ? utilRest.stringToDecimalConversion(this.Apttus_QPConfig_NetPrice):null,
                                                                Freight_Discount_Percentage__c = nullChecker(this.Freight_Discount_Percentage) ? utilRest.stringToDecimalConversion(this.Freight_Discount_Percentage):null,
                                                                Freight_Discount_Amount__c = nullChecker(this.Freight_Discount_Amount) ? utilRest.stringToDecimalConversion(this.Freight_Discount_Amount):null,
                                                                Applied_Discount_Percentage__c = nullChecker(this.Applied_Discount_Percentage) ? utilRest.stringToDecimalConversion(this.Applied_Discount_Percentage):null,
                                                                Applied_Discount_Amount__c = nullChecker(this.Applied_Discount_Amount) ? utilRest.stringToDecimalConversion(this.Applied_Discount_Amount):null,
                                                                Serial_Number__c = this.Serial_Number,
                                                                Apttus_QPConfig__StartDate__c = nullChecker(this.Apttus_QPConfig_StartDate) ? stringTODateFormatConversion(this.Apttus_QPConfig_StartDate):null,
                                                                Apttus_QPConfig__EndDate__c = nullChecker(this.Apttus_QPConfig_EndDate) ? stringTODateFormatConversion(this.Apttus_QPConfig_EndDate):null,
                                                                Project_Id__c = this.Project_Id,
                                                                Attempted_Beadtypes__c = this.Attempted_Beadtypes,
                                                                Add_On_Attempted_Beadtypes__c = this.Add_On_Attempted_Beadtypes,
                                                                Apttus_QPConfig__ListPrice__c  = nullChecker(this.Apttus_QPConfig_ListPrice) ? utilRest.stringToDecimalConversion(this.Apttus_QPConfig_ListPrice):null,
                                                                Applied_Discount_Details__c = this.Applied_Discount_Details,
                                                                Beadchip_Part_Number__c = this.Beadchip_Part_Number,
                                                                Customer_Product_Name__c = this.Customer_Product_Name,
                                                                Species_Name__c = this.Species_Name,
                                                                Species_Category__c = this.Species_Category,
                                                                Reason_For_Rejection__c = this.Reason_For_Rejection,
                                                                Apttus_QPConfig__AdjustmentAmount__c = nullChecker(this.Apttus_QPConfig_AdjustmentAmount) ? utilRest.stringToDecimalConversion(this.Apttus_QPConfig_AdjustmentAmount):null,
                                                                Customer_Price_Per_Unit__c = nullChecker(this.Customer_Price_Per_Unit) ? utilRest.stringToDecimalConversion(this.Customer_Price_Per_Unit):null,
                                                                Customer_Net_Price__c = nullChecker(this.Customer_Net_Price) ? utilRest.stringToDecimalConversion(this.Customer_Net_Price):null,
                                                                Distributor_Rebate__c = nullChecker(this.Distributor_Rebate) ? utilRest.stringToDecimalConversion(this.Distributor_Rebate):null,
                                                                //INC0399426 fix
                                                                List_Price__c = nullChecker(this.Apttus_QPConfig_ListPrice) ? utilRest.stringToDecimalConversion(this.Apttus_QPConfig_ListPrice):null
                                                              );
     if(this.Apttus_QPConfig_AdjustmentType == STRING_A){
      QuoteList.Apttus_QPConfig__AdjustmentType__c = '% Discount';
    }
    else if(this.Apttus_QPConfig_AdjustmentType == STRING_N){
      QuoteList.Apttus_QPConfig__AdjustmentType__c = 'Discount Amount';
    }
     return QuoteList;
    }
    }

/*
 * @Author: Kushagra Desai
 * @Description : promotion class with data
 * @param: NA
 * @return: NA
 */
public class Promotion{
    public String PromotionCode;
    public string PromotionCodeName;
    public string Promo_T_C;
    public string Promo_Channel;
    }

    
}