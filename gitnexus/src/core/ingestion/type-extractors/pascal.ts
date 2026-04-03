import type { LanguageTypeConfig, TypeBindingExtractor, ParameterExtractor } from './types.js';
import type { SyntaxNode } from '../utils/ast-helpers.js';
import { extractSimpleTypeName, extractVarName } from './shared.js';

// Pascal declaration node types
const PASCAL_DECLARATION_NODE_TYPES: ReadonlySet<string> = new Set([
  'variable_declaration',
  'field_declaration',
  'const_declaration',
]);

/** Pascal: var x: Type = ...; or field in class/record */
const extractPascalDeclaration: TypeBindingExtractor = (
  node: SyntaxNode,
  env: Map<string, string>,
): void => {
  // field_declaration or variable_declaration > type:(type_identifier) + names:(identifier_list)
  const typeNode = node.childForFieldName('type');
  if (!typeNode) return;
  const typeName = extractSimpleTypeName(typeNode);
  if (!typeName) return;

  // Find identifier_list or direct identifiers
  const namesNode = node.childForFieldName('names');
  if (namesNode?.type === 'identifier_list') {
    for (let i = 0; i < namesNode.namedChildCount; i++) {
      const ident = namesNode.namedChild(i);
      if (ident?.type === 'identifier') {
        const varName = extractVarName(ident);
        if (varName) env.set(varName, typeName);
      }
    }
  } else {
    // Single identifier fallback
    const nameNode = node.childForFieldName('name');
    if (nameNode) {
      const varName = extractVarName(nameNode);
      if (varName) env.set(varName, typeName);
    }
  }
};

/** Pascal: parameter in procedure/function declaration */
const extractPascalParameter: ParameterExtractor = (
  node: SyntaxNode,
  env: Map<string, string>,
): void => {
  // parameter_declaration > name:(identifier) + type:(type_identifier)
  const nameNode = node.childForFieldName('name');
  const typeNode = node.childForFieldName('type');
  if (!nameNode || !typeNode) return;

  const varName = extractVarName(nameNode);
  const typeName = extractSimpleTypeName(typeNode);
  if (varName && typeName) env.set(varName, typeName);
};

export const pascalTypeConfig: LanguageTypeConfig = {
  declarationNodeTypes: PASCAL_DECLARATION_NODE_TYPES,
  extractDeclaration: extractPascalDeclaration,
  extractParameter: extractPascalParameter,
};
