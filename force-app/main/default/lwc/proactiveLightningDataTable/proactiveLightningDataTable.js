import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';



export default class proactiveLightningDataTable extends NavigationMixin(LightningElement) {
    
    //Decorators,Variables,Constructor logic.
    @api lstTableColumns = [];
    @api lstTableData = [];
    
    @track intRowNumberOffset = 0; 
    @track lstButtons = [];
    @track mapTablesOffsets = [];
    @track objButtonChange;
	@track paginationCount = 10; // Variable to set the pagination limit


    
    /**
     * Method to capture Selected Rows.
     */
    captureSelectedRows(objEvent){
    
        const lstSeletedResults = {
            lstSeletedResults : objEvent.detail.selectedRows
        }
        console.log('lstSeletedResults****'+JSON.stringify(lstSeletedResults));
        const selectEvent = new CustomEvent('mycustomevent', {
        detail: JSON.stringify(objEvent.detail.selectedRows)
    });
    this.dispatchEvent(selectEvent);
    
        
    }   
    /**
     * Method to filter runs for table based on record offset (i.e., Pagination applied)
     */
    get fetchTableData(){
        
        return this.lstTableData.slice(this.intRowNumberOffset,this.intRowNumberOffset+this.paginationCount);
    }

    /**
     * Method to display all pagination buttons on UI.
     */
    get lstFetchButtons(){
        let intPagesCount = Math.ceil(this.lstTableData.length / this.paginationCount);
        let lstButtons= [];
        if(!this.objButtonChange){
        this.objButtonChange = 0;
        }

        //Show first 5 buttons.
        if(this.intRowNumberOffset < 20){
            lstButtons=this.handleFirst5ButtonLogic(intPagesCount,lstButtons);
            
        }

        //Show last 5 buttons.
        else if(this.intRowNumberOffset >= (intPagesCount - 4) * this.paginationCount){
            lstButtons= this.handleMiddleButtonLogic(intPagesCount,lstButtons);
        }

        //Show middle buttons.
        else{
            for(let intButtonCount = 0 ; intButtonCount < intPagesCount ; intButtonCount++ ){
                if(intButtonCount === 0 || intButtonCount === intPagesCount-1 || intButtonCount === this.intRowNumberOffset / this.paginationCount || intButtonCount === (this.intRowNumberOffset / this.paginationCount) - 1 || intButtonCount === (this.intRowNumberOffset / this.paginationCount) + 1 ){
                    lstButtons.push({
                        intTableOffsetNumber : intButtonCount,
                        intButtonLabel : intButtonCount + 1,
                        boolHideRemainingButtons : false,
                    });
                }else if(intButtonCount === 1){
                    lstButtons.push({
                        boolHideRemainingButtons : true,
                        objIconName : 'utility:chevronleft'
                    });
                }else if(intButtonCount === (this.intRowNumberOffset / this.paginationCount) + 2){
                    lstButtons.push({
                        boolHideRemainingButtons : true,
                        objIconName : 'utility:chevronright'
                    });
                }
            }
        }
        setTimeout(() =>{
            this.addOrRemoveButtonBrandStyling();
        },50);
        return lstButtons;
    }

    handleFirst5ButtonLogic(intPagesCount,lstButtons){
        for(let intButtonCount = 0 ; intButtonCount < intPagesCount ; intButtonCount++ ){
            if(intButtonCount <= 4 || intButtonCount === intPagesCount-1){
                lstButtons.push({
                    intTableOffsetNumber : intButtonCount,
                    intButtonLabel : intButtonCount + 1,
                    boolHideRemainingButtons : false,
                });
            }else if(intButtonCount === this.paginationCount){
                lstButtons.push({
                    boolHideRemainingButtons : true,
                    objIconName : 'utility:chevronright'
                });
            }
        }
        return lstButtons;
    
    }

