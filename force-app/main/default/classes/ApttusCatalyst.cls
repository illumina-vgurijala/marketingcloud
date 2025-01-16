/**
*    @author Rahul Sharma
*    @date   2019-04-10
*    @description  Wrapper class for request and response json to catalyst
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Rahul Sharma                 10 Apr 2019          Wrapper for request and response to catalyst
*            Nesar Mohan                  01 Apr 2022          Codescan Fix
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/

public class ApttusCatalyst{

    public static Apttus_Proposal__Proposal__c objQuote;
    public static Map<Id,Apttus_Config2__LineItem__c> mapToCartLine = new Map<Id,Apttus_Config2__LineItem__c>();

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Inner Wrapper class
    */
    public class CustomerItemDetails {
        public String key;
        public String value;
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Inner Wrapper class
    */
    public class QuoteDetails {
            public String quote_line_item_id;
            public List<ApttusCatalyst.CustomerItemDetails> item_details = new List<ApttusCatalyst.CustomerItemDetails>();
            public String discount_percentage;
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Inner virtual class
    */
    public virtual class ApttusCatalystRequest{
        public String request_id;
        public String quotation_id;
        public List<ApttusCatalyst.CustomerItemDetails> customer_details = new List<ApttusCatalyst.CustomerItemDetails>();
        public List<ApttusCatalyst.QuoteDetails> quote_details = new List<ApttusCatalyst.QuoteDetails>();
        public String request_date;
        public String requested_by;
        public String requested_by_system_name;
        
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Inner class extending ApttusCatalystRequest
    */
    public class ApttusCatalystResponse extends ApttusCatalystRequest{
        public String error_message;
        public String error_code;
    }
        
    /*
    *  @Author      : Rahul Sharma
    *  @Description : Method to create JSON based on the parameter type Apttus_Config2__ProductConfiguration__c
    *  @Param       : Apttus_Config2__ProductConfiguration__c
    *  @Return      : String
    */
    public static String createJSON(Apttus_Config2__ProductConfiguration__c objConfig){
        ApttusCatalystRequest catalystRequest = new ApttusCatalystRequest();
        System.debug('Quote number: '+objConfig.Apttus_QPConfig__Proposald__r);
        objQuote = objConfig.Apttus_QPConfig__Proposald__r;
        catalystRequest.request_id = objQuote.Id + '_' + String.valueOf(Datetime.now()) ;
        catalystRequest.quotation_id = objQuote.Id;
        Datetime today = Datetime.now();
        String requestedDate = today.format('MM-dd-YYYY');
        catalystRequest.request_date = requestedDate;
        catalystRequest.requested_by = UserInfo.getUserEmail();
        catalystRequest.requested_by_system_name = Label.Requested_By_System_Name;

        ApttusCatalyst.CustomerItemDetails cd = new ApttusCatalyst.CustomerItemDetails();
        cd.key = Label.Catalyst_Parameter_UC_Number;
        cd.value = objQuote.Ultimate_Consignee_ERP_Number__c;
        catalystRequest.customer_details.add(cd);

        for(Apttus_Config2__LineItem__c objCartLine:objConfig.Apttus_Config2__LineItems__r){
            ApttusCatalyst.QuoteDetails qd = new ApttusCatalyst.QuoteDetails();
            ApttusCatalyst.CustomerItemDetails item1 = new ApttusCatalyst.CustomerItemDetails();
            qd.quote_line_item_id = objCartLine.Id ;
            item1.key = Label.Catalyst_Parameter_Material_Number;
            item1.value = objCartLine.Apttus_Config2__ProductId__r.Material_Number__c;
            ApttusCatalyst.CustomerItemDetails item2 = new ApttusCatalyst.CustomerItemDetails();
            item2.key = Label.Catalyst_Parameter_Service_Start_Date;
            if(objCartLine.Apttus_Config2__StartDate__c!=null)
            {  
                Datetime dt = (DateTime) objCartLine.Apttus_Config2__StartDate__c;
                item2.value = String.valueOf(dt.format('MM-dd-YYYY'));
            }
            ApttusCatalyst.CustomerItemDetails item3 = new ApttusCatalyst.CustomerItemDetails();
            item3.key = Label.Catalyst_Parameter_Service_End_Date; 
            if(objCartLine.Apttus_Config2__EndDate__c!=null)
            {
                Datetime dt = (DateTime) objCartLine.Apttus_Config2__EndDate__c;
                item3.value = String.valueOf(dt.format('MM-dd-YYYY'));
            }
            qd.item_details.add(item1);
            qd.item_details.add(item2);
            qd.item_details.add(item3);
            catalystRequest.quote_details.add(qd);
            mapToCartLine.put(objCartLine.id,objCartLine);
        }

        String pretty = JSON.serialize(catalystRequest);
        System.debug('Catalyst Request JSON'+ pretty);
        return pretty;
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Method to parse JSON based on the Id and String parameters
    *  @Param       : Id and String
    *  @Return      : Boolean
    */
    public static Boolean parserJSON(Id idProductConfiguration, String strResponseJSON){
        Boolean boolError= false;
        System.debug('strResponseJSON'+strResponseJSON);
        Map<String,Object> keyToValue = (Map<String,Object>)JSON.deserializeUntyped(strResponseJSON);
        if(keyToValue!=null && keyToValue.get('is_success')==true){
            ApttusCatalyst.ApttusCatalystResponse objCatResponse= (ApttusCatalyst.ApttusCatalystResponse) JSON.deserialize(JSON.serialize(keyToValue.get('response')),ApttusCatalyst.ApttusCatalystResponse.class);
            if(objCatResponse != null){
                for(ApttusCatalyst.QuoteDetails quoDet:objCatResponse.quote_details){
                    mapToCartLine.get(quoDet.quote_line_item_id).Suggested_Sales_Discount_Percentage__c = (quoDet.discount_percentage) != null ? String.valueOf(Decimal.valueOf(quoDet.discount_percentage).setScale(2,RoundingMode.HALF_UP)) : 'NA';
                    System.debug('Suggested Sales Discount'+mapToCartLine.get(quoDet.quote_line_item_id).Suggested_Sales_Discount_Percentage__c);
                    mapToCartLine.get(quoDet.quote_line_item_id).Suggested_Sales_Discount_Amount__c = mapToCartLine.get(quoDet.quote_line_item_id).Suggested_Sales_Discount_Percentage__c == 'NA' ? 0 : ((mapToCartLine.get(quoDet.quote_line_item_id).Apttus_Config2__ListPrice__c * Decimal.valueOf(mapToCartLine.get(quoDet.quote_line_item_id).Suggested_Sales_Discount_Percentage__c)/100).setScale(2,RoundingMode.HALF_UP));
                }
                System.debug('Value Map:'+mapToCartLine.values());
                update mapToCartLine.values();
            } 
        }
       return boolError;
    }
}