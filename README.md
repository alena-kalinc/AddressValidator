# 🌍 Smarty Address Validation Integration (FinDock Panel Assignment)
**Author:** Alona Kalinchuk

## 📌 Project Overview
This repository contains the solution for the Salesforce Engineer Panel Assignment. The application allows users to validate US and International addresses on the `Contact` object directly from the UI, while being fully optimized for bulk automation operations.

---

## 🎯 Solutions to Panel Exercises

### 1. Performance & Bulkification
* **Bulk API for US:** US addresses are routed to the Smarty Bulk POST endpoint, processing records in chunks of 100 (API limit) to minimize HTTP callouts.
* **Limit Monitoring:** International validation (GET requests) actively monitors `Limits.getCallouts()` to gracefully prevent `System.LimitException`.
* **Live Demo Ready:** An Anonymous Apex script is prepared to prove performance by validating 60+ records instantly.

### 2. Testing Strategy
* **Apex Unit Testing:** Implemented dynamic `HttpCalloutMock` classes that utilize `input_id` mapping to accurately simulate bulk API responses.
* **Coverage & Scenarios:** Tests cover successful validation, invalid data handling, and server-side failures.

### 3. Multi-Provider Architecture (Architecture Design)
* **Strategy & Factory Patterns:** To support multiple providers (e.g., Smarty, Loqate, Google), I propose using an `IAddressValidator` interface. A Factory class would dynamically instantiate the correct provider at runtime.
* **Configuration-Driven:** Provider-specific endpoints, mappings, and credentials should be stored in Custom Metadata Types (CMDT) to allow switching vendors without code deployment.

### 4. Code Review & Best Practices Applied
* **Security First:** Refactored the legacy codebase to include strict CRUD/FLS checks using `WITH SECURITY_ENFORCED` and `Security.stripInaccessible`.
* **Separation of Concerns:** Reorganized the logic to separate Callout Services from UI Controllers.
* **Clean Code:** Removed hardcoded strings and implemented robust error handling with meaningful user feedback.

### 5. Productization (Roadmap for AppExchange / ISV)
To make this a real product that adds value to multiple orgs:
* **SObject Agnostic:** Decouple from the `Contact` object. Use Field Sets and dynamic SOQL to support Leads, Accounts, or Custom Objects.
* **Dynamic Field Mapping:** Allow admins to map their custom address fields to the API payload via UI/CMDT.
* **Persistent Logging:** Implement an `Integration_Log__c` object and Platform Events to track API failures and usage limits for org admins.

---

## 🚀 Setup & Configuration

1. **Deploy Metadata:** Deploy the classes and UI components to your Salesforce org.
2. **Remote Site Settings:** Add `https://us-street.api.smarty.com` and `https://international-street.api.smarty.com`.
3. **Authentication Setup:**
   * Configure **External Credentials** with `Basic Authentication` protocol.
   * Set up the **Principals** with your Smarty `Auth ID` and `Auth Token`.
   * Configure **Named Credentials** (`Smarty_US` and `Smarty_International`) linking to the External Credential.
4. **Permissions:** Assign a Permission Set granting access to the **External Credential Principal** and the `AddressValid__c` field.

---

## 🕒 Timebox & Trade-offs
Decisions made to respect the assignment time limit:

* **Validation Strictness (International API):** The current implementation accepts both `Verified` and `Partial` statuses as a valid address. To achieve a strict 100% `Verified` match, the GET request payload needs to be expanded (e.g., mapping the City field to the `locality` parameter). This was skipped to avoid breaking the legacy method signature but is documented for V2.
* **Hardcoded Configurations:** Named Credentials names and Batch Sizes (100) are currently static in Apex. In production, these would be moved to Custom Metadata.
* **Mass Action UI:** The backend is fully bulk-safe, but a dedicated List View button/LWC was skipped to prioritize core backend architecture and stability.
