# Saved Mappings Feature Specification

## Overview
This feature allows users to save multiple event mappings for a single product, manage them through a dedicated screen, and perform bulk operations on them.

## Data Structure
```typescript
interface SavedMapping {
  name: string;           // max 200 chars, enforced by UI
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

### Phase 1: State Management ✅
- [x] Extend MappingState to include saved mappings collection
- [x] Add state management methods:
  - [x] Create new saved mapping
  - [x] Update existing mapping
  - [x] Duplicate mapping (with "Copy of X" naming)
  - [x] Delete mapping(s)
  - [x] Bulk update mappings
  - [x] Store last bulk operation state for revert
- [x] Unit tests for state management:
  - [x] Test saved mapping CRUD operations
  - [x] Test duplicate naming functionality
  - [x] Test bulk operations
  - [x] Test revert functionality

### Phase 2: Saved Events Screen ✅
- [x] Create SavedMappingsScreen widget
- [x] Implement table/list view with columns:
  - [x] Name
  - [x] Product
  - [x] Total fields mapped
  - [x] Required fields mapped/total
  - [x] Last modified date
  - [x] Visual indicator for duplicate queries
  - [x] Action buttons (Load, Duplicate, Delete)
- [x] Add multi-select functionality:
  - [x] Checkbox selection
  - [x] Bulk action buttons
  - [x] Selection count display
- [x] Unit tests for components:
  - [x] Test table rendering
  - [x] Test selection functionality
  - [x] Test bulk actions
  - [x] Test UI state updates
- [x] Integration tests for screen:
  - [x] Test screen state management
  - [x] Test component integration
  - [x] Test user workflows

### Phase 3: Save/Load Flow (In Progress)
- [x] Add "Save As" functionality:
  - [x] Create SaveAsDialog component
  - [x] Add name input with automatic length enforcement (max 200 chars)
  - [x] Add save button with loading state
  - [x] Add cancel button
  - [x] Handle duplicate names with error messages
  - [x] Add comprehensive dialog tests
- [x] Integrate with UnifiedMapperScreen:
  - [x] Replace Current Mappings section with SavedMappingsSection
  - [x] Add search and filter functionality
  - [x] Add sorting capabilities
  - [x] Implement selection and bulk actions
  - [x] Handle duplicate query indicators
- [ ] Implement query duplicate detection:
  - [ ] Create DuplicateQueryDialog component
  - [ ] Show matching mappings list
  - [ ] Add continue/cancel actions
  - [ ] Update visual indicators
- [ ] Add mapping switch confirmation:
  - [ ] Create UnsavedChangesDialog component
  - [ ] Add save/discard/cancel options
  - [ ] Track unsaved changes state
  - [ ] Handle navigation interruption
- [ ] Unit tests for save/load flow:
  - [x] Test SaveAsDialog functionality
  - [ ] Test DuplicateQueryDialog functionality
  - [ ] Test UnsavedChangesDialog functionality
  - [ ] Test validation and error states
- [ ] Integration tests for save/load flow:
  - [ ] Test end-to-end save workflow
  - [ ] Test duplicate detection workflow
  - [ ] Test unsaved changes workflow

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

### Saved Mappings Section ✅
- [x] Clean, organized table layout
- [x] Clear visual hierarchy
- [x] Responsive design
- [x] Intuitive bulk selection
- [x] Clear action buttons
- [x] Visible duplicate query indicators
- [x] Search and filter functionality
- [x] Sorting by multiple fields

### Save Dialog ✅
- [x] Simple, focused name input
- [x] Clear validation feedback
- [x] Duplicate query warnings
- [x] Cancel/Save buttons

### Bulk Operations
- [x] Clear selection indicators
- [x] Intuitive bulk actions
- [x] Visible revert option
- [x] Progress feedback

## Testing Strategy

### Unit Tests ✅
- [x] State management
- [x] Data validation
- [x] UI components
- [x] Bulk operations
- [ ] Export functionality

### Integration Tests
- [x] Save/load flow
- [x] Bulk operations
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
- [x] Input validation
- [x] Operation failure recovery
- [x] Clear error messages
- [x] State consistency maintenance

## Documentation Requirements
- [x] Code documentation
- [ ] User guide
- [ ] API documentation
- [ ] Example usage 