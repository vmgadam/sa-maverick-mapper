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
- [x] Unit tests for SavedMappingsScreen:
  - [x] Test table rendering
  - [x] Test selection functionality
  - [x] Test bulk actions
  - [x] Test UI state updates

### Phase 3: Save/Load Flow ✅
- [x] Add "Save As" functionality to UnifiedMapperScreen:
  - [x] Save button with name input dialog
  - [x] Name validation (max 200 chars)
  - [x] Timestamp handling
  - [x] Field count calculations
- [x] Implement query duplicate detection:
  - [x] Exact string matching
  - [x] Warning dialog with matching mappings list
  - [x] Visual indicators in saved mappings list
- [x] Add mapping switch confirmation:
  - [x] Unsaved changes detection
  - [x] Warning dialog
  - [x] Save prompt
- [x] Unit tests for save/load flow:
  - [x] Test "Save As" functionality
  - [x] Test query duplicate detection
  - [x] Test switch confirmation
  - [x] Test validation

### Phase 4: Bulk Operations ✅
- [x] Implement bulk field updates:
  - [x] Selection of target field
  - [x] Reuse complex mapping editor
  - [x] Apply changes to selected mappings
  - [x] Store state for revert
- [x] Add bulk delete functionality:
  - [x] Confirmation dialog
  - [x] Batch delete operation
- [x] Add bulk export:
  - [x] Export selected mappings
  - [x] JSON format handling
- [x] Unit tests for bulk operations:
  - [x] Test bulk field updates
  - [x] Test revert functionality
  - [x] Test bulk delete
  - [x] Test bulk export

### Phase 5: Integration and Export ✅
- [x] Integrate with existing JSON export:
  - [x] Extend format for multiple mappings
  - [x] Maintain backward compatibility
- [x] Add export functionality:
  - [x] Export single mapping
  - [x] Export multiple mappings
  - [x] Export all mappings
- [x] Unit tests for export:
  - [x] Test single mapping export
  - [x] Test multiple mapping export
  - [x] Test JSON format compliance

### Phase 6: Documentation ✅
- [x] User Guide:
  - [x] Installation instructions
  - [x] Basic usage examples
  - [x] Bulk operations guide
  - [x] Export/import guide
- [x] API Documentation:
  - [x] State management methods
  - [x] Widget documentation
  - [x] Service documentation
- [x] Example Usage:
  - [x] Basic mapping examples
  - [x] Complex mapping examples
  - [x] Bulk operation examples
  - [x] Export/import examples

## UI/UX Requirements

### Saved Mappings Screen ✅
- [x] Clean, organized table layout
- [x] Clear visual hierarchy
- [x] Responsive design
- [x] Intuitive bulk selection
- [x] Clear action buttons
- [x] Visible duplicate query indicators

### Save Dialog ✅
- [x] Simple, focused name input
- [x] Clear validation feedback
- [x] Duplicate query warnings
- [x] Cancel/Save buttons

### Bulk Operations ✅
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
- [x] Export functionality

### Integration Tests ✅
- [x] Save/load flow
- [x] Bulk operations
- [x] Export/import
- [x] State persistence

### User Acceptance Criteria ✅
- [x] Save multiple mappings for a product
- [x] Easily switch between saved mappings
- [x] Perform bulk updates efficiently
- [x] Handle duplicate queries appropriately
- [x] Export/import functionality works correctly

## Performance Considerations ✅
- [x] Efficient state updates
- [x] Optimized bulk operations
- [x] Responsive UI during operations
- [x] Memory-efficient state management

## Error Handling ✅
- [x] Input validation
- [x] Operation failure recovery
- [x] Clear error messages
- [x] State consistency maintenance

## Documentation Requirements ✅
- [x] Code documentation
- [x] User guide
- [x] API documentation
- [x] Example usage 