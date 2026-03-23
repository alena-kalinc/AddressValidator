import { LightningElement, api, track } from 'lwc';
import validateAddress from '@salesforce/apex/ContactAddressValidation.validateAddress';
import { RefreshEvent } from 'lightning/refresh';

export default class ContactAddressValidation extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track contact;
    @track error;
    @track message;

    handleValidate() {
        validateAddress({ recordId: this.recordId })
          .then((result) => {
            this.contact = result;
            this.message = result.AddressValid__c ? 'Address is Valid' : 'Address is Invalid';
            this.dispatchEvent(new RefreshEvent());
          })
          .catch((error) => {
            this.error = error;
            this.message = 'Error: ' + (error.body?.message || error.message);
          });
      }
}