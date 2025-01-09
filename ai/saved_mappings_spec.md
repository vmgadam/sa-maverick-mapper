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

### Phase 1: Input Handling and Parsing
- [ ] Enhance Request/Response input fields:
  - [ ] Add required field validation
  - [ ] Add visual indicators for required fields
  - [ ] Disable Parse button until all required fields are populated
- [ ] Update Parse functionality:
  - [ ] Store raw sample records based on selected limit
  - [ ] Clear Request/Response fields after successful parse
  - [ ] Maintain current mapping until new Parse or Load action
  - [ ] Validate Event Name is populated

### Phase 2: State Management
- [ ] Update SavedMapping model:
  - [ ] Add rawSamples field for storing sample records
  - [ ] Ensure query from Request is captured
  - [ ] Store selected record limit
- [ ] Implement browser persistence:
  - [ ] Add localStorage integration
  - [ ] Add state recovery on app load
  - [ ] Handle storage limits gracefully
- [ ] Enhance save functionality:
  - [ ] Add Event Name uniqueness validation
  - [ ] Store raw samples with mapping
  - [ ] Update state management to handle new data structure

### Phase 3: Loading and Display
- [ ] Enhance mapping load functionality:
  - [ ] Load stored raw samples into table
  - [ ] Maintain ability to re-map fields
  - [ ] Display mapped data correctly
- [ ] Update table display:
  - [ ] Show correct number of sample records
  - [ ] Handle field mapping updates
  - [ ] Maintain sort and filter capabilities

### Phase 4: Bulk Operations
- [ ] Implement bulk delete:
  - [ ] Add confirmation dialog
  - [ ] Handle state updates after deletion
  - [ ] Update UI to reflect changes
- [ ] Add selection management:
  - [ ] Select/deselect all functionality
  - [ ] Individual selection toggles
  - [ ] Selection count display

## UI/UX Requirements

### Input Section
- [ ] Clear visual hierarchy for required fields
- [ ] Disabled Parse button state when requirements not met
- [ ] Clear feedback for validation errors
- [ ] Smooth transition after successful parse

### Saved Mappings Section
- [ ] Clean, organized table layout
- [ ] Clear visual hierarchy
- [ ] Intuitive bulk selection
- [ ] Clear action buttons
- [ ] Visible selection indicators

### Mapping Table
- [ ] Display raw samples correctly
- [ ] Support re-mapping functionality
- [ ] Maintain existing mapping features
- [ ] Clear display of mapped vs unmapped fields

## Testing Strategy

### Unit Tests
- [ ] Input validation
- [ ] Parse functionality
- [ ] State management
- [ ] Bulk operations

### Integration Tests
- [ ] Save/load flow
- [ ] Bulk operations
- [ ] State persistence
- [ ] Sample record handling

### User Acceptance Criteria
- [ ] Parse Elastic Request/Response successfully
- [ ] Save multiple mappings with unique names
- [ ] Load saved mappings with sample data
- [ ] Perform bulk delete operations
- [ ] Maintain state across browser refreshes

## Error Handling
- [ ] Input validation errors
- [ ] Parse failures
- [ ] Storage limits
- [ ] State recovery failures
- [ ] Bulk operation errors

## Performance Considerations
- [ ] Efficient state updates
- [ ] Optimized bulk operations
- [ ] Responsive UI during operations
- [ ] Browser storage optimization 