/*
*    @author Nishan Shetty
*    @date   15 November 2021
*    @description  DCP-50448 Class to handle Channel Partner Quota record create or update operation.
*    Test Classes for 75%: TestChannelPartnerQuotaAutomation
*    Test Classes for 90%: TestChannelPartnerQuotaAutomation
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*     Nishan Shetty       15-Nov-2021        Initial
*     Vishal Reddy        30-Aug-2022        CMSI-217 Instrumentation
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
public with sharing class ChannelPartnerQuotaAutomation {
    
  private static final String LOG_TITLE = 'ChannelPartnerQuotaAutomation';
  /**
  @author       : Nishan Shetty
  @description  : Method to upsert Channel Partner Quota Records when Channel Partner Agreement is activated.
  @Test Class   : TestChannelPartnerQuotaAutomation.
  @Param        : Serialized map of AccountId to Agreement.
  @return       : void
  */
  public static void upsertChannelPartnerQuotas(String strAcctIdToAgreement) {
    
    ilib_LogEvent.push(LOG_TITLE + 'upsertChannelPartnerQuotas');
    List<Channel_Partner_Quota__c> lstChannelPartnerQuotas=new List<Channel_Partner_Quota__c>();
    Set<Id> setAccountIds=new Set<Id>();
    Set<String> setYearAndAccountId=new Set<String>();
    Map<Id, Apttus__APTS_Agreement__c> mapAcctIdToAgreement = (Map<Id, Apttus__APTS_Agreement__c>) JSON.deserialize(strAcctIdToAgreement, Map<Id, Apttus__APTS_Agreement__c>.class);
    List<Channel_Partner_Quota__c> lstChannelPartnerRecords = new ChannelPartnerQuotaSelector().getQuotaByAccount(new List<Id>(mapAcctIdToAgreement.keySet()));

    for(Channel_Partner_Quota__c objChannelPartQuota:lstChannelPartnerRecords) {
      String strYearAndAccountId= objChannelPartQuota.Year__c + objChannelPartQuota.Account_Name__c;
      Apttus__APTS_Agreement__c objAgreement=mapAcctIdToAgreement.get(objChannelPartQuota.Account_Name__c);
      if(objAgreement!=null && objChannelPartQuota.Year__c == String.valueOf(objAgreement.Apttus__Contract_Start_Date__c.year()) && !setYearAndAccountId.contains(strYearAndAccountId)) {
        //Mapping of Fields
        objChannelPartQuota.CurrencyIsoCode=objAgreement.CurrencyIsoCode;
        objChannelPartQuota.Account_Name__c=objAgreement.Apttus__Account__c;
        objChannelPartQuota.Name=String.valueOf(objAgreement.Apttus__Contract_Start_Date__c.year());
        objChannelPartQuota.Year__c=String.valueOf(objAgreement.Apttus__Contract_Start_Date__c.year());
        objChannelPartQuota.Quarter_1__c=objAgreement.Q1_Quota__c;
        objChannelPartQuota.Quarter_2__c=objAgreement.Q2_Quota__c;
        objChannelPartQuota.Quarter_3__c=objAgreement.Q3_Quota__c;
        objChannelPartQuota.Quarter_4__c=objAgreement.Q4_Quota__c;
        
        lstChannelPartnerQuotas.add(objChannelPartQuota);
        //Set to Identify Account where there is no Matching Channel Partner Quota Record.
        setAccountIds.add(objChannelPartQuota.Account_Name__c);
        //Set to Identify Latest Record To Modify if there is Duplicate Channel Partner Quota Record.
        setYearAndAccountId.add(strYearAndAccountId);
      }
    }
    
    for(Id accountId:mapAcctIdToAgreement.keySet()) {

      if(!setAccountIds.contains(accountId)) {
        Apttus__APTS_Agreement__c objAgreement=mapAcctIdToAgreement.get(accountId);
        Channel_Partner_Quota__c objChannelPartnerQuotaRec=new Channel_Partner_Quota__c();
        objChannelPartnerQuotaRec.CurrencyIsoCode=objAgreement.CurrencyIsoCode;
        objChannelPartnerQuotaRec.Account_Name__c=objAgreement.Apttus__Account__c;
        objChannelPartnerQuotaRec.Name=String.valueOf(objAgreement.Apttus__Contract_Start_Date__c.year());
        objChannelPartnerQuotaRec.Year__c=String.valueOf(objAgreement.Apttus__Contract_Start_Date__c.year());
        objChannelPartnerQuotaRec.Quarter_1__c=objAgreement.Q1_Quota__c;
        objChannelPartnerQuotaRec.Quarter_2__c=objAgreement.Q2_Quota__c;
        objChannelPartnerQuotaRec.Quarter_3__c=objAgreement.Q3_Quota__c;
        objChannelPartnerQuotaRec.Quarter_4__c=objAgreement.Q4_Quota__c;
        lstChannelPartnerQuotas.add(objChannelPartnerQuotaRec);
      }
    }

    

    if(!lstChannelPartnerQuotas.isEmpty()) {
      try {
        upsert lstChannelPartnerQuotas;
      } catch(Exception e) {
        ApexExceptions.emit('ChannelPartnerQuotaAutomation',e,ilib_LogEvent.SALES);
        ilib_LogEvent.pop(); 
        
      }
    }
    ilib_LogEvent.info('lstChannelPartnerQuotas:'+UtilsCollection.getSetOfIds(lstChannelPartnerQuotas));
    ilib_LogEvent.pop();
    
  }
}