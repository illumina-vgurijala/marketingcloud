/*@ author       : Gopi
* @ date         : 01-Jun-2023
* @ Description  : CMCM-698: R/Q Contact Eligible Queueable Helper
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gopi                  01-06-2023                Initial version
* Enrique Reyes         14-08-2023                CMCM-2229
*/
public class RQContactEligibleHelper {
    public static final String DISTRIBUTOR = 'Distributor';
    public static final String SOLDTO ='Sold To';    
    public static final String CODEPARAMETERJAPANST = 'Japan_Billing_Country_Code';
    public static final String CODEPARAMETERRQEXCLUDEDST = 'RQ_Excluded_Billing_Country_Code';
    
    private static final String LOG_TITLE = 'RQContactEligibleHelper';
    public static final String ROLE1 = 'Regulatory/Quality';
    public static final String ROLE2 = 'Hard Copy RQ Sales';
    public static final String ROLE3 = 'Hard Copy RQ Service';
    public static final String JAPAN = 'Japan';
    public static final String GREATERCHINA = 'GreaterChina';


    public static  Set<ID> getRQAccountId(List<Apttus_Config2__Order__c> listOrder,List<String> orderTypeList){
        ilib_LogEvent.push(LOG_TITLE +'.getRQAccountId');  
        ilib_LogEvent.message('listOrder--'+listOrder);
        Set<Id> setAccountIds = new Set<Id>();  
        Set<String> setCountryCodes = new Set<String>();
        List<String> greaterChinaList =new List<String>();
        List<String> japanList =new List<String>();
        List<R_Q_Contact_Eligible_Countries__mdt> codeParameterJapan =new RQContactEligibleCountriesSelector().selectRQContactEligibleByDeveloperName(new set<String>{JAPAN});
        List<R_Q_Contact_Eligible_Countries__mdt> codeParameterGreaterChina =new RQContactEligibleCountriesSelector().selectRQContactEligibleByDeveloperName(new set<String>{GREATERCHINA});
        if(!codeParameterGreaterChina.isEmpty()){
            greaterChinaList =codeParameterGreaterChina[0].CountryCode__c.split(',');
        }
        if(!codeParameterJapan.isEmpty()){
            japanList =codeParameterJapan[0].CountryCode__c.split(',');
        }
        for(Apttus_Config2__Order__c ordObj : listOrder) {  
            if(orderTypeList.contains(ordObj.Apttus_Config2__Type__c)) {
                //Set deciding variables to set RQ Contact eligible           
                Boolean hasNoDistributor = ordObj.Distributor__c == null;
                Boolean isDistributorTypeDistributor = String.isNotBlank(ordObj.Distributor__c) && ordObj.Distributor__r.Account_Group__c == DISTRIBUTOR;
                Boolean isSoldToTypeDistributor = String.isNotBlank(ordObj.Apttus_Config2__SoldToAccountId__c) && ordObj.Apttus_Config2__SoldToAccountId__r.Account_Group__c == DISTRIBUTOR;
                Boolean isSoldToTypeSoldTo = String.isNotBlank(ordObj.Apttus_Config2__SoldToAccountId__c) && ordObj.Apttus_Config2__SoldToAccountId__r.Account_Group__c == SOLDTO;
               
                ilib_LogEvent.info('hasNoDistributor--'+hasNoDistributor);
                ilib_LogEvent.info('isDistributorTypeDistributor--'+isDistributorTypeDistributor);
                ilib_LogEvent.info('isSoldToTypeDistributor--'+isSoldToTypeDistributor);
                ilib_LogEvent.info('isSoldToTypeSoldTo--'+isSoldToTypeSoldTo);
                ilib_LogEvent.info('japanList--'+japanList);
                ilib_LogEvent.info('greaterChinaList--'+greaterChinaList);
                
                //Based upon deciding variables, set RQ Contact eligible on order accounts.       
                if(isSoldToTypeSoldTo){
                    setAccountIds.add(ordObj.Ultimate_Consignee__c);
                } else if(isSoldToTypeDistributor && !hasNoDistributor && japanList.contains(ordObj.Distributor__r.BillingCountryCode)){
                     setAccountIds.add(ordObj.Ultimate_Consignee__c);
                } else if(isSoldToTypeDistributor && !hasNoDistributor && greaterChinaList.contains(ordObj.Distributor__r.BillingCountryCode)){
                    setAccountIds.add(ordObj.Ultimate_Consignee__c);
                    setAccountIds.add(ordObj.Distributor__c);
                }else if(!hasNoDistributor && isSoldToTypeDistributor) {
                    setAccountIds.add(ordObj.Distributor__c);
                }
            }
        }
        ilib_LogEvent.info('setAccountIds--'+setAccountIds);
        ilib_LogEvent.pop();
        return setAccountIds;
    }

    /*@ author       : Gopi
    * @ date         : 01-Jun-2023
    * @ Description  : CMCM-704: R/Q Contact Notifications: Account Engagement Hard Bounced
    */
    public static  List<AccountContactRelation> getAccConReltionship(Set<Id> setContactIds){
        ilib_LogEvent.push(LOG_TITLE +'.getAccConReltionship'); 
        ilib_LogEvent.info('setContactIds--'+setContactIds); 
        List<AccountContactRelation> lstAccContRelationRecsRet = new List<AccountContactRelation>();        
        List<AccountContactRelation> lstAccContRelationRecs = new AccountContactRelationsSelector().getAccountContactRelationByContact(setContactIds);
        ilib_LogEvent.info('lstAccContRelationRecs--'+lstAccContRelationRecs); 
        for(AccountContactRelation accConRec :lstAccContRelationRecs){
            if(String.isNotBlank(accConRec.Roles)){
                List<String> lstOfRoles = accConRec.Roles.split(';');
               //CMCM-933: Added below condtions for removeing the Roles
                    if(lstOfRoles.contains(ROLE1)){
                        lstOfRoles.remove(lstOfRoles.indexOf(ROLE1));
                      }
                      if(lstOfRoles.contains(ROLE2)){
                        lstOfRoles.remove(lstOfRoles.indexOf(ROLE2));
                      }
                      if(lstOfRoles.contains(ROLE3)){
                        lstOfRoles.remove(lstOfRoles.indexOf(ROLE3));
                      }  
                
                ilib_LogEvent.info('lstOfRoles--'+lstOfRoles);
                accConRec.Product_Notifications_Categories__c = null;
                accConRec.Roles = String.join(lstOfRoles,';');
                lstAccContRelationRecsRet.add(accConRec);
               
            }
        }
        ilib_LogEvent.info('lstAccContRelationRecsRet--'+lstAccContRelationRecsRet); 
        ilib_LogEvent.pop();
        return lstAccContRelationRecsRet;
    }

}