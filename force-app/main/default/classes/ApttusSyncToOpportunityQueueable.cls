/**
*    @author Rohan Chandarana
*    @date   2018-07-10
*    @description    DCP-6178: Sync Quote To Opportunity
*    Modification Log:
*    Test Class for 75% coverage : TestApttusProposals
*    Test Class for 90% coverage : TestApttusProposals
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rohan                       2018-07-10
*         Satya Swain                 2020-10-15             Adding Logic to send email for sync failures as part of INC0281082
*         Koustubh M                  2021-11-22             TASK0673753 : make email address in cc dynamic for quote to opportunity sync failure email
*         Ashwin Kumar                2022-02-28             INC0379842 Assign default value to avoid null exception
*         Aman Tyagi                  2022-03-31             Codescan Fixes
*         Anshaj Sinha                2022-08-22             CMSI-199 : Added Instrumentation Methods PS Logging Framework
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApttusSyncToOpportunityQueueable implements Queueable {
  private static final String LOG_TITLE = 'ApttusSyncToOpportunityQueueable';//CMSI-199
  private static final String STROBJPROPOSAL = 'objProposal : '; //CMSI-199
  private static final String STREMAILMSG = 'ApttusSyncToOpportunityQueueable.sendEmailForFailureNotification,';//CMSI-199
  private Set<Id> setProposalIds = new Set<Id>();
  Boolean boolSyncResult = false;     //INC0379842
  public static Boolean boolSendEmail = false;
  public static final String STRING_CODE_QUO_OPP_EMAIL_FAILURE_SETTING = 'Quote_to_Opportunity_Sync_Failure_Email'; //Koustubh 22nd Nov 2021 TASK0673753 - Record of custom setting that holds details of quote to opportunity sync failure email 
  private Map<String, String> mapEmailFailureSettings; //Koustubh 22nd Nov 2021 TASK0673753 - Map that holds custom setting details (quote to opportunity sync failure email )
  public static final String STRING_MAP_KEY_EMAILRECIPIENTS = 'emailRecipients'; //Koustubh 22nd Nov 2021 TASK0673753 - email recipients stored in custom setting (quote to opportunity sync failure email )
  public static final String STRING_MAP_KEY_EMAIL_SETTING = 'emailSetting'; //Koustubh 22nd Nov 2021 TASK0673753 - email On Off flag stored in custom setting (quote to opportunity sync failure email )
  public static final Integer INTEGER_ACTIVATE_SYNC_FAILURE_EMAIL = 1; //Koustubh 22nd Nov 2021 TASK0673753 - Send email only if the value in custom setting is 1

  /*
  * @Author: Rohan
  * @Description : parameterized constructor of class ApttusSyncToOpportunityQueueable and instantiating Id
  * @param : Set<Id> setProposalIds
  */ 
  public ApttusSyncToOpportunityQueueable(Set<Id> setProposalIds){
    this.setProposalIds = setProposalIds;
  }

  /*
  * @Author: Rohan
  * @Description : execute method based on queueable context
  * @param : QueueableContext context
  * @return: void
  */
  public void execute(QueueableContext context){
    ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);//CMSI-199
    ilib_LogEvent.push(LOG_TITLE +'.execute()');//CMSI-199
    //Sync Quote To Opportunity and Invoke Queue again if more quotes left
    if(!setProposalIds.isEmpty()){
      Id idProposal = (new list<Id>(setProposalIds))[0];
      List<Apttus_Proposal__Proposal__c> lstProposal = new ApttusProposalsSelector().selectById(new Set<Id>{idProposal});
      Apttus_Proposal__Proposal__c objProposal = lstProposal.get(0);
      if(!String.isEmpty(objProposal.Apttus_Proposal__Opportunity__c) && objProposal.Apttus_Proposal__Primary__c)
      {
        List<OpportunityLineItem> lstOpportunityLines = new OpportunityLineItemsSelector().selectOpportunityLineItems(new Set<Id>{objProposal.Apttus_Proposal__Opportunity__c});
        for(OpportunityLineItem oli: lstOpportunityLines){
          ilib_LogEvent.message('OLI Id : '+oli.Id);//CMSI-199
          oli.By_Pass_Sync_To_Opportunity__c = true;
          ilib_LogEvent.message('oli.By_Pass_Sync_To_Opportunity__c = true');//CMSI-199
        }
        if(!lstOpportunityLines.isEmpty()) update lstOpportunityLines;
        // added by Satya as part of INC0281082
        syncPrimaryQuoteToOpportunity(objProposal); 
      }  
      setProposalIds.remove(idProposal);
    }
        
    if(!setProposalIds.isEmpty())
    {
      //Updated - Using ilib_QueueableManager Interface
      ApttusSyncToOpportunityQueueable queueableClassInstance = new ApttusSyncToOpportunityQueueable(setProposalIds);
      ilib_Queueablethread queueableThread = new ilib_Queueablethread('AfterUpdateProposals');
      queueableThread.logAndQueue(queueableClassInstance, 'ApttusSyncToOpportunityQueueable', 'execute');
      ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
    }
    ilib_LogEvent.pop();//CMSI-199
    ilib_LogEvent.emit();//CMSI-199
  }
  /**
   * @author Satya Swain
   * @date   2020-10-15
   * @description INC0281082 : sync primary quote to opportunity
   * @modification TASK0673753 : make email address in cc dynamic for quote to opportunity sync failure email
   * @param idProposal Quotation Id
   **/ 
  public void syncPrimaryQuoteToOpportunity(Apttus_Proposal__Proposal__c objProposal)
  {
    ilib_LogEvent.push(LOG_TITLE + '.syncPrimaryQuoteToOpportunity()');//CMSI-199
    ilib_LogEvent.info(STROBJPROPOSAL + objProposal);//CMSI-199
    Apttus_Proposal__ProposalSystemProperties__c proposalSystemProperties = Apttus_Proposal__ProposalSystemProperties__c.getInstance(System.Label.CS_Proposal_System_Properties);
        try{
          // Added by Satya as part of INC0281082
          for(Integer retryCount = 0;retryCount<3;retryCount++)
          {
            boolSyncResult = Apttus_QPConfig.QPConfigWebService.syncWithOpportunity(objProposal.Id, ((proposalSystemProperties != null) ? proposalSystemProperties.Apttus_QPConfig__SyncOptionProducts__c : false)); 
            ilib_LogEvent.message('boolSyncResult : '+boolSyncResult);//CMSI-199
            if(boolSyncResult)
              break;
          }
        }
        catch(Exception e)
        {
          ilib_LogEvent.error('Inside catch of queueable, value of Exception : '+e.getMessage());//CMSI-199
          boolSyncResult = false;
          ApexExceptions.emit('ApttusSyncToOpportunityQueueable',objProposal.Id, e, ilib_LogEvent.SALES);
        }
        finally{
          if(!boolSyncResult || boolSendEmail){
            if(isEmailEnabled()) //Koustubh 22nd Nov 2021 TASK0673753 - Send email if email is enabled
            {
              sendEmailForFailureNotification(objProposal); //Koustubh 22nd Nov 2021 TASK0673753 - call function that sends email
            }
          }
        }
        ilib_LogEvent.pop();//CMSI-199
  }

  /**
   * @author Satya Swain
   * @date   2020-10-15
   * @description INC0281082 : send email to running user when Sync to Opportunity fails
   * @modification TASK0673753 : make email address in cc dynamic for quote to opportunity sync failure email
   * @param Apttus_Proposal__Proposal__c objProposal
   **/ 
  public void sendEmailForFailureNotification(Apttus_Proposal__Proposal__c objProposal)
  {
    ilib_LogEvent.push(LOG_TITLE + '.sendEmailForFailureNotification()');//CMSI-199
    ilib_LogEvent.info(STROBJPROPOSAL + objProposal);//CMSI-199
    List<String> lstCcAddresses = getCcEmailAddresses();
    String strEmailBody = 'Hi '+UserInfo.getName()+',\n\n'+ objProposal.Name+' failed to sync to Opportunity. \n\nPlease contact GIS for assistance.';
    ilib_LogEvent.info('strEmailBody : '+strEmailBody);//CMSI-199
    Messaging.SingleEmailMessage objSingleEmailMessage = new Messaging.SingleEmailMessage();
    objSingleEmailMessage.setTargetObjectId(UserInfo.getUserId());
    objSingleEmailMessage.setSubject(objProposal.Name + ' sync to opportunity failed');
    objSingleEmailMessage.setPlainTextBody(strEmailBody);
    objSingleEmailMessage.setSaveAsActivity(false);
    objSingleEmailMessage.setCcAddresses(lstCcAddresses);
    List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { objSingleEmailMessage });

    logEmailFailures(results);
    ilib_LogEvent.pop();//CMSI-199
  }

  /**
   * @author Koustubh M
   * @date   2021-11-22
   * @description TASK0673753 : make email address in cc dynamic for quote to opportunity sync failure email
  **/
  public Map<String, String> getQuotetoOppSyncFailureEmailSetting()
  {
    ilib_LogEvent.push(LOG_TITLE + '.getQuotetoOppSyncFailureEmailSetting()');//CMSI-199
    if (mapEmailFailureSettings == null)
    {
      mapEmailFailureSettings = UtilsSettings.getCustomMetadataMap(STRING_CODE_QUO_OPP_EMAIL_FAILURE_SETTING); //Koustubh 22nd Nov 2021 TASK0673753 - extract record from custom metadata 'Code_Parameter__mdt'
    }
    ilib_LogEvent.info('mapEmailFailureSettings : '+mapEmailFailureSettings);//CMSI-199
    ilib_LogEvent.pop();//CMSI-199
    return mapEmailFailureSettings;
  }

  /**
   * @author Koustubh M
   * @date   2021-11-22
   * @description TASK0673753 : returns true email is enabled. False if disabled.
  **/
  public Boolean isEmailEnabled(){
    ilib_LogEvent.push(LOG_TITLE + '.isEmailEnabled()');//CMSI-199
    String strSetting = Test.isRunningTest() ? '1' : getQuotetoOppSyncFailureEmailSetting().get(STRING_MAP_KEY_EMAIL_SETTING); //Koustubh 22nd Nov 2021 TASK0673753 - Always send email for test class. Otherwise extract the emailSetting flag which is used to turn email On (1) and Off (0)
    Integer intSetting = String.isNotBlank(strSetting) ? Integer.valueOf(strSetting) : 0; //Koustubh 22nd Nov 2021 TASK0673753 - If emailSetting flag exists, convert it to integer. Otherwise set 0 (no email)      
    ilib_LogEvent.pop();//CMSI-199
    return intSetting==INTEGER_ACTIVATE_SYNC_FAILURE_EMAIL?true:false;//Koustubh 22nd Nov 2021 TASK0673753 - If intSetting is 1, return true. Else return false.
  }

  /**
   * @author Koustubh M
   * @date   2021-11-22
   * @description TASK0673753 : returns a list of email address to assign to CC of email
  **/
  public List<String> getCcEmailAddresses(){
    ilib_LogEvent.push(LOG_TITLE + '.getCcEmailAddresses()');//CMSI-199
    String strRawEmailRecipients = getQuotetoOppSyncFailureEmailSetting().get(STRING_MAP_KEY_EMAILRECIPIENTS);  //Koustubh 22nd Nov 2021 TASK0673753 - Get comma separated email recipients
    List<String> lstCcAddresses = new List<String>(); //Koustubh 22nd Nov 2021 TASK0673753 - This variable will hold cc email addresses
    if (!String.isBlank(strRawEmailRecipients)) //Koustubh 22nd Nov 2021 TASK0673753 - check if there are email address in cc
    {
      lstCcAddresses = strRawEmailRecipients.split(',');//Koustubh 22nd Nov 2021 TASK0673753 - split the email address on comma
    }
    ilib_LogEvent.info('lstCcAddresses : '+lstCcAddresses);//CMSI-199
    ilib_LogEvent.pop();//CMSI-199
    return lstCcAddresses;
  }

  /**
   * @author Satya Swain
   * @date   2020-10-15
   * @description INC0281082 : log email errors
   * @param List<Messaging.SendEmailResult> results
   **/
  public void logEmailFailures(List<Messaging.SendEmailResult> results)
  {
    ilib_LogEvent.push(LOG_TITLE + '.logEmailFailures()');//CMSI-199
    if (!results.get(0).isSuccess())
    {
      System.StatusCode statusCode = results.get(0).getErrors()[0].getStatusCode();
      String strErrorMessage = results.get(0).getErrors()[0].getMessage();
      ilib_LogEvent.error(STREMAILMSG + 'status code : '+statusCode);//CMSI-199
      ilib_LogEvent.error(STREMAILMSG + 'strErrorMessage : '+strErrorMessage);//CMSI-199
      ApexExceptions.emit('ApttusSyncToOpportunityQueueable.sendEmailForFailureNotification', strErrorMessage, ilib_LogEvent.SALES);
    }
    ilib_LogEvent.pop();//CMSI-199
  }
}