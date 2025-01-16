/**
*    @author Satya Swain
*    @date   2020-01-28
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Satya Swain                     2020-01-29         Initial Version as part of PRB0043346
*            Jitesh Lakhwani                 6-July-2022        Code Scan fixes of Comments
*/
public class IntegerIterator implements Iterable<Integer>, Iterator<Integer> {

    Integer counter;

    /**
    * @description: IntegerIterator class Constructor
    * @param : None
    * @return: None
    */
    public IntegerIterator(Integer counter) {
        this.counter = counter;
    }

    /**
    * @description: Method to check whether there is a next value available in iterator OR not.
    * @param : None
    * @return: Boolean
    */
    public Boolean hasNext() { return counter > 0; }

    /**
    * @description: Method will calculate and return the positiion of the next value in the iterator.
    * @param : None
    * @return: Integer
    */
    public Integer next() { return counter--; }

    /**
    * @description: iterator method implementation.
    * @param : None
    * @return: Iterator<Integer>
    */
    public Iterator<Integer> iterator() { return this; }

}