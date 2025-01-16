/**
*    @author: Rahul Bishnoi
*    @date:   28-July-2021
*    @description:  Queuable class To Reprice Cart
*    @ Test class Coverage: 92% - TestCreateQuoteAutomation.cls
*    @ Test class Coverage : 75% - TestCreateQuoteAutomation.cls
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                 Date                Description
*             Rahul                     28-July-2021        Initial Version
*             Ashwin Kumar              15-Nov-2021         INC0350488: Update Quote when reprice is completed
*             Ashwin Kumar              06-Jan-2022         INC0364337: Added Exception logging
*             Aman Tyagi                31-Mar-2022         Codescan Fixes
*             Adithi Acharya            27-Sept-2022        @92% Test Class :  TestCreateQuoteAutomation.cls
*             Aman Tyagi                12-Dec-2022         CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public without sharing class ApttusUpdatePriceForCart implements Queueable {
    private static final String LOG_TITLE = 'ApttusUpdatePriceForCart';
    private static final String DO_REPRICE = 'doReprice';
    public static Boolean runTestBoolIsPricePending = false; //Test Coverage

    Id idProductConfiguration;

    /*
    * @Author: Rahul Bishnoi
    * @Description : parameterized constructor of class ApttusUpdatePriceForCart and instantiating Id
    * @param : Id idProductConfiguration
    */ 
    public ApttusUpdatePriceForCart(Id idProductConfiguration) {
        this.idProductConfiguration = idProductConfiguration;
    }

    /*
    * @Author: Rahul Bishnoi
    * @Description : execute method based on queueable context
    * @param : QueueableContext context
    * @return: void
    */
    public void execute(QueueableContext context) {
        try {
            Apttus_CpqApi.CPQ.UpdatePriceRequestDO updatePriceRequestDOSO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
            updatePriceRequestDOSO.CartId = idProductConfiguration;
            System.debug('Number of queueables used in this apex code so far: ' + Limits.getQueueableJobs());
            Apttus_CpqApi.CPQ.UpdatePriceResponseDO updatePriceResponseDOSO = Apttus_CpqApi.CPQWebService.updatePriceForCart(updatePriceRequestDOSO);
            Boolean boolIsPricePending = updatePriceResponseDOSO.IsPricePending;
            List<Integer> pendingLineNumbers = updatePriceResponseDOSO.PendingLineNumbers;
            List<Integer> completedLineNumbers = updatePriceResponseDOSO.CompletedLineNumbers;
            System.debug('Number of queueables used in this apex code so far: ' + Limits.getQueueableJobs());
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' boolIsPricePending ' + boolIsPricePending);
            System.debug('PendingLineNumbers in this apex code so far: ' + pendingLineNumbers);
            System.debug('CompletedLineNumbers used in this apex code so far: ' + completedLineNumbers);

            if(boolIsPricePending || runTestBoolIsPricePending) {
                ilib_Queueablethread queueableThread = new ilib_Queueablethread(DO_REPRICE);
                queueableThread.logAndQueue(new ApttusUpdatePriceForCart(idProductConfiguration), LOG_TITLE, 'execute');
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
            } else {                    //INC0350488
                updateRepriceFlagOnQuote(idProductConfiguration);
            }
        } catch (Exception ex) { updateRepriceFlagOnQuote(idProductConfiguration);
            ApexExceptions.emit(LOG_TITLE, idProductConfiguration, ex);     //INC0364337
        }
    }   

    /**
     * @author Ashwin Kumar
     * @date   2022-01-06
     * @description INC0364337 : Update Reprice checkbox in Quote
     * @param idProductConfiguration Configuration Id
     **/ 
    public void updateRepriceFlagOnQuote(Id idProductConfiguration) {
        Apttus_Config2__ProductConfiguration__c objProdConfig = new ApttusProductConfigurationsSelector().fetchCart(idProductConfiguration);
        if (!objProdConfig.Apttus_QPConfig__Proposald__r.Is_Reprice_Completed__c) {
            ApttusProposals.updateRepriceFlagOnQuote(objProdConfig.Apttus_QPConfig__Proposald__c);
        }
    }
}