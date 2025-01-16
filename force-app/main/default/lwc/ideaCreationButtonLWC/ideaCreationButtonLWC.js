import { LightningElement,track } from 'lwc';

export default class IdeaCreationButtonLWC extends LightningElement {

@track showComponent = false;

showCreateComponent()
{
    this.showComponent = true;
}

closePopupWindow()
{
    this.showComponent = false;
}

}