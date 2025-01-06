# Saved Mappings Feature Specification

## Overview
This feature allows users to save multiple event mappings for a single product, manage them through a dedicated screen, and perform bulk operations on them.

## Data Structure
```typescript
interface SavedMapping {
  name: string;           // max 200 chars
  product: string;        // product identifier
  query: string;          // for duplicate detection
  mappings: Mapping[];    // current mapping format
  configFields: any;      // configuration fields
  totalFieldsMapped: number;
  requiredFieldsMapped: number;
  totalRequiredFields: number;
  createdAt: DateTime;    // creation timestamp
  modifiedAt: DateTime;   // last modification timestamp
}
```

## Implementation Phases

### Phase 1: State Management
- [ ] Extend MappingState to include saved mappings collection
- [ ] Add state management methods:
  - [ ] Create new saved mapping
  - [ ] Update existing mapping
  - [ ] Duplicate mapping (with "Copy of X" naming)
  - [ ] Delete mapping(s)
  - [ ] Bulk update mappings
  - [ ] Store last bulk operation state for revert
- [ ] Unit tests for state management:
  - [ ] Test saved mapping CRUD operations
  - [ ] Test duplicate naming functionality
  - [ ] Test bulk operations
  - [ ] Test revert functionality

### Phase 2: Saved Events Screen
- [ ] Create SavedMappingsScreen widget
- [ ] Implement table/list view with columns:
  - [ ] Name
  - [ ] Product
  - [ ] Total fields mapped
  - [ ] Required fields mapped/total
  - [ ] Last modified date
  - [ ] Visual indicator for duplicate queries
  - [ ] Action buttons (Load, Duplicate, Delete)
- [ ] Add multi-select functionality:
  - [ ] Checkbox selection
  - [ ] Bulk action buttons
  - [ ] Selection count display
- [ ] Unit tests for SavedMappingsScreen:
  - [ ] Test table rendering
  - [ ] Test selection functionality
  - [ ] Test bulk actions
  - [ ] Test UI state updates

### Phase 3: Save/Load Flow
- [ ] Add "Save As" functionality to UnifiedMapperScreen:
  - [ ] Save button with name input dialog
  - [ ] Name validation (max 200 chars)
  - [ ] Timestamp handling
  - [ ] Field count calculations
- [ ] Implement query duplicate detection:
  - [ ] Exact string matching
  - [ ] Warning dialog with matching mappings list
  - [ ] Visual indicators in saved mappings list
- [ ] Add mapping switch confirmation:
  - [ ] Unsaved changes detection
  - [ ] Warning dialog
  - [ ] Save prompt
- [ ] Unit tests for save/load flow:
  - [ ] Test "Save As" functionality
  - [ ] Test query duplicate detection
  - [ ] Test switch confirmation
  - [ ] Test validation

### Phase 4: Bulk Operations
- [ ] Implement bulk field updates:
  - [ ] Selection of target field
  - [ ] Reuse complex mapping editor
  - [ ] Apply changes to selected mappings
  - [ ] Store state for revert
- [ ] Add bulk delete functionality:
  - [ ] Confirmation dialog
  - [ ] Batch delete operation
- [ ] Add bulk export:
  - [ ] Export selected mappings
  - [ ] JSON format handling
- [ ] Unit tests for bulk operations:
  - [ ] Test bulk field updates
  - [ ] Test revert functionality
  - [ ] Test bulk delete
  - [ ] Test bulk export

### Phase 5: Integration and Export
- [ ] Integrate with existing JSON export:
  - [ ] Extend format for multiple mappings
  - [ ] Maintain backward compatibility
- [ ] Add export functionality:
  - [ ] Export single mapping
  - [ ] Export multiple mappings
  - [ ] Export all mappings
- [ ] Unit tests for export:
  - [ ] Test single mapping export
  - [ ] Test multiple mapping export
  - [ ] Test JSON format compliance

## UI/UX Requirements

### Saved Mappings Screen
- [ ] Clean, organized table layout
- [ ] Clear visual hierarchy
- [ ] Responsive design
- [ ] Intuitive bulk selection
- [ ] Clear action buttons
- [ ] Visible duplicate query indicators

### Save Dialog
- [ ] Simple, focused name input
- [ ] Clear validation feedback
- [ ] Duplicate query warnings
- [ ] Cancel/Save buttons

### Bulk Operations
- [ ] Clear selection indicators
- [ ] Intuitive bulk actions
- [ ] Visible revert option
- [ ] Progress feedback

## Testing Strategy

### Unit Tests
- [ ] State management
- [ ] Data validation
- [ ] UI components
- [ ] Bulk operations
- [ ] Export functionality

### Integration Tests
- [ ] Save/load flow
- [ ] Bulk operations
- [ ] Export/import
- [ ] State persistence

### User Acceptance Criteria
- [ ] Save multiple mappings for a product
- [ ] Easily switch between saved mappings
- [ ] Perform bulk updates efficiently
- [ ] Handle duplicate queries appropriately
- [ ] Export/import functionality works correctly

## Performance Considerations
- [ ] Efficient state updates
- [ ] Optimized bulk operations
- [ ] Responsive UI during operations
- [ ] Memory-efficient state management

## Error Handling
- [ ] Input validation
- [ ] Operation failure recovery
- [ ] Clear error messages
- [ ] State consistency maintenance

## Documentation Requirements
- [ ] Code documentation
- [ ] User guide
- [ ] API documentation
- [ ] Example usage 