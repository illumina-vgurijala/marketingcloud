/**
* @author Shivani Jain
* @date 30th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to update CC Email on Work Orders
*/ 
public with sharing class UpdateCCEmail_WOHelper {
      
    /*
    *  @AUTHOR:  Sandeep
    *  @DESCRIPTION: DCP-575 This method Fetchs Field Support Email associated to the Account
    *  @PARAM :  set<Id> setAccountId, List<SVMXC__Service_Order__c> lstWo
    */
    public static void updateCcEmail(List<Sobject> records) {
        List<Account_to_Field_Support__c> lstAccFS=new List<Account_to_Field_Support__c>();
        Map<Id,String> accountIdToEmail = new Map<Id,String>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            if(objWorkOrder.SVMXC__Company__c!=null && WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c)!=null) {
                lstAccFS.addAll(WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c).values());
            }
        }
         
        for(Account_to_Field_Support__c objAccToFieldSupport : lstAccFS) {
            
            if(!accountIdToEmail.containsKey(objAccToFieldSupport.Account__c)) {
                String strConcatenateEmail = '';
                if((objAccToFieldSupport.User_Role__c == WorkOrders.STRING_LABEL_PRIMARY_FAS || objAccToFieldSupport.User_Role__c == WorkOrders.STRING_LABEL_PRIMARY_FSE) 
                    && objAccToFieldSupport.User__r.SVMXC__Email__c != null) {
                    strConcatenateEmail +=objAccToFieldSupport.User__r.SVMXC__Email__c;
                }
                accountIdToEmail.put(objAccToFieldSupport.Account__c,strConcatenateEmail);
             }else{
                String strConcatenateEmail ='';
                if(objAccToFieldSupport.User_Role__c == WorkOrders.STRING_LABEL_PRIMARY_FAS || objAccToFieldSupport.User_Role__c == WorkOrders.STRING_LABEL_PRIMARY_FSE) {
                    strConcatenateEmail = accountIdToEmail.get(objAccToFieldSupport.Account__c);
                    if(strConcatenateEmail =='' && objAccToFieldSupport.User__r.SVMXC__Email__c != null) {
                        strConcatenateEmail +=objAccToFieldSupport.User__r.SVMXC__Email__c;
                    } else if(objAccToFieldSupport.User__r.SVMXC__Email__c != null) {
                        strConcatenateEmail +=';'+objAccToFieldSupport.User__r.SVMXC__Email__c;
                    }
                if(strConcatenateEmail.contains(';')) {
                    set<String> setSplittedEmails = new set<string>();
                    strConcatenateEmail = strConcatenateEmail.deleteWhitespace();
                    setSplittedEmails.addAll(strConcatenateEmail.split(';'));
                    strConcatenateEmail = setSplittedEmails.toString().replace(',',';');
                    strConcatenateEmail = strConcatenateEmail.remove('{');
                    strConcatenateEmail = strConcatenateEmail.remove('}');
                }
                accountIdToEmail.put(objAccToFieldSupport.Account__c,strConcatenateEmail);
                }              
            }
        }
        
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            if(accountIdToEmail.containsKey(objWorkOrder.SVMXC__Company__c)) {
                objWorkOrder.CC_Email__c=accountIdToEmail.get(objWorkOrder.SVMXC__Company__c);
                system.debug('objWorkOrder.CC_Email__c'+objWorkOrder.CC_Email__c);
            } 
        }
    }
}
