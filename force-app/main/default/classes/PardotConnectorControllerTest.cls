/**
*    @author: Pankaj 
*    @date:   16-Jan-2019
*    @description:  Test Class for PardotConnectorControllerTest
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        24-Aug-2020        Initial Development
*             Rishab                        30-Sep-2022        Added testResetCNContactMeFieldLead, testResetCNContactMeFieldContact
*          Deep Diwakar                    March-22-2023       DCP-59738: Added test methods for this story
     ------------------------------------------------------------------------------------ 
*                    
*/
@isTest 
public class PardotConnectorControllerTest {
    static testmethod void testPardotConnectionForLead(){
        Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
        Charket__WeChatFollower__c follower=new Charket__WeChatFollower__c();
        follower.Charket__Lead__c=ld.id;        
        insert follower;
        //ApexPages.currentPage().getParameters().put('email','test@gmail.com') ;
        ApexPages.currentPage().getParameters().put('redirecturl', 'test.salesforce.com');
        ApexPages.currentPage().getParameters().put('followerId', follower.id);
        
            
        PardotConnectorController obj=new PardotConnectorController();
        obj.redirectURL();
        
    }
    
    static testmethod void testPardotConnectionForContact(){
        Contact con=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
        Charket__WeChatFollower__c follower=new Charket__WeChatFollower__c();
        follower.Charket__Contact__c=con.Id;
        insert follower;
        ApexPages.currentPage().getParameters().put('redirecturl', 'test.salesforce.com');
        ApexPages.currentPage().getParameters().put('followerId', follower.id);
        PardotConnectorController obj=new PardotConnectorController();
        System.debug('Constructor variable - ' + obj);
        
    }
    static testmethod void testPardotConnectionForErrors(){
        ApexPages.currentPage().getParameters().put('redirecturl', 'test.salesforce.com');
        ApexPages.currentPage().getParameters().put('email', 'test.salesforce.com');
        PardotConnectorController obj=new PardotConnectorController();
        obj.redirectURL();
    }
	
	/*
    *  Description: Test method to cover PardotConnectorController
    */
	static testmethod void testResetCNContactMeFieldLead(){
        Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
        Charket__WeChatFollower__c follower=new Charket__WeChatFollower__c();
        follower.Charket__Lead__c=ld.id;
        ld.CN_Contact_Me__c=true;
        update ld;       
        insert follower;
        ApexPages.currentPage().getParameters().put('redirecturl', 'test.salesforce.com');
        ApexPages.currentPage().getParameters().put('followerId', follower.id);
        Test.startTest();
        PardotConnectorController pardotConnCtrl=new PardotConnectorController();        
        pardotConnCtrl.redirectURL();
        Lead updatedLead = [Select Id, CN_Contact_Me__c from Lead where id =: ld.Id];
        System.assert(!updatedLead.CN_Contact_Me__c, 'Lead CN_Contact_Me field has been reset to false');
        Test.stopTest();
    }
	
	/*
    *  Description: Test method to cover PardotConnectorController
    */
    static testmethod void testResetCNContactMeFieldContact(){
        Contact con=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
        Charket__WeChatFollower__c follower=new Charket__WeChatFollower__c();
        follower.Charket__Contact__c=con.id;
        con.CN_Contact_Me__c=true;
        update con;       
        insert follower;
        ApexPages.currentPage().getParameters().put('redirecturl', 'test.salesforce.com');
        ApexPages.currentPage().getParameters().put('followerId', follower.id);
        Test.startTest();
        PardotConnectorController pardotConnCtrl=new PardotConnectorController();        
        pardotConnCtrl.redirectURL();
        Contact updatedContact = [Select Id, CN_Contact_Me__c from Contact where id =: con.id];
        System.assert(!updatedContact.CN_Contact_Me__c, 'Contact CN_Contact_Me field has been reset to false');
        Test.stopTest();
    }
    
    /**
     * @author     : Deep Diwakar
     * @param      : None
     * @return     : void
     * @Description: DCP-59580 - method for testing Charket Lead form submission with NA values as firstname and lastname with existing
     *                           lead record
    **/
    @isTest
    static void testNALeadSubmitExistingLead() {

        Lead existingLead = TestDataMarketing.createLead('Existing','Lead','na_form_submission@testing.com','China','testCompany');
        Lead incomingLead =TestDataMarketing.createLead('N/A','N/A','na_form_submission@testing.com','China','testCompany');
        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c();
        follower.Charket__Lead__c=incomingLead.Id;        
        insert follower;

        ApexPages.currentPage().getParameters().put('redirecturl', 'test.salesforce.com');
        ApexPages.currentPage().getParameters().put('followerId', follower.id);
        
        Test.startTest();
        PardotConnectorController controller = new PardotConnectorController();
        controller.redirectURL();
        Test.stopTest();

        System.assertEquals(existingLead.FirstName, controller.FirstName, 'Existing lead firstname and lastname did not replace incoming lead NA values');

    }

    /**
     * @author     : Deep Diwakar
     * @param      : None
     * @return     : void
     * @Description: DCP-59580 - method for testing Charket Lead form submission with NA values as firstname and lastname with existing
     *                           contact record
    **/
    @isTest
    static void testNALeadSubmitExistingContact() {

        Contact existingContact = TestDataMarketing.createContact('Existing','Lead','na_form_submission@testing.com');
        Lead incomingLead =TestDataMarketing.createLead('N/A','N/A','na_form_submission@testing.com','China','testCompany');
        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c();
        follower.Charket__Lead__c=incomingLead.Id;        
        insert follower;

        ApexPages.currentPage().getParameters().put('redirecturl', 'test.salesforce.com');
        ApexPages.currentPage().getParameters().put('followerId', follower.id);
        
        Test.startTest();
        PardotConnectorController controller = new PardotConnectorController();
        controller.redirectURL();
        Test.stopTest();

        System.assertEquals(existingContact.FirstName, controller.FirstName, 'Existing contact firstname and lastname did not replace incoming lead NA values');

    }
}