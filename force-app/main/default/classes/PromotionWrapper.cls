/***************************************************************************************************************************************
 * NAME         : PromotionWrapper
 * DESCRIPTION  : Promotion Data Wrapper 
 * @AUTHOR      : Karthik Rayani
 * @DATE        : 08-Sep-2020  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  Karthik Rayani    08-Sep-2020       DCP-40228-Initial Version.
 *  Rajbabu Boopalan  12-Dec-2024       CMCM-9332 Promo Fiori changes
 ****************************************************************************************************************************************/

Public class PromotionWrapper {

    public String Name;
    public String Promotion_Code;
    public String Expiration_Date;
    public String Effective_Date;
    public String Terms_and_Conditions;
    public String Approval_Required;
    public String Approver;
    public String Change_History;
    public String Country;
    public String Customer_Description;
    public String Distribution_Channel;
    public String Distribution_Channel_Description;
    public String Distributor_Eligible;
    public String Limit_View;
    public String Marketing_Trade_In;
    public String Primary_Product_Line;
    public String Promo_Channel;
    public String Promotion_Channel_Description;
    public String Promotion_Details;
    public String Promotion_Owner;
    public String Redemption_Limit;
    public String Redemption_Method;
    public String Regions;
    public String Rules_Requirements;
    public String Sales_Description;
    public String Sales_Org;
    public String Stackable;
    public String Promo_Type;

    /*
    * @author:Karthik
   */
    public Promotions__c getSobject(PromotionWrapper prw) 
    {
        Promotions__c pr = new Promotions__c();
        pr.Name = prw.Name;
        pr.Promotion_Code__c = prw.Promotion_Code;
        pr.Terms_and_Conditions__c = prw.Terms_and_Conditions;
        if (String.isNotBlank(prw.Expiration_Date))
            pr.Expiration_Date__c = Date.valueOf(prw.Expiration_Date);
        if (String.isNotBlank(prw.Effective_Date))
            pr.Effective_Date__c = Date.valueOf(prw.Effective_Date);
        if (String.isNotBlank(prw.Approval_Required))
            pr.Approval_Required__c = Boolean.valueOf(prw.Approval_Required);
        if(string.isNotBlank(prw.Approver)){
            pr.Approver__c = prw.Approver;
        }
        pr.Change_History__c = prw.Change_History;
        pr.Country__c = prw.Country;
        pr.Customer_Description__c = prw.Customer_Description;
        pr.Distribution_Channel__c = prw.Distribution_Channel;
        pr.Distribution_Channel_Description__c = prw.Distribution_Channel_Description;
        if (String.isNotBlank(prw.Distributor_Eligible))
            pr.Distributor_Eligible__c = Boolean.valueOf(prw.Distributor_Eligible);
        if (String.isNotBlank(prw.Limit_View))
            pr.Limit_View__c = Boolean.valueOf(prw.Limit_View);
        pr.Marketing_Trade_In__c = prw.Marketing_Trade_In;
        pr.Primary_Product_Line__c = prw.Primary_Product_Line;
        pr.Promotion_Channel__c = prw.Promo_Channel;
        pr.Promotion_Channel_Description__c = prw.Promotion_Channel_Description;
        pr.Promotion_Details__c = prw.Promotion_Details;
        if(string.isNotBlank(prw.Promotion_Owner)){
            pr.Promotion_Owner__c = prw.Promotion_Owner;
        }
        pr.Redemption_Limit__c = prw.Redemption_Limit;
        pr.Redemption_Method__c = prw.Redemption_Method;
        pr.Regions__c = prw.Regions;
        pr.Rules_Requirements__c = prw.Rules_Requirements;
        pr.Sales_Description__c = prw.Sales_Description;
        pr.Sales_Org__c = prw.Sales_Org;
        if (String.isNotBlank(prw.Stackable))
            pr.Stackable__c = Boolean.valueOf(prw.Stackable);
        pr.Promo_Type__c = prw.Promo_Type;
        return pr;
    }
    /*
    * @author:Karthik
   */
    public List < Promotions__c > getSobjectList(List < PromotionWrapper > listPromotionWrapper) 
    {
        List < Promotions__c > listPromos = new List < Promotions__c > ();
        for (PromotionWrapper prw: listPromotionWrapper) {
            Promotions__c pr = getSobject(prw);
            
            listPromos.add(pr);
        }
        return listPromos;
    }
}