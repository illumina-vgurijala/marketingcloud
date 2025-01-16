/*
* @author : Todd Newman
* @description :
* @Date: 2018-11-29
* Modification Log:
*       ------------------------------------------------------------------------------------
*        Developer               Date                 Description
*        Todd Newmann           2018-11-29          Initial Version
*        Aman Tyagi             2022-03-31          CodeScan Fixes
*       ------------------------------------------------------------------------------------
*/
public with sharing class ApttusPLIStagings extends ilib_SObjectDomain {

    /*
    * @Author:  Todd Newman
    * @Description : parameterized constructor of the class ApttusPLIStagings
    * @param: List<Apttus_PLI_Staging__c> sObjectList
    */
    public ApttusPLIStagings(List<Apttus_PLI_Staging__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {

        /*
        * @Author:  Todd Newman
        * @Description : parameterized constructor of the base class 
        * @param: List<SObject> sObjectList
        */       
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusPLIStagings(sObjectList);
        }
    }

    /*
    * @Author:  Todd Newman
    * @Description : this method has logic for before insert
    * @param: null
    * @return: void
    */ 
    public override void onBeforeInsert()
    {
        removePrependedZeros();
        markNoMaterialRowsComplete();
    }

    private void removePrependedZeros()
    {
        String regExp = '0*';
        Pattern p = Pattern.compile(regExp);

        for (Apttus_PLI_Staging__c rec : (List<Apttus_PLI_Staging__c>)records)
        {
            Matcher m = p.matcher(rec.MaterialId__c);

            String zerosRemoved = m.replaceFirst('');
            System.debug(zerosRemoved);

            rec.MaterialId__c = zerosRemoved;
        }
    }

    private void markNoMaterialRowsComplete()
    {
        for (Apttus_PLI_Staging__c rec : (List<Apttus_PLI_Staging__c>)records)
        {
            if (String.isBlank(rec.MaterialId__c))
                rec.Processed_Date__c = Date.today();
        }
    }

}