/**
 * @author Roopal Verma
 * @date   2020-01-16
 * @description    Campaign Member sync with DCP
 * Modification Log:
 *       -------------------------
 *
 * Roopal Verma         16/01/2020          Original Version
 * Himanshu             31/03/2022          Code Scan Fixes    
 **/
public class FreeTrialCreateWrapper{
    /**
     * @author Roopal Verma
     * @date   2020-01-16
     * @description    wrapper that has attributes that are mapped to CampaignMember
     */
    public class CampaignMemberWrapper{
        public string Free_Trial_Start_Date;
        public string Free_Trial_iCredit_Balance;
        public String Free_Trial_End_Date;
        public String Free_Trial_Subscription_ID;
        public String Zuora_Product_Id;
        public String PGUID;
        public String Subscription_Status;
        /**
         * @author Roopal Verma
         * @date   2020-01-16
         * @description    method to map CampaignMember fields to above attributes
         * @params null
         * @return CampaignMember
        */
        public CampaignMember getSobject(){
        
            UtilsRest utilRest = new UtilsRest();
            CampaignMember campMemberObj = new CampaignMember();
            campMemberObj.Free_Trial_Start_Date__c = Date.valueOf(this.Free_Trial_Start_Date);
            campMemberObj.Free_Trial_iCredit_Balance__c = utilRest.stringToDecimalConversion(this.Free_Trial_iCredit_Balance);
            campMemberObj.Free_Trial_End_Date__c= Date.valueOf(this.Free_Trial_End_Date);
            campMemberObj.Free_Trial_Subscription_ID__c= this.Free_Trial_Subscription_ID;
            campMemberObj.Subscription_Status__c = this.Subscription_Status;
            return campMemberObj;
        }       
    }

}