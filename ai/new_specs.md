### Updated Specifications for Maverick Mapper

#### **Project Overview**
The Maverick Mapper is a Flutter application designed to facilitate field mapping between many different application's events and SaaS Alerts. It provides a user-friendly interface for creating, managing, and exporting field mappings that conform to the SaaS Alerts mapping configuration format.

#### **Purpose**
The Maverick Mapper mini-application is an internal tool designed to map data between two disparate systems. It facilitates importing data, parsing it, and mapping source fields to SaaS Alerts fields with a user-friendly drag-and-drop interface. The tool prioritizes ease of use, maintainability, and straightforward functionality.

---

#### **Key Features**

1. **Source Data Input**
   - **Input Methods:**
     - API integration (Swagger and existing functionality provided).
     - Paste JSON directly into the application.
   - **Supported Sources:**
     - SaaS Alerts RAW event source.
     - JSON event sources that are pasted in.
     - Rocket Cyber API.
   - **JSON Parsing:**
     - Parse the input JSON into a list of fields.
     - Display atomic fields.

2. **SaaS Alerts Fields**
   - **Field List:**
     - Fields are defined in `config/fields.json`.
     - Fields can be marked as "Required" and "Optional".
   - **Field Presentation:**
     - Represented as tags, labels, or small cards.

3. **Mapping Functionality**
   - **Drag-and-Drop Interface:**
     - Source fields can be dragged to SaaS Alerts fields.
     - Visual feedback shows successful mapping.
   - **Mappings Table:**
     - Automatic addition of mappings without confirmation.
     - Easy removal of mappings.

4. **Export Options**
   - **CSV Export:**
     - Includes source app name, field name, and mapping details.
   - **JSON Export:**
     - Follows the JSONata format.

5. **Complex Mapping**
   - **JSONata Integration:**
     - Visual JSONata expression builder for complex mappings.
     - Live preview of evaluated expressions.

6. **State Management**
   - Utilizes local state for managing mappings and selections.

7. **User Interface Design**
   - **Layout:**
     - Source fields displayed on the left.
     - SaaS Alerts fields displayed on the right.
   - **Mapping Table:**
     - Persistent, scrollable list of active mappings.

8. **Technical Requirements**
   - **Frontend:**
     - Framework: Flutter.
     - Components: Drag-and-drop library, table for displaying mappings.
   - **Backend:**
     - APIs: SaaS Alerts API and Rocket Cyber API.

9. **Data Validation**
   - Ensure required fields are mapped before export.
   - Validate JSON format during input.

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