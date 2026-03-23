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
            this.message = 'button clicked';
            this.dispatchEvent(new RefreshEvent());
          })
          .catch((error) => {
            this.error = error;
          });
      }
}