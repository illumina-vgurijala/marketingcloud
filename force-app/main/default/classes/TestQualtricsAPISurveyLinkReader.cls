/* @ author      : Vaibhav
* @ date         : 15 Jun 2021
* @ Description  : TestQualtricsAPISurveyLinkReader is the test class for the QualtricsAPISurveyLinkReader
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav               15 Jun 2021                 DCP-46141        Initial version
* Vineeta				24 Nov 2023					INC0500807		To tet oagination in getQualtricsSurveyLink
*/
@isTest
public with sharing class TestQualtricsAPISurveyLinkReader {
    /*  @author      :Vaibhav
     *  @description :Setup method
     **/
	@TestSetup
    static void setupData()
    {
        Account objAcc = TestDataAccount.getNewAccount();   
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Charket__WeChatAccount__c weChatAcc = new Charket__WeChatAccount__c(Charket__AppId__c='wx5be7c34117b39da9',Name='WeChat Account',Charket__Type__c='Service Account',Charket__WeChatOriginId__c='gh_322a115b01e1');
        insert weChatAcc;
        Charket__WeChatFollower__c weChatFollower= new  Charket__WeChatFollower__c( Charket__WeChatAccount__c=weChatAcc.Id ,Charket__Contact__c=con.id,Charket__IsFollowing__c=true,IsEmailVerified__c=true);
        insert weChatFollower;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'Order';
        cs.Category__c = 'New Order'; 
        cs.Status = 'In Progress';
        cs.SuppliedEmail = 'test@gmail.com.invalid';
        cs.Closed_with_Associated_Codes__c = false;
        cs.origin=cases.STRING_CASE_ORIGIN_WECHAT;
        cs.WeChatFollower__c = weChatFollower.Id;
        cs.status=System.label.CaseStatusReopenedInProgress;
        cs.First_Call_Resolution__c=true;        
        insert cs;        
    }
    /*  @author      :Vineeta Verma
     *  @description :To test Qualtrics API Callout for Survey Link Generation when contact found in First callout response 
    **/
    @isTest
    public static void testQualtricsCallout() {
        StaticResource endpoint = [SELECT Id,Name, Body FROM StaticResource WHERE Name = 'QualtricsSurveyFirstEndpoint' LIMIT 1];
        String qualtricsSurveyFirstEndpoint = endpoint.Body.toString();
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(qualtricsSurveyFirstEndpoint+Label.Qualtrics_Survey_ID,'QuatricsSurveyWIthContactMock');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);
        Case caseObj = [Select Id,Sent_to_Qualtrics__c from Case where SuppliedEmail = 'test@gmail.com.invalid' limit 1];
        caseObj.Sent_to_Qualtrics__c = true;
        Test.StartTest();
        update caseObj;
        Test.StopTest();
        Case caseObjUpdated = [Select Id,Sent_to_Qualtrics__c,Qualtrics_Survey_Link__c from Case where SuppliedEmail = 'test@gmail.com.invalid' limit 1];
        System.assertNotEquals('', caseObjUpdated.Qualtrics_Survey_Link__c, 'Qualtrics Survey Link Generated');
        
    }
    /*  @author      :Vineeta Verma
     *  @description :To test Qualtrics API Callout for Survey Link Generation when contact found in next callout response 
    **/
    @isTest
    public static void testQualtricsCalloutNextPg() {
        Map<String,String> endpoints = new Map<String,String>();
        for(StaticResource endpoint : [SELECT Id,Name, Body FROM StaticResource WHERE Name = 'QualtricsSurveyFirstEndpoint' or Name='QualtricsSurveySecEndpoint' LIMIT 2]){
            endpoints.put(endpoint.Name, endpoint.Body.toString());
        }
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(endpoints.get('QualtricsSurveyFirstEndpoint')+Label.Qualtrics_Survey_ID, 'QualtricsSurveyNoCononFirstMock');
        multimock.setStaticResource(endpoints.get('QualtricsSurveySecEndpoint'),'QuatricsSurveySecondMock');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);
        Case caseObj = [Select Id,Sent_to_Qualtrics__c from Case where SuppliedEmail = 'test@gmail.com.invalid' limit 1];
        caseObj.Sent_to_Qualtrics__c = true;
        Test.StartTest();
        update caseObj;
        Test.StopTest();
        Case caseObjUpdated = [Select Id,Sent_to_Qualtrics__c,Qualtrics_Survey_Link__c from Case where SuppliedEmail = 'test@gmail.com.invalid' limit 1];
        System.assertNotEquals('', caseObjUpdated.Qualtrics_Survey_Link__c, 'Qualtrics Survey Link Generated');
        
    }
    /*  @author      :Vineeta Verma
     *  @description :To test Qualtrics API Callout for Survey Link Generation when no contact found in any callout response 
    **/
     @isTest 
    public static void testQualtricsCalloutNoContact() {
        Map<String,String> endpoints = new Map<String,String>();
        for(StaticResource endpoint : [SELECT Id,Name, Body FROM StaticResource WHERE Name = 'QualtricsSurveyFirstEndpoint' or Name='QualtricsSurveySecEndpoint' LIMIT 2]){
            endpoints.put(endpoint.Name, endpoint.Body.toString());
        }
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(endpoints.get('QualtricsSurveyFirstEndpoint')+Label.Qualtrics_Survey_ID, 'QualtricsSurveyNoCononFirstMock');
        multimock.setStaticResource(endpoints.get('QualtricsSurveySecEndpoint'),'QualtricsSurveyNoCononSecMock');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);
        Case caseObj = [Select Id,Sent_to_Qualtrics__c from Case where SuppliedEmail = 'test@gmail.com.invalid' limit 1];
        caseObj.Sent_to_Qualtrics__c = true;
        Test.StartTest();
        update caseObj;
        Test.StopTest();
        Case caseObjUpdated = [Select Id,Sent_to_Qualtrics__c,Qualtrics_Survey_Link__c from Case where SuppliedEmail = 'test@gmail.com.invalid' limit 1];
        System.assertNotEquals('', caseObjUpdated.Qualtrics_Survey_Link__c, 'Qualtrics Survey Link Generated');
        
    }
}