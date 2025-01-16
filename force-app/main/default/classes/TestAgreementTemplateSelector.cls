/*@ author       : Digvijay
* @ date         : 15-05-2020
* @ Description  : Test class for AgreementTemplateSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Digviijay          10-04-2018                 US-33468             Initial version
* Vishal Reddy       6-10-2022                                       Code coverage
* 
*/
@IsTest(SeeAllData=false)
global with sharing class TestAgreementTemplateSelector{
    
	/**
     *  @author - Digvijay 
     *  @description - to test AgreementTemplateSelector
     **/
    @IsTest
    public static void testUserSelection(){

         TestDataFieldService.createUser('System Administrator',true);
        List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name = 'System Administrator'
                                AND IsActive = TRUE
                                LIMIT 1]; 
    
     if(!lstUsers.isEmpty()){
        System.runAs(lstUsers[0]){
        echosign_dev1__Agreement_Template__c temp=new echosign_dev1__Agreement_Template__c(name='DCIR Form Self Sign Template');
        insert temp;
        Test.startTest();
        new AgreementsSelector().selectAgreements(new Set<Id>{temp.id});
    
        
        List<echosign_dev1__Agreement_Template__c> templist=  AgreementTemplateSelector.selectAgreementTemplatebyName('DCIR Form Self Sign Template');
        System.assert(templist[0].Id!=null);
        Test.stopTest();
       }
     }

    
    
     
     
    }

    /**
     *  @author - Vishal Reddy
     *  @description - raises exception
     **/

    @IsTest
    public static void testUserSelectionCatchException(){
     TestDataFieldService.createUser('System Administrator',true);
        List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name = 'System Administrator'
                                AND IsActive = TRUE
                                LIMIT 1]; 
     if(!lstUsers.isEmpty()){
     System.runAs(lstUsers[0]){
     echosign_dev1__Agreement_Template__c temp=new echosign_dev1__Agreement_Template__c(name='DCIR Form Self Sign Template');
     insert temp;
     Test.startTest();
     new AgreementsSelector().selectAgreements(new Set<Id>{temp.id});
     try{
     AgreementTemplateSelector.catchException = true;
     AgreementTemplateSelector.selectAgreementTemplatebyName('DCIR Form Self Sign Template');
     System.assert(!AgreementTemplateSelector.catchException, 'catchException is still true');
     }
     catch(Exception e){
      System.debug('Error : '+e.getMessage());
     }
     Test.stopTest();
     }
    }

    }
}