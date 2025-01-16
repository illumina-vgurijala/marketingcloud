/**
*    @author Pranay   
*    @date          
*    @description   Inteface class. (CMSI-11)
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*/

public interface IPsLog {

void setTitle(String title);
String getRootTitle();
void push(String scope);
void pop();
void emit();
void emit(String emitScopeName);
void error(String message);
void info(String message);
void debug(String message);
void debug(ilib_LogQuery.Data query);
void fine(String message);

}