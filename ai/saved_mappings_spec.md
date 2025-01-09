# Saved Mappings Feature Specification

## Overview
This feature allows users to save multiple event mappings, manage them through a dedicated screen, and perform bulk operations on them. The primary data source is Elastic Request/Response data.

## Data Structure
```typescript
interface SavedMapping {
  name: string;           // Event name (max 200 chars, required)
  product: string;        // product identifier
  query: string;          // from Elastic request
  mappings: Mapping[];    // field mappings
  configFields: any;      // configuration fields
  totalFieldsMapped: number;
  requiredFieldsMapped: number;
  totalRequiredFields: number;
  rawSamples: any[];     // raw sample records from Elastic
  createdAt: DateTime;    // creation timestamp
  modifiedAt: DateTime;   // last modification timestamp
}
```

## Implementation Phases

### Phase 1: Input Handling and Parsing ✅
- [x] Enhance Request/Response input fields:
  - [x] Add required field validation
  - [x] Add visual indicators for required fields
  - [x] Disable Parse button until all required fields are populated
- [x] Update Parse functionality:
  - [x] Store raw sample records based on selected limit
  - [x] Clear Request/Response fields after successful parse
  - [x] Maintain current mapping until new Parse or Load action
  - [x] Validate Event Name is populated

### Phase 2: State Management ✅
- [x] Update SavedMapping model:
  - [x] Add rawSamples field for storing sample records
  - [x] Ensure query from Request is captured
  - [x] Store selected record limit
- [x] Enhance save functionality:
  - [x] Add Event Name uniqueness validation
  - [x] Store raw samples with mapping
  - [x] Update state management to handle new data structure

### Phase 3: Loading and Display ✅
- [x] Enhance mapping load functionality:
  - [x] Load stored raw samples into table
  - [x] Maintain ability to re-map fields
  - [x] Display mapped data correctly
- [x] Update table display:
  - [x] Show correct number of sample records
  - [x] Handle field mapping updates
  - [x] Maintain sort and filter capabilities

### Phase 4: Bulk Operations ✅
- [x] Implement bulk delete:
  - [x] Add confirmation dialog
  - [x] Handle state updates after deletion
  - [x] Update UI to reflect changes
- [x] Add selection management:
  - [x] Select/deselect all functionality
  - [x] Individual selection toggles
  - [x] Selection count display

## UI/UX Requirements

### Input Section ✅
- [x] Clear visual hierarchy for required fields
- [x] Disabled Parse button state when requirements not met
- [x] Clear feedback for validation errors
- [x] Smooth transition after successful parse

### Saved Mappings Section ✅
- [x] Clean, organized table layout
- [x] Clear visual hierarchy
- [x] Intuitive bulk selection
- [x] Clear action buttons
- [x] Visible selection indicators

### Mapping Table ✅
- [x] Display raw samples correctly
- [x] Support re-mapping functionality
- [x] Maintain existing mapping features
- [x] Clear display of mapped vs unmapped fields

## Testing Strategy

### Unit Tests ✅
- [x] Input validation
- [x] Parse functionality
- [x] State management
- [x] Bulk operations

### Integration Tests ✅
- [x] Save/load flow
- [x] Bulk operations
- [x] State persistence
- [x] Sample record handling

### User Acceptance Criteria
- [x] Parse Elastic Request/Response successfully
- [x] Save multiple mappings with unique names
- [x] Load saved mappings with sample data
- [x] Perform bulk delete operations
- [ ] Maintain state across browser refreshes

## Error Handling
- [x] Input validation errors
- [x] Parse failures
- [ ] Storage limits
- [ ] State recovery failures
- [x] Bulk operation errors

## Performance Considerations
- [x] Efficient state updates
- [x] Optimized bulk operations
- [x] Responsive UI during operations 