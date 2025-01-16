/**
*    @author Satya Swain
*    @date   2021-03-31
*    @description   TASK0578653 : Scheduled Batch To Activate Orders
*    Test classes for 75%: TestScheduledBatchActivateOrders
*    Test Classes for 90%: TestScheduledBatchActivateOrders
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Satya Swain                 2021-03-31             Initial Version
*         Satya Swain                 2021-04-16             TASK0585742 : Adding ability to activate previously inactive asset line items
*         Ashwin                      2022-01-17             TASK0699567: Updated Exception logging method signature to include list of processed records to capture Ids
*         Vishal Reddy                2022-08-30             CMSI-217 Instrumentation
*         Koustubh M                  2022-03-28             TASK0730598: Used header level asset activation 
*    -----------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ScheduledBatchActivateOrders extends ilib_ScheduleAndBatch implements Database.Stateful
{
    public static final String STRING_MAP_KEY_BATCHSIZE = 'batchSize';
    public static final String STRING_MAP_KEY_EMAILRECIPIENTS = 'emailRecipients';
    public static final String STRING_MAP_KEY_EMAIL_SETTING = 'emailSetting';
    public static final String STRING_CODE_PARAMETER_OLI_SETTING = 'Activate_Order_Line_Item_Setting';
    public static final String STRING_EMPTY_STRING = '';
    public static final String NULLSTR = 'Null';
    List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
    List<Apttus_Config2__OrderLineItem__c> lstOrderLineItemsUpdated = new List<Apttus_Config2__OrderLineItem__c>();
    public Integer intEmailSetting;
    AsyncApexJob job;
    private static Map<String, String> mapOliSettings;
    public static final string LOG_TITLE = 'ScheduledBatchActivateOrders';
    /**
     * @author Satya
     * @description constructor
     **/
    public ScheduledBatchActivateOrders(){}
    /**
     * @author Satya
     * @description parameterized constructor
     **/
    public ScheduledBatchActivateOrders(Integer intEmailSetting) 
    { 
        this.intEmailSetting = intEmailSetting;
    }
    /**
     * @author Satya
     * @description execute method of Scheduler
     **/
    public override void execute(SchedulableContext sc)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE+'.execute()');
        // intBatchSize contains the count for batch size
        // intSetting decides email settings
        // if intSetting = -1, then don't send mail
        // if intSetting = 0, then send email after all batches are processed, i.e. in finish method
        // if intSetting > 0 , then it indicates the number of records which must be processed first after which email should be sent
        // For Example - if intSetting = 20 and there are 100 order line items, then email will be sent 5 times after every 20th OLI processed
        Integer intBatchSize = Test.isRunningTest() ? 2 : Integer.valueOf(getOrderLineActivationSettings().get(STRING_MAP_KEY_BATCHSIZE));
        String strSetting = Test.isRunningTest() ? '1' : getOrderLineActivationSettings().get(STRING_MAP_KEY_EMAIL_SETTING);
        Integer intSetting = String.isNotBlank(strSetting) ? Integer.valueOf(strSetting) : -1;
        ilib_LogEvent.info('intSetting: '+intSetting);
        ilib_LogEvent.info('intBatchSize: '+intBatchSize);
        Database.executeBatch(new ScheduledBatchActivateOrders(intSetting),intBatchSize);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
     * @author Satya
     * @description start method of Batch
     **/
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        //The query gets orders for which order lines are not activated
        String strQuery = 'SELECT Id,Apttus_Config2__Status__c, Apttus_Config2__ActivatedDate__c, Order_Line_Not_Activated__c, No_Of_Order_Lines__c, Sales_Order_Number_Unique__c FROM Apttus_Config2__Order__c WHERE Order_Line_Not_Activated__c > 0';
        
        ilib_LogEvent.info('strQuery: '+strQuery);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return Database.getQueryLocator(strQuery);
    }
    /**
     * @author Satya
     * @description execute method of Batch
     **/
    public override void execute(Database.BatchableContext bc,  List<SObject> scope)
    {
        if(scope.isEmpty()){ return;
        }    

        //Execute batch with size 1 because only one order can be activated at a time. This has been confirmed from Suseel from Conga
        Apttus_Config2__Order__c orderToActivate = (Apttus_Config2__Order__c)scope[0];

        try
        {
            

            //Delete all existing ALIs as new ones are created on activation.
            List<Apttus_Config2__AssetLineItem__c> aliToDelete = new ApttusAssetLineItemsSelector().selectAssetsByContractNumber(orderToActivate.Sales_Order_Number_Unique__c);
            if(!aliToDelete.isEmpty()){
                delete aliToDelete;
            }
            

            //Header level activation does not work without first making Status and Activated Date as null.
            orderToActivate.Apttus_Config2__Status__c=null; 
            orderToActivate.Apttus_Config2__ActivatedDate__c = null;
            update orderToActivate;

            //Below function does header level activation of one order at a time. Suseel from conga confirmed this behaviour. He will have product team confirm the behaviour after capturing subscriber logs
            ApttusOrderDataReceiver.headerLevelActivationOfAssets(orderToActivate);

            List<Apttus_Config2__OrderLineItem__c> oliToActivate = new List<Apttus_Config2__OrderLineItem__c>();
            List<Apttus_Config2__AssetLineItem__c> aliToActivate = new List<Apttus_Config2__AssetLineItem__c>();

            for(Apttus_Config2__OrderLineItem__c oliItem: new ApttusOrderLineItemsSelector().fetchLinesWithInactiveAssetsByIds(new set<Id>{orderToActivate.Id})){
                if(string.isBlank(oliItem.Apttus_Config2__AssetLineItemId__c)){ continue;
                }
                Apttus_Config2__AssetLineItem__c aliItem = new Apttus_Config2__AssetLineItem__c(Id = oliItem.Apttus_Config2__AssetLineItemId__c);
                aliItem.Apttus_Config2__IsInactive__c=false;
                aliItem.Apttus_Config2__AssetStatus__c=Label.OrderLineItemStatusActivated;
                aliToActivate.add(aliItem);
                if(oliItem.Apttus_Config2__Status__c == Label.OrderLineItemStatusFulfilled){
                    oliItem.Apttus_Config2__Status__c = Label.OrderLineItemStatusActivated;
                    oliToActivate.add(oliItem);
                }
            }
            if(!aliToActivate.isEmpty()){update aliToActivate;
            }
            if(!oliToActivate.isEmpty()){update oliToActivate;
            }
        }
        catch(Exception e)
        {
            ApexExceptions.emit(e, 'ScheduledBatchActivateOrders', scope);      //TASK0699567
            if(intEmailSetting>=0){sendEmailNotification(orderToActivate.Sales_Order_Number_Unique__c,e.getMessage());
            }
        }  
    }

    /**
     * @author Satya
     * @description finish method of Batch
     **/
    public override void finish(Database.BatchableContext bc)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE+'.finish()');
        job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
    }
    
    /**
     * @author Satya
     * @description returns map of key value pairs for Order line item settings from metadata
     **/
    public static Map<String, String> getOrderLineActivationSettings()
    {
        ilib_LogEvent.push(LOG_TITLE+'.getOrderLineActivationSettings()');
        if (mapOliSettings == null)
        {
            mapOliSettings = UtilsSettings.getCustomMetadataMap(STRING_CODE_PARAMETER_OLI_SETTING);
        }
        ilib_LogEvent.info('mapOliSettings : '+mapOliSettings);
        ilib_LogEvent.pop();
        return mapOliSettings;
    }
    /**
     * @author Satya
     * @description  method to send email regarding OLI details processed
     **/
    @testVisible
    private void sendEmailNotification(String salesOrderNumber, String exceptionString)
    {
        ilib_LogEvent.push(LOG_TITLE+'.sendEmailNotification()');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
        String strSubject  = 'Order Activation Processing Job';
        if(job != NULL){ strSubject += ' '+ job.Status + ' with '+job.NumberOfErrors+' Errors';
        }
        
        String strRawValue = getOrderLineActivationSettings().get(STRING_MAP_KEY_EMAILRECIPIENTS);
        if (String.isBlank(strRawValue)){ return;
        }
        List<String> toAddresses = strRawValue.split(',');
        mail.setToAddresses(toAddresses);
        mail.setSubject(strSubject);
        String body = 'Hi,<br/>';
        body += 'The order activation failed for order ';
        body += salesOrderNumber;
        body += ' with the following error:<br/>';
        body += exceptionString;
        body += '<br/><br/>Thanks';
        mail.setHtmlBody(body);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { mail });
        ilib_LogEvent.info('mail : '+mail);
        ilib_LogEvent.pop();
    }
}