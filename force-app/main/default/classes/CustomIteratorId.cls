/**
*    @author  Pankaj Singla
*    @date    01-August-2018
*    @description  This is Custom Iteratort to retun contact and lead Ids to Start method of apex 
					batch job

*        Modification Log:
*       
------------------------------------------------------------------------------------
*       Developer                       Date                Description
*       
------------------------------------------------------------------------------------
*       Pankaj Singla          			01/08/2018            Original  Version
*       Jitesh Lakhwani                 6-July-2022           Code Scan fixes of Comments
*/

public class CustomIteratorId implements Iterable<String>,Iterator<string>{
    public List<string> lstIds {get;set;}
    public Integer intCounter {get;set;}

    /**
    * @description: IntegerIterator class Constructor
    * @param : List<string> lstIds
    * @return: None
    */
    public CustomIteratorId(List<string> lstIds){
        this.lstIds=lstIds;
        intCounter=0;
    }
    
    /**
    * @description: Method to check whether there is a next value available in iterator OR not.
    * @param : None
    * @return: Boolean
    */
    public boolean hasNext(){
        return intCounter>=lstIds.size()?false:true;
    }

    /**
    * @description: Method will calculate and return the next value in the list.
    * @param : None
    * @return: String
    */
    public string next(){
        intCounter++;
        return lstIds[intCounter-1];
    }

    /**
    * @description: iterator method implementation.
    * @param : None
    * @return: Iterator<String>
    */
    public Iterator<String> iterator()
   {
      return this;   
   }
    
}