/***************************************************************************************************************************************
* NAME   : TestFlowExceptionLog
* DESCRIPTION  : For Covering the Create Flow Exception log Flow
*    
* @AUTHOR : Abhishek
* @DATE   : 6-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek             6-Oct-2023              Initial Version (CMCM-3462)
****************************************************************************************************************************************/
@isTest
public class TestFlowExceptionLog { 

    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testExceptionMap() {
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('Source','Flow');
        inputs.put('Message','Flow Error');
        inputs.put('CurrentUser',UserInfo.getUserId());
        inputs.put('Workstream','Service');
        Flow.Interview exceptionFlw = new Flow.Interview.Create_Flow_Exception_log(inputs);
        Test.startTest();
        exceptionFlw.start();
        Test.stopTest();
        List<Exception_Log__c> logList = [SELECT Id FROM Exception_Log__c LIMIT 1];
        Assert.isTrue(!logList.isEmpty());        
    }
}