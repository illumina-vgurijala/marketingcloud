/***************************************************************************************************************************************
 * NAME   : TestilibQueueable
 * DESCRIPTION  : TestClass for ilib_Queuable FrameWork
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 09-03-2020  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Digvijay                   09-03-2020           Initial Version
 * Anshaj                     04-20-2022           Added few lines to increase code coverage
  ***************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestilibQueueable {

    static testmethod void testilibQueueable()
    {
		Interface_Log__c ilog = new Interface_Log__c();
		insert ilog;

        Test.StartTest();
        {
			ilib_Queueablethread queueableThread = new ilib_Queueablethread('TestClass');

			queueableThread.logandQueue(new InnerTestQueueable(5), 'InnerTestQueueable', 'Execute');
			queueableThread.logandQueue(new InnerTestQueueable(0), 'InnerTestQueueable', 'Execute');
			ilib_QueueableManager.enqueueJob(queueableThread);

			ilib_Queueablethread queueableThread2 = new ilib_Queueablethread('TestClass', ilog.Id);
			queueableThread2.logandQueue(new InnerTestQueueable(5), 'InnerTestQueueable', 'Execute');
			ilib_QueueableManager.enqueueJob(queueableThread2);
//CMSI-14 Added below code section to increase code coverage, calling out the method updateQueueableLogItems which takes exception as an input.
            ilib_QueueableJobWrapper queueablejobwrapper = new ilib_QueueableJobWrapper(new InnerTestQueueable(5), 'InnerTestWrapper', 'Execute');
            try {
              throw new auraHandledException('Error while Processing data');
            } catch (Exception ex) {
              Queueable_Log_Item__c qLog = ilib_QueueableLogger.updateQueueableLogItems(queueablejobwrapper,  ilog.Id, ex,0.0);
              System.assertEquals('Failed',qLog.Satus__c, 'Status expected should be failed, but it is not');
            }
        }
		Test.StopTest();
    }

	static testmethod void testilibQueueable2()
    {
		Interface_Log__c ilog = new Interface_Log__c();
		insert ilog;
		string strErrorMsg = '';
		try{
        Test.StartTest();
        {
			ilib_Queueablethread queueableThread = new ilib_Queueablethread('TestClass');

			queueableThread.logandQueue(new InnerTestQueueable(5), 'InnerTestQueueable', 'Execute');
			ilib_QueueableManager.throwException = true;
			ilib_QueueableManager.enqueueJob(queueableThread);
        }
		Test.StopTest();
		}
		catch(Exception e){
                strErrorMsg = e.getMessage();
            }
        system.assertequals('Exception for test coverage',strErrorMsg,'Assertion failed');
    }

/**
*    @author        Illumina
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              
*/

    public class InnerTestQueueable implements Queueable
    {
		Integer num;

        public InnerTestQueueable(Integer num)
        {
			this.num = num;
		}
/**
*    @author        Illumina
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              
*/
        public void execute(QueueableContext qc)
        {
			//System.debug('Divide by:' + 1150 / num);

			ilib_Queueablethread queueableThread = new ilib_Queueablethread('InnerTestQueueable');
			queueableThread.logandQueue(new InnerTestQueueablePart2(5), 'InnerTestQueueablePart2', 'Execute');
			ilib_QueueableManager.enqueueJob(queueableThread);
		}
   	}
/**
*    @author        Illumina
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              
*/
    public class InnerTestQueueablePart2 implements Queueable
    {
        Integer num;

        public InnerTestQueueablePart2(Integer num)
        {
            this.num = num;
        }
/**
*    @author        Illumina
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              
*/
        public void execute(QueueableContext qc)
        {
			System.debug('Job Id:' + qc.getJobId());
			//System.debug('Divide by:' + 1150 / num);
       	}
    }

}