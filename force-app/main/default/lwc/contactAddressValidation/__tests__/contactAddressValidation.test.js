import { createElement } from 'lwc';
import ContactAddressValidation from 'c/contactAddressValidation';
import validateAddress from '@salesforce/apex/ContactAddressValidation.validateAddress';

jest.mock(
    '@salesforce/apex/ContactAddressValidation.validateAddress',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const RECORD_ID = '003000000000001AAA';

describe('c-contact-address-validation', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders component with initial state', () => {
        // Arrange
        const element = createElement('c-contact-address-validation', {
            is: ContactAddressValidation
        });
        element.recordId = RECORD_ID;

        // Act
        document.body.appendChild(element);

        // Assert: Ensure the button and initial message are rendered correctly
        const button = element.shadowRoot.querySelector('lightning-button');
        expect(button).not.toBeNull();
        expect(button.label).toBe('Validate Address');

        const messageSpan = element.shadowRoot.querySelector('span');
        expect(messageSpan.textContent).toBe(''); // Initial message should be empty
    });

    it('handles successful validation (Address is Valid)', async () => {
        // Arrange: Set up the Apex mock to return a valid address result
        const mockSuccessResult = {
            Id: RECORD_ID,
            AddressValid__c: true
        };
        validateAddress.mockResolvedValue(mockSuccessResult);

        const element = createElement('c-contact-address-validation', {
            is: ContactAddressValidation
        });
        element.recordId = RECORD_ID;
        document.body.appendChild(element);

        // Act: Find the button and simulate a click event
        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();

        // Wait for the Apex Promise to resolve and the LWC DOM to update
        await flushPromises();

        // Assert: Verify Apex was called with the correct parameters
        expect(validateAddress).toHaveBeenCalledTimes(1);
        expect(validateAddress).toHaveBeenCalledWith({ recordId: RECORD_ID });

        // Assert: Check that the UI message updated correctly
        const messageSpan = element.shadowRoot.querySelector('span');
        expect(messageSpan.textContent).toBe('Address is Valid');
    });

    it('handles successful validation (Address is Invalid)', async () => {
        // Arrange: Set up the Apex mock to return an invalid address result
        const mockInvalidResult = {
            Id: RECORD_ID,
            AddressValid__c: false
        };
        validateAddress.mockResolvedValue(mockInvalidResult);

        const element = createElement('c-contact-address-validation', {
            is: ContactAddressValidation
        });
        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();

        await flushPromises();

        // Assert: Verify the UI reflects the invalid status
        const messageSpan = element.shadowRoot.querySelector('span');
        expect(messageSpan.textContent).toBe('Address is Invalid');
    });

    it('handles Apex error correctly', async () => {
        // Arrange: Set up the Apex mock to throw an error (simulate a Server/Callout Error)
        const mockError = {
            body: {
                message: 'Something went wrong on the server'
            }
        };
        validateAddress.mockRejectedValue(mockError);

        const element = createElement('c-contact-address-validation', {
            is: ContactAddressValidation
        });
        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();

        await flushPromises();

        // Assert: Verify the UI displays the error message properly
        const messageSpan = element.shadowRoot.querySelector('span');
        expect(messageSpan.textContent).toBe('Error: Something went wrong on the server');
    });
});