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
  // Updated to match tree-sitter-pascal node types
  typeDeclarationNodes: ['declClass', 'declIntf', 'declHelper'],
  fieldNodeTypes: ['declField', 'declVar', 'declConst'],
  bodyNodeTypes: ['declSection', '_declClass'],
  defaultVisibility: 'public',

  extractName(node) {
    // declField has direct name field
    const nameNode = node.childForFieldName('name');
    if (nameNode) return nameNode.text;

    // Fallback: check for identifier_list (var declarations)
    const namesNode = node.childForFieldName('names');
    if (namesNode?.type === 'identifier_list') {
      const firstIdent = namesNode.namedChild(0);
      if (firstIdent?.type === 'identifier') return firstIdent.text;
    }
    return undefined;
  },

  extractType(node) {
    // declField > type:(typeref)
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
    // Pascal class fields are marked with 'class var'
    // Check for class keyword in parent context
    return false;
  },

  isReadonly(node) {
    // const declarations are readonly
    return node.type === 'declConst' || node.type === 'declConsts';
  },
};
