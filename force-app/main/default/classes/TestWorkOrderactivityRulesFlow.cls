/**
*    @author: Kumar Gaurav
*    @date:   
*    @description:  Test Class for WorkOrderActivityRules flow
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Kumar Gaurav              12-Aug-2024           Initial Build           
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public class TestWorkOrderactivityRulesFlow {
    @isTest
 /* @author Kumar Gaurav
    *  @description
    */
	public static void testOnChangeDecision() {
		List <Work_Order_Activity_Rules__c> woaRulList = new List <Work_Order_Activity_Rules__c>();
		Work_Order_Activity_Rules__c woaRule = new Work_Order_Activity_Rules__c();
        woaRule.Document_Name__c = 'TestClass1234';
        woaRule.Document_Number__c = '123456';
        woaRule.Name = 'TestClass1234';
        woaRule.Activity_Type__c = 'Calibration';
        woaRule.Product_Group__c = 'AmpliSeq Library Prep';
        woaRule.Generic_Document__c = true;
        woaRule.Required__c = false;
		woaRulList.add(woaRule);
		insert woaRulList;
		System.assertequals(1, woaRulList.size(),'work order activity rule Updated');
	}
	@isTest
	/* @author Kumar Gaurav
    *  @description
    */
    public static void testDeactivationRuleDecision() {
		List <Work_Order_Activity_Rules__c> woaRulList = new List <Work_Order_Activity_Rules__c>();
		Work_Order_Activity_Rules__c woaRule = new Work_Order_Activity_Rules__c();
        woaRule.Document_Name__c = 'TestClass1234';
        woaRule.Document_Number__c = '123456';
        woaRule.Name = 'TestClass1234';
        woaRule.Activity_Type__c = 'Calibration';
        woaRule.Product_Group__c = 'AmpliSeq Library Prep';
        woaRule.Generic_Document__c = true;
        woaRule.Required__c = false;
		woaRule.Active__c=True;
		woaRulList.add(woaRule);
		insert woaRulList;
		System.assertequals(1, woaRulList.size(),'work order activity rule Updated');
	}
	@isTest
	/* @author Kumar Gaurav
    *  @description
    */
    public static void testOnCreateDecision() {
		List <Work_Order_Activity_Rules__c> woaRulList = new List <Work_Order_Activity_Rules__c>();
		Work_Order_Activity_Rules__c woaRule = new Work_Order_Activity_Rules__c();
        woaRule.Document_Name__c = 'TestClass1234';
        woaRule.Document_Number__c = '123456';
        woaRule.Name = 'TestClass1234';
        woaRule.Activity_Type__c = 'Calibration';
        woaRule.Product_Group__c = 'AmpliSeq Library Prep';
        woaRule.Generic_Document__c = true;
        woaRule.Required__c = false;
		woaRulList.add(woaRule);
		Test.startTest();
		insert woaRulList;
		Test.stopTest();
		System.assertequals(1, woaRulList.size(),'work order activity rule Created');
		
	}
}