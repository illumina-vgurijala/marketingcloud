/**
*    @author Todd Newman
*    @date   2020-05-23
*    @description  DCP-34910 Email Service Handler
*    Modification Log:
*   ----------------------------------------------------------------------------------------------------- 
*    Developer                      Date                Description
*    Todd Newman                 2020-05-23           Initial Version
*    Rishab Wali                 2020-06-22           Check if current transaction is in Sandbox or Prod
*    Nesar Mohan                 2022-04-01           CodeScan Fix - Add code comments
*    ----------------------------------------------------------------------------------------------------                  
*/

global without sharing class IntegrationEmailMessageHandler implements Messaging.InboundEmailHandler {

    public static final String LOG_TITLE = 'IntegrationEmailMessageHandler';

    // names of implementing handlers
    public static final String TEST_HANDLER = 'Test Handler';
    public static String strLargeCartCallback = 'Large Cart Callback';
    public static final String TESTSTRING = '[TEST] ';
    public static final String STREXCEPTION = 'EXCEPTION';

    /*
    *  @Author      : Todd Newman
    *  @Description : global method to handle the inbound email
    *  @Param       : Messaging.InboundEmail, Messaging.InboundEnvelope
    *  @Return      : Messaging.InboundEmailResult
    */

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env)
    {
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.handleInboundEmail()');
        Messaging.InboundEmailResult result;

        try
        {
            // confirm at least one dash exists in the subject
            Integer serviceNameDelimiter = email.subject.indexOf('-');
            if (serviceNameDelimiter == -1)
            {
                throw new IntegrationEmailException(System.Label.UI_Exception_Msg_Invalid_Subject + ' ' + email.subject);
            }

            // process the subject
            // example service names
            //     QuoteCallback-677890
            //     Agreement-12345-E
            // the string before the first dash (ex Agreement) determines the handler
            // the string after the first dash is passed to the handler as a parameter
            String serviceName = email.subject.substring(0, serviceNameDelimiter);
            String serviceParameter = email.subject.substring(serviceNameDelimiter + 1);
            ilib_LogEvent.message(serviceName);
            ilib_LogEvent.message(serviceParameter);

            // get hander for the given service name
            IntegrationEmailProcessor_I handler = handlerFactory(serviceName);
            if (handler == null)
            {
                throw new IntegrationEmailException(System.Label.UI_Service_Invalid + ' ' + serviceName);
            }

            // let handler process the email
            result = handler.process(email, env, serviceParameter);
        }
        catch (Exception e)
        {
            ilib_LogEvent.push(STREXCEPTION);
            ilib_LogEvent.message(e.getMessage().abbreviate(4000));
            ilib_LogEvent.pop();

            ApexExceptions.emit(LOG_TITLE, e);

            result = new Messaging.InboundEmailResult();
            result.success = false;
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return result;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Global interface class to handle the email
    */

    global interface IntegrationEmailProcessor_I {
        Messaging.InboundEmailResult process(Messaging.InboundEmail email, Messaging.InboundEnvelope env, String parameter);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : method to handle the email logic before sending
    *  @Param       : String
    *  @Return      : IntegrationEmailProcessor_I
    */

    private IntegrationEmailProcessor_I handlerFactory(String integrationName)
    {
        Boolean isSandbox = Organizations.isProduction() ? false : true;
        strLargeCartCallback = isSandbox ? TESTSTRING+strLargeCartCallback : strLargeCartCallback;
        
        if(test.isRunningTest()){strLargeCartCallback = TESTSTRING+strLargeCartCallback;}
        
        if (integrationName == strLargeCartCallback)
        {
            return new IntegrationEmailQuoteCallback();
        }

        if (integrationName == TEST_HANDLER)
        {
            return new TestMessageHandler();
        }

        return null;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Custom Apex exception class
    */

    public class IntegrationEmailException extends Exception { }

    /*
    *  @Author      : Todd Newman
    *  @Description : class for unit testing
    */

    public class TestMessageHandler implements IntegrationEmailMessageHandler.IntegrationEmailProcessor_I {

        /*
        *  @Author      : Todd Newman
        *  @Description : InboundEmailResult method for unit testing
        *  @Param       : Messaging.InboundEmail, Messaging.InboundEnvelope, String
        *  @Return      : Messaging.InboundEmailResult
        */
        
        public Messaging.InboundEmailResult process(Messaging.InboundEmail email, Messaging.InboundEnvelope env, String parameter)
        {
            Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
            result.success = true;
            return result;
        }

    }

}