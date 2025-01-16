    /*
    *  @Author: Gopinath Reddy
    *  @Date: 
    *  @Description: Class for Apttus Quote creation from Mobile
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Gopinath Reddy                                   Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix - Add code comments
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/
public with sharing class ApttusMobileCreateQuoteController {
    
    private final Opportunity opp;
    
    /*
    *  @Author      : Gopinath Reddy
    *  @Description : Constructor to get the current in context opportunity record
    */
    public ApttusMobileCreateQuoteController(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
      }
	  }