    handleMiddleButtonLogic(intPagesCount,lstButtons){
        for(let intButtonCount = 0 ; intButtonCount < intPagesCount ; intButtonCount++ ){
            if(intButtonCount === 0 || intButtonCount >= intPagesCount-this.paginationCount){
                lstButtons.push({
                    intTableOffsetNumber : intButtonCount,
                    intButtonLabel : intButtonCount + 1,
                    boolHideRemainingButtons : false,
                });
            }else if(intButtonCount === 1){
                lstButtons.push({
                    boolHideRemainingButtons : true,
                    objIconName : 'utility:chevronleft'
                });
            }
        }
        return lstButtons;
    }


    get getRunsCount(){
        return this.lstTableData.length;
    }

    /**
     * Method to toggle pagination buttons on UI.
     */
    get boolShowButtons(){
        return this.lstTableData.length > 0;
    }


    /**
     * Method to fetch record offset to display row mumber.
     */
    get getRowNumberOffset(){
        return this.intRowNumberOffset;
    }

    /**
     * Method to display runs based on  button selected.
     */
    processNextRecords(objEvent){
        
        this.haveRowsDeselected();

        const objButtonDataId = objEvent.currentTarget.getAttribute('data-id');
        const objLastButtonOffset = (Math.ceil(this.lstTableData.length / this.paginationCount) - 1) * this.paginationCount;
        if(objButtonDataId === 'idPrevButton' && this.intRowNumberOffset !== 0){
            this.intRowNumberOffset -= this.paginationCount;
        }else if(objButtonDataId === 'idNextButton' && this.intRowNumberOffset !== objLastButtonOffset){
            this.intRowNumberOffset += this.paginationCount;
        }else if (parseInt(objButtonDataId) >= 0){
            this.intRowNumberOffset = objButtonDataId * this.paginationCount;
        } 
        
        if(objButtonDataId != this.objButtonChange){
        const selectEvent = new CustomEvent('nextpageevent', {
            detail: true
        });

        this.dispatchEvent(selectEvent);
        }
    
        this.objButtonChange = objButtonDataId; 
    }

    /**
     * Method to apply brand style to button selected.
     */
    addOrRemoveButtonBrandStyling(){
        try{
            let intButtonIdForChangingVariant;
            const intTotalButtonCount = Math.ceil(this.lstTableData.length / this.paginationCount);
            const objLastButtonOffset = (Math.ceil(this.lstTableData.length / this.paginationCount) - 1) * this.paginationCount;
            for(let intKey = 0 ; intKey < intTotalButtonCount ; intKey++){
                this.mapTablesOffsets.push({
                    key : intKey,
                    value: intKey * this.paginationCount
                });
            }
            for(const strKey in this.mapTablesOffsets){
                if(this.mapTablesOffsets[strKey].value === this.intRowNumberOffset){
                    intButtonIdForChangingVariant = this.mapTablesOffsets[strKey].key;
                }
            }
            for(const strKey in this.mapTablesOffsets){
                this.handleButtonVariant(objLastButtonOffset,strKey,intTotalButtonCount,intButtonIdForChangingVariant);
            } 
        }catch(objException){
            console.log(objException);
        }
    }

    handleButtonVariant(objLastButtonOffset,strKey,intTotalButtonCount,intButtonIdForChangingVariant){
        try{
            if(objLastButtonOffset && this.mapTablesOffsets[strKey].key <= intTotalButtonCount-1){
                if(intButtonIdForChangingVariant === this.mapTablesOffsets[strKey].key && this.template.querySelector('[data-id="' + intButtonIdForChangingVariant + '"]')){
                    this.template.querySelector('[data-id="' + intButtonIdForChangingVariant + '"]').variant = 'brand'
                }else if(this.template.querySelector('[data-id="' + this.mapTablesOffsets[strKey].key + '"]')){
                    this.template.querySelector('[data-id="' + this.mapTablesOffsets[strKey].key + '"]').variant = 'neutral'
                }
            }
        }catch(objException){
            console.log(objException);
        }
    }

    /**
     * Method to clear the user selection on navigating to other pages or records
     */
    haveRowsDeselected() {
        
        if (this.template.querySelector('[data-id="idDataTable"]').selectedRows){
            this.template.querySelector('[data-id="idDataTable"]').selectedRows = [];
        }
            
    }
}