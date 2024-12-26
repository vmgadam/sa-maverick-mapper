### Specifications Engineering Document: Maverick Mapper

#### **Overall Requirements**
You are an expert developer. You will look over all existing codebase to make your proposal prior to moving forward. You will utilize existing, popular, well-maintained packages if required. You will remember that this is an MVP and no database work, authentication, or anything fancy needs to be implemented. In the event that state management is required, use Riverpods.

You will save all progress that you make often and for each major function inside a file called `ai/changes.md` so that we can always know where we left off. Also, keep `ai/specs.md` in your memory at all times so you remember what you are building. Also, review `ai/fields.md` for a list of SaaS Alerts fields. The Rocket Cyber Postman collection is located in `Kaseya - RocketCyber.postman_collection.json`.

#### **Purpose**
The Maverick Mapper mini-application is an internal tool designed to map data between two disparate systems. It facilitates importing data, parsing it, and mapping source fields to SaaS Alerts fields with a user-friendly drag-and-drop interface. The tool will prioritize ease of use, maintainability, and straightforward functionality over aesthetic design. It will be a standalone screen in the application and the default screen at launch.

---

#### **Key Features**

1. **Source Data Input**
   - **Input Methods:**
     - API integration (Swagger and existing functionality provided).
     - Paste JSON directly into the application.
   - **Supported Sources:**
     - SaaS Alerts event source (https://app.swaggerhub.com/apis-docs/SaaS_Alerts/functions/0.21.0 or existing implementation).
     - Rocket Cyber API (existing implementation in codebase).
   - **JSON Parsing:**
     - Parse the input JSON into a list of fields.
     - Display atomic fields (e.g., `user.firstName`, `user.lastName`).
     - Ignore map-like structures (e.g., `user` is not displayed).

2. **SaaS Alerts Fields**
   - **Field List:**
   - SaaS Alerts event source (https://app.swaggerhub.com/apis-docs/SaaS_Alerts/functions/0.21.0 or existing implementation).
     - ai/fields.md will have the list of fields. Create it if it doesn't exist. and we can feed in fields from the API.
     - Fields can be marked as "Required" and "Optional".
    - Review 'ai/mappingConfig.json' for example mapping configurations and to pull the SaaS Alerts fields.
   - **Field Presentation:**
     - Represented as tags, labels, or small cards to conserve screen space.

3. **Mapping Functionality**
   - **Drag-and-Drop Interface:**
     - Source fields can be dragged to SaaS Alerts fields.
     - Visual feedback shows successful mapping.
   - **Mappings Table:**
     - Automatic addition of mappings without confirmation.
     - Easy removal of mappings.
     - Fields return to their respective lists when unmapped.
   - **Visual Updates:**
     - Matched fields disappear from available lists.
     - Unmapped fields reappear in their respective lists.

4. **Export Options**
   - **CSV Export:**
     - Includes:
       - Source app name.
       - Source field name.
       - Source sample data.
       - Source sample data record ID.
       - SaaS Alerts field name.
       - SaaS Alerts sample data and record ID.
   - **JSON Export:**
     - Follows the JSONata format.
     - Support for combining multiple source values and applying conditional logic (e.g., if/then/else).

5. **JSONata Integration**
   - **Formatting Logic:**
     - Allow formatting similar to https://try.jsonata.org/.
     - Enable users to combine fields and apply conditional logic directly in the tool.
     - Review 'ai/mappingConfig.json' for example mapping configurations and to pull the SaaS Alerts fields.

6. **Multiple Sources**
   - **Source Selection:**
     - Allow selection from multiple input sources.
     - Extendable for future data sources.

7. **Implementation Scope**
   - **Screen Design:**
     - Added as a new screen in the application, named "Maverick Mapper."
   - **Code Management:**
     - Legacy code remains untouched.
     - New implementations will be standalone or copied as needed from existing code.
   - **Future Proofing:**
     - Modular design to replace legacy code entirely in the future.

---

#### **User Interface Design**

- **Layout:**
  - Source fields displayed on the left (or top) side of the screen.
  - SaaS Alerts fields displayed on the right (or bottom) side of the screen.
  - Drag-and-drop interface between the two sections.

- **Mapping Table:**
  - Persistent, scrollable list of active mappings.
  - Option to remove mappings with a single action.

- **Export Options:**
  - Buttons for exporting data as CSV or JSON.

- **Field Presentation:**
  - Compact tags or labels for fields.
  - Visual indicators for required vs. optional fields.

---

#### **Technical Requirements**

1. **Frontend**
   - Framework: Existing application framework (e.g., React, Angular, or Flutter).
   - Components:
     - Drag-and-drop library.
     - Table for displaying mappings.
     - Form elements for JSON input.
   
2. **Backend**
   - APIs:
     - SaaS Alerts API for field data and sample records.
     - Swagger-defined or implemented Rocket Cyber API.
   - JSONata processing library for export formatting.

3. **State Management**
   - Local state for managing mappings.
   - Persistence of selections and mappings in local storage or memory.

4. **Data Validation**
   - Ensure required fields are mapped before export.
   - Validate JSON format during input.

---

#### **Open Questions**

1. **Sample Data:**
   - What sample records should be provided for source and SaaS Alerts fields?
   
2. **Field Presentation:**
   - Should we prioritize a specific visual style for the tags/cards (e.g., color coding)?
   
3. **Error Handling:**
   - What specific errors should be handled for API connections and user inputs?

4. **JSONata Logic:**
   - Should the tool include a full editor for JSONata expressions, or simply accept pasted logic?
   
5. **Extensibility:**
   - Are there plans to add more source systems in the near future? If so, should this tool support dynamic source additions?

---

#### **Success Criteria**

1. **Functionality:**
   - All mappings can be created, edited, and removed seamlessly.
   - Exports include all necessary data in the specified formats.

2. **Ease of Use:**
   - Intuitive drag-and-drop interface.
   - Clear feedback on field mapping.

3. **Maintainability:**
   - Modular and clean codebase for easy updates and extensions.

4. **Integration:**
   - Smooth API integrations with SaaS Alerts and Rocket Cyber.

---

This document will guide the development of the Maverick Mapper tool. Additional feedback and iterations will refine the specifications further.