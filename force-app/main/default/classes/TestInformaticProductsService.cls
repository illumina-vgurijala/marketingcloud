/**
 *    @author Akshay Mohan
 *    @date   01-13-2020
 *    @description   Test class for InformaticProductsService
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *      Developer                      Date                 Description
 *      Akshay Mohan                   01-15-2020           Initial version
 *
*/
@isTest
public with sharing class TestInformaticProductsService {
  /*
    *@author: Akshay Mohan
    *@Desc: Test method  to check valid config
  */
  @isTest
  public static void checkValidConfig(){
    InformaticProductsService.InformaticsProductWrapper config = 
          InformaticProductsService.getConfig('BASESPACE_SEQUENCE_HUB', 'SUBSCRIPTION', 'Enterprise');
    System.assert(config!=null,'Config not found for BaseSpace Sequence Hub');
    System.assert(!config.setRequiredFields.isEmpty(),'Required fields not set');
  }  
   /*
    *@author: Akshay Mohan
    *@Desc: Test method  to check invalid config
  */
  @isTest
  public static void checkInvalidConfig(){
      InformaticProductsService.InformaticsProductWrapper config = InformaticProductsService.getConfig('Blah', 'Blah', 'Blah');
      System.assertEquals(null,config,'Config  found for bogus value');
  }  
}