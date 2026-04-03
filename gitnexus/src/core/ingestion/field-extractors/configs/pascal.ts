// gitnexus/src/core/ingestion/field-extractors/configs/pascal.ts

import { SupportedLanguages } from 'gitnexus-shared';
import type { FieldExtractionConfig } from '../generic.js';
import type { FieldVisibility } from '../../field-types.js';
import type { SyntaxNode } from '../../utils/ast-helpers.js';
import { extractSimpleTypeName } from '../../type-extractors/shared.js';

const PASCAL_VIS = new Set<FieldVisibility>(['public', 'private', 'protected']);

function findPascalVisibility(node: SyntaxNode): FieldVisibility {
  // Check for visibility specifiers in parent or modifiers
  const visKeywords: FieldVisibility[] = ['public', 'private', 'protected'];
  for (let i = 0; i < node.childCount; i++) {
    const child = node.child(i);
    if (child && visKeywords.includes(child.text as FieldVisibility)) {
      return child.text as FieldVisibility;
    }
  }
  // Check parent's children for visibility specifiers
  if (node.parent) {
    for (let i = 0; i < node.parent.childCount; i++) {
      const sibling = node.parent.child(i);
      if (sibling && visKeywords.includes(sibling.text as FieldVisibility)) {
        return sibling.text as FieldVisibility;
      }
    }
  }
  return 'public'; // Pascal default is public in interface section
}

export const pascalConfig: FieldExtractionConfig = {
  language: SupportedLanguages.Pascal,
  typeDeclarationNodes: ['class_type', 'record_type', 'object_type'],
  fieldNodeTypes: ['field_declaration', 'variable_declaration'],
  bodyNodeTypes: ['class_body', 'record_field_list', 'object_body'],
  defaultVisibility: 'public',

  extractName(node) {
    // field_declaration > names:(identifier_list) > identifiers
    const namesNode = node.childForFieldName('names');
    if (namesNode?.type === 'identifier_list') {
      const firstIdent = namesNode.namedChild(0);
      if (firstIdent?.type === 'identifier') return firstIdent.text;
    }
    // Fallback: direct name field
    const nameNode = node.childForFieldName('name');
    if (nameNode) return nameNode.text;
    return undefined;
  },

  extractType(node) {
    // field_declaration > type:(type_identifier)
    const typeNode = node.childForFieldName('type');
    if (typeNode) {
      return extractSimpleTypeName(typeNode) ?? typeNode.text?.trim();
    }
    return undefined;
  },

  extractVisibility(node) {
    return findPascalVisibility(node);
  },

  isStatic(_node) {
    // Pascal doesn't have static class fields in the same way
    return false;
  },

  isReadonly(node) {
    // const fields are readonly
    return node.type === 'const_declaration' || node.type === 'const_section';
  },
};
