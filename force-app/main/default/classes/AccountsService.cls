/**
*    @author     Saddam 
*    @date       21-March-2022 
*    @description : Handler class for AccountContactRelationship Logic 
New class created to check the related ACR or Contacts Records in Accounts and Accountcontactrelationship domain class, as part of PM-41 and Pm-430 User story
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Saddam                      21-March-2022           Initial version
*             Saddam                      19-APR-22               codescan fixes
*             Saddam                      17-MAy-22               codescan fixes    
*             Himanshu                    21-Nov-22               INC0436156
*             Gerardo Garcia              07-Aug-24               CMCM-9578 - add status populators
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class AccountsService {
    
    private static final String ACR_ROLES_R_Q ='Regulatory/Quality';
    private static final String ACR_PNC_DEFAULT = 'Default (All)';
    //variables for Account
    private static final String ACC_COMPLIANT = 'Compliant';
    private static final String ACC_NOT_APPLICABLE = 'Not Applicable';
    private static final String ACC_NON_COMPLIANT = 'Non Compliant';
   
    private static final String LOG_TITLE = 'AccountsService';

    private static final String ACC_ID_WITH_SINGLE_CONTACT = 'setOfAccIdSingleCon';
    private static final String ACC_ID_WITH_MULTIPLE_CONTACT = 'setOfAccIdMultipleCon';
    private static final String ACC_ID_WITH_RQ_CONTACT = 'setofaccAcrRqContact';
    private static final String ACC_ID_WITHOUT_RQ_CONTACT = 'setofaccAcrNotRqContact';
    private static final String ACC_ID_WITH_MUL_RQ_CONTACT = 'setOfaccmulAcrRqContact';
    private static final String ACC_ID_WITHOUT_MUL_RQ_CONTACT = 'setOfaccmulAcrNotRqContact';
    private static final String ACC_ID_WITHOUT_MUL2_RQ_CONTACT = 'setOfaccmul2AcrNotRqContact';

    public static final String REJECT_CREDIT = 'Credit Block';
    public static final String REJECT_ORDER = 'Order Block';
    public static final String REJECT_DELIVERY = 'Delivery Block';
    public static final String REJECT_BILLING = 'Billing Issue';
    public static final String REJECT_SALES = 'Sales Block';

    public static final Id PROSPECT_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountProspect).getRecordTypeId();
    public static final Id CUSTOMER_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeCustomer).getRecordTypeId();
    public static final Id INDIRECT_PARTNER_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
    public static final Id ILLUMINA_INTERNAL_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIlluminaInternal).getRecordTypeId();
    public static final Id CHANNEL_PARTNER_PROSPECT_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRTChannelPartnerProspect).getRecordTypeId();

    private static final String  ACCOUNTID = 'AccountId'; //codescan fix

    /**
     * @author Saddam
     * @description : PM-41 and PM-430,  Created New Method updateRqAccount() to check the related ACR or Contacts Records in Accounts, Invoked in Accounts and AccountcontactrelationshipService class.
     * Params : Accountids
     * Returns : List<account> 
     **/
    public static List<Account> updateRqAccount(set<Id> accIds) {
        
        ilib_LogEvent.push(LOG_TITLE + '.updateRqAccount()');

        //Final R/Q set of contact/acr ids
        set<id> setofaccAcrRqContact = new set<id>();
        set<id> setofaccAcrNotRqContact= new set<id>();

        //Check if the Account has related contacts or not 
        List<Account> listOfAcc = new AccountsSelector().accountWithRelatedContacts(accIds);
        for(Account acc:listOfAcc) {
            if(acc.Contacts.isempty()) {
                setofaccAcrNotRqContact.add(Acc.id);
            }
        } 
        ilib_LogEvent.message('accountids without contact@@: '+setofaccAcrNotRqContact);

        set<id> setOfAccIdSingleCon = new set<id>();
        set<id> setOfAccIdMultipleCon  = new set<id>();

        //checks and returns the accountid with count of ACR records in a account 
        Map<string,set<id>> mapOfAccIds = new Map<string,set<id>>();
        mapOfAccIds=getACRCounts(accIds);
        ilib_LogEvent.message('mapof ids@@:'+mapOfAccIds);

        setOfAccIdSingleCon = getSetofIdsFromMap(mapOfAccIds,ACC_ID_WITH_SINGLE_CONTACT,setOfAccIdSingleCon);
        setOfAccIdMultipleCon = getSetofIdsFromMap(mapOfAccIds,ACC_ID_WITH_MULTIPLE_CONTACT,setOfAccIdMultipleCon);
        setofaccAcrNotRqContact = getSetofIdsFromMap(mapOfAccIds,ACC_ID_WITHOUT_RQ_CONTACT,setofaccAcrNotRqContact);

        ilib_LogEvent.message('map of ids returned from method  @@: '+mapOfAccIds);
        ilib_LogEvent.message('accountids with inactive contact @@: '+setofaccAcrNotRqContact);
        ilib_LogEvent.message('setOfAccIdSingleCon: '+setOfAccIdSingleCon);
        ilib_LogEvent.message('setOfAccIdMultipleCon: '+setOfAccIdMultipleCon);

        //checks the  R/q requirement and returns the account ids which has single ACR records
        Map<string,set<id>> mapOfSingleACRIds = new  Map<string,set<id>>();
        mapOfSingleACRIds= checkAccWithSingleACR(setOfAccIdSingleCon);
        //
        setofaccAcrRqContact = getSetofIdsFromMap(mapOfSingleACRIds,ACC_ID_WITH_RQ_CONTACT,setofaccAcrRqContact);
        setofaccAcrNotRqContact = getSetofIdsFromMap(mapOfSingleACRIds,ACC_ID_WITHOUT_RQ_CONTACT,setofaccAcrNotRqContact);

        ilib_LogEvent.message('map of single acr ids returned from method @@: '+mapOfSingleACRIds);
        ilib_LogEvent.message('setofaccAcrRqContact: from id singleid pass '+setofaccAcrRqContact);
        ilib_LogEvent.message('setofaccAcrNotRqContact:  from id singleid pass'+setofaccAcrNotRqContact);

        //checks R/q requirement and returns the account ids which has Multiple ACR records
        Map<string,set<id>> mapOFMultipleACRIds = new  Map<string,set<id>>();
        mapOFMultipleACRIds= checkAccWithMultipleACR(setOfAccIdMultipleCon);

        setofaccAcrRqContact = getSetofIdsFromMap(mapOFMultipleACRIds,ACC_ID_WITH_MUL_RQ_CONTACT,setofaccAcrRqContact);
        setofaccAcrNotRqContact = getSetofIdsFromMap(mapOFMultipleACRIds,ACC_ID_WITHOUT_MUL_RQ_CONTACT,setofaccAcrNotRqContact);
        setofaccAcrNotRqContact = getSetofIdsFromMap(mapOFMultipleACRIds,ACC_ID_WITHOUT_MUL2_RQ_CONTACT,setofaccAcrNotRqContact);


        ilib_LogEvent.message('map of multiple acr ids returned from method @@: '+mapOFMultipleACRIds);
        ilib_LogEvent.message('setofaccAcrRqContact: from multiple id pass'+setofaccAcrRqContact);
        ilib_LogEvent.message('setofaccAcrNotRqContact:from multiple id pass '+setofaccAcrNotRqContact);

        //Receives the Account update list from method 
        List<Account> accToUpdate = new List<Account>(getAccUpdateList(setofaccAcrRqContact,setofaccAcrNotRqContact));
        ilib_LogEvent.message('Account update list:'+accToUpdate);

        return accToUpdate;
        
    } 

    /**
     * @author Saddam
     * @description : PM-41 and PM-430,  Created New Method getSetofIdsFromMap(),for adding the ids from map to set based on the key.Codescan fix 
     * Params : map<String,Set<Id>> ,String,accIds.
     * Returns : set<id>
     **/
    public static  set<id> getSetofIdsFromMap(map<String,Set<Id>> mapStrOfIds,String str,Set<Id> accIds) {
  
        if(mapStrOfIds.containsKey(str)) {
            accIds.addAll(mapStrOfIds.get(str));
        }
        ilib_LogEvent.message('Returned account id in getSetofIdsFromMap  @@: '+accIds);

        return accIds;
    }

    /**
     * @author Saddam
     * @description : PM-41 and PM-430,checks and returns the accountid with count of ACR records in a account   
     * Params : Accountids
     * Returns : Map<string,id>
     **/
    public static Map<string,set<id>> getACRCounts(set<Id> accIds) {

        //check Active Contact/Acr records count by passing setofAccids
        ilib_LogEvent.message('accIds: '+accIds);
        List<AggregateResult> accconrelrecords = new AccountContactRelationsSelector().getAcrCountByAccount(accIds);
            ilib_LogEvent.message('accconrelrecords: '+accconrelrecords);
            Map<string,set<id>> mapOfAccIds = new Map<string,set<id>>();
            set<id> setAcctIds = new set<id>();
            set<id> setAcctIdsForMul = new set<id>();
            set<id> setAcctIdsForNoRq = new set<id>();
            ilib_LogEvent.message('set of ids : '+setAcctIds+'map of ids :'+mapOfAccIds);
             for (AggregateResult ar : accconrelrecords) {
                if(ar.get(ACCOUNTID)!=Null && (integer)ar.get('NumberOfRecord')==1 && (Boolean)ar.get('contactIsActive') && (Boolean)ar.get('IsActive')) {
                    mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITH_SINGLE_CONTACT,setAcctIds,(id)ar.get(ACCOUNTID));
                    ilib_LogEvent.message('set of ids count=1 : '+setAcctIds+'map of ids count=1 from :'+mapOfAccIds);
                } else if(ar.get(ACCOUNTID)!=Null && (integer)ar.get('NumberOfRecord')>1 &&  (Boolean)ar.get('contactIsActive') && (Boolean)ar.get('IsActive')) {
                    mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITH_MULTIPLE_CONTACT,setAcctIdsForMul,(id)ar.get(ACCOUNTID));
                    ilib_LogEvent.message('set of ids  count=1 from from  if-else: '+setAcctIdsForMul+'map of ids  count=1 from from  if-else:'+mapOfAccIds);
                } else {
                    mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITHOUT_RQ_CONTACT,setAcctIdsForNoRq,(id)ar.get(ACCOUNTID));
                    ilib_LogEvent.message('set of ids  count=1 from from  else: '+setAcctIdsForNoRq+'map of ids  count=1 from from  else:'+mapOfAccIds);
                 } 
              }
              ilib_LogEvent.message('setOFAccIds getacrcount: '+setAcctIds+'mapOfAccIds getacrcount:'+mapOfAccIds);
              ilib_LogEvent.message('setAcctIdsForMul getacrcount: '+setAcctIdsForMul+'mapOfAccIds getacrcount:'+mapOfAccIds);
              ilib_LogEvent.message('setAcctIdsForNoRq getacrcount: '+setAcctIdsForNoRq+'mapOfAccIds getacrcount:'+mapOfAccIds);

            return mapOfAccIds;
              
    }

    
    /**
     * @author Saddam
     * @description : PM-41 and PM-430,Created New Method getMapOfStringOfIds(),for adding the ids into map with set of ids based on the key and to bulkyfy the code.Codescan fix 
     * Params : map<String,Set<Id>> ,String,accIds set , single account id
     * Returns : Map<string,id>
     **/
    public static  map<String,Set<Id>> getMapOfStringOfIds(map<String,Set<Id>> mapOfAccIds,String str,Set<Id> setAcctIds, Id accountId) {
        
        Set<Id> setOfAccountids = setAcctIds;

        if(!mapOfAccIds.isEmpty() && mapOfAccIds.containsKey(str)){   
            setOfAccountids=mapOfAccIds.get(str);
            setOfAccountids.add(accountId); 
            mapOfAccIds.put(str,setOfAccountids); 
        } else{
            setOfAccountids.add(accountId);
            mapOfAccIds.put(str,setOfAccountids);
        }
        ilib_LogEvent.message('Returned map of id with string in getMapOfStringOfIds  @@: '+mapOfAccIds);
        return mapOfAccIds;
    }

    /**
     * @author Saddam
     * @description : PM-41 and PM-430,checks R/q requirement and returns the account ids which has single ACR records
     * Params : Accountids
     * Returns : Map<string,id>
     **/
    public static Map<string,set<id>> checkAccWithSingleACR(set<Id> setOfAccIdSingleCon) {

        ilib_LogEvent.message('setOfAccIdSingleCon: '+setOfAccIdSingleCon);
        //check if Account has single R/q Acr or not
        List<AccountContactRelation> listofAccConRel = new AccountContactRelationsSelector().getAcrWithContactByAccount(setOfAccIdSingleCon);
        ilib_LogEvent.message('listofAccConRel: '+listofAccConRel);
        Map<string,set<id>> mapOfAccIds = new Map<string,set<id>>();
        set<id> setAcctIds = new set<id>();
        set<id> setAcctIdsForZeroRq = new set<id>();
        if(listofAccConRel!=NUll && !listofAccConRel.isEmpty()) {
            for (AccountContactRelation accConRelObj : listofAccConRel) {
                if(accConRelObj.Product_Notifications_Categories__c!=Null && accConRelObj.Product_Notifications_Categories__c.contains(ACR_PNC_Default) && accConRelObj.Roles!=Null && accConRelObj.Roles.contains(ACR_ROLES_R_Q) && accConRelObj.IsActive && accConRelObj.contact.Is_Active__c) {                
                    mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITH_RQ_CONTACT,setAcctIds,accConRelObj.AccountId);
                    ilib_LogEvent.message('set of ids single from if: '+setAcctIds+'map of ids single from if:'+mapOfAccIds);
                } 
                else {
                    mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITHOUT_RQ_CONTACT,setAcctIdsForZeroRq,accConRelObj.AccountId);
                    ilib_LogEvent.message('set of ids single from else: '+setAcctIdsForZeroRq+'map of ids single from else:'+mapOfAccIds);
                }
            }
        }
        ilib_LogEvent.message('setOFAccIds checkAccWithSingleACR: '+setAcctIds+'mapOfAccIds2 checkAccWithSingleACR: '+mapOfAccIds);
        ilib_LogEvent.message('setAcctIdsForZeroRq checkAccWithSingleACR: '+setAcctIdsForZeroRq+'mapOfAccIds2 checkAccWithSingleACR: '+mapOfAccIds);

        return mapOfAccIds;
    }

    /**
     * @author Saddam
     * @description : PM-41 and PM-430,checks R/q requirement and returns the account ids which has Multiple ACR records
     * Params : Accountids
     * Returns : Map<string,id>
     **/
    public static  Map<string,set<id>> checkAccWithMultipleACR(set<Id> setOfAccIdMultipleCon) {
     
        ilib_LogEvent.message('setOfAccIdMultipleCon: '+setOfAccIdMultipleCon);
        //Check if Account has atleast two R/q Acr or not
        List<AccountContactRelation> listAccConRelMul = new AccountContactRelationsSelector().getAcrWithContactByAccount(setOfAccIdMultipleCon);
        ilib_LogEvent.message('listAccConRelMul: '+listAccConRelMul);
        Map<string,set<id>> mapOfAccIds = new Map<string,set<id>>();
        set<id> setAcctIds = new set<id>();
        set<id> setAcctIdsNotRq = new set<id>();
        Map<Id,List<AccountContactRelation>> mapAccIdToAccConRel = new Map<Id,List<AccountContactRelation>>();
        List<AccountContactRelation> listAccConRelTemp = new List<AccountContactRelation>();
        if(listAccConRelMul!=NUll && !listAccConRelMul.isEmpty()) {
            for (AccountContactRelation accConRelObj : listAccConRelMul) {            
                if(accConRelObj.Product_Notifications_Categories__c!=Null && accConRelObj.Product_Notifications_Categories__c.contains(ACR_PNC_Default) && accConRelObj.Roles!=Null && accConRelObj.Roles.contains(ACR_ROLES_R_Q) && accConRelObj.IsActive && accConRelObj.contact.Is_Active__c) {                
                    if(mapAccIdToAccConRel.containsKey(accConRelObj.AccountId)) {
                        listAccConRelTemp = mapAccIdToAccConRel.get(accConRelObj.AccountId);
                        listAccConRelTemp.add(accConRelObj);
                        mapAccIdToAccConRel.put(accConRelObj.AccountId,listAccConRelTemp);
                    } else {
                        mapAccIdToAccConRel.put(accConRelObj.AccountId,new List<AccountContactRelation> { accConRelObj });
                    }                
                }
            } 
        }
            for(Id accId : setOfAccIdMultipleCon) {
                if(mapAccIdToAccConRel.containsKey(accId)) {
                    listAccConRelTemp = mapAccIdToAccConRel.get(accId);
                    if(listAccConRelTemp.size()>1) {
                        mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITH_MUL_RQ_CONTACT,setAcctIds,accId);
                        ilib_LogEvent.message('set of ids mul from if: '+setAcctIds+'map of ids mul from if:'+mapOfAccIds);

                    } else {
                        mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITHOUT_MUL_RQ_CONTACT,setAcctIdsNotRq,accId);                  
                        ilib_LogEvent.message('set of ids mul from else 1: '+setAcctIdsNotRq+'map of ids mul from else 1:'+mapOfAccIds);
                    }
                } else {
                    mapOfAccIds = getMapOfStringOfIds(mapOfAccIds,ACC_ID_WITHOUT_MUL2_RQ_CONTACT,setAcctIdsNotRq,accId);
                    ilib_LogEvent.message('set of ids mul from else 2: '+setAcctIdsNotRq+'map of ids mul from else 2:'+mapOfAccIds);
                }   
            }
            ilib_LogEvent.message('setOFAccIds checkAccWithMultipleACR: '+setAcctIds+'mapOfAccIds checkAccWithMultipleACR: '+mapOfAccIds);
            ilib_LogEvent.message('setAcctIdsNotRq checkAccWithMultipleACR: '+setAcctIdsNotRq+'mapOfAccIds checkAccWithMultipleACR: '+mapOfAccIds);


            
        return mapOfAccIds;
    }

     
    /**
     * @author Saddam
     * @description : PM-41 and PM-430,checks R/q requirement and returns the account ids which has Multiple ACR records
     * Params : set of Account ids of Rqcontact and NonRqcontact 
     * Returns : List<Account>
     **/
    public static List<Account> getAccUpdateList(set<Id> setofaccAcrRqContact,set<Id> setOfaccAcrNotRqContact ) {
     
        ilib_LogEvent.message('setofaccAcrRqContact@'+setofaccAcrRqContact+'setOfaccAcrNotRqContact'+setOfaccAcrNotRqContact);        
        List<Account> accUpdateList = new  List<Account>();  
        Set<Id> setAccIds = new Set<Id>();
        setAccIds.addAll(setofaccAcrRqContact);
        setAccIds.addAll(setOfaccAcrNotRqContact);
        List<Account> accListQuery = new AccountsSelector().getRqComplianceAccounts(setAccIds);
        ilib_LogEvent.message('accListQuery@: '+accListQuery);
        Date nonComplianceDate = System.today(); //INC0436156
        for(Account accRecord : accListQuery) {
            if(setofaccAcrRqContact.contains(accRecord.Id)) {
                accRecord.R_Q_Contact_Compliant__c = accRecord.R_Q_Contact_Eligible__c ? ACC_COMPLIANT : ACC_NOT_APPLICABLE;
                 accRecord.R_Q_Non_Compliance_Date__c = null;
            } else if (setOfaccAcrNotRqContact.contains(accRecord.Id)) {
                accRecord.R_Q_Contact_Compliant__c = accRecord.R_Q_Contact_Eligible__c ? ACC_NON_COMPLIANT : ACC_NOT_APPLICABLE;
                 accRecord.R_Q_Non_Compliance_Date__c = accRecord.R_Q_Contact_Eligible__c ? nonComplianceDate : null;
              }
            accUpdateList.add(accRecord);
        }
        
        ilib_LogEvent.message('accUpdateList from getAccUpdateList: '+accUpdateList);        
        ilib_LogEvent.pop(); 
        
        return accUpdateList;
    }

}


