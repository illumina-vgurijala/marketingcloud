@isTest
/**
*    @author: Pankaj Singla
*    @date:   09-Sept-2020
*    @description:  Test Class for Promotions
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              09 Sept 2020           Initial Build
              
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class TestPromotions {
     
    /**
     * @author Pankaj Singla
     * @date   2020-09-09
     * @description  Test the insert and update of Promotion Record
     * 
     **/
    static testmethod void testpromotionTrigger(){
        Promotions__c objPromotion=new Promotions__c(Approval_Required__c=true,Change_History__c='test',
         Country__c='India',Name='test',Promotion_Code__c='123');
        insert objPromotion;
        Apttus_Config2__Incentive__c objincentive=[select id,name from Apttus_Config2__Incentive__c 
                                                   where Master_Promotions__c=:objPromotion.Id];
        system.assertEquals(objincentive.Name, objPromotion.Promotion_Code__c);
        objPromotion.Promotion_Code__c='345';
    	update objPromotion;
        
    }
    
    
}