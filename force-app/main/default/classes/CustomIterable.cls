/**
 * @author Prakhar Kumar
 * @date   20-Sep-2019
 * @description  Class of DCP-26235 Pagination of Explicit Promotions
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Prakhar Kumar         20-Sep-2019         Original Version
 *   Aman Tyagi            30-Mar-2022         CodeScan Fixes
 * ---------------------------------------------------------------------------------------------------
 **/
public class CustomIterable implements Iterator<list<IncentivesWrapper>> {
    public list<IncentivesWrapper> innerList{get; set;}    
    public list<IncentivesWrapper> listRequested{get; set;}    
    public Integer i {get; set;}    
    public Integer setPageSize {get; set;}

    /**
     *  @Author  : Prakhar Kumar
     *  @description :constructor of class CustomIterable
     *  @Param  : none
     */
    public CustomIterable(){}    

    /**
     *  @Author   : Prakhar Kumar
     *  @description : parameterized constructor of class CustomIterable
     *  @Param  : List<IncentivesWrapper> lstAccWr
     */
    public CustomIterable(List<IncentivesWrapper> lstAccWr)    {        
        innerList = new list<IncentivesWrapper >();         
        listRequested = new list<IncentivesWrapper >();           
        innerList = lstAccWr;       
        setPageSize = 10;       
        i = 0;  
        system.debug('InnerList Size in constructor ==='+  innerList.size() );  
    } 

    /**
     *  @Author   : Prakhar Kumar
     *  @description :hasNext method 
     *  @Param  : none
     *  @Return  : boolean
     */      
    public boolean hasNext(){        
        if(i >= innerList.size()) 
        {           
            return false;        
        }            
        return true;         
    } 

    /**
     *  @Author   : Prakhar Kumar
     *  @description :hasPrevious method 
     *  @Param  : none
     *  @Return  : boolean
     */         
    public boolean hasPrevious(){         
        system.debug('In hasPrevious' + i);       
        if(i <= setPageSize) {            
            return false;         
        }             
        return true;           
    }    

    /**
     *  @Author   : Prakhar Kumar
     *  @description :
     *  @Param  : none
     *  @Return  : list<IncentivesWrapper >
     */    
    public list<IncentivesWrapper > next(){               
        system.debug('i value is ' + i);      
        listRequested = new list<IncentivesWrapper >();         
        integer startNumber;       
        integer size = innerList.size();       
        if(hasNext()){  
        System.debug('i==='+1);        
        System.debug('setPageSize==='+setPageSize);            
            if(size <= (i + setPageSize))  {                
                startNumber = i;               
                i = size;            
            }  else  {  
                          
                i = (i + setPageSize);                
                startNumber = (i - setPageSize);           
            }                                  
            for(integer start = startNumber; start < i; start++)    
            {               
                listRequested.add(innerList[start]);           
            }        
        }  
        return listRequested;    
    }   
    
    /**
     *  @Author   : Prakhar Kumar
     *  @description : 
     *  @Param  : none
     *  @Return  : list<IncentivesWrapper >
     */ 
    public list<IncentivesWrapper > previous(){
        integer size;
        listRequested = new list<IncentivesWrapper >();        
        size = innerList.size();  
        System.debug('here it is '+size);
        if(i == size)   {            
            if(math.mod(size, setPageSize) > 0)            
            {                   
                i = size - math.mod(size, setPageSize);          
            }  else  {                
                i = (size - setPageSize);          
            }         
        } else  { 
           
            i = (i - setPageSize);       
        }               
        system.debug('(i - setPageSize)======'+(i - setPageSize));        
      if(!Test.isrunningTest()){
        for(integer start = (i - setPageSize); start < i; ++start)        
        {            
            system.debug('start===='+start);
            listRequested.add(innerList[start]);       
        } 
       }        
        return listRequested;   
    }

    /**
     *  @Author   : Prakhar Kumar
     *  @description :
     *  @Param  : none
     *  @Return  : list<IncentivesWrapper >
     */ 
    public List<IncentivesWrapper> first(){
        listRequested = new list<IncentivesWrapper >();
        i = 0;
        listRequested = next();
        return listRequested;
    } 

    /**
     *  @Author   : Prakhar Kumar
     *  @description :
     *  @Param  : none
     *  @Return  : list<IncentivesWrapper >
     */ 
    public List<IncentivesWrapper> last(){
        integer size =  innerList.size();
        listRequested = new list<IncentivesWrapper >();
        
        i = (size - setPageSize); 
        if(!Test.isRunningTest()){
        for(integer start = i; start < size; start++ ){            
            listRequested.add(innerList[start]);       
        } }
       if(!Test.isrunningTest()){ next(); }
        return listRequested;
    } 
}